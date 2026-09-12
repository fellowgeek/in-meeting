/**
 * In Meeting — Landing Page Engine
 * Minimalist Swiss Signal & Raycast Elegance Interactive Controller
 */

document.addEventListener('DOMContentLoaded', () => {
    
    // ==========================================
    // 1. Theme Management
    // ==========================================
    const themeToggleBtn = document.getElementById('theme-toggle');
    const body = document.body;
    
    const savedTheme = localStorage.getItem('in-meeting-theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (savedTheme === 'light' || (!savedTheme && !prefersDark)) {
        body.classList.remove('theme-dark');
        body.classList.add('theme-light');
    } else {
        body.classList.remove('theme-light');
        body.classList.add('theme-dark');
    }
    
    if (themeToggleBtn) {
        themeToggleBtn.addEventListener('click', () => {
            const isDark = body.classList.contains('theme-dark');
            if (isDark) {
                body.classList.remove('theme-dark');
                body.classList.add('theme-light');
                localStorage.setItem('in-meeting-theme', 'light');
            } else {
                body.classList.remove('theme-light');
                body.classList.add('theme-dark');
                localStorage.setItem('in-meeting-theme', 'dark');
            }
        });
    }

    // ==========================================
    // 2. Interactive Simulator
    // ==========================================
    const simState = {
        cameraActive: false,
        micActive: false,
        isPaused: false
    };

    const toggleCameraBtn = document.getElementById('toggle-camera');
    const toggleMicBtn = document.getElementById('toggle-mic');
    const togglePauseBtn = document.getElementById('toggle-pause');

    const rowCamera = document.getElementById('device-row-camera');
    const rowMic = document.getElementById('device-row-mic');

    const labelCamStatus = document.getElementById('label-cam-status');
    const labelMicStatus = document.getElementById('label-mic-status');

    const simStatusItem = document.getElementById('sim-status-item');
    const simReactionBadge = document.getElementById('sim-reaction-badge');

    const tallyLight = document.getElementById('tally-light');
    const tallySub = document.getElementById('tally-sub');

    const fileBadge = document.getElementById('file-state-badge');
    const fileOutputText = document.getElementById('file-output-text');

    const webhookPayloadJson = document.getElementById('webhook-payload-json');

    const simToast = document.getElementById('sim-toast');
    const toastBodyText = document.getElementById('toast-body-text');
    let toastTimeout = null;

    function showSimToast(message) {
        if (!simToast || !toastBodyText) return;
        toastBodyText.textContent = message;
        simToast.classList.add('show');
        if (toastTimeout) clearTimeout(toastTimeout);
        toastTimeout = setTimeout(() => {
            simToast.classList.remove('show');
        }, 3200);
    }

    function renderSimulator(lastTriggeredDevice, lastStatus) {
        // 1. Device Toggles & Rows
        if (toggleCameraBtn) {
            toggleCameraBtn.setAttribute('aria-pressed', simState.cameraActive ? 'true' : 'false');
        }
        if (toggleMicBtn) {
            toggleMicBtn.setAttribute('aria-pressed', simState.micActive ? 'true' : 'false');
        }
        if (togglePauseBtn) {
            togglePauseBtn.setAttribute('aria-pressed', simState.isPaused ? 'true' : 'false');
        }

        if (rowCamera) {
            rowCamera.classList.toggle('is-active', simState.cameraActive);
        }
        if (rowMic) {
            rowMic.classList.toggle('is-active', simState.micActive);
            rowMic.classList.toggle('mic-active', simState.micActive);
        }

        if (labelCamStatus) {
            labelCamStatus.textContent = simState.cameraActive ? 'Active (Capturing)' : 'Idle (Closed)';
        }
        if (labelMicStatus) {
            labelMicStatus.textContent = simState.micActive ? 'Active (Recording)' : 'Idle (Muted)';
        }

        // 2. Menu Bar Extra Icon Status
        if (simStatusItem) {
            simStatusItem.classList.remove('active-camera', 'active-mic', 'paused');
            if (simState.isPaused) {
                simStatusItem.classList.add('paused');
            } else if (simState.cameraActive) {
                simStatusItem.classList.add('active-camera');
            } else if (simState.micActive) {
                simStatusItem.classList.add('active-mic');
            }
        }

        // Check overall capture state
        const anyActive = (simState.cameraActive || simState.micActive) && !simState.isPaused;

        // 3. Reaction Badge
        if (simReactionBadge) {
            if (simState.isPaused) {
                simReactionBadge.textContent = 'Paused';
                simReactionBadge.className = 'col-badge';
            } else if (anyActive) {
                simReactionBadge.textContent = 'Dispatched (< 0.8ms)';
                simReactionBadge.className = 'col-badge active-red';
            } else {
                simReactionBadge.textContent = 'Standing By';
                simReactionBadge.className = 'col-badge green';
            }
        }

        // 4. Studio Tally Light
        if (tallyLight && tallySub) {
            tallyLight.classList.remove('lit-red', 'lit-amber');
            if (simState.isPaused) {
                tallyLight.textContent = 'PAUSED';
                tallySub.textContent = 'Triggers suspended by menu bar pause';
            } else if (simState.cameraActive) {
                tallyLight.classList.add('lit-red');
                tallyLight.textContent = 'ON AIR';
                tallySub.textContent = 'Office Door Light: RED (Camera Active)';
            } else if (simState.micActive) {
                tallyLight.classList.add('lit-amber');
                tallyLight.textContent = 'LIVE MIC';
                tallySub.textContent = 'Office Door Light: AMBER (Microphone Active)';
            } else {
                tallyLight.textContent = 'IDLE';
                tallySub.textContent = 'Office Door Light: GREEN (Available / Free)';
            }
        }

        // 5. Local Status File (~/.in-meeting)
        if (fileBadge && fileOutputText) {
            if (anyActive) {
                fileBadge.textContent = 'active';
                fileBadge.classList.add('active');
                fileOutputText.textContent = '"active"';
                fileOutputText.classList.add('active');
            } else {
                fileBadge.textContent = 'inactive';
                fileBadge.classList.remove('active');
                fileOutputText.textContent = '"inactive"';
                fileOutputText.classList.remove('active');
            }
        }

        // 6. Webhook Payload JSON
        if (webhookPayloadJson) {
            const now = new Date().toISOString();
            let payloadObj = {};

            if (simState.isPaused) {
                payloadObj = {
                    status: 'suppressed',
                    reason: 'detection_paused',
                    timestamp: now
                };
            } else if (lastTriggeredDevice) {
                payloadObj = {
                    device: lastTriggeredDevice,
                    type: lastTriggeredDevice.includes('Camera') ? 'camera' : 'microphone',
                    status: lastStatus,
                    overall_state: anyActive ? 'active' : 'inactive',
                    timestamp: now
                };
            } else {
                payloadObj = {
                    device: 'system',
                    status: anyActive ? 'active' : 'idle',
                    timestamp: now
                };
            }
            webhookPayloadJson.textContent = JSON.stringify(payloadObj, null, 2);
        }

        // 7. Notification Banner
        if (lastTriggeredDevice && !simState.isPaused) {
            const deviceType = lastTriggeredDevice.includes('Camera') ? 'Camera' : 'Microphone';
            showSimToast(`${deviceType} ${lastTriggeredDevice} is now ${lastStatus === 'active' ? 'Active' : 'Inactive'}`);
        } else if (simState.isPaused) {
            showSimToast('Detection paused. Hardware monitoring suspended.');
        }
    }

    if (toggleCameraBtn) {
        toggleCameraBtn.addEventListener('click', () => {
            simState.cameraActive = !simState.cameraActive;
            renderSimulator('FaceTime HD Camera', simState.cameraActive ? 'active' : 'inactive');
        });
    }

    if (toggleMicBtn) {
        toggleMicBtn.addEventListener('click', () => {
            simState.micActive = !simState.micActive;
            renderSimulator('Studio Microphone', simState.micActive ? 'active' : 'inactive');
        });
    }

    if (togglePauseBtn) {
        togglePauseBtn.addEventListener('click', () => {
            simState.isPaused = !simState.isPaused;
            renderSimulator(null, null);
        });
    }

    // Set dynamic tray clock
    const simTrayClock = document.getElementById('sim-tray-clock');
    if (simTrayClock) {
        const updateSimClock = () => {
            const d = new Date();
            const hours = String(d.getHours()).padStart(2, '0');
            const minutes = String(d.getMinutes()).padStart(2, '0');
            simTrayClock.textContent = `${hours}:${minutes}`;
        };
        updateSimClock();
        setInterval(updateSimClock, 30000);
    }

    // ==========================================
    // 3. Showcase Segment Controller
    // ==========================================
    const segButtons = document.querySelectorAll('.seg-btn');
    const showcasePanels = document.querySelectorAll('.showcase-panel');
    const windowTitle = document.getElementById('showcase-window-title');

    const showcaseTitles = {
        menu: 'In Meeting — Status Bar Menu',
        general: 'In Meeting Preferences — General',
        webhooks: 'In Meeting Preferences — Webhooks'
    };

    segButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const targetId = btn.getAttribute('data-showcase');
            
            segButtons.forEach(b => b.classList.remove('active'));
            showcasePanels.forEach(p => p.classList.remove('active'));
            
            btn.classList.add('active');
            const activePanel = document.getElementById(`panel-${targetId}`);
            if (activePanel) activePanel.classList.add('active');

            if (windowTitle && showcaseTitles[targetId]) {
                windowTitle.textContent = showcaseTitles[targetId];
            }
        });
    });


    // ==========================================
    // 5. Universal Clipboard Copy Utility
    // ==========================================
    const copyTriggers = document.querySelectorAll('[data-copy]');

    copyTriggers.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const textToCopy = btn.getAttribute('data-copy');
            if (!textToCopy) return;

            navigator.clipboard.writeText(textToCopy).then(() => {
                const labelElem = btn.querySelector('.copy-label') || btn;
                const prevHtml = labelElem.innerHTML;
                const prevText = labelElem.textContent;

                labelElem.textContent = 'Copied!';
                btn.classList.add('copied');

                setTimeout(() => {
                    if (labelElem === btn) {
                        labelElem.textContent = prevText;
                    } else {
                        labelElem.innerHTML = prevHtml;
                    }
                    btn.classList.remove('copied');
                }, 2000);
            }).catch(err => {
                console.error('Clipboard copy failed:', err);
            });
        });
    });

});
