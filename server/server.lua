-- Car Radio Server Side
-- Keeps radio state per vehicle plate and broadcasts updates to all clients.
-- The server stores the start timestamp so every client can seek to the same
-- playback position when switching between inside/outside audio.

local vehicleRadios = {}

local function Debug(message)
    if Config.Debug then
        print("^2[CarRadio]^7 " .. tostring(message))
    end
end

local function NormalizePlate(plate)
    if not plate then return nil end
    return string.gsub(tostring(plate), "^%s*(.-)%s*$", "%1")
end

local function ClampVolume(volume)
    volume = tonumber(volume) or Config.DefaultVolume or 0.5
    local minVolume = Config.MinVolume or 0.0
    local maxVolume = Config.MaxVolume or 1.0

    if volume < minVolume then volume = minVolume end
    if volume > maxVolume then volume = maxVolume end

    return volume
end

local function GetPlaybackTime(state)
    if not state then return 0.0 end

    local currentTime = tonumber(state.currentTime) or 0.0
    if state.isPlaying ~= true then
        return currentTime
    end

    local startedAt = tonumber(state.startedAt) or 0
    if startedAt <= 0 then
        return currentTime
    end

    local elapsed = os.time() - startedAt
    if elapsed < 0 then elapsed = 0 end

    return currentTime + elapsed
end

local function BuildState(vehicleId, url, isPlaying, owner, volume, currentTime)
    return {
        vehicleId = vehicleId,
        currentUrl = url,
        isPlaying = isPlaying == true,
        currentTime = tonumber(currentTime) or 0.0,
        startedAt = isPlaying == true and os.time() or nil,
        serverTime = os.time(),
        owner = owner,
        volume = ClampVolume(volume)
    }
end

local function AttachServerTime(state)
    if state then
        state.serverTime = os.time()
    end
    return state
end

local function SendRadioState(target, state)
    TriggerClientEvent('carRadio:updateRadio', target, AttachServerTime(state))
end

local function SendAllRadioStates(target)
    local now = os.time()
    for _, state in pairs(vehicleRadios) do
        state.serverTime = now
    end
    TriggerClientEvent('carRadio:updateAllRadios', target, vehicleRadios)
end

RegisterServerEvent('carRadio:setRadio')
AddEventHandler('carRadio:setRadio', function(vehicleId, url)
    local src = source
    vehicleId = NormalizePlate(vehicleId)

    if not vehicleId or vehicleId == "" or not url or url == "" then
        return
    end

    local previous = vehicleRadios[vehicleId]

    -- Do not restart or replace the current song until Stop is pressed first.
    if previous and previous.currentUrl and previous.currentUrl ~= "" then
        TriggerClientEvent('carRadio:playRejected', src, 'Stop the current song before playing a new one.')
        SendRadioState(src, previous)
        return
    end

    Debug(("Player %s set radio for vehicle %s to: %s"):format(src, vehicleId, url))

    local state = BuildState(vehicleId, url, true, src, previous and previous.volume or Config.DefaultVolume, 0.0)
    vehicleRadios[vehicleId] = state

    SendRadioState(-1, state)
end)

RegisterServerEvent('carRadio:toggleRadio')
AddEventHandler('carRadio:toggleRadio', function(vehicleId, isPlaying)
    vehicleId = NormalizePlate(vehicleId)
    if not vehicleId or not vehicleRadios[vehicleId] then return end

    local state = vehicleRadios[vehicleId]

    if isPlaying == true then
        state.isPlaying = true
        state.startedAt = os.time()
    else
        state.currentTime = GetPlaybackTime(state)
        state.isPlaying = false
        state.startedAt = nil
    end

    state.owner = source

    Debug(("Vehicle %s radio toggled: %s at %.2fs"):format(vehicleId, tostring(isPlaying), tonumber(state.currentTime) or 0.0))
    SendRadioState(-1, state)
end)

RegisterServerEvent('carRadio:setVolume')
AddEventHandler('carRadio:setVolume', function(vehicleId, volume)
    vehicleId = NormalizePlate(vehicleId)
    if not vehicleId or not vehicleRadios[vehicleId] then return end

    vehicleRadios[vehicleId].volume = ClampVolume(volume)
    vehicleRadios[vehicleId].owner = source

    Debug(("Vehicle %s radio volume changed to: %.2f"):format(vehicleId, vehicleRadios[vehicleId].volume))
    SendRadioState(-1, vehicleRadios[vehicleId])
end)

RegisterServerEvent('carRadio:stopRadio')
AddEventHandler('carRadio:stopRadio', function(vehicleId)
    vehicleId = NormalizePlate(vehicleId)
    if not vehicleId then return end

    Debug(("Vehicle %s radio stopped by player %s"):format(vehicleId, source))

    vehicleRadios[vehicleId] = nil

    SendRadioState(-1, {
        vehicleId = vehicleId,
        currentUrl = nil,
        isPlaying = false,
        currentTime = 0,
        startedAt = nil,
        serverTime = os.time(),
        owner = source,
        volume = Config.DefaultVolume or 0.5
    })
end)

RegisterServerEvent('carRadio:requestState')
AddEventHandler('carRadio:requestState', function(vehicleId)
    local src = source
    vehicleId = NormalizePlate(vehicleId)

    if vehicleId and vehicleRadios[vehicleId] then
        SendRadioState(src, vehicleRadios[vehicleId])
    else
        SendRadioState(src, {
            vehicleId = vehicleId,
            currentUrl = nil,
            isPlaying = false,
            currentTime = 0,
            startedAt = nil,
            serverTime = os.time(),
            owner = nil,
            volume = Config.DefaultVolume or 0.5
        })
    end
end)

RegisterServerEvent('carRadio:requestAllStates')
AddEventHandler('carRadio:requestAllStates', function()
    SendAllRadioStates(source)
end)

exports('GetRadioState', function(vehicleId)
    vehicleId = NormalizePlate(vehicleId)
    if vehicleId then
        return vehicleRadios[vehicleId]
    end

    return vehicleRadios
end)
