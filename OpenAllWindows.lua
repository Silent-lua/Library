-- SilentHub multi-window shell.
-- UI-only scaffold: interactive placeholders, no game feature logic.
-- Requires executor support for game:HttpGet and loadstring.

local CACHE = "SilentUI"
local CACHE_FILE = CACHE .. "/SilentHub.lua"
local LIBRARY_URL = "https://raw.githubusercontent.com/Silent-lua/Library/main/SilentHub.lua"

local function ensureCache()
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local ok, exists = pcall(isfolder, CACHE)
        if ok and not exists then pcall(makefolder, CACHE) end
    end
end

local function loadLibrary()
    local source
    local downloadOk, downloaded = pcall(function() return game:HttpGet(LIBRARY_URL) end)

    -- Check the published version first so an older cached copy cannot mask updates.
    if downloadOk and type(downloaded) == "string" and #downloaded > 0 then
        source = downloaded
        ensureCache()
        if type(writefile) == "function" then pcall(writefile, CACHE_FILE, source) end
    elseif type(isfile) == "function" and type(readfile) == "function" then
        -- Offline fallback: reuse the last successfully cached library.
        local ok, exists = pcall(isfile, CACHE_FILE)
        if ok and exists then
            local readOk, cached = pcall(readfile, CACHE_FILE)
            if readOk and type(cached) == "string" and #cached > 0 then source = cached end
        end
    end

    if not source then
        error("SilentHub download failed and no cached copy is available: " .. tostring(downloaded))
    end

    if type(loadstring) ~= "function" then error("loadstring is not available in this environment.") end
    local compileOk, chunk = pcall(loadstring, source)
    if not compileOk or type(chunk) ~= "function" then error("SilentHub compile failed: " .. tostring(chunk)) end
    local runOk, library = pcall(chunk)
    if not runOk or type(library) ~= "table" then error("SilentHub init failed: " .. tostring(library)) end
    return library
end

local Library = loadLibrary()
if type(Library.Window) ~= "function" then error("SilentHub.Window() is missing.") end

-- All per-window presentation options are supplied at creation time.
-- Set CUSTOM_LOGO to an asset ID to replace the default for these windows.
-- Leave it nil to use the library's default logo.
local CUSTOM_LOGO = nil -- Example: "rbxassetid://1234567890"

local function createWindow(options)
    options.Logo = options.Logo or CUSTOM_LOGO
    options.Loading = false
    options.ConfigurationSaving = { Enabled = false }
    return Library:Window(options)
end

local main = createWindow({
    Name = "MainWindow",
    Title = "SilentHub",
    SubTitle = "Multi-window UI shell",
    Logo = CUSTOM_LOGO,
    Size = UDim2.fromOffset(760, 560),
    MinSize = Vector2.new(480, 360),
    MaxSize = Vector2.new(900, 700),
    Keybind = Enum.KeyCode.RightControl,
})
local loader = createWindow({
    Name = "LoaderWindow",
    Title = "Loader",
    SubTitle = "Placeholder interface",
    Logo = CUSTOM_LOGO,
    Size = UDim2.fromOffset(340, 250),
    MinSize = Vector2.new(280, 210),
    MaxSize = Vector2.new(560, 420),
    Keybind = Enum.KeyCode.RightShift,
})
local skins = createWindow({
    Name = "SkinsWindow",
    Title = "Skins",
    SubTitle = "Placeholder interface",
    Logo = CUSTOM_LOGO,
    Size = UDim2.fromOffset(420, 320),
    MinSize = Vector2.new(300, 230),
    MaxSize = Vector2.new(680, 500),
    Keybind = Enum.KeyCode.LeftAlt,
})
local accessories = createWindow({
    Name = "AccessoriesWindow",
    Title = "Accessories",
    SubTitle = "Placeholder interface",
    Logo = CUSTOM_LOGO,
    Size = UDim2.fromOffset(420, 320),
    MinSize = Vector2.new(300, 230),
    MaxSize = Vector2.new(680, 500),
    Keybind = Enum.KeyCode.Home,
})

-- Main panel: status, dialogs and window management.
local overview = main:Tab({ Name = "Overview", Icon = "house", Desc = "UI scaffold overview" })
overview:Section("Status")
overview:Paragraph({ Name = "UI shell is ready", Content = "All four windows are open. Controls are interactive placeholders; no game features are connected." })
local status = overview:Label({ Text = "Status: idle" })
overview:Button({ Name = "Test notification", Icon = "bell", Callback = function()
    main:Notify({ Title = "SilentHub", Content = "Notification component is responding.", Type = "Success", Duration = 3 })
end })
overview:Button({ Name = "Test dialog", Icon = "message-square", Callback = function()
    main:Dialog({ Title = "Placeholder dialog", Content = "UI test only. No game action will be performed.", Icon = "info",
        Buttons = { { Title = "Close", Variant = "Primary" } } })
end })

local manager = main:Tab({ Name = "Windows", Icon = "panels-top-left", Desc = "Independent visibility controls" })
manager:Section("Visibility")
manager:Button({ Name = "Show all windows", Icon = "eye", Callback = function()
    main:Toggle(true); loader:Toggle(true); skins:Toggle(true); accessories:Toggle(true)
    status:Set("Status: all windows shown")
end })
manager:Button({ Name = "Hide loader", Icon = "eye-off", Callback = function()
    loader:Toggle(false); status:Set("Status: loader hidden")
end })
manager:Button({ Name = "Hide skins", Icon = "eye-off", Callback = function()
    skins:Toggle(false); status:Set("Status: skins hidden")
end })
manager:Button({ Name = "Hide accessories", Icon = "eye-off", Callback = function()
    accessories:Toggle(false); status:Set("Status: accessories hidden")
end })

