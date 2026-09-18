

local Keybind = {}
Keybind.__index = Keybind
Keybind.__type = "Keybind"

local utility = script.Parent.Parent.utility

local variables = require(utility.variables)
local functions = require(utility.functions)
local moveable = require(utility.moveable)
local lockable = require(utility.lockable)
local locale = require(utility.locale)
local constants = require(utility.constants)
local hapticEngine = require(utility.HapticEngine)
local enums = require(utility.enums)
local log = require(utility.log)

local resizeInfo = constants.pillResizeInfo
local recordInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local mouseNames = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function keyName(value)
    if typeof(value) ~= "EnumItem" or value == Enum.KeyCode.Unknown then
        return "None"
    end
    return mouseNames[value] or value.Name
end

local function coerceKey(value)
    if typeof(value) == "EnumItem" then
        return value
    end
    if type(value) == "string" then
        local ok, key = pcall(function()
            return Enum.KeyCode[value]
        end)
        if ok and key then
            return key
        end
        local mouseOk, button = pcall(function()
            return Enum.UserInputType[value]
        end)
        if mouseOk and button and mouseNames[button] then
            return button
        end
    end
    return Enum.KeyCode.Unknown
end

function Keybind.new(tab, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local self = setmetatable({
        tab = assert(tab, "Missing argument #1 (Tab expected)"),
        window = tab.window,
        name = properties.name or properties.Name or "Keybind",
        icon = properties.icon or properties.Icon,
        description = properties.description or properties.Description,
        forgetState = properties.forgetState or properties.ForgetState or tab.forgetState,

        isMenuToggle = properties.isMenuToggle or properties.IsMenuToggle or false,

        callback = properties.callback or properties.Callback or function() end,
        onChanged = properties.onChanged or properties.OnChanged or function() end,

        hold = properties.hold or properties.Hold or false,
        holdThreshold = properties.holdThreshold or properties.HoldThreshold or 0.2,

        recording = false,
    }, Keybind)

    self.value = coerceKey(properties.value or properties.Value or properties.default or properties.Default)

    self.flag = properties.flag
        or properties.Flag
        or (not self.forgetState and functions.deriveFlagFromName(self.name) or nil)
    self.window:_registerControl(self)

    self.main = self.window:Create("Frame", {
        Size = UDim2.new(1, -20, 0, 41),
        BorderSizePixel = 0,
        Name = self.name,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),

        BackgroundTransparency = 1,

        Parent = self.tab.tabPage,
    }, { BackgroundTransparency = "ElementTransparency" })

    self.stroke = self.window:StyleElementBody(self.main)
    self.hoverOverlay = self.window:CreateHoverOverlay(self.main)

    self.container = self.window:Create("Frame", {
        Size = UDim2.new(0, 170, 0, 16),
        Position = UDim2.new(0, 20, 0.5, 0),
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

    self.box = self.window:Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0, 20),
        Size = UDim2.fromOffset(40, 30),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,

        BackgroundTransparency = 1,

        Parent = self.main,
    }, { BackgroundColor3 = "FieldBackground" })

    self.window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.box,
    })

    self.boxStroke = self.window:Create("UIStroke", {
        Transparency = 1,

        Parent = self.box,
    }, { Color = "SurfaceStroke" })

    self.glow = self.window:CreateGlow(self.box, "FieldGlow", 20, 1)
    self._glowIdle = 0.9

    self.keyLabel = self.window:Create("TextLabel", {
        Text = keyName(self.value),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 2,

        TextTransparency = 1,

        Parent = self.box,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    self.window:ConnectFor(self, self.box.MouseButton1Click, function()
        hapticEngine.click()
        if self.recording then
            self:_stopRecording()
        else
            self:_startRecording()
        end
    end)

    self.window:ConnectFor(self, variables.userInputService.InputBegan, function(input, processed)
        if processed then
            return
        end
        if self.recording then
            self:_capture(input)
            return
        end
        if self.window._recordingKeybind then
            return
        end
        if self:_matches(input) then
            if self.hold then
                self:_beginHold(input)
            else
                self.window:_runGuarded(self, self.callback, self.value)
            end
        end
    end)

    self.window:_wireElementHover(self)

    if self.description then
        self.descriptor = require(script.Parent.descriptor).new(self.tab, { description = self.description })
    end

    self:_sizeBox(false)

    return self
end

function Keybind:_sizeBox(animate)
    local width = math.clamp(functions.textWidth(self.window.theme.Font, 15, self.keyLabel.Text) + 28, 40, 200)
    if animate then
        variables.tweenService:Create(self.box, resizeInfo, { Size = UDim2.fromOffset(width, 30) }):Play()
    else
        self.box.Size = UDim2.fromOffset(width, 30)
    end
end

function Keybind:_startRecording()
    local current = self.window._recordingKeybind
    if current and current ~= self then
        current:_stopRecording()
    end
    self.recording = true
    self.window._recordingKeybind = self
    self.keyLabel.Text = locale.resolve("Recording")
    self:_sizeBox(true)
    variables.tweenService:Create(self.glow, recordInfo, { Transparency = 0.7 }):Play()
    variables.tweenService:Create(self.keyLabel, recordInfo, { TextTransparency = 0 }):Play()
end

function Keybind:_stopRecording()
    self.recording = false
    if self.window._recordingKeybind == self then
        local window = self.window
        task.defer(function()
            if window._recordingKeybind == self then
                window._recordingKeybind = nil
            end
        end)
    end
    self.keyLabel.Text = keyName(self.value)
    self:_sizeBox(true)
    variables.tweenService:Create(self.glow, recordInfo, { Transparency = 0.9 }):Play()
    variables.tweenService:Create(self.keyLabel, recordInfo, { TextTransparency = 0.6 }):Play()
end

function Keybind:_capture(input)
    local key
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.Escape then
            self:_stopRecording()
            return
        end
        if input.KeyCode == Enum.KeyCode.Backspace then
            self:_bind(Enum.KeyCode.Unknown)
            return
        end
        key = input.KeyCode
    elseif
        input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3
    then
        key = input.UserInputType
    end
    if not key then
        return
    end

    if self.isMenuToggle then
        local clash = self.window:_keybindUsing(key, self)
        if clash then
            self.window:Notify({
                title = locale.resolve("Keybind unavailable"),
                content = string.format(
                    locale.resolve("%s is bound to %s. Kept %s."),
                    keyName(key),
                    clash.name,
                    keyName(self.value)
                ),
            })
            self:_stopRecording()
            self.window:_flashResult(self, false)
            return
        end
    elseif key == self.window.settings.toggleKeybind then
        self.window:Notify({
            title = locale.resolve("Keybind unavailable"),
            content = string.format(
                locale.resolve("%s is the menu toggle key. Kept %s."),
                keyName(key),
                keyName(self.value)
            ),
        })
        self:_stopRecording()
        self.window:_flashResult(self, false)
        return
    end

    self:_bind(key)
end

function Keybind:_bind(key)
    self.value = key
    self:_stopRecording()
    self.window:_runGuarded(self, self.onChanged, key)
    self.window:_persist(self)

    self.window:_flashResult(self, true)
end

function Keybind:_matches(input)
    local v = self.value
    if typeof(v) ~= "EnumItem" or v == Enum.KeyCode.Unknown then
        return false
    end
    if v.EnumType == Enum.KeyCode then
        return input.KeyCode == v
    elseif v.EnumType == Enum.UserInputType then
        return input.UserInputType == v
    end
    return false
end

function Keybind:_beginHold(input)
    if self._holding or self._holdPress then
        return
    end
    local press = {}
    self._holdPress = press

    local heldKeyCode = input.KeyCode
    local heldInputType = input.UserInputType

    task.delay(self.holdThreshold, function()
        if self._holdPress ~= press then
            return
        end
        self._holding = true
        self.window:_runGuarded(self, self.callback, true)
    end)

    local conn
    conn = self.window:ConnectFor(self, variables.userInputService.InputEnded, function(ended)
        local released = if heldKeyCode ~= Enum.KeyCode.Unknown
            then ended.KeyCode == heldKeyCode
            else ended.UserInputType == heldInputType
        if not released then
            return
        end
        if self.connections then
            local index = table.find(self.connections, conn)
            if index then
                table.remove(self.connections, index)
            end
        end
        self.window:Disconnect(conn)
        if self._holdPress == press then
            self._holdPress = nil
        end
        if self._holding then
            self._holding = false
            self.window:_runGuarded(self, self.callback, false)
        end
    end)
end

function Keybind:Set(value, skipChanged)
    local key = coerceKey(value)

    if key ~= Enum.KeyCode.Unknown then
        if self.isMenuToggle then
            local clash = self.window:_keybindUsing(key, self)
            if clash then
                log.warn(
                    "Library: "
                        .. keyName(key)
                        .. " is bound to '"
                        .. tostring(clash.name)
                        .. "'; kept "
                        .. keyName(self.value)
                )
                return
            end
        elseif key == self.window.settings.toggleKeybind then
            log.warn("Library: " .. keyName(key) .. " is the menu toggle key; kept " .. keyName(self.value))
            return
        end
    end

    self.value = key
    if self.recording then
        self:_stopRecording()
    else
        self.keyLabel.Text = keyName(self.value)
        self:_sizeBox(true)
    end

    if not skipChanged then
        self.window:_runGuarded(self, self.onChanged, self.value)
        self.window:_persist(self)
    end
end

function Keybind:_serialize()
    return { tostring(self.value.EnumType), self.value.Value }
end

function Keybind:_deserialize(raw)
    local enumName = tostring(raw[1]):gsub("^Enum%.", "")
    local enumOk, enumType = pcall(function()
        return Enum[enumName]
    end)
    if not enumOk or not enumType then
        return
    end

    local item = enums.itemFromValue(enumType, raw[2])
    if item then
        self:Set(item)
    end
end

function Keybind:_setShown(shown, animate)
    local w = self.window
    if shown then
        w:_revealCommon(self, animate)
        w:_reveal(self.box, { BackgroundTransparency = w.theme.FieldTransparency }, animate)
        w:_reveal(self.boxStroke, { Transparency = 0.85 }, animate)
        w:_reveal(self.keyLabel, { TextTransparency = 0.6 }, animate)
        w:_reveal(self.glow, { Transparency = 0.9 }, animate)
    else
        w:_hideCommon(self, animate)
        w:_reveal(self.box, { BackgroundTransparency = 1 }, animate)
        w:_reveal(self.boxStroke, { Transparency = 1 }, animate)
        w:_reveal(self.keyLabel, { TextTransparency = 1 }, animate)
        w:_reveal(self.glow, { Transparency = 1 }, animate)
    end
end

function Keybind:_refreshTheme()
    variables.tweenService
        :Create(
            self.box,
            TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { BackgroundTransparency = self.window.theme.FieldTransparency }
        )
        :Play()
end

moveable(Keybind)
lockable(Keybind)

return Keybind
