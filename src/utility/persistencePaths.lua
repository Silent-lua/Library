

local variables = require(script.Parent.variables)
local path = require(script.Parent.path)

local paths = {}

type ConfigWindow = {
    configuration: {
        fileName: string?,
        customFolder: string?,
    },
    name: string,
}

function paths.getConfigPath(window: ConfigWindow, name: unknown?): (string?, string?)
    local dir = variables.fileSystemManager:getPath("Configurations")
    if window.configuration.customFolder then
        dir = path.join(dir, path.sanitizeFolder(window.configuration.customFolder))
    end
    if name ~= nil then
        local safe = path.sanitizeFile(name)
        if safe == "" then
            return nil, nil
        end
        return dir, path.join(dir, safe .. ".rfld")
    end
    local safe = path.sanitizeFile(window.configuration.fileName or window.name)
    if safe == "" then
        safe = path.sanitizeFile(window.name)
    end
    if safe == "" then
        safe = "Configuration"
    end
    return dir, path.join(dir, safe .. ".rfld")
end

function paths.getSettingsPath(): (string, string)
    local dir = variables.fileSystemManager:getPath("Settings")
    return dir, path.join(dir, "Library.rfld")
end

return paths
