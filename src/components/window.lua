

local utility = script.Parent.Parent.utility
local image = require(utility.image)
local functions = require(utility.functions)
local persistence = require(utility.persistence)
local constants = require(utility.constants)
local locale = require(utility.locale)
local log = require(utility.log)
local hapticEngine = require(utility.HapticEngine)
local windowSizing = require(utility.windowSizing)
local layouts = require(utility.layouts)
local chrome = require(script.Parent.chrome)
local search = require(script.Parent.search)
local sidebar = require(script.Parent.sidebar)

local variables = require(utility.variables)

local themes = script.Parent.Parent.themes

local Window = {}
Window.__index = Window

local revealInfo = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local collapsedSize = UDim2.fromOffset(185, 50)
local collapsedIconSize = UDim2.fromOffset(50, 50)
local collapsedTop = UDim2.new(0.5, 0, 0, 20)
local topToastOpenPosition = UDim2.new(0.5, 0, 0, 12)
local topToastClosedPosition = UDim2.new(0.5, 0, 0, collapsedTop.Y.Offset + collapsedSize.Y.Offset + 12)
local topToastMoveInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local maxToastWidth = 320

local compactRowHeight = 41

local lockScrimTransparency = 0.55
local lockedDescriptionTransparency = 0.55

local tabStagger = 0.04
local maxStaggeredTabs = 8

local viewportReconcileInterval = 2

local function fitWindowSize(mode): UDim2
    local camera = variables.workspace.CurrentCamera
    return windowSizing.fit(camera and camera.ViewportSize, mode)
end

local cornerNames = { "TopLeftRadius", "TopRightRadius", "BottomLeftRadius", "BottomRightRadius" }

local perCornerSupported = (function()
    return (
        pcall(function()
            local probe = Instance.new("UICorner")
            probe.TopLeftRadius = UDim.new(0, 1)
            probe:Destroy()
        end)
    )
end)()

local function resolveLayout(value)
    return if value then layouts.sidebar else layouts.top
end

local gradientKeys = {
    WindowColor = true,
    ElementGradient = true,
    ElementStrokeGradient = true,
    TabBackground = true,
    TabStroke = true,
    SliderProgress = true,
}

local function coerceThemeValue(key, value)
    if gradientKeys[key] and typeof(value) == "Color3" then
        return ColorSequence.new(value)
    end
    return value
end

local function firstColor(value)
    return if typeof(value) == "ColorSequence" then value.Keypoints[1].Value else value
end

local function setTopToastPosition(window, animate)
    local container = window._toastsTop
    if not container then
        return
    end

    local target = if window._collapsedShown then topToastClosedPosition else topToastOpenPosition
    if not animate or container.Position == target then
        container.Position = target
        return
    end

    variables.tweenService:Create(container, topToastMoveInfo, { Position = target }):Play()
end

local function edgeShade(color, amount)
    local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
    local target = if luminance > 0.5 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
    return color:Lerp(target, amount)
end

local function deriveStrokes(resolved, overrides)
    if overrides.ElementGradient then
        local fill = firstColor(resolved.ElementGradient)
        if overrides.ElementStroke == nil then
            resolved.ElementStroke = edgeShade(fill, 0.28)
        end
        if overrides.ElementStrokeGradient == nil then
            resolved.ElementStrokeGradient = ColorSequence.new(edgeShade(fill, 0.4))
        end
        if overrides.ElementStrokeHover == nil then
            resolved.ElementStrokeHover = edgeShade(fill, 0.52)
        end
    end
    if overrides.TabBackground and overrides.TabStroke == nil then
        resolved.TabStroke = ColorSequence.new(edgeShade(firstColor(resolved.TabBackground), 0.4))
    end
end

local function themeOverrides(value)
    if typeof(value) == "table" then
        return value
    elseif typeof(value) == "string" then
        local named = themes:FindFirstChild(string.lower(value))
        if named then
            return require(named)
        end
        log.warn("Library: unknown theme '" .. value .. "', using default")
    elseif value ~= nil then
        log.warn("Library: invalid theme (expected a built-in name or a theme table), using default")
    end
    return require(themes["default"])
end

local function resolveTheme(value)
    local resolved = table.clone(require(themes["default"]))
    local overrides = themeOverrides(value)
    for key, override in overrides do
        resolved[key] = coerceThemeValue(key, override)
    end
    if typeof(value) == "table" then
        deriveStrokes(resolved, overrides)
    end

    local userTable = if typeof(value) == "table" then value else nil
    if not (userTable and (userTable.Font or userTable.font)) then
        resolved.Font = variables.brandFont(Enum.FontWeight.Medium)
    end
    if not (userTable and (userTable.TitleFont or userTable.titleFont)) then
        resolved.TitleFont = variables.brandFont(Enum.FontWeight.SemiBold)
    end

    return resolved
end

