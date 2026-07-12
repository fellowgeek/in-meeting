// JavaScript for In Meeting Landing Page (Nordic Frost Redesign)

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
    // 2. Installation Tab Navigation Logic
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
    // 4. Application Showcase Logic
    // ==========================================
    const showcaseTabs = document.querySelectorAll('.showcase-tab');
    const showcasePanels = document.querySelectorAll('.showcase-panel');
    const showcaseTitle = document.getElementById('showcase-title');

    const titleMap = {
        'menu': 'Status Bar Menu — In Meeting',
        'general': 'General Preferences — In Meeting',
        'webhooks': 'Webhook Orchestration — In Meeting'
    };
    
    showcaseTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const targetShowcase = tab.getAttribute('data-showcase');
            
            // Remove active states from tabs & panels
            showcaseTabs.forEach(t => t.classList.remove('active'));
            showcasePanels.forEach(p => p.classList.remove('active'));
            
            // Activate selected tab & panel
            tab.classList.add('active');
            const panel = document.getElementById(`showcase-${targetShowcase}`);
            if (panel) {
                panel.classList.add('active');
            }

            // Update window title dynamically
            if (showcaseTitle && titleMap[targetShowcase]) {
                showcaseTitle.textContent = titleMap[targetShowcase];
            }
        });
    });
});
