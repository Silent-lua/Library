-- Silent Framework | Core/Creator.lua
-- Responsabilidad: Instanciación limpia y preparación para el ThemeManager.

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
                continue -- Se aplica al final
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

    -- FASE 2: Aquí inyectaremos el ThemeManager si existen themeTags
    if themeTags then
        -- Placeholder para ThemeManager.Register(instance, themeTags)
        instance:SetAttribute("Silent_HasTheme", true)
    end

    return instance
end

return Creator
