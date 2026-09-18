

local services = require(script.Parent.services)

export type RuntimeState = {
    secureMode: boolean,
    coreGui: CoreGui,
    workspace: Workspace,
    runService: RunService,
    userInputService: UserInputService,
    guiService: GuiService,
    localPlayer: Player?,
    tweenService: TweenService,
    httpService: HttpService,
    textService: TextService,
    replicatedStorage: ReplicatedStorage,
    localizationService: LocalizationService,
    guiContainer: Instance,
}

local runtime = {} :: RuntimeState

runtime.secureMode = (function()
    if typeof(getgenv) ~= "function" then
        return false
    end
    local ok, val = pcall(function()
        return getgenv().LIBRARY_SECURE
    end)
    return ok and val == true
end)()

runtime.coreGui = services.getService("CoreGui") :: CoreGui
runtime.workspace = services.getService("Workspace") :: Workspace
runtime.runService = services.getService("RunService") :: RunService
runtime.userInputService = services.getService("UserInputService") :: UserInputService
runtime.guiService = services.getService("GuiService") :: GuiService
runtime.localPlayer = (services.getService("Players") :: Players).LocalPlayer
runtime.tweenService = services.getService("TweenService") :: TweenService
runtime.httpService = services.getService("HttpService") :: HttpService
runtime.textService = services.getService("TextService") :: TextService
runtime.replicatedStorage = services.getService("ReplicatedStorage") :: ReplicatedStorage
runtime.localizationService = services.getService("LocalizationService") :: LocalizationService
runtime.guiContainer = (function(): Instance
    if runtime.runService:IsStudio() then
        local player = runtime.localPlayer
        if player then
            return player.PlayerGui
        end
        return runtime.coreGui
    end
    if typeof(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and container then
            return container
        end
    end
    return runtime.coreGui
end)()

return runtime
