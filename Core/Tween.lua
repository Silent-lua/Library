-- Silent Framework | Core/Tween.lua
-- Responsabilidad: Animaciones seguras.

local Services = nil
local Tween = {}
local DefaultInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function Tween.InitDependencies(servicesModule)
    Services = servicesModule
end

function Tween.Play(instance, tweenInfo, properties)
    if not instance or typeof(instance) ~= "Instance" then return nil end
    
    local info = tweenInfo or DefaultInfo
    local TweenService = Services.TweenService
    
    local success, tweenObj = pcall(function()
        return TweenService:Create(instance, info, properties)
    end)
    
    if success and tweenObj then
        tweenObj:Play()
        return tweenObj
    else
        pcall(function()
            for k, v in pairs(properties) do
                instance[k] = v
            end
        end)
        return nil
    end
end

return Tween
