-- SilentHub bootstrap Loader / separate Main Interface
-- Community belongs to this Loader. Scripts and Configuration belong to Main Interface.

local CACHE_FOLDER = "SilentUI"
local CACHE_FILE = CACHE_FOLDER .. "/SilentHub.lua"
local AUTOLOAD_FILE = CACHE_FOLDER .. "/LauncherSettings.json"
local LIBRARY_URL = "https://raw.githubusercontent.com/Silent-lua/Library/main/SilentHub.lua?v=f4446ad56be00e6b101753aa3322de4f8958cc0d"
local HttpService = game:GetService("HttpService")

-- Source customization. Empty/omitted Logo and Fondo keep their built-in defaults.
local UI_OPTIONS = {
    Title = "SilentHub",
    SubTitle = "Main Interface",
    Logo = "",                    -- Empty/omitted = default SilentHub logo
    Fondo = "",                   -- Empty/omitted = theme background for Loader + Main Interface
    SecondaryBackground = "",    -- Optional shared background for secondary module windows
    Theme = "Midnight Graphite",  -- Set the default global palette here; switch palettes in Configuración > Colores
    ConfigName = "default",
}

-- Community data is configured here because Community belongs to the Loader.
local COLLABORATORS = {
    -- { Name = "Username", Description = "Role or contribution" },
}
local FRIENDS = {
    -- { Name = "Username", Description = "Short note" },
}
local RECOMMENDATIONS = {
    -- { Name = "Project", Description = "What it does and why it is useful" },
}

-- Optional custom items are appended AFTER the permanent built-in Configuration controls.
local CONFIGURATION_ITEMS = {
    -- { Type = "Section", Name = "Extra settings" },
    -- { Type = "Toggle", Name = "Custom option", Flag = "CustomOption", Default = false },
}

local function ensureCacheFolder()
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local ok, exists = pcall(isfolder, CACHE_FOLDER)
        if ok and not exists then pcall(makefolder, CACHE_FOLDER) end
    end
end

local function readCachedLibrary()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local ok, exists = pcall(isfile, CACHE_FILE)
    if not ok or not exists then return nil end
    local readOk, source = pcall(readfile, CACHE_FILE)
    if readOk and type(source) == "string" and #source > 0 then return source end
    return nil
end

local function readAutoLoadSettings()
    local settings = { Enabled = false, ConfigName = UI_OPTIONS.ConfigName }
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return settings end
    local ok, exists = pcall(isfile, AUTOLOAD_FILE)
    if not ok or not exists then return settings end
    local readOk, raw = pcall(readfile, AUTOLOAD_FILE)
    if not readOk or type(raw) ~= "string" or raw == "" then return settings end
    local decodeOk, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if decodeOk and type(decoded) == "table" then
        settings.Enabled = decoded.Enabled == true
        if type(decoded.ConfigName) == "string" and decoded.ConfigName ~= "" then
            settings.ConfigName = decoded.ConfigName
        end
    end
    return settings
end

local function writeAutoLoadSettings(enabled, configName)
    if type(writefile) ~= "function" then
        warn("[SilentHub] AutoLoad preference cannot be saved: writefile is unavailable.")
        return false
    end
    ensureCacheFolder()
    local payload = {
        Enabled = enabled == true,
        ConfigName = tostring(configName or UI_OPTIONS.ConfigName or "default"),
    }
    local ok, err = pcall(function()
        writefile(AUTOLOAD_FILE, HttpService:JSONEncode(payload))
    end)
    if not ok then warn("[SilentHub] AutoLoad preference save failed: " .. tostring(err)) end
    return ok
end

local AutoLoadSettings = readAutoLoadSettings()

