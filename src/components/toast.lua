

local Toast = {}
Toast.__index = Toast
Toast.__type = "Toast"

local utility = script.Parent.Parent.utility
local variables = require(utility.variables)
local functions = require(utility.functions)
local constants = require(utility.constants)
local image = require(utility.image)
local hapticEngine = require(utility.HapticEngine)

local slideInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local growInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local fadeLong = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local fadeShort = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local shrinkInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local iconSize = 24
local avatarSize = 32
local leftPadding = 18
local rightPadding = 18
local avatarLeftPadding = 10
local avatarRightPadding = 28
local iconGap = 12
local stackPadding = 8
local MIN_WIDTH, MAX_WIDTH = 140, 320

local maxLive = 6

local offscreenAbove = UDim2.new(0.5, 0, 0.5, -180)
local offscreenBelow = UDim2.new(0.5, 0, 0.5, 180)
local centred = UDim2.new(0.5, 0, 0.5, 0)

local function autoDuration(text)
    return math.clamp(#text * 0.06 + 3, 3, 9)
end

local function resolveImage(icon)
    if type(icon) == "number" then
        return "rbxassetid://" .. tostring(icon)
    end
    return icon
end

function Toast.new(window, properties, container)
    properties = if typeof(properties) == "table" then properties else {}

    local self = setmetatable({
        window = assert(window, "Missing argument #1 (Window expected)"),
        title = properties.title or properties.Title or "",
        subtitle = properties.subtitle or properties.Subtitle,
        icon = properties.icon or properties.Icon,
        avatar = properties.avatar or properties.Avatar,
        minWidth = properties.minWidth or properties.MinWidth,
        subtitleAbove = properties.subtitleAbove or properties.SubtitleAbove or false,
        position = properties.position or "Top",
        _hovered = false,
        _dismissed = false,
    }, Toast)

    self.duration = properties.duration or properties.Duration or autoDuration(self.title .. (self.subtitle or ""))

    local hasAvatar = self.avatar ~= nil and self.avatar ~= 0
    local hasIcon = hasAvatar or (self.icon ~= nil and self.icon ~= 0 and self.icon ~= "")
    self._iconImage = if hasAvatar
        then image.avatar(self.avatar, function(uri)
            if self.iconLabel and not self._dismissed and self.main.Parent then
                image.assign(self.iconLabel, "Image", uri)
            end
        end)
        elseif hasIcon then resolveImage(self.icon)
        else nil
    self._iconSize = if hasAvatar then avatarSize else iconSize
    self._leftPad = if hasAvatar then avatarLeftPadding else leftPadding
    self._rightPad = if hasAvatar then avatarRightPadding else rightPadding
    self._minWidth = math.clamp(self.minWidth or 0, MIN_WIDTH, MAX_WIDTH)
    local hasSubtitle = self.subtitle ~= nil and self.subtitle ~= ""

    self.main = self.window:Create("Frame", {
        Name = "Toast",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = constants.zIndex.toast,

        Parent = container or self.window.toasts,
    })

    self.window:Create("UIPadding", {
        PaddingTop = UDim.new(0, stackPadding),

        Parent = self.main,
    })

    self.body = self.window:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(1, 0, 1, 0),
        Position = if self.position == "Bottom" then offscreenBelow else offscreenAbove,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Active = true,
        BorderSizePixel = 0,
        ZIndex = constants.zIndex.toast,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UIGradient", {
        Rotation = 270,
        Offset = Vector2.new(0, -0.1),

        Parent = self.body,
    }, { Color = { "WindowColor", functions.toColorSequence } })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),

        Parent = self.body,
    })

    self.stroke = self.window:Create("UIStroke", {
        Transparency = 1,

        Parent = self.body,
    }, { Color = "SurfaceStroke" })

    self.shadow = self.window:CreateGlow(self.body, "ShadowColor", 20, 1)

    self.window:Create("UIPadding", {
        PaddingLeft = UDim.new(0, self._leftPad),
        PaddingRight = UDim.new(0, self._rightPad),

        Parent = self.body,
    })

    self.window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, iconGap),

        Parent = self.body,
    })

    if hasIcon then
        self.iconLabel = self.window:Create("ImageLabel", {
            Image = self._iconImage,
            Size = UDim2.fromOffset(self._iconSize, self._iconSize),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            LayoutOrder = 1,
            ZIndex = constants.zIndex.toastContent,

            BackgroundTransparency = 1,
            ImageTransparency = 1,

            Parent = self.body,
        }, if hasAvatar then nil else { ImageColor3 = "ContentColor" })

        self.window:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),

            Parent = self.iconLabel,
        })
    end

    self.container = self.window:Create("Frame", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, hasSubtitle and 32 or 16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = constants.zIndex.toastContent,

        Parent = self.body,
    })

    self.window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),

        Parent = self.container,
    })

    self.titleLabel = self.window:Create("TextLabel", {
        Text = self.title,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 16),
        BackgroundTransparency = 1,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = if self.subtitleAbove then 2 else 1,
        ZIndex = constants.zIndex.toastContent,

        TextTransparency = 1,

        Parent = self.container,
    }, { TextColor3 = "ContentColor", FontFace = "TitleFont" })

    if hasSubtitle then
        self.subtitleLabel = self.window:Create("TextLabel", {
            Text = self.subtitle,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 14),
            BackgroundTransparency = 1,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = if self.subtitleAbove then 1 else 2,
            ZIndex = constants.zIndex.toastContent,

            TextTransparency = 1,

            Parent = self.container,
        }, { TextColor3 = "ContentColor", FontFace = "Font" })
    end

    self.window._toastCount = (self.window._toastCount or 0) + 1
    self.main.LayoutOrder = -self.window._toastCount

    local stacks = self.window._liveToasts
    if not stacks then
        stacks = {}
        self.window._liveToasts = stacks
    end
    local live = stacks[self.main.Parent]
    if not live then
        live = {}
        stacks[self.main.Parent] = live
    end
    self._live = live
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

