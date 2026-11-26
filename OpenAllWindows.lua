-- SilentHub bootstrap loader / modular Main Panel
-- Loads the latest library from GitHub and falls back to a local executor cache.
-- The Skins / Accessories / Animations windows below are interface slots only:
-- the uploaded reference library does not include the actual game-feature logic.

local CACHE_FOLDER = "SilentUI"
local CACHE_FILE = CACHE_FOLDER .. "/SilentHub.lua"
local LIBRARY_URL = "https://raw.githubusercontent.com/Silent-lua/Library/main/SilentHub.lua?v=2440b8bb59142b9868fbbbb881106a962cfd8384"

-- Source customization: empty strings or omitted values use the built-in defaults.
-- Logo accepts a Roblox asset ID. Background accepts an asset ID or direct PNG/JPG URL.
local UI_OPTIONS = {
    Title = "SilentHub",
    SubTitle = "Main Panel",
    Logo = "",                 -- Blank/omitted = default SilentHub logo
    Background = "",           -- Blank/omitted = theme background
    SecondaryBackground = "", -- Optional shared background for secondary module windows
}

-- Add community entries here. Entries can be strings or {Name, Description} tables.
local COLLABORATORS = {
    -- { Name = "Username", Description = "Role or contribution" },
}
local FRIENDS = {
    -- { Name = "Username", Description = "Short note" },
}
local RECOMMENDATIONS = {
    -- { Name = "Project", Description = "What it does and why it is useful" },
}

-- Executor-specific cache support is optional; online loading only requires
-- game:HttpGet + loadstring. If download fails, a cached copy is used when present.
local function ensureCacheFolder()
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local ok, exists = pcall(isfolder, CACHE_FOLDER)
        if ok and not exists then
            pcall(makefolder, CACHE_FOLDER)
        end
    end
end

local function readCachedLibrary()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end
    local ok, exists = pcall(isfile, CACHE_FILE)
    if not ok or not exists then
        return nil
    end
    local readOk, source = pcall(readfile, CACHE_FILE)
    if readOk and type(source) == "string" and #source > 0 then
        return source
    end
    return nil
end

local function loadLibrary()
    if type(loadstring) ~= "function" then
        error("SilentHub requires executor loadstring support.")
    end

    local source
    local downloadOk, downloaded = pcall(function()
        return game:HttpGet(LIBRARY_URL)
    end)

    if downloadOk and type(downloaded) == "string" and #downloaded > 0 then
        source = downloaded
        ensureCacheFolder()
        if type(writefile) == "function" then
            pcall(writefile, CACHE_FILE, source)
        end
    else
        source = readCachedLibrary()
    end

    if not source then
        error("Could not download SilentHub and no valid cached copy exists: " .. tostring(downloaded))
    end

    local compileOk, chunk = pcall(loadstring, source)
    if not compileOk or type(chunk) ~= "function" then
        error("SilentHub compilation failed: " .. tostring(chunk))
    end

    local runOk, library = pcall(chunk)
    if not runOk or type(library) ~= "table" then
        error("SilentHub initialization failed: " .. tostring(library))
    end
    if type(library.CreateLauncher) ~= "function" then
        error("The downloaded library is outdated: CreateLauncher() is unavailable.")
    end
    return library
end

local Library = loadLibrary()

-- A module factory is called only the first time its button is pressed.
-- Its window is cached by the launcher and reused after hide/show.
local function makeModulePanel(title, subtitle, description, keybind)
    return function(launcher, module)
        local panel = launcher:CreateModuleWindow({
            Name = "SilentHub_" .. tostring(module.Id),
            Title = title,
            SubTitle = subtitle,
            Logo = UI_OPTIONS.Logo,
            Size = UDim2.fromOffset(680, 480),
            MinSize = Vector2.new(400, 300),
            MaxSize = Vector2.new(860, 640),
            Responsive = true,
            BackgroundGroup = "Secondary",
            Loading = false,
            OpenButton = false,
            Keybind = keybind,
            ConfigurationSaving = { Enabled = false },
        })

        local tab = panel:Tab({
            Name = "Overview",
            Desc = description,
            Icon = module.Icon or "app-window",
        })
        tab:Section("Module interface")
        tab:Paragraph({
            Name = title .. " interface slot",
            Content = "The independent window, visibility state, responsive layout, global theme and Secondary background are connected. The actual " .. title .. " gameplay logic was not present in the reference file and has not been fabricated.",
        })
        tab:Button({
            Name = "Hide " .. title,
            Desc = "Close this panel without affecting other modules.",
            Icon = "eye-off",
            Callback = function()
                panel:Toggle(false)
            end,
        })
        return panel
    end
