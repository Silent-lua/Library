-- SilentHub unified loader.
-- The main window is the script hub; child panels start hidden and are toggled individually.
-- Requires executor support for game:HttpGet and loadstring.

local CACHE = "SilentUI"
local CACHE_FILE = CACHE .. "/SilentHub.lua"
local LIBRARY_URL = "https://raw.githubusercontent.com/Silent-lua/Library/main/SilentHub.lua"

-- Optional shared background: numeric asset ID, rbxassetid:// URI, or direct image URL.
-- URL backgrounds additionally require writefile and getcustomasset/getsynasset in the executor.
local SHARED_BACKGROUND_IMAGE = nil
local BACKGROUND_IMAGE_TRANSPARENCY = 0.24
local CUSTOM_LOGO = nil -- Example: "rbxassetid://1234567890"

-- Add trusted scripts here. Only scripts with a URL get a Run button.
-- Category must be "Official", "Collaborators", or "Recommendations".
local SCRIPT_CATALOG = {
    -- { Name = "Example script", Author = "Collaborator", Description = "Description", Url = "https://raw.githubusercontent.com/user/repo/main/script.lua", Category = "Collaborators" },
    -- { Name = "Recommended utility", Author = "Community", Description = "Description", Url = "https://raw.githubusercontent.com/user/repo/main/utility.lua", Category = "Recommendations" },
}

local function ensureCache()
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local ok, exists = pcall(isfolder, CACHE)
        if ok and not exists then pcall(makefolder, CACHE) end
    end
end

local function loadLibrary()
    local source
    local downloadOk, downloaded = pcall(function() return game:HttpGet(LIBRARY_URL) end)

    if downloadOk and type(downloaded) == "string" and #downloaded > 0 then
        source = downloaded
        ensureCache()
        if type(writefile) == "function" then pcall(writefile, CACHE_FILE, source) end
    elseif type(isfile) == "function" and type(readfile) == "function" then
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
    if not compileOk or type(chunk) ~= "function" then
        error("SilentHub compile failed: " .. tostring(chunk))
    end
    local runOk, library = pcall(chunk)
    if not runOk or type(library) ~= "table" then
        error("SilentHub init failed: " .. tostring(library))
    end
    return library
end

local Library = loadLibrary()
if type(Library.Window) ~= "function" then error("SilentHub.Window() is missing.") end
if type(Library.SetTheme) ~= "function" then error("This SilentHub library version does not support SetTheme().") end

