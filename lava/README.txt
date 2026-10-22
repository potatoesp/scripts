LAVA (getlava) — The Chosen One — local build
================================================
1. Extract this whole "lava" folder into your executor's WORKSPACE folder
   so that this file exists:  workspace/lava/src/games/tco.luau
2. In The Chosen One, run:
       loadstring(readfile("lava/loader.lua"))()
3. A small status window shows each step. If anything fails it turns red,
   shows the stage + error, has a "Copy log" button, and writes
   workspace/lava/last_error.txt. Send me that log.
Menu key: RightShift.

The original source files are untouched. loader.lua patches them in memory
(dead example.invalid URLs, leftover renamed helpers, out-of-scope locals).

Known limits (not fixable from the open-source drop):
 - Bots tab: needs Lava's private relay (ctx.relayReady) -> stays disabled.
 - "Auto Execute on Hop": needs a hosted URL -> does nothing.
 - Update log / Discord links: point to dead services.
 - Community Builds browser: its backend was never published.
 - Private TCO vault features were removed by the authors.
