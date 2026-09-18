


local function lockable<T>(class: T): T
    local target = class :: any

    function target:Lock(reason: string?)
        self.window:_setElementLocked(self, true, reason)
    end

    function target:Unlock()
        self.window:_setElementLocked(self, false)
    end

    function target:IsLocked(): boolean
        return self.locked == true
    end

    return class
end

return lockable
