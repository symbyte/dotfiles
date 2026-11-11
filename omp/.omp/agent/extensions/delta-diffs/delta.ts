import { spawnSync } from "node:child_process";
import { structuredPatchHunks } from "@oh-my-pi/pi-natives";
import { truncateToWidth, visibleWidth } from "@oh-my-pi/pi-tui";

// OMP owns scrolling. Space-filled backgrounds cannot erase an adjacent split pane.
const cache = new Map<string, { lines: readonly string[]; bytes: number }>();
let cacheBytes = 0;
const cacheLimit = 16 * 1024 * 1024;

function quotePath(path: string): string {
	return /[\s"\\\x00-\x1f]/.test(path) ? JSON.stringify(path) : path;
}

function headers(path: string, oldExists = true, newExists = true, sourcePath = path): string {
	const oldPath = quotePath(`a/${sourcePath}`);
	const newPath = quotePath(`b/${path}`);
	let text = `diff --git ${oldPath} ${newPath}\n`;
	if (!oldExists) text += "new file mode 100644\n";
	if (!newExists) text += "deleted file mode 100644\n";
	if (sourcePath !== path) text += `rename from ${quotePath(sourcePath)}\nrename to ${quotePath(path)}\n`;
	return `${text}--- ${oldExists ? oldPath : "/dev/null"}\n+++ ${newExists ? newPath : "/dev/null"}\n`;
}

function snapshots(oldText: string | undefined, newText: string | undefined, path: string, sourcePath = path): string {
	if (oldText === undefined && newText === undefined) return "";
	if (oldText === newText && sourcePath === path) return "";
	const header = headers(path, oldText !== undefined, newText !== undefined, sourcePath);
	if (oldText?.includes("\0") || newText?.includes("\0")) {
		return `${header}Binary files ${oldText === undefined ? "/dev/null" : quotePath(`a/${sourcePath}`)} and ${newText === undefined ? "/dev/null" : quotePath(`b/${path}`)} differ\n`;
	}
	const hunks = structuredPatchHunks(oldText ?? "", newText ?? "", 3);
	return header + hunks.map(hunk =>
		`@@ -${hunk.oldStart},${hunk.oldLines} +${hunk.newStart},${hunk.newLines} @@\n${hunk.lines.join("\n")}\n`,
	).join("");
}

function isPatch(text: string): boolean {
	return /^(?:diff --(?:git|cc|combined) .+|--- .+\r?\n\+\+\+ .+)/m.test(text);
}

function compact(diff: string, path: string): string {
	if (isPatch(diff)) return diff;
	if (/^@@ -\d/m.test(diff)) return headers(path) + diff + (diff.endsWith("\n") ? "" : "\n");
	let offset = 0;
	let oldStart = 0;
	let newStart = 0;
	let oldCount = 0;
	let newCount = 0;
	let rows: string[] = [];
	const hunks: string[] = [];
	const close = () => {
		if (!rows.length) return;
		const oldLine = oldCount === 0 ? Math.max(0, oldStart - 1) : oldStart;
		const newLine = newCount === 0 ? Math.max(0, newStart - 1) : newStart;
		hunks.push(`@@ -${oldLine},${oldCount} +${newLine},${newCount} @@\n${rows.join("\n")}\n`);
		offset += newCount - oldCount;
		rows = [];
		oldCount = newCount = 0;
	};
	for (const line of diff.split("\n")) {
		// Canonical compact rows retain the literal source after the first '|'.
		const match = /^([ +\-])\s*(\d+)\|(.*)$/.exec(line) ?? /^([ +\-])\s*(\d+) (.*)$/.exec(line);
		if (!match) {
			if (line === "\\ No newline at end of file" && rows.length) rows.push(line);
			else close();
			continue;
		}
		const [, sign, number, content] = match;
		const n = Number(number);
		if (!rows.length) {
			oldStart = sign === "+" ? n - offset : n;
			newStart = sign === "+" ? n : n + offset;
		}
		rows.push(`${sign}${content}`);
		if (sign !== "+") oldCount++;
		if (sign !== "-") newCount++;
	}
	close();
	return hunks.length ? headers(path) + hunks.join("") : "";
}

function render(patch: string, width: number, cwd = Delta.cwd): readonly string[] {
	if (!patch || width < 1) return [];
	width = Math.floor(width);
	const key = `${cwd}\0${width}\0${patch}`;
	const hit = cache.get(key);
	if (hit) {
		cache.delete(key);
		cache.set(key, hit);
		return hit.lines;
	}
	const result = spawnSync("delta", [
		"--paging=never", `--width=${width}`, "--line-fill-method=spaces", "--detect-dark-light=never",
	], {
		cwd, input: patch, encoding: "utf8", timeout: 10_000, maxBuffer: 64 * 1024 * 1024,
		env: { ...process.env, COLUMNS: String(width) },
	});
	let output: string;
	if (result.error || result.status !== 0) {
		const reason = result.error?.message || result.stderr?.trim() || `exit ${result.status}`;
		output = `Delta rendering failed: ${reason}\n${patch}`;
	} else {
		output = result.stdout;
	}
	const lines = output.split("\n");
	if (lines.at(-1) === "") lines.pop();
	// Preserve Delta's SGR/OSC8 bytes. Clip only output wider than the host surface
	// (e.g. long file headings); never re-highlight, trim, or re-wrap diff rows.
	const safe = lines.map(line => visibleWidth(line) > width ? truncateToWidth(line, width, "") : line);
	const bytes = 2 * (key.length + output.length);
	if (bytes <= cacheLimit) {
		while (cacheBytes + bytes > cacheLimit && cache.size) {
			const first = cache.keys().next().value!;
			cacheBytes -= cache.get(first)!.bytes;
			cache.delete(first);
		}
		cache.set(key, { lines: safe, bytes });
		cacheBytes += bytes;
	}
	return safe;
}

export const Delta = {
	cwd: process.cwd(),
	render,
	compact,
	snapshots,
	isPatch,
	clear(): void {
		cache.clear();
		cacheBytes = 0;
	},
};
