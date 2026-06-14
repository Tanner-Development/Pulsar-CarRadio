-- Car Radio Client Side
-- Vehicle-scoped radio audio:
--  * occupants hear full/clean local audio
--  * nearby outside players hear positional quieter audio
--  * outside audio gets louder when doors are open or windows are broken

--[[
MIT License

Copyright (c) 2026 James Peterson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]





local radioOpen = false
local currentVehicle = nil
local radioState = {
    vehicleId = nil,
    currentUrl = nil,
    isPlaying = false,
    currentTime = 0,
    owner = nil,
    volume = Config.DefaultVolume or 0.5
}

local radioStates = {}
local activeSounds = {}
local lastAllStateRequest = 0

local function Debug(message)
    if Config.Debug then
        print("^2[CarRadio]^7 " .. tostring(message))
    end
end

local function TrimPlate(plate)
    if not plate then return nil end
    return string.gsub(tostring(plate), "^%s*(.-)%s*$", "%1")
end

local function GetCurrentVehicle()
    return GetVehiclePedIsIn(PlayerPedId(), false)
end

local function GetCurrentVehiclePlate()
    local vehicle = GetCurrentVehicle()
    if vehicle == 0 then return nil end
    return TrimPlate(GetVehicleNumberPlateText(vehicle))
end

local function GetSoundId(vehicleId, mode)
    vehicleId = TrimPlate(vehicleId)
    if not vehicleId or vehicleId == "" then return nil end

    -- Keep inside and outside audio as separate xsound entries.
    -- This prevents a non-positional inside PlayUrl from getting stuck after exiting the car.
    mode = mode or "any"
    return ("carRadio_%s_%s"):format(vehicleId:gsub("%s+", "_"), tostring(mode))
end

local function GetLegacySoundId(vehicleId)
    vehicleId = TrimPlate(vehicleId)
    if not vehicleId or vehicleId == "" then return nil end
    return "carRadio_" .. vehicleId:gsub("%s+", "_")
end

local function XSoundCall(exportName, ...)
    if not exports or not exports["xsound"] then
        return false, nil
    end

    local ok, result = pcall(function(...)
        return exports["xsound"][exportName](exports["xsound"], ...)
    end, ...)

    if not ok then
        Debug(("xsound %s failed: %s"):format(tostring(exportName), tostring(result)))
        return false, nil
    end

    return true, result
end

local function XSoundExists(soundId)
    if not soundId then return false end
    local ok, exists = XSoundCall("soundExists", soundId)
    return ok and exists == true
end

local function ClampVolume(volume)
    volume = tonumber(volume) or Config.DefaultVolume or 0.5
    local minVolume = Config.MinVolume or 0.0
    local maxVolume = Config.MaxVolume or 1.0

    if volume < minVolume then volume = minVolume end
    if volume > maxVolume then volume = maxVolume end

    return volume
end


local function GetSyncedPlaybackTime(state)
    if not state then return 0.0 end

    local currentTime = tonumber(state.currentTime) or 0.0
    if state.isPlaying ~= true then
        return currentTime
    end

    local startedAt = tonumber(state.startedAt) or 0
    if startedAt <= 0 then
        return currentTime
    end

    -- FiveM client Lua does not expose the normal Lua os table.
    -- The server sends os.time() as serverTime, then the client advances it
    -- locally using GetGameTimer() so inside/outside swaps stay in sync.
    local serverTime = tonumber(state.serverTime) or startedAt
    local receivedAt = tonumber(state.clientReceivedAt) or GetGameTimer()
    local localElapsed = (GetGameTimer() - receivedAt) / 1000.0
    if localElapsed < 0 then localElapsed = 0 end

    local elapsed = (serverTime - startedAt) + localElapsed
    if elapsed < 0 then elapsed = 0 end

    return currentTime + elapsed
end

local function ApplyTimestamp(soundId, seconds)
    seconds = tonumber(seconds) or 0.0
    if seconds <= 0.25 then return end

    -- Some xsound builds need a short delay after PlayUrl/PlayUrlPos before seeking.
    SetTimeout(Config.SeekDelay or 350, function()
        if XSoundExists(soundId) then
            XSoundCall("setTimeStamp", soundId, seconds)
        end
    end)
end

local function DestroySoundId(soundId)
    if soundId and XSoundExists(soundId) then
        Debug("Stopping radio audio: " .. soundId)
        XSoundCall("Destroy", soundId)
    end
end

local function StopSound(vehicleId, mode)
    vehicleId = TrimPlate(vehicleId)
    if not vehicleId then return end

    if mode then
        DestroySoundId(GetSoundId(vehicleId, mode))

        local sound = activeSounds[vehicleId]
        if sound and sound.mode == mode then
            activeSounds[vehicleId] = nil
        end
        return
    end

    -- Destroy every possible sound id used by previous builds and by the split inside/outside mode.
    DestroySoundId(GetSoundId(vehicleId, "inside"))
    DestroySoundId(GetSoundId(vehicleId, "outside"))
    DestroySoundId(GetLegacySoundId(vehicleId))

    activeSounds[vehicleId] = nil
end

local function StopAllAudio()
    for vehicleId in pairs(activeSounds) do
        StopSound(vehicleId)
    end
end

local function FindVehicleByPlate(vehicleId)
    vehicleId = TrimPlate(vehicleId)
    if not vehicleId then return 0 end

    local playerVehicle = GetCurrentVehicle()
    if playerVehicle ~= 0 and TrimPlate(GetVehicleNumberPlateText(playerVehicle)) == vehicleId then
        return playerVehicle
    end

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) and TrimPlate(GetVehicleNumberPlateText(vehicle)) == vehicleId then
            return vehicle
        end
    end

    return 0