function Window.new(properties)
    properties = if typeof(properties) == "table" then properties else {}

    if properties.translations or properties.Translations then
        locale.register(properties.translations or properties.Translations)
    end
    if properties.translator or properties.Translator then
        locale.translator = properties.translator or properties.Translator
    end
    locale.setActive(properties.locale or properties.Locale or locale.detect())

    local fallbackFont = properties.fallbackFont or properties.FallbackFont
    if fallbackFont then
        variables.setFallbackFont(fallbackFont)
    end

    local layout = resolveLayout(properties.sidebarLayout or properties.SidebarLayout)

    local self = setmetatable({
        name = properties.name or properties.Name or "Library Window",
        subheading = properties.subtitle or properties.Subtitle,
        layout = layout,
        size = fitWindowSize(layout.mode),
        instances = {},
        connections = {},

        icon = properties.icon or properties.Icon,
        showName = properties.showName or properties.ShowName or "Library",
        showIcon = properties.showIcon or properties.ShowIcon or constants.icons.Library,
        showIconOnly = properties.showIconOnly or properties.ShowIconOnly or false,
        profileText = properties.profile or properties.Profile,

        themeProperties = {},
        localeProperties = {},
        tabs = {},
        tabSections = {},
        tags = {},
        selectedTab = nil,
        theme = resolveTheme(properties.theme or properties.Theme),

        controls = {},

        configuration = (function()
            local cfg = properties.configuration or properties.Configuration
            if not cfg then
                return {}
            end
            return {
                autoSave = cfg.autoSave or cfg.AutoSave,
                autoLoad = cfg.autoLoad or cfg.AutoLoad,
                fileName = cfg.fileName or cfg.FileName,
                customFolder = cfg.customFolder or cfg.CustomFolder,
            }
        end)(),
    }, Window)

    self.Flags = setmetatable({}, {
        __index = function(_, flag)
            local control = self.controls[flag]
            return control and control.value
        end,
        __newindex = function(_, flag, value)
            local control = self.controls[flag]
            if not control then
                log.warn("Library: no flag '" .. tostring(flag) .. "' to set")
                return
            end
            control:Set(value)
        end,
        __iter = function()
            local flag
            return function()
                local control
                flag, control = next(self.controls, flag)
                if flag then
                    return flag, control.value
                end
                return nil
            end
        end,
    })

    self.settings = {
        toggleKeybind = Enum.KeyCode.K,
        mouseOverride = true,
        keepOnScreen = true,
        welcomeToast = true,
        haptics = true,
        showProfile = true,
    }

    self.screenGui = self:Create("ScreenGui", {
        Name = variables.httpService:GenerateGUID(false),
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        Enabled = true,
        DisplayOrder = constants.displayOrder.window,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,

        Parent = variables.guiContainer,
    })

    self.main = self:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Name = self.name,
        ZIndex = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset((self.size.X.Offset - 50), 0),
        BackgroundTransparency = 1,
        Visible = false,

        Parent = self.screenGui,
    })

    self.drag = require(script.Parent.drag).new(self)

    self.windowCorner = self:Create("UICorner", {

        Parent = self.main,
    }, { CornerRadius = "CornerRoundness" })

    self.windowStroke = self:Create("UIStroke", {
        Transparency = 1,

        Parent = self.main,
    }, { Color = "SurfaceStroke" })

    self.windowGradient = self:Create("UIGradient", {
        Rotation = 270,
        Offset = Vector2.new(0, -0.1),

        Parent = self.main,
    }, { Color = { "WindowColor", functions.toColorSequence } })

    self.bottomFade = self:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = self.layout.fadeSize,
        ZIndex = constants.zIndex.bottomFade,

        BackgroundTransparency = 1,

        Parent = self.main,
    })

    self.bottomFadeCorner = self:_roundCorners(self.bottomFade, self.layout.fadeCorners)

    self.bottomFadeGradient = self:Create("UIGradient", {
        Rotation = 270,
        Offset = Vector2.new(0, 0.2),
        Transparency = self.layout.fadeTransparency,

        Parent = self.bottomFade,
    }, {
        Color = {
            "WindowColor",
            function(color)
                return ColorSequence.new(functions.toColorSequence(color).Keypoints[1].Value)
            end,
        },
    })

    self.topbar = self:Create("Frame", {

        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, self.layout.topbarHeight),
        Active = true,

        Parent = self.main,
    })

    self.topContainer = self:Create("Frame", {
        Size = UDim2.new(0, 300, 0, 24),
        Position = UDim2.new(0, 25, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,

        Parent = self.topbar,
    })

    self.topContainerLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.topContainer,
    })

    self.titleContainer = self:Create("Frame", {
        Size = UDim2.fromOffset(50, 24),
        Position = UDim2.new(0, 25, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        LayoutOrder = 1,

        Parent = self.topContainer,
    })

    self.titleContainerLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.titleContainer,
    })

    if self.name then
        self.title = self:Create("TextLabel", {
            Text = locale.t(self.name),

            FontFace = variables.brandFont(Enum.FontWeight.Medium),

            Size = UDim2.fromOffset(50, 20),
            AutomaticSize = Enum.AutomaticSize.X,

            BackgroundTransparency = 1,
            TextSize = 20,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,

            TextTransparency = 1,

            Parent = self.titleContainer,
        }, { FontFace = "Font", TextColor3 = "TitlingColor" })
    end

    if self.icon then
        self.topbarIcon = self:Create("ImageLabel", {
            Image = self.icon,

            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(32, 32),

            ImageTransparency = 1,

            Parent = self.topContainer,
        }, { ImageColor3 = "TitlingColor" })
    end

    if self.subheading then
        self.subtitle = self:Create("TextLabel", {
            Text = locale.t(self.subheading),

            Size = UDim2.fromOffset(50, 12),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,

            TextTransparency = 1,

            Parent = self.titleContainer,
        }, { TextColor3 = "TitlingColor", FontFace = "Font" })
    end

    self.tagContainer = self:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 25, 0.5, 0),
        Size = UDim2.fromOffset(50, 24),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Visible = false,

        Parent = self.topContainer,
    })

    self.tagContainerLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.tagContainer,
    })

    self.windowShadow = self:CreateGlow(self.main, "ShadowColor", 20, 1)


    self.elements = self:Create("Frame", {
        Size = UDim2.new(1, 0, 1, -self.layout.chromeHeight),
        Position = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ClipsDescendants = true,

        Parent = self.main,
    })

    if self.layout.mode == "sidebar" then
        self.elementsCorner = self:_roundCorners(self.elements, self.layout.cardCorners)

        self.elementsStroke = self:Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

            Transparency = 1,

            Parent = self.elements,
        }, { Color = "SurfaceStroke" })

        self:Create("UIGradient", {
            Rotation = self.layout.cardStrokeRotation,
            Transparency = self.layout.cardStrokeTransparency,

            Parent = self.elementsStroke,
        })
    end

    self.elementsLayout = self:Create("UIPageLayout", {
        Padding = UDim.new(0, 0),
        FillDirection = self.layout.pageDirection,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        ScrollWheelInputEnabled = false,
        GamepadInputEnabled = false,
        TouchInputEnabled = false,

        EasingStyle = Enum.EasingStyle.Exponential,
        TweenTime = 0.4,

        Parent = self.elements,
    })

    if self.layout.mode == "sidebar" then
        sidebar.build(self, self.layout)
        sidebar.applyWidth(self, layouts.railWidthFor(self.layout, self.size.X.Offset))
    else
        self.tabList = self:Create("ScrollingFrame", {
            Name = "Tabs",
            Active = true,
            Size = UDim2.new(1, 0, 0, self.layout.tabStripHeight),
            Position = UDim2.new(0.5, 0, 0, self.layout.tabStripTop),
            AnchorPoint = Vector2.new(0.5, 0),

            BackgroundTransparency = 1,
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            ScrollingDirection = Enum.ScrollingDirection.X,

            Parent = self.main,
        })

        self.tabListLayout = self:Create("UIListLayout", {
            Padding = UDim.new(0, 7),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            SortOrder = Enum.SortOrder.LayoutOrder,

            Parent = self.tabList,
        })

        self:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 22),
            PaddingRight = UDim.new(0, 10),

            Parent = self.tabList,
        })
    end

    self.actionContainer = self:Create("Frame", {

        AnchorPoint = Vector2.new(1, 0.5),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 24),
        Position = UDim2.new(1, -20, 0.5, 0),
        BackgroundTransparency = 1,

        Parent = self.topbar,
    })

    self.actionsListLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = self.actionContainer,
    })

    self.rfSettings = self:CreateTab({
        name = "Library Settings",
        customOrder = 1000,

        neglectSelector = true,
        forgetState = true,
    })

    require(script.Parent.action).new(self, {
        name = "Close",
        icon = constants.icons.close,
        order = 1,

        callback = function()
            self:ToggleHide()
        end,
    })

    self.minimiseAction = require(script.Parent.action).new(self, {
        name = "Minimise",
        icon = constants.icons.minimise,
        order = 2,

        callback = function()
            self:ToggleMinimise()
        end,
    })

    self.settingsAction = require(script.Parent.action).new(self, {
        name = "Settings",
        icon = constants.icons.settings,
        order = 3,
        linkedTab = self.rfSettings,

        callback = function()
            self.rfSettings:Select()
        end,
    })

    search.build(self)
    self:_applyRailWidth()

    self.unloaded = false
    self.minimised = false
    self.hidden = true
    self.animating = false
    self._revealing = false
    self.hasShownOnce = false
    self._collapsedShown = false

    self:LoadSettings()
    if self.layout.mode == "sidebar" then
        sidebar.reflowProfile(self)
        sidebar.setSubtitle(self, self.profileText)
    end
    hapticEngine.setContainer(self.screenGui)
    hapticEngine.setEnabled(self.settings.haptics)
    chrome.buildCollapsedFace(self)
    self:_bindKeybind()
    self:_bindMouseOverride()
    self:_bindTopbarDrag()
    self:_watchViewport()
    self:_buildSettingsUI()

    self:_syncLiveAnimation()

    return self
end

function Window:_syncLiveAnimation()
    if not self.theme.LiveAnimation then
        self._liveAnimating = false
        return
    end
    if self._liveAnimating then
        return
    end

    self._liveAnimating = true
    self._liveGeneration = (self._liveGeneration or 0) + 1
    local generation = self._liveGeneration
    task.spawn(function()
        local out = true
        local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        while self._liveGeneration == generation and self._liveAnimating and not self.unloaded do
            local tweenW = variables.tweenService:Create(self.windowGradient, tweenInfo, {
                Offset = Vector2.new(if out then 0.4 else -0.2, 0),
                Rotation = (if out then 220 else 280),
            })

            self._liveTween = tweenW
            tweenW:Play()
            tweenW.Completed:Wait()
            out = not out
        end
        if self._liveGeneration == generation then
            self._liveAnimating = false
            self._liveTween = nil
        end
    end)
