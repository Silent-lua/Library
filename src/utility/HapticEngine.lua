


local variables = require(script.Parent.variables)

local hapticEngine = {}

hapticEngine.enabled = false

type HapticTypes = {
    click: Enum.HapticEffectType?,
    notify: Enum.HapticEffectType?,
}

local types: HapticTypes = {}
local supported, resolvedTypes = pcall(function()
    Instance.new("HapticEffect"):Destroy()
    return {
        click = Enum.HapticEffectType.UIHover,
        notify = Enum.HapticEffectType.UIClick,
    }
end)
if supported then
    types = resolvedTypes
end

local effects: { [Enum.HapticEffectType]: Instance } = {}
local container: Instance? = nil

function hapticEngine.setContainer(target: Instance?)
    container = target
end

function hapticEngine.releaseContainer(target: Instance?)
    if target == nil or container == target then
        container = nil
    end
end

local function containerFor(): Instance
    if container and container.Parent then
        return container
    end
    return variables.guiContainer
end

local function effectFor(hapticType: Enum.HapticEffectType): Instance?
    local effect = effects[hapticType]
    if effect and effect.Parent then
        return effect
    end
    local ok, made = pcall(Instance.new, "HapticEffect")
    if not ok then
        return nil
    end
    local hapticEffect = made :: any
    hapticEffect.Type = hapticType
    local parented = pcall(function()
        made.Parent = containerFor()
    end)
    if not parented then
        made:Destroy()
        return nil
    end
    effects[hapticType] = made
    return made
end

local function play(hapticType: Enum.HapticEffectType?)
    if not hapticType or not hapticEngine.enabled then
        return
    end
    local effect = effectFor(hapticType)
    if effect then
        local hapticEffect = effect :: any
        pcall(hapticEffect.Play, effect)
    end
end

function hapticEngine.click()
    play(types.click)
end

function hapticEngine.notify()
    play(types.notify)
end

function hapticEngine.setEnabled(state: boolean?)
    hapticEngine.enabled = state and true or false
    if not hapticEngine.enabled then
        hapticEngine.teardown()
    end
end

function hapticEngine.teardown()
    for hapticType, effect in effects do
        pcall(effect.Destroy, effect)
        effects[hapticType] = nil
    end
end

return hapticEngine
