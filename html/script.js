const resourceName = 'lz-trashsystem'; // Change if needed

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === "openSelector") {
        document.getElementById('selector-ui').style.display = "block";
        document.getElementById('manager-ui').style.display = "none";
    }
    
    if (data.action === "openManager") {
        document.getElementById('manager-ui').style.display = "block";
        document.getElementById('selector-ui').style.display = "none";
        loadTrashList(data.trashData);
    }
});

// Close UI on ESC key
document.onkeyup = function(data) {
    if (data.which == 27) {
        closeUI();
    }
};

function closeUI() {
    document.getElementById('selector-ui').style.display = "none";
    document.getElementById('manager-ui').style.display = "none";
    fetch(`https://${resourceName}/closeUI`, { method: 'POST' });
}

function selectProp(model) {
    closeUI();
    // Send selected model back to Client
    fetch(`https://${resourceName}/spawnTrash`, {
        method: 'POST',
        body: JSON.stringify({ model: model })
    });
}

function loadTrashList(data) {
    const list = document.getElementById('trash-list');
    list.innerHTML = ""; // Clear old list

    // Sort by ID
    data.sort((a, b) => a.id - b.id);

    data.forEach(item => {
        const row = document.createElement('div');
        row.className = 'trash-row';
        row.innerHTML = `
            <span>#${item.id}</span>
            <span>${item.prop_model}</span>
            <div class="actions">
                <button class="btn-icon btn-teleport" onclick="teleportTo(${item.id})">
                    <i class="fas fa-map-marker-alt"></i>
                </button>
                <button class="btn-icon btn-delete" onclick="deleteTrash(${item.id})">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `;
        list.appendChild(row);
    });
}

function teleportTo(id) {
    fetch(`https://${resourceName}/teleportTrash`, {
        method: 'POST',
        body: JSON.stringify({ id: id })
    });
}

function deleteTrash(id) {
    fetch(`https://${resourceName}/deleteTrash`, {
        method: 'POST',
        body: JSON.stringify({ id: id })
    });
    closeUI(); 
}