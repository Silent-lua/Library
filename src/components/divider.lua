


local Divider = {}
Divider.__index = Divider
Divider.__type = "Divider"

local moveable = require(script.Parent.Parent.utility.moveable)
local locale = require(script.Parent.Parent.utility.locale)

local lineThickness = 1
local defaultSpacing = 12
local labelGap = 10
local labelHeight = 14
local textSize = 12

local lineShown = 0.88
local labelShown = 0.55

function Divider.new(tab, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local spacing = properties.spacing or properties.Spacing
    local text = properties.text or properties.Text

    local self = setmetatable({
        tab = assert(tab, "Missing argument #1 (Tab expected)"),
        window = tab.window,
        text = if text ~= nil then tostring(text) else "",
        spacing = if type(spacing) == "number" then math.max(spacing, 0) else defaultSpacing,
        line = properties.line ~= false and properties.Line ~= false,
    }, Divider)

    self.main = self.window:Create("Frame", {
        Size = UDim2.new(1, -40, 0, 0),
        BorderSizePixel = 0,
        Name = "Divider",
        BackgroundTransparency = 1,

        Parent = self.tab.tabPage,
    })

    self.window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, labelGap),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,

        Parent = self.main,
    })

    if self.line then
        self.left = self:_buildHalf(1)
    end

    if self.text ~= "" then
        self:_buildLabel()
    end

    self:_applyHeight()

    return self
end

function Divider:_buildHalf(order)
    local rule = self.window:Create("Frame", {
        Size = UDim2.new(0, 0, 0, lineThickness),
        BorderSizePixel = 0,
        LayoutOrder = order,

        BackgroundTransparency = 1,

        Parent = self.main,
    }, { BackgroundColor3 = "ContentColor" })

    self.window:Create("UIFlexItem", {
        FlexMode = Enum.UIFlexMode.Fill,

        Parent = rule,
    })

    return rule
end

function Divider:_buildLabel()
    self.title = self.window:Create("TextLabel", {
        Text = locale.t(self.text),
        Size = UDim2.fromOffset(0, labelHeight),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        TextSize = textSize,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 2,

        TextTransparency = 1,

        Parent = self.main,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    if self.line then
        self.right = self:_buildHalf(3)
    end
end

function Divider:_applyHeight()
    local content = if self.text ~= "" then labelHeight elseif self.line then lineThickness else 0
    self.main.Size = UDim2.new(1, -40, 0, self.spacing * 2 + content)
end

function Divider:Set(text)
    self.text = if text ~= nil then tostring(text) else ""

    if self.text ~= "" and not self.title then
        self:_buildLabel()

        if not self.window.hidden then
            self:_setShown(true, true)
        end
    end

    if self.title then
        self.window:_bindLocale(self.title, "Text", self.text)

        local named = self.text ~= ""
        self.title.Visible = named
        if self.right then
            self.right.Visible = named
        end
    end

    self:_applyHeight()
end

function Divider:_setShown(shown, animate)
    local w = self.window
    local ruleTransparency = if shown then lineShown else 1

    w:_reveal(self.left, { BackgroundTransparency = ruleTransparency }, animate)
    w:_reveal(self.right, { BackgroundTransparency = ruleTransparency }, animate)
    w:_reveal(self.title, { TextTransparency = if shown then labelShown else 1 }, animate)
end

moveable(Divider)

return Divider
