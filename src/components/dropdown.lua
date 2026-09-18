

local Dropdown = {}
Dropdown.__index = Dropdown
Dropdown.__type = "Dropdown"

local utility = script.Parent.Parent.utility

local variables = require(utility.variables)
local functions = require(utility.functions)
local image = require(utility.image)
local constants = require(utility.constants)
local locale = require(utility.locale)
local hapticEngine = require(utility.HapticEngine)
local windowSizing = require(utility.windowSizing)
local lockable = require(utility.lockable)

local chevronIcon = constants.icons.chevron
local checkIcon = constants.icons.check
local dotIcon = constants.icons.dot
local searchIconAsset = constants.icons.search

local roundRadius = UDim.new(0, 12)
local flatRadius = UDim.new(0, 7)

local searchCollapsedHeight = 30
local searchExpandedHeight = 38

local optionHeight = 38
local optionGap = 5
local listPadding = 2

local headerHeight = 41
local headerGap = 6
local cardPaddingTop = 7
local cardPaddingBottom = 6
local cardPadding = cardPaddingTop + cardPaddingBottom

local maxVisibleOptions = 4

local actionsHeight = 22
local hintTween = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local hoverTween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local scrollbarShown = 0.4
local searchTween = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local function dedupStrings(arr)
    local seen = {}
    local out = {}
    for _, v in arr do
        if typeof(v) == "string" and not seen[v] then
            seen[v] = true
            table.insert(out, v)
        end
    end
    return out
end

local function normalizeValue(value, multi)
    if value == nil then
        return {}
    end
    if typeof(value) == "string" then
        return { value }
    end
    if typeof(value) == "table" then
        local out = dedupStrings(value)
        if not multi and #out > 1 then
            return { out[1] }
        end
        return out
    end
    return {}
end

local function intersectWithOptions(value, options)
    local out = {}
    for _, v in value do
        if table.find(options, v) then
            table.insert(out, v)
        end
    end
    return out
end

local function sameSelection(a, b)
    if #a ~= #b then
        return false
    end
    for _, v in a do
        if not table.find(b, v) then
            return false
        end
    end
    return true
end

