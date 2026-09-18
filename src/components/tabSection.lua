


local TabSection = {}
TabSection.__index = TabSection
TabSection.__type = "TabSection"

local locale = require(script.Parent.Parent.utility.locale)
local log = require(script.Parent.Parent.utility.log)

local sectionInset = 20

local spacingAbove = 6

local spacingBelow = 3

local function anythingAbove(window)
    for _, tab in window.tabs do
        if not tab.neglectSelector then
            return true
        end
    end
    return #window.tabSections > 0
end

function TabSection.new(window, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local self = setmetatable({
        window = assert(window, "Missing argument #1 (Window expected)"),
        name = properties.name or properties.Name or "Section",
        icon = properties.icon or properties.Icon,
    }, TabSection)

    if window.layout.mode ~= "sidebar" then
        if not window._warnedTabSection then
            window._warnedTabSection = true
            log.warn("Library: Window:CreateSection needs the sidebar layout; it does nothing on the top strip.")
        end
        self.inert = true
        return self
    end

    self.main = window:Create("Frame", {
        Name = self.name,
        Size = UDim2.new(1, -sectionInset * 2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Visible = false,

        Parent = window.tabList,
    })

    self.padding = window:Create("UIPadding", {
        PaddingTop = UDim.new(0, if anythingAbove(window) then spacingAbove else 0),
        PaddingBottom = UDim.new(0, spacingBelow),

        Parent = self.main,
    })

    window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        Parent = self.main,
    })

    if self.icon then
        self.iconLabel = window:Create("ImageLabel", {
            Image = self.icon,
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 0,

            ImageTransparency = 1,

            Parent = self.main,
        }, { ImageColor3 = "ContentColor" })
    end

    self.title = window:Create("TextLabel", {
        Text = locale.t(self.name),

        Size = UDim2.fromOffset(0, 15),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        TextWrapped = true,
        LayoutOrder = 1,

        TextTransparency = 1,

        Parent = self.main,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    return self
end

function TabSection:_setShown(shown, animate)
    if not self.main then
        return
    end
    local w = self.window
    w:_reveal(self.title, { TextTransparency = if shown then 0.6 else 1 }, animate)
    if self.iconLabel then
        w:_reveal(self.iconLabel, { ImageTransparency = if shown then 0.65 else 1 }, animate)
    end
end

function TabSection:_setVisible(visible)
    if self.main then
        self.main.Visible = visible
    end
end

function TabSection:Remove()
    local index = table.find(self.window.tabSections, self)
    if index then
        table.remove(self.window.tabSections, index)
    end
    self.window:DestroySubtree(self.main)
    self.main = nil
end

return TabSection
