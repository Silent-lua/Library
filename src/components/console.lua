


local Console = {}
Console.__index = Console
Console.__type = "Console"

local utility = script.Parent.Parent.utility

local moveable = require(utility.moveable)
local locale = require(utility.locale)

local defaultHeight = 120
local minHeight = 48
local titleHeight = 24
local padding = 17
local textPadding = 12
local textSize = 12
local lineHeight = 1.25

local defaultMaxLines = 200

local monoFont = Font.fromEnum(Enum.Font.Code)

function Console.new(tab, properties)
    properties = if typeof(properties) == "table" then properties else {}

    local self = setmetatable({
        tab = assert(tab, "Missing argument #1 (Tab expected)"),
        window = tab.window,
        name = properties.name or properties.Name,
        description = properties.description or properties.Description,

        height = math.max(tonumber(properties.height or properties.Height) or defaultHeight, minHeight),
        follow = properties.follow or properties.Follow or false,
        maxLines = math.max(tonumber(properties.maxLines or properties.MaxLines) or defaultMaxLines, 1),

        lines = {},
        lineLabels = {},
        head = 1,
        nextOrder = 1,
        textDirty = true,
    }, Console)

    self:_build()
    self:_setLines(properties.text or properties.Text or "")

    if self.description then
        self.descriptor = require(script.Parent.descriptor).new(self.tab, { description = self.description })
    end

    return self
end

function Console:Get(): string
    if self.textDirty then
        self.text = table.concat(self.lines, "\n")
        self.textDirty = false
    end
    return self.text
end

function Console:_setLines(text)
    text = if type(text) == "string" then text else tostring(text)

    table.clear(self.lines)
    if text ~= "" then
        for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
            table.insert(self.lines, line)
        end
    end
    self:_trim()
    self:_flush()
end

function Console:_trim()
    local excess = #self.lines - self.maxLines
    if excess <= 0 then
        return
    end
    table.move(self.lines, excess + 1, #self.lines, 1)
    for index = #self.lines, #self.lines - excess + 1, -1 do
        self.lines[index] = nil
    end
end

function Console:_makeLabel()
    return self.window:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        FontFace = monoFont,
        TextSize = textSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        LineHeight = lineHeight,
        RichText = false,

        TextTransparency = self._textTransparency or 1,

        Parent = self.scroll,
    }, { TextColor3 = "ContentColor" })
end

local function rowText(line: string): string
    return if line == "" then " " else line
end

function Console:_flush()
    self.textDirty = true

    for index, line in self.lines do
        local label = self.lineLabels[index]
        if not label then
            label = self:_makeLabel()
            self.lineLabels[index] = label
        end
        label.LayoutOrder = index
        label.Text = rowText(line)
        label.Visible = true
    end

    for index = #self.lines + 1, #self.lineLabels do
        self.lineLabels[index].Visible = false
    end

    self.head = 1
    self.nextOrder = #self.lines + 1
    self:_follow()
end

