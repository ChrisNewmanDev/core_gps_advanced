Framework = {}
Framework.Type = string.lower(Config.Framework)

if Framework.Type == 'qbcore' then
    Framework.Object = exports['qb-core']:GetCoreObject()
elseif Framework.Type == 'esx' then
    Framework.Object = exports['es_extended']:getSharedObject()
elseif Framework.Type == 'qbox' then
    Framework.Object = exports['qbx-core']:GetCoreObject()
end

if IsDuplicityVersion() then
    function Framework.GetPlayer(source)
        if Framework.Type == 'qbcore' then
            return Framework.Object.Functions.GetPlayer(source)
        elseif Framework.Type == 'esx' then
            return Framework.Object.GetPlayerFromId(source)
        elseif Framework.Type == 'qbox' then
            return exports['qbx-core']:GetPlayer(source)
        end
    end
    
    function Framework.GetPlayerName(Player)
        if Framework.Type == 'qbcore' then
            return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        elseif Framework.Type == 'esx' then
            return Player.getName()
        elseif Framework.Type == 'qbox' then
            return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        end
    end
    
    function Framework.AddItem(Player, item, amount, metadata)
        if Framework.Type == 'qbcore' then
            return Player.Functions.AddItem(item, amount, false, metadata)
        elseif Framework.Type == 'esx' then
            return exports.ox_inventory:AddItem(Player.source, item, amount, metadata)
        elseif Framework.Type == 'qbox' then
            return exports.ox_inventory:AddItem(Player.PlayerData.source, item, amount, metadata)
        end
    end
    
    function Framework.Notify(source, message, type)
        if Framework.Type == 'qbcore' then
            TriggerClientEvent('QBCore:Notify', source, message, type)
        elseif Framework.Type == 'esx' then
            TriggerClientEvent('esx:showNotification', source, message, type)
        elseif Framework.Type == 'qbox' then
            TriggerClientEvent('QBCore:Notify', source, message, type)
        end
    end
    
    function Framework.RegisterUsableItem(item, callback)
        if Framework.Type == 'qbcore' then
            Framework.Object.Functions.CreateUseableItem(item, callback)
        elseif Framework.Type == 'esx' then
            Framework.Object.RegisterUsableItem(item, callback)
        elseif Framework.Type == 'qbox' then
            exports['qbx-core']:CreateUseableItem(item, callback)
        end
    end
    
    function Framework.RegisterCommand(name, help, args, adminOnly, callback)
        if Framework.Type == 'qbcore' then
            Framework.Object.Commands.Add(name, help, args, adminOnly, callback, adminOnly and 'admin' or false)
        elseif Framework.Type == 'esx' then
            RegisterCommand(name, function(source, args, rawCommand)
                if adminOnly then
                    local xPlayer = Framework.GetPlayer(source)
                    if xPlayer and xPlayer.getGroup() == 'admin' then
                        callback(source, args)
                    end
                else
                    callback(source, args)
                end
            end, adminOnly)
        elseif Framework.Type == 'qbox' then
            Framework.Object.Commands.Add(name, help, args, adminOnly, callback, adminOnly and 'admin' or false)
        end
    end
    

    function Framework.ItemBox(source, item, type)
        if Framework.Type == 'qbcore' then
            TriggerClientEvent('inventory:client:ItemBox', source, Framework.Object.Shared.Items[item], type)
        elseif Framework.Type == 'esx' then
            -- ESX doesn't have item box notifications by default
            -- You can add custom notification here if needed
        elseif Framework.Type == 'qbox' then
            TriggerClientEvent('inventory:client:ItemBox', source, item, type)
        end
    end
    
    function Framework.DBExecute(query, params, callback)
        if callback then
            exports['oxmysql']:execute(query, params, callback)
        else
            exports['oxmysql']:execute(query, params)
        end
    end
    
    function Framework.DBFetch(query, params, callback)
        if callback then
            exports['oxmysql']:execute(query, params, callback)
        else
            return exports['oxmysql']:executeSync(query, params)
        end
    end
    
    function Framework.DBInsert(query, params)
        return exports['oxmysql']:insertSync(query, params)
    end
    
else

    function Framework.GetPlayerData()
        if Framework.Type == 'qbcore' then
            return Framework.Object.Functions.GetPlayerData()
        elseif Framework.Type == 'esx' then
            return Framework.Object.GetPlayerData()
        elseif Framework.Type == 'qbox' then
            return Framework.Object.Functions.GetPlayerData()
        end
    end
    
    function Framework.Notify(message, type, duration)
        if Framework.Type == 'qbcore' then
            Framework.Object.Functions.Notify(message, type, duration)
        elseif Framework.Type == 'esx' then
            Framework.Object.ShowNotification(message, type, duration)
        elseif Framework.Type == 'qbox' then
            Framework.Object.Functions.Notify(message, type, duration)
        end
    end
    
    function Framework.OnPlayerLoaded(callback)
        if Framework.Type == 'qbcore' then
            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', callback)
        elseif Framework.Type == 'esx' then
            RegisterNetEvent('esx:playerLoaded', callback)
        elseif Framework.Type == 'qbox' then
            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', callback)
        end
    end
    
    function Framework.OnPlayerUnload(callback)
        if Framework.Type == 'qbcore' then
            RegisterNetEvent('QBCore:Client:OnPlayerUnload', callback)
        elseif Framework.Type == 'esx' then
            RegisterNetEvent('esx:onPlayerLogout', callback)
        elseif Framework.Type == 'qbox' then
            RegisterNetEvent('QBCore:Client:OnPlayerUnload', callback)
        end
    end
    
    function Framework.GetPlayerItems()
        if Framework.Type == 'qbcore' then
            local PlayerData = Framework.GetPlayerData()
            return PlayerData.items or {}
        elseif Framework.Type == 'esx' then
            local items = exports.ox_inventory:GetPlayerItems()
            return items or {}
        elseif Framework.Type == 'qbox' then
            local PlayerData = Framework.GetPlayerData()
            return PlayerData.items or {}
        end
    end
    
    function Framework.GetItemGPSId(item)
        if not item then return nil end
        if item.info and item.info.gps_id then
            return item.info.gps_id
        end
        if item.metadata and item.metadata.gps_id then
            return item.metadata.gps_id
        end
        return nil
    end
end
