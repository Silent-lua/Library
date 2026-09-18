

local Tab = {}
Tab.__index = Tab
Tab.__type = "Tab"

local utility = script.Parent.Parent.utility

local variables = require(utility.variables)
local assignOrder = require(utility.ordering)
local hapticEngine = require(utility.HapticEngine)
local search = require(script.Parent.search)
local tabSelector = require(script.Parent.tabSelector)

local function teardownElements(window, elements)
    for _, element in elements do
        if element.__type == "Group" then
            teardownElements(window, element.elements)
        else
            window:_unregisterControl(element)
        end

        if element.connections then
            for _, connection in element.connections do
                window:Disconnect(connection)
            end
            element.connections = nil
        end

        if element._dragConnection then
            element._dragConnection:Disconnect()
            element._dragConnection = nil
        end
        if window._recordingKeybind == element then
            window._recordingKeybind = nil
        end
        if element._outsideClickConn then
            window:Disconnect(element._outsideClickConn)
            element._outsideClickConn = nil
        end
    end
end

local selectTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local hoverTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function Tab.new(window, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local self = setmetatable({
        window = assert(window, "Missing argument #1 (Window expected)"),
        name = properties.name or properties.Name,
        icon = properties.icon or properties.Icon,
        neglectSelector = properties.neglectSelector or properties.NeglectSelector or false,
        customOrder = properties.customOrder or properties.CustomOrder or 0,
        forgetState = properties.forgetState or properties.ForgetState or false,

        elements = {},
        connections = {},
    }, Tab)

    assert(self.name or self.icon, "A tab needs a name or an icon.")

    if not self.neglectSelector then
        tabSelector.build(self, self.window.layout)
    end

    self.tabPage = self.window:Create("ScrollingFrame", {
        Name = self.name,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 68),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,

        LayoutOrder = self.customOrder or 0,

        Parent = self.window.elements,
    })

    self.tabPageLayout = self.window:Create("UIListLayout", {
        Padding = UDim.new(0, 7),
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.tabPage,
    })

    self.window:Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 33),

        Parent = self.tabPage,
    })

    if not self.neglectSelector then
        table.insert(
            self.connections,
            self.window:Connect(self.topbarItemInteract.MouseButton1Click, function()
                hapticEngine.click()
                self:Select()
            end)
        )

        table.insert(
            self.connections,
            self.window:Connect(self.topbarItemInteract.MouseEnter, function()
                if not self.window:_interactive() then
                    return
                end
                if self.window.selectedTab ~= self then
                    self:_applyVisual("hover", hoverTweenInfo)
                    self:_spinGradients()
                end
            end)
        )

        table.insert(
            self.connections,
            self.window:Connect(self.topbarItemInteract.MouseLeave, function()
                if self.window.selectedTab ~= self then
                    self:_applyVisual("unselected", hoverTweenInfo)
                end
            end)
        )
    end


    return self
end

function Tab:_applyVisual(stateName, tweenInfo)
    if self.neglectSelector or not self.topbarItem then
        return
    end

    local state = tabSelector.states[self.window.layout.mode][stateName]
    if not state then
        return
    end

    tabSelector.applyVisual(self, state, tweenInfo)
end

function Tab:_spinGradients()
    if self.neglectSelector then
        return
    end

    local spinInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    for _, gradient in { self.topbarItemGradient, self.topbarItemStrokeGradient } do
        gradient.Rotation = 90 - 360
        variables.tweenService:Create(gradient, spinInfo, { Rotation = 90 }):Play()
    end
end

function Tab:Select(noAnimation)
    if self.window._searching then
        search.close(self.window, { showTabs = true, jumpTo = false })
    end

    self.window.selectedTab = self
    self.window:_jumpTo(self.tabPage)

    local skipAnimation = noAnimation or not self.window:_interactive()

    if not self.neglectSelector and not skipAnimation then
        self:_applyVisual("selected", selectTweenInfo)
    end

    for _, tab in self.window.tabs do
        if tab ~= self.window.selectedTab then
            tab:Deselect(skipAnimation)
        end
    end

    if self ~= self.window.rfSettings and self.window.settingsAction and not skipAnimation then
        variables.tweenService
            :Create(
                self.window.settingsAction.iconLabel,
                TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { ImageTransparency = 0.6 }
            )
            :Play()
    end
end

function Tab:Deselect(noAnimation)
    if not self.neglectSelector and not noAnimation then
        self:_applyVisual("unselected", selectTweenInfo)
    end
end

function Tab:_register(element)
    table.insert(self.elements, element)
    assignOrder(element, #self.elements * 10)
    self.window:_restoreLate(element)

    if not self.window.hidden then
        element:_setShown(true, true)
    end

    return element
end

function Tab:CreateButton(properties)
    return self:_register(require(script.Parent.button).new(self, properties))
end

function Tab:CreateToggle(properties)
    return self:_register(require(script.Parent.toggle).new(self, properties))
end

function Tab:CreateSwitch(properties)
    return self:CreateToggle(properties)
end

function Tab:CreateSection(properties)
    return self:_register(require(script.Parent.section).new(self, properties))
end

function Tab:CreateText(properties)
    return self:_register(require(script.Parent.text).new(self, properties))
end

function Tab:CreateDivider(properties)
    return self:_register(require(script.Parent.divider).new(self, properties))
end

function Tab:CreateProgress(properties)
    return self:_register(require(script.Parent.progress).new(self, properties))
end

function Tab:CreateConsole(properties)
    return self:_register(require(script.Parent.console).new(self, properties))
end

function Tab:CreateStat(properties)
    return self:_register(require(script.Parent.stat).new(self, properties))
end

function Tab:CreateSlider(properties)
    return self:_register(require(script.Parent.slider).new(self, properties))
end

function Tab:CreateDropdown(properties)
    return self:_register(require(script.Parent.dropdown).new(self, properties))
end

function Tab:CreateInput(properties)
    return self:_register(require(script.Parent.input).new(self, properties))
end

function Tab:CreateKeybind(properties)
    return self:_register(require(script.Parent.keybind).new(self, properties))
end

function Tab:CreateColorPicker(properties)
    return self:_register(require(script.Parent.colorpicker).new(self, properties))
end

function Tab:CreateGroup(properties)
    return self:_register(require(script.Parent.group).new(self, properties))
end

function Tab:_moveElement(element, targetIndex)
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

function Tab:Remove()
    local window = self.window

    if window._searching then
        search.close(window, { showTabs = true, jumpTo = window.selectedTab and window.selectedTab.tabPage })
    end

    local idx = table.find(window.tabs, self)
    if idx then
        table.remove(window.tabs, idx)
    end

    if window.selectedTab == self then
        window.selectedTab = nil
        for _, tab in ipairs(window.tabs) do
            if not tab.neglectSelector then
                tab:Select()
                break
            end
        end
    end

    teardownElements(window, self.elements)

    for _, connection in self.connections do
        window:Disconnect(connection)
    end
    self.connections = {}

    if self.topbarItem then
        window:DestroySubtree(self.topbarItem)
    end
    if self.tabPage then
        window:DestroySubtree(self.tabPage)
    end
    self.topbarItem = nil
    self.tabPage = nil
    self.elements = {}
end

return Tab
