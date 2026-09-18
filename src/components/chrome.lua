


local utility = script.Parent.Parent.utility
local variables = require(utility.variables)
local filesystem = require(utility.filesystem)
local constants = require(utility.constants)
local locale = require(utility.locale)
local hapticEngine = require(utility.HapticEngine)

local chrome = {}

local dragThreshold = 5

function chrome.buildCollapsedFace(window)
    local iconOnly = window.showIconOnly

    window.collapsedIcon = window:Create("ImageLabel", {
        Name = "CollapsedIcon",
        AnchorPoint = if iconOnly then Vector2.new(0.5, 0.5) else Vector2.new(0, 0.5),
        Position = if iconOnly then UDim2.fromScale(0.5, 0.5) else UDim2.new(0, 16, 0.5, 0),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Image = window.showIcon,
        ZIndex = constants.zIndex.restoreContent,

        ImageTransparency = 1,

        Parent = window.main,
    }, { ImageColor3 = "TitlingColor" })

    window:Create("UICorner", {
        Parent = window.collapsedIcon,
    }, { CornerRadius = "PillCornerRadius" })

    local textContainer = window:Create("Frame", {
        Name = "CollapsedText",
        Visible = not iconOnly,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 50, 0.5, 0),
        Size = UDim2.new(1, -60, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = constants.zIndex.restoreContent,

        Parent = window.main,
    })

    window:Create("UIListLayout", {
        Padding = UDim.new(0, 1),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = textContainer,
    })

    window.collapsedTitle = window:Create("TextLabel", {
        Name = "Title",
        Text = window.showName,
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        FontFace = variables.brandFont(Enum.FontWeight.Medium),
        RichText = true,
        TextSize = 16,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = constants.zIndex.restoreContent,

        TextTransparency = 1,

        Parent = textContainer,
    }, { TextColor3 = "TitlingColor" })

    window.collapsedSubtitle = window:Create("TextLabel", {
        Name = "Subtitle",
        Text = locale.t("Tap to show"),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        FontFace = variables.brandFont(Enum.FontWeight.Medium),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        ZIndex = constants.zIndex.restoreContent,

        TextTransparency = 1,

        Parent = textContainer,
    }, { TextColor3 = "TitlingColor" })

    window.collapsedInteract = window:Create("TextButton", {
        Name = "CollapsedInteract",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextTransparency = 1,
        Visible = false,
        ZIndex = constants.zIndex.restoreInteract,

        Parent = window.main,
    })

    chrome.bindCollapsedDrag(window)
end

function chrome.bindCollapsedDrag(window)
    local uis = variables.userInputService
    local dragging, moved = false, false
    local grabOffset, grabMouse = Vector2.zero, Vector2.zero

    local function insetOffset()
        if window.screenGui and window.screenGui.IgnoreGuiInset then
            return variables.guiService:GetGuiInset()
        end
        return Vector2.zero
    end

    window:Connect(window.collapsedInteract.InputBegan, function(input, processed)
        if processed or not window.hidden or window.animating then
            return
        end
        local inputType = input.UserInputType.Name
        if inputType ~= "MouseButton1" and inputType ~= "Touch" then
            return
        end

        dragging, moved = true, false
        grabMouse = uis:GetMouseLocation()
        grabOffset = window.main.AbsolutePosition + window.main.AbsoluteSize * window.main.AnchorPoint - grabMouse
    end)

    window:Connect(uis.InputEnded, function(input)
        local inputType = input.UserInputType.Name
        if inputType ~= "MouseButton1" and inputType ~= "Touch" then
            return
        end
        if not dragging then
            return
        end
        dragging = false

        if moved then
            window._collapsedPosition = window.main.Position
            return
        end

        hapticEngine.click()
        window:ToggleHide()
    end)

    window:Connect(uis.WindowFocusReleased, function()
        dragging = false
    end)

    window:Connect(variables.runService.RenderStepped, function()
        if not dragging then
            return
        end
        if not window.hidden or window.animating then
            dragging = false
            return
        end

        local mouse = uis:GetMouseLocation()
        if not moved and (mouse - grabMouse).Magnitude < dragThreshold then
            return
        end
        moved = true

        local target = mouse + grabOffset + insetOffset()
        window.main.Position = UDim2.fromOffset(target.X, target.Y)
    end)
end

function chrome.isNewUser()
    local localPlayer = variables.localPlayer
    if not localPlayer then
        return false
    end

    if typeof(filesystem.isfile) ~= "function" or typeof(filesystem.writefile) ~= "function" then
        return true
    end

    local path = variables.fileSystemManager:getPath("lastuser.txt")
    local currentId = tostring(localPlayer.UserId)
    local isNew = true

    pcall(function()
        if filesystem.isfile(path) then
            isNew = filesystem.readfile(path) ~= currentId
        end
    end)

    pcall(function()
        filesystem.writefile(path, currentId)
    end)

    return isNew
end

function chrome.setCollapsedShown(window, shown, tweenInfo)
    local targets = {
        [window.collapsedIcon] = { ImageTransparency = if shown then 0 else 1 },
    }

    if not window.showIconOnly then
        targets[window.collapsedTitle] = { TextTransparency = if shown then 0 else 1 }
        targets[window.collapsedSubtitle] = { TextTransparency = if shown then 0.5 else 1 }
    end

    for instance, props in targets do
        if tweenInfo then
            variables.tweenService:Create(instance, tweenInfo, props):Play()
        else
            for property, value in props do
                instance[property] = value
            end
        end
    end
end

return chrome
