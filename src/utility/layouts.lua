


local layouts = {}

local topbarHeight = 64

local tabStripTop = topbarHeight - 1
local tabStripHeight = 38
local tabStripGap = 3



layouts.top = {
    mode = "top",

    topbarHeight = topbarHeight,
    chromeHeight = tabStripTop + tabStripHeight + tabStripGap,

    tabStripTop = tabStripTop,
    tabStripHeight = tabStripHeight,

    pageDirection = Enum.FillDirection.Horizontal,

    fadeSize = UDim2.new(1, 0, -0.093, 100),
    fadeTransparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.4414, 0),
        NumberSequenceKeypoint.new(0.7007, 0.631),
        NumberSequenceKeypoint.new(1, 1),
    }),
}

layouts.sidebar = {
    mode = "sidebar",

    topbarHeight = topbarHeight,
    chromeHeight = topbarHeight,

    railWidth = 219,
    railCollapsedWidth = 64,
    railCollapseBelow = 589,

    rowHeight = 38,
    rowCornerRadius = 14,
    rowSpacing = 4,
    railPadding = 17,
    rowInset = 15,
    rowPadding = 10,
    rowContentSpacing = 6,
    rowIconSize = 20,

    footerHeight = 60,
    avatarSize = 34,

    pageDirection = Enum.FillDirection.Vertical,

    cardTransparency = 0.98,
    cardStrokeRotation = 55,
    cardCorners = { "TopLeftRadius", "BottomRightRadius" },
    cardStrokeTransparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.128, 0.95),
        NumberSequenceKeypoint.new(0.414, 0.985),
        NumberSequenceKeypoint.new(1, 1),
    }),

    fadeSize = UDim2.new(1, 0, 0, 55),
    fadeTransparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.377, 0),
        NumberSequenceKeypoint.new(1, 1),
    }),
    fadeCorners = { "BottomRightRadius" },
}

function layouts.get(mode)
    if mode == "sidebar" then
        return layouts.sidebar
    elseif mode == "top" then
        return layouts.top
    end
    return nil
end

function layouts.railWidthFor(layout, windowWidth)
    if layout.mode ~= "sidebar" then
        return 0
    end
    local full = layout.railWidth :: number
    if windowWidth < (layout.railCollapseBelow :: number) then
        return layout.railCollapsedWidth :: number
    end
    return full
end

return layouts
