-- Silent Framework | init.lua (Network Bootstrapper v2.0)
-- Responsabilidad: Resolución de dependencias, cacheo, y peticiones HTTP seguras con Timeout.

if getgenv().SilentFramework_Loaded then
    return getgenv().SilentFramework_API
end

local Silent = {
    Version = "Beta",
    Build = "Owner:BySilent",
    Repo_URL = "https://raw.githubusercontent.com/Silent-lua/Library/main/"
}

local ModuleCache = {}

-- Detección de capacidades del ejecutor (Inspirado en Rayfield y Snowy Hub)
Silent.Capabilities = {
    FileSystem = (readfile ~= nil and writefile ~= nil and isfolder ~= nil),
    Clipboard = (setclipboard ~= nil or toclipboard ~= nil),
    Http = (request ~= nil or syn and syn.request ~= nil or http and http.request ~= nil)
}

-- Función de Carga con Tolerancia a Fallos (Timeout)
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
            warn(string.format("[Silent:Loader] Request for %s timed out after %d seconds.", url, timeout))
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

    local url = Silent.Repo_URL .. path .. ".lua"
    local success, moduleFunction = LoadWithTimeout(url, 7)

    if not success or not moduleFunction then
        error(string.format("[Silent:Loader] Failed to fetch/parse module '%s': %s", path, tostring(moduleFunction)), 2)
    end

    local moduleData = moduleFunction()
    ModuleCache[path] = moduleData
    return moduleData
end

-- Carga del Core
local Services = Import("Core/Services")
local Runtime  = Import("Core/Runtime")
local Cleanup  = Import("Core/Cleanup")
local Signal   = Import("Core/Signal")
local Tween    = Import("Core/Tween")
local Creator  = Import("Core/Creator")

Silent.Services = Services
Silent.Runtime = Runtime
Silent.Cleanup = Cleanup
Silent.Signal = Signal
Silent.Tween = Tween.Play
Silent.Creator = Creator

function Silent:SetDebug(state)
    self.Runtime.SetDebug(state)
end

function Silent:Init()
    if self.Runtime.State.IsLoaded then return end
    self.Runtime.UpdateState("IsLoaded", true)
    
    if self.Runtime.Debug then
        print("[Silent] Enterprise Framework Initialized.")
    end
end

getgenv().SilentFramework_Loaded = true
getgenv().SilentFramework_API = table.freeze(Silent)

return getgenv().SilentFramework_API
