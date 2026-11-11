import { visibleWidth, type Component } from "@oh-my-pi/pi-tui";
import { toolRenderers, type ToolRenderer } from "@oh-my-pi/pi-tui/tools";
import { getEditInputPaths, type EditToolDetails, type EditRenderContext } from "@oh-my-pi/pi-tui/tools/edit";
import type { ReadToolDetails } from "@oh-my-pi/pi-tui/tools/read";
import {
	CachedOutputBlock,
	outputBlockContentWidth,
	type OutputBlockOptions,
} from "@oh-my-pi/pi-tui/render/output-block";
import {
	formatDiagnostics,
	formatExpandHint,
	PREVIEW_LIMITS,
	previewWindowRows,
} from "@oh-my-pi/pi-tui/render/render-utils";
import { getLanguageFromPath } from "@oh-my-pi/pi-tui/lang-from-path";
import { Delta } from "./delta";

// These adapters target the ANSI renderer contract in omp 18.13.1. In particular,
// describeCall/describeResult (Tern) and the actual tools are never replaced.
// The host registry erases individual tool payload types at its shared seam.
type RecordValue = Partial<
	Omit<EditToolDetails & EditRenderContext & ReadToolDetails, "editDiffPreview">
	& NonNullable<ReadToolDetails["displayContent"]> & Patch
> & {
	file_path?: string;
	content?: string;
	input?: string;
	_input?: string;
	previewDiff?: string;
	editDiffPreview?: RecordValue;
	edits?: RecordValue[];
	isError?: boolean;
	error?: string;
	deltaDiff?: Patch;
};
type Options = Parameters<ToolRenderer["renderResult"]>[1];
type Theme = Parameters<ToolRenderer["renderResult"]>[2];
type Result = Parameters<ToolRenderer["renderResult"]>[0];
type Patch = { patch: string; cwd?: string };
type Scope = {
	tokens: Map<string, Patch>;
	options: Options;
	theme: Theme;
	preview: boolean;
	edit?: boolean;
	write?: { patch: Patch; result?: Result; args: RecordValue };
};
let active: Scope | undefined;
let installed = false;
const pendingWrites = new Map<string, Map<string, Patch>>();

/** Only call after reading the old file; undefined must mean confirmed absence. */
export function setWriteSnapshot(path: string, oldText: string | undefined, newText: string): void {
	let entries = pendingWrites.get(path);
	if (!entries) pendingWrites.set(path, (entries = new Map()));
	entries.set(newText, { patch: Delta.snapshots(oldText, newText, path), cwd: Delta.cwd });
}

export function clearWriteSnapshot(path: string, newText: string): void {
	const entries = pendingWrites.get(path);
	entries?.delete(newText);
	if (entries?.size === 0) pendingWrites.delete(path);
}

function object(value: unknown): RecordValue {
	return value !== null && typeof value === "object" ? value as RecordValue : {};
}

function pathOf(args: RecordValue): string {
	return typeof args.file_path === "string" ? args.file_path : typeof args.path === "string" ? args.path : "";
}

function plain(text: string): string {
	return text.replace(/\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)/g, "").replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
}

function rows(patch: Patch, width: number, scope: Scope): readonly string[] {
	let rendered: readonly string[];
	try {
		rendered = Delta.render(patch.patch, Math.max(1, width), patch.cwd);
	} catch (error) {
		// SafeToolRenderer otherwise catches exceptions and silently restores the
		// native body. Keep the actual Delta failure visible in the tool card.
		return [scope.theme.fg("error", `Delta: ${String(error)}`)];
	}
	const limit = scope.preview
		? scope.options.expanded ? previewWindowRows() : Math.min(PREVIEW_LIMITS.EXPANDED_LINES, previewWindowRows())
		: scope.options.expanded ? Infinity : PREVIEW_LIMITS.DIFF_COLLAPSED_LINES;
	if (rendered.length <= limit) return rendered;
	const hidden = rendered.length - limit;
	const hint = scope.theme.fg("dim", `… (${hidden} more Delta rows) ${formatExpandHint(scope.theme)}`);
	return scope.preview ? [hint, ...rendered.slice(-limit)] : [...rendered.slice(0, limit), hint];
}