-- Loader panel: simulated progress only.
local loaderTab = loader:Tab({ Name = "Loader", Icon = "package-open", Desc = "Visual loading placeholders" })
loaderTab:Section("Simulation")
local loaderStatus = loaderTab:Label({ Text = "Status: waiting" })
local progress = loaderTab:Progress({ Name = "Progress", Default = 0 })
local progressValue = 0
loaderTab:Button({ Name = "Advance progress", Icon = "play", Callback = function()
    progressValue = math.min(progressValue + 0.2, 1)
    progress:Set(progressValue)
    loaderStatus:Set(progressValue >= 1 and "Status: placeholder complete" or "Status: simulated progress")
end })
loaderTab:Button({ Name = "Reset progress", Icon = "rotate-ccw", Callback = function()
    progressValue = 0; progress:Set(0); loaderStatus:Set("Status: waiting")
end })
loaderTab:Paragraph({ Name = "No loader backend", Content = "This panel does not download, execute or initialize game features." })

-- Skins panel: dropdown and color picker only; no character changes.
local skinsTab = skins:Tab({ Name = "Catalog", Icon = "palette", Desc = "Skin UI placeholders" })
skinsTab:Section("Preview")
local selectedSkin = "Default"
skinsTab:Dropdown({ Name = "Preset", Options = { "Default", "Preset A", "Preset B", "Preset C" }, Default = selectedSkin,
    Callback = function(value)
        selectedSkin = value
        skins:Notify({ Title = "Selection changed", Content = "Selected: " .. tostring(value), Duration = 2 })
    end })
skinsTab:ColorPicker({ Name = "Preview color", Default = Color3.fromRGB(235, 199, 246), Callback = function() end })
skinsTab:Button({ Name = "Preview selection", Icon = "eye", Callback = function()
    skins:Notify({ Title = "Preview only", Content = "Preset: " .. tostring(selectedSkin), Duration = 3 })
end })

-- Accessories panel: slot and local toggle only; no accessories are modified.
local accessoriesTab = accessories:Tab({ Name = "Accessories", Icon = "shapes", Desc = "Accessory UI placeholders" })
accessoriesTab:Section("Configuration")
local selectedSlot = "Head"
accessoriesTab:Dropdown({ Name = "Slot", Options = { "Head", "Face", "Back", "Shoulder", "Waist" }, Default = selectedSlot,
    Callback = function(value) selectedSlot = value end })
accessoriesTab:Toggle({ Name = "Preview enabled", Desc = "Local UI state only", Default = false,
    Callback = function(enabled)
        accessories:Notify({ Title = "Preview state", Content = selectedSlot .. ": " .. (enabled and "enabled" or "disabled"), Duration = 2 })
    end })
accessoriesTab:Button({ Name = "Test selection", Icon = "check", Callback = function()
    accessories:Notify({ Title = "Placeholder", Content = "Selected slot: " .. selectedSlot, Duration = 3 })
end })
accessoriesTab:Paragraph({ Name = "No accessory backend", Content = "This panel does not equip, remove, clone or modify accessories." })

-- Desktop: four-panel layout. Narrow screens: a cascade with all panels clamped.
local windows = { main, loader, skins, accessories }
local function clamp(value, low, high) return math.max(low, math.min(value, high)) end
local function place(window, targetX, targetY)
    local screen = window.Gui.AbsoluteSize
    if screen.X <= 0 or screen.Y <= 0 then return end

    -- The library owns UIScale. Do not override Scale here; doing so would
    -- desynchronize its cached fit factor when the window is shown again.
    local half = window.Root.AbsoluteSize / 2 + Vector2.new(44, 44)
    local minX, maxX = half.X, screen.X - half.X
    local minY, maxY = half.Y, screen.Y - half.Y
    local x = maxX < minX and screen.X / 2 or clamp(targetX, minX, maxX)
    local y = maxY < minY and screen.Y / 2 or clamp(targetY, minY, maxY)
    window.Root.Position = UDim2.fromOffset(x, y)
end

task.spawn(function()
    task.wait(0.65) -- allow the library intro to finish before repositioning roots
    for index, window in ipairs(windows) do
        if window.Gui and window.Gui.Parent and window.Root and window.Root.Parent then
            local viewport = window.Gui.AbsoluteSize
            if viewport.X >= 1100 and viewport.Y >= 760 then
                local targets = {
                    { viewport.X * 0.27, viewport.Y * 0.27 },
                    { viewport.X * 0.75, viewport.Y * 0.25 },
                    { viewport.X * 0.27, viewport.Y * 0.75 },
                    { viewport.X * 0.75, viewport.Y * 0.75 },
                }
                place(window, targets[index][1], targets[index][2])
            else
                local offsets = { { -36, -30 }, { 36, -10 }, { -18, 22 }, { 42, 46 } }
                place(window, viewport.X / 2 + offsets[index][1], viewport.Y / 2 + offsets[index][2])
            end
            if window.OpenButton then
                window.OpenButton.AnchorPoint = Vector2.new(0, 0)
                window.OpenButton.Position = UDim2.fromOffset(12, 12 + (index - 1) * 46)
            end
        end
    end
end)

main:Notify({ Title = "SilentHub shell loaded", Content = "Main, Loader, Skins and Accessories are open. Feature logic is intentionally empty.", Type = "Success", Duration = 4 })
