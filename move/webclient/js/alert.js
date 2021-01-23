'use strict';

(function ($) {
    var $alert = $('#alert');
    var $alertHeader = $alert.find('.header');
    var $alertMessage = $alert.find('.message');
    var $alertCloseButton = $alert.find('.close');
    
    var isVisible = false;
    var timer = null;
    
    function alertIn() {
        $alert.slideDown('slow', function() {
            isVisible = true
        });
    }
    
    function alertOut() {
        $alert.slideUp('slow', function() {
            isVisible = false
        });
    }
    
    function alertAbort() {
        clearTimeout(timer);
        alertOut();
    }
    
    function alert(header, message) {
        $alertHeader.html(header);
        $alertMessage.html(message);
        
        if(!isVisible) {
            alertIn();
            timer = setTimeout(alertOut, 4000);
        } else {
            // reset timeout
            clearTimeout(timer);
            timer = setTimeout(alertOut, 5000);
        }
    }
    
    $alertCloseButton.click(alertAbort);
    
    $.extend({
        alertSuccess: function(message) {
            $alert.removeClass('alert-danger').addClass('alert-success');
            alert('Success', message);
        },
        alertError: function(message) {
            $alert.removeClass('alert-success').addClass('alert-danger');
            alert('You cancelled the challenge', message);
        }
    });
})(jQuery);