local function loadLibrary()
    if type(loadstring) ~= "function" then error("SilentHub requires executor loadstring support.") end
    local source
    local downloadOk, downloaded = pcall(function() return game:HttpGet(LIBRARY_URL) end)
    if downloadOk and type(downloaded) == "string" and #downloaded > 0 then
        source = downloaded
        ensureCacheFolder()
        if type(writefile) == "function" then pcall(writefile, CACHE_FILE, source) end
    else
        source = readCachedLibrary()
    end
    if not source then
        error("Could not download SilentHub and no valid cached copy exists: " .. tostring(downloaded))
    end
    local compileOk, chunk = pcall(loadstring, source)
    if not compileOk or type(chunk) ~= "function" then error("SilentHub compilation failed: " .. tostring(chunk)) end
    local runOk, library = pcall(chunk)
    if not runOk or type(library) ~= "table" then error("SilentHub initialization failed: " .. tostring(library)) end
    if type(library.CreateLauncher) ~= "function" then error("The downloaded library is outdated: CreateLauncher() is unavailable.") end
    return library
end

local Library = loadLibrary()
Library:SetTheme(UI_OPTIONS.Theme)
Library:SetBackground("Primary", UI_OPTIONS.Fondo)
Library:SetBackground("Secondary", UI_OPTIONS.SecondaryBackground)

local function makeModulePanel(title, subtitle, description, keybind)
    return function(launcher, module)
        local panel = launcher:CreateModuleWindow({
            Name = "SilentHub_" .. tostring(module.Id),
            Title = title,
            SubTitle = subtitle,
            Logo = UI_OPTIONS.Logo,
            Size = UDim2.fromOffset(580, 420),
            MinSize = Vector2.new(340, 260),
            MaxSize = Vector2.new(740, 540),
            Responsive = true,
            BackgroundGroup = "Secondary",
            Loading = false,
            OpenButton = false,
            Keybind = keybind,
            ConfigurationSaving = { Enabled = false },
        })
        local tab = panel:Tab({ Name = "Overview", Desc = description, Icon = module.Icon or "app-window" })
        tab:Section("Module interface")
        tab:Paragraph({
            Name = title .. " interface slot",
            Content = "This independent window is connected to the global theme and Secondary background. The reference source did not include the actual " .. title .. " gameplay logic, so this is an integration slot only.",
        })
        tab:Button({
            Name = "Hide " .. title,
            Desc = "Close this panel without affecting other modules.",
            Icon = "eye-off",
            Callback = function() panel:Toggle(false) end,
        })
        return panel
    end
end

local MODULES = {
    { Id = "skins", Title = "Skins", Description = "Independent Skins window and visibility control.", Category = "Avatar", Icon = "palette", Create = makeModulePanel("Skins", "Avatar customization", "Skins module interface. Add its feature controls here.", Enum.KeyCode.F6) },
    { Id = "accessories", Title = "Accessories", Description = "Independent Accessories window and visibility control.", Category = "Avatar", Icon = "shirt", Create = makeModulePanel("Accessories", "Accessory management", "Accessories module interface. Add its feature controls here.", Enum.KeyCode.F7) },
    { Id = "animations", Title = "Animations", Description = "Prepared module slot for future animation controls.", Category = "Avatar", Icon = "activity", Create = makeModulePanel("Animations", "Animation library", "Animations module interface slot. Register animation controls when available.", Enum.KeyCode.F8) },
}

local MainLauncher
local function openMainInterface()
    if MainLauncher and MainLauncher.Window and not MainLauncher.Window._destroyed then
        MainLauncher:Toggle(true)
        return MainLauncher
    end
    MainLauncher = Library:CreateLauncher({
        Title = UI_OPTIONS.Title,
        SubTitle = UI_OPTIONS.SubTitle,
        Logo = UI_OPTIONS.Logo,
        Background = UI_OPTIONS.Fondo,
        SecondaryBackground = UI_OPTIONS.SecondaryBackground,
        Theme = UI_OPTIONS.Theme,
        DefaultConfigName = AutoLoadSettings.ConfigName,
        AutoLoadEnabled = AutoLoadSettings.Enabled,
        AutoLoadConfigName = AutoLoadSettings.ConfigName,
        OnAutoLoadChanged = function(enabled, configName)
            AutoLoadSettings.Enabled = enabled == true
            AutoLoadSettings.ConfigName = tostring(configName or UI_OPTIONS.ConfigName or "default")
            writeAutoLoadSettings(AutoLoadSettings.Enabled, AutoLoadSettings.ConfigName)
        end,
        ConfigurationItems = CONFIGURATION_ITEMS,
        WindowOptions = {
            Name = "SilentHub_MainInterface",
            Size = UDim2.fromOffset(600, 420),
            MinSize = Vector2.new(360, 270),
            MaxSize = Vector2.new(760, 560),
            Responsive = true,
            OpenButton = true,
            Keybind = Enum.KeyCode.RightControl,
            Loading = false,
            ConfigurationSaving = { Enabled = true, FileName = AutoLoadSettings.ConfigName or UI_OPTIONS.ConfigName or "default" },
        },
        Modules = MODULES,
    })
    _G.SilentHubLauncher = MainLauncher
    return MainLauncher
