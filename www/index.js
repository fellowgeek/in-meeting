// JavaScript for In Meeting Landing Page (Nordic Frost)

document.addEventListener('DOMContentLoaded', () => {
    
    // ==========================================
    // 1. Theme Toggle Logic
    // ==========================================
    const themeToggleBtn = document.getElementById('theme-toggle');
    const body = document.body;
    
    // Check local storage or defaults
    const currentTheme = localStorage.getItem('theme') || 'dark';
    body.className = `theme-${currentTheme}`;
    
    themeToggleBtn.addEventListener('click', () => {
        if (body.classList.contains('theme-dark')) {
            body.classList.remove('theme-dark');
            body.classList.add('theme-light');
            localStorage.setItem('theme', 'light');
        } else {
            body.classList.remove('theme-light');
            body.classList.add('theme-dark');
            localStorage.setItem('theme', 'dark');
        }
    });

    // ==========================================
    // 2. Tab Navigation Logic (Build instructions)
    // ==========================================
    const tabHeaders = document.querySelectorAll('.tab-header');
    const tabPanels = document.querySelectorAll('.tab-panel');
    
    tabHeaders.forEach(header => {
        header.addEventListener('click', () => {
            const targetTab = header.getAttribute('data-tab');
            
            // Remove active states
            tabHeaders.forEach(h => h.classList.remove('active'));
            tabPanels.forEach(p => p.classList.remove('active'));
            
            // Add active state to selected
            header.classList.add('active');
            document.getElementById(`tab-${targetTab}`).classList.add('active');
        });
    });

    // ==========================================
    // 3. Copy to Clipboard Utility
    // ==========================================
    const copyButtons = document.querySelectorAll('.btn-copy');
    
    copyButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const textToCopy = btn.getAttribute('data-copy');
            
            navigator.clipboard.writeText(textToCopy).then(() => {
                const originalText = btn.textContent;
                btn.textContent = 'Copied!';
                btn.classList.add('copied');
                
                setTimeout(() => {
                    btn.textContent = originalText;
                    btn.classList.remove('copied');
                }, 2000);
            }).catch(err => {
                console.error('Could not copy text: ', err);
            });
        });
    });

    // ==========================================
    // 4. Live Status Simulator Logic
    // ==========================================
    const menuBarTrigger = document.getElementById('menu-bar-trigger');
    const statusIcon = document.getElementById('status-icon');
    const currentModeBadge = document.getElementById('current-mode-badge');
    const terminalContent = document.getElementById('terminal-content');
    
    const btnSetActive = document.getElementById('btn-set-active');
    const btnSetInactive = document.getElementById('btn-set-inactive');
    const btnSetPaused = document.getElementById('btn-set-paused');
    
    const deviceTypeInputs = document.getElementsByName('sim-device-type');
    
    // States: 'active', 'inactive', 'paused'
    let currentAppState = 'active'; 
    
    function getSelectedDeviceName() {
        let selectedValue = 'camera';
        deviceTypeInputs.forEach(input => {
            if (input.checked) selectedValue = input.value;
        });
        return selectedValue === 'camera' ? 'FaceTime HD Camera' : 'Built-in Microphone';
    }
    
    function getSelectedDeviceType() {
        let selectedValue = 'camera';
        deviceTypeInputs.forEach(input => {
            if (input.checked) selectedValue = input.value;
        });
        return selectedValue === 'camera' ? 'Camera' : 'Microphone';
    }

    function updateSimulatorUI() {
        // Remove old classes
        statusIcon.className = 'status-icon';
        currentModeBadge.className = 'mode-badge';
        
        // Remove active class from toggle buttons
        btnSetActive.classList.remove('active');
        btnSetInactive.classList.remove('active');
        btnSetPaused.classList.remove('active');
        
        switch (currentAppState) {
            case 'active':
                statusIcon.classList.add('icon-active');
                currentModeBadge.classList.add('badge-active');
                currentModeBadge.textContent = 'ACTIVE';
                btnSetActive.classList.add('active');
                break;
                
            case 'inactive':
                statusIcon.classList.add('icon-idle');
                currentModeBadge.classList.add('badge-inactive');
                currentModeBadge.textContent = 'IDLE';
                btnSetInactive.classList.add('active');
                break;
                
            case 'paused':
                statusIcon.classList.add('icon-paused');
                currentModeBadge.classList.add('badge-paused');
                currentModeBadge.textContent = 'PAUSED';
                btnSetPaused.classList.add('active');
                break;
        }
    }
    
    function logToTerminal(message, type = 'info') {
        const timestamp = new Date().toISOString().split('T')[1].slice(0, 8);
        let logLine = '';
        
        switch (type) {
            case 'info':
                logLine = `<span class="term-dim">[${timestamp}] ${message}</span>`;
                break;
            case 'active':
                logLine = `<span class="term-dim">[${timestamp}]</span> <span class="term-green">[Active] ${message}</span>`;
                break;
            case 'inactive':
                logLine = `<span class="term-dim">[${timestamp}]</span> <span class="term-yellow">[Inactive] ${message}</span>`;
                break;
            case 'success':
                logLine = `<span class="term-dim">[${timestamp}]</span> <span class="term-green">${message}</span>`;
                break;
            case 'warning':
                logLine = `<span class="term-dim">[${timestamp}]</span> <span class="term-yellow">${message}</span>`;
                break;
            case 'error':
                logLine = `<span class="term-dim">[${timestamp}]</span> <span class="term-red">${message}</span>`;
                break;
        }
        
        terminalContent.innerHTML += '\n' + logLine;
        
        // Auto scroll terminal to bottom
        const terminalBody = document.querySelector('.terminal-body');
        terminalBody.scrollTop = terminalBody.scrollHeight;
    }
    
    // Action functions
    function setDeviceState(state) {
        if (currentAppState === state) return; // No change
        
        currentAppState = state;
        updateSimulatorUI();
        
        const deviceName = getSelectedDeviceName();
        const deviceType = getSelectedDeviceType();
        
        if (state === 'active') {
            logToTerminal(`${deviceType}: ${deviceName}`, 'active');
            logToTerminal(`[Webhook Info] Dispatching HTTP POST to http://localhost:8080/active...`);
            setTimeout(() => {
                logToTerminal(`[Webhook Success] Server returned 200 OK.`, 'success');
            }, 400);
        } else if (state === 'inactive') {
            logToTerminal(`${deviceType}: ${deviceName}`, 'inactive');
            logToTerminal(`[Webhook Info] Dispatching HTTP POST to http://localhost:8080/inactive...`);
            setTimeout(() => {
                logToTerminal(`[Webhook Success] Server returned 200 OK.`, 'success');
            }, 400);
        } else if (state === 'paused') {
            logToTerminal(`Detection PAUSED. Observers temporarily suspended.`, 'warning');
            logToTerminal(`[Webhook Info] Status events short-circuited. No webhooks will fire.`);
        }
    }
    
    // Cycle when clicking status bar directly
    menuBarTrigger.addEventListener('click', () => {
        if (currentAppState === 'active') {
            setDeviceState('inactive');
        } else if (currentAppState === 'inactive') {
            setDeviceState('paused');
        } else {
            setDeviceState('active');
        }
    });
    
    // Control panel buttons
    btnSetActive.addEventListener('click', () => setDeviceState('active'));
    btnSetInactive.addEventListener('click', () => setDeviceState('inactive'));
    btnSetPaused.addEventListener('click', () => setDeviceState('paused'));
    
    // Hardware type selectors
    deviceTypeInputs.forEach(input => {
        input.addEventListener('change', () => {
            const devName = getSelectedDeviceName();
            logToTerminal(`Selected Focus Device: ${devName}`);
        });
    });
});
