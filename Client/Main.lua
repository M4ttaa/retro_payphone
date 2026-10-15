local IsOpen = false
local isOnCallCell = false
local IsPhoneOpened = false
local RegisteredPhones = {}

local firstOpen = false

local CurrentPayphone = nil
local CurrentEntity

local TempViewMode = 0

Payphones = {}
Calls = {}

AddEventHandler('onResourceStart', function(resource)
	FrameworkOptions.TriggerCallback('retro_payphone:server:getPayphones', function(payphones)
        Payphones = payphones
    end)
end)

RegisterNetEvent(FrameworkOptions.OnPlayerLoaded, function()
    FrameworkOptions.TriggerCallback('retro_payphone:server:getPayphones', function(payphones)
        Payphones = payphones
    end)
end)

function GetPhoneNumberFromCoords(EntityCoords)
    EntityCoords = vector3(math.abs(EntityCoords.x), math.abs(EntityCoords.y), math.abs(EntityCoords.z))

    if EntityCoords.x == 0.0 and EntityCoords.y == 0.0 and EntityCoords.z == 0.0 then
        return nil
    end

    EntityCoords = {
        x = string.gsub(EntityCoords.x, '%.', ''),
        y = string.gsub(EntityCoords.y, '%.', ''),
        z = string.gsub(EntityCoords.z, '%.', ''),
    }
    EntityCoords.x = string.gsub(EntityCoords.x, '%s+', '')
    EntityCoords.y = string.gsub(EntityCoords.y, '%s+', '')
    EntityCoords.z = string.gsub(EntityCoords.z, '%s+', '')

    EntityCoords.x = string.sub(EntityCoords.x, 1, 4)
    EntityCoords.y = string.sub(EntityCoords.y, 1, 4)
    EntityCoords.z = string.sub(EntityCoords.z, 1, 2)
    return EntityCoords.x .. EntityCoords.y .. EntityCoords.z 
end