function Dropdown.new(tab, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local options = properties.options or properties.Options or {}
    local multiSelect = properties.multiSelect or properties.MultiSelect or properties.MultipleOptions or false

    local self = setmetatable({
        tab = assert(tab, "Missing argument #1 (Tab expected)"),
        window = tab.window,
        name = properties.name or properties.Name or "Dropdown",
        icon = properties.icon or properties.Icon,
        description = properties.description or properties.Description,
        forgetState = properties.forgetState or properties.ForgetState or tab.forgetState,

        flag = properties.flag
            or properties.Flag
            or (
                not (properties.forgetState or properties.ForgetState or tab.forgetState)
                    and functions.deriveFlagFromName(properties.name or properties.Name or "Dropdown")
                or nil
            ),

        callback = properties.callback or properties.Callback or function() end,

        options = dedupStrings(options),
        multiSelect = multiSelect,
        placeholderText = locale.resolve(properties.placeholder or properties.Placeholder or "None"),
        value = normalizeValue(
            properties.value or properties.Value or properties.currentOption or properties.CurrentOption,
            multiSelect
        ),

        _isOpen = false,
        _optionFrames = {},
    }, Dropdown)

    self._desiredValue = self.value
    self.value = intersectWithOptions(self.value, self.options)

    self.window:_registerControl(self)

    self.main = self.window:Create("Frame", {
        Size = UDim2.new(1, -20, 0, 41),
        BorderSizePixel = 0,
        Name = self.name,
        BackgroundTransparency = 1,

        Parent = self.tab.tabPage,
    })

    self.top = self.window:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 41),
        Position = UDim2.fromScale(0, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        ZIndex = 1,

        Parent = self.main,
    }, { BackgroundTransparency = "ElementTransparency" })

    self.stroke = self.window:StyleElementBody(self.top)
    self.hoverOverlay = self.window:CreateHoverOverlay(self.top)
    self.flashTarget = self.top

    self.container = self.window:Create("Frame", {
        BorderSizePixel = 0,

        Parent = self.top,
        Size = UDim2.new(0, 170, 0, 16),
        Position = UDim2.new(0, 20, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 5,
    })

    self.containerLayout = self.window:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,

        Parent = self.container,
    })

    if self.icon then
        self.iconLabel = self.window:Create("ImageLabel", {
            Image = self.icon,
            Size = UDim2.fromOffset(16, 16),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,

            ImageTransparency = 1,

            ZIndex = 5,
            Parent = self.container,
        }, { ImageColor3 = "ContentColor" })
    end

    self.title = self.window:Create("TextLabel", {
        Text = locale.t(self.name),

        Size = UDim2.fromOffset(150, 16),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        TextSize = 16,
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 1,

        TextTransparency = 1,

        ZIndex = 5,
        Parent = self.container,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    self.selectedLabel = self.window:Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -41, 0.5, 0),
        Size = UDim2.fromOffset(168, 15),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextWrapped = true,

        TextTransparency = 1,

        ZIndex = 5,
        Parent = self.top,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    self.chevron = self.window:Create("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -18, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Image = "rbxassetid://" .. tostring(chevronIcon),
        Rotation = 180,

        ImageTransparency = 1,

        ZIndex = 5,
        Parent = self.top,
    }, { ImageColor3 = "ContentColor" })

    self.interact = self.window:Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 41),
        Position = UDim2.fromScale(0, 0),
        BorderSizePixel = 0,
        Text = "",
        TextTransparency = 1,
        ZIndex = 10,
        AutoButtonColor = false,

        Parent = self.main,
    })

    self.panel = self.window:Create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.new(1, 0, 1, -(headerHeight + headerGap)),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 1,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.panelStroke = self.window:StyleElementPanel(self.panel)

    self.window:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.panel,
    })

    self.window:Create("UIPadding", {
        PaddingTop = UDim.new(0, cardPaddingTop),
        PaddingBottom = UDim.new(0, cardPaddingBottom),

        Parent = self.panel,
    })

    self:_buildSearch()
    self:_buildActions()

    self.list = self.window:Create("ScrollingFrame", {
        Active = true,
        Size = UDim2.new(1, 0, 0, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollBarImageColor3 = Color3.fromRGB(240, 240, 240),
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 1,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        LayoutOrder = 3,
        ZIndex = 1,

        Parent = self.panel,
    })

    self.window:Create("UIFlexItem", {
        FlexMode = Enum.UIFlexMode.Fill,

        Parent = self.list,
    })

    self.window:ConnectFor(self, self.list:GetPropertyChangedSignal("CanvasPosition"), function()
        self:_syncScrollHint()
    end)
    self.window:ConnectFor(self, self.list:GetPropertyChangedSignal("AbsoluteCanvasSize"), function()
        self:_syncScrollHint()
    end)

    self.window:ConnectFor(self, self.list:GetPropertyChangedSignal("AbsoluteWindowSize"), function()
        self:_syncScrollHint()
    end)

    self.listLayout = self.window:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,

        Parent = self.list,
    })

    self.window:Create("UIPadding", {
        PaddingTop = UDim.new(0, listPadding),
        PaddingBottom = UDim.new(0, listPadding),

        Parent = self.list,
    })

    self.emptyLabel = self.window:Create("TextLabel", {
        Name = "Empty",
        Size = UDim2.new(1, -12, 0, optionHeight),
        BackgroundTransparency = 1,
        Text = locale.t("No matches"),
        TextSize = 14,
        TextTransparency = 0.55,
        Visible = false,
        LayoutOrder = 1,

        Parent = self.list,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    local function isOptionSelected(name)
        return table.find(self.value, name) ~= nil
    end

    local function renderOptionState(data, animate)
        local selected = isOptionSelected(data.name)
        local bgT = if self._isOpen then (selected and 0.9 or 0.95) else 1
        local titleT = if self._isOpen then (selected and 0 or 0.3) else 1
        local iconT = if self._isOpen then (selected and 0 or 0.7) else 1
        local strokeT = if self._isOpen then (selected and 0.85 or 0.93) else 1

        image.assign(data.checkIcon, "Image", if selected then checkIcon else dotIcon)

        if animate then
            local info = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            variables.tweenService:Create(data.frame, info, { BackgroundTransparency = bgT }):Play()
            variables.tweenService:Create(data.title, info, { TextTransparency = titleT }):Play()
            variables.tweenService:Create(data.checkIcon, info, { ImageTransparency = iconT }):Play()
            variables.tweenService:Create(data.stroke, info, { Transparency = strokeT }):Play()
        else
            data.frame.BackgroundTransparency = bgT
            data.title.TextTransparency = titleT
            data.checkIcon.ImageTransparency = iconT
            data.stroke.Transparency = strokeT
        end
    end

    local function updateSelectedLabel()
        if self.multiSelect then
            local n = #self.value
            if n == 0 then
                self.selectedLabel.Text = self.placeholderText
            elseif n == 1 then
                self.selectedLabel.Text = self.value[1]
            else
                self.selectedLabel.Text = locale.resolve("Various")
            end
        else
            self.selectedLabel.Text = self.value[1] or self.placeholderText
        end
    end

    self._renderOptionState = renderOptionState
    self._updateSelectedLabel = updateSelectedLabel

    local function buildOption(optionName)
        local frame = self.window:Create("Frame", {
            Size = UDim2.new(1, -12, 0, optionHeight),
            BorderSizePixel = 0,
            LayoutOrder = #self._optionFrames + 1,

            BackgroundTransparency = 1,

            Parent = self.list,
        }, { BackgroundColor3 = "DropdownHighlight" })

        local corner = self.window:Create("UICorner", {
            CornerRadius = flatRadius,
            Parent = frame,
        })

        local optionStroke = self.window:Create("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 1,
            Parent = frame,
        })

        local interact = self.window:Create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextTransparency = 1,
            ZIndex = 50,
            Parent = frame,
        })

        local container = self.window:Create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(170, 16),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = frame,
        })

        self.window:Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = container,
        })

        local checkIcon = self.window:Create("ImageLabel", {
            Image = "rbxassetid://" .. tostring(checkIcon),
            Size = UDim2.fromOffset(16, 16),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ImageTransparency = 1,
            ZIndex = 5,
            Parent = container,
        }, { ImageColor3 = "ContentColor" })

        local title = self.window:Create("TextLabel", {
            Text = optionName,
            Size = UDim2.fromOffset(170, 16),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 1,
            TextTransparency = 1,
            ZIndex = 5,
            Parent = container,
        }, { TextColor3 = "ContentColor", FontFace = "Font" })

        local data = {
            name = optionName,
            frame = frame,
            interact = interact,
            title = title,
            checkIcon = checkIcon,
            container = container,
            stroke = optionStroke,
            corner = corner,
            connections = {},
        }

        table.insert(
            data.connections,
            self.window:ConnectFor(self, frame.MouseEnter, function()
                if not self._isOpen or not self.window:_interactive() then
                    return
                end
                if isOptionSelected(data.name) then
                    return
                end
                variables.tweenService
                    :Create(
                        frame,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundTransparency = 0.9 }
                    )
                    :Play()
                variables.tweenService
                    :Create(
                        title,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { TextTransparency = 0.15 }
                    )
                    :Play()
            end)
        )

        table.insert(
            data.connections,
            self.window:ConnectFor(self, frame.MouseLeave, function()
                if not self._isOpen then
                    return
                end
                if isOptionSelected(data.name) then
                    return
                end
                variables.tweenService
                    :Create(
                        frame,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { BackgroundTransparency = 0.95 }
                    )
                    :Play()
                variables.tweenService
                    :Create(
                        title,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { TextTransparency = 0.3 }
                    )
                    :Play()
            end)
        )

        table.insert(
            data.connections,
            self.window:ConnectFor(self, interact.MouseButton1Click, function()
                if not self._isOpen then
                    return
                end
                hapticEngine.click()
                local sel = isOptionSelected(data.name)

                if not self.multiSelect then
                    if sel then
                        self:_close()
                        return
                    end
                    table.clear(self.value)
                    table.insert(self.value, data.name)
                else
                    if sel then
                        local idx = table.find(self.value, data.name)
                        if idx then
                            table.remove(self.value, idx)
                        end
                    else
                        table.insert(self.value, data.name)
                    end
                end

                self._desiredValue = table.clone(self.value)

                for _, d in self._optionFrames do
                    renderOptionState(d, true)
                end

                updateSelectedLabel()

                self.window:_runGuarded(self, self.callback, self:_callbackValue())
                self.window:_persist(self)

                if not self.multiSelect then
                    task.wait(0.1)
                    self:_close()
                end
            end)
        )

        return data
    end

    self._buildOption = buildOption

    for _, opt in self.options do
        local data = buildOption(opt)
        table.insert(self._optionFrames, data)
    end

    updateSelectedLabel()
    self:_updateCorners()

    self.window:ConnectFor(self, self.interact.MouseButton1Click, function()
        hapticEngine.click()
        if self._isOpen then
            self:_close()
        else
            self:_open()
        end
    end)

    self.window:ConnectFor(self, self.main.MouseEnter, function()
        if self._isOpen or not self.window:_interactive() then
            return
        end
        variables.tweenService
            :Create(self.title, hoverTween, { TextColor3 = self.window.theme.ElementTextHoverColor })
            :Play()
        variables.tweenService:Create(self.hoverOverlay, hoverTween, { BackgroundTransparency = 0.97 }):Play()
        variables.tweenService
            :Create(self.stroke, hoverTween, {
                Transparency = self.window.theme.ElementStrokeHoverTransparency,
                Color = self.window.theme.ElementStrokeHover,
            })
            :Play()
    end)

    self.window:ConnectFor(self, self.main.MouseLeave, function()
        variables.tweenService:Create(self.title, hoverTween, { TextColor3 = self.window.theme.ContentColor }):Play()
        variables.tweenService:Create(self.hoverOverlay, hoverTween, { BackgroundTransparency = 1 }):Play()
        variables.tweenService
            :Create(self.stroke, hoverTween, {
                Transparency = self.window.theme.ElementStrokeTransparency,
                Color = self.window.theme.ElementStroke,
            })
            :Play()
    end)

    if self.description then
        self.descriptor = require(script.Parent.descriptor).new(self.tab, { description = self.description })
    end

    return self
