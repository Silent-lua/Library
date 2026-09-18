-- Silent Framework | init.lua (Network Bootstrapper v4.0)

if getgenv().SilentFramework_Loaded then
    return getgenv().SilentFramework_API
end

local Silent = {
    Version = "4.0.0-ENTERPRISE",
    Build = "FASE4-COMPONENTS",
    Repo_URL = "https://raw.githubusercontent.com/Silent-lua/Library/main/"
}

local ModuleCache = {}

Silent.Capabilities = {
    FileSystem = (readfile ~= nil and writefile ~= nil and isfolder ~= nil),
    Clipboard = (setclipboard ~= nil or toclipboard ~= nil),
    Http = (request ~= nil or syn and syn.request ~= nil or http and http.request ~= nil)
}

local function LoadWithTimeout(url, timeout)
    timeout = timeout or 5
    local requestCompleted, success, result = false, false, nil

    local requestThread = task.spawn(function()
        local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url)
        if not fetchSuccess or #fetchResult == 0 then
            success, result = false, "Empty or failed response"
            requestCompleted = true
            return
        end
        local execSuccess, execResult = pcall(loadstring, fetchResult)
        success, result = execSuccess, execResult
        requestCompleted = true
    end)

    local timeoutThread = task.delay(timeout, function()
        if not requestCompleted then
            warn(string.format("[Silent:Loader] Request for %s timed out.", url))
            task.cancel(requestThread)
            result = "Request timed out"
            requestCompleted = true
        end
    end)

    while not requestCompleted do task.wait() end
    if coroutine.status(timeoutThread) ~= "dead" then task.cancel(timeoutThread) end
    
    return success, result
end

local function Import(path)
    if ModuleCache[path] then return ModuleCache[path] end
    local url = Silent.Repo_URL .. path .. ".lua?t=" .. tostring(math.random(100000, 999999))
    local success, moduleFunction = LoadWithTimeout(url, 7)

    if not success or not moduleFunction then
        error(string.format("[Silent:Loader] Failed to fetch/parse module '%s'. Check URL.", path), 2)
    end

    local moduleData = moduleFunction()
    ModuleCache[path] = moduleData
    return moduleData
end

-- Carga del Core
local Services     = Import("Core/Services")
local Runtime      = Import("Core/Runtime")
local Cleanup      = Import("Core/Cleanup")
local Signal       = Import("Core/Signal")
local Tween        = Import("Core/Tween")
local ThemeManager = Import("Core/ThemeManager")
local Creator      = Import("Core/Creator")
local Elements     = Import("Core/Elements")
local Window       = Import("Core/Window")

-- Inyección de Dependencias
Runtime.InitDependencies(Services)
Tween.InitDependencies(Services)
Creator.InitDependencies(ThemeManager)
ThemeManager.InitDependencies(Tween.Play)
Elements.InitDependencies(Services, Creator, ThemeManager, Tween.Play, Runtime)
Window.InitDependencies(Services, Creator, ThemeManager, Tween.Play, Runtime, Elements)

Silent.Services = Services
Silent.Runtime = Runtime
Silent.Cleanup = Cleanup
Silent.Signal = Signal
Silent.Tween = Tween.Play
Silent.Theme = ThemeManager
Silent.Creator = Creator
Silent.Window = Window

function Silent:SetDebug(state)
    self.Runtime.SetDebug(state)
end

function Silent:SetTheme(themeName)
    self.Theme.SetTheme(themeName)
end

function Silent:CreateWindow(options)
    if not self.Runtime.State.IsLoaded then self:Init() end
    return self.Window.New(options)
end

function Silent:Init()
    if self.Runtime.State.IsLoaded then return end
    self.Runtime.UpdateState("IsLoaded", true)
end

getgenv().SilentFramework_Loaded = true
getgenv().SilentFramework_API = table.freeze(Silent)

return getgenv().SilentFramework_API
