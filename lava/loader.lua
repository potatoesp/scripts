-- Lava (getlava) TCO — local loader with status / error UI
-- Put the whole "lava" folder inside your executor's workspace folder, then run:
--   loadstring(readfile("lava/loader.lua"))()
local ROOT = "lava"
local env = getgenv and getgenv() or _G
local Players = game:GetService("Players")

-- ───────────── status / error UI ─────────────
local gui, listBox, titleLabel, copyBtn
local lines = {}
local function mountGui()
	local ok = pcall(function()
		gui = Instance.new("ScreenGui")
		gui.Name = "LavaLoaderStatus"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 2147483647
		local parent = (gethui and gethui()) or game:GetService("CoreGui")
		gui.Parent = parent
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(460, 260)
		frame.Position = UDim2.new(0.5, -230, 0.5, -130)
		frame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.Draggable = true
		frame.Parent = gui
		titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -90, 0, 28)
		titleLabel.Position = UDim2.fromOffset(10, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = Color3.fromRGB(255, 120, 60)
		titleLabel.Text = "Lava loader"
		titleLabel.Parent = frame
		copyBtn = Instance.new("TextButton")
		copyBtn.Size = UDim2.fromOffset(70, 20)
		copyBtn.Position = UDim2.new(1, -80, 0, 4)
		copyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		copyBtn.BorderSizePixel = 0
		copyBtn.Font = Enum.Font.Gotham
		copyBtn.TextSize = 12
		copyBtn.TextColor3 = Color3.new(1, 1, 1)
		copyBtn.Text = "Copy log"
		copyBtn.Parent = frame
		listBox = Instance.new("ScrollingFrame")
		listBox.Size = UDim2.new(1, -20, 1, -40)
		listBox.Position = UDim2.fromOffset(10, 32)
		listBox.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
		listBox.BorderSizePixel = 0
		listBox.CanvasSize = UDim2.new()
		listBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
		listBox.ScrollBarThickness = 4
		listBox.Parent = frame
		local text = Instance.new("TextLabel")
		text.Name = "Log"
		text.Size = UDim2.new(1, -8, 0, 0)
		text.AutomaticSize = Enum.AutomaticSize.Y
		text.Position = UDim2.fromOffset(4, 2)
		text.BackgroundTransparency = 1
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextYAlignment = Enum.TextYAlignment.Top
		text.TextWrapped = true
		text.Font = Enum.Font.Code
		text.TextSize = 12
		text.TextColor3 = Color3.fromRGB(215, 215, 220)
		text.Text = ""
		text.Parent = listBox
		copyBtn.MouseButton1Click:Connect(function()
			if setclipboard then setclipboard(table.concat(lines, "\n")) end
			copyBtn.Text = "Copied"
		end)
	end)
	return ok
end

local function refresh()
	if listBox and listBox:FindFirstChild("Log") then
		listBox.Log.Text = table.concat(lines, "\n")
		listBox.CanvasPosition = Vector2.new(0, 1e6)
	end
