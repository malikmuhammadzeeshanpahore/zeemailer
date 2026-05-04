document.addEventListener('DOMContentLoaded', () => {
    // Views
    const setupView = document.getElementById('setup-view');
    const dashboardView = document.getElementById('dashboard-view');
    const wizardView = document.getElementById('wizard-view');

    // Wizard Steps
    const steps = [
        document.getElementById('step-1'),
        document.getElementById('step-2'),
        document.getElementById('step-3'),
        document.getElementById('step-4'),
        document.getElementById('step-5'),
        document.getElementById('step-6')
    ];

    let currentData = [];
    let currentHeaders = [];
    // Custom variables: [{ varName: 'Name', colName: 'Full Name' }, ...]
    let customVars = [];

    // Default built-in variables (mapped from step 2)
    const builtinVars = [];

    // Initialize App
    checkStatus();

    async function checkStatus() {
        try {
            const res = await fetch('/api/status');
            const data = await res.json();
            if (data.isSetup) {
                showView(dashboardView);
                loadAnalytics();
            } else {
                showView(setupView);
            }
        } catch (e) {
            console.error("Failed to fetch status", e);
        }
    }

    function showView(view) {
        setupView.classList.add('hidden');
        dashboardView.classList.add('hidden');
        wizardView.classList.add('hidden');
        view.classList.remove('hidden');
    }

    function showStep(index) {
        steps.forEach((step, i) => {
            if (i === index) step.classList.remove('hidden');
            else step.classList.add('hidden');
        });
    }

    // Load Analytics
    async function loadAnalytics() {
        try {
            const res = await fetch('/api/analytics');
            const data = await res.json();
            document.getElementById('stat-sent').innerText = data.totalEmailsSent || 0;
            document.getElementById('stat-followup').innerText = data.totalFollowUps || 0;
            document.getElementById('stat-niches').innerText = data.niches.length ? data.niches.join(', ') : '-';
        } catch (e) {
            console.error(e);
        }
    }

    // Setup Form Submit
    document.getElementById('setup-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = e.target.querySelector('button');
        btn.innerText = 'Saving...';
        
        const payload = {
            emailUser: document.getElementById('setup-email').value,
            emailPass: document.getElementById('setup-pass').value,
            emailHost: document.getElementById('setup-host').value,
            emailPort: document.getElementById('setup-port').value,
            geminiKey: document.getElementById('setup-gemini').value
        };

        const res = await fetch('/api/setup', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (res.ok) {
            showView(dashboardView);
            loadAnalytics();
        } else {
            alert('Setup failed.');
            btn.innerText = 'Save Credentials';
        }
    });

    // Start Campaign
    document.getElementById('new-campaign-btn').addEventListener('click', () => {
        showView(wizardView);
        showStep(0);
        customVars = [];
        document.getElementById('file-upload').value = '';
    });

    document.getElementById('cancel-campaign-btn').addEventListener('click', () => {
        showView(dashboardView);
    });

    // Step 1 -> 2 (Upload File)
    document.getElementById('upload-btn').addEventListener('click', async () => {
        const fileInput = document.getElementById('file-upload');
        if (!fileInput.files.length) return alert('Please select a file.');

        const btn = document.getElementById('upload-btn');
        btn.innerText = 'Uploading...';

        const formData = new FormData();
        formData.append('file', fileInput.files[0]);

        try {
            const res = await fetch('/api/upload', {
                method: 'POST',
                body: formData
            });
            const result = await res.json();
            if (result.error) throw new Error(result.error);

            currentHeaders = result.headers;
            currentData = result.data;

            // Populate mapping selects
            const emailSelect = document.getElementById('map-email');
            const nameSelect = document.getElementById('map-name');
            const phoneSelect = document.getElementById('map-phone');
            
            emailSelect.innerHTML = '';
            nameSelect.innerHTML = '<option value="">None</option>';
            phoneSelect.innerHTML = '<option value="">None</option>';

            currentHeaders.forEach(hdr => {
                emailSelect.add(new Option(hdr, hdr));
                nameSelect.add(new Option(hdr, hdr));
                phoneSelect.add(new Option(hdr, hdr));
            });

            btn.innerText = 'Next';
            showStep(1);

        } catch (e) {
            alert(e.message);
            btn.innerText = 'Next';
        }
    });

    // Step 2 -> 3 (Mapping)
    document.getElementById('map-btn').addEventListener('click', () => {
        const emailCol = document.getElementById('map-email').value;
        if (!emailCol) return alert('Email column is required.');
        showStep(2);
    });

    // ─── Step 4: Prepare Template Editor ─────────────────────────────────────
    function openTemplateEditor(title, desc, prefillContent = '') {
        document.getElementById('step4-title').innerText = title;
        document.getElementById('step4-desc').innerText = desc;
        document.getElementById('email-template').value = prefillContent;
        document.getElementById('email-subject').value = '';

        // Build built-in vars from column mapping
        const builtins = [];
        const nameCol = document.getElementById('map-name').value;
        const phoneCol = document.getElementById('map-phone').value;
        if (nameCol) builtins.push({ varName: 'Name', colName: nameCol });
        if (phoneCol) builtins.push({ varName: 'Phone', colName: phoneCol });
        // Company is auto-detected
        builtins.push({ varName: 'Company', colName: '__auto_company__' });

        // Populate custom-var column dropdown with all headers
        const newVarCol = document.getElementById('new-var-col');
        newVarCol.innerHTML = '';
        currentHeaders.forEach(h => newVarCol.add(new Option(h, h)));

        // Reset custom vars and render
        customVars = [...builtins];
        renderVariables();

        showStep(3);
    }

    function renderVariables() {
        const list = document.getElementById('variables-list');
        list.innerHTML = '';
        customVars.forEach((v, idx) => {
            const tag = document.createElement('span');
            tag.className = 'var-tag';
            tag.title = `Maps to column: "${v.colName === '__auto_company__' ? 'auto-detected company column' : v.colName}"`;
            tag.innerHTML = `[${v.varName.toUpperCase()}] <span class="remove-var" data-idx="${idx}">✕</span>`;
            // Click on text part inserts the variable
            tag.addEventListener('click', (e) => {
                if (e.target.classList.contains('remove-var')) return;
                insertAtCursor(document.getElementById('email-template'), `[${v.varName.toUpperCase()}]`);
            });
            // Click on ✕ removes the var
            tag.querySelector('.remove-var').addEventListener('click', () => {
                customVars.splice(idx, 1);
                renderVariables();
            });
            list.appendChild(tag);
        });
    }

    function insertAtCursor(el, text) {
        const start = el.selectionStart;
        const end = el.selectionEnd;
        const val = el.value;
        el.value = val.substring(0, start) + text + val.substring(end);
        el.selectionStart = el.selectionEnd = start + text.length;
        el.focus();
    }

    document.getElementById('add-var-btn').addEventListener('click', () => {
        const nameInput = document.getElementById('new-var-name');
        const colSelect = document.getElementById('new-var-col');
        const varName = nameInput.value.trim().replace(/\s+/g, '_');
        const colName = colSelect.value;
        if (!varName) return alert('Please enter a variable name.');
        if (!colName) return alert('Please select a column to map it to.');
        // Check duplicate
        if (customVars.find(v => v.varName.toUpperCase() === varName.toUpperCase())) {
            return alert(`Variable [${varName.toUpperCase()}] already exists.`);
        }
        customVars.push({ varName, colName });
        renderVariables();
        nameInput.value = '';
    });

    // ─── Step 3 Buttons ──────────────────────────────────────────────────────

    // Generate with AI
    document.getElementById('generate-btn').addEventListener('click', async () => {
        const type = document.getElementById('camp-type').value;
        const agency = document.getElementById('camp-agency').value;
        const niche = document.getElementById('camp-niche').value;

        if (type === 'new' && (!agency || !niche)) {
            return alert('Agency and Niche are required for new campaigns.');
        }

        const btn = document.getElementById('generate-btn');
        btn.innerText = 'Generating with AI...';
        btn.disabled = true;

        try {
            const res = await fetch('/api/generate-template', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ campaignType: type, agencyName: agency, niche })
            });
            const result = await res.json();
            if (result.error) throw new Error(result.error);

            openTemplateEditor(
                'Step 4: Review AI Template',
                'The AI has drafted the following template. Click a variable tag to insert it, or edit freely.',
                result.template
            );

        } catch (e) {
            alert('⚠️ ' + e.message + '\n\nYou can write the template manually instead.');
        } finally {
            btn.innerText = '✨ Generate with AI';
            btn.disabled = false;
        }
    });

    // Write Manually
    document.getElementById('manual-btn').addEventListener('click', () => {
        openTemplateEditor(
            'Step 4: Write Template',
            'Write your email template below. Click a variable tag above to insert it at the cursor.',
            ''
        );
    });

    // ─── Step 4 -> 5 -> 6 (Send) ─────────────────────────────────────────────
    document.getElementById('send-btn').addEventListener('click', async () => {
        const subject = document.getElementById('email-subject').value;
        const template = document.getElementById('email-template').value;
        if (!subject) return alert('Please enter a Subject Line.');
        if (!template) return alert('Please write an email template.');

        showStep(4); // Loader view

        const payload = {
            subject,
            template,
            data: currentData,
            campaignType: document.getElementById('camp-type').value,
            niche: document.getElementById('camp-niche').value,
            mapping: {
                email: document.getElementById('map-email').value,
                name: document.getElementById('map-name').value,
                phone: document.getElementById('map-phone').value
            },
            customVars   // Send the custom variable → column mapping to backend
        };

        try {
            const res = await fetch('/api/send-campaign', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const result = await res.json();
            
            if (result.error) throw new Error(result.error);

            document.getElementById('success-count').innerText = `Sent to ${result.sentCount} contacts.`;
            showStep(5); // Success view

        } catch (e) {
            alert(e.message);
            showStep(3); // Back to review
        }
    });

    // Finish
    document.getElementById('finish-btn').addEventListener('click', () => {
        showView(dashboardView);
        loadAnalytics();
    });
});