-- Ten complete palettes: each preset changes backgrounds, surfaces, borders and accents.
local THEMES = {
    Amethyst = {
        Background = Color3.fromRGB(16, 15, 23), Surface = Color3.fromRGB(22, 20, 31), Surface2 = Color3.fromRGB(30, 27, 41), Surface3 = Color3.fromRGB(47, 42, 61),
        Stroke = Color3.fromRGB(48, 43, 62), StrokeHover = Color3.fromRGB(103, 85, 133), Accent = Color3.fromRGB(183, 143, 255), AccentDark = Color3.fromRGB(34, 26, 52),
        Text = Color3.fromRGB(244, 241, 250), Muted = Color3.fromRGB(151, 145, 169), Warning = Color3.fromRGB(250, 188, 112), Success = Color3.fromRGB(116, 216, 169), Error = Color3.fromRGB(255, 119, 139),
    },
    Ocean = {
        Background = Color3.fromRGB(11, 19, 27), Surface = Color3.fromRGB(16, 29, 39), Surface2 = Color3.fromRGB(22, 40, 52), Surface3 = Color3.fromRGB(34, 59, 73),
        Stroke = Color3.fromRGB(35, 61, 75), StrokeHover = Color3.fromRGB(65, 125, 145), Accent = Color3.fromRGB(74, 204, 218), AccentDark = Color3.fromRGB(13, 48, 60),
        Text = Color3.fromRGB(234, 247, 249), Muted = Color3.fromRGB(137, 168, 177), Warning = Color3.fromRGB(247, 190, 112), Success = Color3.fromRGB(105, 218, 179), Error = Color3.fromRGB(255, 123, 137),
    },
    Emerald = {
        Background = Color3.fromRGB(13, 22, 20), Surface = Color3.fromRGB(18, 32, 28), Surface2 = Color3.fromRGB(24, 44, 37), Surface3 = Color3.fromRGB(37, 63, 51),
        Stroke = Color3.fromRGB(37, 62, 51), StrokeHover = Color3.fromRGB(77, 131, 99), Accent = Color3.fromRGB(94, 211, 151), AccentDark = Color3.fromRGB(18, 52, 37),
        Text = Color3.fromRGB(237, 247, 240), Muted = Color3.fromRGB(143, 170, 151), Warning = Color3.fromRGB(242, 190, 111), Success = Color3.fromRGB(102, 224, 157), Error = Color3.fromRGB(246, 117, 117),
    },
    Crimson = {
        Background = Color3.fromRGB(25, 14, 19), Surface = Color3.fromRGB(36, 19, 27), Surface2 = Color3.fromRGB(49, 26, 36), Surface3 = Color3.fromRGB(70, 39, 51),
        Stroke = Color3.fromRGB(70, 40, 52), StrokeHover = Color3.fromRGB(143, 72, 91), Accent = Color3.fromRGB(238, 105, 126), AccentDark = Color3.fromRGB(63, 24, 36),
        Text = Color3.fromRGB(250, 239, 242), Muted = Color3.fromRGB(180, 143, 152), Warning = Color3.fromRGB(246, 184, 104), Success = Color3.fromRGB(119, 210, 158), Error = Color3.fromRGB(255, 105, 117),
    },
    Amber = {
        Background = Color3.fromRGB(25, 21, 15), Surface = Color3.fromRGB(36, 29, 19), Surface2 = Color3.fromRGB(49, 39, 25), Surface3 = Color3.fromRGB(69, 55, 34),
        Stroke = Color3.fromRGB(68, 55, 37), StrokeHover = Color3.fromRGB(139, 111, 65), Accent = Color3.fromRGB(239, 184, 91), AccentDark = Color3.fromRGB(61, 43, 20),
        Text = Color3.fromRGB(249, 244, 233), Muted = Color3.fromRGB(174, 158, 130), Warning = Color3.fromRGB(255, 198, 104), Success = Color3.fromRGB(145, 211, 139), Error = Color3.fromRGB(245, 115, 107),
    },
    Midnight = {
        Background = Color3.fromRGB(12, 17, 31), Surface = Color3.fromRGB(17, 24, 42), Surface2 = Color3.fromRGB(24, 34, 57), Surface3 = Color3.fromRGB(37, 51, 79),
        Stroke = Color3.fromRGB(38, 51, 77), StrokeHover = Color3.fromRGB(78, 105, 156), Accent = Color3.fromRGB(112, 157, 255), AccentDark = Color3.fromRGB(21, 37, 69),
        Text = Color3.fromRGB(238, 243, 253), Muted = Color3.fromRGB(143, 159, 188), Warning = Color3.fromRGB(247, 190, 111), Success = Color3.fromRGB(113, 218, 174), Error = Color3.fromRGB(255, 120, 134),
    },
    Rose = {
        Background = Color3.fromRGB(25, 17, 23), Surface = Color3.fromRGB(37, 24, 33), Surface2 = Color3.fromRGB(51, 32, 45), Surface3 = Color3.fromRGB(72, 46, 63),
        Stroke = Color3.fromRGB(69, 45, 62), StrokeHover = Color3.fromRGB(139, 83, 119), Accent = Color3.fromRGB(235, 139, 184), AccentDark = Color3.fromRGB(60, 31, 50),
        Text = Color3.fromRGB(250, 240, 246), Muted = Color3.fromRGB(179, 146, 165), Warning = Color3.fromRGB(248, 190, 110), Success = Color3.fromRGB(121, 214, 167), Error = Color3.fromRGB(255, 112, 137),
    },
    Graphite = {
        Background = Color3.fromRGB(17, 19, 21), Surface = Color3.fromRGB(25, 28, 31), Surface2 = Color3.fromRGB(34, 38, 42), Surface3 = Color3.fromRGB(49, 55, 60),
        Stroke = Color3.fromRGB(51, 57, 62), StrokeHover = Color3.fromRGB(102, 115, 121), Accent = Color3.fromRGB(176, 200, 120), AccentDark = Color3.fromRGB(38, 49, 29),
        Text = Color3.fromRGB(241, 244, 242), Muted = Color3.fromRGB(153, 162, 160), Warning = Color3.fromRGB(235, 184, 102), Success = Color3.fromRGB(137, 210, 143), Error = Color3.fromRGB(241, 118, 118),
    },
    Arctic = {
        Background = Color3.fromRGB(14, 22, 28), Surface = Color3.fromRGB(20, 31, 39), Surface2 = Color3.fromRGB(28, 43, 53), Surface3 = Color3.fromRGB(42, 62, 73),
        Stroke = Color3.fromRGB(42, 62, 73), StrokeHover = Color3.fromRGB(91, 133, 148), Accent = Color3.fromRGB(141, 211, 231), AccentDark = Color3.fromRGB(25, 51, 62),
        Text = Color3.fromRGB(239, 248, 251), Muted = Color3.fromRGB(148, 176, 185), Warning = Color3.fromRGB(246, 191, 116), Success = Color3.fromRGB(121, 218, 181), Error = Color3.fromRGB(255, 125, 139),
    },
    Sunset = {
        Background = Color3.fromRGB(27, 17, 20), Surface = Color3.fromRGB(40, 23, 25), Surface2 = Color3.fromRGB(55, 31, 31), Surface3 = Color3.fromRGB(77, 45, 40),
        Stroke = Color3.fromRGB(76, 46, 43), StrokeHover = Color3.fromRGB(151, 86, 69), Accent = Color3.fromRGB(247, 148, 105), AccentDark = Color3.fromRGB(67, 35, 29),
        Text = Color3.fromRGB(252, 242, 235), Muted = Color3.fromRGB(184, 151, 138), Warning = Color3.fromRGB(255, 193, 105), Success = Color3.fromRGB(132, 214, 156), Error = Color3.fromRGB(255, 113, 119),
    },
}

