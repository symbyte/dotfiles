import type { AssistantMessage } from "@oh-my-pi/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { type Component, TUI, parseSgrMouse, truncateToWidth, visibleWidth } from "@oh-my-pi/pi-tui";
import { AssistantMessageComponent } from "@oh-my-pi/pi-tui/chat/assistant-message";
import { UserMessageComponent } from "@oh-my-pi/pi-tui/chat/user-message";
import { TranscriptContainer } from "@oh-my-pi/pi-tui/chrome/transcript-container";
import { Composer } from "@oh-my-pi/pi-tui/prompt/composer";

// OMP 18.12.6 has no public transcript-routing hook. These display-only adapters
// are scoped to the owning TUI; provider messages and persisted entries never change.
type Snapshot = {
	full: AssistantMessage;
	projected?: AssistantMessage;
	options?: { transient?: boolean };
	version: number;
	side?: AssistantMessageComponent;
	sideVersion?: number;
};
type Split = {
	tui: TUI;
	enabled: boolean;
	activityFraction?: number;
	dragging: boolean;
	conversationOffset: number;
	activityOffset: number;
	transcript?: TranscriptContainer;
	messages: Component[];
	assistants: Set<AssistantMessageComponent>;
	users: Map<UserMessageComponent, UserMessageComponent["render"]>;
};

const splits = new WeakMap<TUI, Split>();
const owners = new WeakMap<AssistantMessageComponent, Split>();
const snapshots = new WeakMap<AssistantMessageComponent, Snapshot>();
const updateContent = AssistantMessageComponent.prototype.updateContent;
const renderFrame = Composer.prototype.renderFrame;
const renderResizeFrame = Composer.prototype.renderResizeFrame;
const renderTail = TranscriptContainer.prototype.renderTail;
const transcriptOwners = new WeakMap<TranscriptContainer, Split>();
const empty: readonly string[] = [];
const mouseProviders = new WeakMap<TUI, (() => boolean) | undefined>();
const setInlineMouseTrackingProvider = TUI.prototype.setInlineMouseTrackingProvider;
const addInputListener = TUI.prototype.addInputListener;

TUI.prototype.setInlineMouseTrackingProvider = function (provider) {
	mouseProviders.set(this, provider);
	setInlineMouseTrackingProvider.call(this, () => splits.get(this)?.enabled === true || provider?.() === true);
};

function activityWidth(split: Split, columns: number, requested?: number): number {
	const available = Math.max(2, columns - 1);
	const minimum = Math.min(20, Math.floor(available / 2));
	const preferred = requested ?? (split.activityFraction === undefined
		? Math.floor(available / 2)
		: Math.round(available * split.activityFraction));
	return Math.max(minimum, Math.min(available - minimum, preferred));
}

function handleMouse(tui: TUI, data: string): { consume: true } | undefined {
	const split = splits.get(tui);
	if (!split?.enabled) return;
	if (!data.startsWith("\x1b[<") || tui.hasOverlay()) {
		split.dragging = false;
		return;
	}
	const event = parseSgrMouse(data);
	if (!event) return;
	const columns = tui.terminal.columns;
	const divider = activityWidth(split, columns);
	if (split.dragging) {
		if ((event.button & 64) !== 0) return { consume: true };
		if ((event.button & 3) === 0 && (event.motion || event.release)) {
			const width = activityWidth(split, columns, event.col);
			if (width !== divider) {
				split.activityFraction = width / Math.max(2, columns - 1);
				tui.requestRender();
			}
			if (event.release) split.dragging = false;
			return { consume: true };
		}
		// Recover from a release lost outside the terminal, or a new button press.
		split.dragging = false;
		if (event.motion || event.release) return { consume: true };
	}
	const inside = event.col >= 0 && event.col < columns &&
		event.row >= 0 && event.row < tui.terminal.rows;
	if (inside && event.col === divider && event.leftClick && event.button === 0) {
		split.dragging = true;
		return { consume: true };
	}
	if (event.wheel === null) return;
	if (!event.release && inside && event.col !== divider) {
		const pane = event.col < divider ? "activityOffset" : "conversationOffset";
		split[pane] = Math.max(0, split[pane] - event.wheel * 3);
		tui.requestRender();
	}
	return { consume: true };
}

// Product inline-mouse listeners otherwise consume pointer reports before the
// extension sees them. Route pane gestures first, but leave overlays in control.
TUI.prototype.addInputListener = function (listener) {
	return addInputListener.call(this, data => handleMouse(this, data) ?? listener(data));
};

function project(snapshot: Snapshot, enabled: boolean): AssistantMessage {
	if (!enabled) {
		snapshot.projected = undefined;
		return snapshot.full;
	}
	return (snapshot.projected = {
		...snapshot.full,
		content: snapshot.full.content.filter(block => block.type !== "text"),
	});
}

