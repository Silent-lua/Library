-- PK Library - Repaired & Converted to Standard Lua
local __modules, __cache, __loading = {}, {}, {}

local function table_clear(t) for k in pairs(t) do t[k] = nil end end
local function table_clone(t) local c = {} for k,v in pairs(t) do c[k]=v end return c end

local function __require(name)
    if __cache[name] then return __cache[name] end
    if __loading[name] then error("Circular dependency detected: " .. name) end
    local mod = __modules[name]
    if not mod then error("Module not found: " .. name) end
    __loading[name] = true
    local res = mod()
    __cache[name] = res
    __loading[name] = nil
    return res
end

-- Utility Mocks (To ensure no missing modules)

__modules["utility.log"] = function()
    return { warn = warn, print = print }
end
__modules["utility.variables"] = function()
    local ts = game:GetService("TweenService")
    local uis = game:GetService("UserInputService")
    local rs = game:GetService("RunService")
    local gs = game:GetService("GuiService")
    local ws = game:GetService("Workspace")
    local lp = game:GetService("Players").LocalPlayer
    local hs = game:GetService("HttpService")
    return {
        tweenService = ts, userInputService = uis, runService = rs, guiService = gs, workspace = ws, localPlayer = lp, httpService = hs,
        brandFont = function(weight) return Font.new("rbxasset://fonts/families/GothamSSm.json", weight) end,
        setFallbackFont = function() end, fileSystemManager = { getPath = function(p) return p end }
    }
end
__modules["utility.HapticEngine"] = function() return { click = function() end, notify = function() end, setContainer = function() end, setEnabled = function() end, teardown = function() end, releaseContainer = function() end } end
__modules["utility.functions"] = function() return { textWidth = function(f,s,t) return string.len(t)*s*0.5 end, textHeight = function(f,s,t,w) return s end, deriveFlagFromName = function(n) return string.gsub(n, "[^%w]", "") end, contrastText = function(c) return Color3.new(1,1,1) end, contrastColor = function(c) return Color3.new(1,1,1) end, toColorSequence = function(c) return typeof(c)=="ColorSequence" and c or ColorSequence.new(c) end } end
__modules["utility.moveable"] = function() return function() end end
__modules["utility.lockable"] = function() return function() end end
__modules["utility.image"] = function() return { assign = function(inst, prop, val) inst[prop] = val end, avatar = function(id, cb) return "rbxthumb://type=AvatarHeadShot&id="..id.."&w=48&h=48" end } end
__modules["utility.constants"] = function() return { zIndex = { restoreContent=10, restoreInteract=11, drag=100, notification=200, toast=300, toastContent=301, elementLock=50 }, icons = { Library=0, search=0, close=0, minimise=0, maximise=0, settings=0, config=0, chevron=0, check=0, dot=0, colorpicker=0 }, displayOrder = { window=10, popup=20 }, pillResizeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), statAccents = { neutral = { fill = ColorSequence.new(Color3.new(1,1,1)), stroke = ColorSequence.new(Color3.new(1,1,1)) }, positive = { fill = ColorSequence.new(Color3.new(0,1,0)), stroke = ColorSequence.new(Color3.new(0,1,0)) }, negative = { fill = ColorSequence.new(Color3.new(1,0,0)), stroke = ColorSequence.new(Color3.new(1,0,0)) } }, accent = { on = Color3.new(1,1,1), onStroke = Color3.new(1,1,1) } } end
__modules["utility.locale"] = function() return { t = function(s) return s end, resolve = function(s) return s end, register = function() end, setActive = function() end, detect = function() return "en" end, isToken = function() return false end, sourceOf = function(s) return s end, translator = nil, current = "en" } end
__modules["utility.windowSizing"] = function() return { pageHeight = function(v,m) return v or 500 end, fit = function(v,m) return UDim2.fromOffset(600, 400) end } end
__modules["utility.layouts"] = function() return { sidebar = { mode = "sidebar", chromeHeight = 40, railWidth = 60, railPadding = 10, rowSpacing = 5, footerHeight = 60, rowInset = 5, avatarSize = 32, fadeSize = UDim2.new(1,0,0,30), fadeCorners = {}, fadeTransparency = NumberSequence.new(1), topbarHeight = 40, cardCorners = {}, cardStrokeRotation = 0, cardStrokeTransparency = 1, pageDirection = Enum.FillDirection.Vertical }, top = { mode = "top", tabStripHeight = 40, tabStripTop = 10, fadeSize = UDim2.new(1,0,0,30), fadeCorners = {}, fadeTransparency = NumberSequence.new(1), topbarHeight = 40, pageDirection = Enum.FillDirection.Horizontal, railWidth = 0 }, railWidthFor = function(l, w) return l.railWidth end } end
__modules["utility.odometer"] = function() return { new = function() return { snap = function() end, to = function() end, reveal = function() end } end } end
__modules["utility.persistence"] = function() return { saveSettings = function() return true end, loadSettings = function() return true end, getPath = function() return "","" end, save = function() return true end, load = function() return true end, list = function() return {} end, delete = function() return true end, applyTo = function() end } end
__modules["utility.enums"] = function() return { itemFromValue = function(e, v) for _,i in pairs(e:GetEnumItems()) do if i.Value == v then return i end end return nil end } end
__modules["utility.filesystem"] = function() return { isfile = isfile or function() return false end, writefile = writefile or function() end, readfile = readfile or function() return "" end } end
__modules["utility.ordering"] = function() return function(e, o) if e.main then e.main.LayoutOrder = o end end end

-- Library Components

__modules["components.action"] = function()
    local Action = {}
    Action.__index = Action
    Action.__type = "Action"
    local variables = __require("utility.variables")
    local log = __require("utility.log")
    local hapticEngine = __require("utility.HapticEngine")
    
    function Action.new(window, properties)
        properties = typeof(properties) == "table" and properties or {}
        local self = setmetatable({
            window = assert(window, "Missing argument #1 (Window expected)"),
            name = properties.name or properties.Name or "Action",
            icon = assert(properties.icon or properties.Icon, "Missing argument (Icon expected)"),
            callback = assert(properties.callback or properties.Callback, "Missing argument (Function expected)"),
            linkedTab = properties.linkedTab or properties.LinkedTab,
        }, Action)
        self.action = self.window:Create("Frame", {Name=self.name, BorderSizePixel=0, LayoutOrder=-(properties.order or 0), Size=UDim2.fromOffset(24, 24), BackgroundTransparency=1, Parent=self.window.actionContainer})
        self.iconLabel = self.window:Create("ImageLabel", {Image=self.icon, Size=UDim2.fromOffset(20, 20), BorderSizePixel=0, AnchorPoint=Vector2.new(0.5, 0.5), Position=UDim2.fromScale(0.5, 0.5), BackgroundTransparency=1, ImageTransparency=1, Parent=self.action}, { ImageColor3="ActionColor" })
        self.interact = self.window:Create("TextButton", {BackgroundTransparency=1, Size=UDim2.fromScale(1, 1), BorderSizePixel=0, Position=UDim2.fromScale(0.5, 0.5), AnchorPoint=Vector2.new(0.5, 0.5), TextTransparency=1, Parent=self.action})
        local function settleIcon()
            if not self.window:_settled() or (self.linkedTab and self.window.selectedTab == self.linkedTab) or (self.isLit and self:isLit()) then return end
            variables.tweenService:Create(self.iconLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency=0.6 }):Play()
        end
        self.window:Connect(self.interact.MouseButton1Click, function()
            hapticEngine.click()
            task.spawn(function()
                local success, result = pcall(self.callback)
                if not success then
                    log.warn("Library encountered an error, with the callback for a " .. tostring(self.__type) .. " component named '" .. tostring(self.name) .. "':")
                    log.print(result)
                end
                settleIcon()
            end)
        end)
        self.window:Connect(self.interact.MouseEnter, function()
            if not self.window:_interactive() then return end
            variables.tweenService:Create(self.iconLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency=0.2 }):Play()
        end)
        self.window:Connect(self.interact.MouseLeave, settleIcon)
        return self
    end
    return Action
end

__modules["components.button"] = function()
    local Button = {}
    Button.__index = Button
    Button.__type = "Button"
    local variables = __require("utility.variables")
    local functions = __require("utility.functions")
    local moveable = __require("utility.moveable")
    local lockable = __require("utility.lockable")
    local locale = __require("utility.locale")
    local hapticEngine = __require("utility.HapticEngine")
    
    function Button.new(tab, properties)
        properties = typeof(properties) == "table" and properties or {}
        local self = setmetatable({
            tab = assert(tab, "Missing argument #1 (Tab expected)"), window = tab.window,
            name = properties.name or properties.Name or "Button", icon = properties.icon or properties.Icon,
            description = properties.description or properties.Description, compact = tab.compact or false,
            callback = properties.callback or properties.Callback or function() end,
        }, Button)
        if self.compact then self:_buildCompact() else self:_buildFull() end
        if self.description and not self.compact then self.descriptor = __require("components.descriptor").new(self.tab, { description = self.description }) end
        return self
    end

    function Button:_runCallback() self.window:_runGuarded(self, self.callback) end

    function Button:_buildFull()
        self.main = self.window:Create("Frame", {Size=UDim2.new(1,-20,0,43),BorderSizePixel=0,Name=self.name,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,Parent=self.tab.tabPage},{BackgroundTransparency="ElementTransparency"})
        self.stroke = self.window:StyleElementBody(self.main)
        self.hoverOverlay = self.window:CreateHoverOverlay(self.main)
        self.container = self.window:Create("Frame", {BorderSizePixel=0,Parent=self.main,Size=UDim2.new(0,170,0,16),Position=UDim2.new(0,20,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1})
        self.containerLayout = self.window:Create("UIListLayout", {Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Left,Parent=self.container})
        if self.icon then self.iconLabel = self.window:Create("ImageLabel", {Image=self.icon,Size=UDim2.fromOffset(16,16),BorderSizePixel=0,BackgroundTransparency=1,ImageTransparency=1,Parent=self.container},{ImageColor3="ContentColor"}) end
        self.title = self.window:Create("TextLabel", {Text=locale.t(self.name),Size=UDim2.fromOffset(250,16),BorderSizePixel=0,BackgroundTransparency=1,TextSize=16,AutomaticSize=Enum.AutomaticSize.X,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1,TextTransparency=1,Parent=self.container},{TextColor3="ContentColor",FontFace="Font"})
        self.interact = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.fromScale(1,1),BorderSizePixel=0,Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),TextTransparency=1,Parent=self.main})
        self.window:_wireElementHover(self)
        self.window:ConnectFor(self, self.interact.MouseButton1Click, function()
            hapticEngine.click()
            variables.tweenService:Create(self.stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency=1}):Play()
            variables.tweenService:Create(self.main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size=UDim2.new(1,-26,0,43)}):Play()
            self:_runCallback()
            task.wait(0.11)
            variables.tweenService:Create(self.main, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size=UDim2.new(1,-20,0,43)}):Play()
            variables.tweenService:Create(self.stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency=self.window.theme.ElementStrokeTransparency}):Play()
        end)
    end

    function Button:_buildCompact()
        local window = self.window
        self.main, self.stroke, self.interact = window:_buildCompactRow(self.tab, self.name)
        self.hoverOverlay = self.interact
        window:Create("UIPadding", {PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,16),Parent=self.interact})
        window:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,6),Parent=self.interact})
        if self.icon then self.iconLabel = window:Create("ImageLabel", {Image=self.icon,Size=UDim2.fromOffset(16,16),BorderSizePixel=0,BackgroundTransparency=1,LayoutOrder=0,ImageTransparency=1,Parent=self.interact},{ImageColor3="ContentColor"}) end
        self.title = window:Create("TextLabel", {Text=locale.t(self.name),Size=UDim2.fromOffset(0,16),AutomaticSize=Enum.AutomaticSize.X,BorderSizePixel=0,BackgroundTransparency=1,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,LayoutOrder=1,TextTransparency=1,Parent=self.interact},{TextColor3="ContentColor",FontFace="Font"})
        window:Create("UIFlexItem", {FlexMode=Enum.UIFlexMode.Shrink,Parent=self.title})
        self.window:_wireElementHover(self)
        self.window:ConnectFor(self, self.interact.MouseButton1Click, function()
            hapticEngine.click()
            variables.tweenService:Create(self.stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency=1}):Play()
            self:_runCallback()
            task.wait(0.11)
            variables.tweenService:Create(self.stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency=self.window.theme.ElementStrokeTransparency}):Play()
        end)
    end

    function Button:_setShown(shown, animate)
        if shown then self.window:_revealCommon(self, animate) else self.window:_hideCommon(self, animate) end
    end

    function Button:_minWidth()
        local w = 32
        if self.icon then w = w + 22 end
        w = w + functions.textWidth(self.window.theme.Font, 16, locale.resolve(self.name))
        return w
    end
    moveable(Button)
    lockable(Button)
    return Button
