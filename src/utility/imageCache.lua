

local filesystem = require(script.Parent.filesystem)
local path = require(script.Parent.path)
local variables = require(script.Parent.variables)
local constants = require(script.Parent.constants)

export type RewriteMap = { [number]: string }
export type CacheSettledCallback = (failed: number) -> ()
export type PreloadCallback = CacheSettledCallback
export type AvatarCallback = (uri: string) -> ()
export type OnCachedCallback = (id: number) -> ()
export type ThumbnailEntry = {
    state: string?,
    imageUrl: string?,
}
export type ThumbnailResponse = {
    data: { ThumbnailEntry }?,
}
local imageCache = {}

local cacheRoot = variables.fileSystemManager:getRootFolder()
local cacheFolder = variables.fileSystemManager:getAssetsFolder()
local assetResolver = variables.assetResolver

local assetBase = "https://raw.githubusercontent.com/LibrarySoftwareLtd/Library-gen2/main/assets/"
local headshotPx = 48
local thumbEndpoint =
    "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=%dx%d&format=Png&isCircular=false"

local manifest: { [number]: string } = {}
for _, id in constants.icons do
    local iconId = id :: number
    manifest[iconId] = assetBase .. tostring(iconId) .. ".png"
end
local manifestSize = 0
for _ in manifest do
    manifestSize += 1
end

imageCache.rewrites = {} :: RewriteMap
imageCache.onCached = nil :: OnCachedCallback?

local pngMagic = "\137PNG\r\n\26\n"

local function cacheFile(filePath: string, url: string): string?
    if type(getfenv().getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
        return nil
    end
    if not filesystem.isfile(filePath) then
        pcall(filesystem.ensureFolder, cacheRoot)
        pcall(filesystem.ensureFolder, cacheFolder)
        local body = assetResolver:getAssetContentFromUrl(url, filePath, false)
        if not body or string.sub(body, 1, 8) ~= pngMagic then
            return nil
        end
        if not pcall(filesystem.writefile, filePath, body) then
            return nil
        end
    end
    local ok, uri = pcall(getfenv().getcustomasset, filePath)
    return if ok and type(uri) == "string" then uri else nil
end

local function avatarPath(userId: number): string
    return path.join(cacheFolder, "avatar_" .. tostring(userId) .. ".png")
end

local function decodeThumbnailUrl(body: string): string?
    local decodeOk, parsed = pcall(function()
        return variables.httpService:JSONDecode(body)
    end)
    if not decodeOk or type(parsed) ~= "table" then
        return nil
    end

    local data = (parsed :: ThumbnailResponse).data
    if type(data) ~= "table" then
        return nil
    end

    local entry = data[1]
    if type(entry) ~= "table" then
        return nil
    end

    local thumbnail = entry :: ThumbnailEntry
    if thumbnail.state == "Completed" and type(thumbnail.imageUrl) == "string" then
        return thumbnail.imageUrl
    end

    return nil
end

local function fetchAvatar(userId: number): string?
    local cdnUrl: string? = nil
    for attempt = 1, 4 do
        local body = assetResolver:getAssetContentFromUrl(
            string.format(thumbEndpoint, userId, headshotPx, headshotPx),
            "avatar:" .. tostring(userId),
            attempt > 1
        )
        if body then
            local imageUrl = decodeThumbnailUrl(body)
            if imageUrl then
                cdnUrl = imageUrl
                break
            end
        end
        if attempt < 4 then
            task.wait(0.3)
        end
    end
    if not cdnUrl then
        return nil
    end

    return cacheFile(avatarPath(userId), cdnUrl)
end

local pendingAvatars: { [number]: { AvatarCallback } } = {}
local failedAvatars: { [number]: boolean } = {}

function imageCache.preload(onSettled: PreloadCallback?): (boolean, number)
    local env = getfenv()
    if type(env.getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
        if onSettled then
            task.defer(onSettled, manifestSize)
        end
        return false, manifestSize
    end

    local rewrites = imageCache.rewrites
    table.clear(rewrites)

    local function settle()
        if not onSettled then
            return
        end
        local failed = 0
        for id in manifest do
            if not rewrites[id] then
                failed += 1
            end
        end
        onSettled(failed)
    end

    local pending, missing = 0, 0
    local spawning = true
    for id, url in manifest do
        local filePath = path.join(cacheFolder, tostring(id) .. ".png")
        local uri: string? = nil
        if filesystem.isfile(filePath) then
            local ok, res = pcall(env.getcustomasset, filePath)
            uri = if ok and type(res) == "string" then res else nil
        end
        if uri then
            rewrites[id] = uri
        else
            missing += 1
            pending += 1
            task.spawn(function()
                local cached = cacheFile(filePath, url)
                if cached then
                    rewrites[id] = cached
                    if imageCache.onCached then
                        pcall(imageCache.onCached, id)
                    end
                end
                pending -= 1
                if pending == 0 and not spawning then
                    settle()
                end
            end)
        end
    end

    spawning = false
    if pending == 0 then
        settle()
    end

    return missing == 0, missing
end

function imageCache.avatar(userId: unknown, onReady: AvatarCallback?): string
    if type(userId) ~= "number" then
        return ""
    end

    if typeof(filesystem.isfile) ~= "function" then
        return ""
    end

    local filePath = avatarPath(userId)
    if filesystem.isfile(filePath) then
        local ok, uri = pcall(getfenv().getcustomasset, filePath)
        if ok and type(uri) == "string" then
            return uri
        end
    end

    if failedAvatars[userId] then
        return ""
    end

    local waiting = pendingAvatars[userId]
    if waiting then
        if onReady then
            table.insert(waiting, onReady)
        end
        return ""
    end

    if onReady then
        pendingAvatars[userId] = { onReady }
        task.spawn(function()
            local uri = fetchAvatar(userId)
            local callbacks = pendingAvatars[userId]
            pendingAvatars[userId] = nil
            if not uri then
                failedAvatars[userId] = true
                return
            end
            if callbacks then
                for _, callback in callbacks do
                    pcall(callback, uri)
                end
            end
        end)
    end

    return ""
end

return imageCache
