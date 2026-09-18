

local Notification = {}
Notification.__index = Notification
Notification.__type = "Notification"

local utility = script.Parent.Parent.utility

local variables = require(utility.variables)
local functions = require(utility.functions)
local constants = require(utility.constants)
local hapticEngine = require(utility.HapticEngine)

local growInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local fadeLong = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local fadeShort = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local swipeInInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local shrinkInfo = TweenInfo.new(0.9, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local offscreenRight = UDim2.new(0.5, 360, 0.5, 0)
local centred = UDim2.new(0.5, 0, 0.5, 0)

local maxLive = 6

local stackPadding = 8

local function autoDuration(content)
    return math.clamp(#content * 0.06 + 3, 3, 9)
end

function Notification.new(window, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local self = setmetatable({
        window = assert(window, "Missing argument #1 (Window expected)"),
        title = properties.title or properties.Title or "Notification",
        content = properties.content or properties.Content or "",
        icon = properties.icon or properties.Icon,
        _hovered = false,
        _dismissed = false,
    }, Notification)

    self.duration = properties.duration or properties.Duration or autoDuration(self.content)

    local hasIcon = self.icon ~= nil and self.icon ~= 0 and self.icon ~= ""

    self.main = self.window:Create("Frame", {
        Name = "Notification",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = constants.zIndex.notification,

        Parent = self.window.notifications,
    })

    self.window:Create("UIPadding", {
        PaddingTop = UDim.new(0, stackPadding),

        Parent = self.main,
    })

    self.body = self.window:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(1, 0, 1, 0),
        Position = offscreenRight,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Active = true,
        BorderSizePixel = 0,
        ZIndex = constants.zIndex.notification,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UIGradient", {
        Rotation = 270,
        Offset = Vector2.new(0, -0.1),

        Parent = self.body,
    }, { Color = { "WindowColor", functions.toColorSequence } })

    self.window:Create("UICorner", {
        Parent = self.body,
    }, { CornerRadius = "CornerRoundness" })

    self.stroke = self.window:Create("UIStroke", {
        Transparency = 1,

        Parent = self.body,
    }, { Color = "SurfaceStroke" })

    self.shadow = self.window:CreateGlow(self.body, "ShadowColor", 20, 1)

    self.window:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20),

        Parent = self.body,
    })

    self.window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 14),

        Parent = self.body,
    })

    if hasIcon then
        self.iconLabel = self.window:Create("ImageLabel", {
            Image = self.icon,
            Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            ZIndex = constants.zIndex.notification,

            ImageTransparency = 1,

            Parent = self.body,
        }, { ImageColor3 = "ContentColor" })
    end

    self.container = self.window:Create("Frame", {
        Size = UDim2.fromOffset(hasIcon and 222 or 260, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = constants.zIndex.notification,

        Parent = self.body,
    })

    self.window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),

        Parent = self.container,
    })

    self.titleLabel = self.window:Create("TextLabel", {
        Text = self.title,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        TextSize = 16,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = constants.zIndex.notification,

        TextTransparency = 1,

        Parent = self.container,
    }, { TextColor3 = "ContentColor", FontFace = "TitleFont" })

    if self.content ~= "" then
        self.descriptionLabel = self.window:Create("TextLabel", {
            Text = self.content,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            TextSize = 15,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2,
            ZIndex = constants.zIndex.notification,

            TextTransparency = 1,

            Parent = self.container,
        }, { TextColor3 = "ContentColor", FontFace = "Font" })
    end

    self.window._notificationCount = (self.window._notificationCount or 0) + 1
    self.main.LayoutOrder = self.window._notificationCount

    local live = self.window._liveNotifications
    if not live then
        live = {}
        self.window._liveNotifications = live
    end
    table.insert(live, self)
    while #live > maxLive do
        local oldest = table.remove(live, 1)
        if oldest and oldest ~= self then
            task.spawn(oldest._dismiss, oldest)
        end
    end

    self._connections = {
        self.window:Connect(self.body.MouseEnter, function()
            self._hovered = true
        end),
        self.window:Connect(self.body.MouseLeave, function()
            self._hovered = false
        end),
        self.window:Connect(self.body.InputBegan, function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                self:_dismiss()
            end
        end),
    }

    task.spawn(function()
        self:_show()
    end)

    return self
end

function Notification:_measure()
    local colWidth = self.iconLabel and 222 or 260

    local contentH = functions.textHeight(self.window.theme.TitleFont, 16, self.title, colWidth)
    if self.descriptionLabel then
        contentH = contentH + 4 + functions.textHeight(self.window.theme.Font, 15, self.content, colWidth)
    end

    return math.max(contentH, self.iconLabel and 24 or 0) + 28
end

function Notification:_show()
    local target = self:_measure() + stackPadding
    if self._dismissed or not self.main.Parent then
        return
    end

    hapticEngine.notify()

    variables.tweenService:Create(self.main, growInfo, { Size = UDim2.new(1, 0, 0, target) }):Play()
    variables.tweenService:Create(self.body, swipeInInfo, { Position = centred }):Play()
    variables.tweenService:Create(self.body, fadeLong, { BackgroundTransparency = 0 }):Play()
    variables.tweenService:Create(self.titleLabel, fadeShort, { TextTransparency = 0 }):Play()
    variables.tweenService:Create(self.stroke, fadeLong, { Transparency = 0.95 }):Play()
    variables.tweenService:Create(self.shadow, fadeShort, { Transparency = 0.6 }):Play()

    task.wait(0.05)
    if self._dismissed or not self.main.Parent then
        return
    end
    if self.iconLabel then
        variables.tweenService:Create(self.iconLabel, fadeShort, { ImageTransparency = 0 }):Play()
    end

    task.wait(0.05)
    if self._dismissed or not self.main.Parent then
        return
    end
    if self.descriptionLabel then
        variables.tweenService:Create(self.descriptionLabel, fadeShort, { TextTransparency = 0.35 }):Play()
    end

    local elapsed = 0
    while elapsed < self.duration and not self._dismissed and self.main.Parent do
        local dt = task.wait()
        if not self._hovered then
            elapsed += dt
        end
    end

    self:_dismiss()
end

function Notification:_dismiss()
    if self._dismissed then
        return
    end
    self._dismissed = true

    local live = self.window._liveNotifications
    local index = live and table.find(live, self)
    if live and index then
        table.remove(live, index)
    end

    if not self.main.Parent then
        return
    end

    variables.tweenService:Create(self.body, fadeLong, { BackgroundTransparency = 1 }):Play()
    variables.tweenService:Create(self.stroke, fadeLong, { Transparency = 1 }):Play()
    variables.tweenService:Create(self.shadow, fadeShort, { Transparency = 1 }):Play()
    variables.tweenService:Create(self.titleLabel, fadeShort, { TextTransparency = 1 }):Play()
    if self.descriptionLabel then
        variables.tweenService:Create(self.descriptionLabel, fadeShort, { TextTransparency = 1 }):Play()
    end
    if self.iconLabel then
        variables.tweenService:Create(self.iconLabel, fadeShort, { ImageTransparency = 1 }):Play()
    end

    variables.tweenService:Create(self.body, shrinkInfo, { Size = UDim2.new(1, -90, 1, 0) }):Play()
    local collapse = variables.tweenService:Create(self.main, shrinkInfo, { Size = UDim2.new(1, 0, 0, 0) })
    collapse:Play()
    collapse.Completed:Wait()

    if not self.main.Parent then
        return
    end

    for _, connection in self._connections do
        self.window:Disconnect(connection)
    end
    self.window:DestroySubtree(self.main)
end

return Notification