local DEFAULT_THEME = "Amethyst"
Library:SetTheme(THEMES[DEFAULT_THEME])

local function createWindow(options)
    options.Logo = options.Logo or CUSTOM_LOGO
    options.Loading = false
    options.ConfigurationSaving = { Enabled = false }
    if options.BackgroundImage == nil then
        options.BackgroundImage = SHARED_BACKGROUND_IMAGE
    end
    options.BackgroundImageTransparency = options.BackgroundImageTransparency or BACKGROUND_IMAGE_TRANSPARENCY
    return Library:Window(options)
end

-- Main loader: one adaptive window for the full device width/height.
local main = createWindow({
    Name = "SilentHubLoader",
    Title = "SilentHub",
    SubTitle = "Script Loader · Hub",
    Fullscreen = true,
    Keybind = Enum.KeyCode.RightControl,
})

-- Independent panels start hidden; each has its own show/hide control on the hub.
local skins = createWindow({
    Name = "SkinsWindow",
    Title = "Skins",
    SubTitle = "Skin panel",
    Fullscreen = true,
    StartHidden = true,
    OpenButton = false,
    Keybind = Enum.KeyCode.LeftAlt,
})
local accessories = createWindow({
    Name = "AccessoriesWindow",
    Title = "Accessories",
    SubTitle = "Accessory panel",
    Fullscreen = true,
    StartHidden = true,
    OpenButton = false,
    Keybind = Enum.KeyCode.Home,
})

local sharedWindows = { main, skins, accessories }
local function applySharedBackground(value)
    local ok, message = main:SetBackgroundImage(value, BACKGROUND_IMAGE_TRANSPARENCY)
    if not ok then
        main:Notify({ Title = "Background not applied", Content = tostring(message), Type = "Error", Duration = 5 })
        return false
    end
    for index = 2, #sharedWindows do
        local childOk, childMessage = sharedWindows[index]:SetBackgroundImage(value, BACKGROUND_IMAGE_TRANSPARENCY)
        if not childOk then
            main:Notify({ Title = "Background warning", Content = tostring(childMessage), Type = "Warning", Duration = 4 })
            return false
        end
    end
    main:Notify({ Title = "Background updated", Content = value and "Shared image applied to all panels." or "Shared image removed.", Type = "Success", Duration = 3 })
    return true
end

-- Home
local home = main:Tab({ Name = "Home", Icon = "house", Desc = "Main control center" })
home:Section("Welcome")
home:Paragraph({ Name = "SilentHub Loader", Content = "Use this hub to launch trusted scripts and open each built-in panel independently. Child panels start hidden." })
local status = home:Label({ Text = "Status: ready" })
home:Section("Quick access")
home:Button({ Name = "Show / hide Skins", Icon = "palette", Callback = function()
    local visible = not skins.Open
    skins:Toggle(visible)
    status:Set("Skins: " .. (visible and "visible" or "hidden"))
end })
home:Button({ Name = "Show / hide Accessories", Icon = "shapes", Callback = function()
    local visible = not accessories.Open
    accessories:Toggle(visible)
    status:Set("Accessories: " .. (visible and "visible" or "hidden"))
end })
home:Button({ Name = "Close child panels", Icon = "panels-top-left", Callback = function()
    skins:Toggle(false)
    accessories:Toggle(false)
    status:Set("Child panels: hidden")
end })

