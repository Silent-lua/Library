-- Silent Framework | Core/Elements.lua
-- Responsabilidad: Componentes visualmente idénticos a Rayfield Gen2.

local Services, Creator, ThemeManager, Tween, Runtime
local Elements = {}

function Elements.InitDependencies(services, creator, theme, tween, runtime)
    Services = services; Creator = creator; ThemeManager = theme; Tween = tween; Runtime = runtime
end

function Elements.CreateButton(parent, options)
    local title = options.Title or "Button"
    local callback = options.Callback or function() end

    local btnFrame = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.new(1,1,1),
        Text = "", AutoButtonColor = false, Parent = parent, ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
        Creator.New("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
            Text = title, Font = Enum.Font.GothamMedium, TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left, ThemeTag = { TextColor3 = "Text" }
        }),
        Creator.New("ImageLabel", { -- Icono de flecha típico de Rayfield
            Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -16, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1,
            Image = "rbxassetid://10002373410", ThemeTag = { ImageColor3 = "TextMuted" }
        })
    })

    btnFrame.MouseEnter:Connect(function() Tween(btnFrame, nil, { BackgroundTransparency = 0.4 }) end)
    btnFrame.MouseLeave:Connect(function() Tween(btnFrame, nil, { BackgroundTransparency = 0 }) end)
    btnFrame.MouseButton1Click:Connect(function()
        local orig = ThemeManager.GetColor("Panel")
        btnFrame.BackgroundColor3 = ThemeManager.GetColor("Border")
        Tween(btnFrame, TweenInfo.new(0.3), { BackgroundColor3 = orig })
        Runtime.CallSafely(callback)
    end)
    return {}
end

