let isPlaying = false;
let currentUIPosition = 'middle-right';
let customFallbackImage = '';
let currentVolume = 0.5;
let volumeDebounce = null;
let urlDraft = '';
let userIsEditingUrl = false;

function setPlayLocked(locked) {
    const button = document.querySelector('.play-btn');
    const urlInput = document.getElementById('urlInput');
    if (!button || !urlInput) return;

    if (locked) {
        button.disabled = true;
        button.classList.add('loading');
        urlInput.disabled = true;
        urlInput.placeholder = 'Stop current song before playing another...';
    } else {
        button.disabled = false;
        button.classList.remove('loading');
        button.textContent = '▶ Play';
        urlInput.disabled = false;
        urlInput.placeholder = 'https://www.youtube.com/watch?v=';
    }
}


// Set UI position
function setUIPosition(position) {
    // Remove all position classes
    document.body.classList.remove('pos-top-right', 'pos-top-left', 'pos-bottom-right', 'pos-bottom-left', 'pos-center', 'pos-middle-left', 'pos-middle-right');
    
    // Add the new position class
    const posClass = 'pos-' + (position || 'top-right');
    document.body.classList.add(posClass);
    currentUIPosition = position;
}

// Get fallback image
function normalizeUiImagePath(path) {
    if (!path) return '';
    if (path.startsWith('http') || path.startsWith('data:') || path.startsWith('./')) return path;
    if (path.startsWith('html/')) return './' + path.replace('html/', '');
    return './' + path;
}

function getFallbackImage() {
    if (customFallbackImage) {
        return normalizeUiImagePath(customFallbackImage);
    }
    return 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 300 300%22%3E%3Crect fill=%22%23070f1b%22 width=%22300%22 height=%22300%22/%3E%3Ctext x=%22150%22 y=%22160%22 font-size=%2296%22 fill=%22%231c66ff%22 text-anchor=%22middle%22 dominant-baseline=%22middle%22%3E%E2%99%AA%3C/text%3E%3C/svg%3E';
}

// Close the radio UI
function closeRadio() {
    const container = document.querySelector('.radio-container');
    if (container) {
        container.classList.add('hidden');
    }
    
    fetch(`https://${GetParentResourceName()}/closeRadio`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).then(r => r.json()).catch(r => console.log(r))
}

// Play radio with YouTube URL
function playRadio() {
    const urlInput = document.getElementById('urlInput');
    const url = urlInput.value.trim();
    urlDraft = url;

    if (!url) {
        showMessage('Please enter a YouTube URL', 'error');
        return;
    }

    const button = document.querySelector('.play-btn');
    button.textContent = 'Loading...';
    button.disabled = true;
    button.classList.add('loading');

    fetch(`https://${GetParentResourceName()}/playRadio`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ url: url })
    }).then(r => r.json()).then(data => {
        if (data.success) {
            showMessage('Now playing!', 'success');
            urlDraft = '';
            userIsEditingUrl = false;
            updateUI(url, true, data.thumbnail, currentVolume);
        } else {
            button.textContent = '▶ Play';
            button.disabled = false;
            button.classList.remove('loading');
            showMessage(data.message || 'Invalid URL', 'error');
        }
    }).catch(err => {
        button.textContent = '▶ Play';
        button.disabled = false;
        button.classList.remove('loading');
        showMessage('Error playing radio', 'error');
        console.log(err);
    })
}

// Toggle play/pause
function toggleRadio() {
    isPlaying = !isPlaying;
    const pauseBtn = document.getElementById('pauseBtn');
    
    fetch(`https://${GetParentResourceName()}/toggleRadio`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ isPlaying: isPlaying })
    }).then(r => r.json()).then(data => {
        if (data.success) {
            pauseBtn.textContent = isPlaying ? '⏸ Pause' : '▶ Resume';
        }
    }).catch(err => console.log(err))
}

// Stop radio
function stopRadio() {
    fetch(`https://${GetParentResourceName()}/stopRadio`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).then(r => r.json()).then(data => {
        if (data.success) {
            updateUI('', false, null, currentVolume);
            isPlaying = false;
            document.getElementById('pauseBtn').textContent = '⏸ Pause';
            showMessage('Radio stopped', 'success');
        }
    }).catch(err => console.log(err))
}

function setVolumeUI(volume) {
    currentVolume = Math.max(0, Math.min(1, Number(volume ?? currentVolume ?? 0.5)));

    const volumeSlider = document.getElementById('volumeSlider');
    const volumeValue = document.getElementById('volumeValue');

    if (volumeSlider) {
        volumeSlider.value = Math.round(currentVolume * 100);
    }

    if (volumeValue) {
        volumeValue.textContent = `${Math.round(currentVolume * 100)}%`;
    }
}

function changeVolume(value) {
    setVolumeUI(Number(value) / 100);

    clearTimeout(volumeDebounce);
    volumeDebounce = setTimeout(() => {
        fetch(`https://${GetParentResourceName()}/setVolume`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ volume: currentVolume })
        }).then(r => r.json()).then(data => {
            if (!data.success && data.message) {
                showMessage(data.message, 'error');
            }
        }).catch(err => console.log(err));
    }, 120);
}

