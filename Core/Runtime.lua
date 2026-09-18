-- Silent Framework | Core/Runtime.lua
-- Responsabilidad: Estado global, inyección segura de UI y ejecución protegida de callbacks.

local Services = require(script.Parent.Services)
local CoreGui = Services.CoreGui
local RunService = Services.RunService

local Runtime = {
    Debug = false,
    State = {
        IsLoaded = false,
        IsWindowCreated = false
    }
}

function Runtime.SetDebug(state)
    Runtime.Debug = state == true
end

function Runtime.Log(message, isWarning)
    if Runtime.Debug then
        if isWarning then
            warn(string.format("[Silent:Warning] %s", tostring(message)))
        else
            print(string.format("[Silent:Log] %s", tostring(message)))
        end
    end
end

-- Ejecuta funciones de usuario evitando que errores rompan el framework
function Runtime.CallSafely(callback, ...)
    if type(callback) ~= "function" then return false, "Not a function" end
    
    local args = {...}
    local success, result = xpcall(
        function() return callback(unpack(args)) end,
        function(err)
            local trace = debug.traceback(err, 2)
            Runtime.Log(string.format("Consumer Callback Error:\n%s", trace), true)
            return err
        end
    )
    return success, result
end

-- Busca el mejor contenedor para esconder la UI del juego (Anti-Cheat Bypass)
function Runtime.GetSafeParent()
    local targetParent = nil
    
    if not RunService:IsStudio() then
        if gethui then
            pcall(function() targetParent = gethui() end)
        elseif syn and syn.protect_gui then
            targetParent = CoreGui
        elseif CoreGui:FindFirstChild("RobloxGui") then
            targetParent = CoreGui:FindFirstChild("RobloxGui")
        else
            targetParent = CoreGui
        end
    else
        targetParent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    return targetParent or CoreGui
end

function Runtime.ProtectGui(guiInstance)
    if not RunService:IsStudio() and syn and syn.protect_gui then
        pcall(function() syn.protect_gui(guiInstance) end)
    end
    guiInstance.Parent = Runtime.GetSafeParent()
end

function Runtime.UpdateState(key, value)
    if Runtime.State[key] ~= nil then
        Runtime.State[key] = value
    end
end

return Runtime
