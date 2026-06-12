-- Car Radio Configuration
-- Customize your car radio settings here
-- NOTE: This script requires the 'xsound' resource to be running!

Config = {}

-- Audio range in meters (how far players can hear the radio)
Config.AudioRange = 50.0

-- Command to open the radio UI
Config.Command = 'carRadio'

-- UI position options: 'top-right', 'top-left', 'bottom-right', 'bottom-left', 'center', 'middle-left', 'middle-right'
Config.UIPosition = 'middle-right'

-- Enable/disable debug mode
Config.Debug = true

-- Show chat messages (notifications)
Config.ShowMessages = true

-- Custom fallback image (place image in html folder, e.g., 'html/fallback.png')
-- Leave empty to use default music icon
Config.CustomFallbackImage = ''

-- Only driver can control (set to false to allow all passengers)
Config.OnlyDriverCanControl = false

-- Auto-close UI when exiting vehicle
Config.AutoCloseOnExit = true

-- UI Width in pixels
Config.UIWidth = 495

-- UI Height in pixels (will auto-adjust based on content)
Config.UIHeight = 360


-- Clean volume heard by people sitting inside the vehicle
Config.InsideVolume = 0.50

-- Exterior audio range/volume. Closed vehicles are intentionally quieter/muffled.
-- The script now manually fades this volume by distance instead of trusting xsound alone.
Config.ExteriorRange = 35.0
Config.ExteriorClosedVolume = 0.012
Config.ExteriorClosedRange = 8.0

-- Exterior audio when a door is open or a window is busted
Config.ExteriorOpenVolume = 0.16
Config.ExteriorOpenRange = 28.0

-- Distance around the car where exterior volume stays at its strongest before fading
Config.ExteriorFullVolumeDistance = 0.5

-- "smooth" gives a stronger drop-off than "linear"
Config.ExteriorFalloffCurve = "smooth"

-- Under this value, exterior audio is destroyed instead of playing silently
Config.ExteriorMinimumAudibleVolume = 0.003

-- How often clients update vehicle radio position and volume
Config.AudioRefreshRate = 250

-- Safety resync for people who join after a song started
Config.FullStateRefreshInterval = 10000


-- Synced radio volume, controlled from the radio UI
-- This is the master vehicle volume. Inside/outside/muffled volumes are scaled by this.
Config.DefaultVolume = 0.50
Config.MinVolume = 0.00
Config.MaxVolume = 1.00
Config.VolumeStep = 0.05

-- Door/window detection and sync seeking
Config.DoorOpenAngleThreshold = 0.03
Config.SeekDelay = 350
