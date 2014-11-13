/* 
   Configure jquery.fileupload to upload files with progress report
*/

$(function () {
    'use strict';
/*    var url = '/dms/system/forms/upload?component=' + $('#fileupload').attr('data-target'); */
    var url = 'upload';
    $('#fileupload').fileupload({
        url: url,
        dataType: 'json',
        autoUpload: true,
        acceptFileTypes: /\.(csv|ttl|rdf|owl|nt|ru)$/i,
        // maxFileSize: 5000000, // switch on for chunking

        progressall: function (e, data) {
            var progress = parseInt(data.loaded / data.total * 100, 10);
            $('#progress .progress-bar').css(
                'width',
                progress + '%'
                );
        },

        add: function (e, data) {
            var filenames = "";
            $.each(data.originalFiles, function (index, file) {
                filenames = filenames + " <span>" + file.name + "</span>" 
            });
                $('#file-name').html(filenames);
                if (data.autoUpload || (data.autoUpload !== false &&
                $(this).fileupload('option', 'autoUpload'))) {
                data.process().done(function () {
                    data.submit();
                });
            }
        },

        // This version only works for single files but then that's what we currently use
        done: function (e, data) {
            $.each(data.result.files, function (index, file) {
                if (file.error) {
                    $("#file-result").html("<span class='text-danger'>" + file.error + "</span>");
                } else {
                    $("#file-result").html("<span class='text-success'><i class='fa fa-check text-success'></i></span>");
                    if (file.redirect) {
                        window.location = file.redirect;
                    }
                }
            });
        }
    });

    if (typeof(dataType) === typeof(Function)) {
        $('#uploads-table').dataTable(
        {
            "order": []
        } );
    }

});

