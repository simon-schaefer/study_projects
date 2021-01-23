'use strict';

// https://stackoverflow.com/questions/1987524/turn-a-number-into-star-rating-display-using-jquery-and-css
$.fn.stars = function() {
    return $(this).each(function() {
        $(this).html($('<span />').width(Math.max(0, (Math.min(5, parseFloat($(this).html())))) * 16));
    });
}
