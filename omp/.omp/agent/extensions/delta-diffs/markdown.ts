import {
	getPaddingX,
	Markdown,
	sliceWithWidth,
	visibleWidth,
	type DescribeContext,
} from "@oh-my-pi/pi-tui";
import { Lexer, type Token } from "marked";
import { Delta } from "./delta";

type Fence = {
	lang: string;
	text: string;
	diff: boolean;
};

type Span = {
	open: number;
	close: number;
	prefixWidth: number;
};

type CachedRender = {
	source: string;
	width: number;
	cwd: string;
	native: readonly string[];
	lines: readonly string[];
};

const installed = Symbol.for("omp.delta-diffs.markdown");
const cache = new WeakMap<Markdown, CachedRender>();
const describeContext: DescribeContext = {
	cols: 80,
	reduceMotion: true,
	dark: true,
	supports: () => false,
	feature: () => false,
};

function fences(tokens: readonly Token[], result: Fence[] = []): Fence[] {
	for (const token of tokens) {
		if (token.type === "code") {
			const lang = token.lang ?? "";
			result.push({ lang, text: token.text, diff: /^(?:diff|patch|udiff|unified-diff)(?:\s|$)/i.test(lang) });
		} else if (token.type === "list") {
			for (const item of token.items) fences(item.tokens, result);
		} else if (token.type === "blockquote") {
			fences(token.tokens ?? [], result);
		}
	}
	return result;
}

/**
 * Locate a source code token in the unmodified renderer's rows. Comparing the
 * complete body, not just fence-looking rows, distinguishes literal fences
 * inside longer fences and protects prose/other code from accidental splices.
 * Wrapping, syntax ANSI, margins and hanging indentation do not change that
 * comparison. The actual lexer supplies nested/list and still-open fences.
 */
function findSpan(
	rows: readonly string[],
	fence: Fence,
	from: number,
	literal: boolean,
): Span | undefined {
	const opening = `\`\`\`${fence.lang}`;
	const expected = fence.text.replace(/\s/g, "");
	for (let open = from; open < rows.length; open++) {
		const row = rows[open].trimEnd();
		if (!row.endsWith(opening)) continue;
		const prefix = row.slice(0, -opening.length);
		if (prefix.includes("`")) continue;
		const prefixWidth = visibleWidth(prefix);
		// First-line list bullets become spaces on subsequent rows. The
		// closing border supplies the real continuation/blockquote prefix.
		for (let close = open + 1; close < rows.length; close++) {
			const end = rows[close].trimEnd();
			if (!end.endsWith("```")) continue;
			const continuation = end.slice(0, -3);
			if (visibleWidth(continuation) !== prefixWidth) continue;
			let body = "";
			for (let i = open + 1; i < close; i++) {
				const line = rows[i];
				if (!literal && !line.startsWith(continuation)) {
					body = "\u0000";
					break;
				}
				body += (literal ? line : line.slice(continuation.length)).replace(/\s/g, "");
			}
			if (body === expected) return { open, close, prefixWidth: literal ? 0 : prefixWidth };
		}
	}
	return undefined;
}

/**
 * ANSI-chat adapter only: native Tern consumes describe() instead of render()
 * and intentionally retains its original Markdown node. Neither source text,
 * stored messages, the theme, nor the component's streaming state is mutated.
 */
export function installMarkdownDiffs(): void {
	const prototype = Markdown.prototype as Markdown & { [installed]?: boolean };
	if (prototype[installed]) return;
	const render = prototype.render;
	prototype.render = function (width: number): readonly string[] {
		const native = render.call(this, width);
		const node = this.describe({ ...describeContext, cols: width });
		if (node.k !== "md" || typeof node.p?.text !== "string") return native;
		const source = node.p.text;
		const previous = cache.get(this);
		if (previous?.native === native && previous.source === source && previous.width === width && previous.cwd === Delta.cwd) {
			return previous.lines;
		}

		let lines: readonly string[] = native;
		// Avoid lexing the overwhelmingly common prose/non-diff case.
		if (/(?:`{3,}|~{3,})[ \t]*(?:diff|patch|udiff|unified-diff)(?:\s|$)/i.test(source)) {
			// OMP's lexer expands every tab before tokenization. Use the raw
			// upstream block lexer so Delta receives the original source bytes.
			const blocks = fences(new Lexer().blockTokens(source));
			if (blocks.some(block => block.diff)) {
				const layout = this.debugState();
				const indent = typeof layout.codeBlockIndent === "number" ? layout.codeBlockIndent : 2;
				const basePadding = typeof layout.paddingX === "number" ? layout.paddingX : 0;
				const paddingX = layout.ignoreTight ? basePadding : getPaddingX(basePadding);
				const plain = native.map(line => Bun.stripANSI(line));
				const output: string[] = [];
				let cursor = 0;
				let copied = 0;
				let unmapped = false;
				for (const block of blocks) {
					const span = findSpan(plain, block, cursor, indent === 0);
					if (!span) {
						// Mermaid/other theme-resolved blocks need not have code
						// borders at all. A diff that cannot be mapped is reported,
						// rather than guessing and deleting neighboring content.
						if (block.diff) unmapped = true;
						continue;
					}
					cursor = span.close + 1;
					if (!block.diff) continue;
					const leftWidth = span.prefixWidth + indent;
					const rightWidth = indent === 0 ? 0 : paddingX;
					const available = width - leftWidth - rightWidth;
					if (available < 1) {
						unmapped = true;
						continue;
					}
					for (let i = copied; i <= span.open; i++) output.push(native[i]);
					const border = native[span.close];
					const prefix = span.prefixWidth === 0 ? "" : sliceWithWidth(border, 0, span.prefixWidth).text;
					for (const deltaLine of Delta.render(block.text, available)) {
						const remaining = Math.max(0, width - leftWidth - visibleWidth(deltaLine));
						const suffix = " ".repeat(remaining);
						output.push(`${prefix}${" ".repeat(indent)}\x1b[0m${deltaLine}\x1b[0m${suffix}`);
					}
					copied = span.close;
				}
				for (let i = copied; i < native.length; i++) output.push(native[i]);
				if (unmapped) {
					// Keep the original rows intact on an unsupported custom theme
					// or a width too small to expose intact fence borders.
					const warning = "[delta-diffs: cannot locate fenced diff at this width/theme; original rows retained]";
					for (let start = 0; start < warning.length; start += Math.max(1, width)) {
						output.push(`\x1b[31m${warning.slice(start, start + Math.max(1, width))}\x1b[0m`);
					}
				}
				lines = output;
			}
		}
		cache.set(this, { source, width, cwd: Delta.cwd, native, lines });
		return lines;
	};
	Object.defineProperty(prototype, installed, { value: true });
}