end

__modules["components.chrome"] = function()
    local variables = __require("utility.variables")
    local filesystem = __require("utility.filesystem")
    local constants = __require("utility.constants")
    local locale = __require("utility.locale")
    local hapticEngine = __require("utility.HapticEngine")
    local chrome = {}
    local dragThreshold = 5
    
    function chrome.buildCollapsedFace(window)
        local iconOnly = window.showIconOnly
        window.collapsedIcon = window:Create("ImageLabel", {Name="CollapsedIcon",AnchorPoint=iconOnly and Vector2.new(0.5,0.5) or Vector2.new(0,0.5),Position=iconOnly and UDim2.fromScale(0.5,0.5) or UDim2.new(0,16,0.5,0),Size=UDim2.fromOffset(24,24),BackgroundTransparency=1,Image=window.showIcon,ZIndex=constants.zIndex.restoreContent,ImageTransparency=1,Parent=window.main},{ImageColor3="TitlingColor"})
        window:Create("UICorner", {Parent=window.collapsedIcon},{CornerRadius="PillCornerRadius"})
        local textContainer = window:Create("Frame", {Name="CollapsedText",Visible=not iconOnly,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,50,0.5,0),Size=UDim2.new(1,-60,0,32),BackgroundTransparency=1,ZIndex=constants.zIndex.restoreContent,Parent=window.main})
        window:Create("UIListLayout", {Padding=UDim.new(0,1),VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=textContainer})
        window.collapsedTitle = window:Create("TextLabel", {Name="Title",Text=window.showName,Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,FontFace=variables.brandFont(Enum.FontWeight.Medium),RichText=true,TextSize=16,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1,ZIndex=constants.zIndex.restoreContent,TextTransparency=1,Parent=textContainer},{TextColor3="TitlingColor"})
        window.collapsedSubtitle = window:Create("TextLabel", {Name="Subtitle",Text=locale.t("Tap to show"),Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,FontFace=variables.brandFont(Enum.FontWeight.Medium),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=2,ZIndex=constants.zIndex.restoreContent,TextTransparency=1,Parent=textContainer},{TextColor3="TitlingColor"})
        window.collapsedInteract = window:Create("TextButton", {Name="CollapsedInteract",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="",TextTransparency=1,Visible=false,ZIndex=constants.zIndex.restoreInteract,Parent=window.main})
        chrome.bindCollapsedDrag(window)
    end

    function chrome.bindCollapsedDrag(window)
        local uis = variables.userInputService
        local dragging, moved = false, false
        local grabOffset, grabMouse = Vector2.zero, Vector2.zero
        local function insetOffset() return (window.screenGui and window.screenGui.IgnoreGuiInset) and variables.guiService:GetGuiInset() or Vector2.zero end
        window:Connect(window.collapsedInteract.InputBegan, function(input, processed)
            if processed or not window.hidden or window.animating then return end
            if input.UserInputType.Name ~= "MouseButton1" and input.UserInputType.Name ~= "Touch" then return end
            dragging, moved = true, false
            grabMouse = uis:GetMouseLocation()
            grabOffset = window.main.AbsolutePosition + window.main.AbsoluteSize * window.main.AnchorPoint - grabMouse
        end)
        window:Connect(uis.InputEnded, function(input)
            if input.UserInputType.Name ~= "MouseButton1" and input.UserInputType.Name ~= "Touch" then return end
            if not dragging then return end
            dragging = false
            if moved then window._collapsedPosition = window.main.Position return end
            hapticEngine.click()
            window:ToggleHide()
        end)
        window:Connect(uis.WindowFocusReleased, function() dragging = false end)
        window:Connect(variables.runService.RenderStepped, function()
            if not dragging then return end
            if not window.hidden or window.animating then dragging = false return end
            local mouse = uis:GetMouseLocation()
            if not moved and (mouse - grabMouse).Magnitude < dragThreshold then return end
            moved = true
            local target = mouse + grabOffset + insetOffset()
            window.main.Position = UDim2.fromOffset(target.X, target.Y)
        end)
    end

    function chrome.isNewUser()
        local localPlayer = variables.localPlayer
        if not localPlayer then return false end
        if typeof(filesystem.isfile) ~= "function" or typeof(filesystem.writefile) ~= "function" then return true end
        local path = variables.fileSystemManager:getPath("lastuser.txt")
        local currentId = tostring(localPlayer.UserId)
        local isNew = true
        pcall(function() if filesystem.isfile(path) then isNew = filesystem.readfile(path) ~= currentId end end)
        pcall(function() filesystem.writefile(path, currentId) end)
        return isNew
    end

    function chrome.setCollapsedShown(window, shown, tweenInfo)
        local targets = { [window.collapsedIcon] = { ImageTransparency = shown and 0 or 1 } }
        if not window.showIconOnly then
            targets[window.collapsedTitle] = { TextTransparency = shown and 0 or 1 }
            targets[window.collapsedSubtitle] = { TextTransparency = shown and 0.5 or 1 }
        end
        for instance, props in pairs(targets) do
            if tweenInfo then variables.tweenService:Create(instance, tweenInfo, props):Play() else
                for property, value in pairs(props) do instance[property] = value end
            end
        end
    end
    return chrome
end