function Toast:_measure()
    local titleWidth = functions.textWidth(self.window.theme.TitleFont, 16, self.title)
    local subtitleWidth = if self.subtitleLabel
        then functions.textWidth(self.window.theme.Font, 14, self.subtitle)
        else 0
    local textWidth = math.max(titleWidth, subtitleWidth)

    local left = if self.iconLabel then self._leftPad + self._iconSize + iconGap else self._leftPad
    local width = math.clamp(left + textWidth + self._rightPad, self._minWidth, MAX_WIDTH)

    if left + textWidth + self._rightPad > MAX_WIDTH then
        local column = MAX_WIDTH - left - self._rightPad
        for _, label in { self.titleLabel, self.subtitleLabel } do
            if label then
                label.AutomaticSize = Enum.AutomaticSize.None
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.Size = UDim2.fromOffset(column, label.Size.Y.Offset)
            end
        end
    end

    local textHeight = if self.subtitleLabel then 16 + 1 + 14 else 16
    local height = math.max(textHeight, if self.iconLabel then self._iconSize else 0) + 18

    return width, height
end

function Toast:_show()
    if not self.main.Parent then
        return
    end

    hapticEngine.notify()

    local width, height = self:_measure()
    if self._dismissed or not self.main.Parent then
        return
    end
    self.main.Size = UDim2.new(0, width, 0, 0)

    variables.tweenService:Create(self.main, growInfo, { Size = UDim2.new(0, width, 0, height + stackPadding) }):Play()
    variables.tweenService:Create(self.body, slideInfo, { Position = centred }):Play()
    variables.tweenService:Create(self.body, fadeLong, { BackgroundTransparency = 0 }):Play()
    variables.tweenService:Create(self.stroke, fadeLong, { Transparency = 0.9 }):Play()
    variables.tweenService:Create(self.shadow, fadeShort, { Transparency = 0.6 }):Play()
    variables.tweenService:Create(self.titleLabel, fadeShort, { TextTransparency = 0 }):Play()

    task.wait(0.05)
    if self._dismissed or not self.main.Parent then
        return
    end
    if self.iconLabel then
        variables.tweenService:Create(self.iconLabel, fadeShort, { BackgroundTransparency = 0.95 }):Play()
        variables.tweenService:Create(self.iconLabel, fadeShort, { ImageTransparency = 0 }):Play()
    end

    task.wait(0.05)
    if self._dismissed or not self.main.Parent then
        return
    end
    if self.subtitleLabel then
        variables.tweenService:Create(self.subtitleLabel, fadeShort, { TextTransparency = 0.5 }):Play()
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

function Toast:_dismiss()
    if self._dismissed then
        return
    end
    self._dismissed = true

    local live = self._live
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
    if self.subtitleLabel then
        variables.tweenService:Create(self.subtitleLabel, fadeShort, { TextTransparency = 1 }):Play()
    end
    if self.iconLabel then
        variables.tweenService
            :Create(self.iconLabel, fadeShort, { ImageTransparency = 1, BackgroundTransparency = 1 })
            :Play()
    end

    variables.tweenService:Create(self.body, shrinkInfo, { Size = UDim2.new(1, -60, 1, 0) }):Play()
    local collapse =
        variables.tweenService:Create(self.main, shrinkInfo, { Size = UDim2.new(0, self.main.Size.X.Offset, 0, 0) })
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

return Toast
