-- Silent Framework | Core/Window.lua
-- Responsabilidad: Construcción de la interfaz principal, sistema de arrastre y gestión de pestañas.

local Services, Creator, ThemeManager, Tween, Runtime

local Window = {}

-- Inyección de Dependencias
function Window.InitDependencies(servicesModule, creatorModule, themeModule, tweenModule, runtimeModule)
    Services = servicesModule
    Creator = creatorModule
    ThemeManager = themeModule
    Tween = tweenModule
    Runtime = runtimeModule
end

-- Lógica de arrastre suave (Smooth Dragging)
local function MakeDraggable(dragArea, targetFrame)
    local UserInputService = Services.UserInputService
    local dragging, dragInput, dragStart, startPos

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
    local size = options.Size or UDim2.new(0, 550, 0, 380)
    
    local safeParent = Runtime.GetSafeParent()

    local screenGui = Creator.New("ScreenGui", {
        Name = "Silent_UI",
        Parent = safeParent,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })
    Runtime.ProtectGui(screenGui)

    -- Marco Principal
    local mainFrame = Creator.New("Frame", {
        Name = "MainFrame",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        Parent = screenGui,
        ClipsDescendants = true,
        ThemeTag = { BackgroundColor3 = "Background" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } })
    })

    -- Barra Superior (Topbar)
    local topbar = Creator.New("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = mainFrame
    }, {
        Creator.New("TextLabel", {
            Text = title,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 15, 0, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            ThemeTag = { TextColor3 = "Text" }
        }),
        Creator.New("Frame", {
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -1),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Border" }
        })
    })

    -- Barra Lateral (Sidebar para Tabs)
    local sidebar = Creator.New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BorderSizePixel = 0,
        Parent = mainFrame,
        ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("Frame", { -- Ocultar la esquina derecha para que se fusione con el contenido
            Size = UDim2.new(0, 8, 1, 0),
            Position = UDim2.new(1, -8, 0, 0),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Panel" }
        })
    })

    -- NUEVO: Contenedor interior solo para los botones (Fix del Layout)
    local tabContainer = Creator.New("ScrollingFrame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        BorderSizePixel = 0,
        Parent = sidebar
    }, {
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        }),
        Creator.New("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        })
    })

    -- Contenedor de Contenido (Donde van los elementos de las pestañas)
    local contentContainer = Creator.New("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -140, 1, -40),
        Position = UDim2.new(0, 140, 0, 40),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })

    MakeDraggable(topbar, mainFrame)

    local WindowObj = {
        GUI = screenGui,
        Main = mainFrame,
        Sidebar = sidebar,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        CurrentTab = nil
    }

    -- Método para crear pestañas
    function WindowObj:CreateTab(tabName)
        local tabId = "Tab_" .. tostring(tabName)
        
        local tabButton = Creator.New("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1,
            Text = tabName,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = self.TabContainer, -- Asignado al nuevo contenedor seguro
            ThemeTag = { TextColor3 = "TextMuted" }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) })
        })

        local tabContent = Creator.New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            BorderSizePixel = 0,
            Visible = false,
            Parent = self.ContentContainer,
            ThemeTag = { ScrollBarImageColor3 = "Border" }
        }, {
            Creator.New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6)
            }),
            Creator.New("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10)
            })
        })

        local TabObj = {
            Button = tabButton,
            Content = tabContent,
            Name = tabName
        }

        tabButton.MouseButton1Click:Connect(function()
            self:SelectTab(TabObj)
        end)

        table.insert(self.Tabs, TabObj)
        
        -- Si es la primera pestaña, la seleccionamos automáticamente
        if #self.Tabs == 1 then
            self:SelectTab(TabObj)
        end

        return TabObj
    end

    function WindowObj:SelectTab(tabObj)
        for _, tab in ipairs(self.Tabs) do
            tab.Content.Visible = false
            -- Reiniciamos estilos de los botones inactivos
            Tween(tab.Button, nil, { BackgroundTransparency = 1 })
            ThemeManager.Register(tab.Button, { TextColor3 = "TextMuted" })
        end

        -- Activamos la pestaña seleccionada
        tabObj.Content.Visible = true
        ThemeManager.Register(tabObj.Button, {
            BackgroundColor3 = "Accent",
            TextColor3 = "Background"
        })
        Tween(tabObj.Button, nil, { BackgroundTransparency = 0 })
        
        self.CurrentTab = tabObj
    end

    return WindowObj
end

return Window