AssistantMessageComponent.prototype.updateContent = function (message, options) {
	const previous = snapshots.get(this);
	// Setters may reuse or shallow-copy the last display projection. Preserve
	// its full content while still accepting changed presentation metadata.
	const full = previous?.projected && message.content === previous.projected.content
		? message === previous.projected ? previous.full : { ...message, content: previous.full.content }
		: message;
	const snapshot: Snapshot = previous ?? { full, version: 0 };
	snapshot.full = full;
	snapshot.options = options;
	snapshot.version++;
	snapshots.set(this, snapshot);
	updateContent.call(this, project(snapshot, owners.get(this)?.enabled === true), options);
};

function collect(split: Split): void {
	const transcript = split.tui.children.find(child => child instanceof TranscriptContainer);
	if (!(transcript instanceof TranscriptContainer)) return;
	split.transcript = transcript;
	transcriptOwners.set(transcript, split);
	const messages: Component[] = [];
	const visit = (component: Component): void => {
		if (component instanceof UserMessageComponent) {
			messages.push(component);
			if (!split.users.has(component)) {
				const render = component.render;
				split.users.set(component, render);
				component.render = width => split.enabled ? empty : render.call(component, width);
			}
		} else if (component instanceof AssistantMessageComponent) {
			messages.push(component);
			if (!split.assistants.has(component)) {
				split.assistants.add(component);
				owners.set(component, split);
				const snapshot = snapshots.get(component);
				if (snapshot && split.enabled) {
					component.resetTranscriptStableRows();
					updateContent.call(component, project(snapshot, true), snapshot.options);
				}
			}
		} else if ("children" in component && Array.isArray(component.children)) {
			for (const child of component.children) visit(child);
		}
	};
	for (const component of transcript.children) visit(component);
	split.messages = messages;
	const current = new Set(messages);
	for (const [user, render] of split.users) {
		if (current.has(user)) continue;
		user.render = render;
		split.users.delete(user);
	}
	for (const assistant of split.assistants) {
		if (current.has(assistant)) continue;
		const snapshot = snapshots.get(assistant);
		if (snapshot) {
			updateContent.call(assistant, project(snapshot, false), snapshot.options);
			snapshot.side?.dispose();
			snapshot.side = undefined;
			snapshot.sideVersion = undefined;
		}
		owners.delete(assistant);
		split.assistants.delete(assistant);
	}
}

function setEnabled(split: Split, enabled: boolean): void {
	collect(split);
	split.enabled = enabled;
	split.dragging = false;
	split.conversationOffset = 0;
	split.activityOffset = 0;
	for (const assistant of split.assistants) {
		const snapshot = snapshots.get(assistant);
		if (snapshot) updateContent.call(assistant, project(snapshot, enabled), snapshot.options);
	}
	split.transcript?.resetStableEmission();
	split.tui.resetDisplay();
	split.tui.requestRender();
}

function conversationRows(split: Split, width: number, height: number): string[] {
	const rows: string[] = [];
	const capacity = Math.max(0, height - 1);
	let needed = capacity + split.conversationOffset;
	for (let index = split.messages.length - 1; index >= 0 && rows.length < needed; index--) {
		const component = split.messages[index]!;
		let block: readonly string[] = empty;
		if (component instanceof UserMessageComponent) {
			component.setTranscriptAllocation(Number.MAX_SAFE_INTEGER, { now: performance.now(), tick: 0 });
			block = split.users.get(component)!.call(component, width);
		} else if (component instanceof AssistantMessageComponent) {
			const snapshot = snapshots.get(component);
			if (!snapshot || !snapshot.full.content.some(part => part.type === "text" && part.text.trim())) continue;
			if (!snapshot.side) snapshot.side = new AssistantMessageComponent(undefined, true, () => split.tui.requestRender());
			if (snapshot.sideVersion !== snapshot.version) {
				updateContent.call(snapshot.side, {
					...snapshot.full,
					content: snapshot.full.content.filter(part => part.type === "text"),
					stopReason: "stop",
					errorMessage: undefined,
					retryRecovery: undefined,
				}, snapshot.options);
				snapshot.sideVersion = snapshot.version;
			}
			block = snapshot.side.render(width);
		}
		if (block.length > 0) rows.unshift(...block, "");
	}
	// Clamp overscroll so repeated Page Up never produces an empty pane.
	split.conversationOffset = Math.min(split.conversationOffset, Math.max(0, rows.length - capacity));
	needed = rows.length - split.conversationOffset;
	const label = split.conversationOffset ? "Conversation · history" : "Conversation · live";
	return [truncateToWidth(label, width), ...rows.slice(Math.max(0, needed - capacity), needed)];
}

TranscriptContainer.prototype.renderTail = function (width, maxRows) {
	const split = transcriptOwners.get(this);
	if (!split?.enabled || split.activityOffset === 0) return renderTail.call(this, width, maxRows);
	const rows = renderTail.call(this, width, maxRows + split.activityOffset);
	split.activityOffset = Math.min(split.activityOffset, Math.max(0, rows.length - maxRows));
	const end = rows.length - split.activityOffset;
	return rows.slice(Math.max(0, end - maxRows), end);
};

