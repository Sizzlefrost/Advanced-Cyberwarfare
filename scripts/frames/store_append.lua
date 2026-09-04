local util = include("modules/util")

local storeFile = include("sim/units/store")
local oldCreateStoreItems = storeFile.createStoreItems
function storeFile.createStoreItems( store, storeUnit, sim, ... )
    local diff = sim._params.difficultyOptions
    if diff and not diff.ACW_frames_enabled then
        return oldCreateStoreItems( store, storeUnit, sim, ... )
    end

    -- as a precaution, let's not add too many defs. Over 30% of all possible wares is too many wares.
    local frame_wares_max = 0.1
    local total_wares = #store.itemList
    -- util.shuffle calls RNG a lot of times
    -- so we make our own generator instance for the shuffle, using the seed of the sim, and restoring sim to its prior seed
    -- functionally, we just make a temporary copy of the game's RNG to not mess with the original
    local seed = sim._seed
    local RNG = include("modules/rand").createGenerator( sim:nextRand() )
    sim._seed = seed

    -- now we want to get a list of the frames, shuffle it, and mark a bunch of entries for deletion, if necessary
    local frames_original = include(SCRIPT_PATHS.advanced_cyberwarfare.."/frames/framedefs")
    local frames = {}
    for i, frame in pairs(frames_original) do
        if not frame.do_not_sell then
            table.insert(frames, frame)
        end
    end
    util.shuffle( frames, function(i)
        return RNG:nextInt( 1, i )
    end )
    log:write("LOG_SPAM", "[ACW-STORE] Detected ["..#frames.."] frames, with boundary at ["..math.ceil(total_wares * frame_wares_max).."].")
    while #frames > (total_wares * frame_wares_max) do
        -- pop an entry from the table
        local gone = frames[#frames]
        --log:write("LOG_SPAM", "[ACW-STORE] Preliminary removal: "..gone.name)
        frames[#frames] = nil
    end
    -- and transfer the deleted entries to the store itself
    for id, item in pairs(store.itemList) do
        if item.traits and item.traits.SLF_incogFrame then 
            -- this is usually used to remove original items when modded ones override them
            -- we'll use it to remove frames as well
            local found = false
            for i, frame in pairs(frames) do
                if frame.name == item.traits.SLF_incogFrame then
                    found = true
                end
            end

            if not found then
                log:write("LOG_SPAM", "[ACW-STORE] Frame removed: "..item.traits.SLF_incogFrame)
                item.markedForDeletion = true
            else
                --log:write("LOG_SPAM", "[ACW-STORE] Frame retained: "..item.traits.SLF_incogFrame)
            end
        end
    end

    return oldCreateStoreItems( store, storeUnit, sim, ... )
end
