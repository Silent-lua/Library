

local variables = require(script.Parent.variables)
local textService = variables.textService

local textMetrics = {}

local widthCache: { [string]: number } = {}
local widthCacheCount = 0
local widthCacheCap = 1024

local function getTextBounds(params: GetTextBoundsParams): unknown
    local ok, bounds = pcall(function()
        return textService:GetTextBoundsAsync(params)
    end)
    return if ok then bounds else nil
end

local function boundAxis(bounds: unknown, axis: "X" | "Y"): number?
    if typeof(bounds) == "Vector2" then
        return if axis == "X" then bounds.X else bounds.Y
    end
    if type(bounds) == "table" and type((bounds :: any)[axis]) == "number" then
        return (bounds :: any)[axis]
    end
    return nil
end

function textMetrics.textWidth(font: Font, size: number, text: any): number
    text = tostring(text)
    local key = tostring(font.Family)
        .. "|"
        .. tostring(font.Weight)
        .. "|"
        .. tostring(font.Style)
        .. "|"
        .. tostring(size)
        .. "|"
        .. text
    local cached = widthCache[key]
    if cached then
        return cached
    end

    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Font = font
    params.Size = size
    params.Width = math.huge

    local measuredWidth = boundAxis(getTextBounds(params), "X")
    if not measuredWidth then
        local length = utf8.len(text) or #text
        return math.ceil(size * 0.55 * length)
    end

    local width = math.ceil(measuredWidth)
    if widthCacheCount >= widthCacheCap then
        widthCache = {}
        widthCacheCount = 0
    end
    widthCache[key] = width
    widthCacheCount += 1
    return width
end

function textMetrics.textHeight(font: Font, size: number, text: any, width: number): number
    local params = Instance.new("GetTextBoundsParams")
    params.Text = tostring(text)
    params.Font = font
    params.Size = size
    params.Width = width

    local measuredHeight = boundAxis(getTextBounds(params), "Y")
    return if measuredHeight then math.ceil(measuredHeight) else size
end

return textMetrics
