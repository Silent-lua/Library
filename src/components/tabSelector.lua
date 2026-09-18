


local utility = script.Parent.Parent.utility
local variables = require(utility.variables)
local functions = require(utility.functions)
local locale = require(utility.locale)

local tabSelector = {}

local function initialOf(name: string?): string
    if type(name) ~= "string" or name == "" then
        return "?"
    end
    local afterFirst = utf8.offset(name, 2)
    local first = if afterFirst then string.sub(name, 1, afterFirst - 1) else name
    return string.upper(first)
end

tabSelector.states = {
    top = {
        selected = { background = 0, stroke = 0, content = 0 },
        hover = { background = 0.4, stroke = 0.3, content = 0.3 },
        unselected = { background = 0.8, stroke = 0.65, content = 0.5 },
        hidden = { background = 1, stroke = 1, content = 1 },
    },
    sidebar = {
        selected = { background = 0.4, stroke = 0.5, content = 0, shadow = 0.8 },
        hover = { background = 0.7, stroke = 0.8, content = 0.3, shadow = 1 },
        unselected = { background = 1, stroke = 1, content = 0.5, shadow = 1 },
        hidden = { background = 1, stroke = 1, content = 1, shadow = 1 },
    },
}

local function addGradients(tab, host, stroke)
    tab.topbarItemGradient = tab.window:Create("UIGradient", {
        Rotation = 90,

        Parent = host,
    }, { Color = { "TabBackground", functions.toColorSequence } })

    tab.topbarItemStrokeGradient = tab.window:Create("UIGradient", {
        Rotation = 90,

        Parent = stroke,
    }, { Color = { "TabStroke", functions.toColorSequence } })
end

local function addContent(tab, iconSize, withInitial)
    if withInitial and not tab.icon then
        tab.topbarItemInitial = tab.window:Create("TextLabel", {
            Text = initialOf(tab.name),

            Size = UDim2.fromOffset(iconSize, iconSize),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextSize = iconSize - 4,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Visible = false,

            TextTransparency = 1,

            Parent = tab.topbarItemContainer,
        }, { TextColor3 = "TabColor", FontFace = "Font" })
    end

    if tab.icon then
        tab.topbarItemIcon = tab.window:Create("ImageLabel", {
            Image = tab.icon,

            Size = UDim2.fromOffset(iconSize, iconSize),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,

            ImageTransparency = 1,

            Parent = tab.topbarItemContainer,
        }, { ImageColor3 = "TabColor" })
    end

    if tab.name then
        tab.topbarItemTitle = tab.window:Create("TextLabel", {
            Text = locale.t(tab.name),

            Size = UDim2.fromOffset(0, 16),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextSize = 16,
            AutomaticSize = Enum.AutomaticSize.XY,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 1,

            TextTransparency = 1,

            Parent = tab.topbarItemContainer,
        }, { TextColor3 = "TabColor", FontFace = "Font" })
    end
end

local function buildPill(tab)
    tab.topbarItem = tab.window:Create("Frame", {
        Name = tab.name,
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,

        BackgroundTransparency = 1,
        Visible = false,

        LayoutOrder = tab.customOrder or 0,

        Parent = tab.window.tabList,
    })

    tab.topbarItemInteract = tab.window:Create("TextButton", {
        Active = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Text = "",
        TextTransparency = 1,

        Parent = tab.topbarItem,
    })

    tab.window:Create("UICorner", {
        Parent = tab.topbarItem,
    }, { CornerRadius = "PillCornerRadius" })

    tab.topbarItemStroke = tab.window:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.fromRGB(255, 255, 255),

        Transparency = 1,

        Parent = tab.topbarItem,
    })

    addGradients(tab, tab.topbarItem, tab.topbarItemStroke)

    tab.topbarItemContainer = tab.window:Create("Frame", {
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Parent = tab.topbarItem,
    })

    tab.window:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 13),
        PaddingRight = UDim.new(0, 14),

        Parent = tab.topbarItemContainer,
    })

    tab.topbarItemLayout = tab.window:Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = tab.topbarItemContainer,
    })

    addContent(tab, 16, false)
end

local function buildRow(tab, layout)
    tab.topbarItem = tab.window:Create("Frame", {
        Name = tab.name,
        Size = UDim2.new(1, -layout.rowInset * 2, 0, layout.rowHeight),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,

        BackgroundTransparency = 1,
        Visible = false,

        LayoutOrder = tab.customOrder or 0,

        Parent = tab.window.tabList,
    })

    tab.topbarItemInteract = tab.window:Create("TextButton", {
        Active = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Text = "",
        TextTransparency = 1,

        Parent = tab.topbarItem,
    })

    tab.window:Create("UICorner", {
        CornerRadius = UDim.new(0, layout.rowCornerRadius),

        Parent = tab.topbarItem,
    })

    tab.topbarItemStroke = tab.window:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.fromRGB(255, 255, 255),

        Transparency = 1,

        Parent = tab.topbarItem,
    })

    addGradients(tab, tab.topbarItem, tab.topbarItemStroke)

    tab.topbarItemShadow = tab.window:Create("UIShadow", {
        BlurRadius = UDim.new(0, 20),
        Color = Color3.fromRGB(255, 255, 255),
        Offset = UDim2.new(0, 0, 0, -15),
        Spread = UDim2.new(0, 10, 0, -30),
        ZIndex = -1,

        Transparency = 1,

        Parent = tab.topbarItem,
    })

    tab.topbarItemContainer = tab.window:Create("Frame", {
        Size = UDim2.new(1, -layout.rowPadding, 0, 24),
        Position = UDim2.new(0, layout.rowPadding, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Parent = tab.topbarItem,
    })

    tab.topbarItemLayout = tab.window:Create("UIListLayout", {
        Padding = UDim.new(0, layout.rowContentSpacing),
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = tab.topbarItemContainer,
    })

    addContent(tab, layout.rowIconSize, true)
end

function tabSelector.build(tab, layout)
    if layout.mode == "sidebar" then
        buildRow(tab, layout)
    else
        buildPill(tab)
    end
end

function tabSelector.setRowCollapsed(tab, collapsed, layout)
    if layout.mode ~= "sidebar" or not tab.topbarItem then
        return
    end

    if tab.topbarItemTitle then
        tab.topbarItemTitle.Visible = not collapsed
    end
    if tab.topbarItemInitial then
        tab.topbarItemInitial.Visible = collapsed
    end
    local inset = if collapsed then 0 else layout.rowPadding
    tab.topbarItemContainer.Size = UDim2.new(1, -inset, 0, 24)
    tab.topbarItemContainer.Position = UDim2.new(0, inset, 0.5, 0)
    tab.topbarItemLayout.HorizontalAlignment = if collapsed
        then Enum.HorizontalAlignment.Center
        else Enum.HorizontalAlignment.Left
end

function tabSelector.applyVisual(tab, state, tweenInfo)
    local targets = {
        [tab.topbarItem] = { BackgroundTransparency = state.background },
        [tab.topbarItemStroke] = { Transparency = state.stroke },
    }

    if tab.topbarItemIcon then
        targets[tab.topbarItemIcon] = { ImageTransparency = state.content }
    end
    if tab.topbarItemTitle then
        targets[tab.topbarItemTitle] = { TextTransparency = state.content }
    end
    if tab.topbarItemInitial then
        targets[tab.topbarItemInitial] = { TextTransparency = state.content }
    end
    if tab.topbarItemShadow and state.shadow then
        targets[tab.topbarItemShadow] = { Transparency = state.shadow }
    end

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

return tabSelector