function token(scope: Scope, patch: Patch, reserved = ""): string {
	for (const [key, existing] of scope.tokens) {
		if (existing.patch === patch.patch && existing.cwd === patch.cwd) return key;
	}
	// One printable cell survives even a narrow source-code preview. Tokens are
	// display-local and disappear before the frame is laid out or copied.
	for (let code = 0xe000; code <= 0xf8ff; code++) {
		const key = String.fromCharCode(code);
		if (!scope.tokens.has(key) && !reserved.includes(key)) {
			scope.tokens.set(key, patch);
			return key;
		}
	}
	throw new Error("Delta display has too many independent patches");
}

function replaceTokens(lines: readonly string[], width: number, scope: Scope, framed = false): readonly string[] {
	let changed = false;
	const output: string[] = [];
	for (const line of lines) {
		const text = plain(line);
		let replacement: Patch | undefined;
		for (const [key, patch] of scope.tokens) {
			if (text.includes(key)) { replacement = patch; break; }
		}
		if (replacement) {
			changed = true;
			// read's code-cell renderer calls renderOutputBlock directly, unlike
			// ToolCard. Replace its marker after layout but retain both frame rails.
			const rail = scope.theme.boxRound.vertical;
			const left = framed ? line.indexOf(rail) : -1;
			const right = framed ? line.lastIndexOf(rail) : -1;
			if (left >= 0 && right > left && text.trimStart().startsWith(rail)) {
				const innerWidth = Math.max(1, width - 4);
				const prefix = line.slice(0, left + rail.length);
				const suffix = scope.theme.fg("borderMuted", line.slice(right));
				for (const row of rows(replacement, innerWidth, scope)) {
					output.push(`${prefix} \x1b[0m${row}\x1b[0m${" ".repeat(Math.max(0, innerWidth - visibleWidth(row)))} ${suffix}`);
				}
			} else output.push(...rows(replacement, width, scope));
		} else output.push(line);
	}
	if (changed) {
		// Native compact-diff truncation counted source rows before the marker.
		// Delta now clamps its own visual rows; do not retain stale native counts.
		return scope.edit ? output.filter(line => !/^… \(\d+ more (?:hunks|lines)(?:, \d+ more (?:hunks|lines))?\)/.test(plain(line).trim())) : output;
	}
	return lines;
}

