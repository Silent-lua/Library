


local utility = script.Parent.Parent.utility
local variables = require(utility.variables)
local image = require(utility.image)
local locale = require(utility.locale)
local tabSelector = require(script.Parent.tabSelector)
local search = require(script.Parent.search)

local sidebar = {}

local nameTransparency = 0
local subtitleTransparency = 0.7
local avatarPlateTransparency = 0.95

local settleInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function profileVisible(window)
    return window.layout.mode == "sidebar"
        and window.profile ~= nil
        and window.settings.showProfile
        and variables.localPlayer ~= nil
end

local function buildProfile(window, layout)
    local player = variables.localPlayer
    if not player then
        return
    end

    window.profile = window:Create("Frame", {
        Name = "Profile",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 1),
        Size = UDim2.new(1, 0, 0, layout.footerHeight),
        BackgroundTransparency = 1,

        Parent = window.sidebar,
    })

    window.profileContainer = window:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, layout.rowInset, 0.5, 0),
        Size = UDim2.new(1, -layout.rowInset, 1, 0),
        BackgroundTransparency = 1,

        Parent = window.profile,
    })

    window.profileLayout = window:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = window.profileContainer,
    })

    window.profileAvatar = window:Create("ImageLabel", {
        Name = "Avatar",
        Image = image.avatar(player.UserId, function(uri)
            if window.profileAvatar and not window.unloaded then
                image.assign(window.profileAvatar, "Image", uri)
            end
        end),
        Size = UDim2.fromOffset(layout.avatarSize, layout.avatarSize),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,

        BackgroundTransparency = 1,
        ImageTransparency = 1,

        Parent = window.profileContainer,
    })

    window:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),

        Parent = window.profileAvatar,
    })

    window.profileLabels = window:Create("Frame", {
        Size = UDim2.fromOffset(50, layout.avatarSize),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 1,

        Parent = window.profileContainer,
    })

    window:Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = window.profileLabels,
    })

    window.profileName = window:Create("TextLabel", {
        Text = player.DisplayName,
        Size = UDim2.fromOffset(50, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,

        TextTransparency = 1,

        Parent = window.profileLabels,
    }, { TextColor3 = "TitlingColor", FontFace = "Font" })

    window.profileSubtitle = window:Create("TextLabel", {
        Text = "",
        Size = UDim2.fromOffset(50, 14),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Visible = false,

        TextTransparency = 1,

        Parent = window.profileLabels,
    }, { TextColor3 = "TitlingColor", FontFace = "Font" })
end

function sidebar.build(window, layout)
    window.sidebar = window:Create("Frame", {
        Name = "Sidebar",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(0, layout.railWidth, 1, -layout.chromeHeight),
        BackgroundTransparency = 1,

        Visible = false,

        Parent = window.main,
    })

    window.tabList = window:Create("ScrollingFrame", {
        Name = "Tabs",
        Active = true,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ScrollBarImageTransparency = 1,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,

        Parent = window.sidebar,
    })

    window:Create("UIPadding", {
        PaddingTop = UDim.new(0, layout.railPadding),
        PaddingBottom = UDim.new(0, layout.railPadding),

        Parent = window.tabList,
    })

    window.tabListLayout = window:Create("UIListLayout", {
        Padding = UDim.new(0, layout.rowSpacing),
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = window.tabList,
    })

    buildProfile(window, layout)
    sidebar.reflowProfile(window)
end

function sidebar.reflowProfile(window)
    local layout = window.layout
    local shown = profileVisible(window)

    if window.profile then
        window.profile.Visible = shown
    end
    window.tabList.Size = UDim2.new(1, 0, 1, if shown then -layout.footerHeight else 0)
end

function sidebar.applyWidth(window, width)
    local layout = window.layout

    window.sidebar.Size = UDim2.new(0, width, 1, -layout.chromeHeight)
    window.elements.Size = UDim2.new(1, -width, 1, -layout.chromeHeight)
    window.bottomFade.Size = UDim2.new(1, -width, layout.fadeSize.Y.Scale, layout.fadeSize.Y.Offset)
    search.railWidth(window, width)

    local collapsed = width < (layout.railWidth :: number)
    for _, tab in window.tabs do
        if not tab.neglectSelector then
            tabSelector.setRowCollapsed(tab, collapsed, layout)
        end
    end

    if window.profileContainer then
        window.profileContainer.Position = UDim2.new(0, if collapsed then 0 else layout.rowInset, 0.5, 0)
        window.profileContainer.Size = UDim2.new(1, if collapsed then 0 else -layout.rowInset, 1, 0)
        window.profileLayout.HorizontalAlignment = if collapsed
            then Enum.HorizontalAlignment.Center
            else Enum.HorizontalAlignment.Left
        window.profileLabels.Visible = not collapsed
    end
end

function sidebar.setProfileShown(window, shown, tweenInfo)
    if not window.profile or not window.profile.Visible then
        return
    end

    local targets = {
        [window.profileAvatar] = {
            ImageTransparency = if shown then 0 else 1,
            BackgroundTransparency = if shown then avatarPlateTransparency else 1,
        },
        [window.profileName] = { TextTransparency = if shown then nameTransparency else 1 },
        [window.profileSubtitle] = { TextTransparency = if shown then subtitleTransparency else 1 },
    }

    for instance, properties in targets do
        if tweenInfo then
            variables.tweenService:Create(instance, tweenInfo, properties):Play()
        else
            for property, value in properties do
                instance[property] = value
            end
        end
    end
end

function sidebar.setProfileEnabled(window, enabled)
    if not window.profile then
        window.settings.showProfile = enabled
        return
    end

    if enabled then
        window.settings.showProfile = true
        sidebar.reflowProfile(window)
        sidebar.setProfileShown(window, true, settleInfo)
        return
    end

    sidebar.setProfileShown(window, false, settleInfo)
    task.delay(settleInfo.Time, function()
        if window.unloaded or window.settings.showProfile then
            return
        end
        sidebar.reflowProfile(window)
    end)
    window.settings.showProfile = false
end

function sidebar.setSubtitle(window, text)
    if not window.profileSubtitle then
        return
    end

    local resolved = if type(text) == "string" and text ~= "" then locale.resolve(text) else nil
    window.profileSubtitle.Text = resolved or ""
    window.profileSubtitle.Visible = resolved ~= nil
end

return sidebar
