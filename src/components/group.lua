

local Group = {}
Group.__index = Group
Group.__type = "Group"


local moveable = require(script.Parent.Parent.utility.moveable)
local log = require(script.Parent.Parent.utility.log)
local assignOrder = require(script.Parent.Parent.utility.ordering)

local elementPadding = 8

local compactCapable = {
    button = true,
    toggle = true,
    stat = true,
    slider = true,
}

function Group.new(tab, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local dir = string.lower(properties.direction or properties.Direction or "row")
    local vertical = dir == "column" or dir == "vertical"
    local horizontal = not vertical
    local direction = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical

    local self = setmetatable({
        tab = assert(tab, "Missing argument #1 (Tab expected)"),
        window = tab.window,
        direction = direction,
        compact = horizontal,
        forgetState = tab.forgetState,
        elements = {},
    }, Group)

    local nestedInRow = tab.direction == Enum.FillDirection.Horizontal

    self.main = self.window:Create("Frame", {
        Name = "Group",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = if horizontal then UDim2.new(1, -20, 0, 0) else UDim2.new(1, 0, 0, 0),

        Parent = self.tab.tabPage,
    })

    if nestedInRow then
        self.main.Size = UDim2.new(0, 0, 0, 0)
        self.window:Create("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Fill,
            Parent = self.main,
        })
    end

    self.tabPage = self.main

    self.layout = self.window:Create("UIListLayout", {
        FillDirection = direction,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, elementPadding),
        VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
        HorizontalAlignment = if horizontal then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center,

        Parent = self.main,
    })

    return self
end

function Group:_add(componentName, properties)
    if self.compact and not compactCapable[componentName] then
        log.warn(
            `Library: a row only holds compact elements (button/toggle/stat/slider), ignoring '{componentName}'. Use a column for it.`
        )
        return nil
    end

    local element = require(script.Parent[componentName]).new(self, properties)
    table.insert(self.elements, element)
    assignOrder(element, #self.elements * 10)
    self.window:_restoreLate(element)

    if self.compact then
        self:_wrapChild(element)
    end
    self:_reflowRow()

    if not self.window.hidden then
        element:_setShown(true, true)
    end

    return element
end

function Group:_reflowRow()
    if self.direction ~= Enum.FillDirection.Horizontal then
        return
    end

    local onlyGroups = #self.elements > 0
    for _, element in self.elements do
        if element.__type ~= "Group" then
            onlyGroups = false
            break
        end
    end

    self.layout.Padding = if onlyGroups then UDim.new(0, -10) else UDim.new(0, elementPadding)
end

function Group:_wrapChild(element)
    self.layout.Wraps = true
    self.layout.HorizontalFlex = Enum.UIFlexAlignment.Fill

    element._widthManaged = true

    local minWidth = if element._minWidth then element:_minWidth() else 0
    if minWidth > 0 then
        element.main.AutomaticSize = Enum.AutomaticSize.None
        element.main.Size = UDim2.new(0, minWidth, element.main.Size.Y.Scale, element.main.Size.Y.Offset)
    end
end

function Group:CreateButton(properties)
    return self:_add("button", properties)
end
function Group:CreateToggle(properties)
    return self:_add("toggle", properties)
end
function Group:CreateSwitch(properties)
    return self:_add("toggle", properties)
end
function Group:CreateStat(properties)
    return self:_add("stat", properties)
end
function Group:CreateSlider(properties)
    return self:_add("slider", properties)
end
function Group:CreateDropdown(properties)
    return self:_add("dropdown", properties)
end
function Group:CreateSection(properties)
    return self:_add("section", properties)
end
function Group:CreateText(properties)
    return self:_add("text", properties)
end
function Group:CreateDivider(properties)
    return self:_add("divider", properties)
end

function Group:_addGroup(properties)
    properties = if typeof(properties) == "table" then table.clone(properties) else {}

    if self.direction == Enum.FillDirection.Horizontal then
        self.layout.VerticalAlignment = Enum.VerticalAlignment.Top
        if self.tab.direction ~= Enum.FillDirection.Horizontal then
            self.main.Size = UDim2.new(1, 0, 0, 0)
        end
    end

    local group = Group.new(self, properties)
    table.insert(self.elements, group)
    group.main.LayoutOrder = #self.elements * 10
    self:_reflowRow()
    return group
end

function Group:CreateGroup(properties)
    return self:_addGroup(properties)
end

function Group:_moveElement(element, targetIndex)
    local idx = table.find(self.elements, element)
    if not idx then
        return
    end
    table.remove(self.elements, idx)
    targetIndex = math.clamp(targetIndex, 1, #self.elements + 1)
    table.insert(self.elements, targetIndex, element)
    for i, el in self.elements do
        assignOrder(el, i * 10)
    end
end

function Group:_setShown(shown, animate)
    for _, el in self.elements do
        el:_setShown(shown, animate)
    end
end

function Group:_refreshTheme()
    for _, el in self.elements do
        if el._refreshTheme then
            el:_refreshTheme()
        end
    end
end

moveable(Group)

return Group
