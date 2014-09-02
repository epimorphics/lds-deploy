/* 
    start a timer to refresh the status of an action view
*/
'use strict';

$(function () {
    var timerID;
    var offset = 0;

    var makeProgressBar = function(percent, completed, success) {
        var bar = '<div class="progress-bar ';
        if (completed) {
            bar += success ? 'progress-bar-success' : 'progress-bar-danger';
        }
        bar += '" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="'
            + percent +'"  style="width: ' + percent + '%;"><span class="sr-only">' + percent + '% Complete</span>';
        if (completed) {
            bar += '<span>Completed</span>';
        } else {
            bar += '<span>In progress ...</span>';
        }
        bar += '</div>';
        return bar;
    }

    var updateProgress = function(data) {
        if(data.state === 'Terminated') {
            clearInterval(timerID);
            $('#progress').html( makeProgressBar(100, true, data.succeeded) );
            // Refresh to see updated status as static page
            window.location = $('#actionview').attr('data-target');
        } else {
            $('#progress').html( makeProgressBar(data.progress, false, data.succeeded) );
        }
        for (var i = 0; i < data.messages.length; i++) {
            var message = data.messages[i];
            $('#messages').append(
                '<div class="progress-message ' + message.type + '">' + message.message + '</div>'
                );
        }
        offset += data.messages.length;
    };

    var checkProgress = function() {
        var target = $('#actionview').attr('data-messages');
        $.getJSON(target, {'since': offset}, updateProgress);
    };

    timerID = setInterval(checkProgress, 400);

});
