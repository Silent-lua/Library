

local path = {}

function path.join(basePath: string, childPath: string?): string
    if not childPath or childPath == "" then
        return basePath
    end

    return basePath .. "/" .. childPath
end

local function stripTraversal(text: string): string
    local previous
    repeat
        previous = text
        text = text:gsub("%.%.", "")
    until text == previous
    return text
end

function path.sanitizeFolder(value: unknown): string
    local text = tostring(value):gsub("\\", "/"):gsub('[:<>"|?*%c]', "")
    text = stripTraversal(text):gsub("/+", "/")
    return (text:gsub("^/+", ""))
end

function path.sanitizeFile(value: unknown): string
    local text = tostring(value):gsub("[/\\]", ""):gsub('[:<>"|?*%c]', "")
    return stripTraversal(text)
end

function path.basename(value: unknown): string
    return tostring(value):match("[^/\\]+$") or tostring(value)
end

function path.stripExtension(value: unknown, extension: string?): string
    if extension and extension ~= "" then
        local text = tostring(value)
        if text:sub(-#extension) == extension then
            return text:sub(1, -#extension - 1)
        end
        return text
    end

    local base = tostring(value):match("^(.+)%.%w+$")
    return base or tostring(value)
end

return path
