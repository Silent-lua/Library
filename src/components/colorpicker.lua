

local ColorPicker = {}
ColorPicker.__index = ColorPicker
ColorPicker.__type = "ColorPicker"

local utility = script.Parent.Parent.utility

local variables = require(utility.variables)
local functions = require(utility.functions)
local moveable = require(utility.moveable)
local lockable = require(utility.lockable)
local constants = require(utility.constants)
local locale = require(utility.locale)
local hapticEngine = require(utility.HapticEngine)

local hueSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
})

local headerHeight = 41
local contentY = 52
local mapSize = Vector2.new(150, 120)
local hueX = 184
local hueWidth = 10
local alphaX = 214
local alphaWidth = 10
local rightX = 240
local alphaFieldWidth = 62
local fieldGap = 8
local narrowWidth = 400

local layoutSpec = {
    wide = {
        height = 190,
        previewPos = UDim2.new(1, -20, 0, contentY + 39),
        previewSize = UDim2.new(1, -(rightX + 20), 0, 78),
        hexPos = UDim2.new(0, rightX, 0, contentY + 90),
        hexSize = UDim2.new(1, -(rightX + 20 + alphaFieldWidth + fieldGap), 0, 30),
        alphaFieldPos = UDim2.new(1, -(20 + alphaFieldWidth), 0, contentY + 90),
        alphaFieldSize = UDim2.new(0, alphaFieldWidth, 0, 30),
    },
    narrow = {
        height = 296,
        previewPos = UDim2.new(1, -20, 0, contentY + mapSize.Y + 40),
        previewSize = UDim2.new(1, -40, 0, 56),
        hexPos = UDim2.new(0, 20, 0, contentY + mapSize.Y + 78),
        hexSize = UDim2.new(1, -(40 + alphaFieldWidth + fieldGap), 0, 30),
        alphaFieldPos = UDim2.new(1, -(20 + alphaFieldWidth), 0, contentY + mapSize.Y + 78),
        alphaFieldSize = UDim2.new(0, alphaFieldWidth, 0, 30),
    },
}

local previewClosedPos = UDim2.new(1, -16, 0, headerHeight / 2)
local previewClosedSize = UDim2.fromOffset(40, 22)

local openInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local followInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local dragInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local heldInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function clamp01(n)
    return math.clamp(n, 0, 1)
end

local function clampByte(n)
    return math.clamp(math.round(n), 0, 255)
end

local namedColors = {
    black = Color3.fromRGB(0, 0, 0),
    white = Color3.fromRGB(255, 255, 255),
    red = Color3.fromRGB(255, 0, 0),
    green = Color3.fromRGB(0, 255, 0),
    blue = Color3.fromRGB(0, 0, 255),
    yellow = Color3.fromRGB(255, 255, 0),
    cyan = Color3.fromRGB(0, 255, 255),
    magenta = Color3.fromRGB(255, 0, 255),
    orange = Color3.fromRGB(255, 165, 0),
    purple = Color3.fromRGB(128, 0, 128),
    pink = Color3.fromRGB(255, 105, 180),
    brown = Color3.fromRGB(139, 69, 19),
    gray = Color3.fromRGB(128, 128, 128),
    grey = Color3.fromRGB(128, 128, 128),
}

local function hslToColor(h, s, l)
    if s <= 0 then
        return Color3.new(l, l, l)
    end
    local function hue2(p, q, t)
        t = t % 1
        if t < 1 / 6 then
            return p + (q - p) * 6 * t
        elseif t < 1 / 2 then
            return q
        elseif t < 2 / 3 then
            return p + (q - p) * (2 / 3 - t) * 6
        end
        return p
    end
    local q = if l < 0.5 then l * (1 + s) else l + s - l * s
    local p = 2 * l - q
    return Color3.new(hue2(p, q, h + 1 / 3), hue2(p, q, h), hue2(p, q, h - 1 / 3))
end

local function numbersIn(s)
    local out = {}
    for n in s:gmatch("[%d%.]+") do
        table.insert(out, tonumber(n))
    end
    return out
end

