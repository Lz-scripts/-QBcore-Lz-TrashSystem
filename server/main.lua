local QBCore = exports['qb-core']:GetCoreObject()
local DbTable = nil
local DbColumn = nil 

local function InventoryDbSet ()
    if Config.inventory == 'qb' then 
        DbTable = 'inventories'
        DbColumn = 'identifier'
    elseif Config.inventory == 'tgiann' then 
        DbTable = 'tgiann_inventory_stashitems'
        DbColumn = 'stash'
    end
end

QBCore.Commands.Add('addtrash', 'Open Trash Creator UI (Admin)', {}, false, function(source)
    TriggerClientEvent('lz-trash:client:OpenAddUI', source)
end, Config.AdminGroup)

QBCore.Commands.Add('deltrash', 'Delete the closest trash can (Admin Only)', {}, false, function(source)
    TriggerClientEvent('lz-trash:client:DeleteClosest', source)
end, Config.AdminGroup)

QBCore.Commands.Add('cleartrash', 'Clear Trash(Admin)', {}, false, function(source)
    TriggerClientEvent('lz-trash:client:ClearStashes', source)
end, Config.AdminGroup)

QBCore.Commands.Add('trashmanage', 'Manage Existing Trash (Admin)', {}, false, function(source)

    MySQL.query('SELECT * FROM lz_trash_system', {}, function(result)
        if result then
            TriggerClientEvent('lz-trash:client:OpenManageUI', source, result)
        else
            TriggerClientEvent('QBCore:Notify', source, "No trash cans found in DB.", "error")
        end
    end)
end, Config.AdminGroup)

RegisterNetEvent('lz-trash:server:SaveTrash', function(data)
    local src = source
    
    MySQL.insert('INSERT INTO lz_trash_system (prop_model, coords, heading) VALUES (?, ?, ?)', {
        data.model,
        json.encode(data.coords), 
        data.heading
    }, function(id)
        if id then
            local newTrash = {
                id = id,
                prop_model = data.model,
                coords = json.encode(data.coords),
                heading = data.heading
            }
            
            TriggerClientEvent('lz-trash:client:SyncNewTrash', -1, newTrash)
            TriggerClientEvent('QBCore:Notify', src, "Trash Can Saved (ID: "..id..")", "success")
        end
    end)
end)


RegisterNetEvent('lz-trash:server:RemoveTrash', function(id)
    local src = source
    MySQL.query('DELETE FROM lz_trash_system WHERE id = ?', {id}, function()
        TriggerClientEvent('lz-trash:client:RemoveTrashProp', -1, id)
        TriggerClientEvent('QBCore:Notify', src, "Trash #"..id.." Removed.", "error")
    end)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    MySQL.query('SELECT * FROM lz_trash_system', {}, function(result)
        if result then
            TriggerClientEvent('lz-trash:client:LoadAllTrash', src, result)
        end
    end)
end)


AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    Wait(500)
    InventoryDbSet() 

    MySQL.query('SELECT * FROM lz_trash_system', {}, function(result)
        if result and #result > 0 then
            TriggerClientEvent('lz-trash:client:LoadAllTrash', -1, result)
            
            -- if Config.inventory == 'tgiann' then
            --     print("^2[LZ-TRASH] Registering " .. #result .. " Tgiann Stashes...^7")
                
            --     for _, trash in pairs(result) do
            --         local stashName = "trash_" .. trash.id
            --         exports["tgiann-inventory"]:RegisterStash(
            --             stashName, 
            --             stashName, 
            --             Config.TrashSlots, 
            --             Config.TrashWeight, 
            --             false, 
            --             false, 
            --             nil, 
            --             nil, 
            --             nil
            --         )
            --     end
            -- end
        end
    end)
    print([[
    _      ________ 
    | |    |___   /
    | |       / /      
    | |      / /       
    | |____ / /____    
    |______/_______|   
    ]])
end)


RegisterNetEvent('Lz:TrashSys:ClearStash',function(TrashId)
    local StashId = "trash_"..TrashId
    if Config.inventory == 'qs' then
        local StashItems = exports['qs-inventory']:GetStashItems(StashId)
        print(StashId)
        if StashItems then 
            for slot , ItemData in pairs(StashItems) do 
                print('slot'.. slot)
                print('item'.. ItemData.name)
                print('item'.. ItemData.amount)
                exports['qs-inventory']:RemoveItemIntoStash(StashId, ItemData.name, ItemData.amount, slot, Config.TrashSlots,Config.TrashWeight)
            end
        end
    elseif Config.inventory == 'qb' then 
        exports['qb-inventory']:ClearStash(StashId)
    elseif Config.inventory == 'tgiann' then 
        local allItems = exports["tgiann-inventory"]:GetSecondaryInventoryItems("stash", StashId)
        if allItems then
            for slot, itemData in pairs(allItems) do
                exports["tgiann-inventory"]:RemoveItemFromSecondaryInventory(
                "stash",             
                StashId,           
                itemData.name,       
                itemData.amount,     
                slot,               
                itemData.info     
            )
            Wait(10) 
            end
        end
    end
end)

RegisterNetEvent('Lz:TrashSys:tgiannstash',function (stashName)
    local src = source
    if Config.inventory == 'tgiann' then
        exports["tgiann-inventory"]:RegisterStash(stashName, stashName, Config.TrashSlots , Config.TrashWeight, false , false , nil , nil , nil)
    elseif Config.inventory == 'qb' then 
        exports['qb-inventory']:OpenInventory(src, stashName)
    end
end)



RegisterNetEvent('lz-trash:server:RequestSync', function()
    local src = source
    MySQL.query('SELECT * FROM lz_trash_system', {}, function(result) 
        if result then
            TriggerClientEvent('lz-trash:client:LoadAllTrash', src, result)
        end
    end)
end)



CreateThread(function()
    while true do
        Wait(Config.CleanupInterval * 60 * 1000)
        if Config.inventory == 'qb' then 
            MySQL.query("SELECT id FROM lz_trash_system", {}, function(trashResult)
                if trashResult and #trashResult > 0 then
                    
                    local count = 0
                    for _, v in pairs(trashResult) do
                        if Config.inventory == 'qb' then  
                             targetStashName = "trash_" .. v.id
                            exports['qb-inventory']:ClearStash(targetStashName)
                            count = count + 1
                        elseif Config.inventory == 'qs' then 
                            local StashItems = exports['qs-inventory']:GetStashItems(targetStashName)
                            if StashItems then 
                                for slot , ItemData in pairs(StashItems) do 
                                    exports['qs-inventory']:RemoveItemIntoStash(targetStashName, ItemData.name, ItemData.amount, slot, Config.TrashSlots,Config.TrashWeight)
                                end
                            end
                        elseif Config.inventory == 'tgiann' then
                            local allItems = exports["tgiann-inventory"]:GetSecondaryInventoryItems("stash", targetStashName)
                            if allItems then
                                for slot, itemData in pairs(allItems) do
                                    exports["tgiann-inventory"]:RemoveItemFromSecondaryInventory(
                                    "stash",             
                                    targetStashName,           
                                    itemData.name,       
                                    itemData.amount,     
                                    slot,               
                                    itemData.info     
                                )
                                Wait(10) 
                                end
                            end
                        end
                    end

                    print("^2[LZ-TRASH] Precision Cleanup: Refreshed " .. count .. " trash bins.^7")
                end
            end)

        end
    end
end)