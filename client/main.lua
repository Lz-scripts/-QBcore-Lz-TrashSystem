local QBCore = exports['qb-core']:GetCoreObject()
local SpawnedTrash = {} 


RegisterNetEvent('lz-trash:client:OpenAddUI', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openSelector" })
end)

RegisterNetEvent('lz-trash:client:OpenManageUI', function(trashData)
    SetNuiFocus(true, true)
    SendNUIMessage({ 
        action = "openManager",
        trashData = trashData
    })
end)


RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('spawnTrash', function(data, cb)
    TriggerEvent('lz-trash:client:StartPlacement', data.model)
    cb('ok')
end)

RegisterNUICallback('teleportTrash', function(data, cb)
    local id = tonumber(data.id)
    local entity = SpawnedTrash[id]

    if entity and DoesEntityExist(entity) then
        local coords = GetEntityCoords(entity)
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0)
        QBCore.Functions.Notify("Teleported to Trash #"..id, "success")
    else
        QBCore.Functions.Notify("Trash ID not found (try moving closer to where it should be?)", "error")
    end
    cb('ok')
end)

RegisterNUICallback('deleteTrash', function(data, cb)
    local id = tonumber(data.id)
    TriggerServerEvent('lz-trash:server:RemoveTrash', id)
    cb('ok')
end)

RegisterNetEvent('lz-trash:client:StartPlacement', function(modelName)
    local propModel = modelName or "prop_bin_05a"
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(0) end
    
    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    
    local tempProp = CreateObject(propModel, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(tempProp, 200, false)
    local result = exports['Lz-Gizmo']:useGizmo(tempProp)
    
    if result then
        local finalCoords = vector3(result.position.x, result.position.y, result.position.z)
        local finalHeading = result.rotation.z 

        TriggerServerEvent('lz-trash:server:SaveTrash', {
            model = propModel,
            coords = finalCoords,
            heading = finalHeading
        })
    else
        QBCore.Functions.Notify("Placement Cancelled", "error")
    end


    DeleteEntity(tempProp) 
end)


RegisterNetEvent('lz-trash:client:LoadAllTrash', function(trashList)
    for _, data in pairs(trashList) do
        SpawnTrashProp(data)
    end
end)


RegisterNetEvent('lz-trash:client:SyncNewTrash', function(data)
    SpawnTrashProp(data)
end)


RegisterNetEvent('lz-trash:client:RemoveTrashProp', function(id)
    local trashId = tonumber(id)
    local entity = SpawnedTrash[trashId]
    
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
        SpawnedTrash[trashId] = nil
        exports['qb-target']:RemoveTargetEntity(entity)
    end
end)

function SpawnTrashProp(data)
    local id = tonumber(data.id)
     local stashName = "trash_" ..id


    if SpawnedTrash[id] and DoesEntityExist(SpawnedTrash[id]) then return end

    local coords = json.decode(data.coords)
    local model = data.prop_model

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end


    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, data.heading or 0.0)
    FreezeEntityPosition(obj, true)
    PlaceObjectOnGroundProperly(obj)
    SpawnedTrash[id] = obj


    exports['qb-target']:AddTargetEntity(obj, {
        options = {
            {
                type = "client",
                event = "lz-trash:client:OpenTrash", 
                icon = "fas fa-trash",
                label = "Open Trash",
                trashId = id,
            },
        },
        distance = 2.0
    })
    if Config.inventory == 'tgiann' then 
        TriggerServerEvent('Lz:TrashSys:tgiannstash',stashName)
    end

end


RegisterNetEvent('lz-trash:client:OpenTrash', function(data)
    local stashName = "trash_" .. data.trashId

    local ped = PlayerPedId()
    LoadAnimDict("amb@prop_human_bum_bin@idle_b")
    TaskPlayAnim(ped, "amb@prop_human_bum_bin@idle_b", "idle_d", 4.0, 4.0, -1, 50, 0, false, false, false)
    if Config.inventory == 'qb' then
        TriggerServerEvent('Lz:TrashSys:tgiannstash',stashName)
        TriggerEvent("inventory:client:SetCurrentStash", stashName)
    elseif Config.inventory == 'tgiann' then
       exports["tgiann-inventory"]:OpenInventory("stash", stashName, { maxweight = Config.TrashWeight, slots = Config.TrashSlots })
    end
    Wait(1000)
    ClearPedTasks(ped)
end)

function LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

RegisterNetEvent('lz-trash:client:DeleteClosest', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestId = nil
    local closestDist = 3.0

    for id, entity in pairs(SpawnedTrash) do
        if DoesEntityExist(entity) then
            local trashCoords = GetEntityCoords(entity)
            local dist = #(coords - trashCoords)

            if dist < closestDist then
                closestDist = dist
                closestId = id
            end
        end
    end
    if closestId then
        TriggerServerEvent('lz-trash:server:RemoveTrash', closestId)
        QBCore.Functions.Notify("Trash #"..closestId.." Deleted!", "success")
    else
        QBCore.Functions.Notify("No trash can found nearby.", "error")
    end
end)



RegisterNetEvent('lz-trash:client:ClearStashes', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestId = nil
    local closestDist = 3.0
    
    for id, entity in pairs(SpawnedTrash) do
        if DoesEntityExist(entity) then
            local trashCoords = GetEntityCoords(entity)
            local dist = #(coords - trashCoords)
    
            if dist < closestDist then
                closestDist = dist
                closestId = id
            end
        end
    end
    if closestId then
        TriggerServerEvent('Lz:TrashSys:ClearStash',closestId)
        QBCore.Functions.Notify("Trash #"..closestId.." Deleted!", "success")
    else
        QBCore.Functions.Notify("No trash can found nearby.", "error")
    end
end)


AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.citizenid then
        TriggerServerEvent('lz-trash:server:RequestSync')
        print("[LZ-TRASH] Resource restarted - Requesting Sync...")
    end
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('lz-trash:server:RequestSync')
    print("[LZ-TRASH] Player Loaded - Requesting Sync...")
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for id, entity in pairs(SpawnedTrash) do
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
    end
end)