end

local function IsVehicleOpenOrBroken(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    -- Doors open/cracked open.
    for door = 0, 5 do
        local doorRatio = GetVehicleDoorAngleRatio(vehicle, door) or 0.0
        if doorRatio > (Config.DoorOpenAngleThreshold or 0.03) then
            return true
        end
    end

    -- Broken/busted windows. Not every vehicle has every index, so this is safe to check broadly.
    for window = 0, 7 do
        if not IsVehicleWindowIntact(vehicle, window) then
            return true
        end
    end

    return false
end


local function CalculateExteriorVolume(distance, range, baseVolume, masterVolume)
    distance = tonumber(distance) or range or 0.0
    range = tonumber(range) or 1.0
    baseVolume = tonumber(baseVolume) or 0.0
    masterVolume = ClampVolume(masterVolume)

    if range <= 0.0 or distance >= range then
        return 0.0
    end

    -- Manual falloff because some xsound builds keep PlayUrlPos too flat.
    -- Close to the car = base exterior volume. Near max range = almost silent.
    local minFullVolumeDistance = Config.ExteriorFullVolumeDistance or 2.0
    local usableDistance = math.max(distance - minFullVolumeDistance, 0.0)
    local usableRange = math.max(range - minFullVolumeDistance, 1.0)
    local falloff = 1.0 - (usableDistance / usableRange)

    if Config.ExteriorFalloffCurve == "linear" then
        -- keep linear
    else
        falloff = falloff * falloff
    end

    local volume = baseVolume * masterVolume * falloff

    if volume < (Config.ExteriorMinimumAudibleVolume or 0.01) then
        return 0.0
    end

    return volume
end

local function PlayOrUpdateSound(vehicleId, url, mode, vehicle, volume, distance, playbackTime)
    vehicleId = TrimPlate(vehicleId)
    if not vehicleId or not url or url == "" then return end

    mode = mode == "inside" and "inside" or "outside"
    local soundId = GetSoundId(vehicleId, mode)
    if not soundId then return end

    -- Important: kill the opposite mode first.
    -- Inside audio uses PlayUrl and is not positional; outside audio uses PlayUrlPos.
    -- If the inside id survives after exit, the player hears full volume everywhere.
    if mode == "inside" then
        StopSound(vehicleId, "outside")
    else
        StopSound(vehicleId, "inside")
    end

    local current = activeSounds[vehicleId]
    local mustRestart = not current or current.soundId ~= soundId or current.url ~= url or current.mode ~= mode or not XSoundExists(soundId)

    if mustRestart then
        DestroySoundId(soundId)

        if mode == "inside" then
            Debug(("Starting inside radio audio %s volume %.3f"):format(soundId, tonumber(volume) or 0.0))
            XSoundCall("PlayUrl", soundId, url, volume, false)
            ApplyTimestamp(soundId, playbackTime)
        else
            local coords = vehicle ~= 0 and DoesEntityExist(vehicle) and GetEntityCoords(vehicle) or GetEntityCoords(PlayerPedId())
            Debug(("Starting outside positional radio audio %s volume %.3f distance %.1f"):format(soundId, tonumber(volume) or 0.0, tonumber(distance) or 0.0))
            XSoundCall("PlayUrlPos", soundId, url, volume, coords, false)
            XSoundCall("Distance", soundId, distance)
            ApplyTimestamp(soundId, playbackTime)
        end

        activeSounds[vehicleId] = {
            soundId = soundId,
            url = url,
            mode = mode,
            lastPlaybackTime = playbackTime or 0.0
        }
    end

    if XSoundExists(soundId) then
        XSoundCall("setVolume", soundId, volume)

        if mode == "outside" and vehicle ~= 0 and DoesEntityExist(vehicle) then
            XSoundCall("Position", soundId, GetEntityCoords(vehicle))
            XSoundCall("Distance", soundId, distance)
        end
    end
end

local function UpdateAudioForState(state)
    if not state or not state.vehicleId then return end

    local vehicleId = TrimPlate(state.vehicleId)

    if not state.currentUrl or state.currentUrl == "" or not state.isPlaying then
        StopSound(vehicleId)
        return
    end

    local playerVehiclePlate = GetCurrentVehiclePlate()
    local vehicle = FindVehicleByPlate(vehicleId)
    local masterVolume = ClampVolume(state.volume)
    local playbackTime = GetSyncedPlaybackTime(state)

    -- Inside the same vehicle: clean/full local audio.
    if playerVehiclePlate == vehicleId then
        PlayOrUpdateSound(vehicleId, state.currentUrl, "inside", vehicle, (Config.InsideVolume or 0.5) * masterVolume, Config.InteriorDistance or 8.0, playbackTime)
        return
    end

    -- Outside nearby: positional/muffled audio from the vehicle.
    -- We manually calculate distance falloff so it gets quieter as players leave the car area.
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        local pedCoords = GetEntityCoords(PlayerPedId())
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(pedCoords - vehCoords)
        local maxRange = Config.ExteriorRange or Config.AudioRange or 35.0
        local openOrBroken = IsVehicleOpenOrBroken(vehicle)
        local range = openOrBroken and (Config.ExteriorOpenRange or maxRange) or (Config.ExteriorClosedRange or math.min(maxRange, 12.0))
        local baseExteriorVolume = openOrBroken and (Config.ExteriorOpenVolume or 0.22) or (Config.ExteriorClosedVolume or 0.045)

        if dist <= range then
            local volume = CalculateExteriorVolume(dist, range, baseExteriorVolume, masterVolume)

            if volume > 0.0 then
                PlayOrUpdateSound(vehicleId, state.currentUrl, "outside", vehicle, volume, range, playbackTime)
                return
            end
        end
    end

    -- Not inside the car and not close enough to hear exterior audio.
    StopSound(vehicleId)
end

local function RefreshAllAudio()
    local seen = {}

    for vehicleId, state in pairs(radioStates) do
        vehicleId = TrimPlate(vehicleId)
        seen[vehicleId] = true
        UpdateAudioForState(state)
    end

    for vehicleId in pairs(activeSounds) do
        if not seen[vehicleId] then
            StopSound(vehicleId)
        end
    end
end

local function CanControlVehicleRadio()
    local vehicle = GetCurrentVehicle()
    if vehicle == 0 then
        return false, "You must be in a vehicle"
    end

    if Config.OnlyDriverCanControl then
        local driverPed = GetPedInVehicleSeat(vehicle, -1)
        if driverPed ~= PlayerPedId() then
            return false, "Only the driver can control the radio"
        end
    end

    return true, nil
end

-- Get YouTube video ID from URL
function GetYouTubeVideoId(url)
    if not url or url == "" then return nil end

    local videoId = url:match("youtube.com/watch%?v=([%w-]+)") or
                    url:match("youtube.com/shorts/([%w-]+)") or
                    url:match("youtu.be/([%w-]+)") or
                    url:match("youtube.com/embed/([%w-]+)") or
                    url:match("youtube.com/v/([%w-]+)") or
                    url:match("youtube.com/%?.*v%=([%w-]+)") or
                    url:match("youtu%.be/([%w-]+)")

    return videoId
end

function GetYouTubeThumbnail(url)
    local videoId = GetYouTubeVideoId(url)
    if not videoId then return nil end
    return "https://img.youtube.com/vi/" .. videoId .. "/hqdefault.jpg"
end

function SendReactMessage(action, data)
    SendNUIMessage({
        type = action,
        data = data or {}
    })
end

RegisterCommand(Config.Command, function(source, args, rawCommand)
    local vehicle = GetCurrentVehicle()

    if vehicle == 0 then
        if Config.ShowMessages then
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"Car Radio", "You must be in a vehicle!"}
            })
        end
        return
    end

    currentVehicle = vehicle
    local plate = GetCurrentVehiclePlate()
    local state = plate and radioStates[plate] or nil
    radioState = state or radioState

    radioOpen = true
    SetNuiFocus(true, true)

    SendReactMessage('openRadio', {
        vehicleId = plate,
        currentUrl = state and state.currentUrl or "",
        isPlaying = state and state.isPlaying or false,
        thumbnail = state and state.currentUrl and GetYouTubeThumbnail(state.currentUrl) or "",
        volume = state and ClampVolume(state.volume) or ClampVolume(Config.DefaultVolume),
        uiPosition = Config.UIPosition,
        customFallback = Config.CustomFallbackImage
    })

    TriggerServerEvent('carRadio:requestState', plate)
