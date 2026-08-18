-- next-track.lua
-- Exposes the next track in the queue to shell widgets via:
--   cliamp plugins call next-track next
-- Read-only: no permissions required. Returns a JSON object:
--   {"shuffle": bool, "track": {title, artist, album, ...} | null}
-- When shuffle is on the next track is unpredictable, so track is null.

local p = plugin.register({
    name = "next-track",
    type = "hook",
    version = "1.0.0",
    description = "Expose the next track in the queue for shell widgets",
})

p:command("next", function()
    local queue = cliamp.queue.list()
    local current = cliamp.queue.current()
    local shuffle = cliamp.player.shuffle()
    local track = nil

    if not shuffle and queue and current >= 0 then
        -- Prefer the first play-next (queued) item after the current track.
        for i = 1, #queue do
            local item = queue[i]
            if item.queued and item.index > current then
                track = item
                break
            end
        end
        -- Otherwise the next entry in the playlist (0-based current -> 1-based list).
        if not track and current + 1 < #queue then
            track = queue[current + 2]
        end
    end

    return cliamp.json.encode({ shuffle = shuffle, track = track })
end)
