### disclaimer
Tanner Development Asset Disclaimer

All scripts, files, code, designs, graphics, logos, or any other digital assets created by Tanner Development are protected and remain the property of Tanner Development unless stated otherwise.

You are not allowed to resell, redistribute, reupload, leak, claim ownership of, or package any Tanner Development script or asset as your own without proper authorization.

Any use, showcase, modification, or redistribution of Tanner Development assets must include proper credit to Tanner Development.

Credit Requirement

Proper credit must clearly state:
```fix
- Created by Tanner Development
```
Removing credits, renaming the resource to hide ownership, or claiming the work as your own is strictly prohibited.

Resale & Redistribution Policy

Tanner Development assets may not be resold, redistributed, reuploaded, included in paid packages, or included in any other public or private release without explicit written permission from Tanner Development.

With explicit written permission from Tanner Development, an asset may be included, redistributed, or packaged as approved, as long as proper credit is provided and any conditions given by Tanner Development are followed.

Failure to follow these terms may result in removal requests, blacklist actions, or other appropriate action.



# Car Radio - FiveM Script

A standalone, lightweight car radio script for FiveM with a clean, modern UI. Players can stream YouTube videos as music that all nearby players can hear.

## Features

✨ **Clean, Modern UI** - Simple and intuitive interface  
🎵 **YouTube Integration** - Paste any YouTube URL to play  
📸 **Video Thumbnails** - Automatically displays video thumbnails  
🎧 **Proximity Audio** - All players within 50 meters can hear the music  
🚗 **Car-Based** - Radio works only inside vehicles  
🔐 **Permission System** - Only passengers can control the radio  
⚡ **Lightweight** - Standalone script with no dependencies  

## Installation

1. **Install xsound** (REQUIRED) - Download from: https://github.com/Xogy/xsound
   - Extract xsound to your resources folder
   - Add `ensure xsound` to your server.cfg BEFORE carradio

2. Download the carradio script files
3. Place the `carradio` folder in your `resources` directory
4. Add this line to your `server.cfg`:
   ```
   ensure carradio
   ```
5. Restart your server or use `refresh` and `ensure carradio`

**Important:** xsound MUST be running before carradio for audio to work!

## Usage

**Commands:**
- `/carRadio` - Opens the radio UI (must be in a vehicle)

**How to Use:**
1. Enter a vehicle
2. Type `/carRadio` to open the radio interface
3. Paste a YouTube URL into the input field
4. Click the "Play" button
5. All players within 50 meters will hear the music
6. Use the Pause/Stop buttons to control playback
7. Press ESC to close the radio UI

## Configuration

Currently, the script is pre-configured with:
- **Audio Range:** 50 meters
- **UI Position:** Top-right corner of screen
- **Control Method:** `/carRadio` command + NUI

### UI Position Options

You can change the position of the radio UI on the screen:

```lua
-- Available positions:
Config.UIPosition = 'top-right'       -- Top right corner (default)
Config.UIPosition = 'top-left'        -- Top left corner
Config.UIPosition = 'bottom-right'    -- Bottom right corner
Config.UIPosition = 'bottom-left'     -- Bottom left corner
Config.UIPosition = 'center'          -- Center of screen
Config.UIPosition = 'middle-left'     -- Middle left (vertically centered)
Config.UIPosition = 'middle-right'    -- Middle right (vertically centered)
```

1. Place your image in the `html` folder (e.g., `html/fallback.png`)
2. Edit `config.lua` and add:
   ```lua
   Config.CustomFallbackImage = 'html/fallback.png'
   ```

Supported formats: PNG, JPG, GIF, SVG (recommended size: 300x169px)

If left empty, the script uses a default music icon emoji.

To customize audio range, edit `config.lua`:
```lua
local lastAudioRange = 50.0  -- Change this value
```

## YouTube URL Formats Supported

The script supports multiple YouTube URL formats:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`

## Syncing & Networking

- **Server-Side:** Manages radio state and syncs across all players
- **Client-Side:** Handles proximity audio and UI interactions
- **Auto-Sync:** When a player joins, they receive the current radio state
- **Vehicle Tracking:** Radio state is tied to vehicle number plates

## Technical Details

- **Framework:** Standalone (no ESX/QBCore required)
- **Language:** Lua + JavaScript
- **Architecture:** Server-Client with NUI
- **Performance:** Minimal resource usage
- **Audio:** xsound integration for proximity audio
- **Streaming:** Supports direct stream URLs and YouTube links

## Audio Streaming - IMPORTANT

**xsound requires DIRECT AUDIO STREAM URLs, not YouTube links!**

YouTube URLs will NOT work. You need to convert them to audio stream URLs first.

### Using Audio Streams

**Option 1: Direct MP3/OGG URLs**
Paste direct links to audio files:
- `https://example.com/music.mp3`
- `https://example.com/song.ogg`

**Option 2: YouTube to Audio Conversion**
Use a backend service to convert YouTube URLs. Popular options:
- **yt-dlp** (recommended for servers) - extract audio streams
- **youtube-dl** - similar tool
- Third-party APIs that convert YouTube to audio

**Example with backend:**
1. User pastes: `https://www.youtube.com/watch?v=VIDEO_ID`
2. Backend converts to: `https://audio-stream.example.com/VIDEO_ID.mp3`
3. Script plays the audio stream

### Setup Guide for Audio Streaming

For a working setup, you need to either:
1. **Use direct audio URLs** (easiest) - find public audio streams
2. **Set up a backend converter** - runs yt-dlp to convert YouTube links
3. **Use a streaming API** - services that provide audio streams from YouTube

Without proper audio stream URLs, no sound will play!

## Troubleshooting

**Radio doesn't play:**
- Make sure the YouTube URL is valid
- Check that you're inside a vehicle
- Verify the script is properly installed

**UI doesn't show:**
- Try reopening with `/carRadio`
- Check your FiveM console for errors
- Restart the script: `refresh && ensure carradio`

**Thumbnails not loading:**
- Check your internet connection
- YouTube thumbnail server might be temporarily down
- YouTube URL might be invalid

## Notes

⚠️ **Audio Streaming:** This script handles the UI and syncing. For actual audio playback, you can integrate with:
- YouTube to MP3 API services
- External audio streaming services
- Local audio files converted to streams

The current setup provides the framework for audio playback when integrated with a proper streaming service.

## Support

For issues or feature requests, check the script logs and console output for error messages.
if you need direct support please come into the community discord to recive it, or open a issues tab

## License

MIT License

Copyright (c) 2026 James Peterson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

