/**
 * Main JavaScript file for MySQL Examples Web Interface
 */

// Initialize tooltips
document.addEventListener('DOMContentLoaded', function() {
    // Bootstrap tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize code highlighting
    if (typeof Prism !== 'undefined') {
        Prism.highlightAll();
    }

    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Active navigation highlighting
    const currentPath = window.location.pathname;
    document.querySelectorAll('.navbar-nav .nav-link').forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.classList.add('active');
        }
    });
});

// Copy to clipboard functionality
function copyToClipboard(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);

    // Show toast notification
    showToast('Copied to clipboard!');
}

// Toast notification
function showToast(message, type = 'success') {
    const toastHtml = `
        <div class="toast align-items-center text-white bg-${type} border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    ${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    `;

    const toastContainer = document.getElementById('toast-container');
    if (!toastContainer) {
        const container = document.createElement('div');
        container.id = 'toast-container';
        container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(container);
    }

    const toastElement = document.createElement('div');
    toastElement.innerHTML = toastHtml;
    document.getElementById('toast-container').appendChild(toastElement);

    const toast = new bootstrap.Toast(toastElement.querySelector('.toast'));
    toast.show();

    setTimeout(() => {
        toastElement.remove();
    }, 5000);
}

// Search functionality enhancements
function enhanceSearch() {
    const searchInput = document.querySelector('input[name="q"]');
    if (searchInput) {
        // Add autocomplete suggestions
        const suggestions = [
            'CREATE TABLE', 'INDEX', 'FOREIGN KEY', 'TRIGGER', 'PROCEDURE',
            'SELECT', 'JOIN', 'GROUP BY', 'PARTITION', 'TRANSACTION',
            'customer', 'product', 'order', 'user', 'payment'
        ];

        const datalist = document.createElement('datalist');
        datalist.id = 'search-suggestions';
        suggestions.forEach(suggestion => {
            const option = document.createElement('option');
            option.value = suggestion;
            datalist.appendChild(option);
        });
        document.body.appendChild(datalist);
        searchInput.setAttribute('list', 'search-suggestions');

        // Keyboard shortcut (Ctrl+K or Cmd+K)
        document.addEventListener('keydown', function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault();
                searchInput.focus();
                searchInput.select();
            }
        });
    }
}

// File tree navigation
function initFileTree() {
    document.querySelectorAll('.file-tree-toggle').forEach(toggle => {
        toggle.addEventListener('click', function() {
            const target = this.nextElementSibling;
            if (target) {
                target.classList.toggle('show');
                this.querySelector('i').classList.toggle('fa-chevron-right');
                this.querySelector('i').classList.toggle('fa-chevron-down');
            }
        });
    });
}

// Compare page functionality
function initCompare() {
    const compareForm = document.querySelector('form[action="/compare"]');
    if (compareForm) {
        const selectElement = compareForm.querySelector('select[name="examples[]"]');
        if (selectElement) {
            selectElement.addEventListener('change', function() {
                const selected = Array.from(this.selectedOptions);
                if (selected.length > 3) {
                    showToast('Maximum 3 examples can be compared at once', 'warning');
                    // Deselect the last selected option
                    selected[selected.length - 1].selected = false;
                }
            });
        }
    }
}

// Statistics counter animation
function animateCounters() {
    const counters = document.querySelectorAll('.stat-counter');
    counters.forEach(counter => {
        const target = parseInt(counter.getAttribute('data-target'));
        const duration = 2000; // 2 seconds
        const increment = target / (duration / 16); // 60fps
        let current = 0;

        const updateCounter = () => {
            current += increment;
            if (current < target) {
                counter.textContent = Math.floor(current);
                requestAnimationFrame(updateCounter);
            } else {
                counter.textContent = target;
            }
        };

        // Start animation when element is in viewport
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    updateCounter();
                    observer.unobserve(entry.target);
                }
            });
        });
        observer.observe(counter);
    });
}

// Download progress indicator
function downloadWithProgress(url, filename) {
    const progressBar = document.createElement('div');
    progressBar.className = 'progress';
    progressBar.innerHTML = '<div class="progress-bar" role="progressbar" style="width: 0%"></div>';

    // Show progress in modal
    const modal = new bootstrap.Modal(document.getElementById('download-modal'));
    document.querySelector('#download-modal .modal-body').appendChild(progressBar);
    modal.show();

    fetch(url)
        .then(response => {
            const reader = response.body.getReader();
            const contentLength = +response.headers.get('Content-Length');
            let receivedLength = 0;
            const chunks = [];

            return reader.read().then(function processResult(result) {
                if (result.done) {
                    const blob = new Blob(chunks);
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = filename;
                    a.click();
                    URL.revokeObjectURL(url);
                    modal.hide();
                    showToast('Download completed!');
                    return;
                }

                chunks.push(result.value);
                receivedLength += result.value.length;
                const progress = (receivedLength / contentLength) * 100;
                progressBar.querySelector('.progress-bar').style.width = progress + '%';

                return reader.read().then(processResult);
            });
        })
        .catch(error => {
            modal.hide();
            showToast('Download failed: ' + error.message, 'danger');
        });
}

// Theme switcher
function initThemeSwitcher() {
    const themeSwitcher = document.getElementById('theme-switcher');
    if (themeSwitcher) {
        const currentTheme = localStorage.getItem('theme') || 'light';
        document.documentElement.setAttribute('data-theme', currentTheme);

        themeSwitcher.addEventListener('click', function() {
            const currentTheme = document.documentElement.getAttribute('data-theme');
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';
            document.documentElement.setAttribute('data-theme', newTheme);
            localStorage.setItem('theme', newTheme);

            // Update icon
            const icon = this.querySelector('i');
            icon.classList.toggle('fa-moon');
            icon.classList.toggle('fa-sun');
        });
    }
}

// Initialize all features
document.addEventListener('DOMContentLoaded', function() {
    enhanceSearch();
    initFileTree();
    initCompare();
    animateCounters();
    initThemeSwitcher();

    // Add keyboard shortcuts help
    document.addEventListener('keydown', function(e) {
        if (e.key === '?' && e.shiftKey) {
            showKeyboardShortcuts();
        }
    });
});

// Keyboard shortcuts modal
function showKeyboardShortcuts() {
    const shortcuts = [
        { key: 'Ctrl/Cmd + K', action: 'Focus search' },
        { key: 'Shift + ?', action: 'Show keyboard shortcuts' },
        { key: 'G then H', action: 'Go to home' },
        { key: 'G then C', action: 'Go to compare' },
        { key: 'G then T', action: 'Go to tools' },
        { key: 'G then D', action: 'Go to documentation' }
    ];

    let modalHtml = `
        <div class="modal fade" id="shortcuts-modal" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Keyboard Shortcuts</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Shortcut</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
    `;

    shortcuts.forEach(shortcut => {
        modalHtml += `
            <tr>
                <td><kbd>${shortcut.key}</kbd></td>
                <td>${shortcut.action}</td>
            </tr>
        `;
    });

    modalHtml += `
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    `;

    const modalElement = document.createElement('div');
    modalElement.innerHTML = modalHtml;
    document.body.appendChild(modalElement);

    const modal = new bootstrap.Modal(modalElement.querySelector('.modal'));
    modal.show();

    modalElement.querySelector('.modal').addEventListener('hidden.bs.modal', function() {
        modalElement.remove();
    });
}

// Export functions for use in templates
window.copyToClipboard = copyToClipboard;
window.showToast = showToast;
window.downloadWithProgress = downloadWithProgress;