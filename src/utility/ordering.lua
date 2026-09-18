


type OrderedElement = {
    main: GuiObject,
    descriptor: { main: GuiObject }?,
}

local function assignOrder(element: OrderedElement, order: number)
    element.main.LayoutOrder = order
    if element.descriptor then
        element.descriptor.main.LayoutOrder = order + 1
    end
end

return assignOrder
