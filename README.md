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

## Repository description
A minimal example in 6502 assembly for NES that demonstrates synchronized input reading and scroll control using the hardware registers directly.  
Made for study purposes to show how to handle the v-blank and controller input at low level.
