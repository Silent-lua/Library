-- Silent Framework | Core/ThemeManager.lua
-- Responsabilidad: Registro de componentes, gestión de 20 paletas y actualización dinámica.

local ThemeManager = {
    Themes = {
        -- ==========================================
        -- TEMAS OSCUROS (Dark)
        -- ==========================================
        -- Dark Puro (AMOLED): Fondo 0,0,0 y Texto 255,255,255
        ["Dark"] = { Background = Color3.fromRGB(0, 0, 0), Panel = Color3.fromRGB(15, 15, 15), Border = Color3.fromRGB(35, 35, 35), Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(150, 150, 150), Accent = Color3.fromRGB(80, 180, 255) },
        
        ["Midnight"] = { Background = Color3.fromRGB(10, 14, 23), Panel = Color3.fromRGB(18, 25, 40), Border = Color3.fromRGB(35, 45, 65), Text = Color3.fromRGB(230, 235, 245), TextMuted = Color3.fromRGB(140, 155, 180), Accent = Color3.fromRGB(100, 150, 255) },
        ["Dracula"] = { Background = Color3.fromRGB(40, 42, 54), Panel = Color3.fromRGB(68, 71, 90), Border = Color3.fromRGB(98, 114, 164), Text = Color3.fromRGB(248, 248, 242), TextMuted = Color3.fromRGB(191, 191, 191), Accent = Color3.fromRGB(189, 147, 249) },
        ["Nord"] = { Background = Color3.fromRGB(46, 52, 64), Panel = Color3.fromRGB(59, 66, 82), Border = Color3.fromRGB(76, 86, 106), Text = Color3.fromRGB(236, 239, 244), TextMuted = Color3.fromRGB(216, 222, 233), Accent = Color3.fromRGB(136, 192, 208) },
        ["Mocha"] = { Background = Color3.fromRGB(30, 30, 46), Panel = Color3.fromRGB(49, 50, 68), Border = Color3.fromRGB(69, 71, 90), Text = Color3.fromRGB(205, 214, 244), TextMuted = Color3.fromRGB(166, 173, 200), Accent = Color3.fromRGB(203, 166, 247) },
        ["Monokai"] = { Background = Color3.fromRGB(39, 40, 34), Panel = Color3.fromRGB(62, 61, 50), Border = Color3.fromRGB(89, 89, 89), Text = Color3.fromRGB(248, 248, 242), TextMuted = Color3.fromRGB(160, 160, 160), Accent = Color3.fromRGB(166, 226, 46) },
        ["Crimson"] = { Background = Color3.fromRGB(15, 5, 5), Panel = Color3.fromRGB(25, 10, 10), Border = Color3.fromRGB(45, 20, 20), Text = Color3.fromRGB(255, 230, 230), TextMuted = Color3.fromRGB(180, 130, 130), Accent = Color3.fromRGB(255, 60, 60) },
        ["Forest"] = { Background = Color3.fromRGB(10, 20, 15), Panel = Color3.fromRGB(20, 35, 25), Border = Color3.fromRGB(40, 60, 45), Text = Color3.fromRGB(230, 245, 235), TextMuted = Color3.fromRGB(150, 180, 160), Accent = Color3.fromRGB(80, 220, 140) },
        ["Ocean"] = { Background = Color3.fromRGB(8, 16, 26), Panel = Color3.fromRGB(18, 30, 45), Border = Color3.fromRGB(35, 55, 75), Text = Color3.fromRGB(220, 240, 255), TextMuted = Color3.fromRGB(130, 170, 200), Accent = Color3.fromRGB(60, 180, 230) },
        ["Grape"] = { Background = Color3.fromRGB(20, 10, 30), Panel = Color3.fromRGB(35, 20, 50), Border = Color3.fromRGB(60, 35, 80), Text = Color3.fromRGB(245, 230, 255), TextMuted = Color3.fromRGB(180, 150, 200), Accent = Color3.fromRGB(190, 100, 255) },
        ["Cyberpunk"] = { Background = Color3.fromRGB(15, 5, 25), Panel = Color3.fromRGB(30, 15, 45), Border = Color3.fromRGB(60, 20, 80), Text = Color3.fromRGB(255, 240, 255), TextMuted = Color3.fromRGB(180, 150, 200), Accent = Color3.fromRGB(255, 255, 0) },
        ["SolarDark"] = { Background = Color3.fromRGB(0, 43, 54), Panel = Color3.fromRGB(7, 54, 66), Border = Color3.fromRGB(88, 110, 117), Text = Color3.fromRGB(131, 148, 150), TextMuted = Color3.fromRGB(101, 123, 131), Accent = Color3.fromRGB(42, 161, 152) },
        ["Rose"] = { Background = Color3.fromRGB(30, 15, 20), Panel = Color3.fromRGB(50, 25, 35), Border = Color3.fromRGB(80, 40, 55), Text = Color3.fromRGB(255, 230, 240), TextMuted = Color3.fromRGB(200, 150, 170), Accent = Color3.fromRGB(255, 120, 160) },
        ["Slate"] = { Background = Color3.fromRGB(25, 29, 35), Panel = Color3.fromRGB(35, 41, 49), Border = Color3.fromRGB(55, 63, 75), Text = Color3.fromRGB(220, 225, 230), TextMuted = Color3.fromRGB(150, 160, 175), Accent = Color3.fromRGB(110, 160, 220) },

        -- ==========================================
        -- TEMAS CLAROS (Light)
        -- ==========================================
        -- Light Puro: Fondo 255,255,255 y Texto 0,0,0
        ["Light"] = { Background = Color3.fromRGB(255, 255, 255), Panel = Color3.fromRGB(240, 240, 240), Border = Color3.fromRGB(215, 215, 215), Text = Color3.fromRGB(0, 0, 0), TextMuted = Color3.fromRGB(100, 100, 100), Accent = Color3.fromRGB(0, 120, 200) },
        
        ["Latte"] = { Background = Color3.fromRGB(239, 241, 245), Panel = Color3.fromRGB(204, 208, 218), Border = Color3.fromRGB(172, 176, 190), Text = Color3.fromRGB(76, 79, 105), TextMuted = Color3.fromRGB(124, 127, 147), Accent = Color3.fromRGB(30, 102, 245) },
        ["SolarLight"] = { Background = Color3.fromRGB(253, 246, 227), Panel = Color3.fromRGB(238, 232, 213), Border = Color3.fromRGB(200, 195, 180), Text = Color3.fromRGB(101, 123, 131), TextMuted = Color3.fromRGB(147, 161, 161), Accent = Color3.fromRGB(38, 139, 210) },
        ["Mint"] = { Background = Color3.fromRGB(235, 250, 240), Panel = Color3.fromRGB(215, 240, 225), Border = Color3.fromRGB(180, 220, 195), Text = Color3.fromRGB(20, 50, 30), TextMuted = Color3.fromRGB(80, 120, 95), Accent = Color3.fromRGB(40, 180, 100) },
        ["Peach"] = { Background = Color3.fromRGB(255, 240, 235), Panel = Color3.fromRGB(255, 225, 215), Border = Color3.fromRGB(240, 195, 180), Text = Color3.fromRGB(80, 40, 30), TextMuted = Color3.fromRGB(140, 90, 75), Accent = Color3.fromRGB(240, 100, 70) },
        ["Lavender"] = { Background = Color3.fromRGB(245, 240, 255), Panel = Color3.fromRGB(230, 220, 250), Border = Color3.fromRGB(210, 190, 235), Text = Color3.fromRGB(60, 40, 80), TextMuted = Color3.fromRGB(120, 90, 150), Accent = Color3.fromRGB(140, 80, 220) },
    },
    CurrentTheme = "Dark",
    _Registry = {}
}

local TweenPlay = nil
function ThemeManager.InitDependencies(tweenFunc) TweenPlay = tweenFunc end

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
    local registryId = tostring(instance) .. "_" .. tostring(math.random(100000, 999999))
    ThemeManager._Registry[registryId] = { Instance = instance, Tags = themeTags }
    ThemeManager._ApplyThemeToInstance(registryId, false)
    
    local connection
    connection = instance.Destroying:Connect(function()
        ThemeManager._Registry[registryId] = nil
        if connection then connection:Disconnect() end
    end)
end

function ThemeManager.SetTheme(themeName)
    if not ThemeManager.Themes[themeName] then return end
    ThemeManager.CurrentTheme = themeName
    
    for registryId, _ in pairs(ThemeManager._Registry) do
        ThemeManager._ApplyThemeToInstance(registryId, true)
    end
end

function ThemeManager.GetThemeNames()
    local names = {}
    for name, _ in pairs(ThemeManager.Themes) do 
        table.insert(names, name) 
    end
    table.sort(names)
    return names
end

return ThemeManager
