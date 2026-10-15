exports['qb-target']:AddTargetModel(Config.PayphoneModels, {
    options = {
        {
            event = 'retro_payphone:client:payphone',
            icon = 'fa-solid fa-phone',
            label = Locale("PAYPHONE") .. ' (' .. Config.Price .. '$)',
            canInteract = function(entity)
                return not IsAnyCallOnEntitiy(entity)
            end
        },
        {
            event = 'retro_payphone:client:answerCall',
            icon = 'fa-solid fa-phone-volume',
            label = Locale("ANSWER_CALL"),
            canInteract = function(entity)
                return IsAnyCallOnEntitiy(entity)
            end
        }
    },
    distance = 1,
})