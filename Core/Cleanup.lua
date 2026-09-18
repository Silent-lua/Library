-- Silent Framework | Core/Cleanup.lua
-- Responsabilidad: Recolección de basura determinista (Janitor Pattern).

local Cleanup = {}
Cleanup.__index = Cleanup

function Cleanup.new()
    return setmetatable({ _tasks = {} }, Cleanup)
end

function Cleanup:Add(task, methodName)
    if not task then return task end
    table.insert(self._tasks, { Task = task, Method = methodName })
    return task
end

function Cleanup:DoCleanup()
    for i = #self._tasks, 1, -1 do
        local taskData = self._tasks[i]
        local taskItem = taskData.Task
        local method = taskData.Method

        pcall(function()
            if type(taskItem) == "function" then
                taskItem()
            elseif typeof(taskItem) == "RBXScriptConnection" then
                taskItem:Disconnect()
            elseif type(taskItem) == "table" then
                if method and type(taskItem[method]) == "function" then
                    taskItem[method](taskItem)
                elseif type(taskItem.Destroy) == "function" then
                    taskItem:Destroy()
                elseif type(taskItem.Disconnect) == "function" then
                    taskItem:Disconnect()
                end
            elseif typeof(taskItem) == "Instance" then
                taskItem:Destroy()
            end
        end)
        self._tasks[i] = nil
    end
end

function Cleanup:Destroy()
    self:DoCleanup()
end

return Cleanup