end)

RegisterNUICallback('playRadio', function(data, cb)
    Debug("Play radio requested with URL: " .. (data.url or "nil"))

    local canControl, message = CanControlVehicleRadio()
    if not canControl then
        cb({success = false, message = message})
        return
    end

    currentVehicle = GetCurrentVehicle()
    local vehicleId = GetCurrentVehiclePlate()

    local existingState = vehicleId and radioStates[vehicleId] or nil
    if existingState and existingState.currentUrl and existingState.currentUrl ~= "" then
        cb({success = false, message = "Stop the current song before playing a new one."})
        return
    end

    local url = data.url
    if not url or url == "" then
        cb({success = false, message = "URL is empty"})
        return
    end

    local videoId = GetYouTubeVideoId(url)
    if not videoId then
        cb({success = false, message = "Invalid YouTube URL"})
        return
    end

    TriggerServerEvent('carRadio:setRadio', vehicleId, url)
    cb({success = true, thumbnail = GetYouTubeThumbnail(url)})
end)

RegisterNUICallback('toggleRadio', function(data, cb)
    local canControl, message = CanControlVehicleRadio()
    if not canControl then
        radioOpen = false
        SetNuiFocus(false, false)
        cb({success = false, message = message})
        return
    end

    TriggerServerEvent('carRadio:toggleRadio', GetCurrentVehiclePlate(), data.isPlaying == true)
    cb({success = true})
end)