end

function Dropdown:_callbackValue()
    if self.multiSelect then
        return table.clone(self.value)
    end
    return self.value[1]
end

function Dropdown:_buildSearch()
    self._searchOpen = false

    self.searchbar = self.window:Create("Frame", {
        Name = "Search",
        Size = UDim2.new(1, -12, 0, searchCollapsedHeight),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        ClipsDescendants = false,
        ZIndex = 1,

        Parent = self.panel,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.searchbar,
    })

    self.searchStroke = self.window:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,
        Parent = self.searchbar,
    })

    self.searchShadow = self.window:CreateGlow(self.searchbar, Color3.fromRGB(255, 255, 255), 20, 1)

    self.searchToggle = self.window:Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextTransparency = 1,
        ZIndex = 51,
        Parent = self.searchbar,
    })

    self.searchInput = self.window:Create("TextBox", {
        Text = "",
        PlaceholderText = locale.t("Search..."),
        Size = UDim2.new(1, -58, 0, 16),
        Position = UDim2.new(0, 44, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        TextEditable = false,
        Interactable = false,
        ZIndex = 52,

        TextTransparency = 1,

        Parent = self.searchbar,
    }, { TextColor3 = "ContentColor", FontFace = "Font", PlaceholderColor3 = "PlaceholderColor" })

    self.searchIcon = self.window:Create("ImageButton", {
        Image = "rbxassetid://" .. tostring(searchIconAsset),
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(0, 24, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
        ZIndex = 53,

        ImageTransparency = 1,

        Parent = self.searchbar,
    }, { ImageColor3 = "ContentColor" })

    self.window:ConnectFor(self, self.searchToggle.MouseButton1Click, function()
        if not self._searchOpen then
            self:_expandSearch()
        end
    end)
    self.window:ConnectFor(self, self.searchIcon.MouseButton1Click, function()
        if self._searchOpen then
            self:_collapseSearch()
        else
            self:_expandSearch()
        end
    end)
    self.window:ConnectFor(self, self.searchInput:GetPropertyChangedSignal("Text"), function()
        self:_applyFilter(self.searchInput.Text)
    end)
    self.window:ConnectFor(self, self.searchInput.FocusLost, function()
        if self.searchInput.Text == "" then
            self:_collapseSearch()
        end
    end)
end

function Dropdown:_expandSearch()
    if self._searchOpen then
        return
    end
    self._searchOpen = true
    self.searchInput.TextEditable = true
    self.searchInput.Interactable = true

    variables.tweenService
        :Create(
            self.searchbar,
            searchTween,
            { Size = UDim2.new(1, -12, 0, searchExpandedHeight), BackgroundTransparency = 0.92 }
        )
        :Play()
    variables.tweenService:Create(self.searchStroke, searchTween, { Transparency = 0.86 }):Play()
    variables.tweenService:Create(self.searchShadow, searchTween, { Transparency = 0.92 }):Play()
    variables.tweenService:Create(self.searchInput, searchTween, { TextTransparency = 0.3 }):Play()

    self:_resizeToOptions()
    self.searchInput:CaptureFocus()
end

function Dropdown:_collapseSearch()
    if not self._searchOpen then
        return
    end
    self._searchOpen = false
    self.searchInput.TextEditable = false
    self.searchInput.Interactable = false
    self.searchInput:ReleaseFocus()
    self.searchInput.Text = ""

    variables.tweenService
        :Create(
            self.searchbar,
            searchTween,
            { Size = UDim2.new(1, -12, 0, searchCollapsedHeight), BackgroundTransparency = 1 }
        )
        :Play()
    variables.tweenService:Create(self.searchStroke, searchTween, { Transparency = 1 }):Play()
    variables.tweenService:Create(self.searchShadow, searchTween, { Transparency = 1 }):Play()
    variables.tweenService:Create(self.searchInput, searchTween, { TextTransparency = 1 }):Play()

    self:_resizeToOptions()
end

function Dropdown:_applyFilter(query)
    query = string.lower(query or "")
    local shown = 0
    for _, data in self._optionFrames do
        local visible = query == "" or string.find(string.lower(data.name), query, 1, true) ~= nil
        data.frame.Visible = visible
        if visible then
            shown += 1
        end
    end

    self.emptyLabel.Visible = shown == 0 and query ~= ""
    self:_updateCorners()
    self:_resizeToOptions()
    self:_syncScrollHint()
end

function Dropdown:_syncScrollHint()
    local canvasSize, windowSize, at =
        self.list.AbsoluteCanvasSize, self.list.AbsoluteWindowSize, self.list.CanvasPosition
    if not canvasSize or not windowSize or not at then
        return
    end

    local more = self._isOpen and windowSize.Y > 0 and canvasSize.Y - (at.Y + windowSize.Y) > 1

    variables.tweenService
        :Create(self.list, hintTween, { ScrollBarImageTransparency = if more then scrollbarShown else 1 })
        :Play()
end

function Dropdown:_visibleOptions(): { string }
    local names = {}
    for _, data in self._optionFrames do
        if data.frame.Visible then
            table.insert(names, data.name)
        end
    end
    return names
end

function Dropdown:_buildActions()
    if not self.multiSelect then
        return
    end

    self.actions = self.window:Create("Frame", {
        Name = "Actions",
        Size = UDim2.new(1, -12, 0, actionsHeight),
        BackgroundTransparency = 1,
        LayoutOrder = 2,

        Parent = self.panel,
    })

    self.window:Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.actions,
    })

    local function action(label: string, order: number, apply: () -> ())
        local button = self.window:Create("TextButton", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, actionsHeight),
            BackgroundTransparency = 1,
            Text = locale.t(label),
            TextSize = 13,
            TextTransparency = 0.45,
            LayoutOrder = order,

            Parent = self.actions,
        }, { TextColor3 = "ContentColor", FontFace = "Font" })

        self.window:ConnectFor(self, button.MouseEnter, function()
            variables.tweenService:Create(button, hintTween, { TextTransparency = 0.15 }):Play()
        end)
        self.window:ConnectFor(self, button.MouseLeave, function()
            variables.tweenService:Create(button, hintTween, { TextTransparency = 0.45 }):Play()
        end)
        self.window:ConnectFor(self, button.MouseButton1Click, function()
            apply()
            self:_afterBulkChange()
        end)

        return button
    end

    action("Select all", 1, function()
        local shown = self:_visibleOptions()
        for _, name in shown do
            if not table.find(self.value, name) then
                table.insert(self.value, name)
            end
        end
    end)
    action("Clear", 2, function()
        local shown = self:_visibleOptions()
        for index = #self.value, 1, -1 do
            if table.find(shown, self.value[index]) then
                table.remove(self.value, index)
            end
        end
    end)
