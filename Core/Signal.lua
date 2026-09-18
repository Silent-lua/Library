-- Silent Framework | Core/Signal.lua
-- Responsabilidad: Manejo de eventos en memoria y comunicación entre componentes.

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, callback)
    local self = setmetatable({}, Connection)
    self.Signal = signal
    self.Callback = callback
    self.Connected = true
    return self
end

function Connection:Disconnect()
    if not self.Connected then return end
    self.Connected = false
    
    for i, conn in ipairs(self.Signal._connections) do
        if conn == self then
            table.remove(self.Signal._connections, i)
            break
        end
    end
end

function Signal.new()
    return setmetatable({ _connections = {} }, Signal)
end

function Signal:Connect(callback)
    local connection = Connection.new(self, callback)
    table.insert(self._connections, connection)
    return connection
end

function Signal:Wait()
    local running = coroutine.running()
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        task.spawn(running, ...)
    end)
    return coroutine.yield()
end

function Signal:Fire(...)
    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            task.spawn(connection.Callback, ...)
        end
    end
end

function Signal:Destroy()
    for _, connection in ipairs(self._connections) do
        connection.Connected = false
    end
    table.clear(self._connections)
end

return Signal