end

function Window:ChangeTheme(theme)
    local overrides = if typeof(theme) == "table" then theme else resolveTheme(theme)
    for name, value in overrides do
        self.theme[name] = coerceThemeValue(name, value)
    end
    if typeof(theme) == "table" then
        deriveStrokes(self.theme, overrides)
    end

    for instance, properties in self.themeProperties do
        for property, value in properties do
            local targetValue = if typeof(value) == "table" then value[2](self.theme[value[1]]) else self.theme[value]

            if typeof(targetValue) == "Color3" or typeof(targetValue) == "number" then
                variables.tweenService
                    :Create(
                        instance,
                        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { [property] = targetValue }
                    )
                    :Play()
            else
                instance[property] = targetValue
            end
        end
    end

    if self.hidden then
        self._themeRefreshPending = true
    else
        self:_refreshElementThemes()
    end

    self:_syncLiveAnimation()
end

function Window:_refreshElementThemes()
    for _, tab in self.tabs do
        for _, element in tab.elements do
            if element._refreshTheme then
                element:_refreshTheme()
            end
        end
    end
end

function Window:CreateTab(properties)
    assert(not self.unloaded, "Cannot create a tab on an unloaded window.")
    local newTab = require(script.Parent.tab).new(self, properties)

    table.insert(self.tabs, newTab)

    if not newTab.neglectSelector then
        local isFirstVisible = true
        for _, tab in self.tabs do
            if tab ~= newTab and not tab.neglectSelector then
                isFirstVisible = false
                break
            end
        end
        if isFirstVisible then
            newTab:Select(true)
        end

        if not self.hidden and not self.minimised then
            newTab.topbarItem.Visible = true
            newTab:_applyVisual(
                if self.selectedTab == newTab then "selected" else "unselected",
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            )
        end
    end

    return newTab
end

function Window:CreateSection(properties)
    assert(not self.unloaded, "Cannot create a section on an unloaded window.")
    local section = require(script.Parent.tabSection).new(self, properties)
    table.insert(self.tabSections, section)

    if not section.inert and not self.hidden and not self.minimised then
        section:_setVisible(true)
        section:_setShown(true, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    end

    return section
end

function Window:_setTabSectionsShown(shown, tweenInfo)
    for _, section in self.tabSections do
        section:_setShown(shown, tweenInfo)
    end
end

function Window:_setTabSectionsVisible(visible)
    for _, section in self.tabSections do
        section:_setVisible(visible)
    end
end

function Window:CreateTag(properties)
    assert(not self.unloaded, "Cannot create a tag on an unloaded window.")
    local newTag = require(script.Parent.tag).new(self, properties)
    table.insert(self.tags, newTag)
    return newTag
end

function Window:_registerControl(control)
    if not control.flag or control.flag == "" or control.forgetState then
        return
    end

    local flag = control.flag
    if self.controls[flag] then
        local n = 2
        while self.controls[flag .. n] do
            n += 1
        end
        flag = flag .. n
        log.warn(
            "Library: duplicate config flag '"
                .. control.flag
                .. "', saving this one as '"
                .. flag
                .. "'. Set a unique flag to keep it stable across sessions."
        )
    end

    control.flag = flag
    self.controls[flag] = control
    return flag
end

function Window:_restoreLate(element)
    if not self._loadedConfig or not element.flag or element.forgetState then
        return
    end

    local wasLoading = self._loading
    self._loading = true
    persistence.applyTo(element, self._loadedConfig[element.flag])
    self._loading = wasLoading
end

function Window:_persist(control)
    if control.flag and not control.forgetState and self.configuration.autoSave and not self._loading then
        task.spawn(self.Save, self)
    end
end

function Window:_unregisterControl(control)
    if control.flag and self.controls[control.flag] == control then
        self.controls[control.flag] = nil
    end
end

function Window:_keybindUsing(key, exclude)
    if typeof(key) ~= "EnumItem" or key == Enum.KeyCode.Unknown then
        return nil
    end
    for _, tab in self.tabs do
        for _, element in tab.elements do
            if element ~= exclude and element.__type == "Keybind" and element.value == key then
                return element
            end
        end
    end
    return nil
end

function Window:Notify(properties)
    if self.unloaded then
        return
    end
    if not self.notifications then
        self.notifications = self:Create("Frame", {
            Name = "Notifications",
            Size = UDim2.new(0, 300, 0, 800),
            Position = UDim2.new(1, -20, 1, -20),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,

            Parent = self.screenGui,
        })

        self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),

            Parent = self.notifications,
        })
    end

    return require(script.Parent.notification).new(self, properties)
end

function Window:Toast(properties)
    if self.unloaded then
        return
    end

    properties = if typeof(properties) == "table" then properties else {}
    local position = properties.position or properties.Position or "Top"
    local isTop = typeof(position) ~= "string" or position:lower() ~= "bottom"
    properties.position = if isTop then "Top" else "Bottom"
    local containerKey = if isTop then "_toastsTop" else "_toastsBottom"
    local container = self[containerKey]

    if not container then
        container = self:Create("Frame", {
            Name = "Toasts",
            Size = UDim2.new(0, maxToastWidth, 1, -24),
            Position = if isTop then topToastOpenPosition else UDim2.new(0.5, 0, 1, -12),
            AnchorPoint = if isTop then Vector2.new(0.5, 0) else Vector2.new(0.5, 1),
            BackgroundTransparency = 1,
            ZIndex = constants.zIndex.toast,

            Parent = self.screenGui,
        })

        self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = if isTop then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),

            Parent = container,
        })

        self[containerKey] = container

        if isTop then
            setTopToastPosition(self, false)
        end
    end

    return require(script.Parent.toast).new(self, properties, container)
end

function Window:Popup(properties)
    if self.unloaded then
        return
    end
    return require(script.Parent.popup).new(self, properties)
end

function Window:Hide()
    if self.animating or self.hidden then
        return
    end

    if self._searching then
        search.close(self, { showTabs = false, jumpTo = self.selectedTab and self.selectedTab.tabPage })
    end

    if self._recordingKeybind then
        self._recordingKeybind:_stopRecording()
    end

    self.animating = true
    self._revealing = true
    self.hidden = true
    self.collapsedInteract.Visible = false

    if self.minimised then
        self.minimised = false
        image.assign(self.minimiseAction.iconLabel, "Image", constants.icons.minimise)
    end

    self._restorePosition = self.main.Position

    local home, size = self:_collapsedRect()

    local fadeInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local moveInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
    local cornerInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
    local faceInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    variables.tweenService
        :Create(self.drag.dragCosmetic, fadeInfo, { Size = UDim2.fromOffset(0, 4), BackgroundTransparency = 1 })
        :Play()
    task.delay(0.18, function()
        if not self.hidden then
            return
        end
        self.drag.drag.Visible = false
    end)

    self:_fadeSurfaces(false, fadeInfo)

    if self.title then
        variables.tweenService:Create(self.title, fadeInfo, { TextTransparency = 1 }):Play()
    end
    if self.subtitle then
        variables.tweenService:Create(self.subtitle, fadeInfo, { TextTransparency = 1 }):Play()
    end
    if self.topbarIcon then
        variables.tweenService:Create(self.topbarIcon, fadeInfo, { ImageTransparency = 1 }):Play()
    end

    for _, action in ipairs(self.actionContainer:GetChildren()) do
        if action:IsA("Frame") then
            variables.tweenService:Create(action.ImageLabel, fadeInfo, { ImageTransparency = 1 }):Play()
        end
    end

    for _, tag in self.tags do
        tag:_setShown(false, fadeInfo)
    end

    for _, tab in pairs(self.tabs) do
        if not tab.neglectSelector and tab.topbarItem then
            tab:_applyVisual("hidden", fadeInfo)
        end
    end
    self:_setTabSectionsShown(false, fadeInfo)

    self:_fadeSelectedElementsOut()

    local collapse = variables.tweenService:Create(self.main, moveInfo, { Size = size, Position = home })
    collapse.Completed:Connect(function()
        if self.unloaded or not self.hidden then
            return
        end

        self._collapsedShown = true
        setTopToastPosition(self, true)
        self.collapsedInteract.Visible = true
        self.animating = false
        self._revealing = false
    end)
    collapse:Play()
    variables.tweenService:Create(self.windowCorner, cornerInfo, { CornerRadius = UDim.new(1, 0) }):Play()

    task.delay(0.18, function()
        if not self.hidden then
            return
        end
        self.topbar.Visible = false
        self:_setContentVisible(false)

        chrome.setCollapsedShown(self, true, faceInfo)
    end)
