local Payphones = {}

local Calls = {}

FrameworkOptions.CreateCallback('retro_payphone:server:payForPhone', function(source, cb)
    local src = source
    local amount = Config.Price
    local Player = FrameworkOptions.GetPlayer(src)
    local moneyAmount = FrameworkOptions.GetMoney(Player)
    if moneyAmount >= amount then
        FrameworkOptions.RemoveMoney(Player, amount)
        cb(true)
    else
        cb(false)
    end
end)

FrameworkOptions.CreateCallback('retro_payphone:server:getPayphones', function(source, cb)
    cb(Payphones)
end)

FrameworkOptions.CreateCallback('retro_payphone:server:isInCall', function(source, cb)
    local call = Calls[source]
    if call then
        if call.isNotAvailable then
            cb('NOT_RINGING')
            return
        end

        if call.networkError then
            cb('NETWORK_ERROR')
            return
        end

        if not call.isConnected and call.isCanceled then
            cb('NOT_RINGING')
            Calls[source] = nil
            return
        end

        if Player(call.calleSource) then
            if Player(source).state['callChannel'] == Player(call.calleSource).state['callChannel'] and Player(source).state['callChannel'] ~= 0 then
               cb('CONNECTED')
               Calls[source].connected = true
            else
                if Calls[source].connected then
                    cb('INTERRUPTED')
                    Calls[source] = nil
                    return
                end

                if Config.PhoneType == "LB" then
                    if exports["lb-phone"]:IsInCall(call.calleSource) and exports["lb-phone"]:IsInCall(source) then
                        cb('RINGING')
                    else
                        cb('NOT_RINGING')
                    end
                end
            end
        else
            cb('NOT_RINGING')
        end
    else
        cb("INTERRUPTED")
    end
end)

RegisterServerEvent('retro_payphone:server:registerPayphone')
AddEventHandler('retro_payphone:server:registerPayphone', function(number, coords)
    Payphones[number] = coords

    TriggerClientEvent('retro_payphone:client:registerPayphone', -1, number, coords)
end)

RegisterServerEvent('retro_payphone:server:callNumber')
AddEventHandler('retro_payphone:server:callNumber', function(PhoneNumber, CallerNumber, isPayphone)
    local src = source
    local callId = math.random(100000, 999999)

    for k, v in pairs(Calls) do
        if v.PhoneNumber == PhoneNumber or v.PhoneNumber == CallerNumber or v.CallerNumber == PhoneNumber or v.CallerNumber == CallerNumber then
            TriggerClientEvent('retro_payphone:client:busy', src)
            return
        end
    end

    if not isPayphone then
        if Config.PhoneType == "LB" then
            callId = exports["lb-phone"]:CreateCall({
                phoneNumber = CallerNumber,
                source = src
            }, PhoneNumber, {
                requirePhone = false,
                hideNumber = false
            })
        
            Calls[src] = {
                callerSource = src,
                calleSource = exports["lb-phone"]:GetSourceFromNumber(PhoneNumber),
                CallerNumber = CallerNumber,
                PhoneNumber = PhoneNumber,
                isPayphone = false,
                callId = callId,
                networkError = exports["lb-phone"]:GetSourceFromNumber(PhoneNumber) == src
            }
        elseif Config.PhoneType == "QB" then
            exports["pma-voice"]:setPlayerCall(src, callId)
            local Target = FrameworkOptions.GetPlayerByPhone(PhoneNumber)
            if Target ~= nil and Target.PlayerData.source ~= src then
                TriggerClientEvent('qb-phone:client:GetCalled', Target.PlayerData.source, CallerNumber, callId, false)
            end

            Calls[src] = {
                callerSource = src,
                calleSource = Target ~= nil and Target.PlayerData.source or nil,
                CallerNumber = CallerNumber,
                PhoneNumber = PhoneNumber,
                isPayphone = false,
                isNotAvailable = Target == nil,
                networkError = Target ~= nil and Target.PlayerData.source == src,
                callId = callId
            }
        end
    else 
        Calls[src] = {
            callerSource = src,
            CallerNumber = CallerNumber,
            PhoneNumber = PhoneNumber,
            isPayphone = true,
            callId = callId,
            coords = Payphones[PhoneNumber],
        }
        
        TriggerClientEvent('retro_payphone:client:callNumber', -1, src, Calls[src])
    end
end)