function merge(split: Split, left: readonly string[], columns: number, rows: number): string[] {
	const leftWidth = activityWidth(split, columns);
	const rightWidth = Math.max(1, columns - leftWidth - 1);
	const right = conversationRows(split, rightWidth, rows);
	return Array.from({ length: rows }, (_, index) => {
		const line = truncateToWidth(left[index] ?? "", leftWidth);
		return `${line}${" ".repeat(Math.max(0, leftWidth - visibleWidth(line)))}│${truncateToWidth(right[index] ?? "", rightWidth)}`;
	});
}

Composer.prototype.renderFrame = function (viewport) {
	const split = splits.get(this.ui);
	if (!split?.enabled) return renderFrame.call(this, viewport);
	collect(split);
	const width = activityWidth(split, viewport.columns);
	const narrow = { ...viewport, columns: width };
	const plan = renderFrame.call(this, narrow);
	// While split, both panes are bounded views of the semantic ledger. Accept
	// retirement without appending duplicate pane snapshots to native scrollback.
	// Closing the split replays the complete normal transcript at full width.
	return {
		...plan,
		history: plan.history ? { ...plan.history, rows: empty } : undefined,
		viewport: merge(split, renderResizeFrame.call(this, narrow), viewport.columns, viewport.rows),
	};
};

Composer.prototype.renderResizeFrame = function (viewport) {
	const split = splits.get(this.ui);
	if (!split?.enabled) return renderResizeFrame.call(this, viewport);
	collect(split);
	const columns = activityWidth(split, viewport.columns);
	return merge(split, renderResizeFrame.call(this, { ...viewport, columns }), viewport.columns, viewport.rows);
};

export default function conversationSplit(pi: ExtensionAPI): void {
	let split: Split | undefined;
	const toggle = (ctx: ExtensionContext): void => {
		if (!split || !ctx.hasUI) return;
		if (!split.enabled && split.tui.terminal.columns < 40) {
			ctx.ui.notify("Conversation split needs at least 40 terminal columns.", "warning");
			return;
		}
		setEnabled(split, !split.enabled);
	};
	pi.registerShortcut("alt+shift+m", { description: "Toggle conversation split", handler: toggle });
	pi.registerCommand("conversation-split", { description: "Toggle user/agent conversation pane", handler: (_args, ctx) => toggle(ctx) });
	for (const [key, pane, direction] of [
		["alt+pageUp", "conversationOffset", 1],
		["alt+pageDown", "conversationOffset", -1],
		["alt+shift+pageUp", "activityOffset", 1],
		["alt+shift+pageDown", "activityOffset", -1],
	] as const) {
		pi.registerShortcut(key, {
			description: `Scroll ${pane === "conversationOffset" ? "conversation" : "activity"} pane`,
			handler: () => {
				if (!split?.enabled) return;
				split[pane] = Math.max(0, split[pane] + direction * Math.max(1, split.tui.terminal.rows - 4));
				split.tui.requestRender();
			},
		});
	}
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		ctx.ui.setWidget("conversation-split-host", tui => {
			const state: Split = {
				tui, enabled: tui.terminal.columns >= 40, dragging: false, conversationOffset: 0, activityOffset: 0,
				messages: [], assistants: new Set(), users: new Map(),
			};
			split = state;
			splits.set(tui, state);
			tui.setInlineMouseTrackingProvider(mouseProviders.get(tui));
			// When the product's click capture is off, discard otherwise-unhandled
			// pointer reports rather than leaking motion/click bytes into the editor.
			const unsubscribeMouse = tui.addInputListener(data =>
				state.enabled && !tui.hasOverlay() && data.startsWith("\x1b[<") && parseSgrMouse(data)
					? { consume: true } : undefined);
			return {
				render: () => empty,
				dispose: () => {
					unsubscribeMouse();
					if (state.enabled) setEnabled(state, false);
					splits.delete(tui);
					for (const [user, render] of state.users) user.render = render;
					for (const assistant of state.assistants) {
						owners.delete(assistant);
						snapshots.get(assistant)?.side?.dispose();
					}
				},
			};
		});
	});
	const resetOffsets = (): void => {
		if (!split) return;
		split.dragging = false;
		split.conversationOffset = 0;
		split.activityOffset = 0;
		split.tui.requestRender();
	};
	pi.on("session_switch", event => {
		if (split && event.reason === "new") {
			setEnabled(split, split.tui.terminal.columns >= 40);
		} else {
			resetOffsets();
		}
	});
	pi.on("session_branch", resetOffsets);
	pi.on("session_tree", resetOffsets);
	pi.on("session_shutdown", (_event, ctx) => {
		if (split) ctx.ui.setWidget("conversation-split-host", undefined);
		split = undefined;
	});
}