RegisterNUICallback('setVolume', function(data, cb)
    local canControl, message = CanControlVehicleRadio()
    if not canControl then
        cb({success = false, message = message})
        return
    end

    TriggerServerEvent('carRadio:setVolume', GetCurrentVehiclePlate(), ClampVolume(data.volume))
    cb({success = true})
end)

RegisterNUICallback('stopRadio', function(data, cb)
    local canControl, message = CanControlVehicleRadio()
    if not canControl then
        radioOpen = false
        SetNuiFocus(false, false)
        cb({success = false, message = message})
        return
    end

    TriggerServerEvent('carRadio:stopRadio', GetCurrentVehiclePlate())
    cb({success = true})
end)

RegisterNUICallback('closeRadio', function(data, cb)
    radioOpen = false
    currentVehicle = nil
    SetNuiFocus(false, false)
    cb({success = true})

    SetTimeout(50, function()
        SetNuiFocus(false, false)
    end)
end)

RegisterNetEvent('carRadio:updateRadio')
AddEventHandler('carRadio:updateRadio', function(state)
    if not state or not state.vehicleId then return end

    local stateVehicleId = TrimPlate(state.vehicleId)
    state.vehicleId = stateVehicleId

    state.clientReceivedAt = GetGameTimer()

    if state.currentUrl and state.currentUrl ~= "" then
        radioStates[stateVehicleId] = state
    else
        radioStates[stateVehicleId] = nil
        StopSound(stateVehicleId)
    end

    local playerVehicleId = GetCurrentVehiclePlate()
    if playerVehicleId and stateVehicleId == playerVehicleId then
        radioState = state
    end

    UpdateAudioForState(state)

    if radioOpen and GetCurrentVehicle() ~= 0 and stateVehicleId == playerVehicleId then
        SendReactMessage('updateRadio', {
            currentUrl = state.currentUrl or "",
            isPlaying = state.isPlaying,
            thumbnail = state.currentUrl and GetYouTubeThumbnail(state.currentUrl) or "",
            volume = ClampVolume(state.volume),
            currentTime = GetSyncedPlaybackTime(state),
            startedAt = state.startedAt
        })
    end
end)

