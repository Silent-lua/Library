-- Silent Framework | Core/Elements.lua
-- Responsabilidad: Construcción y lógica de componentes interactivos (Botones, Toggles, Sliders).

local Services, Creator, ThemeManager, Tween, Runtime
local Elements = {}

function Elements.InitDependencies(services, creator, theme, tween, runtime)
    Services = services
    Creator = creator
    ThemeManager = theme
    Tween = tween
    Runtime = runtime
end

-- ==========================================
-- COMPONENTE: BUTTON
-- ==========================================
function Elements.CreateButton(parent, options)
    local title = options.Title or "Button"
    local callback = options.Callback or function() end

    local btnFrame = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.new(1,1,1),
        Text = "",
        AutoButtonColor = false,
        Parent = parent,
        ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
        Creator.New("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = title,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" }
        })
    })

    btnFrame.MouseEnter:Connect(function()
        Tween(btnFrame, nil, { BackgroundTransparency = 0.3 })
    end)
    btnFrame.MouseLeave:Connect(function()
        Tween(btnFrame, nil, { BackgroundTransparency = 0 })
    end)
    
    btnFrame.MouseButton1Click:Connect(function()
        local originalColor = ThemeManager.GetColor("Panel")
        local clickColor = ThemeManager.GetColor("Accent")
        
        btnFrame.BackgroundColor3 = clickColor
        Tween(btnFrame, TweenInfo.new(0.3), { BackgroundColor3 = originalColor })
        
        Runtime.CallSafely(callback)
    end)

    return {
        SetTitle = function(self, newTitle)
            btnFrame.TextLabel.Text = newTitle
        end
    }
end

-- ==========================================
-- COMPONENTE: TOGGLE
-- ==========================================
function Elements.CreateToggle(parent, options)
    local title = options.Title or "Toggle"
    local state = options.Default or false
    local callback = options.Callback or function() end

    local toggleFrame = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.new(1,1,1),
        Text = "",
        AutoButtonColor = false,
        Parent = parent,
        ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
        Creator.New("TextLabel", {
            Size = UDim2.new(1, -40, 1, 0),
            BackgroundTransparency = 1,
            Text = title,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" }
        })
    })

    local switchBg = Creator.New("Frame", {
        Size = UDim2.new(0, 36, 0, 18),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Parent = toggleFrame,
        ThemeTag = { BackgroundColor3 = "Border" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    local switchKnob = Creator.New("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Parent = switchBg,
        ThemeTag = { BackgroundColor3 = "TextMuted" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    local function UpdateState(animate)
        local targetPos = state and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        
        if animate then
            Tween(switchKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPos })
        else
            switchKnob.Position = targetPos
        end
        
        -- Re-registro dinámico para que los colores se actualicen si cambia el tema global
        if state then
            ThemeManager.Register(switchBg, { BackgroundColor3 = "Accent" })
            ThemeManager.Register(switchKnob, { BackgroundColor3 = "Background" })
            if not animate then
                switchBg.BackgroundColor3 = ThemeManager.GetColor("Accent")
                switchKnob.BackgroundColor3 = ThemeManager.GetColor("Background")
            end
        else
            ThemeManager.Register(switchBg, { BackgroundColor3 = "Border" })
            ThemeManager.Register(switchKnob, { BackgroundColor3 = "TextMuted" })
            if not animate then
                switchBg.BackgroundColor3 = ThemeManager.GetColor("Border")
                switchKnob.BackgroundColor3 = ThemeManager.GetColor("TextMuted")
            end
        end
    end

    UpdateState(false)

    toggleFrame.MouseButton1Click:Connect(function()
        state = not state
        UpdateState(true)
        Runtime.CallSafely(callback, state)
    end)

    local ToggleObj = { State = state }
    function ToggleObj:Set(value)
        state = value
        UpdateState(true)
        Runtime.CallSafely(callback, state)
    end

    return ToggleObj
end

-- ==========================================
-- COMPONENTE: SLIDER
-- ==========================================
function Elements.CreateSlider(parent, options)
    local title = options.Title or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local callback = options.Callback or function() end

    local sliderFrame = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = parent,
        ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { 
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) 
        })
    })

    local titleLabel = Creator.New("TextLabel", {
        Size = UDim2.new(1, -40, 0, 14),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sliderFrame,
        ThemeTag = { TextColor3 = "Text" }
    })

    local valueLabel = Creator.New("TextLabel", {
        Size = UDim2.new(0, 40, 0, 14),
        Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(default),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = sliderFrame,
        ThemeTag = { TextColor3 = "TextMuted" }
    })

    local slideBg = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 1, -4),
        Text = "",
        AutoButtonColor = false,
        Parent = sliderFrame,
        ThemeTag = { BackgroundColor3 = "Border" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local slideFill = Creator.New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        Parent = slideBg,
        ThemeTag = { BackgroundColor3 = "Accent" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local slideKnob = Creator.New("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Parent = slideFill,
        ThemeTag = { BackgroundColor3 = "Text" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local isDragging = false
    local function UpdateSlider(input)
        local sizeX = math.clamp((input.Position.X - slideBg.AbsolutePosition.X) / slideBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + ((max - min) * sizeX))
        
        Tween(slideFill, TweenInfo.new(0.1), { Size = UDim2.new(sizeX, 0, 1, 0) })
        valueLabel.Text = tostring(value)
        Runtime.CallSafely(callback, value)
    end

    slideBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateSlider(input)
        end
    end)
    slideBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)

    -- Seteo Inicial
    local initPercent = math.clamp((default - min) / (max - min), 0, 1)
    slideFill.Size = UDim2.new(initPercent, 0, 1, 0)

    local SliderObj = {}
    function SliderObj:Set(val)
        val = math.clamp(val, min, max)
        local pct = (val - min) / (max - min)
        Tween(slideFill, TweenInfo.new(0.1), { Size = UDim2.new(pct, 0, 1, 0) })
        valueLabel.Text = tostring(val)
        Runtime.CallSafely(callback, val)
    end

    return SliderObj
end

return Elements
