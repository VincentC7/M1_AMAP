$(document).ready( function () {
    setTimeout(function () {
        $(`.alert`).remove();
    },10000);

    $("#sub-start").change(function () {
        $(".price_abo").toggleClass("d-none");
    });

    $('#cancel_basket').click(function () {
        $(this).toggleClass("d-none");
        $(this).parent().next().toggleClass("d-none");
    });

    $("#cancel_sub").click(function () {
        $(this).toggleClass("d-none");
        $(this).next().toggleClass("d-none");
    });

    $("#update_sub").click(function () {
        $(this).toggleClass("d-none");
        $(this).next().toggleClass("d-none");
    });

    $("#progressbar li").click(function () {
        $("#progressbar li").removeClass("active");
        $(this).prevAll().addClass("active");
        $(this).addClass("active");
        let url = $(this).data("url");
        window.location.replace(url);
    });
});