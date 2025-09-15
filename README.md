# AUTOHOTKEY-V1-ZUIKI-MASCON-SCRIPT-FOR-TRAIN-SIMULATORS
Translates ZUIKI Mascon input into keyboard input.

=====================================================================

AUTOHOTKEY V1 ZUIKI MASCON SCRIPT FOR TRAIN SIMULATORS 🚅🕹️

Version 1.0

=====================================================================

  ➤➤ Introduction

This is an AutoHotkey v1 script for Windows PCs. It translates ZUIKI Mascon input into keyboard key presses.  
With this script, you can play games using your ZUIKI Mascon even if they don't natively support it as an input device.  
The script consists of a .ahk file (the script itself) and a .ini configuration file.  
It has been tested with PCSX2, DuckStation, other emulators, as well as PC games (Steam).  
There should be no need to modify the script file. The configuration file comes pre-configured for "Densha de Go! Professional 2" on PCSX2, providing a sample setup.

=====================================================================
  
  ➤➤ How to use

● Install AutoHotkey v1 (it must be v1; this script does not work with v2)

● Copy the .ahk script file and the .ini configuration file into the same folder. Do not rename the .ini file, as the script looks for "zuiki_config.ini" in the same folder

● It is recommended to create separate folders for different games so you don't need to edit the .ini file when switching games

● Make sure your game/emulator is set up correctly and accepts keyboard inputs. Disconnect all other gamepads and joysticks except for the ZUIKI Mascon

● Open the .ini configuration file and read the description for all settings. Adjust them depending on the game or emulator you use. The .ini is pre-configured for "Densha de Go! Professional 2" on PCSX2

● Save your changes to the .ini file

● Open the .ahk file with AutoHotkey v1, or just double-click it to start the script

● If there is an issue, the script will show a notification. Otherwise, it will display a message confirming that it is running. Click "OK"

● Start your game and play!

● Make sure to have a keyboard ready since sometimes a game might start you in B8 while your actual Mascon is in EB currently. Use you keyboard to sync ingame notch position with actual notch position

● To terminate the script, close the running instance of AutoHotkey or press the Hotkey if those are activated in the .ini

=====================================================================
  
  ➤➤ Troubleshooting

● Ensure all other joysticks and gamepads are disconnected from your PC

● This script sends keys globally, ensure correct window has focus

● Change the "JoystickNumber" in the .ini file until the script can detect your ZUIKI. Try the suggested numbers first, starting with 1

● Verify that controls are configured correctly for your game, and that your emulator accepts keyboard inputs. Try disabling all other forms of input like SDL Input, XInput or DInput

● If ZUIKI Mascon inputs are missed or behave erratically, try adjusting "KeyReleaseDelay", "KeyHoldDuration", and "TimerInterval" in that order. Start by increasing "KeyReleaseDelay"

● Inputs may appear slightly delayed if you increase those values. Give the game a second to catch up when doing large movements (for example B1 to B8)

● Use the suggested values in the .ini file and experiment to find the combination that works best for a specific game or emulator

● For some games, you may need to move the Mascon more slowly, as certain games/emulators do not handle rapid multiple key inputs well

● If you need to change the name or location of the .ini file, open the .ahk file with a text editor and modify this line: INI_FILE := A_ScriptDir . "\zuiki_config.ini"

● If "EnableHotkeys=true" is set, be aware that these hotkeys might conflict with hotkeys in your emulator or game. In that case, consider changing the hotkeys in the game/emulator or setting EnableHotkeys=false

● Be aware that the arrow keys (D-pad) on the ZUIKI cannot be used currently with this script