end

function Window:ToggleHide()
    if self.animating then
        return
    end
    if self.hidden then
        self:Show()
    else
        self:Hide()
    end
end

function Window:ToggleMinimise()
    if self.animating or self.hidden then
        return
    end

    if self._searching then
        search.close(self, { showTabs = true })
    end

    self.animating = true

    local sizeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

    if self.minimised then
        self.minimised = false
        image.assign(self.minimiseAction.iconLabel, "Image", constants.icons.minimise)

        variables.tweenService:Create(self.main, sizeInfo, { Size = self.size }):Play()
        self:_fadeSurfaces(true, fadeInfo)

        variables.tweenService
            :Create(self.drag.drag, sizeInfo, {
                Position = UDim2.new(
                    self.main.Position.X.Scale,
                    self.main.Position.X.Offset,
                    self.main.Position.Y.Scale,
                    self.main.Position.Y.Offset + self.size.Y.Offset / 2 + 15
                ),
            })
            :Play()

        task.delay(0.2, function()
            if self.minimised or self.hidden then
                return
            end
            self:_setContentVisible(true)

            for _, tab in pairs(self.tabs) do
                if not tab.neglectSelector and tab.topbarItem then
                    tab.topbarItem.Visible = true
                    tab:_applyVisual(if self.selectedTab == tab then "selected" else "unselected", fadeInfo)
                end
            end
            self:_setTabSectionsVisible(true)
            self:_setTabSectionsShown(true, fadeInfo)

            self:_revealElements(0.035, 0.4)
        end)

        task.delay(0.5, function()
            self.animating = false
        end)
    else
        self.minimised = true
        image.assign(self.minimiseAction.iconLabel, "Image", constants.icons.maximise)

        self:_fadeSelectedElementsOut()
        for _, tab in pairs(self.tabs) do
            if not tab.neglectSelector and tab.topbarItem then
                tab:_applyVisual("hidden", fadeInfo)
            end
        end
        self:_setTabSectionsShown(false, fadeInfo)

        task.delay(0.3, function()
            if not self.minimised then
                return
            end
            self:_setContentVisible(false)
            for _, tab in pairs(self.tabs) do
                if not tab.neglectSelector and tab.topbarItem then
                    tab.topbarItem.Visible = false
                end
            end
            self:_setTabSectionsVisible(false)
        end)

        self:_fadeSurfaces(false, fadeInfo)
        variables.tweenService
            :Create(self.main, sizeInfo, { Size = UDim2.fromOffset(self.size.X.Offset, self.layout.topbarHeight) })
            :Play()

        variables.tweenService
            :Create(self.drag.drag, sizeInfo, {
                Position = UDim2.new(
                    self.main.Position.X.Scale,
                    self.main.Position.X.Offset,
                    self.main.Position.Y.Scale,
                    self.main.Position.Y.Offset + self.layout.topbarHeight / 2 + 15
                ),
            })
            :Play()

        task.delay(0.5, function()
            self.animating = false
        end)
    end
end

function Window:_syncDragBar()
    local bar = self.drag and self.drag.drag
    if not bar then
        return
    end
    local position = self.main.Position
    local below = self.size.Y.Offset / 2 + 15
    bar.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + below)
end

function Window:_clampedPosition(position: UDim2): UDim2
    if not self.settings or not self.settings.keepOnScreen then
        return position
    end
    if position.X.Scale ~= 0 or position.Y.Scale ~= 0 then
        return position
    end

    local screen = self.screenGui.AbsoluteSize
    local halfX, halfY = self.size.X.Offset / 2, self.size.Y.Offset / 2
    local margin = 8
    local x = math.clamp(position.X.Offset, halfX + margin, math.max(halfX + margin, screen.X - halfX - margin))
    local y = math.clamp(position.Y.Offset, halfY + margin, math.max(halfY + margin, screen.Y - halfY - margin))
    if x == position.X.Offset and y == position.Y.Offset then
        return position
    end
    return UDim2.fromOffset(x, y)
end

function Window:_clampToScreen()
    self.main.Position = self:_clampedPosition(self.main.Position)
end

function Window:_applyWindowSize()
    if self.unloaded then
        return
    end

    local size = fitWindowSize(self.layout.mode)
    local changed = size ~= self.size
    self.size = size

    self:_applyRailWidth()

    if self.hidden or self.minimised or self.animating or self._revealing then
        self._pendingResize = self._pendingResize or changed
        return
    end

    if not changed and not self._pendingResize then
        return
    end
    self._pendingResize = false

    self.main.Size = size
    self:_clampToScreen()
    self:_syncDragBar()
end

function Window:_applyRailWidth()
    if self.layout.mode ~= "sidebar" then
        return
    end
    sidebar.applyWidth(self, layouts.railWidthFor(self.layout, self.size.X.Offset))
end

function Window:_watchViewport()
    local cameraConnection: RBXScriptConnection? = nil
    local pending = false

    local function request()
        if pending then
            return
        end
        pending = true
        task.defer(function()
            pending = false
            self:_applyWindowSize()
        end)
    end

    local function bind()
        if cameraConnection then
            self:Disconnect(cameraConnection)
            cameraConnection = nil
        end
        local camera = variables.workspace.CurrentCamera
        if camera then
            cameraConnection = self:Connect(camera:GetPropertyChangedSignal("ViewportSize"), request)
        end
        request()
    end

    self:Connect(variables.workspace:GetPropertyChangedSignal("CurrentCamera"), bind)
    bind()

    local sinceReconcile = 0
    self:Connect(variables.runService.Heartbeat, function(delta: number)
        sinceReconcile += delta
        if sinceReconcile < viewportReconcileInterval then
            return
        end
        sinceReconcile = 0
        self:_applyWindowSize()
    end)
end

function Window:_bindKeybind()
    self:Connect(variables.userInputService.InputBegan, function(input, processed)
        if processed or self._recordingKeybind then
            return
        end
        if input.KeyCode == self.settings.toggleKeybind or input.UserInputType == self.settings.toggleKeybind then
            self:ToggleHide()
        end
    end)
end

function Window:_bindMouseOverride()
    local uis = variables.userInputService

    local function active()
        return self.settings.mouseOverride and not self.hidden and not self.minimised
    end

    local function free()
        if not active() then
            return
        end
        if uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            return
        end
        if uis.MouseBehavior ~= Enum.MouseBehavior.Default then
            uis.MouseBehavior = Enum.MouseBehavior.Default
        end
        if not uis.MouseIconEnabled then
            uis.MouseIconEnabled = true
        end
    end

    self:Connect(uis:GetPropertyChangedSignal("MouseBehavior"), free)
    self:Connect(uis:GetPropertyChangedSignal("MouseIconEnabled"), free)

    self:Connect(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            free()
        end
    end)

    self._freeMouse = free
end