end

local function addCommunitySection(tab, title, entries, emptyText)
    tab:Section(title)
    if type(entries) ~= "table" or #entries == 0 then
        tab:Paragraph({ Name = "Nothing here yet", Content = emptyText })
        return
    end
    for _, entry in ipairs(entries) do
        local name, description
        if type(entry) == "table" then
            name = tostring(entry.Name or entry.Title or entry.Username or "Entry")
            description = tostring(entry.Description or entry.Content or entry.Desc or "")
        else
            name = tostring(entry)
            description = ""
        end
        tab:Paragraph({ Name = name, Content = description })
    end
end

-- Compact draggable Loader. Community remains here after Main Interface opens.
local Loader = Library:Window({
    Name = "SilentHub_BootstrapLoader",
    Title = UI_OPTIONS.Title,
    SubTitle = "Loader",
    Logo = UI_OPTIONS.Logo,
    BackgroundGroup = "Primary",
    Size = UDim2.fromOffset(300, 190),
    MinSize = Vector2.new(270, 165),
    MaxSize = Vector2.new(360, 230),
    Responsive = true,
    OpenButton = false,
    Keybind = Enum.KeyCode.Unknown,
    Loading = false,
    ConfigurationSaving = { Enabled = false },
})

local LoaderTab = Loader:Tab({ Name = "Start", Desc = "Launch the separate Main Interface.", Icon = "rocket" })
LoaderTab:Section("Welcome")
LoaderTab:Paragraph({ Name = "SilentHub Loader", Content = "A compact launcher for the main workspace. Community information stays in this Loader." })
LoaderTab:Button({
    Name = "Open Main Interface",
    Desc = "Create or focus the separate Main Interface.",
    Icon = "app-window",
    Style = "Primary",
    Callback = function()
        local ok, result = pcall(openMainInterface)
        if not ok then
            Loader:Notify({ Title = "Could not open Main Interface", Content = tostring(result), Type = "Error", Duration = 5 })
            return
        end
        Loader:Notify({ Title = "Main Interface ready", Content = "Scripts and Configuration opened in a separate window.", Type = "Success", Duration = 3 })
    end,
})
LoaderTab:Button({
    Name = "Exit Loader",
    Desc = "Close the Loader. An already opened Main Interface remains available.",
    Icon = "x",
    Callback = function()
        _G.SilentHubLoader = nil
        Loader:Destroy()
    end,
})

local CommunityTab = Loader:Tab({ Name = "Community", Desc = "Collaborators, friends and recommended projects.", Icon = "users" })
addCommunitySection(CommunityTab, "Collaborators", COLLABORATORS, "Add collaborators in COLLABORATORS near the top of OpenAllWindows.lua.")
addCommunitySection(CommunityTab, "Friends", FRIENDS, "Add friends in FRIENDS near the top of OpenAllWindows.lua.")
addCommunitySection(CommunityTab, "Recommendations", RECOMMENDATIONS, "Add recommendations in RECOMMENDATIONS near the top of OpenAllWindows.lua.")

_G.SilentHubLoader = Loader
_G.SilentHubLauncher = nil
return Loader
