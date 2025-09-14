#Persistent
#SingleInstance Force
#NoEnv
SetBatchLines -1

; ===== INI FILE CONFIGURATION =====
INI_FILE := A_ScriptDir . "\zuiki_config.ini"

; Default values (fallbacks if INI reading fails)
JOYSTICK_NUM := 2
TIMER_INTERVAL := 16
KEY_HOLD_DURATION := 50
KEY_RELEASE_DELAY := 5
NOTCHES := [0, 1, 5, 10, 16, 22, 27, 33, 39, 45, 56, 66, 76, 86, 100]
NOTCH_NAMES := ["EB", "B8", "B7", "B6", "B5", "B4", "B3", "B2", "B1", "N", "P1", "P2", "P3", "P4", "P5"]
KEYS := {neutral_to_power: "Down", neutral_to_brake: "Up", power_up: "Down", power_down: "Up", brake_up: "Up", brake_down: "Down", eb: "e"}
JOYSTICK_BUTTONS := {}
IGNORED_NOTCHES := []
HORN_KEY := ""
HORN2_KEY := ""
BUZZER_KEY := ""

; ===== GLOBAL VARIABLES =====
g_PreviousNotch := -1
g_CurrentNotch := -1
g_LastValidNotch := -1  ; Track the last valid notch position
g_JoystickConnected := false
g_ShowTooltip := false
g_HotkeysEnabled := true
g_NeutralNotch := 9  ; Will be calculated based on loaded notches

; ===== INITIALIZATION =====
Gosub, LoadConfiguration
Gosub, InitializeJoystick
Gosub, CreateJoystickButtonHotkeys
Sleep 2000
MsgBox, 64, Zuiki Controller, Zuiki Controller Script Started Successfully!
SetTimer, CheckJoystick, %TIMER_INTERVAL%
return