end

function Dropdown:_afterBulkChange()
    self._desiredValue = table.clone(self.value)

    for _, data in self._optionFrames do
        self._renderOptionState(data, true)
    end
    self:_updateSelectedLabel()
    self:_updateCorners()
    self.window:_runGuarded(self, self.callback, self:_callbackValue())
    self.window:_persist(self)
    hapticEngine.click()
end

function Dropdown:_resizeToOptions()
    if not self._isOpen then
        return
    end
    variables.tweenService:Create(self.main, searchTween, { Size = UDim2.new(1, -20, 0, self:_openHeight()) }):Play()
end

function Dropdown:_updateCorners()
    local visible = {}
    for _, data in self._optionFrames do
        if data.frame.Visible then
            table.insert(visible, data)
        end
    end

    for i, data in visible do
        local topR = if i == 1 then roundRadius else flatRadius
        local botR = if i == #visible then roundRadius else flatRadius
        data.corner.TopLeftRadius = topR
        data.corner.TopRightRadius = topR
        data.corner.BottomLeftRadius = botR
        data.corner.BottomRightRadius = botR
    end
end

local function listHeight(count: number): number
    return count * optionHeight + math.max(0, count - 1) * optionGap + listPadding * 2
end

local function rowsThatFit(space: number): number
    return math.max(math.floor((space - listPadding * 2 + optionGap) / (optionHeight + optionGap)), 1)