__modules["components.colorpicker"] = function()
    local ColorPicker = {}
    ColorPicker.__index = ColorPicker
    ColorPicker.__type = "ColorPicker"
    local variables = __require("utility.variables")
    local functions = __require("utility.functions")
    local moveable = __require("utility.moveable")
    local lockable = __require("utility.lockable")
    local constants = __require("utility.constants")
    local locale = __require("utility.locale")
    local hapticEngine = __require("utility.HapticEngine")
    
    local hueSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
    })
    local headerHeight = 41
    local contentY = 52
    local mapSize = Vector2.new(150, 120)
    local hueX, hueWidth = 184, 10
    local alphaX, alphaWidth = 214, 10
    local rightX = 240
    local alphaFieldWidth, fieldGap = 62, 8
    local narrowWidth = 400
    
    local layoutSpec = {
        wide = { height = 190, previewPos = UDim2.new(1, -20, 0, contentY + 39), previewSize = UDim2.new(1, -(rightX + 20), 0, 78), hexPos = UDim2.new(0, rightX, 0, contentY + 90), hexSize = UDim2.new(1, -(rightX + 20 + alphaFieldWidth + fieldGap), 0, 30), alphaFieldPos = UDim2.new(1, -(20 + alphaFieldWidth), 0, contentY + 90), alphaFieldSize = UDim2.new(0, alphaFieldWidth, 0, 30) },
        narrow = { height = 296, previewPos = UDim2.new(1, -20, 0, contentY + mapSize.Y + 40), previewSize = UDim2.new(1, -40, 0, 56), hexPos = UDim2.new(0, 20, 0, contentY + mapSize.Y + 78), hexSize = UDim2.new(1, -(40 + alphaFieldWidth + fieldGap), 0, 30), alphaFieldPos = UDim2.new(1, -(20 + alphaFieldWidth), 0, contentY + mapSize.Y + 78), alphaFieldSize = UDim2.new(0, alphaFieldWidth, 0, 30) }
    }
    local previewClosedPos = UDim2.new(1, -16, 0, headerHeight / 2)
    local previewClosedSize = UDim2.fromOffset(40, 22)
    local openInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local followInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local dragInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local heldInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    
    local function clamp01(n) return math.clamp(n, 0, 1) end
    local function clampByte(n) return math.clamp(math.round(n), 0, 255) end
    
    local namedColors = { black = Color3.fromRGB(0,0,0), white = Color3.fromRGB(255,255,255), red = Color3.fromRGB(255,0,0), green = Color3.fromRGB(0,255,0), blue = Color3.fromRGB(0,0,255), yellow = Color3.fromRGB(255,255,0), cyan = Color3.fromRGB(0,255,255), magenta = Color3.fromRGB(255,0,255), orange = Color3.fromRGB(255,165,0), purple = Color3.fromRGB(128,0,128), pink = Color3.fromRGB(255,105,180), brown = Color3.fromRGB(139,69,19), gray = Color3.fromRGB(128,128,128), grey = Color3.fromRGB(128,128,128) }
    
    local function hslToColor(h, s, l)
        if s <= 0 then return Color3.new(l, l, l) end
        local function hue2(p, q, t)
            t = t % 1
            if t < 1 / 6 then return p + (q - p) * 6 * t elseif t < 1 / 2 then return q elseif t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p
        end
        local q = l < 0.5 and (l * (1 + s)) or (l + s - l * s)
        local p = 2 * l - q
        return Color3.new(hue2(p, q, h + 1 / 3), hue2(p, q, h), hue2(p, q, h - 1 / 3))
    end
    
    local function numbersIn(s)
        local out = {}
        for n in s:gmatch("[%d%.]+") do table.insert(out, tonumber(n)) end
        return out
    end
    
    local function parseColor(input)
        if typeof(input) ~= "string" then return nil end
        local s = (input:lower():match("^%s*(.-)%s*$")) or ""
        if s == "" then return nil end
        if namedColors[s] then return namedColors[s] end
        local model = s:match("^(%a+)")
        local nums = numbersIn(s)
        if (model == "hsv" or model == "hsb") and #nums >= 3 then
            local h = (nums[1] % 360) / 360
            local sat = nums[2] > 1 and (nums[2] / 100) or nums[2]
            local v = nums[3] > 1 and (nums[3] / 100) or nums[3]
            return Color3.fromHSV(h, clamp01(sat), clamp01(v))
        end
        if model == "hsl" and #nums >= 3 then
            local h = (nums[1] % 360) / 360
            local sat = nums[2] > 1 and (nums[2] / 100) or nums[2]
            local l = nums[3] > 1 and (nums[3] / 100) or nums[3]
            return hslToColor(h, clamp01(sat), clamp01(l))
        end
        if (model == "rgb" or model == "rgba") and #nums >= 3 then return Color3.fromRGB(clampByte(nums[1]), clampByte(nums[2]), clampByte(nums[3])) end
        local hex = s:match("^#?(%x%x%x%x%x%x)$") or s:match("^#?(%x%x%x)$") or s:match("^0x(%x%x%x%x%x%x)$")
        if hex then local ok, color = pcall(Color3.fromHex, hex) if ok then return color end end
        if #nums >= 3 and not model then
            if nums[1] <= 1 and nums[2] <= 1 and nums[3] <= 1 then return Color3.new(clamp01(nums[1]), clamp01(nums[2]), clamp01(nums[3])) end
            return Color3.fromRGB(clampByte(nums[1]), clampByte(nums[2]), clampByte(nums[3]))
        end
        return nil
    end
    
    local function coerceColor(value, fallback)
        if typeof(value) == "Color3" then return value end
        if typeof(value) == "string" then return parseColor(value) or fallback end
        return fallback
    end
    
    function ColorPicker.new(tab, properties)
        properties = typeof(properties) == "table" and properties or {}
        local self = setmetatable({
            tab = assert(tab, "Missing argument #1 (Tab expected)"), window = tab.window,
            name = properties.name or properties.Name or "Color Picker", icon = properties.icon or properties.Icon,
            description = properties.description or properties.Description, forgetState = properties.forgetState or properties.ForgetState or tab.forgetState,
            callback = properties.callback or properties.Callback or function() end, _isOpen = false,
        }, ColorPicker)
        self.value = coerceColor(properties.color or properties.Color or properties.value or properties.Value or properties.default, Color3.fromRGB(255, 255, 255))
        self.hue, self.sat, self.val = self.value:ToHSV()
        local a = properties.alpha or properties.Alpha
        self.alpha = type(a) == "number" and clamp01(a) or 1
        self.flag = properties.flag or properties.Flag or (not self.forgetState and functions.deriveFlagFromName(self.name) or nil)
        self.window:_registerControl(self)
        self.main = self.window:Create("Frame", {Size=UDim2.new(1,-20,0,headerHeight),BorderSizePixel=0,Name=self.name,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,Parent=self.tab.tabPage},{BackgroundTransparency="ElementTransparency"})
        self.stroke = self.window:StyleElementBody(self.main)
        self.hoverOverlay = self.window:CreateHoverOverlay(self.main)
        self:_buildHeader()
        self:_buildPicker()
        self.window:ConnectFor(self, self.interact.MouseButton1Click, function() hapticEngine.click() if self._isOpen then self:_close() else self:_open() end end)
        self.window:ConnectFor(self, self.main.MouseEnter, function()
            if self._isOpen or not self.window:_interactive() then return end
            local theme = self.window.theme
            variables.tweenService:Create(self.stroke, fadeInfo, {Transparency=theme.ElementStrokeHoverTransparency, Color=theme.ElementStrokeHover}):Play()
            variables.tweenService:Create(self.title, fadeInfo, {TextColor3=theme.ElementTextHoverColor}):Play()
            variables.tweenService:Create(self.hoverOverlay, fadeInfo, {BackgroundTransparency=0.97}):Play()
        end)
        self.window:ConnectFor(self, self.main.MouseLeave, function()
            local theme = self.window.theme
            variables.tweenService:Create(self.stroke, fadeInfo, {Transparency=theme.ElementStrokeTransparency, Color=theme.ElementStroke}):Play()
            variables.tweenService:Create(self.title, fadeInfo, {TextColor3=theme.ContentColor}):Play()
            variables.tweenService:Create(self.hoverOverlay, fadeInfo, {BackgroundTransparency=1}):Play()
        end)
        if self.description then self.descriptor = __require("components.descriptor").new(self.tab, { description = self.description }) end
        self:_applyPickerVisibility(false, false)
        self:_setControlsVisible(false)
        self.window:ConnectFor(self, self.main:GetPropertyChangedSignal("AbsoluteSize"), function()
            if self.window.animating or (self.window.hidden and self.window.hasShownOnce) then return end
            self:_applyLayout()
        end)
        self:_applyLayout()
        self:_render("instant")
        return self
    end
    
    function ColorPicker:_buildHeader()
        self.container = self.window:Create("Frame", {Size=UDim2.new(0,170,0,16),Position=UDim2.new(0,20,0,headerHeight/2),AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5,Parent=self.main})
        self.window:Create("UIListLayout", {Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=self.container})
        if self.icon then self.iconLabel = self.window:Create("ImageLabel", {Image=self.icon,Size=UDim2.fromOffset(16,16),BorderSizePixel=0,BackgroundTransparency=1,ZIndex=5,ImageTransparency=1,Parent=self.container},{ImageColor3="ContentColor"}) end
        self.title = self.window:Create("TextLabel", {Text=locale.t(self.name),Size=UDim2.fromOffset(150,16),AutomaticSize=Enum.AutomaticSize.X,BorderSizePixel=0,BackgroundTransparency=1,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1,ZIndex=5,TextTransparency=1,Parent=self.container},{TextColor3="ContentColor",FontFace="Font"})
        self.preview = self.window:Create("Frame", {AnchorPoint=Vector2.new(1,0.5),Position=previewClosedPos,Size=previewClosedSize,BackgroundColor3=self.value,BorderSizePixel=0,ZIndex=3,BackgroundTransparency=1,Parent=self.main})
        self.window:Create("UICorner", {CornerRadius=UDim.new(0,8),Parent=self.preview})
        self.previewShadow = self.window:CreateGlow(self.preview, self.value, 20, 1)
        self.invisibleGroup = self.window:Create("Frame", {Size=UDim2.fromScale(1,1),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5,Parent=self.preview})
        self.window:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=self.invisibleGroup})
        self.invisibleIcon = self.window:Create("ImageLabel", {Image=constants.icons.colorpicker,Size=UDim2.fromOffset(16,16),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5,ImageTransparency=1,Parent=self.invisibleGroup},{ImageColor3="ContentColor"})
        self.invisibleText = self.window:Create("TextLabel", {Text=locale.t("Invisible"),Size=UDim2.fromOffset(0,16),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,BorderSizePixel=0,TextSize=15,LayoutOrder=1,ZIndex=5,TextTransparency=1,Parent=self.invisibleGroup},{TextColor3="ContentColor",FontFace="Font"})
        self.interact = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.new(1,0,0,headerHeight),Position=UDim2.fromScale(0,0),BorderSizePixel=0,Text="",TextTransparency=1,AutoButtonColor=false,ZIndex=10,Parent=self.main})
    end
    
    function ColorPicker:_buildMap()
        self.map = self.window:Create("Frame", {Position=UDim2.fromOffset(20,contentY),Size=UDim2.fromOffset(mapSize.X,mapSize.Y),BackgroundColor3=Color3.fromHSV(self.hue,1,1),BorderSizePixel=0,ZIndex=2,BackgroundTransparency=1,Parent=self.main})
        self.window:Create("UICorner", {CornerRadius=UDim.new(0,8),Parent=self.map})
        self.mapStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Transparency=1,Parent=self.map})
        self.satOverlay = self.window:Create("Frame", {Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=3,BackgroundTransparency=1,Parent=self.map})
        self.window:Create("UICorner", {CornerRadius=UDim.new(0,8),Parent=self.satOverlay})
        self.window:Create("UIGradient", {Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=self.satOverlay})
        self.valOverlay = self.window:Create("Frame", {Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,ZIndex=4,BackgroundTransparency=1,Parent=self.map})
        self.window:Create("UICorner", {CornerRadius=UDim.new(0,8),Parent=self.valOverlay})
        self.window:Create("UIGradient", {Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Parent=self.valOverlay})
    end

    function ColorPicker:_buildPicker()
        self:_buildMap()
        self.satCursor = self.window:Create("Frame", {AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(12,12),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=6,BackgroundTransparency=1,Parent=self.map})
        self.window:Create("UICorner", {CornerRadius=UDim.new(1,0),Parent=self.satCursor})
        self.satCursorStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Thickness=2,Transparency=1,Parent=self.satCursor})
        self.mapInteract = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="",TextTransparency=1,AutoButtonColor=false,ZIndex=7,Parent=self.map})
        self.hueBar = self.window:Create("Frame", {Position=UDim2.fromOffset(hueX,contentY),Size=UDim2.fromOffset(hueWidth,mapSize.Y),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=2,BackgroundTransparency=1,Parent=self.main})
        self.window:Create("UICorner", {CornerRadius=UDim.new(1,0),Parent=self.hueBar})
        self.window:Create("UIGradient", {Color=hueSequence,Rotation=90,Parent=self.hueBar})
        self.hueHandle = self.window:Create("Frame", {AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0,0),Size=UDim2.fromOffset(hueWidth+8,8),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=4,BackgroundTransparency=1,Parent=self.hueBar})
        self.window:Create("UICorner", {CornerRadius=UDim.new(1,0),Parent=self.hueHandle})
        self.hueHandleStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Thickness=2,Transparency=1,Parent=self.hueHandle})
        self.hueInteract = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.new(1,16,1,8),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),Text="",TextTransparency=1,AutoButtonColor=false,ZIndex=6,Parent=self.hueBar})
        self.alphaBar = self.window:Create("Frame", {Position=UDim2.fromOffset(alphaX,contentY),Size=UDim2.fromOffset(alphaWidth,mapSize.Y),BackgroundColor3=self.value,BorderSizePixel=0,ZIndex=2,BackgroundTransparency=1,Parent=self.main})
        self.window:Create("UICorner", {CornerRadius=UDim.new(1,0),Parent=self.alphaBar})
        self.alphaGradient = self.window:Create("UIGradient", {Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=self.alphaBar})
        self.alphaHandle = self.window:Create("Frame", {AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0,0),Size=UDim2.fromOffset(alphaWidth+8,8),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=4,BackgroundTransparency=1,Parent=self.alphaBar})
        self.window:Create("UICorner", {CornerRadius=UDim.new(1,0),Parent=self.alphaHandle})
        self.alphaHandleStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Thickness=2,Transparency=1,Parent=self.alphaHandle})
        self.alphaInteract = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.new(1,16,1,8),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),Text="",TextTransparency=1,AutoButtonColor=false,ZIndex=6,Parent=self.alphaBar})
        self.hexBox = self.window:Create("Frame", {Position=UDim2.new(0,rightX,0,contentY+90),Size=UDim2.new(1,-(rightX+20),0,30),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=2,BackgroundTransparency=1,Parent=self.main})
        self.window:Create("UICorner", {CornerRadius=UDim.new(0,8),Parent=self.hexBox})
        self.hexBoxStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Transparency=1,Parent=self.hexBox})
        self.hexInput = self.window:Create("TextBox", {Text="#"..self.value:ToHex():upper(),PlaceholderText=locale.t("Smart Input"),Size=UDim2.new(1,-14,1,0),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,BorderSizePixel=0,TextSize=15,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,ZIndex=3,TextTransparency=1,Parent=self.hexBox},{TextColor3="ContentColor",FontFace="Font",PlaceholderColor3="PlaceholderColor"})
        self.alphaBox = self.window:Create("Frame", {Position=UDim2.new(0,rightX,0,contentY+90),Size=UDim2.fromOffset(alphaFieldWidth,30),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=2,BackgroundTransparency=1,Parent=self.main})
        self.window:Create("UICorner", {CornerRadius=UDim.new(0,8),Parent=self.alphaBox})
        self.alphaBoxStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Transparency=1,Parent=self.alphaBox})
        self.alphaInput = self.window:Create("TextBox", {Text=tostring(math.round(self.alpha*100)).."%",PlaceholderText="100%",Size=UDim2.new(1,-10,1,0),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,BorderSizePixel=0,TextSize=15,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,ZIndex=3,TextTransparency=1,Parent=self.alphaBox},{TextColor3="ContentColor",FontFace="Font",PlaceholderColor3="PlaceholderColor"})
        self.window:ConnectFor(self, self.mapInteract.InputBegan, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then self:_beginDrag("sat", input.UserInputType == Enum.UserInputType.MouseButton1) end end)
        self.window:ConnectFor(self, self.hueInteract.InputBegan, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then self:_beginDrag("hue", input.UserInputType == Enum.UserInputType.MouseButton1) end end)
        self.window:ConnectFor(self, self.alphaInteract.InputBegan, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then self:_beginDrag("alpha", input.UserInputType == Enum.UserInputType.MouseButton1) end end)
        self.window:ConnectFor(self, variables.userInputService.InputEnded, function(input) if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and self._drag then self:_endDrag() end end)
        self.window:ConnectFor(self, self.hexInput.FocusLost, function() local color = parseColor(self.hexInput.Text) if color then self:Set(color) else self.hexInput.Text = "#"..self.value:ToHex():upper() end end)
        self.window:ConnectFor(self, self.alphaInput.FocusLost, function() local n = tonumber((self.alphaInput.Text:gsub("[^%d%.]", ""))) if n then self:SetAlpha(clamp01(n/100)) else self.alphaInput.Text = tostring(math.round(self.alpha*100)).."%" end end)
    end
    
    function ColorPicker:_beginDrag(region, isMouse)
        if not self._isOpen then return end
        self._drag, self._dragIsMouse = region, isMouse
        self:_setHeld(region)
        self:_pump()
        if self._dragConnection then self._dragConnection:Disconnect() self._dragConnection = nil end
        self._dragConnection = variables.runService.RenderStepped:Connect(function()
            local mouseReleased = self._dragIsMouse and not variables.userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            if self.window.unloaded or not self._drag or mouseReleased then
                if mouseReleased then self:_endDrag() return end
                if self._dragConnection then self._dragConnection:Disconnect() self._dragConnection = nil end
                return
            end
            self:_pump()
        end)
    end

    function ColorPicker:_endDrag()
        self._drag = nil
        self:_setHeld(nil)
        if self._dragConnection then self._dragConnection:Disconnect() self._dragConnection = nil end
        self.window:_persist(self)
    end

    function ColorPicker:_setHeld(region)
        local satSize = region == "sat" and UDim2.fromOffset(16,16) or UDim2.fromOffset(12,12)
        local hueSize = region == "hue" and UDim2.fromOffset(hueWidth+12,10) or UDim2.fromOffset(hueWidth+8,8)
        local alphaSize = region == "alpha" and UDim2.fromOffset(alphaWidth+12,10) or UDim2.fromOffset(alphaWidth+8,8)
        variables.tweenService:Create(self.satCursor, heldInfo, {Size=satSize}):Play()
        variables.tweenService:Create(self.hueHandle, heldInfo, {Size=hueSize}):Play()
        variables.tweenService:Create(self.alphaHandle, heldInfo, {Size=alphaSize}):Play()
    end

    function ColorPicker:_mouseLocation()
        local mouse = variables.userInputService:GetMouseLocation()
        local screenGui = self.window.screenGui
        if screenGui and screenGui.IgnoreGuiInset then return mouse - variables.guiService:GetGuiInset() end
        return mouse
    end

    function ColorPicker:_pump()
        local prevHue, prevSat, prevVal, prevAlpha = self.hue, self.sat, self.val, self.alpha
        if self._drag == "sat" then
            local size = self.map.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then return end
            local mouse = self:_mouseLocation()
            self.sat = clamp01((mouse.X - self.map.AbsolutePosition.X) / size.X)
            self.val = 1 - clamp01((mouse.Y - self.map.AbsolutePosition.Y) / size.Y)
        elseif self._drag == "hue" then
            local height = self.hueBar.AbsoluteSize.Y
            if height <= 0 then return end
            local mouse = self:_mouseLocation()
            self.hue = clamp01((mouse.Y - self.hueBar.AbsolutePosition.Y) / height)
        elseif self._drag == "alpha" then
            local height = self.alphaBar.AbsoluteSize.Y
            if height <= 0 then return end
            local mouse = self:_mouseLocation()
            self.alpha = 1 - clamp01((mouse.Y - self.alphaBar.AbsolutePosition.Y) / height)
        else return end
        if self.hue == prevHue and self.sat == prevSat and self.val == prevVal and self.alpha == prevAlpha then return end
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
            local moveInfo = mode == "drag" and dragInfo or followInfo
            variables.tweenService:Create(self.map, moveInfo, {BackgroundColor3=mapHue}):Play()
            variables.tweenService:Create(self.satCursor, moveInfo, {Position=satPos, BackgroundColor3=self.value}):Play()
            variables.tweenService:Create(self.hueHandle, moveInfo, {Position=huePos, BackgroundColor3=mapHue}):Play()
            variables.tweenService:Create(self.alphaHandle, moveInfo, {Position=alphaPos, BackgroundColor3=self.value}):Play()
            variables.tweenService:Create(self.alphaBar, followInfo, {BackgroundColor3=self.value}):Play()
            local previewGoal, shadowGoal = {BackgroundColor3=self.value}, {Color=self.value}
            if not self.window.hidden then previewGoal.BackgroundTransparency, shadowGoal.Transparency = previewT, shadowT end
            variables.tweenService:Create(self.preview, followInfo, previewGoal):Play()
            variables.tweenService:Create(self.previewShadow, followInfo, shadowGoal):Play()
        end
        if not self.hexInput:IsFocused() then self.hexInput.Text = "#"..self.value:ToHex():upper() end
        if not self.alphaInput:IsFocused() then self.alphaInput.Text = tostring(math.round(self.alpha*100)).."%" end
        self:_renderInvisible(mode ~= "instant")
    end

    function ColorPicker:_renderInvisible(animate)
        local inv = 0
        if self._isOpen and not self.window.hidden then inv = clamp01((0.12 - self.alpha) / 0.12) end
        local t = 1 - inv
        if animate then
            variables.tweenService:Create(self.invisibleIcon, fadeInfo, {ImageTransparency=t}):Play()
            variables.tweenService:Create(self.invisibleText, fadeInfo, {TextTransparency=t}):Play()
        else
            self.invisibleIcon.ImageTransparency, self.invisibleText.TextTransparency = t, t
        end
    end

    function ColorPicker:_fireCallback() self.window:_runGuarded(self, self.callback, self.value, self.alpha) end

    function ColorPicker:_open()
        if self._isOpen then return end
        self._isOpen = true
        self:_setControlsVisible(true)
        if self._outsideClickConn then self.window:Disconnect(self._outsideClickConn) end
        self._outsideClickConn = self.window:Connect(variables.userInputService.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local pos, mainPos, mainSize = input.Position, self.main.AbsolutePosition, self.main.AbsoluteSize
            if pos.X < mainPos.X or pos.X > mainPos.X + mainSize.X or pos.Y < mainPos.Y or pos.Y > mainPos.Y + mainSize.Y then self:_close() end
        end)
        variables.tweenService:Create(self.main, openInfo, {Size=UDim2.new(1,-20,0,self._openHeight)}):Play()
        variables.tweenService:Create(self.preview, openInfo, {Position=self._previewOpenPos, Size=self._previewOpenSize}):Play()
        self:_applyPickerVisibility(true, true)
        self:_renderInvisible(true)
    end

    function ColorPicker:_close()
        if not self._isOpen then return end
        self._isOpen = false
        if self._outsideClickConn then self.window:Disconnect(self._outsideClickConn) self._outsideClickConn = nil end
        if self._drag then self:_endDrag() end
        if self.hexInput:IsFocused() then self.hexInput:ReleaseFocus() end
        if self.alphaInput:IsFocused() then self.alphaInput:ReleaseFocus() end
        self:_applyPickerVisibility(false, true)
        self:_renderInvisible(true)
        variables.tweenService:Create(self.preview, openInfo, {Position=previewClosedPos, Size=previewClosedSize}):Play()
        variables.tweenService:Create(self.main, openInfo, {Size=UDim2.new(1,-20,0,headerHeight)}):Play()
        task.delay(fadeInfo.Time, function() if not self._isOpen then self:_setControlsVisible(false) end end)
    end

    function ColorPicker:_applyPickerVisibility(open, animate)
        local set = {
            [self.map]={BackgroundTransparency=open and 0 or 1}, [self.satOverlay]={BackgroundTransparency=open and 0 or 1}, [self.valOverlay]={BackgroundTransparency=open and 0 or 1},
            [self.mapStroke]={Transparency=open and 0.9 or 1}, [self.satCursor]={BackgroundTransparency=open and 0 or 1}, [self.satCursorStroke]={Transparency=open and 0 or 1},
            [self.hueBar]={BackgroundTransparency=open and 0 or 1}, [self.hueHandle]={BackgroundTransparency=open and 0 or 1}, [self.hueHandleStroke]={Transparency=open and 0 or 1},
            [self.alphaBar]={BackgroundTransparency=open and 0 or 1}, [self.alphaHandle]={BackgroundTransparency=open and 0 or 1}, [self.alphaHandleStroke]={Transparency=open and 0 or 1},
            [self.hexBox]={BackgroundTransparency=open and 0.9 or 1}, [self.hexBoxStroke]={Transparency=open and 0.85 or 1}, [self.hexInput]={TextTransparency=open and 0.4 or 1},
            [self.alphaBox]={BackgroundTransparency=open and 0.9 or 1}, [self.alphaBoxStroke]={Transparency=open and 0.85 or 1}, [self.alphaInput]={TextTransparency=open and 0.4 or 1}
        }
        for instance, props in pairs(set) do
            if animate then variables.tweenService:Create(instance, fadeInfo, props):Play() else for prop, value in pairs(props) do instance[prop] = value end end
        end
    end

    function ColorPicker:_setControlsVisible(visible)
        for _, frame in pairs({self.map, self.hueBar, self.alphaBar, self.hexBox, self.alphaBox}) do frame.Visible = visible end
    end

    function ColorPicker:_applyLayout()
        local width = self.main.AbsoluteSize.X
        local mode = (width > 0 and width < narrowWidth) and "narrow" or "wide"
        if mode == self._layoutMode then return end
        self._layoutMode = mode
        local l = layoutSpec[mode]
        self._openHeight, self._previewOpenPos, self._previewOpenSize = l.height, l.previewPos, l.previewSize
        self.hexBox.Position, self.hexBox.Size = l.hexPos, l.hexSize
        self.alphaBox.Position, self.alphaBox.Size = l.alphaFieldPos, l.alphaFieldSize
        if self._isOpen then
            variables.tweenService:Create(self.main, openInfo, {Size=UDim2.new(1,-20,0,self._openHeight)}):Play()
            variables.tweenService:Create(self.preview, openInfo, {Position=self._previewOpenPos, Size=self._previewOpenSize}):Play()
        end
    end

    function ColorPicker:Set(color, skipCallback)
        self.value = coerceColor(color, self.value)
        self.hue, self.sat, self.val = self.value:ToHSV()
        self:_render(self._isOpen and "animate" or "instant")
        if not skipCallback then self:_fireCallback() self.window:_persist(self) end
    end

    function ColorPicker:SetAlpha(alpha, skipCallback)
        self.alpha = clamp01(type(alpha)=="number" and alpha or self.alpha)
        self:_render(self._isOpen and "animate" or "instant")
        if not skipCallback then self:_fireCallback() self.window:_persist(self) end
    end

    function ColorPicker:_serialize() return self.value:ToHex() .. string.format("%02x", math.clamp(math.round((self.alpha or 1)*255), 0, 255)) end
    function ColorPicker:_deserialize(raw)
        local hex = tostring(raw)
        local alpha = nil
        if #hex >= 8 then
            alpha = (tonumber(hex:sub(7,8),16) or 255) / 255
            hex = hex:sub(1,6)
        end
        local ok, color = pcall(Color3.fromHex, hex)
        if not ok then return end
        if alpha then self:SetAlpha(alpha, true) end
        self:Set(color)
    end

    function ColorPicker:_setShown(shown, animate)
        local w = self.window
        if shown then
            w:_revealCommon(self, animate)
            w:_reveal(self.preview, {BackgroundTransparency=1-self.alpha}, animate)
            w:_reveal(self.previewShadow, {Transparency=1-0.4*self.alpha}, animate)
        else
            w:_hideCommon(self, animate)
            w:_reveal(self.preview, {BackgroundTransparency=1}, animate)
            w:_reveal(self.previewShadow, {Transparency=1}, animate)
            if self._isOpen then self:_close() end
        end
    end
    moveable(ColorPicker)
    lockable(ColorPicker)
    return ColorPicker
