

local flagNames = {}

local offsetBasis = 2166136261
local prime = 16777619

local function hashName(name: string): number
    local hash = offsetBasis
    for index = 1, #name do
        hash = bit32.bxor(hash, string.byte(name, index))
        local low = hash % 65536
        local high = (hash - low) / 65536
        hash = (((high * prime) % 65536) * 65536 + low * prime) % 4294967296
    end
    return hash
end

function flagNames.deriveFlagFromName(name: string): string
    local flag = name:gsub("(%S+)", function(w: string): string
        return w:sub(1, 1):upper() .. w:sub(2, -1)
    end):gsub("[^%w]", "")

    if flag == "" and name ~= "" then
        return string.format("Flag%08x", hashName(name))
    end

    return flag
end

return flagNames
