-- Silent Framework | Core/Creator.lua
-- Responsabilidad: Instanciación limpia y puente de automatización con ThemeManager.

local ThemeManager = require(script.Parent.ThemeManager)
local Creator = {}

function Creator.New(className, properties, children)
    local success, instance = pcall(Instance.new, className)
    if not success or not instance then
        error(string.format("[Silent:Creator] Failed to create %s", tostring(className)), 2)
    end

    local themeTags = nil

    if properties and type(properties) == "table" then
        for key, value in pairs(properties) do
            if key == "ThemeTag" then
                themeTags = value
            elseif key == "Parent" then
                continue -- Retrasamos la asignación del Parent por performance
            elseif type(value) == "function" and string.sub(key, 1, 2) == "On" then
                local eventName = string.sub(key, 3)
                if instance[eventName] then
                    instance[eventName]:Connect(value)
                end
            else
                instance[key] = value
            end
        end
    end

    if children and type(children) == "table" then
        for _, child in ipairs(children) do
            if typeof(child) == "Instance" then
                child.Parent = instance
            end
        end
    end

    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end

    -- FASE 2: Si el componente solicitó tematización, lo registramos automáticamente.
    if themeTags and type(themeTags) == "table" then
        ThemeManager.Register(instance, themeTags)
    end

    return instance
end

return Creator
