


local variables = require(script.Parent.variables)
local log = require(script.Parent.log)

local locale = {}

export type LocaleToken = { [any]: string }
export type Translator = (source: string, localeId: string) -> string?
export type TranslationTables = { [string]: { [string]: string } }

locale.strings = {} :: TranslationTables

locale.current = "en"
locale.translator = nil :: Translator?

local tokenTag = {}

local function languageOf(id: string): string
    return string.match(id, "^(%a+)") or id
end

function locale.t(source: unknown): unknown
    if type(source) ~= "string" or source == "" then
        return source
    end
    return { [tokenTag] = source }
end

function locale.isToken(value: unknown): boolean
    return type(value) == "table" and type((value :: { [any]: unknown })[tokenTag]) == "string"
end

function locale.sourceOf(token: LocaleToken): string
    return token[tokenTag]
end

function locale.resolve(source: unknown): any
    if type(source) ~= "string" then
        return source
    end

    if locale.translator then
        local ok, translated = pcall(locale.translator, source, locale.current)
        if ok and type(translated) == "string" and translated ~= "" then
            return translated
        end
    end

    local exact = locale.strings[locale.current]
    if exact and exact[source] then
        return exact[source]
    end

    local language = locale.strings[languageOf(locale.current)]
    if language and language[source] then
        return language[source]
    end

    return source
end

function locale.register(tables: TranslationTables?)
    if type(tables) ~= "table" then
        return
    end
    for id, entries in tables do
        if type(id) == "string" and type(entries) == "table" then
            id = string.lower(id)
            local target = locale.strings[id]
            if not target then
                target = {}
                locale.strings[id] = target
            end
            for source, translated in entries do
                if type(source) == "string" and type(translated) == "string" then
                    target[source] = translated
                else
                    log.warn(`Library: skipping a '{id}' translation, entries must be string to string.`)
                end
            end
        end
    end
end

function locale.setActive(localeId: string?): string
    locale.current = if type(localeId) == "string" and localeId ~= "" then string.lower(localeId) else "en"
    return locale.current
end

function locale.detect(): string
    local id = variables.localizationService.RobloxLocaleId
    if type(id) == "string" and id ~= "" then
        return string.lower(id)
    end
    return "en"
end

return locale
