// Run with the installed host, not a second copy of its TUI/native modules:
// omp --trusted-extension "$HOME/.omp/agent/extensions/delta-diffs/test/verify.ts" \
//   --no-session --no-skills --no-rules --no-context-files --no-lsp --no-title --mode rpc </dev/null
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import "../index";
import { Delta } from "../delta";
import { getPaddingX, Markdown, truncateToWidth, visibleWidth } from "@oh-my-pi/pi-tui";
import { ensureThemeSync, getMarkdownTheme } from "@oh-my-pi/pi-tui/theme";
import { ToolExecutionComponent } from "@oh-my-pi/pi-tui/chat/tool-execution";

export default function verifyDeltaDiffs(): void {
	ensureThemeSync();
	const oldText = "\tconst count = 1;\n";
	const newText = "\tconst count = 2;\n";
	const patch = Delta.snapshots(oldText, newText, "tabs.ts");
	for (const width of [40, 80, 120, 180]) {
		const direct = spawnSync("delta", ["--paging=never", `--width=${width}`, "--line-fill-method=spaces", "--detect-dark-light=never"], {
			input: patch, cwd: Delta.cwd, encoding: "utf8", env: { ...process.env, COLUMNS: String(width) },
		});
		assert.equal(direct.status, 0, direct.stderr);
		const expected = direct.stdout.split("\n");
		if (expected.at(-1) === "") expected.pop();
		assert.deepEqual(Delta.render(patch, width), expected.map(row => visibleWidth(row) > width ? truncateToWidth(row, width, "") : row));
	}
	const compact = Delta.compact(" 10|before\n+11|inserted\n 11|after\n\n-30|removed\n 31|kept", "file.ts");
	assert.match(compact, /@@ -10,2 \+10,3 @@/);
	assert.match(compact, /@@ -30,2 \+31,1 @@/);
	assert.match(Delta.compact("+1|new", "file.ts"), /@@ -0,0 \+1,1 @@/);
	assert.match(Delta.compact("-1|old", "file.ts"), /@@ -1,1 \+0,0 @@/);
	assert.match(Delta.snapshots(undefined, "", "empty.txt"), /new file mode/);
	assert.match(Delta.snapshots("", undefined, "empty.txt"), /deleted file mode/);
	assert.equal(Delta.snapshots("same", "same", "same.txt"), "");
	assert.match(Delta.snapshots("before", "after", "file.txt"), /\\ No newline at end of file/);
	assert.match(Delta.snapshots("same", "same", "new.ts", "old.ts"), /rename from old.ts\nrename to new.ts/);
	assert.match(Delta.snapshots("a\0b", "a\0c", "binary.bin"), /Binary files/);

	for (const indent of [0, 2]) for (const padding of [0, 1]) for (const width of [40, 80, 120]) {
		const source = `Before\n\n\`\`\`diff\n${patch}\`\`\`\n\nAfter`;
		const md = new Markdown(source, padding, 0, getMarkdownTheme(), undefined, indent);
		const rendered = md.render(width);
		const plain = rendered.map(row => Bun.stripANSI(row));
		assert.equal(plain.filter(row => /^\s*```(?:diff)?\s*$/.test(row)).length, 2, "blank Delta rows must not duplicate Markdown fences");
		assert.ok(rendered.every(row => visibleWidth(row) <= width));
		const available = indent === 0 ? width : width - 2 * getPaddingX(padding) - indent;
		for (const row of Delta.render(patch, available).filter(line => Bun.stripANSI(line).trim())) {
			assert.ok(rendered.some(line => line.includes(row)), "Markdown must preserve Delta's configured tabs and ANSI bytes");
		}
	}

	const ui = { requestRender() {}, requestComponentRender() {}, resetDisplay() {} };
	const edit = new ToolExecutionComponent("edit", { path: "tabs.ts" }, {}, undefined, ui);
	edit.updateResult({ content: [{ type: "text", text: "updated" }], details: {
		path: "tabs.ts", diff: "-1|\tconst count = 1;\n+1|\tconst count = 2;", oldText, newText,
		diagnostics: { messages: ["tabs.ts: warning: retained diagnostic"], summary: "1 warning", errored: false },
	} });
	edit.setExpanded(true);
	const rendered = edit.render(120);
	assert.match(Bun.stripANSI(rendered.join("\n")), /retained diagnostic/);
	for (const row of Delta.render(patch, 118).filter(line => Bun.stripANSI(line).includes("const count"))) {
		assert.ok(rendered.some(line => line.includes(row)), "card backgrounds must not rewrite Delta resets");
	}
	for (const text of [
		patch.slice(0, patch.indexOf("+\tconst")),
		"diff --git a/a.bin b/a.bin\nindex 123..456 100644\nBinary files a/a.bin and b/a.bin differ\n",
		"diff --cc test.ts\nindex 123,456..789\n--- a/test.ts\n+++ b/test.ts\n@@@ -1,1 -1,1 +1,1 @@@\n--const old = 1;\n++const next = 2;\n",
		`Before output\n${patch}${Delta.snapshots("x\n", "y\n", "second.txt")}After output\n`,
	]) {
		const component = new ToolExecutionComponent("bash", { command: "git diff" }, {}, undefined, ui);
		component.updateResult({ content: [{ type: "text", text }], details: { exitCode: 0 } });
		component.setExpanded(true);
		const actual = component.render(120);
		for (const row of Delta.render(text, 116).filter(line => Bun.stripANSI(line).trim())) {
			assert.ok(actual.some(line => line.includes(row)), "all patch formats must retain Delta's ANSI output");
		}
	}

	const previousCwd = Delta.cwd;
	const repo = mkdtempSync(join(tmpdir(), "omp-delta-verify-"));
	try {
		for (const args of [["init", "--quiet", repo], ["-C", repo, "config", "delta.side-by-side", "false"], ["-C", repo, "config", "delta.true-color", "always"], ["-C", repo, "config", "delta.plus-style", 'syntax "#123456"']]) {
			assert.equal(spawnSync("git", args).status, 0);
		}
		Delta.cwd = repo;
		Delta.clear();
		const custom = Delta.render(patch, 120);
		assert.ok(custom.some(line => line.includes("48;2;18;52;86")), "repository Delta colors must win");
		assert.ok(!custom.map(line => Bun.stripANSI(line)).some(line => line.includes("count = 1") && line.includes("count = 2")), "repository layout must win");
		const failure = Delta.render(patch, 120, join(repo, "missing"));
		assert.match(failure[0], /Delta rendering failed/);
		assert.ok(failure.some(line => line.includes("-\tconst count")), "render failures must not hide the patch");
	} finally {
		Delta.cwd = previousCwd;
		Delta.clear();
		rmSync(repo, { recursive: true, force: true });
	}
	console.log("Delta diff verification passed: byte parity, compact hunks, snapshots, Markdown, tool framing, Git configuration, errors.");
}
