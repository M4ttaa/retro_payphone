let isCalling = false;
let canMakeCall = true;
let isOpened = false;
let phoneNumber = '';
let timeoutCall = null;
let Locale = {};
let HangUpTime = 0;
let RingSeconds = 15000;

const callSound = new Audio('./assets/sounds/calling.mp3');
const openSound = new Audio('./assets/sounds/open.mp3');
const hangUpSound = new Audio('./assets/sounds/close_sound.mp3');

function formatUSNumber(entry = '') {
    if (!entry) return ''
    const match = entry
        .replace(/\D+/g, '')
        .match(/([^\d]*\d[^\d]*){1,10}$/)?.[0]

    if (!match) return phoneNumber

    const part1 = match.length > 2 ? `(${match.substring(0, 3)})` : match
    const part2 = match.length > 3 ? ` ${match.substring(3, 6)}` : ''
    const part3 = match.length > 6 ? `-${match.substring(6, 10)}` : ''
    return `${part1}${part2}${part3}`
}

$(document).ready(function () {

    $('.CallButton').click(function () {
        if (!canMakeCall) {
            return;
        }

        if (isCalling) {
            HangUp();
            return;
        }

        Call();
    });

    $('.NumericButton').click(function () {
        if (isCalling) {
            return;
        }

        const number = $(this).attr('id').split('-')[1];

        const soundName = number === '*' ? 'asterisk' : number === '#' ? 'hashtag' : number;

        const sound = new Audio(`./assets/sounds/${soundName}.mp3`);

        sound.play()

        sound.onended = function () {
            sound.remove();
        }

        if (number === '#') {
            phoneNumber = phoneNumber.slice(0, -1);
            $('.Screen').text(formatUSNumber(phoneNumber));
            return;
        }

        if (phoneNumber.length >= 10) {
            return
        }

        phoneNumber += number;
        $('.Screen').text(formatUSNumber(phoneNumber));
    });
});

const Refresh = (customString) => {
    if (isCalling) {
        $('.Screen').text(Locale["CALL_ENDED"]);
    }

    if (customString) {
        $('.Screen').text(customString);
    }

    if (!isCalling) {
        setTimeout(() => {
            $('.Screen').text('');
            $('body').fadeOut();
        }, 1000);
    }

    HangUp(true);
    setTimeout(() => {
        hangUpSound.pause();
    }, 1000);
    callSound.pause();
    phoneNumber = '';
    canMakeCall = true;
}

const HangUp = (forceHangUp) => {
    if (!isCalling) {
        return;
    }

    $.post(`https://${GetParentResourceName()}/HANG_UP`, JSON.stringify({}));

    isCalling = false;
    $('.PayphoneArm').animate({
        rotate: '+=40deg',
        'margin-left': '0rem',
    }, 1000, 'swing', function () {
        hangUpSound.currentTime = 0;

        let hangupPromise = hangUpSound.play();

        if (hangupPromise !== undefined) {
            hangupPromise.then(_ => {
                callSound.pause();
            })
        }

        $('.CallButton').removeClass('Red');

        if (!forceHangUp) {
            $('.Screen').text(Locale["CALL_ENDED"]);
        }

        canMakeCall = false;

        setTimeout(() => {
            $("body").fadeOut();
            $.post(`https://${GetParentResourceName()}/CLOSE_PAYPHONE`, JSON.stringify({}));
            $('.Screen').text('');
        }, 2500);

    });
}

const Call = (CallAnimationOnly) => {
    if (isCalling || (phoneNumber.length === 0 && !CallAnimationOnly)) {
        return;
    }

    if (!CallAnimationOnly) {
        $.post(`https://${GetParentResourceName()}/CALL_NUMBER`, JSON.stringify({
            PhoneNumber: phoneNumber
        }));
    }

    phoneNumber = '';

    isCalling = true;

    $('.PayphoneArm').animate({
        rotate: '-=40deg',
        'margin-left': '-120rem',

    }, 1000, 'swing', function () {

        $('.CallButton').addClass('Red');

        callSound.currentTime = 0;

        callSound.loop = true;

        let callSoundPromise = callSound.play();

        let dots = 0;

        let callSeconds = 0;

        $('.Screen').text(Locale["CALLING"]);

        let isOpenedInterval = setInterval(() => {
            if (isOpened) {
                if (callSoundPromise !== undefined) {
                    callSoundPromise.then(_ => {
                        callSound.pause();
                    })
                }
                clearInterval(isOpenedInterval);
            }
        }, 100);

        timeoutCall = setTimeout(() => {
            if (!isOpened) {
                $('.Screen').text(Locale["CALL_ENDED"]);
                setTimeout(() => {
                    Refresh();
                }, 1000);
            }
        }, RingSeconds);



        // Dot animation
        let interval = setInterval(() => {
            if (!isCalling) {
                clearInterval(interval);
                return;
            }

            if (isOpened) {
                callSeconds++;
                let minutes = Math.floor(callSeconds / 60) < 10 ? `0${Math.floor(callSeconds / 60)}` : Math.floor(callSeconds / 60);
                let seconds = callSeconds % 60 < 10 ? `0${callSeconds % 60}` : callSeconds % 60;
                $('.Screen').text(`${minutes}:${seconds}`);

                if(callSeconds > HangUpTime) {
                    HangUp(true)
                    $('.Screen').text(Locale["TIME_ENDED"]);
                }

                return;
            }



            if (dots >= 3) {
                dots = 0;
                $('.Screen').text(Locale["CALLING"]); 
                return;
            } else {
                $('.Screen').text($('.Screen').text() + '.');
                dots++;
            }
        }, 1000);
    });
}

window.addEventListener("message", function (event) {
    const data = event.data;
    const action = data.action;

    switch (action) {
        case "OPEN_PAYPHONE":
            clearTimeout(timeoutCall);
            timeoutCall = null;
            $("body").fadeIn();
            $(".Screen").text("");
            openSound.play();
            $(".PayphoneNumber").text(formatUSNumber(data.PhoneNumber));
            isCalling = false;
            isOpened = false;
            canMakeCall = true;

            if (data.isCalling) {
                Call(true);
            }
            break;
        case "CLOSE_PAYPHONE":
            data.customMessage ? setTimeout(() => {
                Refresh(data.customMessage);
            }, 3500) :
                Refresh();
            break;
        case "PHONE_OPENED":
            isOpened = true;
            break;
        case "SET_CONFIG":
            Locale = data.Locale;
            HangUpTime = data.HangUpTime;
            RingSeconds = data.RingSeconds;
            break;
    }
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        $.post(`https://${GetParentResourceName()}/CLOSE_PAYPHONE`, JSON.stringify({}));
        Refresh();
    }

    if (event.key === 'Enter') {
        Call();
    }

    if (event.key === 'Backspace') {
        if (!isCalling) {
            phoneNumber = phoneNumber.slice(0, -1);
            $('.Screen').text(formatUSNumber(phoneNumber));
        } else {
            HangUp();
        }
    }

    for (let i = 0; i < 10; i++) {
        if (event.key === i.toString()) {
            $('.NumericButton#num-' + i).click();

            $('.NumericButton#num-' + i).prop('active', true);

            setTimeout(() => {
                $('.NumericButton#num-' + i).prop('active', false);
            }, 100);
        }
    }
});

window.addEventListener('paste', (event) => {
    let paste = (event.clipboardData || window.clipboardData).getData('text');
    if (paste.length > 10) {
        paste = paste.slice(0, 10);
    }

    if (isCalling) {
        return;
    }

    phoneNumber = paste;
    $('.Screen').text(formatUSNumber(phoneNumber));
});