end
local function log(msg)
	lines[#lines + 1] = tostring(msg)
	refresh()
end
local function fail(stage, err)
	err = tostring(err)
	log("")
	log("✗ FAILED at: " .. stage)
	log(err)
	if titleLabel then
		titleLabel.Text = "Lava loader — FAILED"
		titleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
	pcall(function()
		if writefile then writefile(ROOT .. "/last_error.txt", table.concat(lines, "\n")) end
	end)
	error("[lava loader] " .. stage .. ": " .. err, 0)
end

mountGui()
log("Lava loader — The Chosen One")

-- ───────────── environment check ─────────────
if type(readfile) ~= "function" or type(loadstring) ~= "function" then
	fail("environment", "executor is missing readfile() or loadstring()")
end
if type(request) ~= "function" and type(http_request) ~= "function" and not (syn and syn.request) then
	log("! no request()/http_request() — server list and icons may fail")
end
if type(isfile) ~= "function" or not isfile(ROOT .. "/src/games/tco.luau") then
	fail("files", "workspace/" .. ROOT .. "/src/games/tco.luau not found. Extract the whole 'lava' folder into your executor workspace.")
end

-- ───────────── patches (literal find → replace) ─────────────
local OBSIDIAN = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local LUCIDE = "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"
local SERVERS = "https://games.roblox.com/v1/games/"
local TRANSLATE = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl="

local PATCHES = {
	["src/shared/library.luau"] = {
		{ 'local BaseURL = "https://example.invalid"', 'local BaseURL = "' .. OBSIDIAN .. '"', 1 },
		{ 'loadstring(game:HttpGet("https://example.invalid"))', 'loadstring(game:HttpGet("' .. LUCIDE .. '"))', 1 },
	},
	["src/shared/workspace-tools.luau"] = {
		{
			'string.format("https://example.invalid", tostring(game.PlaceId))',
			'string.format("' .. SERVERS .. '%s/servers/Public?sortOrder=Asc&limit=100", tostring(game.PlaceId))',
			1,
		},
	},
	["src/games/tco.luau"] = {
		{ '"https://example.invalid" .. game.PlaceId', '"' .. SERVERS .. '" .. game.PlaceId', 2 },
		-- chat-spy helpers are declared `local` inside one block but used again in a later block (nil at runtime) → make them shared
		{ 'local namecolorshex = {}', 'namecolorshex = {}', 1 },
		{ 'local chatSpySeenMessages = {}', 'chatSpySeenMessages = {}', 1 },
		{ 'local function escapeRichText(str)', 'function escapeRichText(str)', 1 },
		{ 'local function getChatSpyMeta(messagePlayer, rawText)', 'function getChatSpyMeta(messagePlayer, rawText)', 1 },
		{ 'local function _disconnectTouchFlingPartConns()', 'function _disconnectTouchFlingPartConns()', 1 },
		{ '__PW_makeDraggable(', '__getlava_makeDraggable(', 1 },
		{ '__PW_libCreate(', '__getlava_libCreate(', 2 },
		{ 'local url = "https://example.invalid"\n\t\t\t\t.. HttpService:UrlEncode(targetCode)', 'local url = "' .. TRANSLATE .. '"\n\t\t\t\t.. HttpService:UrlEncode(targetCode)', 1 },
	},
}

local function plainReplace(s, find, rep)
	local count, out, init = 0, {}, 1
	while true do
		local a, b = string.find(s, find, init, true)
		if not a then break end
		out[#out + 1] = string.sub(s, init, a - 1)
		out[#out + 1] = rep
		init = b + 1
		count += 1
	end
	out[#out + 1] = string.sub(s, init)
	return table.concat(out), count
end

local function loadPatched(rel, stage)
	local ok, src = pcall(readfile, ROOT .. "/" .. rel)
	if not ok or type(src) ~= "string" or #src == 0 then
		fail(stage, "cannot read " .. rel .. " (" .. tostring(src) .. ")")
	end
	local applied = 0
	for _, p in ipairs(PATCHES[rel] or {}) do
		local n
		src, n = plainReplace(src, p[1], p[2])
		if n ~= p[3] then
			log(("! patch drift in %s: expected %d hit(s), got %d for %q"):format(rel, p[3], n, p[1]:sub(1, 40)))
		end
		applied += n
	end
	log(("✓ read %s (%d patches)"):format(rel, applied))
	local fn, err = loadstring(src, "=" .. rel)
	if not fn then fail(stage, "compile error in " .. rel .. ": " .. tostring(err)) end
	return fn
end

-- ───────────── shims for helpers the OSS drop lost ─────────────
if type(env.getwc) ~= "function" then
	-- whisper TextChannel lookup used by sayto() for non-self targets
	env.getwc = function(a, b)
		local ok, ch = pcall(function()
			local tcs = game:GetService("TextChatService"):FindFirstChild("TextChannels")
			if not tcs then return nil end
			local x, y = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
			return tcs:FindFirstChild("RBXWhisper:" .. x .. "_" .. y) or tcs:FindFirstChild("RBXWhisper:" .. y .. "_" .. x)
		end)
		return ok and ch or nil
	end
end
env.getlava_bot_only = nil

-- ───────────── load modules, hand them to tco.luau ─────────────
local MODULES = {
	{ "src/shared/library.luau", "library" },
	{ "src/shared/theme-manager.luau", "theme_manager" },
	{ "src/shared/save-manager.luau", "save_manager" },
	{ "src/shared/workspace-tools.luau", "workspace_tools" },
	{ "src/games/tco-bots.luau", "tco_bots" },
}
for _, m in ipairs(MODULES) do
	env["__getlava_" .. m[2] .. "_test_module"] = nil
end
-- ThemeManager / SaveManager expect the library to be provided first; tco.luau wires them itself.
for _, m in ipairs(MODULES) do
	local fn = loadPatched(m[1], "load " .. m[2])
	local ok, mod = xpcall(fn, function(e) return tostring(e) .. "\n" .. debug.traceback("", 2) end)
	if not ok then fail("run " .. m[2], mod) end
	if type(mod) ~= "table" then fail("run " .. m[2], "returned " .. type(mod) .. " instead of a module table") end
	env["__getlava_" .. m[2] .. "_test_module"] = mod
	log("✓ module " .. m[2])
end

-- ───────────── run the TCO script ─────────────
log("Starting TCO script…")
local tco = loadPatched("src/games/tco.luau", "load tco")
local ok, err = xpcall(tco, function(e) return tostring(e) .. "\n" .. debug.traceback("", 2) end)
if not ok then fail("run tco", err) end

log("✓ TCO script returned — RightShift toggles the menu")
if titleLabel then titleLabel.Text = "Lava loader — OK" end
task.delay(4, function()
	if gui then pcall(function() gui:Destroy() end) end
end)
