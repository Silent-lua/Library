

local variables = require(script.Parent.variables)
local filesystem = require(script.Parent.filesystem)
local log = require(script.Parent.log)
local path = require(script.Parent.path)
local paths = require(script.Parent.persistencePaths)
local atomic = require(script.Parent.persistenceWrite)

local persistenceConfig = {}

type PersistedControl = {
    value: unknown,
    flag: string?,
    _canBeNil: boolean?,
    _serialize: ((PersistedControl) -> unknown)?,
    _deserialize: ((PersistedControl, unknown) -> ())?,
    Set: (PersistedControl, unknown) -> (),
}

type ConfigWindow = {
    controls: { [string]: PersistedControl },
    configuration: {
        fileName: string?,
        customFolder: string?,
    },
    name: string,
    _loading: boolean?,
    _loadedConfig: { [string]: unknown }?,
    _loadedConfigPath: string?,
}

function persistenceConfig.getPath(window: ConfigWindow, name: unknown?): (string?, string?)
    return paths.getConfigPath(window, name)
end

function persistenceConfig.save(window: ConfigWindow, name: unknown?): boolean
    local dir, fullPath = persistenceConfig.getPath(window, name)
    if not dir or not fullPath then
        log.warn("Library: configuration name '" .. tostring(name) .. "' has no usable characters")
        return false
    end

    if typeof(filesystem.writefile) ~= "function" then
        return false
    end

    local flags: { [string]: unknown } = {}
    for flag, control in window.controls do
        local ok, value = pcall(function()
            local serialize = control._serialize
            if serialize then
                return serialize(control)
            end
            return control.value
        end)
        if ok then
            flags[flag] = value
        else
            log.warn("Library: Failed to serialize flag '" .. tostring(flag) .. "' - " .. tostring(value))
        end
    end

    local loadedConfig = window._loadedConfig
    if loadedConfig and window._loadedConfigPath == fullPath then
        for flag, value in loadedConfig do
            if window.controls[flag] == nil then
                flags[flag] = value
            end
        end
    end

    local encodeSuccess, encoded = pcall(variables.httpService.JSONEncode, variables.httpService, flags)
    if not encodeSuccess then
        log.warn("Library: Failed to encode configuration - " .. tostring(encoded))
        return false
    end

    local ok, err = pcall(function()
        atomic.write(dir, fullPath, encoded)
    end)

    if not ok then
        log.warn("Library: Failed to save configuration - " .. tostring(err))
        return false
    end

    if window._loadedConfigPath == nil or window._loadedConfigPath == fullPath then
        window._loadedConfig = flags
        window._loadedConfigPath = fullPath
    end

    return true
end

local function decodeFile(fullPath: string): ({ [string]: unknown }?, string?)
    if not filesystem.isfile(fullPath) then
        return nil, nil
    end

    local readOk, contents = pcall(filesystem.readfile, fullPath)
    if not readOk or type(contents) ~= "string" then
        log.warn("Library: Failed to read configuration file")
        return nil, nil
    end

    local decodeOk, parsed = pcall(variables.httpService.JSONDecode, variables.httpService, contents)

    if not decodeOk or type(parsed) ~= "table" then
        return nil, contents
    end

    return parsed :: { [string]: unknown }, contents
end

local function backupPathFor(fullPath: string): string
    local stem = path.stripExtension(fullPath, ".rfld")
    local candidate = stem .. " (Incorrect Format).rfld"
    local index = 2
    while index <= 100 and filesystem.isfile(candidate) do
        candidate = stem .. " (Incorrect Format " .. index .. ").rfld"
        index += 1
    end
    return candidate
end

function persistenceConfig.load(window: ConfigWindow, name: unknown?): boolean
    local dir, fullPath = persistenceConfig.getPath(window, name)
    if not dir or not fullPath then
        log.warn("Library: configuration name '" .. tostring(name) .. "' has no usable characters")
        return false
    end

    if typeof(filesystem.isfile) ~= "function" then
        return false
    end

    local parsedFlags, raw = decodeFile(fullPath)

    if not parsedFlags and filesystem.isfile(fullPath) then
        local parked, parkedRaw = decodeFile(atomic.tempPathFor(fullPath))
        if parked and parkedRaw then
            parsedFlags = parked
            pcall(atomic.write, dir, fullPath, parkedRaw)
        end
    end

    if not parsedFlags then
        if raw then
            log.warn("Library: Configuration file has an invalid format, backing up and resetting")
            local backupPath = backupPathFor(fullPath)
            pcall(function()
                filesystem.ensureDir(dir)
                filesystem.writefile(backupPath, raw)
                filesystem.delfile(fullPath)
            end)
        end
        return false
    end

    local flags = parsedFlags :: { [string]: unknown }
    local wasLoading = window._loading
    window._loading = true
    local applyOk, applyErr = pcall(function()
        for flag, control in window.controls do
            persistenceConfig.applyTo(control, flags[flag])
        end
    end)
    window._loading = wasLoading
    if not applyOk then
        log.warn("Library: Failed to apply configuration - " .. tostring(applyErr))
    end

    window._loadedConfig = flags
    window._loadedConfigPath = fullPath

    return true
end

function persistenceConfig.applyTo(control: PersistedControl, value: unknown)
    if value == nil and not control._canBeNil then
        return
    end
    local ok, err = pcall(function()
        local deserialize = control._deserialize
        if deserialize then
            deserialize(control, value)
        else
            control:Set(value)
        end
    end)
    if not ok then
        log.warn("Library: Failed to restore flag '" .. tostring(control.flag) .. "' - " .. tostring(err))
    end
end

function persistenceConfig.list(window: ConfigWindow): { string }
    local dir = persistenceConfig.getPath(window)

    local names: { string } = {}
    if not dir then
        return names
    end
    local ok, files = pcall(filesystem.listfiles, dir)
    if not ok or type(files) ~= "table" then
        return names
    end

    for _, filePath in files do
        local file = path.basename(filePath)
        if file:sub(-5) == ".rfld" then
            local base = path.stripExtension(file, ".rfld")
            if base and base ~= "" and not base:find(" %(Incorrect Format[^%)]*%)$") then
                table.insert(names, base)
            end
        end
    end

    table.sort(names)
    return names
end

function persistenceConfig.delete(window: ConfigWindow, name: unknown): boolean
    if type(name) ~= "string" or name == "" then
        return false
    end

    local _, fullPath = persistenceConfig.getPath(window, name)
    if not fullPath then
        return false
    end
    if typeof(filesystem.isfile) ~= "function" or not filesystem.isfile(fullPath) then
        return false
    end

    pcall(filesystem.delfile, atomic.tempPathFor(fullPath))

    return (pcall(filesystem.delfile, fullPath))
end

return persistenceConfig
