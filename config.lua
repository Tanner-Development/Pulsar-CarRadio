-- Car Radio Configuration
-- Customize your car radio settings here
-- NOTE: This script requires the 'xsound' resource to be running!

--[[
ALL RIGHTS RESERVED - Tanner Development
This code and associated assets are the intellectual property of Tanner Development.
Unauthorized use, reproduction, or distribution of this code or its assets is strictly prohibited.
For inquiries or permissions, please contact Tanner Development directly.
]]




Config = {}



-- Audio range in meters (how far players can hear the radio)

Config.AudioRange = 50.0



-- Command to open the radio UI

Config.Command = 'carRadio'


-- UI position options: 'top-right', 'top-left', 'bottom-right', 'bottom-left', 'center', 'middle-left', 'middle-right'

Config.UIPosition = 'bottom-right' -- moved to the bottom-right from middle-right for better visibility and less interference with other UI elements like the minimap which is usually on the bottom-left



-- Enable/disable debug mode

Config.Debug = true -- toggled to false for production, true for development to see debug prints in console



-- Show chat messages (notifications)

Config.ShowMessages = false -- THIS IS STILL BROKEN WORKING ON A FIX FOR PULSAR



-- Custom fallback image (place image in html folder, e.g., 'html/fallback.png')
-- Leave empty to use default music icon

Config.CustomFallbackImage = '' -- removed freeworld so you guys can edit to your desiered image or leave blank for default



-- Only driver can control (set to false to allow all passengers)

Config.OnlyDriverCanControl = false 



-- Auto-close UI when exiting vehicle

Config.AutoCloseOnExit = true



-- UI Width in pixels

Config.UIWidth = 495 -- DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING, CHANGING THIS MAY CAUSE UI ISSUES



-- UI Height in pixels (will auto-adjust based on content)

Config.UIHeight = 360 -- DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING, CHANGING THIS MAY CAUSE UI ISSUES




-- Clean volume heard by people sitting inside the vehicle

Config.InsideVolume = 0.70 -- edited form 0.50 to 0.70








-- Exterior audio range/volume. Closed vehicles are intentionally quieter/muffled.
-- The script now manually fades this volume by distance instead of trusting xsound alone.

Config.ExteriorRange = 35.0

Config.ExteriorClosedVolume = 0.012

Config.ExteriorClosedRange = 8.0



-- Exterior audio when a door is open or a window is busted

Config.ExteriorOpenVolume = 0.25 -- edited to 0.25 from 0.16

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
Config.DefaultVolume = 0.50 -- edit to your hearts content.... 🙃🙃

Config.MinVolume = 0.00 -- this can be set to 0.00 to allow for complete silence, 

Config.MaxVolume = 1.00 -- this convar can not exceed 1.00 due to how xsound handles volume, setting it above 1.00 will not make it louder and may cause issues with volume fading and distance calculations

Config.VolumeStep = 0.01 -- edited to 0.01 from 0.05 for finer control due to .05 being too large of a jump and making it hard to find a good volume levels




-- Door/window detection and sync seeking

Config.DoorOpenAngleThreshold = 0.03 -- DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING, CHANGING THIS MAY CAUSE ISSUES

Config.SeekDelay = 350 -- delay in milliseconds between seeking and updating audio position/volume, to allow for door/window state to be detected and synced properly