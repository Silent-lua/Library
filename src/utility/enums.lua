
local enums = {}

function enums.itemFromValue(enumType, value)
    local ok, item = pcall(function()
        return enumType:FromValue(value)
    end)
    if ok and item then
        return item
    end

    local itemsOk, items = pcall(function()
        return enumType:GetEnumItems()
    end)
    if not itemsOk then
        return nil
    end

    for _, enumItem in items do
        if enumItem.Value == value then
            return enumItem
        end
    end

    return nil
end

return enums