Citizen.CreateThread(function()
    while true do
      local PlayerPed = GetPlayerPed(-1)
      local Coords = GetEntityCoords(PlayerPed)
      for _, key in pairs(Config.PayphoneModels) do
        local ClosestPhoneBox = GetClosestObjectOfType(Coords.x, Coords.y, Coords.z, 25.0, key, false, false, false)
        if ClosestPhoneBox ~= 0 and not RegisteredPhones[ClosestPhoneBox] then
          local PhoneCoords = GetEntityCoords(ClosestPhoneBox)
          local number = GetPhoneNumberFromCoords(PhoneCoords)
            
          if not Payphones[number] then
            TriggerServerEvent('retro_payphone:server:registerPayphone', number, PhoneCoords)
          end
          RegisteredPhones[ClosestPhoneBox] = true
        end
      end
      Citizen.Wait(2000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if IsOpen and isOnCallCell then 
            Citizen.Wait(200)
            FrameworkOptions.TriggerCallback('retro_payphone:server:isInCall', function(result)
                if not IsOpen or not isOnCallCell then return end
                if result == 'NOT_RINGING' then
                    SendNUIMessage({
                        action = 'CLOSE_PAYPHONE',
                        customMessage = Locale("NOT_AVAILABLE")
                    })
                    isOnCallCell = false
                elseif result == 'NETWORK_ERROR' then
                    SendNUIMessage({
                        action = 'CLOSE_PAYPHONE',
                        customMessage = Locale("NETWORK_ERROR")
                    })
                    isOnCallCell = false
                elseif result == 'INTERRUPTED' then
                    SendNUIMessage({
                        action = 'CLOSE_PAYPHONE',
                    })
                    isOnCallCell = false
                elseif result == 'BUSY' then
                    SendNUIMessage({
                        action = 'CLOSE_PAYPHONE'
                    })
                    isOnCallCell = false
                elseif result == 'CONNECTED' then
                    IsPhoneOpened = true
                    SendNUIMessage({
                        action = 'PHONE_OPENED'
                    })
                end
            end)
        else
            Citizen.Wait(2000)
        end
    end
end)


function Locale(type)
    local locale = Config.CurrentLocale

    return Config.Locale[locale][type]
end

RegisterNetEvent('retro_payphone:client:registerPayphone', function(number, coords)
    Payphones[number] = coords
end)

RegisterNetEvent('retro_payphone:client:payphone', function(option) 
    local maxHealth = GetEntityMaxHealth(option.entity)
    local health = GetEntityHealth(option.entity)
    
    if health + 50 < maxHealth then
        FrameworkOptions.Notify(Locale("PAYPHONE_BROKEN"), 'error')
        return
    end

    FrameworkOptions.TriggerCallback('retro_payphone:server:payForPhone', function(result)
        if not result then
            FrameworkOptions.Notify(Locale("NOT_ENOUGH_MONEY"), 'error')
            return
        end
        
        local EntityCoords = GetEntityCoords(option.entity)
        local PhoneNumber = GetPhoneNumberFromCoords(EntityCoords)

        if math.random(1, 100) <= Config.LostMoneyChance then
            FrameworkOptions.Notify(Locale("LOST_MONEY"), 'error')
            return
        end

        OpenPayphone(false, option.entity, PhoneNumber)
    end)
end)

RegisterNetEvent('retro_payphone:client:callNumber', function(src, Call)
    Calls[src] = Call

    if Call.PhoneNumber == CurrentPayphone then
        SendNUIMessage({
            action = 'CLOSE_PAYPHONE',
            customMessage = Locale("NETWORK_ERROR")
        })
    end

    exports['xsound']:PlayUrlPos("call-" .. Call.callId, "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/sounds/ring.mp3", 1, Call.coords, true)
    exports['xsound']:Distance("call-" .. Call.callId, 20)
end)

RegisterNetEvent('retro_payphone:client:answerCall', function(option)
    local EntityCoords = GetEntityCoords(option.entity)
    local PhoneNumber = GetPhoneNumberFromCoords(EntityCoords)

    if PhoneNumber == nil then return end

    OpenPayphone(true, option.entity, PhoneNumber)

    TriggerServerEvent('retro_payphone:server:answerCall', PhoneNumber)
end)

RegisterNetEvent('retro_payphone:client:hangUpOrOpen', function(src, isOpened)
    if Calls[src] ~= nil then
        exports['xsound']:Destroy("call-" .. Calls[src].callId)
        if isOpened and (Calls[src].CallerNumber == CurrentPayphone or Calls[src].PhoneNumber == CurrentPayphone) then
            SendNUIMessage({
                action = 'PHONE_OPENED'
            })
        elseif not isOpened and (Calls[src].CallerNumber == CurrentPayphone or Calls[src].PhoneNumber == CurrentPayphone) then
            SendNUIMessage({
                action = 'CLOSE_PAYPHONE'
            })

            Calls[src] = nil
        else
            Calls[src] = nil
        end
    end
end)

RegisterNetEvent('retro_payphone:client:busy', function()
    SendNUIMessage({
        action = 'CLOSE_PAYPHONE',
        customMessage = Locale("BUSY")
    })
end)

RegisterNUICallback('CALL_NUMBER', function(data, cb)
    local PhoneNumber = data.PhoneNumber
    local event = Config.Events[PhoneNumber]
    if event ~= nil then
        if type(event.event) == 'function' then
            event.event()
        else
            if event.type == 'client' then
                TriggerEvent(event.event, CurrentPayphone, CurrentEntity)
            elseif event.type == 'server' then
                TriggerServerEvent(event.event, CurrentPayphone, CurrentEntity)
            elseif event.type == 'command' then
                ExecuteCommand(event.event)
            end
        end
        SendNUIMessage({
            action = 'CLOSE_PAYPHONE',
            customMessage = Locale("SOMETHING_HAPPENED")
        })
        return
    end

    if CurrentPayphone == PhoneNumber then
        SendNUIMessage({
           action = 'CLOSE_PAYPHONE',
           customMessage = Locale("NETWORK_ERROR")
        })
        return
    end
    local isPayphone = false
    if Payphones[PhoneNumber] ~= nil then
        isPayphone = true
    else
        isOnCallCell = true
    end

    TriggerServerEvent('retro_payphone:server:callNumber', PhoneNumber, CurrentPayphone, true)
    cb('ok')
end)

RegisterNUICallback('HANG_UP', function(data, cb)
    TriggerServerEvent('retro_payphone:server:hangUp')
    isOnCallCell = false
    cb('ok')
end)

RegisterNUICallback('CLOSE_PAYPHONE', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')

    CurrentPayphone = nil
    CurrentEntity = nil

    IsOpen = false
    isOnCallCell = false
    IsPhoneOpened = false

    SetFollowPedCamViewMode(TempViewMode)
end)


function IsOpen()
    return IsOpen
end

exports('IsOpen', IsOpen)

function IsAnyCallOnEntitiy(entity) 
    for _, Call in pairs(Calls) do
        for _, Entity in pairs(Config.PayphoneModels) do
            local ClosestPhoneBox = GetClosestObjectOfType(Call.coords.x, Call.coords.y, Call.coords.z, 2.0, Entity, false, false, false)
            if ClosestPhoneBox == entity then
                return true
            end
        end
    end
end

function OpenPayphone(isCalling, entity, PhoneNumber)
    if not firstOpen then
        SendNUIMessage({
            action = "SET_CONFIG",
            Locale = Config.Locale[Config.CurrentLocale],
            HangUpTime = Config.HangUpTime,
            RingSeconds = Config.RingSeconds,
        })
        firstOpen = true
    end

    TempViewMode = GetFollowPedCamViewMode()

    SetFollowPedCamViewMode(4)

    SendNUIMessage({
        action = 'OPEN_PAYPHONE',
        PhoneNumber = PhoneNumber,
        isCalling = isCalling
    })

    SetNuiFocus(true, true)

    CurrentPayphone = PhoneNumber
    CurrentEntity = entity

    IsOpen = true
end