end

function Dropdown:_pageHeight(): number
    local size = self.window.size
    return windowSizing.pageHeight(size and size.Y.Offset, self.window.layout.mode)
end

function Dropdown:_openHeight()
    local n = 0
    for _, data in self._optionFrames do
        if data.frame.Visible then
            n += 1
        end
    end

    local searchHeight = if self._searchOpen then searchExpandedHeight else searchCollapsedHeight
    local overhead = headerHeight
        + headerGap
        + cardPadding
        + searchHeight
        + optionGap
        + (if self.actions then actionsHeight + optionGap else 0)

    local available = self:_pageHeight()
    local rows = math.min(math.max(n, 1), maxVisibleOptions, rowsThatFit(available - overhead))

    return math.min(overhead + listHeight(rows), available)
end

function Dropdown:_open()
    if self._isOpen then
        return
    end
    self._isOpen = true

    if self._outsideClickConn then
        self.window:Disconnect(self._outsideClickConn)
    end
    self._outsideClickConn = self.window:Connect(variables.userInputService.InputBegan, function(input)
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end

        local pos = input.Position
        local mainPos = self.main.AbsolutePosition
        local mainSize = self.main.AbsoluteSize
        if
            pos.X < mainPos.X
            or pos.X > mainPos.X + mainSize.X
            or pos.Y < mainPos.Y
            or pos.Y > mainPos.Y + mainSize.Y
        then
            self:_close()
        end
    end)

    variables.tweenService
        :Create(
            self.main,
            TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { Size = UDim2.new(1, -20, 0, self:_openHeight()) }
        )
        :Play()
    variables.tweenService
        :Create(
            self.chevron,
            TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { Rotation = 0 }
        )
        :Play()
    variables.tweenService
        :Create(
            self.panel,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { BackgroundTransparency = self.window.theme.ElementTransparency or 0 }
        )
        :Play()
    variables.tweenService
        :Create(
            self.panelStroke,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Transparency = self.window.theme.ElementStrokeTransparency }
        )
        :Play()
    variables.tweenService
        :Create(
            self.searchIcon,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { ImageTransparency = 0.5 }
        )
        :Play()

    for _, data in self._optionFrames do
        self._renderOptionState(data, true)
    end

    self:_syncScrollHint()
    self:_bringIntoView()