-- Script hub. The catalog is intentionally data-driven so collaborators can be added in one place.
local scriptsTab = main:Tab({ Name = "Scripts", Icon = "package-open", Desc = "Official, collaborator and recommended scripts" })
local function runScript(entry)
    if type(entry.Url) ~= "string" or not entry.Url:match("^https://") then
        main:Notify({ Title = "Invalid script URL", Content = "Add a direct HTTPS raw script URL to SCRIPT_CATALOG.", Type = "Error", Duration = 4 })
        return
    end
    if type(loadstring) ~= "function" then
        main:Notify({ Title = "Executor limitation", Content = "loadstring is unavailable in this environment.", Type = "Error", Duration = 4 })
        return
    end
    main:Notify({ Title = "Loading script", Content = tostring(entry.Name), Duration = 2 })
    local downloadOk, source = pcall(function() return game:HttpGet(entry.Url) end)
    if not downloadOk or type(source) ~= "string" or #source == 0 then
        main:Notify({ Title = "Download failed", Content = tostring(source), Type = "Error", Duration = 5 })
        return
    end
    local compileOk, chunk = pcall(loadstring, source)
    if not compileOk or type(chunk) ~= "function" then
        main:Notify({ Title = "Compile failed", Content = tostring(chunk), Type = "Error", Duration = 5 })
        return
    end
    task.spawn(function()
        local runOk, result = pcall(chunk)
        if runOk then
            main:Notify({ Title = "Script finished", Content = tostring(entry.Name) .. " finished without a runtime error.", Type = "Success", Duration = 4 })
        else
            main:Notify({ Title = "Script runtime error", Content = tostring(result), Type = "Error", Duration = 6 })
        end
    end)
end

local categoryOrder = { "Official", "Collaborators", "Recommendations" }
local scriptCount = 0
for _, category in ipairs(categoryOrder) do
    local entries = {}
    for _, entry in ipairs(SCRIPT_CATALOG) do
        if (entry.Category or "Collaborators") == category then
            table.insert(entries, entry)
        end
    end
    if #entries > 0 then
        scriptsTab:Section(category)
        for _, entry in ipairs(entries) do
            scriptCount += 1
            scriptsTab:Paragraph({
                Name = tostring(entry.Name or "Unnamed script"),
                Content = (entry.Description or "") .. "\nAuthor: " .. tostring(entry.Author or "Unspecified"),
            })
            if type(entry.Url) == "string" and entry.Url ~= "" then
                scriptsTab:Button({ Name = "Run: " .. tostring(entry.Name or "Script"), Icon = "play", Callback = function()
                    runScript(entry)
                end })
            end
        end
    end
end
if scriptCount == 0 then
    scriptsTab:Section("Script catalog")
    scriptsTab:Paragraph({ Name = "No scripts added yet", Content = "Add each script to SCRIPT_CATALOG near the top of this file. Set its name, author, description, direct HTTPS URL and category (Official, Collaborators or Recommendations). Scripts are only downloaded and executed when you press Run." })
end

-- Appearance: one theme source for the main window and every child panel.
local appearance = main:Tab({ Name = "Appearance", Icon = "palette", Desc = "Global colors and shared background" })
appearance:Section("Interface colors")
local themeNames = { "Amethyst", "Ocean", "Emerald", "Crimson", "Amber", "Midnight", "Rose", "Graphite", "Arctic", "Sunset" }
appearance:Dropdown({ Name = "Professional theme", Options = themeNames, Default = DEFAULT_THEME, Callback = function(name)
    local palette = THEMES[name]
    if palette then
        Library:SetTheme(palette)
        main:Notify({ Title = "Theme changed", Content = name .. " applied to all panels.", Type = "Success", Duration = 3 })
    end
end })
appearance:Section("Shared background image")
local backgroundInput = appearance:Input({ Name = "Image URL or asset ID", Placeholder = "rbxassetid://123456789 or https://..." })
appearance:Button({ Name = "Apply background to all panels", Icon = "image", Callback = function()
    local value = backgroundInput:Get()
    if type(value) ~= "string" or value == "" then
        main:Notify({ Title = "Missing image", Content = "Enter an asset ID or direct image URL first.", Type = "Warning", Duration = 3 })
        return
    end
    applySharedBackground(value)
end })
appearance:Button({ Name = "Remove shared background", Icon = "image-off", Callback = function()
    applySharedBackground(nil)
end })
appearance:Paragraph({ Name = "Image fit", Content = "Images use Crop scaling to fill the panel without stretching. Asset IDs work directly. Direct URLs need executor support for HTTP download, file writing and custom assets." })

-- Skins panel: the existing UI-only preview controls are kept; no character changes are performed.
local skinsTab = skins:Tab({ Name = "Catalog", Icon = "palette", Desc = "Skin panel" })
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
skinsTab:Paragraph({ Name = "UI preview only", Content = "This panel keeps the current preview controls. No skin is changed on the character." })

-- Accessories panel: the existing UI-only slot controls are kept; no accessories are modified.
local accessoriesTab = accessories:Tab({ Name = "Accessories", Icon = "shapes", Desc = "Accessory panel" })
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
accessoriesTab:Paragraph({ Name = "UI preview only", Content = "This panel keeps the current preview controls. No accessory is equipped, removed or modified." })

main:Notify({ Title = "SilentHub Loader ready", Content = "The main hub is adaptive. Skins and Accessories open independently.", Type = "Success", Duration = 4 })