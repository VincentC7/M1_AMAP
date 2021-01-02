document.addEventListener("DOMContentLoaded",function () {
    let btn_sign_up = document.getElementById("btn_sign_up");
    let sign_up_form = document.getElementById("sign_up_form");
    let sign_in_form = document.getElementById("sign_in_form");

    btn_sign_up.addEventListener("click",function () {
        sign_in_form.classList.add("d-none");
        sign_up_form.classList.remove("d-none");
    });

    let btn_cancel_sign_up = document.getElementById("cancel_sign_up");
    btn_cancel_sign_up.addEventListener("click",function () {
        sign_in_form.classList.remove("d-none");
        sign_up_form.classList.add("d-none");
    });
});