local function parseColor(input)
    if typeof(input) ~= "string" then
        return nil
    end
    local s = (input:lower():match("^%s*(.-)%s*$")) or ""
    if s == "" then
        return nil
    end

    if namedColors[s] then
        return namedColors[s]
    end

    local model = s:match("^(%a+)")
    local nums = numbersIn(s)

    if (model == "hsv" or model == "hsb") and #nums >= 3 then
        local h = (nums[1] % 360) / 360
        local sat = if nums[2] > 1 then nums[2] / 100 else nums[2]
        local v = if nums[3] > 1 then nums[3] / 100 else nums[3]
        return Color3.fromHSV(h, clamp01(sat), clamp01(v))
    end

    if model == "hsl" and #nums >= 3 then
        local h = (nums[1] % 360) / 360
        local sat = if nums[2] > 1 then nums[2] / 100 else nums[2]
        local l = if nums[3] > 1 then nums[3] / 100 else nums[3]
        return hslToColor(h, clamp01(sat), clamp01(l))
    end

    if (model == "rgb" or model == "rgba") and #nums >= 3 then
        return Color3.fromRGB(clampByte(nums[1]), clampByte(nums[2]), clampByte(nums[3]))
    end

    local hex = s:match("^#?(%x%x%x%x%x%x)$") or s:match("^#?(%x%x%x)$") or s:match("^0x(%x%x%x%x%x%x)$")
    if hex then
        local ok, color = pcall(Color3.fromHex, hex)
        if ok then
            return color
        end
    end

    if #nums >= 3 and not model then
        if nums[1] <= 1 and nums[2] <= 1 and nums[3] <= 1 then
            return Color3.new(clamp01(nums[1]), clamp01(nums[2]), clamp01(nums[3]))
        end
        return Color3.fromRGB(clampByte(nums[1]), clampByte(nums[2]), clampByte(nums[3]))
    end

    return nil
end

local function coerceColor(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end
    if typeof(value) == "string" then
        return parseColor(value) or fallback
    end
    return fallback
end

function ColorPicker.new(tab, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local self = setmetatable({
        tab = assert(tab, "Missing argument #1 (Tab expected)"),
        window = tab.window,
        name = properties.name or properties.Name or "Color Picker",
        icon = properties.icon or properties.Icon,
        description = properties.description or properties.Description,
        forgetState = properties.forgetState or properties.ForgetState or tab.forgetState,

        callback = properties.callback or properties.Callback or function() end,

        _isOpen = false,
    }, ColorPicker)

    self.value = coerceColor(
        properties.color or properties.Color or properties.value or properties.Value or properties.default,
        Color3.fromRGB(255, 255, 255)
    )

    self.hue, self.sat, self.val = self.value:ToHSV()

    local a = properties.alpha or properties.Alpha
    self.alpha = if type(a) == "number" then clamp01(a) else 1

    self.flag = properties.flag
        or properties.Flag
        or (not self.forgetState and functions.deriveFlagFromName(self.name) or nil)
    self.window:_registerControl(self)

    self.main = self.window:Create("Frame", {
        Size = UDim2.new(1, -20, 0, headerHeight),
        BorderSizePixel = 0,
        Name = self.name,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,

        Parent = self.tab.tabPage,
    }, { BackgroundTransparency = "ElementTransparency" })

    self.stroke = self.window:StyleElementBody(self.main)
    self.hoverOverlay = self.window:CreateHoverOverlay(self.main)

    self:_buildHeader()
    self:_buildPicker()

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
        local theme = self.window.theme
        variables.tweenService
            :Create(self.stroke, fadeInfo, {
                Transparency = theme.ElementStrokeHoverTransparency,
                Color = theme.ElementStrokeHover,
            })
            :Play()
        variables.tweenService:Create(self.title, fadeInfo, { TextColor3 = theme.ElementTextHoverColor }):Play()
        variables.tweenService:Create(self.hoverOverlay, fadeInfo, { BackgroundTransparency = 0.97 }):Play()
    end)

    self.window:ConnectFor(self, self.main.MouseLeave, function()
        local theme = self.window.theme
        variables.tweenService
            :Create(
                self.stroke,
                fadeInfo,
                { Transparency = theme.ElementStrokeTransparency, Color = theme.ElementStroke }
            )
            :Play()
        variables.tweenService:Create(self.title, fadeInfo, { TextColor3 = theme.ContentColor }):Play()
        variables.tweenService:Create(self.hoverOverlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
    end)

    if self.description then
        self.descriptor = require(script.Parent.descriptor).new(self.tab, { description = self.description })
    end

    self:_applyPickerVisibility(false, false)
    self:_setControlsVisible(false)

    self.window:ConnectFor(self, self.main:GetPropertyChangedSignal("AbsoluteSize"), function()
        if self.window.animating or (self.window.hidden and self.window.hasShownOnce) then
            return
        end
        self:_applyLayout()
    end)
    self:_applyLayout()

    self:_render("instant")

    return self
end

function ColorPicker:_buildHeader()
    self.container = self.window:Create("Frame", {
        Size = UDim2.new(0, 170, 0, 16),
        Position = UDim2.new(0, 20, 0, headerHeight / 2),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,

        Parent = self.main,
    })

    self.window:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.container,
    })

    if self.icon then
        self.iconLabel = self.window:Create("ImageLabel", {
            Image = self.icon,
            Size = UDim2.fromOffset(16, 16),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 5,

            ImageTransparency = 1,

            Parent = self.container,
        }, { ImageColor3 = "ContentColor" })
    end

    self.title = self.window:Create("TextLabel", {
        Text = locale.t(self.name),
        Size = UDim2.fromOffset(150, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 5,

        TextTransparency = 1,

        Parent = self.container,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    self.preview = self.window:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = previewClosedPos,
        Size = previewClosedSize,
        BackgroundColor3 = self.value,
        BorderSizePixel = 0,
        ZIndex = 3,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.preview,
    })

    self.previewShadow = self.window:CreateGlow(self.preview, self.value, 20, 1)

    self.invisibleGroup = self.window:Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,

        Parent = self.preview,
    })

    self.window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.invisibleGroup,
    })

    self.invisibleIcon = self.window:Create("ImageLabel", {
        Image = constants.icons.colorpicker,
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,

        ImageTransparency = 1,

        Parent = self.invisibleGroup,
    }, { ImageColor3 = "ContentColor" })

    self.invisibleText = self.window:Create("TextLabel", {
        Text = locale.t("Invisible"),
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = 15,
        LayoutOrder = 1,
        ZIndex = 5,

        TextTransparency = 1,

        Parent = self.invisibleGroup,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    self.interact = self.window:Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, headerHeight),
        Position = UDim2.fromScale(0, 0),
        BorderSizePixel = 0,
        Text = "",
        TextTransparency = 1,
        AutoButtonColor = false,
        ZIndex = 10,

        Parent = self.main,
    })
