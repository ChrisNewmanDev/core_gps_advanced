local savedMarkers = {}
local blips = {}
local markersVisible = true
local receiveLocationsAllowed = false
local isUIOpen = false
local currentGPSId = nil
local isPlayingAnim = false
local phoneProp = 0

Framework.OnPlayerLoaded(function()
end)

Framework.OnPlayerUnload(function()
    savedMarkers = {}
    currentGPSId = nil
    ClearAllBlips()
    DeletePhoneProp()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000)
        if markersVisible then
            local hasItem, itemData = GetGPSItem()
            local gpsId = Framework.GetItemGPSId(itemData)
            if hasItem and gpsId then
                currentGPSId = gpsId
                TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
                Wait(500)
                if #savedMarkers > 0 then
                    RefreshBlips()
                end
            end
        end
    end
end)

function GetGPSItem()
    local items = Framework.GetPlayerItems()
    if not items then return false, nil end
    for _, item in pairs(items) do
        if item and item.name == Config.ItemName then
            return true, item
        end
    end
    return false, nil
end

function CountGPSItems()
    local items = Framework.GetPlayerItems()
    if not items then return 0 end
    local count = 0
    for _, item in pairs(items) do
        if item and item.name == Config.ItemName then
            count = count + 1
        end
    end
    return count
end

function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

function CreatePhoneProp()
    local ped = PlayerPedId()
    local model = `prop_phone_ing_03`
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    phoneProp = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    local bone = GetPedBoneIndex(ped, 28422)
    
    AttachEntityToEntity(phoneProp, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 2, true)
    SetModelAsNoLongerNeeded(model)
end

function DeletePhoneProp()
    if phoneProp ~= 0 and DoesEntityExist(phoneProp) then
        DeleteEntity(phoneProp)
        phoneProp = 0
    end
end

function StartGPSAnimation()
    if isPlayingAnim then return end
    
    local ped = PlayerPedId()
    LoadAnimDict("cellphone@")
    CreatePhoneProp()
    TaskPlayAnim(ped, "cellphone@", "cellphone_text_read_base", 3.0, 3.0, -1, 49, 0, false, false, false)
    isPlayingAnim = true
    
    CreateThread(function()
        while isUIOpen and isPlayingAnim do
            Wait(500)
            if isUIOpen and isPlayingAnim then
                local ped = PlayerPedId()
                if not IsEntityPlayingAnim(ped, "cellphone@", "cellphone_text_read_base", 3) then
                    TaskPlayAnim(ped, "cellphone@", "cellphone_text_read_base", 3.0, 3.0, -1, 49, 0, false, false, false)
                end
            end
        end
    end)
end

function StopGPSAnimation()
    if not isPlayingAnim then return end
    
    local ped = PlayerPedId()
    StopAnimTask(ped, "cellphone@", "cellphone_text_read_base", 1.0)
    DeletePhoneProp()
    isPlayingAnim = false
end

RegisterNetEvent('core_gps:client:useItem', function(item)
    local gpsId = Framework.GetItemGPSId(item)
    
    if gpsId then
        currentGPSId = gpsId
        TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
        Wait(100)
        OpenGPSUI()
    else
        Framework.Notify('This GPS device is not properly registered!', 'error')
    end
end)

function OpenGPSUI()
    if isUIOpen then return end
    if not currentGPSId then
        Framework.Notify('No GPS device detected!', 'error')
        return
    end
    isUIOpen = true
    StartGPSAnimation()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        markers = savedMarkers,
        markersVisible = markersVisible,
        gpsId = currentGPSId,
        receiveLocationsAllowed = receiveLocationsAllowed
    })
end

RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    StopGPSAnimation()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('markLocation', function(data, cb)
    if not currentGPSId then
        Framework.Notify('GPS device not detected. Please try closing and reopening the GPS.', 'error')
        cb('error')
        return
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local markerData = {
        label = data.label or 'Marked Location',
        coords = {x = coords.x, y = coords.y, z = coords.z},
        street = streetName,
        timestamp = (os and os.time and os.time()) or math.floor(GetGameTimer() / 1000)
    }
    TriggerServerEvent('core_gps:server:addMarker', currentGPSId, markerData)
    cb('ok')
end)

RegisterNUICallback('removeMarker', function(data, cb)
    if not currentGPSId then
        cb('error')
        return
    end
    TriggerServerEvent('core_gps:server:removeMarker', currentGPSId, data.index)
    cb('ok')
end)

RegisterNUICallback('shareMarker', function(data, cb)
    if not currentGPSId then
        cb('error')
        return
    end
    TriggerServerEvent('core_gps:server:shareMarker', currentGPSId, data.playerId, data.index)
    cb('ok')
end)

RegisterNUICallback('renameMarker', function(data, cb)
    if not currentGPSId then
        cb('error')
        return
    end
    TriggerServerEvent('core_gps:server:renameMarker', currentGPSId, data.index, data.newLabel)
    cb('ok')
end)

RegisterNUICallback('toggleMarkers', function(data, cb)
    markersVisible = data.visible
    if markersVisible then
        local hasItem, itemData = GetGPSItem()
        local gpsId = Framework.GetItemGPSId(itemData)
        if hasItem and gpsId then
            RefreshBlips()
        end
    else
        ClearAllBlips()
    end
    cb('ok')
end)

