# NES Input and Scroll Demo

This small NES assembly program shows how to read the controller and move the background scroll depending on the direction pressed.  
It uses the original Nintendo algorithm that reads the joypad serially through $4016, using the carry flag as an implicit counter.  
Each NMI (triggered during v-blank) reads the pad, stores the result in memory, and then updates the scroll registers on the PPU.

The priority for movement is: Right → Left → Down → Up.  
Only one direction is applied per frame to keep the motion simple.

## How it works
- During v-blank the NMI runs.
- The joypad is latched (strobe on/off) and read 8 times to collect all button bits.
- The resulting byte is analyzed to check the first active direction bit.
- X and Y scroll values in RAM are incremented or decremented.
- These values are written to the PPU scroll registers ($2005) to move the background.

## Versions
This Exercise started on a basic version that work on input catching directly in nmi ,then i evolved in other version that work with more efficent code,cleaner comments sections and more customizations.You can find here:

- nes03.nes : First attempt . It works but the input catching part written in nmi it's not so stable and its not very customazable
- nes04.nes : Now input catch part is managed inside loop and nmi part manage only graphic changes (ppu communication), but the movement look to much fast
- nes05.nes : Customazable speed introducing Frame frec sync ,Throttle Effect and a Speed value

here i wrote more details about this last (Definitive?) version

# Version 05 : Customazable Speed and Efficent Scrolling

## Overview

The program performs these main tasks:

1. **PPU Initialization**
   - Activates NMI and enables background rendering.
   - Loads a simple **color palette** and a **nametable tile** to display a visible background.

2. **Main Loop**
   - Waits for a new frame signal from the NMI (ensuring 60 Hz sync).
   - Reads controller input from `$4016` and stores button states in `$03`.
   - Adjusts scroll position (X = `$01`, Y = `$02`) based on directional input.
   - Uses configurable **speed** and **throttling** variables to define how fast or how often movement occurs.

3. **NMI Routine**
   - Executes once per frame.
   - Updates the PPU scroll registers (`PPUSCRL`) to reflect the current X/Y position.
   - Increments a simple color value each frame to make a subtle visual change (for debugging).

---

## ⚙️ Adjustable Variables

| Variable | Description | Example Value |
|-----------|--------------|----------------|
| `SPEED` / `SPEED_VALUE` | How many pixels to move per step. Higher = faster. | `#$01`, `#$02`, `#$04` |
| `THROTTLE` / `THROTTLE_VALUE` | Number of frames to wait between moves. Higher = slower. | `#$00`, `#$03`, `#$05` |
| `FRAME` | Frame flag set once per NMI (1 per video frame). Used for sync. | Auto-managed |

These variables can be changed directly in the source to control how the screen scrolls.

---

## 🕒 Frame Wait

Before any movement happens, the code waits for the NMI interrupt to update the `FRAME` variable.  
This ensures the logic runs **once per frame**, synchronized with the NES refresh rate (~60 Hz).

```asm
WaitFrame:
    LDA FRAME
    BEQ WaitFrame     ; wait until NMI sets FRAME
    LDA #$00
    STA FRAME         ; consume the frame signal

##  Throttling

Throttling defines **how many frames** must pass before another movement step occurs.  
Each frame, the variable `THROTTLE` is **decreased by one** until it reaches zero — at that moment, a single movement step is executed, and the counter is reset to `THROTTLE_VALUE`.

This mechanism allows you to slow down the scroll speed by waiting multiple frames between movements.

## Speed Control

SPEED determines how much X or Y changes each time a move is triggered.
This controls the magnitude of each scroll step in pixels.

### 🔁 Combined Effect

| Variable | Function | Higher Value → |
|-----------|-----------|----------------|
| `FRAME` | Synchronizes logic with NMI | — |
| `THROTTLE_VALUE` | Frames between movement steps | Slower motion |
| `SPEED_VALUE` | Pixels moved per step | Faster motion |