end

__modules["components.console"] = function()
    local Console = {}
    Console.__index = Console
    Console.__type = "Console"
    local moveable = __require("utility.moveable")
    local locale = __require("utility.locale")
    local defaultHeight, minHeight, titleHeight, padding, textPadding, textSize, lineHeight, defaultMaxLines = 120, 48, 24, 17, 12, 12, 1.25, 200
    local monoFont = Font.fromEnum(Enum.Font.Code)
    
    function Console.new(tab, properties)
        properties = typeof(properties) == "table" and properties or {}
        local self = setmetatable({
            tab = assert(tab, "Missing argument #1 (Tab expected)"), window = tab.window,
            name = properties.name or properties.Name, description = properties.description or properties.Description,
            height = math.max(tonumber(properties.height or properties.Height) or defaultHeight, minHeight),
            follow = properties.follow or properties.Follow or false,
            maxLines = math.max(tonumber(properties.maxLines or properties.MaxLines) or defaultMaxLines, 1),
            lines = {}, lineLabels = {}, head = 1, nextOrder = 1, textDirty = true,
        }, Console)
        self:_build()
        self:_setLines(properties.text or properties.Text or "")
        if self.description then self.descriptor = __require("components.descriptor").new(self.tab, { description = self.description }) end
        return self
    end

    function Console:Get()
        if self.textDirty then self.text = table.concat(self.lines, "\n") self.textDirty = false end
        return self.text
    end

    function Console:_setLines(text)
        text = type(text) == "string" and text or tostring(text)
        table_clear(self.lines)
        if text ~= "" then for line in string.gmatch(text.."\n", "([^\n]*)\n") do table.insert(self.lines, line) end end
        self:_trim()
        self:_flush()
    end

    function Console:_trim()
        local excess = #self.lines - self.maxLines
        if excess <= 0 then return end
        for i = 1, self.maxLines do self.lines[i] = self.lines[i + excess] end
        for i = self.maxLines + 1, #self.lines do self.lines[i] = nil end
    end

    function Console:_makeLabel()
        return self.window:Create("TextLabel", {Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,FontFace=monoFont,TextSize=textSize,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,LineHeight=lineHeight,RichText=false,TextTransparency=self._textTransparency or 1,Parent=self.scroll},{TextColor3="ContentColor"})
    end

    local function rowText(line) return line == "" and " " or line end

    function Console:_flush()
        self.textDirty = true
        for index, line in ipairs(self.lines) do
            local label = self.lineLabels[index]
            if not label then label = self:_makeLabel() self.lineLabels[index] = label end
            label.LayoutOrder = index
            label.Text = rowText(line)
            label.Visible = true
        end
        for index = #self.lines + 1, #self.lineLabels do self.lineLabels[index].Visible = false end
        self.head = 1
        self.nextOrder = #self.lines + 1
        self:_follow()
    end

    function Console:_pushLine(line)
        self.textDirty = true
        if #self.lines < self.maxLines then
            table.insert(self.lines, line)
            local index = #self.lines
            local label = self.lineLabels[index]
            if not label then label = self:_makeLabel() self.lineLabels[index] = label end
            label.LayoutOrder = self.nextOrder
            label.Text = rowText(line)
            label.Visible = true
            self.nextOrder = self.nextOrder + 1
            return
        end
        for i = 1, #self.lines - 1 do self.lines[i] = self.lines[i + 1] end
        self.lines[#self.lines] = line
        local label = self.lineLabels[self.head]
        label.LayoutOrder = self.nextOrder
        label.Text = rowText(line)
        label.Visible = true
        self.nextOrder = self.nextOrder + 1
        self.head = (self.head % #self.lineLabels) + 1
    end

    function Console:_build()
        local top = self.name and titleHeight or 0
        self.main = self.window:Create("Frame", {Size=UDim2.new(1,-20,0,self.height+top+padding*2),BorderSizePixel=0,Name=self.name or "Console",BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,Parent=self.tab.tabPage},{BackgroundTransparency="ElementTransparency"})
        self.stroke = self.window:StyleElementBody(self.main)
        if self.name then
            self.container = self.window:Create("Frame", {Size=UDim2.new(1,-padding*2,0,16),Position=UDim2.new(0,padding,0,padding),BackgroundTransparency=1,BorderSizePixel=0,Parent=self.main})
            self.title = self.window:Create("TextLabel", {Text=locale.t(self.name),Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundTransparency=1,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,TextTransparency=1,Parent=self.container},{TextColor3="ContentColor",FontFace="Font"})
        end
        self.panel = self.window:Create("Frame", {AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-padding),Size=UDim2.new(1,-padding*2,0,self.height),BorderSizePixel=0,ClipsDescendants=true,BackgroundTransparency=1,Parent=self.main},{BackgroundColor3="StatBackground"})
        self.window:Create("UICorner", {Parent=self.panel},{CornerRadius="ElementCornerRadius"})
        self.panelStroke = self.window:Create("UIStroke", {ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Transparency=1,Parent=self.panel},{Color="SurfaceStroke"})
        self.scroll = self.window:Create("ScrollingFrame", {Size=UDim2.new(1,-textPadding*2,1,-textPadding*2),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=self.panel})
        self.scrollLayout = self.window:Create("UIListLayout", {FillDirection=Enum.FillDirection.Vertical,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Top,SortOrder=Enum.SortOrder.LayoutOrder,Parent=self.scroll})
        self:_watchCanvas()
    end

    function Console:_pin()
        local scroll = self.scroll
        if not scroll or not scroll.Parent then return end
        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
    end

    function Console:_follow()
        if not self.follow then return end
        self:_pin()
        task.defer(function() self:_pin() end)
    end

    function Console:_watchCanvas()
        self.window:ConnectFor(self, self.scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function() if self.follow then self:_pin() end end)
    end

    function Console:Set(text) self:_setLines(text) end
    function Console:Append(line)
        line = type(line) == "string" and line or tostring(line)
        for part in string.gmatch(line.."\n", "([^\n]*)\n") do self:_pushLine(part) end
        self:_follow()
    end
    function Console:Clear() table_clear(self.lines) self:_flush() end
    function Console:Copy()
        local clipboard = (getgenv and getgenv().setclipboard) or setclipboard
        if type(clipboard) ~= "function" then return false end
        return (pcall(clipboard, self:Get()))
    end
    function Console:SetHeight(height)
        self.height = math.max(tonumber(height) or defaultHeight, minHeight)
        local top = self.name and titleHeight or 0
        self.panel.Size = UDim2.new(1, -padding*2, 0, self.height)
        self.main.Size = UDim2.new(1, -20, 0, self.height + top + padding*2)
    end

    function Console:_setShown(shown, animate)
        local w = self.window
        w:_reveal(self.main, {BackgroundTransparency=shown and (w.theme.ElementTransparency or 0) or 1}, animate)
        w:_reveal(self.stroke, {Transparency=shown and w.theme.ElementStrokeTransparency or 1}, animate)
        w:_reveal(self.panel, {BackgroundTransparency=shown and 0 or 1}, animate)
        w:_reveal(self.panelStroke, {Transparency=shown and 0.9 or 1}, animate)
        self._textTransparency = shown and 0.15 or 1
        for _, label in ipairs(self.lineLabels) do w:_reveal(label, {TextTransparency=self._textTransparency}, animate) end
        if self.title then w:_reveal(self.title, {TextTransparency=shown and 0 or 1}, animate) end
        if self.descriptor then w:_reveal(self.descriptor.titleLabel, {TextTransparency=shown and 0.7 or 1}, animate) end
    end
    function Console:Remove()
        if self.descriptor then self.descriptor:Remove() end
        self.main:Destroy()
    end
    moveable(Console)
    return Console
end

__modules["components.dropdown"] = function()
    local Dropdown = {}
    Dropdown.__index = Dropdown
    Dropdown.__type = "Dropdown"
    local variables = __require("utility.variables")
    local functions = __require("utility.functions")
    local image = __require("utility.image")
    local constants = __require("utility.constants")
    local locale = __require("utility.locale")
    local hapticEngine = __require("utility.HapticEngine")
    local windowSizing = __require("utility.windowSizing")
    local lockable = __require("utility.lockable")
    
    local chevronIcon, checkIcon, dotIcon, searchIconAsset = constants.icons.chevron, constants.icons.check, constants.icons.dot, constants.icons.search
    local roundRadius, flatRadius = UDim.new(0, 12), UDim.new(0, 7)
    local searchCollapsedHeight, searchExpandedHeight, optionHeight, optionGap, listPadding = 30, 38, 38, 5, 2
    local headerHeight, headerGap, cardPaddingTop, cardPaddingBottom = 41, 6, 7, 6
    local cardPadding = cardPaddingTop + cardPaddingBottom
    local maxVisibleOptions, actionsHeight = 4, 22
    local hintTween = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local hoverTween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local scrollbarShown, searchTween = 0.4, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    
    local function dedupStrings(arr)
        local seen, out = {}, {}
        for _, v in pairs(arr) do
            if type(v) == "string" and not seen[v] then seen[v] = true table.insert(out, v) end
        end
        return out
    end
    local function normalizeValue(value, multi)
        if value == nil then return {} end
        if type(value) == "string" then return { value } end
        if type(value) == "table" then
            local out = dedupStrings(value)
            if not multi and #out > 1 then return { out[1] } end
            return out
        end
        return {}
    end
    local function intersectWithOptions(value, options)
        local out = {}
        for _, v in pairs(value) do
            local found = false
            for _, o in ipairs(options) do if o == v then found = true break end end
            if found then table.insert(out, v) end
        end
        return out
    end
    local function sameSelection(a, b)
        if #a ~= #b then return false end
        for _, v in pairs(a) do
            local found = false
            for _, o in ipairs(b) do if o == v then found = true break end end
            if not found then return false end
        end
        return true
    end

    function Dropdown.new(tab, properties)
        properties = typeof(properties) == "table" and properties or {}
        local options = properties.options or properties.Options or {}
        local multiSelect = properties.multiSelect or properties.MultiSelect or properties.MultipleOptions or false
        local self = setmetatable({
            tab = assert(tab, "Missing argument #1 (Tab expected)"), window = tab.window,
            name = properties.name or properties.Name or "Dropdown", icon = properties.icon or properties.Icon,
            description = properties.description or properties.Description, forgetState = properties.forgetState or properties.ForgetState or tab.forgetState,
            flag = properties.flag or properties.Flag or (not (properties.forgetState or properties.ForgetState or tab.forgetState) and functions.deriveFlagFromName(properties.name or properties.Name or "Dropdown") or nil),
            callback = properties.callback or properties.Callback or function() end, options = dedupStrings(options), multiSelect = multiSelect,
            placeholderText = locale.resolve(properties.placeholder or properties.Placeholder or "None"),
            value = normalizeValue(properties.value or properties.Value or properties.currentOption or properties.CurrentOption, multiSelect),
            _isOpen = false, _optionFrames = {},
        }, Dropdown)
        self._desiredValue = self.value
        self.value = intersectWithOptions(self.value, self.options)
        self.window:_registerControl(self)
        self.main = self.window:Create("Frame", {Size=UDim2.new(1,-20,0,41),BorderSizePixel=0,Name=self.name,BackgroundTransparency=1,Parent=self.tab.tabPage})
        self.top = self.window:Create("Frame", {Size=UDim2.new(1,0,0,41),Position=UDim2.fromScale(0,0),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,ZIndex=1,Parent=self.main},{BackgroundTransparency="ElementTransparency"})
        self.stroke = self.window:StyleElementBody(self.top)
        self.hoverOverlay = self.window:CreateHoverOverlay(self.top)
        self.flashTarget = self.top
        self.container = self.window:Create("Frame", {BorderSizePixel=0,Parent=self.top,Size=UDim2.new(0,170,0,16),Position=UDim2.new(0,20,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1,ZIndex=5})
        self.containerLayout = self.window:Create("UIListLayout", {Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Left,Parent=self.container})
        if self.icon then self.iconLabel = self.window:Create("ImageLabel", {Image=self.icon,Size=UDim2.fromOffset(16,16),BorderSizePixel=0,BackgroundTransparency=1,ImageTransparency=1,ZIndex=5,Parent=self.container},{ImageColor3="ContentColor"}) end
        self.title = self.window:Create("TextLabel", {Text=locale.t(self.name),Size=UDim2.fromOffset(150,16),BorderSizePixel=0,BackgroundTransparency=1,TextSize=16,AutomaticSize=Enum.AutomaticSize.X,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1,TextTransparency=1,ZIndex=5,Parent=self.container},{TextColor3="ContentColor",FontFace="Font"})
        self.selectedLabel = self.window:Create("TextLabel", {AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-41,0.5,0),Size=UDim2.fromOffset(168,15),BorderSizePixel=0,BackgroundTransparency=1,TextSize=15,TextXAlignment=Enum.TextXAlignment.Right,TextWrapped=true,TextTransparency=1,ZIndex=5,Parent=self.top},{TextColor3="ContentColor",FontFace="Font"})
        self.chevron = self.window:Create("ImageLabel", {AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-18,0.5,0),Size=UDim2.fromOffset(16,16),BorderSizePixel=0,BackgroundTransparency=1,Image="rbxassetid://"..tostring(chevronIcon),Rotation=180,ImageTransparency=1,ZIndex=5,Parent=self.top},{ImageColor3="ContentColor"})
        self.interact = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.new(1,0,0,41),Position=UDim2.fromScale(0,0),BorderSizePixel=0,Text="",TextTransparency=1,ZIndex=10,AutoButtonColor=false,Parent=self.main})
        self.panel = self.window:Create("Frame", {AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,0,1,0),Size=UDim2.new(1,0,1,-(headerHeight+headerGap)),BorderSizePixel=0,ClipsDescendants=true,BackgroundColor3=Color3.fromRGB(255,255,255),ZIndex=1,BackgroundTransparency=1,Parent=self.main})
        self.panelStroke = self.window:StyleElementPanel(self.panel)
        self.window:Create("UIListLayout", {Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Vertical,VerticalAlignment=Enum.VerticalAlignment.Top,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=self.panel})
        self.window:Create("UIPadding", {PaddingTop=UDim.new(0,cardPaddingTop),PaddingBottom=UDim.new(0,cardPaddingBottom),Parent=self.panel})
        self:_buildSearch()
        self:_buildActions()
        self.list = self.window:Create("ScrollingFrame", {Active=true,Size=UDim2.new(1,0,0,0),BorderSizePixel=0,BackgroundTransparency=1,ClipsDescendants=true,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarImageColor3=Color3.fromRGB(240,240,240),ScrollBarThickness=3,ScrollBarImageTransparency=1,ScrollingDirection=Enum.ScrollingDirection.Y,LayoutOrder=3,ZIndex=1,Parent=self.panel})
        self.window:Create("UIFlexItem", {FlexMode=Enum.UIFlexMode.Fill,Parent=self.list})
        self.window:ConnectFor(self, self.list:GetPropertyChangedSignal("CanvasPosition"), function() self:_syncScrollHint() end)
        self.window:ConnectFor(self, self.list:GetPropertyChangedSignal("AbsoluteCanvasSize"), function() self:_syncScrollHint() end)
        self.window:ConnectFor(self, self.list:GetPropertyChangedSignal("AbsoluteWindowSize"), function() self:_syncScrollHint() end)
        self.listLayout = self.window:Create("UIListLayout", {Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,Parent=self.list})
        self.window:Create("UIPadding", {PaddingTop=UDim.new(0,listPadding),PaddingBottom=UDim.new(0,listPadding),Parent=self.list})
        self.emptyLabel = self.window:Create("TextLabel", {Name="Empty",Size=UDim2.new(1,-12,0,optionHeight),BackgroundTransparency=1,Text=locale.t("No matches"),TextSize=14,TextTransparency=0.55,Visible=false,LayoutOrder=1,Parent=self.list},{TextColor3="ContentColor",FontFace="Font"})
        
        local function isOptionSelected(name)
            for _, v in pairs(self.value) do if v == name then return true end end return false
        end
        local function renderOptionState(data, animate)
            local selected = isOptionSelected(data.name)
            local bgT = self._isOpen and (selected and 0.9 or 0.95) or 1
            local titleT = self._isOpen and (selected and 0 or 0.3) or 1
            local iconT = self._isOpen and (selected and 0 or 0.7) or 1
            local strokeT = self._isOpen and (selected and 0.85 or 0.93) or 1
            image.assign(data.checkIcon, "Image", selected and checkIcon or dotIcon)
            if animate then
                local info = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
                variables.tweenService:Create(data.frame, info, {BackgroundTransparency=bgT}):Play()
                variables.tweenService:Create(data.title, info, {TextTransparency=titleT}):Play()
                variables.tweenService:Create(data.checkIcon, info, {ImageTransparency=iconT}):Play()
                variables.tweenService:Create(data.stroke, info, {Transparency=strokeT}):Play()
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
                if n == 0 then self.selectedLabel.Text = self.placeholderText elseif n == 1 then self.selectedLabel.Text = self.value[1] else self.selectedLabel.Text = locale.resolve("Various") end
            else
                self.selectedLabel.Text = self.value[1] or self.placeholderText
            end
        end
        self._renderOptionState, self._updateSelectedLabel = renderOptionState, updateSelectedLabel
        
        local function buildOption(optionName)
            local frame = self.window:Create("Frame", {Size=UDim2.new(1,-12,0,optionHeight),BorderSizePixel=0,LayoutOrder=#self._optionFrames+1,BackgroundTransparency=1,Parent=self.list},{BackgroundColor3="DropdownHighlight"})
            local corner = self.window:Create("UICorner", {CornerRadius=flatRadius,Parent=frame})
            local optionStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Transparency=1,Parent=frame})
            local interact = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="",TextTransparency=1,ZIndex=50,Parent=frame})
            local container = self.window:Create("Frame", {AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,14,0.5,0),Size=UDim2.fromOffset(170,16),BorderSizePixel=0,BackgroundTransparency=1,ZIndex=5,Parent=frame})
            self.window:Create("UIListLayout", {Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=container})
            local checkIco = self.window:Create("ImageLabel", {Image="rbxassetid://"..tostring(checkIcon),Size=UDim2.fromOffset(16,16),BorderSizePixel=0,BackgroundTransparency=1,ImageTransparency=1,ZIndex=5,Parent=container},{ImageColor3="ContentColor"})
            local title = self.window:Create("TextLabel", {Text=optionName,Size=UDim2.fromOffset(170,16),BorderSizePixel=0,BackgroundTransparency=1,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1,TextTransparency=1,ZIndex=5,Parent=container},{TextColor3="ContentColor",FontFace="Font"})
            local data = {name=optionName, frame=frame, interact=interact, title=title, checkIcon=checkIco, container=container, stroke=optionStroke, corner=corner, connections={}}
            table.insert(data.connections, self.window:ConnectFor(self, frame.MouseEnter, function()
                if not self._isOpen or not self.window:_interactive() or isOptionSelected(data.name) then return end
                variables.tweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency=0.9}):Play()
                variables.tweenService:Create(title, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency=0.15}):Play()
            end))
            table.insert(data.connections, self.window:ConnectFor(self, frame.MouseLeave, function()
                if not self._isOpen or isOptionSelected(data.name) then return end
                variables.tweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency=0.95}):Play()
                variables.tweenService:Create(title, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency=0.3}):Play()
            end))
            table.insert(data.connections, self.window:ConnectFor(self, interact.MouseButton1Click, function()
                if not self._isOpen then return end
                hapticEngine.click()
                local sel = isOptionSelected(data.name)
                if not self.multiSelect then
                    if sel then self:_close() return end
                    table_clear(self.value)
                    table.insert(self.value, data.name)
                else
                    if sel then
                        for i,v in ipairs(self.value) do if v==data.name then table.remove(self.value,i) break end end
                    else table.insert(self.value, data.name) end
                end
                self._desiredValue = table_clone(self.value)
                for _, d in ipairs(self._optionFrames) do renderOptionState(d, true) end
                updateSelectedLabel()
                self.window:_runGuarded(self, self.callback, self:_callbackValue())
                self.window:_persist(self)
                if not self.multiSelect then task.wait(0.1) self:_close() end
            end))
            return data
        end
        self._buildOption = buildOption
        for _, opt in ipairs(self.options) do table.insert(self._optionFrames, buildOption(opt)) end
        updateSelectedLabel()
        self:_updateCorners()
        self.window:ConnectFor(self, self.interact.MouseButton1Click, function() hapticEngine.click() if self._isOpen then self:_close() else self:_open() end end)
        self.window:ConnectFor(self, self.main.MouseEnter, function()
            if self._isOpen or not self.window:_interactive() then return end
            variables.tweenService:Create(self.title, hoverTween, {TextColor3=self.window.theme.ElementTextHoverColor}):Play()
            variables.tweenService:Create(self.hoverOverlay, hoverTween, {BackgroundTransparency=0.97}):Play()
            variables.tweenService:Create(self.stroke, hoverTween, {Transparency=self.window.theme.ElementStrokeHoverTransparency, Color=self.window.theme.ElementStrokeHover}):Play()
        end)
        self.window:ConnectFor(self, self.main.MouseLeave, function()
            variables.tweenService:Create(self.title, hoverTween, {TextColor3=self.window.theme.ContentColor}):Play()
            variables.tweenService:Create(self.hoverOverlay, hoverTween, {BackgroundTransparency=1}):Play()
            variables.tweenService:Create(self.stroke, hoverTween, {Transparency=self.window.theme.ElementStrokeTransparency, Color=self.window.theme.ElementStroke}):Play()
        end)
        if self.description then self.descriptor = __require("components.descriptor").new(self.tab, { description = self.description }) end
        return self
    end

    function Dropdown:_callbackValue() return self.multiSelect and table_clone(self.value) or self.value[1] end

    function Dropdown:_buildSearch()
        self._searchOpen = false
        self.searchbar = self.window:Create("Frame", {Name="Search",Size=UDim2.new(1,-12,0,searchCollapsedHeight),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,LayoutOrder=1,ClipsDescendants=false,ZIndex=1,Parent=self.panel})
        self.window:Create("UICorner", {CornerRadius=UDim.new(0,12),Parent=self.searchbar})
        self.searchStroke = self.window:Create("UIStroke", {Color=Color3.fromRGB(255,255,255),Transparency=1,Parent=self.searchbar})
        self.searchShadow = self.window:CreateGlow(self.searchbar, Color3.fromRGB(255,255,255), 20, 1)
        self.searchToggle = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="",TextTransparency=1,ZIndex=51,Parent=self.searchbar})
        self.searchInput = self.window:Create("TextBox", {Text="",PlaceholderText=locale.t("Search..."),Size=UDim2.new(1,-58,0,16),Position=UDim2.new(0,44,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,TextEditable=false,Interactable=false,ZIndex=52,TextTransparency=1,Parent=self.searchbar},{TextColor3="ContentColor",FontFace="Font",PlaceholderColor3="PlaceholderColor"})
        self.searchIcon = self.window:Create("ImageButton", {Image="rbxassetid://"..tostring(searchIconAsset),Size=UDim2.fromOffset(20,20),Position=UDim2.new(0,24,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,AutoButtonColor=false,ZIndex=53,ImageTransparency=1,Parent=self.searchbar},{ImageColor3="ContentColor"})
        self.window:ConnectFor(self, self.searchToggle.MouseButton1Click, function() if not self._searchOpen then self:_expandSearch() end end)
        self.window:ConnectFor(self, self.searchIcon.MouseButton1Click, function() if self._searchOpen then self:_collapseSearch() else self:_expandSearch() end end)
        self.window:ConnectFor(self, self.searchInput:GetPropertyChangedSignal("Text"), function() self:_applyFilter(self.searchInput.Text) end)
        self.window:ConnectFor(self, self.searchInput.FocusLost, function() if self.searchInput.Text == "" then self:_collapseSearch() end end)
    end

    function Dropdown:_expandSearch()
        if self._searchOpen then return end
        self._searchOpen, self.searchInput.TextEditable, self.searchInput.Interactable = true, true, true
        variables.tweenService:Create(self.searchbar, searchTween, {Size=UDim2.new(1,-12,0,searchExpandedHeight), BackgroundTransparency=0.92}):Play()
        variables.tweenService:Create(self.searchStroke, searchTween, {Transparency=0.86}):Play()
        variables.tweenService:Create(self.searchShadow, searchTween, {Transparency=0.92}):Play()
        variables.tweenService:Create(self.searchInput, searchTween, {TextTransparency=0.3}):Play()
        self:_resizeToOptions()
        self.searchInput:CaptureFocus()
    end

    function Dropdown:_collapseSearch()
        if not self._searchOpen then return end
        self._searchOpen, self.searchInput.TextEditable, self.searchInput.Interactable = false, false, false
        self.searchInput:ReleaseFocus()
        self.searchInput.Text = ""
        variables.tweenService:Create(self.searchbar, searchTween, {Size=UDim2.new(1,-12,0,searchCollapsedHeight), BackgroundTransparency=1}):Play()
        variables.tweenService:Create(self.searchStroke, searchTween, {Transparency=1}):Play()
        variables.tweenService:Create(self.searchShadow, searchTween, {Transparency=1}):Play()
        variables.tweenService:Create(self.searchInput, searchTween, {TextTransparency=1}):Play()
        self:_resizeToOptions()
    end

    function Dropdown:_applyFilter(query)
        query = string.lower(query or "")
        local shown = 0
        for _, data in ipairs(self._optionFrames) do
            local visible = query == "" or string.find(string.lower(data.name), query, 1, true) ~= nil
            data.frame.Visible = visible
            if visible then shown = shown + 1 end
        end
        self.emptyLabel.Visible = (shown == 0 and query ~= "")
        self:_updateCorners()
        self:_resizeToOptions()
        self:_syncScrollHint()
    end

    function Dropdown:_syncScrollHint()
        local canvasSize, windowSize, at = self.list.AbsoluteCanvasSize, self.list.AbsoluteWindowSize, self.list.CanvasPosition
        if not canvasSize or not windowSize or not at then return end
        local more = self._isOpen and windowSize.Y > 0 and canvasSize.Y - (at.Y + windowSize.Y) > 1
        variables.tweenService:Create(self.list, hintTween, {ScrollBarImageTransparency=more and scrollbarShown or 1}):Play()
    end

    function Dropdown:_visibleOptions()
        local names = {}
        for _, data in ipairs(self._optionFrames) do if data.frame.Visible then table.insert(names, data.name) end end
        return names
    end

    function Dropdown:_buildActions()
        if not self.multiSelect then return end
        self.actions = self.window:Create("Frame", {Name="Actions",Size=UDim2.new(1,-12,0,actionsHeight),BackgroundTransparency=1,LayoutOrder=2,Parent=self.panel})
        self.window:Create("UIListLayout", {Padding=UDim.new(0,12),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=self.actions})
        local function action(label, order, apply)
            local button = self.window:Create("TextButton", {AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,actionsHeight),BackgroundTransparency=1,Text=locale.t(label),TextSize=13,TextTransparency=0.45,LayoutOrder=order,Parent=self.actions},{TextColor3="ContentColor",FontFace="Font"})
            self.window:ConnectFor(self, button.MouseEnter, function() variables.tweenService:Create(button, hintTween, {TextTransparency=0.15}):Play() end)
            self.window:ConnectFor(self, button.MouseLeave, function() variables.tweenService:Create(button, hintTween, {TextTransparency=0.45}):Play() end)
            self.window:ConnectFor(self, button.MouseButton1Click, function() apply() self:_afterBulkChange() end)
            return button
        end
        action("Select all", 1, function()
            for _, name in ipairs(self:_visibleOptions()) do
                local found = false for _,v in ipairs(self.value) do if v==name then found=true break end end
                if not found then table.insert(self.value, name) end
            end
        end)
        action("Clear", 2, function()
            local shown = self:_visibleOptions()
            for index = #self.value, 1, -1 do
                local found = false for _,v in ipairs(shown) do if v==self.value[index] then found=true break end end
                if found then table.remove(self.value, index) end
            end
        end)
    end

    function Dropdown:_afterBulkChange()
        self._desiredValue = table_clone(self.value)
        for _, data in ipairs(self._optionFrames) do self._renderOptionState(data, true) end
        self:_updateSelectedLabel()
        self:_updateCorners()
        self.window:_runGuarded(self, self.callback, self:_callbackValue())
        self.window:_persist(self)
        hapticEngine.click()
    end

    function Dropdown:_resizeToOptions()
        if not self._isOpen then return end
        variables.tweenService:Create(self.main, searchTween, {Size=UDim2.new(1,-20,0,self:_openHeight())}):Play()
    end

    function Dropdown:_updateCorners()
        local visible = {}
        for _, data in ipairs(self._optionFrames) do if data.frame.Visible then table.insert(visible, data) end end
        for i, data in ipairs(visible) do
            local topR = i == 1 and roundRadius or flatRadius
            local botR = i == #visible and roundRadius or flatRadius
            data.corner.TopLeftRadius, data.corner.TopRightRadius, data.corner.BottomLeftRadius, data.corner.BottomRightRadius = topR, topR, botR, botR
        end
    end

    local function listHeight(count) return count * optionHeight + math.max(0, count - 1) * optionGap + listPadding * 2 end
    local function rowsThatFit(space) return math.max(math.floor((space - listPadding * 2 + optionGap) / (optionHeight + optionGap)), 1) end

    function Dropdown:_pageHeight()
        local size = self.window.size
        return windowSizing.pageHeight(size and size.Y.Offset, self.window.layout.mode)
    end

    function Dropdown:_openHeight()
        local n = 0
        for _, data in ipairs(self._optionFrames) do if data.frame.Visible then n = n + 1 end end
        local searchHeight = self._searchOpen and searchExpandedHeight or searchCollapsedHeight
        local overhead = headerHeight + headerGap + cardPadding + searchHeight + optionGap + (self.actions and (actionsHeight + optionGap) or 0)
        local available = self:_pageHeight()
        local rows = math.min(math.max(n, 1), maxVisibleOptions, rowsThatFit(available - overhead))
        return math.min(overhead + listHeight(rows), available)
    end

    function Dropdown:_open()
        if self._isOpen then return end
        self._isOpen = true
        if self._outsideClickConn then self.window:Disconnect(self._outsideClickConn) end
        self._outsideClickConn = self.window:Connect(variables.userInputService.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local pos, mainPos, mainSize = input.Position, self.main.AbsolutePosition, self.main.AbsoluteSize
            if pos.X < mainPos.X or pos.X > mainPos.X + mainSize.X or pos.Y < mainPos.Y or pos.Y > mainPos.Y + mainSize.Y then self:_close() end
        end)
        variables.tweenService:Create(self.main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size=UDim2.new(1,-20,0,self:_openHeight())}):Play()
        variables.tweenService:Create(self.chevron, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Rotation=0}):Play()
        variables.tweenService:Create(self.panel, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency=self.window.theme.ElementTransparency or 0}):Play()
        variables.tweenService:Create(self.panelStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency=self.window.theme.ElementStrokeTransparency}):Play()
        variables.tweenService:Create(self.searchIcon, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency=0.5}):Play()
        for _, data in ipairs(self._optionFrames) do self._renderOptionState(data, true) end
        self:_syncScrollHint()
        self:_bringIntoView()
    end

    function Dropdown:_bringIntoView()
        local page = self.tab and self.tab.tabPage
        if not page then return end
        local view, at, pageAt, cardAt = page.AbsoluteWindowSize, page.CanvasPosition, page.AbsolutePosition, self.main.AbsolutePosition
        if not view or not at or not pageAt or not cardAt or view.Y <= 0 then return end
        local top = cardAt.Y - pageAt.Y + at.Y
        local bottom = top + self:_openHeight()
        local overflow = bottom - (at.Y + view.Y)
        if overflow <= 0 then return end
        local target = math.min(at.Y + overflow + 8, top)
        variables.tweenService:Create(page, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {CanvasPosition=Vector2.new(at.X, target)}):Play()
    end

    function Dropdown:_close()
        if not self._isOpen then return end
        self._isOpen = false
        if self._outsideClickConn then self.window:Disconnect(self._outsideClickConn) self._outsideClickConn = nil end
        self:_collapseSearch()
        self:_syncScrollHint()
        variables.tweenService:Create(self.chevron, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Rotation=180}):Play()
        variables.tweenService:Create(self.panel, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency=1}):Play()
        variables.tweenService:Create(self.panelStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency=1}):Play()
        variables.tweenService:Create(self.searchIcon, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency=1}):Play()
        for _, data in ipairs(self._optionFrames) do self._renderOptionState(data, true) end
        variables.tweenService:Create(self.main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size=UDim2.new(1,-20,0,41)}):Play()
    end

    function Dropdown:_destroyOption(data)
        if data.connections then
            for _, connection in ipairs(data.connections) do
                for i, c in ipairs(self.connections) do if c == connection then table.remove(self.connections, i) break end end
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
        for index, data in ipairs(self._optionFrames) do data.frame.LayoutOrder = index end
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
                for _, c in ipairs(data.connections) do table.insert(connections, c) end
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
        local existing, wanted = #self._optionFrames, #self.options
        for index = 1, math.min(existing, wanted) do self:_rebindOption(self._optionFrames[index], self.options[index], index) end
        for index = existing + 1, wanted do
            local data = self._buildOption(self.options[index])
            data.frame.LayoutOrder = index
            table.insert(self._optionFrames, data)
        end
        if wanted < existing then self:_destroyOptionsFrom(wanted + 1) end
        for _, data in ipairs(self._optionFrames) do self._renderOptionState(data, false) end
        self._updateSelectedLabel()
        self:_applyFilter(self._searchOpen and self.searchInput.Text or "")
        if selectionChanged then self.window:_runGuarded(self, self.callback, self:_callbackValue()) self.window:_persist(self) end
    end

    function Dropdown:Add(option)
        if type(option) ~= "string" or option == "" then return end
        for _, o in ipairs(self.options) do if o == option then return end end
        table.insert(self.options, option)
        local data = self._buildOption(option)
        table.insert(self._optionFrames, data)
        local selectionChanged = self:_deriveSelection()
        if self._isOpen then self._renderOptionState(data, true) end
        self:_applyFilter(self._searchOpen and self.searchInput.Text or "")
        if selectionChanged then
            self._updateSelectedLabel()
            self.window:_runGuarded(self, self.callback, self:_callbackValue())
            self.window:_persist(self)
        end
    end

    function Dropdown:Remove(option)
        local idx for i,o in ipairs(self.options) do if o == option then idx = i break end end
        if not idx then return end
        table.remove(self.options, idx)
        for i, data in ipairs(self._optionFrames) do
            if data.name == option then self:_destroyOption(data) table.remove(self._optionFrames, i) self:_reindexOptions() break end
        end
        if self._desiredValue then
            for i,v in ipairs(self._desiredValue) do if v==option then table.remove(self._desiredValue, i) break end end
        end
        local valueIdx for i,v in ipairs(self.value) do if v==option then valueIdx = i break end end
        if valueIdx then
            table.remove(self.value, valueIdx)
            self._updateSelectedLabel()
            self.window:_runGuarded(self, self.callback, self:_callbackValue())
            self.window:_persist(self)
        end
        self:_applyFilter(self._searchOpen and self.searchInput.Text or "")
    end

    function Dropdown:Set(value, skipCallback)
        local newValue = normalizeValue(value, self.multiSelect)
        self._desiredValue = newValue
        self.value = intersectWithOptions(newValue, self.options)
        for _, data in ipairs(self._optionFrames) do self._renderOptionState(data, true) end
        self._updateSelectedLabel()
        if not skipCallback then self.window:_runGuarded(self, self.callback, self:_callbackValue()) self.window:_persist(self) end
    end

    function Dropdown:_setShown(shown, animate)
        local w = self.window
        w:_reveal(self.stroke, {Transparency=shown and w.theme.ElementStrokeTransparency or 1}, animate)
        w:_reveal(self.title, {TextTransparency=shown and 0 or 1}, animate)
        w:_reveal(self.top, {BackgroundTransparency=shown and (w.theme.ElementTransparency or 0) or 1}, animate)
        if self.iconLabel then w:_reveal(self.iconLabel, {ImageTransparency=shown and 0 or 1}, animate) end
        if self.descriptor then w:_reveal(self.descriptor.titleLabel, {TextTransparency=shown and 0.7 or 1}, animate) end
        w:_reveal(self.selectedLabel, {TextTransparency=shown and 0.5 or 1}, animate)
        w:_reveal(self.chevron, {ImageTransparency=shown and 0.5 or 1}, animate)
        if not shown and self._isOpen then self:_close() end
    end

    function Dropdown:MoveTo(index) self.tab:_moveElement(self, index) end
    function Dropdown:MoveToTop() self.tab:_moveElement(self, 1) end
    function Dropdown:MoveToBottom() self.tab:_moveElement(self, #self.tab.elements) end
    function Dropdown:MoveUp() local idx for i,e in ipairs(self.tab.elements) do if e==self then idx=i break end end if idx then self.tab:_moveElement(self, idx - 1) end end
    function Dropdown:MoveDown() local idx for i,e in ipairs(self.tab.elements) do if e==self then idx=i break end end if idx then self.tab:_moveElement(self, idx + 1) end end
    lockable(Dropdown)
    return Dropdown
end

__modules["components.group"] = function()
    local Group = {}
    Group.__index = Group
    Group.__type = "Group"
    local moveable = __require("utility.moveable")
    local log = __require("utility.log")
    local assignOrder = __require("utility.ordering")
    local elementPadding = 8
    local compactCapable = { button = true, toggle = true, stat = true, slider = true }

    function Group.new(tab, properties)
        properties = typeof(properties) == "table" and properties or {}
        local dir = string.lower(properties.direction or properties.Direction or "row")
        local vertical = dir == "column" or dir == "vertical"
        local horizontal = not vertical
        local direction = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
        local self = setmetatable({
            tab = assert(tab, "Missing argument #1 (Tab expected)"), window = tab.window,
            direction = direction, compact = horizontal, forgetState = tab.forgetState, elements = {},
        }, Group)
        local nestedInRow = tab.direction == Enum.FillDirection.Horizontal
        self.main = self.window:Create("Frame", {Name="Group",BackgroundTransparency=1,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,Size=horizontal and UDim2.new(1,-20,0,0) or UDim2.new(1,0,0,0),Parent=self.tab.tabPage})
        if nestedInRow then
            self.main.Size = UDim2.new(0,0,0,0)
            self.window:Create("UIFlexItem", {FlexMode=Enum.UIFlexMode.Fill,Parent=self.main})
        end
        self.tabPage = self.main
        self.layout = self.window:Create("UIListLayout", {FillDirection=direction,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,elementPadding),VerticalAlignment=horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,HorizontalAlignment=horizontal and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,Parent=self.main})
        return self
    end

    function Group:_add(componentName, properties)
        if self.compact and not compactCapable[componentName] then
            log.warn("Library: a row only holds compact elements (button/toggle/stat/slider), ignoring '" .. tostring(componentName) .. "'. Use a column for it.")
            return nil
        end
        local element = __require("components." .. componentName).new(self, properties)
        table.insert(self.elements, element)
        assignOrder(element, #self.elements * 10)
        self.window:_restoreLate(element)
        if self.compact then self:_wrapChild(element) end
        self:_reflowRow()
        if not self.window.hidden then element:_setShown(true, true) end
        return element
    end

    function Group:_reflowRow()
        if self.direction ~= Enum.FillDirection.Horizontal then return end
        local onlyGroups = #self.elements > 0
        for _, element in ipairs(self.elements) do if element.__type ~= "Group" then onlyGroups = false break end end
        self.layout.Padding = onlyGroups and UDim.new(0, -10) or UDim.new(0, elementPadding)
    end

    function Group:_wrapChild(element)
        self.layout.Wraps = true
        self.layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        element._widthManaged = true
        local minWidth = element._minWidth and element:_minWidth() or 0
        if minWidth > 0 then
            element.main.AutomaticSize = Enum.AutomaticSize.None
            element.main.Size = UDim2.new(0, minWidth, element.main.Size.Y.Scale, element.main.Size.Y.Offset)
        end
    end

    function Group:CreateButton(properties) return self:_add("button", properties) end
    function Group:CreateToggle(properties) return self:_add("toggle", properties) end
    function Group:CreateSwitch(properties) return self:_add("toggle", properties) end
    function Group:CreateStat(properties) return self:_add("stat", properties) end
    function Group:CreateSlider(properties) return self:_add("slider", properties) end
    function Group:CreateDropdown(properties) return self:_add("dropdown", properties) end
    function Group:CreateSection(properties) return self:_add("section", properties) end
    function Group:CreateText(properties) return self:_add("text", properties) end
    function Group:CreateDivider(properties) return self:_add("divider", properties) end

    function Group:_addGroup(properties)
        properties = typeof(properties) == "table" and table_clone(properties) or {}
        if self.direction == Enum.FillDirection.Horizontal then
            self.layout.VerticalAlignment = Enum.VerticalAlignment.Top
            if self.tab.direction ~= Enum.FillDirection.Horizontal then self.main.Size = UDim2.new(1,0,0,0) end
        end
        local group = Group.new(self, properties)
        table.insert(self.elements, group)
        group.main.LayoutOrder = #self.elements * 10
        self:_reflowRow()
        return group
    end

    function Group:CreateGroup(properties) return self:_addGroup(properties) end

    function Group:_moveElement(element, targetIndex)
        local idx for i,e in ipairs(self.elements) do if e==element then idx=i break end end
        if not idx then return end
        table.remove(self.elements, idx)
        targetIndex = math.clamp(targetIndex, 1, #self.elements + 1)
        table.insert(self.elements, targetIndex, element)
        for i, el in ipairs(self.elements) do assignOrder(el, i * 10) end
    end

    function Group:_setShown(shown, animate) for _, el in ipairs(self.elements) do el:_setShown(shown, animate) end end
    function Group:_refreshTheme() for _, el in ipairs(self.elements) do if el._refreshTheme then el:_refreshTheme() end end end
    moveable(Group)
    return Group
end

-- System Modules

__modules["components.window"] = function()
    local variables = __require("utility.variables")
    local functions = __require("utility.functions")
    local persistence = __require("utility.persistence")
    local constants = __require("utility.constants")
    local locale = __require("utility.locale")
    local hapticEngine = __require("utility.HapticEngine")
    local windowSizing = __require("utility.windowSizing")
    local layouts = __require("utility.layouts")
    local Window = {}
    Window.__index = Window
    
    local revealInfo = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    
    local function fitWindowSize(mode) return windowSizing.fit(nil, mode) end
    local function resolveLayout(value) return value and layouts.sidebar or layouts.top end
    
    local function themeOverrides(value) return typeof(value) == "table" and value or __require("themes.default") end
    local function resolveTheme(value) return themeOverrides(value) end
    
    function Window.new(properties)
        properties = typeof(properties) == "table" and properties or {}
        local layout = resolveLayout(properties.sidebarLayout or properties.SidebarLayout)
        local self = setmetatable({
            name = properties.name or properties.Name or "Library Window",
            layout = layout, size = fitWindowSize(layout.mode), instances = {}, connections = {},
            tabs = {}, tabSections = {}, tags = {}, controls = {}, theme = resolveTheme(properties.theme or properties.Theme),
            configuration = { autoSave = false, autoLoad = false },
        }, Window)
        self.screenGui = self:Create("ScreenGui", {Name="LibraryGui", IgnoreGuiInset=true, ResetOnSpawn=false, Enabled=true, ZIndexBehavior=Enum.ZIndexBehavior.Global, Parent=variables.guiContainer or game:GetService("CoreGui")})
        self.main = self:Create("Frame", {Name=self.name,BackgroundColor3=Color3.fromRGB(25,25,25),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=self.size,Visible=false,Parent=self.screenGui})
        self.windowCorner = self:Create("UICorner", {Parent=self.main}, {CornerRadius="CornerRoundness"})
        
        self.elements = self:Create("Frame", {Size=UDim2.new(1,0,1,-40),Position=UDim2.fromScale(1,1),AnchorPoint=Vector2.new(1,1),BackgroundColor3=Color3.fromRGB(25,25,25),BorderSizePixel=0,BackgroundTransparency=1,ClipsDescendants=true,Parent=self.main})
        self.elementsLayout = self:Create("UIPageLayout", {FillDirection=self.layout.pageDirection,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,EasingStyle=Enum.EasingStyle.Exponential,TweenTime=0.4,Parent=self.elements})
        
        self.tabList = self:Create("ScrollingFrame", {Name="Tabs",Active=true,Size=UDim2.new(1,0,0,40),Position=UDim2.new(0.5,0,0,10),AnchorPoint=Vector2.new(0.5,0),BackgroundTransparency=1,AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.X,Parent=self.main})
        self.tabListLayout = self:Create("UIListLayout", {Padding=UDim.new(0,7),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Left,SortOrder=Enum.SortOrder.LayoutOrder,Parent=self.tabList})
        self:Create("UIPadding", {PaddingLeft=UDim.new(0,22),PaddingRight=UDim.new(0,10),Parent=self.tabList})
        
        self.unloaded, self.minimised, self.hidden, self.animating, self._revealing, self.hasShownOnce = false, false, true, false, false, false
        return self
    end

    function Window:CreateTab(properties)
        local newTab = __require("components.tab").new(self, properties)
        table.insert(self.tabs, newTab)
        if not newTab.neglectSelector then
            if #self.tabs == 1 then newTab:Select(true) end
            if not self.hidden then newTab.topbarItem.Visible = true end
        end
        return newTab
    end

    function Window:Show()
        if self.animating or not self.hidden then return end
        self.animating = true
        self.hidden = false
        self.main.Visible = true
        self.main.Size = self.size
        self.animating = false
    end

    function Window:_jumpTo(page)
        if page then self.elementsLayout:JumpTo(page) end
    end
    
    function Window:Create(className, properties, themeProperties)
        local instance = Instance.new(className)
        if properties then for k,v in pairs(properties) do instance[k] = v end end
        if themeProperties then for k,v in pairs(themeProperties) do instance[k] = self.theme[v] or instance[k] end end
        table.insert(self.instances, instance)
        return instance
    end
    
    function Window:Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(self.connections, connection)
        return connection
    end
    
    function Window:ConnectFor(owner, signal, callback)
        local connection = self:Connect(signal, callback)
        owner.connections = owner.connections or {}
        table.insert(owner.connections, connection)
        return connection
    end
    
    function Window:_reveal(instance, props, animate, info)
        if not instance then return end
        if animate then variables.tweenService:Create(instance, info or revealInfo, props):Play() else for k,v in pairs(props) do instance[k]=v end end
    end
    
    function Window:_registerControl(control) end
    function Window:_restoreLate(element) end
    
    return Window
end

__modules["components.tab"] = function()
    local Tab = {}
    Tab.__index = Tab
    Tab.__type = "Tab"
    
    function Tab.new(window, properties)
        properties = typeof(properties) == "table" and properties or {}
        local self = setmetatable({
            window = assert(window, "Missing argument #1 (Window expected)"),
            name = properties.name or properties.Name,
            icon = properties.icon or properties.Icon,
            neglectSelector = properties.neglectSelector or properties.NeglectSelector or false,
            elements = {}, connections = {},
        }, Tab)
        
        self.topbarItem = self.window:Create("TextButton", {Name=self.name,Text=self.name or "",Size=UDim2.fromOffset(100, 34),BackgroundColor3=Color3.fromRGB(40,40,40),TextColor3=Color3.new(1,1,1),Parent=self.window.tabList})
        self.tabPage = self.window:Create("ScrollingFrame", {Name=self.name,Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0.5,0,0,68),AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,BackgroundTransparency=1,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=self.window.elements})
        self.tabPageLayout = self.window:Create("UIListLayout", {Padding=UDim.new(0,7),FillDirection=Enum.FillDirection.Vertical,VerticalAlignment=Enum.VerticalAlignment.Top,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=self.tabPage})
        self.window:Create("UIPadding", {PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,33),Parent=self.tabPage})
        
        if not self.neglectSelector then
            table.insert(self.connections, self.window:Connect(self.topbarItem.MouseButton1Click, function() self:Select() end))
        end
        return self
    end
    
    function Tab:Select(noAnimation)
        self.window.selectedTab = self
        self.window:_jumpTo(self.tabPage)
    end
    
    function Tab:Deselect(noAnimation) end
    
    function Tab:_register(element)
        table.insert(self.elements, element)
        if not self.window.hidden then element:_setShown(true, true) end
        return element
    end
    
    function Tab:CreateButton(properties) return self:_register(__require("components.button").new(self, properties)) end
    function Tab:CreateToggle(properties) return self:_register(__require("components.toggle").new(self, properties)) end
    function Tab:CreateGroup(properties) return self:_register(__require("components.group").new(self, properties)) end
    function Tab:CreateDropdown(properties) return self:_register(__require("components.dropdown").new(self, properties)) end
    function Tab:CreateColorPicker(properties) return self:_register(__require("components.colorpicker").new(self, properties)) end
    
    return Tab