function Elements.CreateToggle(parent, options)
    local title = options.Title or "Toggle"
    local state = options.Default or false
    local callback = options.Callback or function() end

    local toggleFrame = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.new(1,1,1),
        Text = "", AutoButtonColor = false, Parent = parent, ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
        Creator.New("TextLabel", {
            Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = title,
            Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" }
        })
    })

    local switchBg = Creator.New("Frame", {
        Size = UDim2.new(0, 40, 0, 20), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Parent = toggleFrame, ThemeTag = { BackgroundColor3 = "Border" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local switchKnob = Creator.New("Frame", {
        Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0), Parent = switchBg, ThemeTag = { BackgroundColor3 = "TextMuted" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
         Creator.New("UIStroke", { Thickness = 1, Transparency = 0.5, ThemeTag = { Color = "Background" } }) 
    })

    local function UpdateState(animate)
        local targetPos = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        if animate then
            Tween(switchKnob, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPos })
        else switchKnob.Position = targetPos end
        
        if state then
            ThemeManager.Register(switchBg, { BackgroundColor3 = "Accent" })
            ThemeManager.Register(switchKnob, { BackgroundColor3 = "Text" })
            if not animate then switchBg.BackgroundColor3 = ThemeManager.GetColor("Accent"); switchKnob.BackgroundColor3 = ThemeManager.GetColor("Text") end
        else
            ThemeManager.Register(switchBg, { BackgroundColor3 = "Border" })
            ThemeManager.Register(switchKnob, { BackgroundColor3 = "TextMuted" })
            if not animate then switchBg.BackgroundColor3 = ThemeManager.GetColor("Border"); switchKnob.BackgroundColor3 = ThemeManager.GetColor("TextMuted") end
        end
    end

    UpdateState(false)
    toggleFrame.MouseButton1Click:Connect(function()
        state = not state; UpdateState(true); Runtime.CallSafely(callback, state)
    end)

    return { Set = function(self, val) state = val; UpdateState(true); Runtime.CallSafely(callback, state) end }
end

function Elements.CreateSlider(parent, options)
    local title = options.Title or "Slider"
    local min, max, default = options.Min or 0, options.Max or 100, options.Default or 0
    local callback = options.Callback or function() end

    local sliderFrame = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 56), Parent = parent, ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) })
    })

    Creator.New("TextLabel", {
        Size = UDim2.new(1, -40, 0, 14), BackgroundTransparency = 1, Text = title,
        Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sliderFrame, ThemeTag = { TextColor3 = "Text" }
    })

    local valueLabel = Creator.New("TextLabel", {
        Size = UDim2.new(0, 40, 0, 14), Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1, Text = tostring(default), Font = Enum.Font.GothamBold, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = sliderFrame, ThemeTag = { TextColor3 = "Accent" }
    })

    local slideBg = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6),
        Text = "", AutoButtonColor = false, Parent = sliderFrame, ThemeTag = { BackgroundColor3 = "Border" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    local slideFill = Creator.New("Frame", {
        Size = UDim2.new(0, 0, 1, 0), Parent = slideBg, ThemeTag = { BackgroundColor3 = "Accent" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    Creator.New("Frame", {
        Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Parent = slideFill, ThemeTag = { BackgroundColor3 = "Text" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }), Creator.New("UIStroke", { Thickness = 2, Transparency = 0.5, ThemeTag = { Color = "Background" } }) })

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
            isDragging = true; UpdateSlider(input)
        end
    end)
    slideBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateSlider(input) end
    end)

    slideFill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
    return {}
end

function Elements.CreateDropdown(parent, options)
    local title = options.Title or "Dropdown"
    local items = options.Options or {}
    local current = options.Default or items[1]
    local callback = options.Callback or function() end

    local isOpen = false
    local itemHeight = 32
    local maxVisible = 5
    local listHeight = math.min(#items, maxVisible) * itemHeight

    local dropFrame = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        ClipsDescendants = true, Parent = parent, ThemeTag = { BackgroundColor3 = "Panel" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } })
    })

    local headerBtn = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Text = "", Parent = dropFrame
    }, {
        Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) })
    })

    local titleLabel = Creator.New("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1,
        Text = title .. ": " .. tostring(current), Font = Enum.Font.GothamMedium, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = headerBtn, ThemeTag = { TextColor3 = "Text" }
    })

    local iconLabel = Creator.New("ImageLabel", {
        Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -16, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1, Image = "rbxassetid://10002373410", Rotation = 90, Parent = headerBtn, ThemeTag = { ImageColor3 = "TextMuted" }
    })

    local optionList = Creator.New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, listHeight), Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1, ScrollBarThickness = 2, BorderSizePixel = 0,
        Parent = dropFrame, ThemeTag = { ScrollBarImageColor3 = "Border" }
    }, { Creator.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

    local function Populate()
        for _, child in ipairs(optionList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for _, item in ipairs(items) do
            local optBtn = Creator.New("TextButton", {
                Size = UDim2.new(1, 0, 0, itemHeight), BackgroundTransparency = 1,
                Text = "  " .. tostring(item), Font = Enum.Font.Gotham, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = optionList, ThemeTag = { TextColor3 = "TextMuted" }
            })

            optBtn.MouseEnter:Connect(function() ThemeManager.Register(optBtn, { TextColor3 = "Accent", BackgroundColor3 = "Border" }); Tween(optBtn, nil, {BackgroundTransparency = 0.5}) end)
            optBtn.MouseLeave:Connect(function() ThemeManager.Register(optBtn, { TextColor3 = "TextMuted" }); Tween(optBtn, nil, {BackgroundTransparency = 1}) end)
            
            optBtn.MouseButton1Click:Connect(function()
                current = item
                titleLabel.Text = title .. ": " .. tostring(current)
                isOpen = false
                Tween(dropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0, 42) })
                Tween(iconLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = 90 })
                Runtime.CallSafely(callback, current)
            end)
        end
        optionList.CanvasSize = UDim2.new(0, 0, 0, #items * itemHeight)
    end
    Populate()

    headerBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            Tween(dropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0, 42 + listHeight) })
            Tween(iconLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = -90 })
        else
            Tween(dropFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0, 42) })
            Tween(iconLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Rotation = 90 })
        end
    end)

    return {
        Refresh = function(self, newOptions)
            items = newOptions
            listHeight = math.min(#items, maxVisible) * itemHeight
            optionList.Size = UDim2.new(1, 0, 0, listHeight)
            Populate()
        end
    }
end

return Elements