function Window:_bindTopbarDrag()
    local uis = variables.userInputService
    local dragging = false
    local relative = Vector2.zero

    local offset = Vector2.zero
    if self.screenGui and self.screenGui.IgnoreGuiInset then
        offset = variables.guiService:GetGuiInset()
    end

    local function getTarget()
        local position = uis:GetMouseLocation() + relative + offset
        local x, y = position.X, position.Y

        if self.settings and self.settings.keepOnScreen then
            local size = self.main.AbsoluteSize
            local screen = self.screenGui.AbsoluteSize
            local margin = 8
            local halfX, halfY = size.X / 2, size.Y / 2
            x = math.clamp(x, halfX + margin, math.max(halfX + margin, screen.X - halfX - margin))
            y = math.clamp(y, halfY + margin, math.max(halfY + margin, screen.Y - halfY - margin))
        end

        return UDim2.fromOffset(x, y)
    end

    local function overInteractiveChild(x, y)
        for _, region in { self.tabList, self.actionContainer } do
            local position, size = region.AbsolutePosition, region.AbsoluteSize
            if x >= position.X and x <= position.X + size.X and y >= position.Y and y <= position.Y + size.Y then
                return true
            end
        end
        return false
    end

    self:Connect(self.topbar.InputBegan, function(input, processed)
        if processed then
            return
        end

        local inputType = input.UserInputType.Name
        if inputType ~= "MouseButton1" and inputType ~= "Touch" then
            return
        end

        if overInteractiveChild(input.Position.X, input.Position.Y) then
            return
        end

        if not self:_interactive() then
            return
        end

        dragging = true

        if self.screenGui and self.screenGui.IgnoreGuiInset then
            offset = variables.guiService:GetGuiInset()
        end

        relative = self.main.AbsolutePosition + self.main.AbsoluteSize * self.main.AnchorPoint - uis:GetMouseLocation()
    end)

    self:Connect(uis.InputEnded, function(input)
        local inputType = input.UserInputType.Name
        if inputType == "MouseButton1" or inputType == "Touch" then
            dragging = false
        end
    end)

    self:Connect(uis.WindowFocusReleased, function()
        dragging = false
    end)

    self:Connect(variables.runService.RenderStepped, function()
        if not dragging then
            return
        end

        if not self:_interactive() then
            dragging = false
            return
        end

        self.main.Position = getTarget()

        if self.drag and self.drag.drag then
            local mainPosition = self.main.Position
            self.drag.drag.Position = UDim2.new(
                mainPosition.X.Scale,
                mainPosition.X.Offset,
                mainPosition.Y.Scale,
                mainPosition.Y.Offset + (self.main.Size.Y.Offset / 2 + 15)
            )
        end
    end)
end

function Window:_buildSettingsUI()
    self.rfSettings:CreateSection({ name = "General" })

    self.rfSettings:CreateKeybind({
        name = "Toggle Keybind",
        icon = constants.icons.search,
        value = self.settings.toggleKeybind,
        isMenuToggle = true,
        onChanged = function(key)
            self.settings.toggleKeybind = key
            self:SaveSettings()
        end,
    })

    self.rfSettings:CreateToggle({
        name = "Unlock cursor while open",
        description = "Unlocks the cursor while the menu is open so you can configure in FPS games that lock it.",
        value = self.settings.mouseOverride,
        callback = function(state)
            self.settings.mouseOverride = state
            self:SaveSettings()
        end,
    })

    self.rfSettings:CreateToggle({
        name = "Welcome toast",
        description = "Shows a 'Signed in as' toast the first time you open the menu on a new account.",
        value = self.settings.welcomeToast,
        callback = function(state)
            self.settings.welcomeToast = state
            self:SaveSettings()
        end,
    })

    self.rfSettings:CreateToggle({
        name = "Haptics",
        description = "A subtle tap as you interact, on devices that support haptics.",
        value = self.settings.haptics,
        callback = function(state)
            self.settings.haptics = state
            hapticEngine.setEnabled(state)
            self:SaveSettings()
        end,
    })

    self.rfSettings:CreateSection({ name = "Window" })

    if self.layout.mode == "sidebar" and self.profile then
        self.rfSettings:CreateToggle({
            name = "Show profile",
            description = "Shows your avatar and name at the base of the sidebar. Turn it off to keep "
                .. "them out of a stream or a screenshot.",
            value = self.settings.showProfile,
            callback = function(state)
                sidebar.setProfileEnabled(self, state)
                self:SaveSettings()
            end,
        })
    end

    self.rfSettings:CreateToggle({
        name = "Keep window on screen",
        description = "Stops the window being dragged off the edge of the screen and lost.",
        value = self.settings.keepOnScreen,
        callback = function(state)
            self.settings.keepOnScreen = state
            self:SaveSettings()
        end,
    })

    self.rfSettings:CreateButton({
        name = "Reset Window Position",
        callback = function()
            variables.tweenService
                :Create(self.main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                })
                :Play()
            variables.tweenService
                :Create(self.drag.drag, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, 0, 0.5, self.size.Y.Offset / 2 + 15),
                })
                :Play()
        end,
    })

    if next(self.configuration) ~= nil then
        self.rfSettings:CreateSection({ name = "Configurations" })

        local selected = self:ListConfigs()[1]
        local configDropdown, nameInput

        local function refreshConfigs()
            local names = self:ListConfigs()
            configDropdown:Refresh(names)
            if selected and not table.find(names, selected) then
                selected = names[1]
            end
            if selected then
                configDropdown:Set(selected, true)
            end
        end

        configDropdown = self.rfSettings:CreateDropdown({
            name = "Saved Configurations",
            icon = constants.icons.config,
            options = self:ListConfigs(),
            value = selected,
            placeholder = "No saved configurations",
            callback = function(value)
                selected = value
            end,
        })

        nameInput = self.rfSettings:CreateInput({
            name = "Configuration Name",
            description = "Name a new configuration, or leave blank to overwrite the selected one.",
            placeholder = "e.g. PvP Loadout",
            clearOnFocus = false,
        })

        local actions = self.rfSettings:CreateGroup()

        actions:CreateButton({
            name = "Save",
            icon = constants.icons.config,
            callback = function()
                local name = nameInput.value
                if name == "" then
                    name = selected
                end
                if not name or name == "" then
                    self:Toast({ title = locale.resolve("Name your configuration first") })
                    return
                end
                if self:Save(name) then
                    nameInput:Set("")
                    selected = name
                    refreshConfigs()
                    self:Toast({
                        title = locale.resolve("Saved configuration"),
                        subtitle = name,
                        icon = constants.icons.config,
                    })
                else
                    self:Toast({ title = locale.resolve("Couldn't save configuration"), subtitle = name })
                end
            end,
        })

        actions:CreateButton({
            name = "Load",
            callback = function()
                if not selected or selected == "" then
                    self:Toast({ title = locale.resolve("Pick a configuration to load") })
                    return
                end
                if self:_applyNamedConfig(selected) then
                    self:Toast({ title = locale.resolve("Loaded configuration"), subtitle = selected })
                else
                    self:Toast({ title = locale.resolve("Couldn't load configuration"), subtitle = selected })
                end
            end,
        })

        actions:CreateButton({
            name = "Delete",
            callback = function()
                local deleting = selected
                if not deleting or deleting == "" then
                    self:Toast({ title = locale.resolve("Pick a configuration to delete") })
                    return
                end
                if self:DeleteConfig(deleting) then
                    refreshConfigs()
                    self:Toast({ title = locale.resolve("Deleted configuration"), subtitle = deleting })
                else
                    self:Toast({ title = locale.resolve("Couldn't delete configuration"), subtitle = deleting })
                end
            end,
        })
    end
end

function Window:SetProfile(text)
    self.profileText = text
    sidebar.setSubtitle(self, text)
end

function Window:SaveSettings()
    return persistence.saveSettings(self)
end

function Window:LoadSettings()
    return persistence.loadSettings(self)
end

function Window:_roundCorners(parent, corners)
    if not corners or not perCornerSupported then
        return self:Create("UICorner", {
            Parent = parent,
        }, { CornerRadius = "CornerRoundness" })
    end

    local properties = { Parent = parent }
    local themed = {}
    for _, name in cornerNames do
        properties[name] = UDim.new(0, 0)
    end
    for _, name in corners do
        properties[name] = nil
        themed[name] = "CornerRoundness"
    end

    return self:Create("UICorner", properties, themed)