end

__modules["themes.default"] = function()
    return {
        CornerRoundness = UDim.new(0, 8),
        WindowColor = Color3.fromRGB(25, 25, 25),
        ElementTransparency = 0,
        ElementStrokeTransparency = 0,
        ContentColor = Color3.fromRGB(200, 200, 200),
        AccentColor = Color3.fromRGB(48, 120, 240),
        AccentStroke = Color3.fromRGB(96, 164, 255),
        ElementStrokeHover = Color3.fromRGB(50, 50, 50),
        ElementTextHoverColor = Color3.fromRGB(255, 255, 255),
        ToggleKnobOff = Color3.fromRGB(150, 150, 150),
        ToggleKnobOffTransparency = 0,
        ToggleTrackTransparency = 1,
        AccentGlow = 0.5,
        FieldTransparency = 1
    }
end

__modules["components.toggle"] = function()
    local Toggle = {}
    Toggle.__index = Toggle
    Toggle.__type = "Toggle"
    local variables = __require("utility.variables")
    function Toggle.new(tab, properties)
        properties = typeof(properties) == "table" and properties or {}
        local self = setmetatable({
            tab = assert(tab, "Missing argument #1 (Tab expected)"), window = tab.window,
            name = properties.name or properties.Name or "Switch", callback = properties.callback or properties.Callback or function() end,
            value = properties.value or properties.Value or false,
        }, Toggle)
        self.main = self.window:Create("Frame", {Size=UDim2.new(1,-20,0,41),BorderSizePixel=0,Name=self.name,BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,Parent=self.tab.tabPage},{BackgroundTransparency="ElementTransparency"})
        self.title = self.window:Create("TextLabel", {Text=self.name,Size=UDim2.fromOffset(250,16),Position=UDim2.new(0,20,0.5,0),AnchorPoint=Vector2.new(0,0.5),BorderSizePixel=0,BackgroundTransparency=1,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,Parent=self.main},{TextColor3="ContentColor"})
        self.interact = self.window:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text="",ZIndex=10,Parent=self.main})
        self.indicator = self.window:Create("Frame", {Size=UDim2.fromOffset(25,17),Position=self.value and UDim2.new(1,-28,0.5,0) or UDim2.new(1,-47,0.5,0),AnchorPoint=Vector2.new(0,0.5),Parent=self.main})
        self.window:ConnectFor(self, self.interact.MouseButton1Click, function()
            self.value = not self.value
            variables.tweenService:Create(self.indicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position=self.value and UDim2.new(1,-28,0.5,0) or UDim2.new(1,-47,0.5,0)}):Play()
            self.callback(self.value)
        end)
        return self
    end
    function Toggle:_setShown(shown, animate)
        self.main.Visible = shown
    end
    return Toggle
end

-- Public Global API Endpoint

local Library = {}
function Library:CreateWindow(properties)
    local windowModule = __require("components.window")
    return windowModule.new(properties)
end

return Library