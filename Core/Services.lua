-- Silent Framework | Core/Services.lua
-- Responsabilidad: Cacheo de servicios nativos protegido con cloneref contra Anti-Cheats.

local Services = {}
local ServiceCache = {}

-- Definir cloneref si el ejecutor lo soporta, de lo contrario usar función puente
local cloneReference = (cloneref or clonereference or function(instance) return instance end)

setmetatable(Services, {
    __index = function(_, serviceName)
        if ServiceCache[serviceName] then
            return ServiceCache[serviceName]
        end

        local success, service = pcall(game.GetService, game, serviceName)
        if success and service then
            local secureService = cloneReference(service)
            ServiceCache[serviceName] = secureService
            return secureService
        end

        return nil
    end,
    __newindex = function()
        error("[Silent:Services] Attempt to modify read-only Services registry.", 2)
    end
})

return Services
