document.addEventListener("DOMContentLoaded", () => {
    initNavigation();
    loadDashboardData();
});

function initNavigation() {
    const sidebarItems = document.querySelectorAll(".sidebar-item");
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

async function loadDashboardData() {
    await fetchScripts();
    await fetchLicenses();
}

async function fetchScripts() {
    try {
        const response = await fetch('/api/scripts');
        const scripts = await response.json();
        renderScripts(scripts);
    } catch (error) {
        console.error(error);
    }
}

function renderScripts(scripts) {
    const container = document.getElementById("scripts-list");
    if (!container) return;

    container.innerHTML = "";
    scripts.forEach(script => {
        const card = document.createElement("div");
        card.className = "script-card";
        const isChecked = script.active === 1 ? "checked" : "";
        card.innerHTML = `
            <div class="script-details">
                <h4>${script.name}</h4>
                <span class="script-universe">${script.universe_id}</span>
            </div>
            <div class="script-actions">
                <label class="switch-control">
                    <input type="checkbox" ${isChecked} onchange="toggleScript(${script.id}, this.checked)">
                    <span class="slider-control"></span>
                </label>
                <button class="revoke-btn" onclick="deleteScript(${script.id})">Purge</button>
            </div>
        `;
        container.appendChild(card);
    });
}

async function toggleScript(id, isActive) {
    try {
        await fetch(`/api/scripts/${id}/toggle`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ active: isActive })
        });
    } catch (error) {
        console.error(error);
    }
}

async function deleteScript(id) {
    try {
        const response = await fetch(`/api/scripts/${id}`, {
            method: 'DELETE'
        });
        if (response.ok) {
            await fetchScripts();
        }
    } catch (error) {
        console.error(error);
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
    const name = document.getElementById("modal-script-name").value;
    const universe = document.getElementById("modal-script-universe").value;
    const code = document.getElementById("modal-script-code").value;

    if (!name || !universe || !code) return;

    try {
        const response = await fetch('/api/scripts', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: name, universe_id: universe, code: code })
        });

        if (response.ok) {
            await fetchScripts();
            closeScriptModal();
        }
    } catch (error) {
        console.error(error);
    }
}

async function fetchLicenses() {
    try {
        const response = await fetch('/api/licenses');
        const licenses = await response.json();
        renderLicenses(licenses);
    } catch (error) {
        console.error(error);
    }
}

function renderLicenses(licenses) {
    const tbody = document.getElementById("licenses-tbody");
    if (!tbody) return;

    tbody.innerHTML = "";
    licenses.forEach(lic => {
        const row = document.createElement("tr");
        const statusClass = lic.status === 'Active' ? 'active' : 'revoked';
        const actionBtn = lic.status === 'Active' 
            ? `<button class="revoke-btn" onclick="revokeLicense(${lic.id})">Terminate</button>` 
            : "-";

        row.innerHTML = `
            <td><code>${lic.key_string}</code></td>
            <td>${lic.duration}</td>
            <td>${lic.max_uses}</td>
            <td><span class="status-badge ${statusClass}">${lic.status}</span></td>
            <td>${actionBtn}</td>
        `;
        tbody.appendChild(row);
    });
}

async function generateLicenseKey() {
    const prefix = document.getElementById("license-prefix").value || "SH_";
    const select = document.getElementById("license-duration");
    const duration = select.options[select.selectedIndex].value;
    const uses = document.getElementById("license-uses").value || 1;

    try {
        const response = await fetch('/api/licenses', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ prefix: prefix, duration: duration, max_uses: parseInt(uses) })
        });

        if (response.ok) {
            await fetchLicenses();
        }
    } catch (error) {
        console.error(error);
    }
}

async function revokeLicense(id) {
    try {
        const response = await fetch(`/api/licenses/${id}/revoke`, {
            method: 'PUT'
        });
        
        if (response.ok) {
            await fetchLicenses();
        }
    } catch (error) {
        console.error(error);
    }
}
