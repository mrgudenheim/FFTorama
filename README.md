# [Click here for newest release](https://github.com/mrgudenheim/FFTorama/releases)

# About
This extension adds three panels to pixelorama:  
"Assembled Frame" - Displays a selected frame  
"Assembled Animation" - Displays a selected animation  
"FFT Settings" - Shows settings for the extension  

When selecting a frame, the corresponding sections of the sprite sheet will be selected.

# Installation
To use the extension, drag the .pck file into Pixelorama. Then go to Edit -> Preferences -> Extensions and select and enable FFTorama.
Three new tabs should appear in the top left. They can be dragged to new locations within pixelorama.

https://www.oramainteractive.com/Pixelorama-Docs/extension_system/extension_basics#installing-the-extension

# Notes
- Animations only interpret the following opcodes:
    - LoadFrameAndWait
    - QueueSpriteAnim
    - LoadMFItem, UnloadMFItem, MFItemPosFBDU
    - Move operations
    - SetLayerPriority
    - SetFrameOffset
    - FlipHorizontal
    - Wait
    - WaitForInput, WeaponSheatheCheck1, and WeaponSheatheCheck2 - These are interpreted as a fixed delay (in frames) set in the settings panel
- There may be alignment errors on frames that use rotation
- Does not handle transparency
- Does not account for SP2 lookups
- Works with Pixelorama 1.0

# Pixelorama Links
https://github.com/Orama-Interactive/Pixelorama  
https://orama-interactive.itch.io/pixelorama  
https://www.oramainteractive.com/Pixelorama-Docs/