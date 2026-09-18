


local layouts = require(script.Parent.layouts)

local windowSizing = {}

export type Profile = {
    defaultSize: Vector2,
    minSize: Vector2,

    maxOccupancyX: number,
    maxOccupancyY: number?,
    marginFloorX: number,
    marginFloorY: number,

    topbarClearance: number?,

    maxAspectRatio: number,
    minAspectRatio: number?,

    widthCompensation: number?,

    chromeHeight: number,
}

local minPlausibleViewport = 200

local profiles = {
    top = {
        defaultSize = Vector2.new(475, 500),
        minSize = Vector2.new(300, 285),

        maxOccupancyX = 0.86,
        topbarClearance = 36,
        marginFloorX = 24,
        marginFloorY = 28,

        maxAspectRatio = 2.3,
        widthCompensation = 130,

        chromeHeight = layouts.top.chromeHeight,
    } :: Profile,
    sidebar = {
        defaultSize = Vector2.new(685, 450),
        minSize = Vector2.new(560, 350),

        maxOccupancyX = 0.92,
        maxOccupancyY = 0.8,
        marginFloorX = 24,
        marginFloorY = 28,

        maxAspectRatio = 2.6,
        minAspectRatio = 1.2,

        chromeHeight = layouts.sidebar.chromeHeight,
    } :: Profile,
}

function windowSizing.profile(mode: layouts.Mode?): Profile
    if mode == "sidebar" then
        return profiles.sidebar
    end
    return profiles.top
end

function windowSizing.pageHeight(windowHeight: number?, mode: layouts.Mode?): number
    local profile = windowSizing.profile(mode)
    local height = if windowHeight and windowHeight > 0 then windowHeight else profile.minSize.Y
    return math.max(height - profile.chromeHeight, 0)
end

local function availableHeight(profile: Profile, viewportY: number): number
    local limit = viewportY - profile.marginFloorY
    if profile.topbarClearance then
        limit = math.min(limit, viewportY - profile.topbarClearance * 2)
    end
    if profile.maxOccupancyY then
        limit = math.min(limit, viewportY * profile.maxOccupancyY)
    end
    return limit
end

local function deficit(actual: number, ideal: number, floor: number): number
    return math.clamp((ideal - actual) / (ideal - floor), 0, 1)
end

local function fitVertical(profile: Profile, availableX: number, availableY: number): UDim2
    local height = math.floor(math.min(math.clamp(availableY, profile.minSize.Y, profile.defaultSize.Y), availableY))
    local lost = deficit(height, profile.defaultSize.Y, profile.minSize.Y)
    local width = math.max(profile.defaultSize.X + (profile.widthCompensation :: number) * lost, profile.minSize.X)

    return UDim2.fromOffset(math.floor(math.min(width, availableX, height * profile.maxAspectRatio)), height)
end

local function fitHorizontal(profile: Profile, availableX: number, availableY: number): UDim2
    local width = math.min(math.clamp(availableX, profile.minSize.X, profile.defaultSize.X), availableX)
    local height = math.min(math.clamp(availableY, profile.minSize.Y, profile.defaultSize.Y), availableY)

    height = math.floor(math.min(height, width / (profile.minAspectRatio :: number)))
    width = math.floor(math.min(width, height * profile.maxAspectRatio))

    return UDim2.fromOffset(width, height)
end

function windowSizing.fit(viewport: Vector2?, mode: layouts.Mode?): UDim2
    local profile = windowSizing.profile(mode)

    if not viewport or viewport.X < minPlausibleViewport or viewport.Y < minPlausibleViewport then
        return UDim2.fromOffset(profile.defaultSize.X, profile.defaultSize.Y)
    end

    local availableX = math.min(viewport.X * profile.maxOccupancyX, viewport.X - profile.marginFloorX)
    local availableY = availableHeight(profile, viewport.Y)

    if profile.minAspectRatio then
        return fitHorizontal(profile, availableX, availableY)
    end
    return fitVertical(profile, availableX, availableY)
end

return windowSizing
