-- Silent Framework | Core/ThemeManager.lua
-- Responsabilidad: Registro de componentes, gestión de paletas y actualización dinámica.

local ThemeManager = {
    Themes = {
        Dark = {
            Background = Color3.fromRGB(15, 15, 15),
            Panel = Color3.fromRGB(22, 22, 22),
            Border = Color3.fromRGB(40, 40, 40),
            Text = Color3.fromRGB(240, 240, 240),
            TextMuted = Color3.fromRGB(130, 130, 130),
            Accent = Color3.fromRGB(80, 180, 255),
            AccentHover = Color3.fromRGB(100, 200, 255),
            Success = Color3.fromRGB(45, 225, 130),
            Error = Color3.fromRGB(255, 65, 85)
        },
        Light = {
            Background = Color3.fromRGB(245, 245, 245),
            Panel = Color3.fromRGB(230, 230, 230),
            Border = Color3.fromRGB(200, 200, 200),
            Text = Color3.fromRGB(40, 40, 40),
            TextMuted = Color3.fromRGB(120, 120, 120),
            Accent = Color3.fromRGB(0, 146, 214),
            AccentHover = Color3.fromRGB(0, 170, 255),
            Success = Color3.fromRGB(30, 180, 90),
            Error = Color3.fromRGB(220, 40, 60)
        }
    },
    CurrentTheme = "Dark",
    _Registry = {}
}

-- Puntero para evitar dependencias circulares con Tween
local TweenPlay = nil

function ThemeManager.InitDependencies(tweenFunc)
    TweenPlay = tweenFunc
end

function ThemeManager.GetColor(tag)
    local palette = ThemeManager.Themes[ThemeManager.CurrentTheme]
    if not palette then return Color3.new(1, 1, 1) end
    return palette[tag] or Color3.new(1, 1, 1)
end

function ThemeManager._ApplyThemeToInstance(registryId, animate)
    local data = ThemeManager._Registry[registryId]
    if not data or not data.Instance then return end

    local propertiesToUpdate = {}
    for property, tag in pairs(data.Tags) do
        propertiesToUpdate[property] = ThemeManager.GetColor(tag)
    end

    if animate and TweenPlay then
        TweenPlay(data.Instance, nil, propertiesToUpdate)
    else
        for prop, val in pairs(propertiesToUpdate) do
            data.Instance[prop] = val
        end
    end
end

function ThemeManager.Register(instance, themeTags)
    -- Generar un ID único basado en memoria
    local registryId = tostring(instance) .. "_" .. tostring(math.random(100000, 999999))
    
    ThemeManager._Registry[registryId] = {
        Instance = instance,
        Tags = themeTags
    }

    -- Aplicar tema sin animación en la creación inicial
    ThemeManager._ApplyThemeToInstance(registryId, false)

    -- Garbage Collection automático: eliminar del registro si el objeto es destruido
    local connection
    connection = instance.Destroying:Connect(function()
        ThemeManager._Registry[registryId] = nil
        if connection then connection:Disconnect() end
    end)
end

function ThemeManager.SetTheme(themeName)
    if not ThemeManager.Themes[themeName] then
        warn(string.format("[Silent:Theme] Theme '%s' does not exist.", tostring(themeName)))
        return
    end

    ThemeManager.CurrentTheme = themeName
    
    for registryId, _ in pairs(ThemeManager._Registry) do
        ThemeManager._ApplyThemeToInstance(registryId, true)
    end
end

return ThemeManager
