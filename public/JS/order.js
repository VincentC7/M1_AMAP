$(document).ready(function () {
    $('.slider').each(function () {
        rangeSlider($(this).attr('id'));
    });

    $('#order_form').submit(function (e) {
        if (e.originalEvent.submitter.id === "cancel_order") {
            window.location.replace($("#cancel_order").data("url"));
            return false;
        }
    });
});

let total_price = 0;

function rangeSlider(id) {
    var range = document.getElementById(id),
        down = false,
        rangeWidth, rangeLeft;

    range.addEventListener("mousedown", function(e) {
        rangeWidth = this.offsetWidth;
        rangeLeft = this.offsetLeft;
        down = true;
        updateDragger(e);
        return false;
    });

    range.addEventListener("mousemove", function(e) {
        updateDragger(e);
    });

    range.addEventListener("mouseup", function() {
        down = false;
        update_total_order_price();
    });

    function updateDragger(e) {
        if (down) {
            let elem = $('#'+id)
            elem.prev().text("Quantité ("+elem.val()+")");
        }
    }
}

function update_total_order_price() {
    total_price = 0;
    $('.slider').each(function () {
        total_price += (parseInt($(this).val()) * parseFloat($(this).data("price")));
    });
    $('#order_price').text("Total : "+total_price.toFixed(2) +"€");
}