end

-- Register core modules here. The three core slots appear in Quick Access too.
local MODULES = {
    {
        Id = "skins",
        Title = "Skins",
        Description = "Independent Skins window and visibility control.",
        Category = "Avatar",
        Icon = "palette",
        Create = makeModulePanel("Skins", "Avatar customization", "Skins module interface. Add its feature controls here.", Enum.KeyCode.F6),
    },
    {
        Id = "accessories",
        Title = "Accessories",
        Description = "Independent Accessories window and visibility control.",
        Category = "Avatar",
        Icon = "shirt",
        Create = makeModulePanel("Accessories", "Accessory management", "Accessories module interface. Add its feature controls here.", Enum.KeyCode.F7),
    },
    {
        Id = "animations",
        Title = "Animations",
        Description = "Prepared module slot for future animation controls.",
        Category = "Avatar",
        Icon = "activity",
        Create = makeModulePanel("Animations", "Animation library", "Animations module interface slot. Register the animation feature logic when it is available.", Enum.KeyCode.F8),
    },

    -- Add future modules by copying this pattern. Create must return a window
    -- created through launcher:CreateModuleWindow(...) or Library:Window(...).
    -- {
    --     Id = "my_module",
    --     Title = "My Module",
    --     Description = "Module description",
    --     Category = "Utilities",
    --     Icon = "settings",
    --     Create = function(launcher, module)
    --         local panel = launcher:CreateModuleWindow({
    --             Name = "MyModuleWindow",
    --             Title = "My Module",
    --             SubTitle = "Module subtitle",
    --             Loading = false,
    --             OpenButton = false,
    --             Keybind = Enum.KeyCode.F9,
    --             ConfigurationSaving = { Enabled = false },
    --         })
    --         local tab = panel:Tab({ Name = "Overview", Desc = "Module description" })
    --         tab:Paragraph({ Name = "Ready", Content = "Add module controls here." })
    --         return panel
    --     end,
    -- },
}

local Launcher = Library:CreateLauncher({
    Title = UI_OPTIONS.Title,
    SubTitle = UI_OPTIONS.SubTitle,
    Logo = UI_OPTIONS.Logo,
    Background = UI_OPTIONS.Background,
    SecondaryBackground = UI_OPTIONS.SecondaryBackground,
    Theme = "Midnight Graphite",
    WindowOptions = {
        Name = "SilentHub_MainPanel",
        Size = UDim2.fromOffset(700, 500),
        MinSize = Vector2.new(420, 320),
        MaxSize = Vector2.new(900, 680),
        Responsive = true,
        OpenButton = true,
        Keybind = Enum.KeyCode.RightControl,
        Loading = { Duration = 0.85, Title = "SilentHub", Text = "Opening Main Panel" },
        ConfigurationSaving = { Enabled = false },
    },
    Modules = MODULES,
    Collaborators = COLLABORATORS,
    Friends = FRIENDS,
    Recommendations = RECOMMENDATIONS,
})

-- Expose the launcher object to executor consoles for simple runtime management.
-- Examples:
--   SilentHubLauncher:SetModuleVisible("skins", true)
--   SilentHubLauncher:SetModuleVisible("accessories", false)
--   SilentHubLauncher:RegisterModule({ Id = "extra", Title = "Extra", Create = factory })
--   SilentHubLauncher:SetTheme("Oceanic")
_G.SilentHubLauncher = Launcher

return Launcher
