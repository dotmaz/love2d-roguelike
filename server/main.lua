local enet = require("enet")

local host = enet.host_create("*:6789")
local players = {} -- Store player positions

function love.update(dt)
    local event = host:service(100)
    while event do
        if event.type == "receive" then
            local data = event.data
            local id = tostring(event.peer:connect_id()) -- Use peer as the unique ID

            -- Update player position
            local x, y, radians = data:match("([%-?%d%.]+),([%-?%d%.]+),([%-?%d%.]+)")
            if x and y and radians then
                players[id] = { x = tonumber(x), y = tonumber(y), radians = tonumber(radians) }
                -- Broadcast updated position to all clients
                for i = 1, host:peer_count() do
                    local peer = host:get_peer(i)
                    if peer and peer:state() == "connected" then
                        peer:send(id .. "," .. x .. "," .. y .. "," .. radians)
                    end
                end
            end
        elseif event.type == "connect" then
            print(event.peer, "connected.")
            players[tostring(event.peer:connect_id())] = { x = 0, y = 0, radians = 0 }
        elseif event.type == "disconnect" then
            print(event.peer, "disconnected.")
            players[tostring(event.peer:connect_id())] = nil
        end
        event = host:service()
    end
end