end

function ColorPicker:_buildMap()
    self.map = self.window:Create("Frame", {
        Position = UDim2.fromOffset(20, contentY),
        Size = UDim2.fromOffset(mapSize.X, mapSize.Y),
        BackgroundColor3 = Color3.fromHSV(self.hue, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.map })

    self.mapStroke = self.window:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,

        Parent = self.map,
    })

    self.satOverlay = self.window:Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 3,

        BackgroundTransparency = 1,

        Parent = self.map,
    })
    self.window:Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.satOverlay })
    self.window:Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = self.satOverlay,
    })

    self.valOverlay = self.window:Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 4,

        BackgroundTransparency = 1,

        Parent = self.map,
    })
    self.window:Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.valOverlay })
    self.window:Create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = self.valOverlay,
    })
end

function ColorPicker:_buildPicker()
    self:_buildMap()

    self.satCursor = self.window:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 6,

        BackgroundTransparency = 1,

        Parent = self.map,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.satCursor,
    })

    self.satCursorStroke = self.window:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
        Transparency = 1,

        Parent = self.satCursor,
    })

    self.mapInteract = self.window:Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextTransparency = 1,
        AutoButtonColor = false,
        ZIndex = 7,

        Parent = self.map,
    })

    self.hueBar = self.window:Create("Frame", {
        Position = UDim2.fromOffset(hueX, contentY),
        Size = UDim2.fromOffset(hueWidth, mapSize.Y),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 2,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.hueBar,
    })

    self.window:Create("UIGradient", {
        Color = hueSequence,
        Rotation = 90,

        Parent = self.hueBar,
    })

    self.hueHandle = self.window:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(hueWidth + 8, 8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 4,

        BackgroundTransparency = 1,

        Parent = self.hueBar,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.hueHandle,
    })

    self.hueHandleStroke = self.window:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
        Transparency = 1,

        Parent = self.hueHandle,
    })

    self.hueInteract = self.window:Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 16, 1, 8),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "",
        TextTransparency = 1,
        AutoButtonColor = false,
        ZIndex = 6,

        Parent = self.hueBar,
    })

    self.alphaBar = self.window:Create("Frame", {
        Position = UDim2.fromOffset(alphaX, contentY),
        Size = UDim2.fromOffset(alphaWidth, mapSize.Y),
        BackgroundColor3 = self.value,
        BorderSizePixel = 0,
        ZIndex = 2,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.alphaBar,
    })

    self.alphaGradient = self.window:Create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = self.alphaBar,
    })

    self.alphaHandle = self.window:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(alphaWidth + 8, 8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 4,

        BackgroundTransparency = 1,

        Parent = self.alphaBar,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.alphaHandle,
    })

    self.alphaHandleStroke = self.window:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
        Transparency = 1,

        Parent = self.alphaHandle,
    })

    self.alphaInteract = self.window:Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 16, 1, 8),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "",
        TextTransparency = 1,
        AutoButtonColor = false,
        ZIndex = 6,

        Parent = self.alphaBar,
    })

    self.hexBox = self.window:Create("Frame", {
        Position = UDim2.new(0, rightX, 0, contentY + 90),
        Size = UDim2.new(1, -(rightX + 20), 0, 30),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 2,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.hexBox,
    })

    self.hexBoxStroke = self.window:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,

        Parent = self.hexBox,
    })

    self.hexInput = self.window:Create("TextBox", {
        Text = "#" .. self.value:ToHex():upper(),
        PlaceholderText = locale.t("Smart Input"),
        Size = UDim2.new(1, -14, 1, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        ZIndex = 3,

        TextTransparency = 1,

        Parent = self.hexBox,
    }, { TextColor3 = "ContentColor", FontFace = "Font", PlaceholderColor3 = "PlaceholderColor" })

    self.alphaBox = self.window:Create("Frame", {
        Position = UDim2.new(0, rightX, 0, contentY + 90),
        Size = UDim2.fromOffset(alphaFieldWidth, 30),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 2,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.alphaBox,
    })

    self.alphaBoxStroke = self.window:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,

        Parent = self.alphaBox,
    })

    self.alphaInput = self.window:Create("TextBox", {
        Text = tostring(math.round(self.alpha * 100)) .. "%",
        PlaceholderText = "100%",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        ZIndex = 3,

        TextTransparency = 1,

        Parent = self.alphaBox,
    }, { TextColor3 = "ContentColor", FontFace = "Font", PlaceholderColor3 = "PlaceholderColor" })

    self.window:ConnectFor(self, self.mapInteract.InputBegan, function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            self:_beginDrag("sat", input.UserInputType == Enum.UserInputType.MouseButton1)
        end
    end)

    self.window:ConnectFor(self, self.hueInteract.InputBegan, function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            self:_beginDrag("hue", input.UserInputType == Enum.UserInputType.MouseButton1)
        end
    end)

    self.window:ConnectFor(self, self.alphaInteract.InputBegan, function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            self:_beginDrag("alpha", input.UserInputType == Enum.UserInputType.MouseButton1)
        end
    end)

    self.window:ConnectFor(self, variables.userInputService.InputEnded, function(input)
        if
            (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
            and self._drag
        then
            self:_endDrag()
        end
    end)

    self.window:ConnectFor(self, self.hexInput.FocusLost, function()
        local color = parseColor(self.hexInput.Text)
        if color then
            self:Set(color)
        else
            self.hexInput.Text = "#" .. self.value:ToHex():upper()
        end
    end)

    self.window:ConnectFor(self, self.alphaInput.FocusLost, function()
        local n = tonumber((self.alphaInput.Text:gsub("[^%d%.]", "")))
        if n then
            self:SetAlpha(clamp01(n / 100))
        else
            self.alphaInput.Text = tostring(math.round(self.alpha * 100)) .. "%"
        end
    end)
end

function ColorPicker:_beginDrag(region, isMouse)
    if not self._isOpen then
        return
    end
    self._drag = region
    self._dragIsMouse = isMouse
    self:_setHeld(region)
    self:_pump()

    if self._dragConnection then
        self._dragConnection:Disconnect()
        self._dragConnection = nil
    end

    self._dragConnection = variables.runService.RenderStepped:Connect(function()
        local mouseReleased = self._dragIsMouse
            and not variables.userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        if self.window.unloaded or not self._drag or mouseReleased then
            if mouseReleased then
                self:_endDrag()
                return
            end
            if self._dragConnection then
                self._dragConnection:Disconnect()
                self._dragConnection = nil
            end
            return
        end
        self:_pump()
    end)
end

function ColorPicker:_endDrag()
    self._drag = nil
    self:_setHeld(nil)
    if self._dragConnection then
        self._dragConnection:Disconnect()
        self._dragConnection = nil
    end

    self.window:_persist(self)
end

function ColorPicker:_setHeld(region)
    local satSize = if region == "sat" then UDim2.fromOffset(16, 16) else UDim2.fromOffset(12, 12)
    local hueSize = if region == "hue" then UDim2.fromOffset(hueWidth + 12, 10) else UDim2.fromOffset(hueWidth + 8, 8)
    local alphaSize = if region == "alpha"
        then UDim2.fromOffset(alphaWidth + 12, 10)
        else UDim2.fromOffset(alphaWidth + 8, 8)
    variables.tweenService:Create(self.satCursor, heldInfo, { Size = satSize }):Play()
    variables.tweenService:Create(self.hueHandle, heldInfo, { Size = hueSize }):Play()
    variables.tweenService:Create(self.alphaHandle, heldInfo, { Size = alphaSize }):Play()
end

function ColorPicker:_mouseLocation()
    local mouse = variables.userInputService:GetMouseLocation()
    local screenGui = self.window.screenGui
    if screenGui and screenGui.IgnoreGuiInset then
        return mouse - variables.guiService:GetGuiInset()
    end
    return mouse
end

function ColorPicker:_pump()
    local prevHue, prevSat, prevVal, prevAlpha = self.hue, self.sat, self.val, self.alpha

    if self._drag == "sat" then
        local size = self.map.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            return
        end
        local mouse = self:_mouseLocation()
        self.sat = clamp01((mouse.X - self.map.AbsolutePosition.X) / size.X)
        self.val = 1 - clamp01((mouse.Y - self.map.AbsolutePosition.Y) / size.Y)
    elseif self._drag == "hue" then
        local height = self.hueBar.AbsoluteSize.Y
        if height <= 0 then
            return
        end
        local mouse = self:_mouseLocation()
        self.hue = clamp01((mouse.Y - self.hueBar.AbsolutePosition.Y) / height)
    elseif self._drag == "alpha" then
        local height = self.alphaBar.AbsoluteSize.Y
        if height <= 0 then
            return
        end
        local mouse = self:_mouseLocation()
        self.alpha = 1 - clamp01((mouse.Y - self.alphaBar.AbsolutePosition.Y) / height)
    else
        return
    end

    if self.hue == prevHue and self.sat == prevSat and self.val == prevVal and self.alpha == prevAlpha then
        return
    end

    self.value = Color3.fromHSV(self.hue, self.sat, self.val)
    self:_render("drag")
    self:_fireCallback()
end

function ColorPicker:_render(mode)
    local mapHue = Color3.fromHSV(self.hue, 1, 1)
    local satPos = UDim2.new(self.sat, 0, 1 - self.val, 0)
    local huePos = UDim2.new(0.5, 0, self.hue, 0)
    local alphaPos = UDim2.new(0.5, 0, 1 - self.alpha, 0)
    local previewT = 1 - self.alpha
    local shadowT = 1 - 0.4 * self.alpha

    if mode == "instant" then
        self.map.BackgroundColor3 = mapHue
        self.satCursor.Position, self.satCursor.BackgroundColor3 = satPos, self.value
        self.hueHandle.Position, self.hueHandle.BackgroundColor3 = huePos, mapHue
        self.alphaBar.BackgroundColor3 = self.value
        self.alphaHandle.Position, self.alphaHandle.BackgroundColor3 = alphaPos, self.value
        self.preview.BackgroundColor3 = self.value
        self.previewShadow.Color = self.value
        if not self.window.hidden then
            self.preview.BackgroundTransparency = previewT
            self.previewShadow.Transparency = shadowT
        end
    else
        local moveInfo = if mode == "drag" then dragInfo else followInfo
        variables.tweenService:Create(self.map, moveInfo, { BackgroundColor3 = mapHue }):Play()
        variables.tweenService
            :Create(self.satCursor, moveInfo, { Position = satPos, BackgroundColor3 = self.value })
            :Play()
        variables.tweenService:Create(self.hueHandle, moveInfo, { Position = huePos, BackgroundColor3 = mapHue }):Play()
        variables.tweenService
            :Create(self.alphaHandle, moveInfo, { Position = alphaPos, BackgroundColor3 = self.value })
            :Play()
        variables.tweenService:Create(self.alphaBar, followInfo, { BackgroundColor3 = self.value }):Play()
        local previewGoal = { BackgroundColor3 = self.value }
        local shadowGoal = { Color = self.value }
        if not self.window.hidden then
            previewGoal.BackgroundTransparency = previewT
            shadowGoal.Transparency = shadowT
        end
        variables.tweenService:Create(self.preview, followInfo, previewGoal):Play()
        variables.tweenService:Create(self.previewShadow, followInfo, shadowGoal):Play()
    end

    if not self.hexInput:IsFocused() then
        self.hexInput.Text = "#" .. self.value:ToHex():upper()
    end
    if not self.alphaInput:IsFocused() then
        self.alphaInput.Text = tostring(math.round(self.alpha * 100)) .. "%"
    end

    self:_renderInvisible(mode ~= "instant")
end

function ColorPicker:_renderInvisible(animate)
    local inv = 0
    if self._isOpen and not self.window.hidden then
        inv = clamp01((0.12 - self.alpha) / 0.12)
    end
    local t = 1 - inv
    if animate then
        variables.tweenService:Create(self.invisibleIcon, fadeInfo, { ImageTransparency = t }):Play()
        variables.tweenService:Create(self.invisibleText, fadeInfo, { TextTransparency = t }):Play()
    else
        self.invisibleIcon.ImageTransparency = t
        self.invisibleText.TextTransparency = t
    end
end

function ColorPicker:_fireCallback()
    self.window:_runGuarded(self, self.callback, self.value, self.alpha)
end

function ColorPicker:_open()
    if self._isOpen then
        return
    end
    self._isOpen = true
    self:_setControlsVisible(true)

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

    variables.tweenService:Create(self.main, openInfo, { Size = UDim2.new(1, -20, 0, self._openHeight) }):Play()
    variables.tweenService
        :Create(self.preview, openInfo, { Position = self._previewOpenPos, Size = self._previewOpenSize })
        :Play()
    self:_applyPickerVisibility(true, true)
    self:_renderInvisible(true)
end

function ColorPicker:_close()
    if not self._isOpen then
        return
    end
    self._isOpen = false

    if self._outsideClickConn then
        self.window:Disconnect(self._outsideClickConn)
        self._outsideClickConn = nil
    end

    if self._drag then
        self:_endDrag()
    end
    if self.hexInput:IsFocused() then
        self.hexInput:ReleaseFocus()
    end
    if self.alphaInput:IsFocused() then
        self.alphaInput:ReleaseFocus()
    end

    self:_applyPickerVisibility(false, true)
    self:_renderInvisible(true)
    variables.tweenService
        :Create(self.preview, openInfo, { Position = previewClosedPos, Size = previewClosedSize })
        :Play()
    variables.tweenService:Create(self.main, openInfo, { Size = UDim2.new(1, -20, 0, headerHeight) }):Play()

    task.delay(fadeInfo.Time, function()
        if not self._isOpen then
            self:_setControlsVisible(false)
        end
    end)
end

function ColorPicker:_applyPickerVisibility(open, animate)
    local set = {
        [self.map] = { BackgroundTransparency = if open then 0 else 1 },
        [self.satOverlay] = { BackgroundTransparency = if open then 0 else 1 },
        [self.valOverlay] = { BackgroundTransparency = if open then 0 else 1 },
        [self.mapStroke] = { Transparency = if open then 0.9 else 1 },
        [self.satCursor] = { BackgroundTransparency = if open then 0 else 1 },
        [self.satCursorStroke] = { Transparency = if open then 0 else 1 },
        [self.hueBar] = { BackgroundTransparency = if open then 0 else 1 },
        [self.hueHandle] = { BackgroundTransparency = if open then 0 else 1 },
        [self.hueHandleStroke] = { Transparency = if open then 0 else 1 },
        [self.alphaBar] = { BackgroundTransparency = if open then 0 else 1 },
        [self.alphaHandle] = { BackgroundTransparency = if open then 0 else 1 },
        [self.alphaHandleStroke] = { Transparency = if open then 0 else 1 },
        [self.hexBox] = { BackgroundTransparency = if open then 0.9 else 1 },
        [self.hexBoxStroke] = { Transparency = if open then 0.85 else 1 },
        [self.hexInput] = { TextTransparency = if open then 0.4 else 1 },
        [self.alphaBox] = { BackgroundTransparency = if open then 0.9 else 1 },
        [self.alphaBoxStroke] = { Transparency = if open then 0.85 else 1 },
        [self.alphaInput] = { TextTransparency = if open then 0.4 else 1 },
    }

    for instance, props in set do
        if animate then
            variables.tweenService:Create(instance, fadeInfo, props):Play()
        else
            for prop, value in props do
                instance[prop] = value
            end
        end
    end
end

function ColorPicker:_setControlsVisible(visible)
    for _, frame in { self.map, self.hueBar, self.alphaBar, self.hexBox, self.alphaBox } do
        frame.Visible = visible
    end
end

function ColorPicker:_applyLayout()
    local width = self.main.AbsoluteSize.X
    local mode = if width > 0 and width < narrowWidth then "narrow" else "wide"
    if mode == self._layoutMode then
        return
    end
    self._layoutMode = mode

    local l = layoutSpec[mode]
    self._openHeight = l.height
    self._previewOpenPos = l.previewPos
    self._previewOpenSize = l.previewSize
    self.hexBox.Position = l.hexPos
    self.hexBox.Size = l.hexSize
    self.alphaBox.Position = l.alphaFieldPos
    self.alphaBox.Size = l.alphaFieldSize

    if self._isOpen then
        variables.tweenService:Create(self.main, openInfo, { Size = UDim2.new(1, -20, 0, self._openHeight) }):Play()
        variables.tweenService
            :Create(self.preview, openInfo, { Position = self._previewOpenPos, Size = self._previewOpenSize })
            :Play()
    end
end

function ColorPicker:Set(color, skipCallback)
    self.value = coerceColor(color, self.value)
    self.hue, self.sat, self.val = self.value:ToHSV()
    self:_render(if self._isOpen then "animate" else "instant")

    if not skipCallback then
        self:_fireCallback()
        self.window:_persist(self)
    end
end

function ColorPicker:SetAlpha(alpha, skipCallback)
    self.alpha = clamp01(if type(alpha) == "number" then alpha else self.alpha)
    self:_render(if self._isOpen then "animate" else "instant")

    if not skipCallback then
        self:_fireCallback()
        self.window:_persist(self)
    end
end

function ColorPicker:_serialize()
    return self.value:ToHex() .. string.format("%02x", math.clamp(math.round((self.alpha or 1) * 255), 0, 255))
end

function ColorPicker:_deserialize(raw)
    local hex = tostring(raw)
    local alpha = nil
    if #hex >= 8 then
        alpha = (tonumber(hex:sub(7, 8), 16) or 255) / 255
        hex = hex:sub(1, 6)
    end

    local ok, color = pcall(Color3.fromHex, hex)
    if not ok then
        return
    end
    if alpha then
        self:SetAlpha(alpha, true)
    end
    self:Set(color)
end

function ColorPicker:_setShown(shown, animate)
    local w = self.window
    if shown then
        w:_revealCommon(self, animate)
        w:_reveal(self.preview, { BackgroundTransparency = 1 - self.alpha }, animate)
        w:_reveal(self.previewShadow, { Transparency = 1 - 0.4 * self.alpha }, animate)
    else
        w:_hideCommon(self, animate)
        w:_reveal(self.preview, { BackgroundTransparency = 1 }, animate)
        w:_reveal(self.previewShadow, { Transparency = 1 }, animate)
        if self._isOpen then
            self:_close()
        end
    end
end

moveable(ColorPicker)
lockable(ColorPicker)

return ColorPicker