RegisterServerEvent('retro_payphone:server:answerCall')
AddEventHandler('retro_payphone:server:answerCall', function(PhoneNumber)
    local src = source
    local call = nil

    for k, v in pairs(Calls) do
        if v.PhoneNumber == PhoneNumber then
            call = v

            Calls[k].calleSource = src
        end
    end

    if call then
        TriggerClientEvent('retro_payphone:client:hangUpOrOpen', -1, call.callerSource, true)
        if Config.PhoneType == "QB" and not call.isPayphone then
            TriggerClientEvent('qb-phone:client:AnswerCall', call.callerSource)
        end

        exports["pma-voice"]:setPlayerCall(call.callerSource, call.callId)
        exports["pma-voice"]:setPlayerCall(src, call.callId)
    end
end)

RegisterServerEvent('retro_payphone:server:cancelCallQB')
AddEventHandler('retro_payphone:server:cancelCallQB', function(CellPhoneSource)
    local src = source
    local call = Calls[CellPhoneSource]
    local callFromQB = true
    if not call then
        for k, v in pairs(Calls) do
            if v.calleSource == CellPhoneSource then
                call = v
                callFromQB = false
            end
        end
    end
    if call then
        call.isCanceled = true
        TriggerClientEvent('retro_payphone:client:hangUpOrOpen', -1, call.callerSource, false)
        if callFromQB and not call.isConnected then
            Calls[CellPhoneSource] = nil
        end
    end
end)

RegisterServerEvent('retro_payphone:server:hangUp')
AddEventHandler('retro_payphone:server:hangUp', function()
    local src = source
    local call = Calls[src]

    if not call then
        for k, v in pairs(Calls) do
            if v.calleSource == src then
                call = v
            end
        end
    end

    if call then
        if call.isPayphone then
            TriggerClientEvent('retro_payphone:client:hangUpOrOpen', -1, call.callerSource, false)

            exports["pma-voice"]:setPlayerCall(call.callerSource, 0)
            exports["pma-voice"]:setPlayerCall(src, 0)
        else
            if Config.PhoneType == "LB" then
                exports["lb-phone"]:EndCall(call.callerSource)
                exports["lb-phone"]:EndCall(call.calleSource)
            elseif Config.PhoneType == "QB" then
                exports["pma-voice"]:setPlayerCall(call.callerSource, 0)
                exports["pma-voice"]:setPlayerCall(call.calleSource, 0)
                TriggerClientEvent('qb-phone:client:CancelCall', call.callerSource)
                TriggerClientEvent('qb-phone:client:CancelCall', call.calleSource)
            end
            TriggerClientEvent('retro_payphone:client:hangUpOrOpen', -1, call.callerSource, false)
        end

        Calls[call.callerSource] = nil
    end
end)

RegisterServerEvent('retro_payphone:server:payphoneCall')
AddEventHandler('retro_payphone:server:payphoneCall', function(CallerSource, PayphoneNumber, CallerNumber, CallId)
    Calls[CallerSource] = {
        callerSource = CallerSource,
        CallerNumber = CallerNumber,
        PhoneNumber = PayphoneNumber,
        isPayphone = false,
        callId = CallId,
        coords = Payphones[PayphoneNumber],
    }

    TriggerClientEvent('retro_payphone:client:callNumber', -1, CallerSource, Calls[CallerSource])
end)

function GetCallState(PayphoneNumber)
    local payphone = Payphones[PayphoneNumber]

    if not payphone then
        return false, false
    end

    local call = nil

    for k, v in pairs(Calls) do
        if v.PhoneNumber == PayphoneNumber then
            call = v
        end
    end

    if call then
        return false, true
    else
        return true, true
    end
end

exports('GetCallState', GetCallState)