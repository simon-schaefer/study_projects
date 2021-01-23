'use strict';

// https://www.sitepoint.com/build-javascript-countdown-timer-no-dependencies/
(function ($) {
    
    var $divCountdown = $('#countdownClock');
    var timeinterval;
    
    function getTimeRemaining(endtime) {
        var t = Date.parse(endtime) - Date.parse(new Date());
        var seconds = Math.floor((t / 1000) % 60);
        var minutes = Math.floor((t / 1000 / 60) % 60);
        var hours = Math.floor((t / (1000 * 60 * 60)) % 24);
        var days = Math.floor(t / (1000 * 60 * 60 * 24));
        return {
            'total': t,
            'days': days,
            'hours': hours,
            'minutes': minutes,
            'seconds': seconds
        };
    }
    
    function initializeClock(endtime) {
        var $spanDays = $divCountdown.find('.days');
        var $spanHours = $divCountdown.find('.hours');
        var $spanMinutes = $divCountdown.find('.minutes');
        var $spanSeconds = $divCountdown.find('.seconds');
        
        function updateClock() {
            
            var time = getTimeRemaining(endtime);
            
            $spanDays.html(time.days);
            $spanHours.html(('0' + time.hours).slice(-2));
            $spanMinutes.html(('0' + time.minutes).slice(-2));
            $spanSeconds.html(('0' + time.seconds).slice(-2));
            
            if (time.total <= 0) {
                // find winner team
                clearInterval(timeinterval);
            }
        }
        updateClock();
        timeinterval = setInterval(updateClock, 1000);
    }
    
    $.extend({
        setCountdown: function(deadline) {
            $divCountdown.css("display", "inline-block");
            initializeClock(deadline);
        },
        removeCountdown: function(deadline) {
            $divCountdown.css("display", "none");
            clearInterval(timeinterval);
        }
    });
})(jQuery);