function replacePatches(text: string, scope: Scope, sourceRows?: number[]): string {
	const clean = plain(text);
	const prefixed = /^[ \t]*\d+(?:#[A-Za-z0-9]+)?[:|](?:diff --(?:git|cc|combined) |--- )/m.test(clean);
	// Undo only read's model-facing anchors. Keep Git's ANSI (color-moved)
	// otherwise; Delta, not this adapter, owns patch parsing and boundaries.
	const patch = prefixed ? clean.replace(/^[ \t]*\d+(?:#[A-Za-z0-9]+)?[:|]/gm, "") : text;
	if (!Delta.isPatch(prefixed ? patch : clean)) return text;
	sourceRows?.push(0);
	return token(scope, { patch }, text);
}

function scoped(component: Component | undefined, scope: Scope): Component | undefined {
	if (!component) return component;
	// Mutate the returned display component, not a facade: frame markers,
	// lifecycle hooks and identity used by the transcript remain intact.
	const render = component.render;
	component.render = function (width) {
		const previous = active;
		active = scope;
		try { return replaceTokens(render.call(this, width), width, scope, true); }
		finally { active = previous; }
	};
	return component;
}

function snapshotPatch(details: RecordValue, fallbackPath: string): Patch | undefined {
	if (details.snapshotsPruned || details.isError) return undefined;
	const old = typeof details.oldText === "string" ? details.oldText : undefined;
	const next = typeof details.newText === "string" ? details.newText : undefined;
	if (!(old !== undefined && next !== undefined || details.op === "create" && next !== undefined || details.op === "delete" && old !== undefined)) return undefined;
	return { patch: Delta.snapshots(old, next, details.path ?? fallbackPath, details.sourcePath) };
}

function editCall(renderer: ToolRenderer, argsValue: unknown, options: Options, theme: Theme): Component | undefined {
	const args = object(argsValue);
	const context = object(options.renderContext);
	const input = typeof args.input === "string" ? args.input : typeof args._input === "string" ? args._input : undefined;
	const previewPath = pathOf(args) || object(args.edits?.[0]).path ||
		(input ? getEditInputPaths(input, context.editMode)[0] : undefined) || "";
	const scope: Scope = { tokens: new Map(), options, theme, preview: true, edit: true };
	const asToken = (diff: string, path: string) => token(scope, { patch: Delta.compact(diff, path) }, diff);
	const previews = Array.isArray(context.perFileDiffPreview) ? context.perFileDiffPreview.map((preview: RecordValue) =>
		preview.diff && !preview.error ? { ...preview, diff: asToken(preview.diff, preview.path ?? previewPath) } : preview) : undefined;
	let changedArgs = args;
	if (typeof args.previewDiff === "string" && args.previewDiff) changedArgs = { ...args, previewDiff: asToken(args.previewDiff, previewPath) };
	else if (typeof args.diff === "string" && (args.op || Delta.isPatch(args.diff) || /^[+ -]\s*\d+\|/m.test(args.diff))) changedArgs = { ...args, diff: asToken(args.diff, previewPath) };
	else if (typeof context.editDiffPreview?.diff === "string") changedArgs = { ...args, previewDiff: asToken(context.editDiffPreview.diff, previewPath) };
	const changedOptions = Object.create(options) as Options;
	changedOptions.renderContext = { ...context, ...(previews ? { perFileDiffPreview: previews } : {}) };
	return scoped(renderer.renderCall(changedArgs, changedOptions, theme), scope);
}

function editResult(renderer: ToolRenderer, result: Result, options: Options, theme: Theme, argsValue: unknown): Component | undefined {
	const args = object(argsValue);
	const details = object(result.details);
	const raw = object(options.renderContext?.rawDetails);
	const scope: Scope = { tokens: new Map(), options, theme, preview: false, edit: true };
	const records: RecordValue[] = Array.isArray(raw.perFileResults) ? raw.perFileResults : Array.isArray(details.perFileResults) ? details.perFileResults : [Object.keys(raw).length ? raw : details];
	const withDiff = (item: RecordValue, authoritative: RecordValue) => {
		if (item.isError || result.isError) return item;
		if (item.diff) return item;
		const patch = snapshotPatch(authoritative, pathOf(args));
		return patch?.patch ? { ...item, diff: patch.patch } : item;
	};
	const changedDetails = Array.isArray(details.perFileResults)
		? { ...details, perFileResults: details.perFileResults.map((item: RecordValue, index: number) => withDiff(item, records[index] ?? item)) }
		: withDiff(details, records[0] ?? details);
	const changedOptions = Object.create(options) as Options;
	changedOptions.renderContext = {
		...options.renderContext,
		renderDiff(diff: string, settings?: { filePath?: string }) {
			const path = settings?.filePath ?? pathOf(args);
			const record = records.find(item => item.path === path || item.sourcePath === path) ?? (records.length === 1 ? records[0] : undefined);
			const patch = record && snapshotPatch(record, path);
			return token(scope, patch ?? { patch: Delta.compact(record?.diff || object(options.renderContext?.editDiffPreview).diff || diff, path) }, diff);
		},
	};
	return scoped(renderer.renderResult({ ...result, details: result.details === undefined ? undefined : changedDetails }, changedOptions, theme, argsValue), scope);
}

function writeScope(options: Options, theme: Theme, argsValue: unknown, result?: Result): Scope | undefined {
	const args = object(argsValue);
	if (result?.isError || typeof args.content !== "string") return undefined;
	const path = pathOf(args);
	if (!path || /^[a-z][a-z0-9+.-]*:\/\//i.test(path)) return undefined;
	const persisted = object(object(result?.details).deltaDiff);
	const patch: Patch | undefined = typeof persisted.patch === "string"
		? { patch: persisted.patch, cwd: persisted.cwd }
		: result ? undefined : pendingWrites.get(path)?.get(args.content);
	if (!patch) return undefined;
	return { tokens: new Map(), options, theme, preview: !result, write: { patch, result, args } };
}

function writeBlock(options: OutputBlockOptions, width: number, scope: Scope): OutputBlockOptions {
	const write = scope.write!;
	const existing = options.sections?.[0]?.lines ?? [];
	const content: string[] = [];
	const result = write.result;
	const progress = result?.content.find(block => block.type === "text")?.text;
	if (result && scope.options.isPartial && progress && existing.length) content.push(existing[0]!);
	content.push(...rows(write.patch, width, scope));
	if (!result) {
		const streaming = existing.findLast(line => plain(line).includes("(streaming)"));
		if (streaming) content.push(streaming);
	} else if (!scope.options.isPartial && object(result.details).diagnostics) {
		const diagnostics = formatDiagnostics(object(result.details).diagnostics!, scope.options.expanded, scope.theme,
			path => scope.theme.getLangIcon(getLanguageFromPath(path)));
		content.push(...diagnostics.trimStart().split("\n"));
	}
	return { ...options, sections: [{ ...options.sections?.[0], lines: content }, ...(options.sections?.slice(1) ?? [])] };
}

function textResult(renderer: ToolRenderer, result: Result, options: Options, theme: Theme, args: unknown): Component | undefined {
	const scope: Scope = { tokens: new Map(), options, theme, preview: false };
	const content = result.content.map(block => block.type === "text" && typeof block.text === "string"
		? { ...block, text: replacePatches(block.text, scope) } : block);
	let details = result.details;
	const display = object(object(details).displayContent);
	if (typeof display.text === "string") {
		const sourceRows: number[] = [];
		const text = replacePatches(display.text, scope, sourceRows);
		if (text !== display.text) {
			const lineNumbers = sourceRows.map(index => display.lineNumbers ? display.lineNumbers[index] ?? null : (display.startLine ?? 1) + index);
			details = { ...object(details), displayContent: { ...display, text, lineNumbers } };
		}
	}
	const context = options.renderContext;
	let changedOptions = options;
	if (typeof context?.output === "string") {
		const output = replacePatches(context.output, scope);
		if (output !== context.output) {
			changedOptions = Object.create(options) as Options;
			changedOptions.renderContext = { ...context, output };
		}
	}
	if (!scope.tokens.size) return renderer.renderResult(result, options, theme, args);
	return scoped(renderer.renderResult({ ...result, content, details }, changedOptions, theme, args), scope);
}

export function installToolDiffs(): void {
	if (installed) return;
	installed = true;
	const renderBlock = CachedOutputBlock.prototype.render;
	CachedOutputBlock.prototype.render = function (options, theme) {
		const scope = active;
		if (!scope || (!scope.write && scope.tokens.size === 0)) return renderBlock.call(this, options, theme);
		const width = outputBlockContentWidth(options.width, options.contentPaddingLeft, options.contentPaddingRight);
		const transformed = scope.write ? writeBlock(options, width, scope) : {
			...options,
			sections: options.sections?.map(section => ({ ...section, lines: replaceTokens(section.lines, width, scope) })),
		};
		// A themed card background rewrites every Delta SGR reset and changes
		// its default/unchanged cells. Let Delta own the complete body palette.
		return renderBlock.call(this, { ...transformed, applyBg: false }, theme);
	};
	for (const [name, renderer] of Object.entries(toolRenderers)) {
		toolRenderers[name] = {
			...renderer,
			renderCall(args, options, theme) {
				if (name === "edit" || name === "apply_patch") return editCall(renderer, args, options, theme);
				const component = renderer.renderCall(args, options, theme);
				const scope = name === "write" ? writeScope(options, theme, args) : undefined;
				return scope ? scoped(component, scope) : component;
			},
			renderResult(result, options, theme, args) {
				if (name === "edit" || name === "apply_patch") return editResult(renderer, result, options, theme, args);
				const scope = name === "write" ? writeScope(options, theme, args, result) : undefined;
				if (scope) return scoped(renderer.renderResult(result, options, theme, args), scope);
				return textResult(renderer, result, options, theme, args);
			},
		};
	}
}
