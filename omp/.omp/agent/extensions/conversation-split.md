# Conversation split

User-level Pi TypeScript extension for OMP's row-rendered interactive TUI. Installed as `~/.omp/agent/extensions/conversation-split.ts`; OMP discovers it automatically on the next launch. Restart OMP and resume your session to load it. No config changes or dependency installation are required.

The split starts open on launch and when creating a new session, provided the terminal has at least 40 columns. You can still close it with Alt+Shift+M or `/conversation-split`. It initially creates equal-width panes separated by a draggable vertical divider:

- Left: the existing editor and status area, tool calls/results, thinking, errors, custom messages, and other non-conversation output, in transcript order.
- Right: user messages and assistant text, including live streaming updates, in conversation order. These messages are hidden from the left while the split is open.

Closing the split restores the normal full-width transcript and native terminal scrollback. This is display-only: persisted session messages and provider context are unchanged.

| Control | Action |
| --- | --- |
| Alt+Shift+M | Toggle the split |
| `/conversation-split` | Toggle using a slash command |
| Left-click and drag the divider | Resize the activity and conversation panes |
| Mouse wheel / trackpad over a pane | Scroll only the pane under the pointer |
| Alt+PageUp / Alt+PageDown | Scroll conversation history / toward the live tail |
| Alt+Shift+PageUp / Alt+Shift+PageDown | Scroll activity history / toward the live tail |

While split, scroll with the wheel/trackpad over the pane you want to browse, or use its pane-scrolling keys. Each pane keeps a separate scroll offset, and scrolling either leaves the other unchanged. Both are bounded views of the retained semantic transcript; native terminal scrollback is rebuilt when you close the split. The editor stays in the left pane while browsing history. Hold Shift while dragging for native text selection. Existing tool expansion controls still apply. Opening requires at least 40 terminal columns.

Drag the `│` separator with the left mouse button to resize both panes live; release to finish. Each pane keeps at least 20 columns when the terminal has room (the minimum adapts in smaller terminals). The chosen proportion survives terminal resizing and closing/reopening the split during the current OMP run; it is not saved across restarts. Wheel hit-testing follows the moved divider. Ordinary pane clicks, modified clicks, and native Shift-drag selection do not resize it; overlays retain pointer ownership.

## Compatibility and verification

Verified against the installed OMP **18.12.6** executable using a real PTY and an emulated terminal screen: resumed conversations, exact-once pane placement, tool/thinking order, hotkey and command toggles, 60/118/160-column resizes, long-history independent scrolling, live partial/final assistant updates, toggling during streaming, component metadata rerenders, and unchanged persisted message contents. Synthetic streaming components exercised the actual production renderer without making model requests.

Independent wheel up/down, keyboard scrolling, horizontal-wheel/divider/release handling, and overlay mouse ownership were verified in the real executable with long histories and with OMP's own mouse capture both enabled and disabled. Closing the split restores that original mouse-capture preference.

Draggable-divider verification on OMP **18.13.1** used the real executable in a PTY: live press/motion/release, final release position, minimum-width bounds, secondary/modified/off-divider gestures, lost-release recovery, keyboard cancellation, 160→120→40→160-column resizing, proportion retention across toggles, independent wheel scrolling against the moved boundary, overlay ownership, and absence of mouse-report text in the editor. Delta diffs reflowed in both resized panes.

OMP currently exposes no public extension API for transcript routing or side-by-side root layouts. The extension therefore adapts `Composer` frame methods, `TranscriptContainer.renderTail`, `AssistantMessageComponent.updateContent`, and TUI mouse-provider/input-listener registration, scoped to its owning TUI. Recheck compatibility after upgrading OMP. RPC/headless and native semantic terminal surfaces are not supported by this panel.

## Delta diffs in both panes

`~/.omp/agent/extensions/delta-diffs/index.ts` is a separate, auto-discovered extension. Restart OMP and resume the session to activate it. It runs the installed `delta` executable with your Git configuration at the actual available pane width; it does not imitate Delta with OMP theme colors. Paging and terminal probing are disabled, and backgrounds use spaces so one pane cannot erase the other. Git configuration is not modified.

Coverage: edit/apply-patch previews and results (including multiple files), local write before/after diffs, patch-bearing built-in tool output, and Markdown diff/patch fences. Existing tool headers, errors and diagnostics remain. Expand tool results to see all rows. Write snapshots are captured only when the local before/after contents are available; historical writes without snapshots cannot be reconstructed. New write results retain their patch in display metadata, without altering model-facing result text.

Use `/delta-refresh` after changing Delta/Git styling to clear the rendering cache. The extension includes the pinned `marked` lexer dependency because OMP's lexer expands tabs before rendering; Delta must receive the original tabs.

The interactive Git/staging viewer is deliberately unchanged. Native Tern surfaces and arbitrary custom tool-renderer overrides are not intercepted. These adapters use OMP's internal renderer registry and public component prototypes; rerun `delta-diffs/test/verify.ts` with the command in its header after upgrading OMP.

Verified with OMP **18.13.1** and Delta **0.18.2**: strict TypeScript checking; direct Delta ANSI parity at 40/80/120/180 columns; edit, multi-file, streaming, read, bash and write scenarios; closed/open/quoted Markdown fences; tab preservation; partial, binary and combined patches; repository-local styling; explicit rendering failures. A real PTY verified automatic loading, both conversation-split panes, 160→120-column resizing, full-width toggling and `/delta-refresh`, without model requests.