; ===== LOAD CONFIGURATION =====
LoadConfiguration:
    ; Check if INI file exists
    if (!FileExist(INI_FILE))
    {
        MsgBox, 48, Warning, Configuration file not found: %INI_FILE%`n`nUsing default settings.
        return
    }
    
    ; Load General settings
    IniRead, JOYSTICK_NUM, %INI_FILE%, General, JoystickNumber, 2
    IniRead, TIMER_INTERVAL, %INI_FILE%, General, TimerInterval, 16
    IniRead, KEY_HOLD_DURATION, %INI_FILE%, General, KeyHoldDuration, 50
    IniRead, KEY_RELEASE_DELAY, %INI_FILE%, General, KeyReleaseDelay, 5
    
    ; Load Axis Keys - 6-STATE SYSTEM
    IniRead, NeutralToPowerKey, %INI_FILE%, AxisKeys, NeutralToPower, Down
    IniRead, NeutralToBrakeKey, %INI_FILE%, AxisKeys, NeutralToBrake, Up
    IniRead, PowerUpKey, %INI_FILE%, AxisKeys, PowerUp, Down
    IniRead, PowerDownKey, %INI_FILE%, AxisKeys, PowerDown, Up
    IniRead, BrakeUpKey, %INI_FILE%, AxisKeys, BrakeUp, Down
    IniRead, BrakeDownKey, %INI_FILE%, AxisKeys, BrakeDown, Up
    IniRead, EBKey, %INI_FILE%, AxisKeys, EB, ERROR
    KEYS := {neutral_to_power: NeutralToPowerKey, neutral_to_brake: NeutralToBrakeKey, power_up: PowerUpKey, power_down: PowerDownKey, brake_up: BrakeUpKey, brake_down: BrakeDownKey}
    
    ; Add EB key if configured
    if (EBKey != "ERROR" && EBKey != "")
    {
        KEYS.eb := EBKey
    }
    
    ; Load Joystick Buttons
    JOYSTICK_BUTTONS := {}
    ButtonList := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14]
    Loop % ButtonList.MaxIndex()
    {
        ButtonNum := ButtonList[A_Index]
        IniRead, ButtonKey, %INI_FILE%, JoystickButtons, %ButtonNum%, ERROR
        if (ButtonKey != "ERROR" && ButtonKey != "")
        {
            JOYSTICK_BUTTONS[ButtonNum] := ButtonKey
        }
    }
    
    ; Load Horn Configuration
    IniRead, HornKey, %INI_FILE%, JoystickButtons, Horn, 
    IniRead, Horn2Key, %INI_FILE%, JoystickButtons, Horn2, 
    IniRead, BuzzerKey, %INI_FILE%, JoystickButtons, Buzzer, 
    HORN_KEY := HornKey
    HORN2_KEY := Horn2Key
    BUZZER_KEY := BuzzerKey
    
    ; Load Notch Configuration
    IniRead, NotchValuesStr, %INI_FILE%, NotchConfiguration, NotchValues, 0,1,5,10,16,22,27,33,39,45,56,66,76,86,100
    IniRead, NotchNamesStr, %INI_FILE%, NotchConfiguration, NotchNames, EB,B8,B7,B6,B5,B4,B3,B2,B1,N,P1,P2,P3,P4,P5
    IniRead, IgnoreNotchValuesStr, %INI_FILE%, NotchConfiguration, IgnoreNotchValues, 
    
    ; Parse notch values (always load all 15)
    NOTCHES := []
    StringSplit, NotchArray, NotchValuesStr, `,
    Loop, %NotchArray0%
    {
        NOTCHES.Push(NotchArray%A_Index%)
    }
    
    ; Parse notch names (always load all 15)
    NOTCH_NAMES := []
    StringSplit, NameArray, NotchNamesStr, `,
    Loop, %NameArray0%
    {
        NOTCH_NAMES.Push(NameArray%A_Index%)
    }
    
    ; Parse ignored notch values
    IGNORED_NOTCHES := []
    if (IgnoreNotchValuesStr != "")
    {
        StringSplit, IgnoreArray, IgnoreNotchValuesStr, `,
        Loop, %IgnoreArray0%
        {
            IGNORED_NOTCHES.Push(IgnoreArray%A_Index%)
        }
    }
    
    ; Find neutral notch (position with value 45)
    g_NeutralNotch := -1
    Loop % NOTCHES.MaxIndex()
    {
        if (NOTCHES[A_Index] = 45)
        {
            g_NeutralNotch := A_Index - 1  ; Convert to 0-based index
            break
        }
    }
        
    ; Load Debug settings
    IniRead, EnableHotkeysStr, %INI_FILE%, Debug, EnableHotkeys, false
    g_HotkeysEnabled := (EnableHotkeysStr = "true")
    
    ; Enable/disable hotkeys based on configuration
    if (g_HotkeysEnabled)
    {
        Hotkey, F1, F1Handler, On
        Hotkey, F2, F2Handler, On  
        Hotkey, F12, F12Handler, On
    }
    else
    {
        Hotkey, F1, F1Handler, Off UseErrorLevel
        Hotkey, F2, F2Handler, Off UseErrorLevel
        Hotkey, F12, F12Handler, Off UseErrorLevel
    }
    
return

; ===== MAIN FUNCTIONS =====
InitializeJoystick:
    ; Check if joystick is connected
    GetKeyState, TestAxis, %JOYSTICK_NUM%JoyY
    if (TestAxis != "")
    {
        g_JoystickConnected := true
        ; Initial notch value
        JoyY := GetKeyState(JOYSTICK_NUM . "JoyY")
        g_CurrentNotch := GetCurrentNotch(JoyY)
        g_PreviousNotch := g_CurrentNotch
        ; Initialize last valid notch if current position is valid
        if (!IsNotchIgnored(g_CurrentNotch))
        {
            g_LastValidNotch := g_CurrentNotch
        }
    }
    else
    {
        MsgBox, 48, Warning, Joystick %JOYSTICK_NUM% not found!
        ExitApp
    }
return

CreateJoystickButtonHotkeys:
    ; Create hotkeys for configured joystick buttons
    for ButtonNum, KeyToSend in JOYSTICK_BUTTONS
    {
        HotkeyString := JOYSTICK_NUM . "Joy" . ButtonNum
        Hotkey, %HotkeyString%, JoystickButtonHandler
    }
return

JoystickButtonHandler:
    ; Extract button number from the hotkey that triggered this
    ButtonString := A_ThisHotkey
    RegExMatch(ButtonString, "\d+Joy(\d+)", Match)
    ButtonNum := Match1
    
    ; Send the configured key
    if (JOYSTICK_BUTTONS.HasKey(ButtonNum))
    {
        KeyToSend := JOYSTICK_BUTTONS[ButtonNum]
        
        ; Check if this button is mapped to horn function
        if (KeyToSend = "HORN" && HORN_KEY != "")
        {
            ; Horn button pressed - hold key while button is held
            Send {%HORN_KEY% down}
            KeyWait, %ButtonString%
            Send {%HORN_KEY% up}
        }
        else if (KeyToSend = "HORN2" && HORN2_KEY != "")
        {
            ; Horn2 button pressed - hold key while button is held
            Send {%HORN2_KEY% down}
            KeyWait, %ButtonString%
            Send {%HORN2_KEY% up}
        }
        else if (KeyToSend = "BUZZER" && BUZZER_KEY != "")
        {
            ; Buzzer button pressed - hold key while button is held
            Send {%BUZZER_KEY% down}
            KeyWait, %ButtonString%
            Send {%BUZZER_KEY% up}
        }
        else if (KeyToSend != "HORN" && KeyToSend != "HORN2" && KeyToSend != "BUZZER")
        {
            ; Normal button - quick press
            Send {%KeyToSend% down}{%KeyToSend% up}
        }
    }
return

CheckJoystick:
    if (!g_JoystickConnected)
        return
        
    ; Get Y-position of joystick
    JoyY := GetKeyState(JOYSTICK_NUM . "JoyY")
    
    ; Determine current notch
    NewNotch := GetCurrentNotch(JoyY)
    
    ; Update tooltip if active
    if (g_ShowTooltip)
        UpdateTooltip(NewNotch)
    
    ; Only process if notch has changed
    if (NewNotch == g_CurrentNotch)
        return
    
    ; Store previous position
    g_PreviousNotch := g_CurrentNotch
    g_CurrentNotch := NewNotch
    
    ; Get current notch value for EB detection
    CurrentNotchValue := (NewNotch >= 0 && NewNotch < NOTCHES.MaxIndex()) ? NOTCHES[NewNotch + 1] : -1
    
    ; Special handling for EB position (always works regardless of other ignored notches)
    if (CurrentNotchValue == 0)
    {
        ; Moving to EB position
        if (KEYS.HasKey("eb"))
            SendKeySequence(KEYS.eb, 1)
        else
            SendKeySequence(KEYS.brake_up, 1)
        g_LastValidNotch := g_CurrentNotch
        return
    }
    
    ; Determine the logical starting position
    FromPosition := (g_LastValidNotch != -1) ? g_LastValidNotch : g_PreviousNotch
    
    ; Special case: If coming from EB and current position is ignored,
    ; we need to track movement through ignored positions properly
    if (g_LastValidNotch == 0 && IsNotchIgnored(g_CurrentNotch))
    {
        ; Coming from EB, moving through ignored brake positions
        ; Update g_LastValidNotch to track our logical position even through ignored notches
        g_LastValidNotch := g_CurrentNotch
        return  ; Don't send keys while moving through ignored positions
    }
    
    ; Find the effective target (last valid notch in movement direction)
    EffectiveTarget := FindLastValidInDirection(FromPosition, g_CurrentNotch)
    
    ; Only send keys if we have a valid movement to make
    if (EffectiveTarget != FromPosition)
    {
        ; Special case: If we were coming from EB (g_LastValidNotch was 0 originally)
        ; and now moving to first valid brake position, only send 1 key
        if (g_LastValidNotch == 0 || (g_LastValidNotch < 9 && IsNotchIgnored(g_LastValidNotch) && !IsNotchIgnored(EffectiveTarget)))
        {
            ; Coming from EB to first valid brake position = 1 key press
            KeysToSend := CalculateMovementKeys(FromPosition, EffectiveTarget)
            KeysToSend.count := 1  ; Override the count to 1
        }
        else
        {
            ; Normal movement calculation
            KeysToSend := CalculateMovementKeys(FromPosition, EffectiveTarget)
        }
        
        if (KeysToSend.count > 0)
        {
            SendKeySequence(KeysToSend.key, KeysToSend.count)
        }
        
        ; Update last valid notch to where we actually moved
        g_LastValidNotch := EffectiveTarget
    }
return

; ===== HELPER FUNCTIONS =====
IsNotchIgnored(NotchIndex)
{
    global NOTCHES, IGNORED_NOTCHES
    
    ; Get the actual notch value for this index
    if (NotchIndex < 0 || NotchIndex >= NOTCHES.MaxIndex())
        return false
        
    NotchValue := NOTCHES[NotchIndex + 1]  ; Convert to 1-based for array access
    
    ; Check if this value is in the ignored list
    Loop % IGNORED_NOTCHES.MaxIndex()
    {
        if (IGNORED_NOTCHES[A_Index] = NotchValue)
            return true
    }
    
    return false
}

GetCurrentNotch(JoyY)
{
    global NOTCHES
    
    ; Binary search for better performance - PRESERVING ORIGINAL ALGORITHM
    Low := 1
    High := NOTCHES.MaxIndex()
    
    while (Low <= High)
    {
        Mid := Floor((Low + High) / 2)
        
        if (JoyY < NOTCHES[Mid])
            High := Mid - 1
        else if (Mid < NOTCHES.MaxIndex() && JoyY >= NOTCHES[Mid + 1])
            Low := Mid + 1
        else
            return Mid - 1  ; Return 0-based index
    }
    
    return NOTCHES.MaxIndex() - 1  ; Return 0-based index
}

UpdateTooltip(NotchIndex)
{
    global NOTCH_NAMES
    
    ; Ensure the index is valid
    if (NotchIndex >= 0 && NotchIndex < NOTCH_NAMES.MaxIndex())
    {
        NotchName := NOTCH_NAMES[NotchIndex + 1]  ; Array is 1-based
        ToolTip, Position: %NotchName% (Notch %NotchIndex%), 10, 10
    }
}

SendKeySequence(Key, Count)
{
    global KEY_HOLD_DURATION, KEY_RELEASE_DELAY
       
    Loop, %Count%
    {
        Send, {%Key% down}
        Sleep, %KEY_HOLD_DURATION%
        Send, {%Key% up}
        
        Sleep, %KEY_RELEASE_DELAY%
    }
}

FindLastValidInDirection(FromNotch, ToNotch)
{
    global NOTCHES
    
    ; Special case: if moving toward EB (value 0), EB is always valid
    if (ToNotch >= 0 && ToNotch < NOTCHES.MaxIndex())
    {
        ToValue := NOTCHES[ToNotch + 1]
        if (ToValue == 0)
            return ToNotch
    }
    
    ; Since ignored notches are contiguous at range ends,
    ; scan backwards from target until we find a valid notch
    Direction := (ToNotch > FromNotch) ? 1 : -1
    
    Loop % Abs(ToNotch - FromNotch)
    {
        CheckNotch := ToNotch - ((A_Index - 1) * Direction)
        if (!IsNotchIgnored(CheckNotch))
            return CheckNotch
    }
    
    return FromNotch  ; Fallback if no valid notch found
}

CalculateMovementKeys(FromNotch, ToNotch)
{
    global NOTCHES, KEYS
    
    ; Get notch values
    FromValue := NOTCHES[FromNotch + 1]
    ToValue := NOTCHES[ToNotch + 1]
    
    ; Calculate number of steps
    StepCount := Abs(ToNotch - FromNotch)
    
    if (StepCount == 0)
        return {key: "", count: 0}
    
    ; Determine key type based on movement pattern
    if (FromValue == 45)
    {
        ; FROM NEUTRAL
        if (ToValue > 45)
            return {key: KEYS.neutral_to_power, count: StepCount}
        else if (ToValue < 45)
            return {key: KEYS.neutral_to_brake, count: StepCount}
    }
    else if (ToValue == 45)
    {
        ; TO NEUTRAL
        if (FromValue > 45)
            return {key: KEYS.power_down, count: StepCount}
        else if (FromValue < 45)
            return {key: KEYS.brake_down, count: StepCount}
    }
    else if (FromValue > 45 && ToValue > 45)
    {
        ; WITHIN POWER RANGE
        if (ToValue > FromValue)
            return {key: KEYS.power_up, count: StepCount}
        else
            return {key: KEYS.power_down, count: StepCount}
    }
    else if (FromValue < 45 && ToValue < 45)
    {
        ; WITHIN BRAKE RANGE
        if (ToValue < FromValue)
            return {key: KEYS.brake_up, count: StepCount}
        else
            return {key: KEYS.brake_down, count: StepCount}
    }
    else
    {
        ; CROSS-RANGE MOVEMENT (shouldn't normally happen)
        if (ToValue > 45)
            return {key: KEYS.neutral_to_power, count: StepCount}
        else
            return {key: KEYS.neutral_to_brake, count: StepCount}
    }
    
    return {key: "", count: 0}
}

; ===== HOTKEYS FOR CONTROL =====
F1Handler:
F1::
    Suspend, Toggle
    if (A_IsSuspended)
        ToolTip, Script paused - F1 to resume
    else
        ToolTip, Script active - F1 to pause
    SetTimer, RemoveToolTip, 2000
return

F2Handler:
F2::
    g_ShowTooltip := !g_ShowTooltip
    if (g_ShowTooltip)
    {
        ; Immediately show current notch
        JoyY := GetKeyState(JOYSTICK_NUM . "JoyY")
        CurrentNotch := GetCurrentNotch(JoyY)
        UpdateTooltip(CurrentNotch)
        ToolTip, Joystick position tooltip activated - F2 to deactivate, 10, 50
        SetTimer, RemoveActivationTooltip, 2000
    }
    else
    {
        ToolTip  ; Remove all tooltips
        ToolTip, Joystick position tooltip deactivated, 10, 50
        SetTimer, RemoveActivationTooltip, 2000
    }
return

F12Handler:
F12::
    ; Exit script
    ExitApp

RemoveToolTip:
    ToolTip
    SetTimer, RemoveToolTip, Off
return

RemoveActivationTooltip:
    ToolTip, , 10, 50  ; Only remove the activation tooltip
    SetTimer, RemoveActivationTooltip, Off
return

; ===== EXIT HANDLER =====
OnExit:
ExitApp