end

function Window:_setElementLocked(element, locked, reason)
    locked = locked == true
    local wasLocked = element.locked == true
    if wasLocked == locked and not (locked and reason) then
        return
    end
    element.locked = locked

    if not element.lockScrim then
        self:_buildLockScrim(element)
    end

    local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    if locked then
        element.lockScrim.Visible = true
    end
    variables.tweenService
        :Create(element.lockScrim, info, {
            BackgroundTransparency = if locked then lockScrimTransparency else 1,
        })
        :Play()
    if not locked then
        task.delay(info.Time, function()
            if not element.locked and element.lockScrim then
                element.lockScrim.Visible = false
            end
        end)
    end

    local descriptor = element.descriptor
    if not descriptor then
        return
    end

    if locked then
        element._descriptionBefore = element._descriptionBefore or descriptor.titleLabel.Text
        descriptor.titleLabel.Text = locale.resolve(reason or "This element is locked.")
    elseif element._descriptionBefore then
        descriptor.titleLabel.Text = element._descriptionBefore
        element._descriptionBefore = nil
    end

    variables.tweenService
        :Create(descriptor.titleLabel, info, {
            TextTransparency = if locked then lockedDescriptionTransparency else 0.7,
        })
        :Play()
end

function Window:_buildLockScrim(element)
    element.lockScrim = self:Create("TextButton", {
        Name = "ElementLock",
        Active = true,
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Text = "",
        TextTransparency = 1,
        ZIndex = constants.zIndex.elementLock,
        Visible = false,

        BackgroundTransparency = 1,

        Parent = element.main,
    }, { BackgroundColor3 = { "WindowColor", firstColor } })

    self:Create("UICorner", {
        Parent = element.lockScrim,
    }, { CornerRadius = "ElementCornerRadius" })
end

function Window:_setContentVisible(visible)
    self.elements.Visible = visible
    self.tabList.Visible = visible
    if self.sidebar then
        self.sidebar.Visible = visible
    end
end

function Window:_fadeSurfaces(shown, fadeInfo)
    local targets = {
        [self.windowShadow] = { Transparency = if shown then 0.6 else 1 },
        [self.windowStroke] = { Transparency = if shown then 0.95 else 1 },
        [self.bottomFade] = { BackgroundTransparency = if shown then 0 else 1 },
    }

    if self.elementsStroke then
        targets[self.elements] = {
            BackgroundTransparency = if shown then self.layout.cardTransparency else 1,
        }
        targets[self.elementsStroke] = { Transparency = if shown then 0 else 1 }
    end

    for instance, properties in targets do
        if fadeInfo then
            variables.tweenService:Create(instance, fadeInfo, properties):Play()
        else
            for property, value in properties do
                instance[property] = value
            end
        end
    end

    sidebar.setProfileShown(self, shown, fadeInfo)
end

function Window:_fadeSelectedElementsOut()
    if self.selectedTab then
        for _, element in ipairs(self.selectedTab.elements) do
            element:_setShown(false, true)
        end
    end
end

function Window:_revealElements(perElementDelay, budget)
    for _, tab in pairs(self.tabs) do
        if tab ~= self.selectedTab then
            for _, element in ipairs(tab.elements) do
                element:_setShown(true, false)
            end
        end
    end

    local tab = self.selectedTab
    if not tab then
        return
    end

    local page = tab.tabPage
    local viewTop = page.AbsolutePosition.Y
    local viewBottom = viewTop + page.AbsoluteWindowSize.Y

    local maxStaggered = math.floor(budget / perElementDelay)
    local staggered = 0
    for _, element in ipairs(tab.elements) do
        local top = element.main.AbsolutePosition.Y
        local onScreen = (top + element.main.AbsoluteSize.Y) > viewTop and top < viewBottom
        if onScreen then
            element:_setShown(true, true)
            staggered += 1
            if staggered <= maxStaggered then
                task.wait(perElementDelay)
            end
        else
            element:_setShown(true, false)
        end
    end
end

function Window:Show()
    if self.animating or not self.hidden then
        return
    end
    self.animating = true
    self._revealing = true

    if self.configuration.autoLoad and not self._autoLoaded then
        self._autoLoaded = true
        local ok, err = pcall(self.Load, self)
        if not ok then
            log.warn("Library: Failed to load configuration - " .. tostring(err))
        end
    end

    self.hidden = false
    self.minimised = false

    if self._themeRefreshPending then
        self._themeRefreshPending = false
        self:_refreshElementThemes()
    end

    self.collapsedInteract.Visible = false

    if self._freeMouse then
        self._freeMouse()
    end

    if self.hasShownOnce then
        self:_quickRestore()
    else
        self.hasShownOnce = true
        self:_firstShow()
    end
end

function Window:_quickRestore()
    local target = self:_clampedPosition(self._restorePosition or UDim2.new(0.5, 0, 0.5, 0))
    self._restorePosition = target

    local growInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
    local cornerInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
    local fadeInfo = TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

    chrome.setCollapsedShown(self, false, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    local restore = variables.tweenService:Create(self.main, growInfo, { Size = self.size, Position = target })
    restore.Completed:Connect(function()
        if self.hidden or self.unloaded then
            return
        end

        self._collapsedShown = false
        setTopToastPosition(self, true)
    end)
    restore:Play()
    variables.tweenService:Create(self.windowCorner, cornerInfo, { CornerRadius = self.theme.CornerRoundness }):Play()

    task.delay(0.22, function()
        self.topbar.Visible = true
        self:_setContentVisible(true)

        self:_fadeSurfaces(true, fadeInfo)

        if self.topbarIcon then
            variables.tweenService:Create(self.topbarIcon, fadeInfo, { ImageTransparency = 0 }):Play()
        end
        if self.title then
            variables.tweenService:Create(self.title, fadeInfo, { TextTransparency = 0 }):Play()
        end
        if self.subtitle then
            variables.tweenService:Create(self.subtitle, fadeInfo, { TextTransparency = 0.7 }):Play()
        end

        for _, action in ipairs(self.actionContainer:GetChildren()) do
            if action:IsA("Frame") then
                variables.tweenService:Create(action.ImageLabel, fadeInfo, { ImageTransparency = 0.6 }):Play()
            end
        end

        if self.settingsAction and self.selectedTab == self.rfSettings then
            variables.tweenService:Create(self.settingsAction.iconLabel, fadeInfo, { ImageTransparency = 0.2 }):Play()
        end

        for _, tag in self.tags do
            tag:_setShown(true, fadeInfo)
        end

        for _, tab in pairs(self.tabs) do
            if not tab.neglectSelector and tab.topbarItem then
                tab.topbarItem.Visible = true
                tab:_applyVisual(if self.selectedTab == tab then "selected" else "unselected", fadeInfo)
            end
        end
        self:_setTabSectionsVisible(true)
        self:_setTabSectionsShown(true, fadeInfo)

        self:_revealElements(0.035, 0.4)
    end)

    task.delay(0.22, function()
        self.drag.drag.Position =
            UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale, target.Y.Offset + self.size.Y.Offset / 2 + 15)
        self.drag.dragCosmetic.Size = UDim2.fromOffset(0, 4)
        self.drag.dragCosmetic.BackgroundTransparency = 1
        self.drag.drag.Visible = true
        variables.tweenService
            :Create(self.drag.dragCosmetic, growInfo, { Size = UDim2.fromOffset(100, 4), BackgroundTransparency = 0.7 })
            :Play()
    end)

    task.delay(0.6, function()
        self.animating = false
        self._revealing = false
    end)
end

