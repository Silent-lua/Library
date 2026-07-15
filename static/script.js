// =========================================
// SilentHub v2
// Mobile Sidebar Controller
// =========================================

const sidebar = document.getElementById("sidebar");
const overlay = document.getElementById("overlay");
const menuToggle = document.getElementById("menuToggle");

function openSidebar() {

    if (!sidebar) return;

    sidebar.classList.add("open");

    if (overlay) {
        overlay.classList.add("show");
    }

}

function closeSidebar() {

    if (!sidebar) return;

    sidebar.classList.remove("open");

    if (overlay) {
        overlay.classList.remove("show");
    }

}

if (menuToggle) {

    menuToggle.addEventListener("click", function () {

        if (sidebar.classList.contains("open")) {

            closeSidebar();

        } else {

            openSidebar();

        }

    });

}

if (overlay) {

    overlay.addEventListener("click", closeSidebar);

}

const menuLinks = document.querySelectorAll(".menu a");

menuLinks.forEach(function(link){

    link.addEventListener("click", function(){

        if (window.innerWidth <= 900){

            closeSidebar();

        }

    });

});

window.addEventListener("resize", function(){

    if(window.innerWidth > 900){

        closeSidebar();

    }

});
