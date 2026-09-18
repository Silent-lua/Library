

local colors = {}

function colors.contrastColor(color: Color3): Color3
    local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
    return if luminance > 0.5 then Color3.fromRGB(0, 0, 0) else Color3.fromRGB(255, 255, 255)
end

function colors.toColorSequence(color: Color3 | ColorSequence): ColorSequence
    return if typeof(color) == "ColorSequence" then color else ColorSequence.new(color)
end

function colors.contrastText(color: Color3): Color3
    local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
    return if luminance > 0.6 then Color3.fromRGB(20, 20, 20) else Color3.fromRGB(255, 255, 255)
end

return colors