RegisterNetEvent('carRadio:playRejected')
AddEventHandler('carRadio:playRejected', function(message)
    SendReactMessage('playRejected', { message = message or 'Stop the current song before playing a new one.' })
end)

RegisterNetEvent('carRadio:updateAllRadios')
AddEventHandler('carRadio:updateAllRadios', function(states)
    radioStates = {}

    if states then
        for vehicleId, state in pairs(states) do
            vehicleId = TrimPlate(vehicleId or state.vehicleId)
            if vehicleId and state.currentUrl and state.currentUrl ~= "" then
                state.vehicleId = vehicleId
                state.clientReceivedAt = GetGameTimer()
                radioStates[vehicleId] = state
            end
        end
    end

    RefreshAllAudio()
end)

-- Keep local audio matched to nearby radios and to the vehicle the player is currently inside.
Citizen.CreateThread(function()
    Wait(1500)
    TriggerServerEvent('carRadio:requestAllStates')

    while true do
        Wait(Config.AudioRefreshRate or 750)

        local vehicle = GetCurrentVehicle()
        local plate = GetCurrentVehiclePlate()

        if vehicle ~= 0 and plate then
            TriggerServerEvent('carRadio:requestState', plate)
        end

        -- Resync full radio list occasionally for players who loaded in after music started.
        local gameTimer = GetGameTimer()
        if gameTimer - lastAllStateRequest > (Config.FullStateRefreshInterval or 10000) then
            lastAllStateRequest = gameTimer
            TriggerServerEvent('carRadio:requestAllStates')
        end

        RefreshAllAudio()

        if radioOpen and Config.AutoCloseOnExit and vehicle == 0 then
            Debug("Player exited vehicle, force closing radio UI")
            radioOpen = false
            currentVehicle = nil
            SetNuiFocus(false, false)
            SendReactMessage('forceClose', {})

            SetTimeout(50, function()
                SetNuiFocus(false, false)
            end)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    StopAllAudio()
    SetNuiFocus(false, false)
end)
