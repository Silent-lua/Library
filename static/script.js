document.addEventListener("DOMContentLoaded", () => {
    initNavigation();
    initDragAndDrop();
});

// ----------------------------------------------------
// NAVEGACIÓN ENTRE SECCIONES
// ----------------------------------------------------
function initNavigation() {
    const sidebarItems = document.querySelectorAll(".sidebar-item, .nav-btn");
    const views = document.querySelectorAll(".dashboard-view");

    sidebarItems.forEach(item => {
        item.addEventListener("click", () => {
            const targetView = item.getAttribute("data-target");
            if (!targetView) return;

            sidebarItems.forEach(sib => sib.classList.remove("active"));
            item.classList.add("active");

            views.forEach(view => {
                view.classList.remove("active-view");
                if (view.id === `${targetView}-view`) {
                    view.classList.add("active-view");
                }
            });
        });
    });
}

// ----------------------------------------------------
// PERSISTENCIA Y OPERACIONES DE LUA SCRIPTS
// ----------------------------------------------------
async function toggleScript(id) {
    try {
        const response = await fetch(`/api/scripts/toggle/${id}`, { 
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        if (!response.ok) throw new Error("Error al cambiar estado del script.");
    } catch (err) {
        console.error(err);
        alert("No se pudo actualizar el estado del script.");
    }
}

async function deleteScript(id) {
    if (!confirm("¿Seguro que deseas eliminar este script de forma permanente?")) return;
    
    try {
        const response = await fetch(`/api/scripts/delete/${id}`, { 
            method: 'DELETE' 
        });
        if (response.ok) {
            location.reload();
        } else {
            throw new Error("No se pudo eliminar de la BD.");
        }
    } catch (err) {
        console.error(err);
        alert("Error al intentar eliminar el script.");
    }
}

function openScriptModal() {
    document.getElementById("script-modal").classList.add("active-modal");
}

function closeScriptModal() {
    document.getElementById("script-modal").classList.remove("active-modal");
    document.getElementById("modal-script-name").value = "";
    document.getElementById("modal-script-universe").value = "";
    document.getElementById("modal-script-code").value = "";
}

async function saveScript() {
    const name = document.getElementById("modal-script-name").value.trim();
    const universe = document.getElementById("modal-script-universe").value.trim();
    const code = document.getElementById("modal-script-code").value;

    if (!name || !universe) {
        alert("Por favor rellena el nombre y el ID de universo.");
        return;
    }

    try {
        const response = await fetch('/api/scripts/create', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: name, universe_id: universe, code: code })
        });

        if (response.ok) {
            closeScriptModal();
            location.reload();
        } else {
            alert("Error al guardar el script en el servidor.");
        }
    } catch (err) {
        console.error(err);
        alert("No se pudo conectar con el servidor.");
    }
}

// ----------------------------------------------------
// SISTEMA DE LICENCIAS (EMISIONES REALES)
// ----------------------------------------------------
async function generateLicenseKey() {
    const prefix = document.getElementById("license-prefix").value.trim() || "SH_";
    const select = document.getElementById("license-duration");
    const duration = select.value;
    const uses = document.getElementById("license-uses").value || 1;

    // Generación segura de clave aleatoria
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let randomPart = "";
    for (let i = 0; i < 8; i++) {
        randomPart += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    const key = `${prefix}${randomPart}`;

    try {
        const response = await fetch('/api/licenses/create', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ key: key, duration: parseInt(duration), max_uses: parseInt(uses) })
        });

        if (response.ok) {
            location.reload();
        } else {
            alert("Error al guardar la licencia.");
        }
    } catch (err) {
        console.error(err);
    }
}

async function revokeLicense(id) {
    if (!confirm("¿Deseas revocar esta llave de acceso?")) return;

    try {
        const response = await fetch(`/api/licenses/revoke/${id}`, { 
            method: 'POST' 
        });
        if (response.ok) {
            location.reload();
        }
    } catch (err) {
        console.error(err);
    }
}

// ----------------------------------------------------
// GESTIÓN DE ARCHIVOS (SUBIDAS DIRECTAS)
// ----------------------------------------------------
function initDragAndDrop() {
    const dropZone = document.getElementById("drop-zone");
    const fileUploader = document.getElementById("file-uploader");

    if (!dropZone || !fileUploader) return;

    dropZone.addEventListener("click", () => fileUploader.click());

    dropZone.addEventListener("dragover", (e) => {
        e.preventDefault();
        dropZone.classList.add("dragover");
    });

    dropZone.addEventListener("dragleave", () => {
        dropZone.classList.remove("dragover");
    });

    dropZone.addEventListener("drop", (e) => {
        e.preventDefault();
        dropZone.classList.remove("dragover");
        if (e.dataTransfer.files.length > 0) {
            handleUploadedFiles(e.dataTransfer.files);
        }
    });

    fileUploader.addEventListener("change", () => {
        if (fileUploader.files.length > 0) {
            handleUploadedFiles(fileUploader.files);
        }
    });
}

async function handleUploadedFiles(files) {
    const formData = new FormData();
    for (let i = 0; i < files.length; i++) {
        formData.append('files[]', files[i]);
    }

    try {
        const response = await fetch('/api/files/upload', {
            method: 'POST',
            body: formData
        });

        if (response.ok) {
            location.reload();
        } else {
            alert("Error al subir los archivos.");
        }
    } catch (err) {
        console.error(err);
    }
}

function copyLink(filename) {
    const fullLink = `${window.location.origin}/static/uploads/${filename}`;
    navigator.clipboard.writeText(fullLink).then(() => {
        alert("Enlace copiado de forma segura:\n" + fullLink);
    }).catch(err => {
        // Fallback en caso de navegadores con restricciones de portapapeles
        const tempInput = document.createElement("input");
        tempInput.value = fullLink;
        document.body.appendChild(tempInput);
        tempInput.select();
        document.execCommand("copy");
        document.body.removeChild(tempInput);
        alert("Enlace copiado de forma segura:\n" + fullLink);
    });
}

async function deleteFile(id) {
    if (!confirm("¿Deseas eliminar permanentemente este archivo físico del servidor?")) return;

    try {
        const response = await fetch(`/api/files/delete/${id}`, { 
            method: 'DELETE' 
        });
        if (response.ok) {
            location.reload();
        }
    } catch (err) {
        console.error(err);
    }
}

// ----------------------------------------------------
// INTEGRACIONES Y CONFIGURACIONES (SETTINGS)
// ----------------------------------------------------
async function saveWebhooks() {
    const executionUrl = document.getElementById("webhook-execution").value.trim();
    const auditUrl = document.getElementById("webhook-audit").value.trim();

    try {
        const response = await fetch('/api/settings/webhooks', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ webhook_execution: executionUrl, webhook_audit: auditUrl })
        });

        if (response.ok) {
            alert("Canales de Webhooks actualizados correctamente.");
        } else {
            alert("No se pudieron registrar las URLs de Discord.");
        }
    } catch (err) {
        console.error(err);
    }
}

async function toggleProtectionSetting(key) {
    const element = key === 'restrict_ips' ? document.getElementById("restrict-ips") : document.getElementById("maintenance-mode");
    const active = element.checked;

    try {
        const response = await fetch('/api/settings/protection', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ key: key, active: active })
        });

        if (!response.ok) throw new Error("Error de guardado.");
    } catch (err) {
        console.error(err);
        element.checked = !active; // Revierte el estado del checkbox si falla
        alert("Ocurrió un problema guardando el ajuste de protección.");
    }
}