function Window:_firstShow()
    self:_setContentVisible(true)

    self.drag.drag.Visible = false
    self.main.Visible = true
    variables.tweenService
        :Create(
            self.main,
            TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
            { BackgroundTransparency = 0, Size = self.size }
        )
        :Play()
    task.wait(0.85)
    self:_fadeSurfaces(true, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
    task.wait(0.3)

    if self.icon then
        variables.tweenService
            :Create(
                self.topbarIcon,
                TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                { ImageTransparency = 0 }
            )
            :Play()
    end
    if self.title then
        variables.tweenService
            :Create(
                self.title,
                TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                { TextTransparency = 0 }
            )
            :Play()
    end
    task.wait(0.1)
    if self.subtitle then
        variables.tweenService
            :Create(
                self.subtitle,
                TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                { TextTransparency = 0.7 }
            )
            :Play()
    end

    for _, action in ipairs(self.actionContainer:GetChildren()) do
        if action:IsA("Frame") then
            task.wait(0.02)
            variables.tweenService
                :Create(
                    action.ImageLabel,
                    TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                    { ImageTransparency = 0.6 }
                )
                :Play()
        end
    end

    for _, tag in self.tags do
        tag:_setShown(true, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
    end

    task.wait(0.2)

    task.spawn(function()
        local info = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        self:_setTabSectionsVisible(true)
        self:_setTabSectionsShown(true, info)

        local staggered = 0
        for _, tab in pairs(self.tabs) do
            if not tab.neglectSelector then
                tab.topbarItem.Visible = true
                tab:_applyVisual(if self.selectedTab == tab then "selected" else "unselected", info)
                tab:_spinGradients()

                staggered += 1
                if staggered <= maxStaggeredTabs then
                    task.wait(tabStagger)
                end
            end
        end
    end)

    self:_revealElements(0.03, 2)

    task.wait(1)

    self:_syncDragBar()
    self.drag.drag.Visible = true
    variables.tweenService
        :Create(
            self.drag.dragCosmetic,
            TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { BackgroundTransparency = 0.7 }
        )
        :Play()
    variables.tweenService
        :Create(
            self.drag.dragCosmetic,
            TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { Size = UDim2.fromOffset(100, 4) }
        )
        :Play()

    self.animating = false
    self._revealing = false

    local localPlayer = variables.localPlayer
    if localPlayer and self.settings.welcomeToast and chrome.isNewUser() then
        self:Toast({
            title = localPlayer.DisplayName,
            subtitle = locale.resolve("Signed in as"),
            subtitleAbove = true,
            avatar = localPlayer.UserId,
            minWidth = 220,
        })
    end
end

function Window:GetPath()
    return persistence.getPath(self)
end

function Window:Save(name)
    if name ~= nil and (type(name) ~= "string" or name == "") then
        return false
    end
    return persistence.save(self, name)
end

function Window:Load(name)
    if name ~= nil and (type(name) ~= "string" or name == "") then
        return false
    end
    return persistence.load(self, name)
end

function Window:_applyNamedConfig(name)
    if not self:Load(name) then
        return false
    end
    local _, defaultPath = persistence.getPath(self)
    self._loadedConfigPath = defaultPath
    self:Save()
    return true
end

function Window:ListConfigs()
    return persistence.list(self)
end

function Window:DeleteConfig(name)
    return persistence.delete(self, name)
end

function Window:Get(flag)
    local control = self.controls[flag]
    return control and control.value
end

function Window:Set(flag, value)
    local control = self.controls[flag]
    if not control then
        return false
    end
    control:Set(value)
    return true
end

function Window:_jumpTo(page)
    if page then
        self.elementsLayout:JumpTo(page)
    end
end

function Window:Navigate(tab)
    if tab == nil then
        return
    end

    local target
    for _, candidate in self.tabs do
        if candidate == tab or candidate.name == tab or candidate.tabPage == tab then
            target = candidate
            break
        end
    end

    if not target then
        return
    end
    target:Select()
end

function Window:Create(className, properties, themeProperties)
    assert(typeof(className) == "string", "Invalid argument #1 (string expected)")
    local instance = Instance.new(className)

    if themeProperties and self.theme then
        for property, value in themeProperties do
            instance[property] = (
                if typeof(value) == "table" then value[2](self.theme[value[1]]) else self.theme[value]
            )
        end

        self.themeProperties[instance] = themeProperties
    end

    if properties then
        for property, value in properties do
            if locale.isToken(value) then
                self:_bindLocale(instance, property, locale.sourceOf(value))
            else
                image.assign(instance, property, value)
            end
        end
    end

    table.insert(self.instances, instance)
    return instance
end

function Window:_bindLocale(instance, property, source)
    instance[property] = locale.resolve(source)

    local entries = self.localeProperties[instance]
    if not entries then
        entries = {}
        self.localeProperties[instance] = entries
    end
    entries[property] = source
end

function Window:SetLocale(localeId)
    locale.setActive(localeId)
    for instance, entries in self.localeProperties do
        for property, source in entries do
            instance[property] = locale.resolve(source)
        end
    end
end

function Window:SetTranslator(translator)
    locale.translator = translator
end

function Window:RegisterTranslations(tables)
    locale.register(tables)
    self:SetLocale(locale.current)
end

function Window:CreateGlow(parent, color, blur, transparency)
    local properties = {
        BlurRadius = UDim.new(0, blur),
        Transparency = transparency,
        ZIndex = -1,

        Parent = parent,
    }

    if typeof(color) == "string" then
        return self:Create("UIShadow", properties, {
            Color = {
                color,
                function(value)
                    return if typeof(value) == "ColorSequence" then value.Keypoints[1].Value else value
                end,
            },
        })
    end

    properties.Color = color
    return self:Create("UIShadow", properties)
end

function Window:_flashResult(element, ok)
    local box = element.box
    if not box then
        return
    end
    local glow = element.glow
    local stroke = element.boxStroke
    local fill = ok and constants.accent.on or self.theme.ErrorColor
    local edge = ok and constants.accent.onStroke or self.theme.ErrorStrokeColor
    local inInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local outInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    variables.tweenService:Create(box, inInfo, { BackgroundColor3 = fill }):Play()
    if stroke then
        variables.tweenService:Create(stroke, inInfo, { Color = edge, Transparency = 0.4 }):Play()
    end
    if glow then
        variables.tweenService:Create(glow, inInfo, { Color = edge, Transparency = 0.6 }):Play()
    end

    element._flashToken = (element._flashToken or 0) + 1
    local token = element._flashToken
    task.delay(0.22, function()
        if element._flashToken ~= token then
            return
        end
        variables.tweenService:Create(box, outInfo, { BackgroundColor3 = self.theme.FieldBackground }):Play()
        if stroke then
            variables.tweenService
                :Create(stroke, outInfo, { Color = self.theme.SurfaceStroke, Transparency = 0.85 })
                :Play()
        end
        if glow then
            variables.tweenService
                :Create(glow, outInfo, { Color = self.theme.FieldGlow, Transparency = element._glowIdle or 1 })
                :Play()
        end
    end)
end

function Window:CreateHoverOverlay(parent)
    local overlay = self:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        ZIndex = 1,

        Parent = parent,
    })

    self:Create("UICorner", {
        Parent = overlay,
    }, { CornerRadius = "ElementCornerRadius" })

    return overlay
end

function Window:_wireElementHover(element)
    local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local theme = self.theme

    self:ConnectFor(element, element.main.MouseEnter, function()
        if not self:_interactive() then
            return
        end
        variables.tweenService
            :Create(
                element.stroke,
                info,
                { Transparency = theme.ElementStrokeHoverTransparency, Color = theme.ElementStrokeHover }
            )
            :Play()
        variables.tweenService:Create(element.title, info, { TextColor3 = theme.ElementTextHoverColor }):Play()
        if element.hoverOverlay then
            variables.tweenService:Create(element.hoverOverlay, info, { BackgroundTransparency = 0.97 }):Play()
        end
    end)

    self:ConnectFor(element, element.main.MouseLeave, function()
        variables.tweenService
            :Create(
                element.stroke,
                info,
                { Transparency = theme.ElementStrokeTransparency, Color = theme.ElementStroke }
            )
            :Play()
        variables.tweenService:Create(element.title, info, { TextColor3 = theme.ContentColor }):Play()
        if element.hoverOverlay then
            variables.tweenService:Create(element.hoverOverlay, info, { BackgroundTransparency = 1 }):Play()
        end
    end)
