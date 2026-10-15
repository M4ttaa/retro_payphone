Config = {
    ["Price"] = 1, -- Price to use the payphone
    --[[
        The time changes for the phone script.
        LB = 15000
        QB = (QB Phone Config) Config.RepeatTimeout * Config.CallRepeats (Default: 2000 * 10 = 20000)
    ]]--
    ["RingSeconds"] = 20000,
    ["PhoneType"] = "LB", -- QB, LB,
    ["Framework"] = "QB", -- QB, ESX, NONE
    ["PayphoneModels"] = {
        "p_phonebox_02_s",
        "prop_phonebox_03",
        "prop_phonebox_02",
        "prop_phonebox_04",
        "prop_phonebox_01c",
        "prop_phonebox_01a",
        "prop_phonebox_01b",
        "p_phonebox_01b_s"
    },
    ["CurrentLocale"] = "en",
    ["HangUpTime"] = 3 * 60, --minutes
    ["LostMoneyChance"] = 5, -- 5%
    ["Events"] = {
        -- ["911"] = {
        --     -- server, client, command
        --     ["event"] = function ()
        --         print('Test')
        --     end 
        -- },
        -- ["911"] = {
        --     -- server, client, command
        --     ["type"] = "client",
        --     ["event"] = "police:CallPolice"
        -- }
    },
    ["Locale"] = {
        ["tr"] = {
            ["NOT_AVAILABLE"] = "Ulaşılamıyor...",
            ["NETWORK_ERROR"] = "Şebeke hatası...",
            ["CALL_ENDED"] = "Çağrı bitti...",
            ["BUSY"] = "Meşgul...",
            ["CALLING"] = "Aranıyor",
            ["TIME_ENDED"] = "Süre bitti...",
            ["PAYPHONE"] = "Telefon Kulübesi",
            ["ANSWER_CALL"] = "Çağrıyı Cevapla",
            ["PAYPHONE_BROKEN"] = "Telefon kulubesi bozuk!",
            ["NOT_ENOUGH_MONEY"] = "Yeterli paranız yok!",
            ["LOST_MONEY"] = "1 dolar kaybettin!",
            ["SOMETHING_HAPPENED"] = "Bir şey oldu!",
        },
        ["en"] = {
            ["NOT_AVAILABLE"] = "Not available...",
            ["NETWORK_ERROR"] = "Network Error...",
            ["CALL_ENDED"] = "Call ended...",
            ["BUSY"] = "Busy...",
            ["CALLING"] = "Calling",
            ["TIME_ENDED"] = "Time Ended...",
            ["PAYPHONE"] = "Payphone",
            ["ANSWER_CALL"] = "Answer Call",
            ["PAYPHONE_BROKEN"] = "This payphone is broken!",
            ["NOT_ENOUGH_MONEY"] = "You don't have enough money!",
            ["LOST_MONEY"] = "You lost 1 penny!",
            ["SOMETHING_HAPPENED"] = "Something happened!",
        },
        ["fr"] = {
            ["NOT_AVAILABLE"] = "Pas disponible...",
            ["NETWORK_ERROR"] = "Erreur réseau...",
            ["CALL_ENDED"] = "Appel terminé...",
            ["BUSY"] = "Occupé...",
            ["CALLING"] = "Appel",
            ["TIME_ENDED"] = "Heure de fin...",
            ["PAYPHONE"] = "Cabine téléphonique",
            ["ANSWER_CALL"] = "Répondre à un appel",
            ["PAYPHONE_BROKEN"] = "Ce téléphone public est cassé!",
            ["NOT_ENOUGH_MONEY"] = "Vous n'avez pas assez d'argent!",
            ["LOST_MONEY"] = "Vous avez perdu 1 centime!",
            ["SOMETHING_HAPPENED"] = "Quelque chose est arrivé!",
        },
    }
}

if Config["Framework"] == "QB" then
    FrameworkOptions = {
        SharedExport = exports['qb-core']:GetCoreObject(),
        OnPlayerLoaded = "QBCore:Client:OnPlayerLoaded",
        TriggerCallback = function(...)
            return FrameworkOptions.SharedExport.Functions.TriggerCallback(...)
        end,
        GetPlayerByPhone = function(PhoneNumber)
            return FrameworkOptions.SharedExport.Functions.GetPlayerByPhone(PhoneNumber)
        end,
        CreateCallback = function(...)
            return FrameworkOptions.SharedExport.Functions.CreateCallback(...)
        end,
        GetPlayer = function(...)
            return FrameworkOptions.SharedExport.Functions.GetPlayer(...)
        end,
        GetMoney = function(Player)
            return Player.PlayerData.money.cash
        end,
        RemoveMoney = function(Player, amount)
            return Player.Functions.RemoveMoney('cash', amount)
        end,
        GetSource = function (Player)
            return Player.source
        end,
        Notify = function(...)
            return FrameworkOptions.SharedExport.ShowNotification(...)
        end,
    }
elseif Config["Framework"] == "ESX" then
    FrameworkOptions = {
        SharedExport = exports['es_extended']:getSharedObject(),
        OnPlayerLoaded = "esx:playerLoaded",
        TriggerCallback = function(...)
            return FrameworkOptions.SharedExport.TriggerServerCallback(...)
        end,
        CreateCallback = function(...)
            return FrameworkOptions.SharedExport.RegisterServerCallback(...)
        end,
        GetPlayer = function(...)
            return FrameworkOptions.SharedExport.GetPlayerFromId(...)
        end,
        GetMoney = function(Player)
            return Player.getMoney()
        end,
        RemoveMoney = function(Player, amount)
            return Player.removeMoney(amount)
        end,
        GetSource = function (Player)
            return Player.source
        end,
        Notify = function(...)
            return FrameworkOptions.SharedExport.ShowNotification(...)
        end,
    }
else
    print("You are using a custom framework. You need to edit the config file.")
    FrameworkOptions = {
        SharedExport = nil,
        OnPlayerLoaded = "retro_payphone",
        TriggerCallback = function(...)
            -- custom framework
            return
        end,
        CreateCallback = function(...)
            -- custom framework
            return
        end,
        GetPlayer = function(...)
            -- custom framework
            return
        end,
        GetMoney = function(Player)
            -- custom framework
            return
        end,
        RemoveMoney = function(Player, amount)
            -- custom framework
            return
        end,
        GetSource = function (Player)
            -- custom framework
            return
        end,
        Notify = function(...)
            -- custom framework
            return
        end,
    }
end


