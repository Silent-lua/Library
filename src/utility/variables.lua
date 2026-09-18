

local runtime = require(script.Parent.runtime)
local constants = require(script.Parent.constants)
local log = require(script.Parent.log)
local fileSystemManager = require(script.Parent.filesystemManager)
local assetResolver = require(script.Parent.assetResolver)
local fontManager = require(script.Parent.fontManager)

type RuntimeState = runtime.RuntimeState
type FileSystemManager = fileSystemManager.FileSystemManager
type AssetResolver = assetResolver.AssetResolver
type FontManager = fontManager.FontManager

export type VariablesState = RuntimeState & {
    fallbackFont: Font,
    fileSystemManager: FileSystemManager,
    assetResolver: AssetResolver,
    fontManager: FontManager,
    setFallbackFont: (font: Enum.Font | Font) -> (),
    brandFont: (weight: Enum.FontWeight?) -> Font,
}

local variables = table.clone(runtime) :: VariablesState
log.setSecureModeSource(function()
    return variables.secureMode
end)

variables.fallbackFont = Font.fromEnum(Enum.Font.BuilderSans)

variables.fileSystemManager = fileSystemManager.new()
variables.assetResolver =
    assetResolver.new(true, assetResolver.Enum.AssetDownloadUrl.RoProxyDownloadUrl) :: AssetResolver
variables.fontManager = fontManager.new(
    variables.fileSystemManager:getAssetsFolder("fonts"),
    false,
    true,
    assetResolver.Enum.AssetDownloadUrl.RoProxyDownloadUrl,
    {
        saveToDisk = true,
        skipCache = false,
        fallbackFont = variables.fallbackFont,
    }
) :: FontManager

function variables.setFallbackFont(font: Enum.Font | Font)
    if typeof(font) == "EnumItem" then
        font = Font.fromEnum(font)
    end
    if typeof(font) == "Font" then
        variables.fallbackFont = font
        variables.fontManager.defaultOptions.fallbackFont = font
    end
end

function variables.brandFont(weight: Enum.FontWeight?): Font
    if variables.secureMode then
        return Font.new(variables.fallbackFont.Family, weight)
    end
    return Font.new(constants.fontAsset, weight)
end

return variables
