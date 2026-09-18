


local variables = require(script.Parent.variables)
local TextService = variables.textService

local odometer = {}
odometer.__index = odometer

local stripLength = 20

local function measure(font, size, text)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Font = font
    params.Size = size
    params.Width = math.huge
    local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
    return if ok then bounds else Vector2.new(size * 0.6, size)
end

local metricsCache = {}
local function digitMetrics(font, size)
    local key = tostring(font.Family)
        .. "|"
        .. tostring(font.Weight)
        .. "|"
        .. tostring(font.Style)
        .. "|"
        .. tostring(size)
    local cached = metricsCache[key]
    if cached then
        return cached
    end

    local advance, maxWidth = {}, 0
    for d = 0, 9 do
        local w = math.ceil(measure(font, size, tostring(d)).X)
        advance[d] = w
        if w > maxWidth then
            maxWidth = w
        end
    end
    cached = { advance = advance, maxWidth = maxWidth }
    metricsCache[key] = cached
    return cached
end

function odometer.new(window, container, opts)
    opts = opts or {}
    local self = setmetatable({
        window = window,
        container = container,
        textSize = opts.textSize or 16,
        transparency = opts.transparency or 1,
        duration = opts.duration or 0.55,
        slots = {},
        length = 0,
    }, odometer)

    self.roll = TweenInfo.new(self.duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    self.zIndex = math.max(container.ZIndex + 1, 6)

    self.height = math.ceil(self.textSize)

    local metrics = digitMetrics(window.theme.Font, self.textSize)
    self.advance = metrics.advance
    self.maxWidth = metrics.maxWidth

    window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = opts.alignment or Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),

        Parent = container,
    })

    return self
end

function odometer:_reel(index)
    local slot = self.slots[index]
    if slot.reel then
        return slot.reel
    end

    local cell = self.window:Create("Frame", {
        Name = "Reel",
        Size = UDim2.fromOffset(self.maxWidth, self.height),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = self.zIndex,

        Parent = self.container,
    })

    local strip = self.window:Create("Frame", {
        Size = UDim2.fromOffset(self.maxWidth, self.height),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = self.zIndex,

        Parent = cell,
    })

    for i = 0, stripLength - 1 do
        self.window:Create("TextLabel", {
            Text = tostring(i % 10),
            Position = UDim2.fromOffset(0, i * self.height),
            Size = UDim2.fromOffset(self.maxWidth, self.height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            TextSize = self.textSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTransparency = self.transparency,
            ZIndex = self.zIndex,

            Parent = strip,
        }, { TextColor3 = "ContentColor", FontFace = "Font" })
    end

    local reel = { cell = cell, strip = strip, digit = 0, target = 0, stripTween = nil, sizeTween = nil }
    slot.reel = reel
    return reel
end

function odometer:_static(index)
    local slot = self.slots[index]
    if slot.static then
        return slot.static
    end

    local label = self.window:Create("TextLabel", {
        Name = "Static",
        Size = UDim2.fromOffset(0, self.height),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = self.textSize,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTransparency = self.transparency,
        ZIndex = self.zIndex,

        Parent = self.container,
    }, { TextColor3 = "ContentColor", FontFace = "Font" })

    slot.static = label
    return label
end

local function stopReel(reel)
    if reel.stripTween then
        reel.stripTween:Cancel()
        reel.stripTween = nil
    end
    if reel.sizeTween then
        reel.sizeTween:Cancel()
        reel.sizeTween = nil
    end
end

function odometer:_reelSnap(reel, digit)
    stopReel(reel)
    reel.cell.Size = UDim2.fromOffset(self.advance[digit], self.height)
    reel.strip.Position = UDim2.new(0.5, 0, 0, -digit * self.height)
    reel.digit = digit
    reel.target = digit
end

function odometer:_reelRoll(reel, digit, up)
    if reel.stripTween or reel.sizeTween then
        self:_reelSnap(reel, reel.target)
    end

    local a = reel.digit
    if a == digit then
        return
    end

    local startIndex, targetIndex
    if up then
        startIndex = a
        targetIndex = a + (digit - a) % 10
    else
        startIndex = a + 10
        targetIndex = startIndex - (a - digit) % 10
    end

    reel.strip.Position = UDim2.new(0.5, 0, 0, -startIndex * self.height)
    reel.target = digit

    local stripTween = variables.tweenService:Create(reel.strip, self.roll, {
        Position = UDim2.new(0.5, 0, 0, -targetIndex * self.height),
    })
    local sizeTween = variables.tweenService:Create(reel.cell, self.roll, {
        Size = UDim2.fromOffset(self.advance[digit], self.height),
    })
    reel.stripTween = stripTween
    reel.sizeTween = sizeTween
    stripTween.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed and reel.stripTween == stripTween then
            self:_reelSnap(reel, digit)
        end
    end)
    stripTween:Play()
    sizeTween:Play()
    reel.digit = digit
end

function odometer:_putDigit(index, digit, up, animate)
    local reel = self:_reel(index)
    local wasHidden = not reel.cell.Visible
    reel.cell.Visible = true
    reel.cell.LayoutOrder = -index
    if self.slots[index].static then
        self.slots[index].static.Visible = false
    end
    if animate and not wasHidden then
        self:_reelRoll(reel, digit, up)
    else
        self:_reelSnap(reel, digit)
    end
end

function odometer:_putStatic(index, char)
    local label = self:_static(index)
    if not label.Visible then
        label.TextTransparency = self.transparency
    end
    label.Text = char
    label.Visible = true
    label.LayoutOrder = -index
    if self.slots[index].reel then
        self.slots[index].reel.cell.Visible = false
    end
end

function odometer:_hide(index)
    local slot = self.slots[index]
    if not slot then
        return
    end
    if slot.reel then
        slot.reel.cell.Visible = false
    end
    if slot.static then
        slot.static.Visible = false
    end
end

function odometer:_render(text, animate, up)
    text = tostring(text)

    if text == self._lastText then
        return
    end
    self._lastText = text

    local chars = {}
    for _, code in utf8.codes(text) do
        table.insert(chars, utf8.char(code))
    end

    local n = #chars
    for i = 0, math.max(n, self.length) - 1 do
        self.slots[i] = self.slots[i] or {}
        if i < n then
            local char = chars[n - i]
            if char:match("%d") then
                self:_putDigit(i, tonumber(char), up, animate)
            else
                self:_putStatic(i, char)
            end
        else
            self:_hide(i)
        end
    end
    self.length = n
end

function odometer:to(text, up)
    self:_render(text, true, up)
end

function odometer:snap(text)
    self:_render(text, false, true)
end

function odometer:reveal(target, animate, info)
    self.transparency = target
    for _, slot in self.slots do
        if slot.static and slot.static.Visible then
            self.window:_reveal(slot.static, { TextTransparency = target }, animate, info)
        end
        if slot.reel then
            for _, lbl in slot.reel.strip:GetChildren() do
                if lbl:IsA("TextLabel") then
                    self.window:_reveal(lbl, { TextTransparency = target }, animate, info)
                end
            end
        end
    end
end

return odometer
