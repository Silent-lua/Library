


local filesystem = require(script.Parent.filesystem)

local persistenceWrite = {}

local parkedExtension = ".saving"

function persistenceWrite.tempPathFor(fullPath: string): string
    return fullPath .. parkedExtension
end

function persistenceWrite.write(dir: string, fullPath: string, contents: string)
    local tempPath = persistenceWrite.tempPathFor(fullPath)

    filesystem.ensureDir(dir)
    filesystem.writefile(tempPath, contents)

    if filesystem.readfile(tempPath) ~= contents then
        error("parked copy did not write cleanly")
    end

    filesystem.writefile(fullPath, contents)
    pcall(filesystem.delfile, tempPath)
end

return persistenceWrite
