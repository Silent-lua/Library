-- Silent Framework | Core/Window.lua
-- Responsabilidad: Diseño visual inspirado en Rayfield Gen2, sistema de arrastre y gestión de pestañas.

local Services, Creator, ThemeManager, Tween, Runtime, Elements

local Window = {}

function Window.InitDependencies(services, creator, theme, tween, runtime, elements)
    Services = services; Creator = creator; ThemeManager = theme
    Tween = tween; Runtime = runtime; Elements = elements
end

local function MakeDraggable(dragArea, targetFrame)
    local UserInputService = Services.UserInputService
    local dragging, dragInput, dragStart, startPos

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Window.New(options)
    options = options or {}
    local title = options.Title or "Silent Framework"
    local size = options.Size or UDim2.new(0, 600, 0, 420)
    
    local safeParent = Runtime.GetSafeParent()

    local screenGui = Creator.New("ScreenGui", {
        Name = "Silent_Rayfield_UI", Parent = safeParent,
        ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Global
    })
    Runtime.ProtectGui(screenGui)

    -- Marco Principal (Sin ClipsDescendants para permitir la sombra exterior)
    local mainFrame = Creator.New("Frame", {
        Name = "MainFrame", Size = size,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        Parent = screenGui, ClipsDescendants = false,
        ThemeTag = { BackgroundColor3 = "Background" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
        -- Sombra Estilo Rayfield Gen2
        Creator.New("ImageLabel", {
            Name = "DropShadow",
            Image = "rbxassetid://8992230677",
            ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.4,
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(99, 99, 99, 99),
            Size = UDim2.new(1, 60, 1, 60), Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = -1
        })
    })

    -- Barra Superior
    local topbar = Creator.New("Frame", {
        Name = "Topbar", Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1, Parent = mainFrame
    }, {
        Creator.New("TextLabel", {
            Text = title, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 20, 0, 0),
            Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" }
        }),
        Creator.New("Frame", {
            Name = "Divider", Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
            BorderSizePixel = 0, ThemeTag = { BackgroundColor3 = "Border" }
        })
    })

    -- Barra Lateral
    local sidebar = Creator.New("Frame", {
        Name = "Sidebar", Size = UDim2.new(0, 150, 1, -45),
        Position = UDim2.new(0, 0, 0, 45), BorderSizePixel = 0,
        Parent = mainFrame, ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Creator.New("Frame", { -- Esquina recta para conectar con el contenido
            Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0),
            BorderSizePixel = 0, ThemeTag = { BackgroundColor3 = "Panel" }
        })
    })

    local tabContainer = Creator.New("ScrollingFrame", {
        Name = "TabContainer", Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0, Parent = sidebar
    }, {
        Creator.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
        Creator.New("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) })
    })

    -- Contenedor de Pestañas (ClipsDescendants aquí para ocultar el scroll interno)
    local contentContainer = Creator.New("Frame", {
        Name = "ContentContainer", Size = UDim2.new(1, -150, 1, -45),
        Position = UDim2.new(0, 150, 0, 45), BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = mainFrame
    })

    MakeDraggable(topbar, mainFrame)

    local WindowObj = {
        GUI = screenGui, Main = mainFrame, Sidebar = sidebar,
        TabContainer = tabContainer, ContentContainer = contentContainer,
        Tabs = {}, CurrentTab = nil
    }

    function WindowObj:CreateTab(tabName)
        -- Botón de Pestaña estilo Rayfield
        local tabButton = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            Parent = self.TabContainer, ThemeTag = { BackgroundColor3 = "Accent" }
        }, { 
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Creator.New("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 20, 0, 0),
                BackgroundTransparency = 1, Text = tabName, Font = Enum.Font.GothamMedium,
                TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "TextMuted" }
            })
        })

        -- Indicador Vertical (Pill)
        local tabIndicator = Creator.New("Frame", {
            Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 6, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1,
            Parent = tabButton, ThemeTag = { BackgroundColor3 = "Accent" }
        }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

        local tabContent = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            ScrollBarThickness = 2, BorderSizePixel = 0, Visible = false,
            Parent = self.ContentContainer, ThemeTag = { ScrollBarImageColor3 = "Border" }
        }, {
            Creator.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
            Creator.New("UIPadding", { PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 20), PaddingBottom = UDim.new(0, 15) })
        })

        local TabObj = {
            Button = tabButton, Indicator = tabIndicator, Label = tabButton.TextLabel,
            Content = tabContent, Name = tabName
        }

        function TabObj:CreateButton(opts) return Elements.CreateButton(self.Content, opts) end
        function TabObj:CreateToggle(opts) return Elements.CreateToggle(self.Content, opts) end
        function TabObj:CreateSlider(opts) return Elements.CreateSlider(self.Content, opts) end
        function TabObj:CreateDropdown(opts) return Elements.CreateDropdown(self.Content, opts) end

        tabButton.MouseButton1Click:Connect(function() self:SelectTab(TabObj) end)
        table.insert(self.Tabs, TabObj)
        if #self.Tabs == 1 then self:SelectTab(TabObj) end

        return TabObj
    end

    function WindowObj:SelectTab(tabObj)
        for _, tab in ipairs(self.Tabs) do
            tab.Content.Visible = false
            Tween(tab.Button, nil, { BackgroundTransparency = 1 })
            Tween(tab.Indicator, nil, { BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 10) })
            ThemeManager.Register(tab.Label, { TextColor3 = "TextMuted" })
        end

        tabObj.Content.Visible = true
        ThemeManager.Register(tabObj.Label, { TextColor3 = "Text" })
        Tween(tabObj.Button, nil, { BackgroundTransparency = 0.9 })
        Tween(tabObj.Indicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 18) })
        
        self.CurrentTab = tabObj
    end

    return WindowObj
end

return Window
