$(document).ready(function () {
    $('.slider').each(function () {
        rangeSlider($(this).attr('id'));
    });

});

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

    document.addEventListener("mousemove", function(e) {
        updateDragger(e);
    });

    document.addEventListener("mouseup", function() {
        down = false;
    });

    function updateDragger(e) {
        if (down) {
            let elem = $('#'+id)
            elem.prev().text("Quantité ("+elem.val()+")");
        }
    }

}