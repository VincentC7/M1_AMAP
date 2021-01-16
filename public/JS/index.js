$(document).ready( function () {
    setTimeout(function () {
        $(`.alert`).remove();
    },10000);

    $("#sub-start").change(function () {
        $(".price_abo").toggleClass("d-none");
    });
});