end

function Window:_runGuarded(element, fn, ...)
    if element.locked then
        return
    end

    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            return fn(table.unpack(args, 1, args.n))
        end)
        if ok or element._errored then
            return
        end
        element._errored = true

        local flashFrame = element.flashTarget or element.main
        local quickOut = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        variables.tweenService:Create(flashFrame, quickOut, { BackgroundColor3 = self.theme.ErrorColor }):Play()
        variables.tweenService:Create(element.stroke, quickOut, { Color = self.theme.ErrorStrokeColor }):Play()
        if element.title then
            element.title.Text = locale.resolve("Error, log recorded in console.")
        end

        log.warn(
            `Library encountered an error, with the callback for a {element.__type} component named '{element.name}':`
        )
        log.print(err)

        task.wait(1)

        if element.title then
            element.title.Text = locale.resolve(element.name)
        end
        variables.tweenService
            :Create(
                flashFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }
            )
            :Play()
        variables.tweenService
            :Create(
                element.stroke,
                TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { Color = self.theme.ElementStroke }
            )
            :Play()
        element._errored = false
    end)
end

function Window:StyleElementBody(main)
    self:Create("UIGradient", {
        Rotation = 270,

        Parent = main,
    }, { Color = "ElementGradient" })

    self:Create("UICorner", {
        Parent = main,
    }, { CornerRadius = "ElementCornerRadius" })

    return self:Create("UIStroke", {
        Transparency = 1,

        Parent = main,
    }, { Color = "ElementStroke", Transparency = "ElementStrokeTransparency" })
end

function Window:_buildCompactRow(host, name, interactZIndex)
    local main = self:Create("Frame", {
        Name = name,
        Size = UDim2.fromOffset(0, compactRowHeight),
        AutomaticSize = Enum.AutomaticSize.X,
        ClipsDescendants = true,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,

        BackgroundTransparency = 1,

        Parent = host.tabPage,
    }, { BackgroundTransparency = "ElementTransparency" })

    local stroke = self:StyleElementBody(main)

    self:Create("UIFlexItem", {
        FlexMode = Enum.UIFlexMode.Fill,
        Parent = main,
    })

    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,

        Parent = main,
    })

    local interact = self:Create("TextButton", {
        Text = "",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, compactRowHeight),
        BorderSizePixel = 0,
        TextTransparency = 1,
        ZIndex = interactZIndex or 1,

        Parent = main,
    })

    self:Create("UICorner", {
        Parent = interact,
    }, { CornerRadius = "ElementCornerRadius" })

    return main, stroke, interact
end

function Window:StyleElementPanel(frame)
    self:Create("UIGradient", {
        Rotation = 270,

        Parent = frame,
    }, { Color = "ElementGradient" })

    self:Create("UICorner", {
        Parent = frame,
    }, { CornerRadius = "ElementCornerRadius" })

    local stroke = self:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,

        Parent = frame,
    })

    self:Create("UIGradient", {
        Rotation = 270,

        Parent = stroke,
    }, { Color = "ElementStrokeGradient" })

    return stroke
end

function Window:_reveal(instance, props, animate, info)
    if not instance then
        return
    end
    if animate then
        variables.tweenService:Create(instance, info or revealInfo, props):Play()
    else
        for property, value in props do
            instance[property] = value
        end
    end
end

function Window:_revealCommon(element, animate)
    self:_reveal(element.stroke, { Transparency = self.theme.ElementStrokeTransparency }, animate)
    self:_reveal(element.title, { TextTransparency = 0 }, animate)
    self:_reveal(element.main, { BackgroundTransparency = self.theme.ElementTransparency or 0 }, animate)
    if element.iconLabel then
        self:_reveal(element.iconLabel, { ImageTransparency = 0 }, animate)
    end
    if element.descriptor then
        self:_reveal(element.descriptor.titleLabel, { TextTransparency = 0.7 }, animate)
    end
end

function Window:_hideCommon(element, animate)
    self:_reveal(element.stroke, { Transparency = 1 }, animate)
    self:_reveal(element.title, { TextTransparency = 1 }, animate)
    self:_reveal(element.main, { BackgroundTransparency = 1 }, animate)
    if element.iconLabel then
        self:_reveal(element.iconLabel, { ImageTransparency = 1 }, animate)
    end
    if element.descriptor then
        self:_reveal(element.descriptor.titleLabel, { TextTransparency = 1 }, animate)
    end
end

function Window:_collapsedRect()
    local size = if self.showIconOnly then collapsedIconSize else collapsedSize
    if self._collapsedPosition then
        return self._collapsedPosition, size
    end
    local home = UDim2.new(
        collapsedTop.X.Scale,
        collapsedTop.X.Offset,
        collapsedTop.Y.Scale,
        collapsedTop.Y.Offset + size.Y.Offset / 2
    )
    return home, size
end

function Window:_interactive()
    return not self.animating and not self.hidden
end

function Window:_settled()
    return not self.hidden and not self._revealing
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

function Window:Disconnect(connection)
    if not connection then
        return
    end
    local index = table.find(self.connections, connection)
    if index then
        table.remove(self.connections, index)
    end
    connection:Disconnect()
end

function Window:DestroySubtree(root)
    if not root then
        return
    end

    local inSubtree = { [root] = true }
    for _, descendant in root:GetDescendants() do
        inSubtree[descendant] = true
    end
    for i = #self.instances, 1, -1 do
        local instance = self.instances[i]
        if inSubtree[instance] then
            table.remove(self.instances, i)
            self.themeProperties[instance] = nil
            self.localeProperties[instance] = nil
        end
    end

    root:Destroy()
end

function Window:DisconnectMany(owner, connections)
    if not connections or #connections == 0 then
        return
    end

    local dropping = {}
    for _, connection in connections do
        dropping[connection] = true
        connection:Disconnect()
    end

    local function filter(list)
        if not list then
            return
        end
        local kept = 0
        for index = 1, #list do
            local entry = list[index]
            if not dropping[entry] then
                kept += 1
                list[kept] = entry
            end
        end
        for index = #list, kept + 1, -1 do
            list[index] = nil
        end
    end

    filter(self.connections)
    if owner and owner ~= self then
        filter(owner.connections)
    end
end

function Window:DestroySubtrees(roots)
    if not roots or #roots == 0 then
        return
    end

    local inSubtree = {}
    for _, root in roots do
        inSubtree[root] = true
        for _, descendant in root:GetDescendants() do
            inSubtree[descendant] = true
        end
    end

    local kept = 0
    for index = 1, #self.instances do
        local instance = self.instances[index]
        if inSubtree[instance] then
            self.themeProperties[instance] = nil
            self.localeProperties[instance] = nil
        else
            kept += 1
            self.instances[kept] = instance
        end
    end
    for index = #self.instances, kept + 1, -1 do
        self.instances[index] = nil
    end

    for _, root in roots do
        root:Destroy()
    end
end

function Window:Unload()
    self.unloaded = true
    hapticEngine.teardown()
    hapticEngine.releaseContainer(self.screenGui)
    if self._liveTween then
        self._liveTween:Cancel()
        self._liveTween = nil
    end
    for i = #self.connections, 1, -1 do
        self.connections[i]:Disconnect()
    end
    for i = #self.instances, 1, -1 do
        self.instances[i]:Destroy()
    end

    table.clear(self.connections)
    table.clear(self.instances)
    table.clear(self.themeProperties)
    table.clear(self.localeProperties)
    table.clear(self.controls)
    table.clear(self.tabs)
end

return Window