RegisterNUICallback('toggleReceiveLocations', function(data, cb)
    receiveLocationsAllowed = data.allowed
    if currentGPSId then
        TriggerServerEvent('core_gps:server:updateReceiveSetting', currentGPSId, receiveLocationsAllowed)
    end
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    local marker = savedMarkers[data.index]
    if marker then
        SetNewWaypoint(marker.coords.x, marker.coords.y)
        Framework.Notify('Waypoint set!', 'success')
    end
    cb('ok')
end)

RegisterNetEvent('core_gps:client:updateMarkers', function(markers)
    savedMarkers = markers
    if isUIOpen then
        SendNUIMessage({
            action = 'updateMarkers',
            markers = savedMarkers
        })
    end
    if markersVisible then
        local hasItem, itemData = GetGPSItem()
        local gpsId = Framework.GetItemGPSId(itemData)
        if hasItem and gpsId then
            RefreshBlips()
        else
            ClearAllBlips()
        end
    end
end)

RegisterNetEvent('core_gps:client:updateReceiveSetting', function(allowed)
    receiveLocationsAllowed = allowed
    if isUIOpen then
        SendNUIMessage({
            action = 'updateReceiveSetting',
            allowed = receiveLocationsAllowed
        })
    end
end)

RegisterNetEvent('core_gps:client:receiveSharedMarker', function(markerData, senderName, senderSource)
    if not receiveLocationsAllowed then
        Framework.Notify('You have disabled location sharing. Enable "Allow Receiving Locations" in your GPS settings.', 'error')
        TriggerServerEvent('core_gps:server:notifyShareRejected', senderSource)
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'receiveLocation',
        markerData = markerData,
        senderName = senderName
    })
end)

RegisterNUICallback('acceptSharedLocation', function(data, cb)
    local markerData = data.markerData
    local hasItem, itemData = GetGPSItem()
    local gpsId = Framework.GetItemGPSId(itemData)
    if hasItem and gpsId then
        TriggerServerEvent('core_gps:server:addMarker', gpsId, markerData)
        Framework.Notify('Location accepted and saved to your GPS!', 'success')
    else
        Framework.Notify('You need a GPS device to save this location!', 'error')
    end
    cb('ok')
end)

RegisterNUICallback('declineSharedLocation', function(data, cb)
    Framework.Notify('Location declined', 'error')
    isUIOpen = false
    StopGPSAnimation()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeReceiveModal', function(data, cb)
    isUIOpen = false
    StopGPSAnimation()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('core_gps:client:shareResult', function(success, message)
    if success then
        Framework.Notify(message, 'success')
    else
        Framework.Notify(message, 'error')
    end
end)

function RefreshBlips()
    ClearAllBlips()
    if not markersVisible then return end
    local gpsCount = CountGPSItems()
    if gpsCount > 1 then
        Framework.Notify('You have too many GPS devices on you to display map data', 'error')
        return
    end
    local hasItem, itemData = GetGPSItem()
    local gpsId = Framework.GetItemGPSId(itemData)
    if not hasItem or not gpsId then 
        return
    end
    for i, marker in ipairs(savedMarkers) do
        local blip = AddBlipForCoord(marker.coords.x, marker.coords.y, marker.coords.z)
        SetBlipSprite(blip, Config.BlipSettings.sprite)
        SetBlipColour(blip, Config.BlipSettings.color)
        SetBlipScale(blip, Config.BlipSettings.scale)
        SetBlipDisplay(blip, Config.BlipSettings.display)
        SetBlipAsShortRange(blip, Config.BlipSettings.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(marker.label)
        EndTextCommandSetBlipName(blip)
        table.insert(blips, blip)
    end
end

function ClearAllBlips()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end

if Framework.Type == 'qbcore' or Framework.Type == 'qbox' then
    RegisterNetEvent('QBCore:Client:ItemBox', function(itemData, type)
        if itemData.name == Config.ItemName then
            if type == "add" then
                local hasItem, item = GetGPSItem()
                local gpsId = Framework.GetItemGPSId(item)
                if hasItem and gpsId then
                    currentGPSId = gpsId
                    TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
                    Wait(500)
                    if markersVisible and #savedMarkers > 0 then
                        RefreshBlips()
                    end
                end
            elseif type == "remove" then
                Wait(100)
                local hasItem, item = GetGPSItem()
                if not hasItem then
                    currentGPSId = nil
                    savedMarkers = {}
                    ClearAllBlips()
                else
                    local gpsId = Framework.GetItemGPSId(item)
                    if gpsId and currentGPSId ~= gpsId then
                        currentGPSId = gpsId
                        TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
                    end
                end
            end
        end
    end)
elseif Framework.Type == 'esx' then
    AddEventHandler('ox_inventory:updateInventory', function(changes)
        if not changes or type(changes) ~= 'table' then return end
        
        for itemName, data in pairs(changes) do
            if itemName == Config.ItemName then
                Wait(100)
                local hasItem, item = GetGPSItem()
                local gpsId = Framework.GetItemGPSId(item)
                
                if hasItem and gpsId then
                    if currentGPSId ~= gpsId then
                        currentGPSId = gpsId
                        TriggerServerEvent('core_gps:server:loadMarkers', currentGPSId)
                        Wait(500)
                        if markersVisible and #savedMarkers > 0 then
                            RefreshBlips()
                        end
                    end
                else
                    if currentGPSId then
                        currentGPSId = nil
                        savedMarkers = {}
                        ClearAllBlips()
                    end
                end
                break
            end
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearAllBlips()
        if isUIOpen then
            StopGPSAnimation()
            SetNuiFocus(false, false)
        end
        DeletePhoneProp()
    end
end)
