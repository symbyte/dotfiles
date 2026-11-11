import { readFile, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { resolve } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import type { TUI } from "@oh-my-pi/pi-tui";
import { Delta } from "./delta";
import { installMarkdownDiffs } from "./markdown";
import { clearWriteSnapshot, installToolDiffs, setWriteSnapshot } from "./tools";

// OMP 18.13.1 has no global diff-renderer hook. These adapters replace display
// bodies only; native tools, provider messages, and the Git staging UI stay intact.
installToolDiffs();
installMarkdownDiffs();

type WriteSnapshot = { path: string; inputPath: string; oldText: string | undefined; content: string; cwd: string };

export default function deltaDiffs(pi: ExtensionAPI): void {
	pi.setLabel("Delta diffs");
	const writes = new Map<string, WriteSnapshot>();
	let tui: TUI | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		Delta.cwd = ctx.cwd;
		ctx.ui.setWidget("delta-diffs-host", host => {
			tui = host;
			return { render: () => [], dispose: () => { tui = undefined; } };
		});
	});

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "write") return;
		const { path, content } = event.input;
		if (typeof path !== "string" || typeof content !== "string" || /^[a-z][a-z\d+.-]*:\/\//i.test(path)) return;
		const absolute = resolve(ctx.cwd, path.startsWith("~/") ? resolve(homedir(), path.slice(2)) : path);
		let oldText: string | undefined;
		try {
			if (!(await stat(absolute)).isFile()) return;
			oldText = await readFile(absolute, "utf8");
		} catch (error) {
			if ((error as NodeJS.ErrnoException).code !== "ENOENT") return;
		}
		writes.set(event.toolCallId, { path: absolute, inputPath: path, oldText, content, cwd: ctx.cwd });
		setWriteSnapshot(path, oldText, content);
	});

	pi.on("tool_result", async event => {
		const snapshot = writes.get(event.toolCallId);
		if (!snapshot) return;
		writes.delete(event.toolCallId);
		clearWriteSnapshot(snapshot.inputPath, snapshot.content);
		if (event.isError) return;
		let newText: string;
		try {
			// Read the actual result, including any native formatter's changes.
			newText = await readFile(snapshot.path, "utf8");
		} catch {
			return;
		}
		const patch = Delta.snapshots(snapshot.oldText, newText, snapshot.inputPath);
		if (!patch) return;
		const details = event.details && typeof event.details === "object" ? event.details : {};
		return { details: { ...details, deltaDiff: { patch, cwd: snapshot.cwd } } };
	});

	pi.registerCommand("delta-refresh", {
		description: "Re-render chat diffs after changing Git/Delta configuration",
		handler: async (_args, ctx) => {
			Delta.cwd = ctx.cwd;
			Delta.clear();
			tui?.invalidate();
			tui?.requestRender();
			ctx.ui.notify("Delta diff cache cleared", "info");
		},
	});

	pi.on("session_shutdown", (_event, ctx) => {
		for (const snapshot of writes.values()) clearWriteSnapshot(snapshot.inputPath, snapshot.content);
		writes.clear();
		if (tui) ctx.ui.setWidget("delta-diffs-host", undefined);
	});
}