end

function Dropdown:_bringIntoView()
    local page = self.tab and self.tab.tabPage
    if not page then
        return
    end

    local view, at, pageAt, cardAt =
        page.AbsoluteWindowSize, page.CanvasPosition, page.AbsolutePosition, self.main.AbsolutePosition
    if not view or not at or not pageAt or not cardAt or view.Y <= 0 then
        return
    end

    local top = cardAt.Y - pageAt.Y + at.Y
    local bottom = top + self:_openHeight()
    local overflow = bottom - (at.Y + view.Y)
    if overflow <= 0 then
        return
    end

    local target = math.min(at.Y + overflow + 8, top)
    variables.tweenService
        :Create(page, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            CanvasPosition = Vector2.new(at.X, target),
        })
        :Play()
end

function Dropdown:_close()
    if not self._isOpen then
        return
    end
    self._isOpen = false

    if self._outsideClickConn then
        self.window:Disconnect(self._outsideClickConn)
        self._outsideClickConn = nil
    end

    self:_collapseSearch()
    self:_syncScrollHint()

    variables.tweenService
        :Create(
            self.chevron,
            TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { Rotation = 180 }
        )
        :Play()
    variables.tweenService
        :Create(
            self.panel,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }
        )
        :Play()
    variables.tweenService
        :Create(
            self.panelStroke,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Transparency = 1 }
        )
        :Play()
    variables.tweenService
        :Create(
            self.searchIcon,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { ImageTransparency = 1 }
        )
        :Play()

    for _, data in self._optionFrames do
        self._renderOptionState(data, true)
    end

    variables.tweenService
        :Create(
            self.main,
            TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { Size = UDim2.new(1, -20, 0, 41) }
        )
        :Play()