function Console:_pushLine(line: string)
    self.textDirty = true

    if #self.lines < self.maxLines then
        table.insert(self.lines, line)
        local index = #self.lines
        local label = self.lineLabels[index]
        if not label then
            label = self:_makeLabel()
            self.lineLabels[index] = label
        end
        label.LayoutOrder = self.nextOrder
        label.Text = rowText(line)
        label.Visible = true
        self.nextOrder += 1
        return
    end

    table.move(self.lines, 2, #self.lines, 1)
    self.lines[#self.lines] = line

    local label = self.lineLabels[self.head]
    label.LayoutOrder = self.nextOrder
    label.Text = rowText(line)
    label.Visible = true

    self.nextOrder += 1
    self.head = (self.head % #self.lineLabels) + 1
end

function Console:_build()
    local top = if self.name then titleHeight else 0

    self.main = self.window:Create("Frame", {
        Size = UDim2.new(1, -20, 0, self.height + top + padding * 2),
        BorderSizePixel = 0,
        Name = self.name or "Console",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),

        BackgroundTransparency = 1,

        Parent = self.tab.tabPage,
    }, { BackgroundTransparency = "ElementTransparency" })

    self.stroke = self.window:StyleElementBody(self.main)

    if self.name then
        self.container = self.window:Create("Frame", {
            Size = UDim2.new(1, -padding * 2, 0, 16),
            Position = UDim2.new(0, padding, 0, padding),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Parent = self.main,
        })

        self.title = self.window:Create("TextLabel", {
            Text = locale.t(self.name),

            Size = UDim2.fromScale(1, 1),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,

            TextTransparency = 1,

            Parent = self.container,
        }, { TextColor3 = "ContentColor", FontFace = "Font" })
    end

    self.panel = self.window:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -padding),
        Size = UDim2.new(1, -padding * 2, 0, self.height),
        BorderSizePixel = 0,
        ClipsDescendants = true,

        BackgroundTransparency = 1,

        Parent = self.main,
    }, { BackgroundColor3 = "StatBackground" })

    self.window:Create("UICorner", {
        Parent = self.panel,
    }, { CornerRadius = "ElementCornerRadius" })

    self.panelStroke = self.window:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

        Transparency = 1,

        Parent = self.panel,
    }, { Color = "SurfaceStroke" })

    self.scroll = self.window:Create("ScrollingFrame", {
        Size = UDim2.new(1, -textPadding * 2, 1, -textPadding * 2),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,

        Parent = self.panel,
    })

    self.scrollLayout = self.window:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.scroll,
    })

    self:_watchCanvas()
end

function Console:_pin()
    local scroll = self.scroll
    if not scroll or not scroll.Parent then
        return
    end
    scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
end

function Console:_follow()
    if not self.follow then
        return
    end
    self:_pin()
    task.defer(function()
        self:_pin()
    end)
end

function Console:_watchCanvas()
    self.window:ConnectFor(self, self.scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        if self.follow then
            self:_pin()
        end
    end)
end

function Console:Set(text)
    self:_setLines(text)
end

function Console:Append(line)
    line = if type(line) == "string" then line else tostring(line)
    for part in string.gmatch(line .. "\n", "([^\n]*)\n") do
        self:_pushLine(part)
    end
    self:_follow()
end

function Console:Clear()
    table.clear(self.lines)
    self:_flush()
end

function Console:Copy(): boolean
    local clipboard = (getgenv and getgenv().setclipboard) or setclipboard
    if typeof(clipboard) ~= "function" then
        return false
    end
    return (pcall(clipboard, self:Get()))
end

function Console:SetHeight(height)
    self.height = math.max(tonumber(height) or defaultHeight, minHeight)
    local top = if self.name then titleHeight else 0
    self.panel.Size = UDim2.new(1, -padding * 2, 0, self.height)
    self.main.Size = UDim2.new(1, -20, 0, self.height + top + padding * 2)
end

function Console:_setShown(shown, animate)
    local w = self.window

    w:_reveal(self.main, { BackgroundTransparency = if shown then w.theme.ElementTransparency or 0 else 1 }, animate)
    w:_reveal(self.stroke, { Transparency = if shown then w.theme.ElementStrokeTransparency else 1 }, animate)
    w:_reveal(self.panel, { BackgroundTransparency = if shown then 0 else 1 }, animate)
    w:_reveal(self.panelStroke, { Transparency = if shown then 0.9 else 1 }, animate)

    self._textTransparency = if shown then 0.15 else 1
    for _, label in self.lineLabels do
        w:_reveal(label, { TextTransparency = self._textTransparency }, animate)
    end

    if self.title then
        w:_reveal(self.title, { TextTransparency = if shown then 0 else 1 }, animate)
    end
    if self.descriptor then
        w:_reveal(self.descriptor.titleLabel, { TextTransparency = if shown then 0.7 else 1 }, animate)
    end
end

function Console:Remove()
    if self.descriptor then
        self.descriptor:Remove()
    end
    self.main:Destroy()
end

moveable(Console)

return Console