// Update UI
function updateUI(url, playing, thumbnail, volume) {
    const urlInput = document.getElementById('urlInput');
    const thumbnailImg = document.getElementById('thumbnail');
    const nowPlayingText = document.getElementById('nowPlayingText');
    const pauseBtn = document.getElementById('pauseBtn');
    const fallbackImg = getFallbackImage();

    if (volume !== undefined && volume !== null) {
        setVolumeUI(volume);
    }

    if (url) {
        setPlayLocked(true);
        urlInput.value = url;
        nowPlayingText.textContent = 'Music is playing...';
        isPlaying = playing;
        pauseBtn.textContent = playing ? '⏸ Pause' : '▶ Resume';
        
        if (thumbnail) {
            // Set up fallback handling for broken thumbnails
            thumbnailImg.onerror = function() {
                console.log('Thumbnail failed to load, using fallback');
                this.src = fallbackImg;
                this.onerror = null; // Prevent infinite loop
            };
            thumbnailImg.src = thumbnail;
        } else {
            // No thumbnail available
            thumbnailImg.src = fallbackImg;
        }
    } else {
        setPlayLocked(false);

        // Do not wipe the input while the player is typing or pasting a link.
        // The client can receive updateRadio/openRadio messages with no currentUrl
        // while the UI is open, which was clearing pasted URLs instantly.
        const activeEl = document.activeElement;
        const isUrlFocused = activeEl === urlInput;
        if (!isUrlFocused && !userIsEditingUrl && !urlDraft) {
            urlInput.value = '';
        }

        nowPlayingText.textContent = 'Nothing playing';
        
        // Show "No Song" version of fallback
        if (customFallbackImage) {
            thumbnailImg.src = fallbackImg;
        } else {
            thumbnailImg.src = 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 300 169%22%3E%3Crect fill=%22%230f3460%22 width=%22300%22 height=%22169%22/%3E%3Ctext x=%22150%22 y=%2285%22 font-size=%2224%22 fill=%22%23999%22 text-anchor=%22middle%22 dominant-baseline=%22middle%22%3ENo Song%3C/text%3E%3C/svg%3E';
        }
        
        isPlaying = false;
        pauseBtn.textContent = '⏸ Pause';
    }
}

// Show temporary message
function showMessage(message, type) {
    const container = document.querySelector('.radio-content');
    const msgEl = document.createElement('div');
    msgEl.style.cssText = `
        padding: 10px;
        margin: 10px 0;
        border-radius: 6px;
        text-align: center;
        font-size: 12px;
        font-weight: 500;
        animation: slideDown 0.3s ease;
        ${type === 'success' ? 'background: rgba(0, 255, 100, 0.15); color: #00ff64; border: 1px solid rgba(0, 255, 100, 0.3);' : 'background: rgba(255, 100, 100, 0.15); color: #ff6464; border: 1px solid rgba(255, 100, 100, 0.3);'}
    `;
    msgEl.textContent = message;
    container.insertBefore(msgEl, container.firstChild);

    setTimeout(() => msgEl.remove(), 3000);
}

// Listen for server updates
window.addEventListener('message', function(event) {
    const data = event.data;
    const container = document.querySelector('.radio-container');

    if (data.type === 'openRadio') {
        if (container) {
            container.classList.remove('hidden');
        }
        if (data.data.uiPosition) {
            setUIPosition(data.data.uiPosition);
        }
        if (data.data.customFallback) {
            customFallbackImage = normalizeUiImagePath(data.data.customFallback);
        }
        updateUI(data.data.currentUrl, data.data.isPlaying, data.data.thumbnail, data.data.volume);
    }

    if (data.type === 'updateRadio') {
        if (!container || !container.classList.contains('hidden')) {
            updateUI(data.data.currentUrl, data.data.isPlaying, data.data.thumbnail, data.data.volume);
        }
    }

    if (data.type === 'playRejected') {
        showMessage((data.data && data.data.message) || data.message || 'Stop the current song before playing a new one.', 'error');
    }

    if (data.type === 'closeRadio' || data.type === 'forceClose') {
        if (container) {
            container.classList.add('hidden');
        }
    }
});


function setupUrlInputProtection() {
    const urlInput = document.getElementById('urlInput');
    if (!urlInput) return;

    urlInput.addEventListener('focus', function() {
        userIsEditingUrl = true;
        urlDraft = this.value || urlDraft;
    });

    urlInput.addEventListener('input', function() {
        userIsEditingUrl = true;
        urlDraft = this.value;
    });

    urlInput.addEventListener('paste', function() {
        userIsEditingUrl = true;
        // Let the paste complete, then save the pasted value so updateUI cannot wipe it.
        setTimeout(() => {
            urlDraft = this.value;
        }, 0);
    });

    urlInput.addEventListener('blur', function() {
        urlDraft = this.value;
        // Keep the draft protected as long as text is still in the box.
        userIsEditingUrl = !!urlDraft;
    });
}

// Keyboard shortcuts
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeRadio();
    }
});

// Initialize
window.addEventListener('load', function() {
    console.log('Car Radio UI Loaded');
    setUIPosition('middle-right'); // Default position
    setVolumeUI(currentVolume);
    setupUrlInputProtection();
});