end

function Dropdown:_destroyOption(data)
    if data.connections then
        for _, connection in data.connections do
            local idx = table.find(self.connections, connection)
            if idx then
                table.remove(self.connections, idx)
            end
            self.window:Disconnect(connection)
        end
        data.connections = nil
    end
    self.window:DestroySubtree(data.frame)
end

function Dropdown:_deriveSelection()
    local previous = self.value
    self.value = intersectWithOptions(self._desiredValue or self.value, self.options)
    return not sameSelection(self.value, previous)
end

function Dropdown:_reindexOptions()
    for index, data in self._optionFrames do
        data.frame.LayoutOrder = index
    end
end

function Dropdown:_rebindOption(data, name, index)
    data.name = name
    data.title.Text = name
    data.frame.LayoutOrder = index
end

function Dropdown:_destroyOptionsFrom(first)
    local roots, connections = {}, {}

    for index = #self._optionFrames, first, -1 do
        local data = self._optionFrames[index]
        table.insert(roots, data.frame)
        if data.connections then
            table.move(data.connections, 1, #data.connections, #connections + 1, connections)
            data.connections = nil
        end
        self._optionFrames[index] = nil
    end

    self.window:DisconnectMany(self, connections)
    self.window:DestroySubtrees(roots)
end

function Dropdown:Refresh(newOptions)
    self.options = dedupStrings(newOptions or {})

    local selectionChanged = self:_deriveSelection()

    local existing = #self._optionFrames
    local wanted = #self.options

    for index = 1, math.min(existing, wanted) do
        self:_rebindOption(self._optionFrames[index], self.options[index], index)
    end

    for index = existing + 1, wanted do
        local data = self._buildOption(self.options[index])
        data.frame.LayoutOrder = index
        table.insert(self._optionFrames, data)
    end

    if wanted < existing then
        self:_destroyOptionsFrom(wanted + 1)
    end

    for _, data in self._optionFrames do
        self._renderOptionState(data, false)
    end

    self._updateSelectedLabel()
    self:_applyFilter(if self._searchOpen then self.searchInput.Text else "")

    if selectionChanged then
        self.window:_runGuarded(self, self.callback, self:_callbackValue())
        self.window:_persist(self)
    end
end

function Dropdown:Add(option)
    if typeof(option) ~= "string" or option == "" then
        return
    end
    if table.find(self.options, option) then
        return
    end

    table.insert(self.options, option)
    local data = self._buildOption(option)
    table.insert(self._optionFrames, data)

    local selectionChanged = self:_deriveSelection()

    if self._isOpen then
        self._renderOptionState(data, true)
    end

    self:_applyFilter(if self._searchOpen then self.searchInput.Text else "")

    if selectionChanged then
        self._updateSelectedLabel()
        self.window:_runGuarded(self, self.callback, self:_callbackValue())
        self.window:_persist(self)
    end
end

function Dropdown:Remove(option)
    local idx = table.find(self.options, option)
    if not idx then
        return
    end

    table.remove(self.options, idx)

    for i, data in self._optionFrames do
        if data.name == option then
            self:_destroyOption(data)
            table.remove(self._optionFrames, i)
            self:_reindexOptions()
            break
        end
    end

    if self._desiredValue then
        local desiredIdx = table.find(self._desiredValue, option)
        if desiredIdx then
            table.remove(self._desiredValue, desiredIdx)
        end
    end

    local valueIdx = table.find(self.value, option)
    if valueIdx then
        table.remove(self.value, valueIdx)
        self._updateSelectedLabel()
        self.window:_runGuarded(self, self.callback, self:_callbackValue())
        self.window:_persist(self)
    end

    self:_applyFilter(if self._searchOpen then self.searchInput.Text else "")
end

function Dropdown:Set(value, skipCallback)
    local newValue = normalizeValue(value, self.multiSelect)
    self._desiredValue = newValue
    self.value = intersectWithOptions(newValue, self.options)

    for _, data in self._optionFrames do
        self._renderOptionState(data, true)
    end
    self._updateSelectedLabel()

    if not skipCallback then
        self.window:_runGuarded(self, self.callback, self:_callbackValue())
        self.window:_persist(self)
    end
end

function Dropdown:_setShown(shown, animate)
    local w = self.window
    w:_reveal(self.stroke, { Transparency = if shown then w.theme.ElementStrokeTransparency else 1 }, animate)
    w:_reveal(self.title, { TextTransparency = if shown then 0 else 1 }, animate)
    w:_reveal(self.top, { BackgroundTransparency = if shown then (w.theme.ElementTransparency or 0) else 1 }, animate)
    if self.iconLabel then
        w:_reveal(self.iconLabel, { ImageTransparency = if shown then 0 else 1 }, animate)
    end
    if self.descriptor then
        w:_reveal(self.descriptor.titleLabel, { TextTransparency = if shown then 0.7 else 1 }, animate)
    end
    w:_reveal(self.selectedLabel, { TextTransparency = if shown then 0.5 else 1 }, animate)
    w:_reveal(self.chevron, { ImageTransparency = if shown then 0.5 else 1 }, animate)

    if not shown and self._isOpen then
        self:_close()
    end
end

function Dropdown:MoveTo(index)
    self.tab:_moveElement(self, index)
end

function Dropdown:MoveToTop()
    self.tab:_moveElement(self, 1)
end

function Dropdown:MoveToBottom()
    self.tab:_moveElement(self, #self.tab.elements)
end

function Dropdown:MoveUp()
    local idx = table.find(self.tab.elements, self)
    if idx then
        self.tab:_moveElement(self, idx - 1)
    end
end

function Dropdown:MoveDown()
    local idx = table.find(self.tab.elements, self)
    if idx then
        self.tab:_moveElement(self, idx + 1)
    end
end

lockable(Dropdown)

return Dropdown
