'-----------------------------------------------------------------------------------------------------------------------
' Input - Unified Keyboard, Mouse, Game Controller & Window Event System for QB64-PE
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Math.bi'
'$INCLUDE:'Asc.bi'
'$INCLUDE:'Vector2f.bi'
'$INCLUDE:'Bounds2f.bi'

' Standard ASCII Keys
CONST KEY_SPACE& = _ASC_SPACE
CONST KEY_EXCLAMATION& = _ASC_EXCLAMATION
CONST KEY_QUOTE& = _ASC_QUOTE
CONST KEY_HASH& = _ASC_HASH
CONST KEY_DOLLAR& = _ASC_DOLLAR
CONST KEY_PERCENT& = _ASC_PERCENT
CONST KEY_AMPERSAND& = _ASC_AMPERSAND
CONST KEY_APOSTROPHE& = _ASC_APOSTROPHE
CONST KEY_LEFTBRACKET& = _ASC_LEFTBRACKET
CONST KEY_RIGHTBRACKET& = _ASC_RIGHTBRACKET
CONST KEY_ASTERISK& = _ASC_ASTERISK
CONST KEY_PLUS& = _ASC_PLUS
CONST KEY_COMMA& = _ASC_COMMA
CONST KEY_MINUS& = _ASC_MINUS
CONST KEY_FULLSTOP& = _ASC_FULLSTOP
CONST KEY_FORWARDSLASH& = _ASC_FORWARDSLASH
CONST KEY_0& = ASC_0
CONST KEY_1& = ASC_1
CONST KEY_2& = ASC_2
CONST KEY_3& = ASC_3
CONST KEY_4& = ASC_4
CONST KEY_5& = ASC_5
CONST KEY_6& = ASC_6
CONST KEY_7& = ASC_7
CONST KEY_8& = ASC_8
CONST KEY_9& = ASC_9
CONST KEY_COLON& = _ASC_COLON
CONST KEY_SEMICOLON& = _ASC_SEMICOLON
CONST KEY_LESSTHAN& = _ASC_LESSTHAN
CONST KEY_EQUAL& = _ASC_EQUAL
CONST KEY_GREATERTHAN& = _ASC_GREATERTHAN
CONST KEY_QUESTION& = _ASC_QUESTION
CONST KEY_ATSIGN& = _ASC_ATSIGN
CONST KEY_UPPER_A& = ASC_UPPER_A
CONST KEY_UPPER_B& = ASC_UPPER_B
CONST KEY_UPPER_C& = ASC_UPPER_C
CONST KEY_UPPER_D& = ASC_UPPER_D
CONST KEY_UPPER_E& = ASC_UPPER_E
CONST KEY_UPPER_F& = ASC_UPPER_F
CONST KEY_UPPER_G& = ASC_UPPER_G
CONST KEY_UPPER_H& = ASC_UPPER_H
CONST KEY_UPPER_I& = ASC_UPPER_I
CONST KEY_UPPER_J& = ASC_UPPER_J
CONST KEY_UPPER_K& = ASC_UPPER_K
CONST KEY_UPPER_L& = ASC_UPPER_L
CONST KEY_UPPER_M& = ASC_UPPER_M
CONST KEY_UPPER_N& = ASC_UPPER_N
CONST KEY_UPPER_O& = ASC_UPPER_O
CONST KEY_UPPER_P& = ASC_UPPER_P
CONST KEY_UPPER_Q& = ASC_UPPER_Q
CONST KEY_UPPER_R& = ASC_UPPER_R
CONST KEY_UPPER_S& = ASC_UPPER_S
CONST KEY_UPPER_T& = ASC_UPPER_T
CONST KEY_UPPER_U& = ASC_UPPER_U
CONST KEY_UPPER_V& = ASC_UPPER_V
CONST KEY_UPPER_W& = ASC_UPPER_W
CONST KEY_UPPER_X& = ASC_UPPER_X
CONST KEY_UPPER_Y& = ASC_UPPER_Y
CONST KEY_UPPER_Z& = ASC_UPPER_Z
CONST KEY_LEFTSQUAREBRACKET& = _ASC_LEFTSQUAREBRACKET
CONST KEY_BACKSLASH& = _ASC_BACKSLASH
CONST KEY_RIGHTSQUAREBRACKET& = _ASC_RIGHTSQUAREBRACKET
CONST KEY_CARET& = _ASC_CARET
CONST KEY_UNDERSCORE& = _ASC_UNDERSCORE
CONST KEY_GRAVE& = _ASC_GRAVE
CONST KEY_LOWER_A& = ASC_LOWER_A
CONST KEY_LOWER_B& = ASC_LOWER_B
CONST KEY_LOWER_C& = ASC_LOWER_C
CONST KEY_LOWER_D& = ASC_LOWER_D
CONST KEY_LOWER_E& = ASC_LOWER_E
CONST KEY_LOWER_F& = ASC_LOWER_F
CONST KEY_LOWER_G& = ASC_LOWER_G
CONST KEY_LOWER_H& = ASC_LOWER_H
CONST KEY_LOWER_I& = ASC_LOWER_I
CONST KEY_LOWER_J& = ASC_LOWER_J
CONST KEY_LOWER_K& = ASC_LOWER_K
CONST KEY_LOWER_L& = ASC_LOWER_L
CONST KEY_LOWER_M& = ASC_LOWER_M
CONST KEY_LOWER_N& = ASC_LOWER_N
CONST KEY_LOWER_O& = ASC_LOWER_O
CONST KEY_LOWER_P& = ASC_LOWER_P
CONST KEY_LOWER_Q& = ASC_LOWER_Q
CONST KEY_LOWER_R& = ASC_LOWER_R
CONST KEY_LOWER_S& = ASC_LOWER_S
CONST KEY_LOWER_T& = ASC_LOWER_T
CONST KEY_LOWER_U& = ASC_LOWER_U
CONST KEY_LOWER_V& = ASC_LOWER_V
CONST KEY_LOWER_W& = ASC_LOWER_W
CONST KEY_LOWER_X& = ASC_LOWER_X
CONST KEY_LOWER_Y& = ASC_LOWER_Y
CONST KEY_LOWER_Z& = ASC_LOWER_Z
CONST KEY_LEFTCURLYBRACKET& = _ASC_LEFTCURLYBRACKET
CONST KEY_VERTICALBAR& = _ASC_VERTICALBAR
CONST KEY_RIGHTCURLYBRACKET& = _ASC_RIGHTCURLYBRACKET
CONST KEY_TILDE& = _ASC_TILDE

' Control and Extended Keys
CONST KEY_ESCAPE& = _KEY_ESC
CONST KEY_ENTER& = _KEY_ENTER
CONST KEY_TAB& = _KEY_TAB
CONST KEY_BACKSPACE& = _KEY_BACKSPACE
CONST KEY_INSERT& = _KEY_INSERT
CONST KEY_DELETE& = _KEY_DELETE
CONST KEY_HOME& = _KEY_HOME
CONST KEY_END& = _KEY_END
CONST KEY_PAGEUP& = _KEY_PAGEUP
CONST KEY_PAGE_UP& = _KEY_PAGEUP
CONST KEY_PAGEDOWN& = _KEY_PAGEDOWN
CONST KEY_PAGE_DOWN& = _KEY_PAGEDOWN
CONST KEY_UP& = _KEY_UP
CONST KEY_DOWN& = _KEY_DOWN
CONST KEY_LEFT& = _KEY_LEFT
CONST KEY_RIGHT& = _KEY_RIGHT
CONST KEY_F1& = _KEY_F1
CONST KEY_F2& = _KEY_F2
CONST KEY_F3& = _KEY_F3
CONST KEY_F4& = _KEY_F4
CONST KEY_F5& = _KEY_F5
CONST KEY_F6& = _KEY_F6
CONST KEY_F7& = _KEY_F7
CONST KEY_F8& = _KEY_F8
CONST KEY_F9& = _KEY_F9
CONST KEY_F10& = _KEY_F10
CONST KEY_F11& = _KEY_F11
CONST KEY_F12& = _KEY_F12

' Virtual Key Modifiers
CONST KEY_LSHIFT& = _KEY_LSHIFT
CONST KEY_RSHIFT& = _KEY_RSHIFT
CONST KEY_LCTRL& = _KEY_LCTRL
CONST KEY_RCTRL& = _KEY_RCTRL
CONST KEY_LALT& = _KEY_LALT
CONST KEY_RALT& = _KEY_RALT
CONST KEY_LSUPER& = 100311&
CONST KEY_RSUPER& = 100312&

' Mouse Button Constants
CONST MOUSE_BUTTON_LEFT& = 1&
CONST MOUSE_BUTTON_1& = MOUSE_BUTTON_LEFT
CONST MOUSE_BUTTON_RIGHT& = 2&
CONST MOUSE_BUTTON_2& = MOUSE_BUTTON_RIGHT
CONST MOUSE_BUTTON_MIDDLE& = 3&
CONST MOUSE_BUTTON_CENTER& = MOUSE_BUTTON_MIDDLE
CONST MOUSE_BUTTON_3& = MOUSE_BUTTON_MIDDLE
CONST MOUSE_BUTTON_4& = 4&
CONST MOUSE_BUTTON_5& = 5&
CONST MOUSE_BUTTON_6& = 6&
CONST MOUSE_BUTTON_7& = 7&
CONST MOUSE_BUTTON_8& = 8&
CONST MOUSE_BUTTON_FIRST& = MOUSE_BUTTON_1
CONST MOUSE_BUTTON_LAST& = MOUSE_BUTTON_8

' Gamepad Button Constants (Standard 10-Button Layout)
CONST GAMEPAD_BUTTON_A& = 1&
CONST GAMEPAD_BUTTON_B& = 2&
CONST GAMEPAD_BUTTON_X& = 3&
CONST GAMEPAD_BUTTON_Y& = 4&
CONST GAMEPAD_BUTTON_LB& = 5&
CONST GAMEPAD_BUTTON_RB& = 6&
CONST GAMEPAD_BUTTON_LT& = 7&
CONST GAMEPAD_BUTTON_RT& = 8&
CONST GAMEPAD_BUTTON_BACK& = 9&
CONST GAMEPAD_BUTTON_START& = 10&
CONST GAMEPAD_BUTTON_FIRST& = 1&
CONST GAMEPAD_BUTTON_LAST& = 10&

' Gamepad Axis Constants
CONST GAMEPAD_AXIS_LX& = 1&
CONST GAMEPAD_AXIS_LY& = 2&
CONST GAMEPAD_AXIS_RX& = 3&
CONST GAMEPAD_AXIS_RY& = 4&
CONST GAMEPAD_AXIS_DEADZONE_DEFAULT! = 0.20!

' Internal Structures
TYPE __Input_MouseButtonState
    isDown AS _BYTE
    wasPressed AS _BYTE
    wasClicked AS _BYTE
    downPosition AS Vector2f
    upPosition AS Vector2f
    clickedBounds AS Bounds2f
END TYPE

TYPE __Input_MouseEvent
    position AS Vector2f
    lastPosition AS Vector2f
    delta AS Vector2f
    scrollWheelValue AS SINGLE
    button(MOUSE_BUTTON_first TO MOUSE_BUTTON_last) AS __Input_MouseButtonState
END TYPE

TYPE __Input_GamepadButtonState
    isDown AS _BYTE
    wasPressed AS _BYTE
    wasReleased AS _BYTE
END TYPE

TYPE __Input_GamepadState
    isConnected AS _BYTE
    stickLX AS SINGLE
    stickLY AS SINGLE
    stickRX AS SINGLE
    stickRY AS SINGLE
    lastStickLX AS SINGLE
    lastStickLY AS SINGLE
    btn(GAMEPAD_BUTTON_FIRST TO GAMEPAD_BUTTON_LAST) AS __Input_GamepadButtonState
END TYPE

TYPE __Input_WindowState
    shouldClose AS _BYTE
    resized AS _BYTE
    size AS Vector2f
END TYPE

TYPE __Input
    initialized AS _BYTE
    kbdKeyCode AS LONG
    isMouseEvent AS _BYTE
    mse AS __Input_MouseEvent
    isWindowEvent AS _BYTE
    win AS __Input_WindowState
    isGamepadEvent AS _BYTE
    gp(1 TO 2) AS __Input_GamepadState
    deadzone AS SINGLE
    navUp AS _BYTE
    navDown AS _BYTE
    navLeft AS _BYTE
    navRight AS _BYTE
    navConfirm AS _BYTE
    navCancel AS _BYTE
    navPageUp AS _BYTE
    navPageDown AS _BYTE
END TYPE

DIM __Input AS __Input

''' @brief Normalizes raw stick axis (1..254 with center ~127) to [-1.0, 1.0] with deadzone filtering.
FUNCTION __Input_NormalizeAxis! (rawValue AS INTEGER, deadzone AS SINGLE)
    DIM norm AS SINGLE: norm = _CLAMP((rawValue - 127.5!) / 126.5!, -1!, 1!)
    IF ABS(norm) < deadzone THEN
        __Input_NormalizeAxis = 0!
    ELSE
        __Input_NormalizeAxis = norm
    END IF
END FUNCTION

''' @brief Updates input manager internals, polling keyboard, mouse, gamepads, and window events.
''' Run this once per frame in the main application loop.
SUB Input_Update
    SHARED __Input AS __Input

    STATIC lastMBDown(MOUSE_BUTTON_FIRST TO MOUSE_BUTTON_LAST) AS _BYTE
    STATIC lastGPDown(1 TO 2, GAMEPAD_BUTTON_FIRST TO GAMEPAD_BUTTON_LAST) AS _BYTE

    ' One-time subsystem initialization
    IF NOT __Input.initialized THEN
        DIM dummyDev AS LONG: dummyDev = _DEVICES
        __Input.deadzone = GAMEPAD_AXIS_DEADZONE_DEFAULT
        __Input.initialized = _TRUE
    END IF

    ' 1. Poll Keyboard
    __Input.kbdKeyCode = _KEYHIT

    ' 2. Reset Mouse Transient State
    __Input.isMouseEvent = _FALSE
    __Input.mse.lastPosition = __Input.mse.position
    __Input.mse.scrollWheelValue = 0!
    __Input.mse.delta.x = 0!
    __Input.mse.delta.y = 0!

    DIM i AS LONG
    FOR i = MOUSE_BUTTON_FIRST TO MOUSE_BUTTON_LAST
        __Input.mse.button(i).wasPressed = _FALSE
        __Input.mse.button(i).wasClicked = _FALSE
    NEXT i

    ' 3. Process Pending Mouse Events
    DO WHILE _MOUSEINPUT
        __Input.isMouseEvent = _TRUE

        Vector2f_Set _MOUSEX, _MOUSEY, __Input.mse.position
        __Input.mse.scrollWheelValue = __Input.mse.scrollWheelValue + _MOUSEWHEEL

        FOR i = MOUSE_BUTTON_FIRST TO MOUSE_BUTTON_LAST
            DIM currentDown AS _BYTE: currentDown = _MOUSEBUTTON(i)

            IF currentDown _ANDALSO NOT lastMBDown(i) THEN
                __Input.mse.button(i).downPosition = __Input.mse.position
                __Input.mse.button(i).clickedBounds.lt = __Input.mse.position
                __Input.mse.button(i).wasPressed = _TRUE
            ELSEIF NOT currentDown _ANDALSO lastMBDown(i) THEN
                __Input.mse.button(i).upPosition = __Input.mse.position
                __Input.mse.button(i).clickedBounds.rb = __Input.mse.position
                Bounds2f_Sanitize __Input.mse.button(i).clickedBounds
                __Input.mse.button(i).wasClicked = _TRUE
            END IF

            __Input.mse.button(i).isDown = currentDown
            lastMBDown(i) = currentDown
        NEXT i
    LOOP

    ' Compute mouse delta for the frame
    Vector2f_Subtract __Input.mse.position, __Input.mse.lastPosition, __Input.mse.delta

    ' 4. Poll Game Controllers (Gamepad 1 and 2)
    __Input.isGamepadEvent = _FALSE
    DIM gpIdx AS LONG
    FOR gpIdx = 1 TO 2
        DIM stickX AS INTEGER, stickY AS INTEGER
        DIM stick2X AS INTEGER, stick2Y AS INTEGER

        stickX = STICK(0, gpIdx)
        stickY = STICK(1, gpIdx)
        stick2X = STICK(0, gpIdx + 1)
        stick2Y = STICK(1, gpIdx + 1)

        __Input.gp(gpIdx).stickLX = __Input_NormalizeAxis(stickX, __Input.deadzone)
        __Input.gp(gpIdx).stickLY = __Input_NormalizeAxis(stickY, __Input.deadzone)
        __Input.gp(gpIdx).stickRX = __Input_NormalizeAxis(stick2X, __Input.deadzone)
        __Input.gp(gpIdx).stickRY = __Input_NormalizeAxis(stick2Y, __Input.deadzone)

        IF __Input.gp(gpIdx).stickLX <> 0! _ORELSE __Input.gp(gpIdx).stickLY <> 0! _ORELSE __Input.gp(gpIdx).stickRX <> 0! _ORELSE __Input.gp(gpIdx).stickRY <> 0! THEN
            __Input.isGamepadEvent = _TRUE
        END IF

        ' Poll buttons 1 to 10
        DIM b AS LONG
        FOR b = GAMEPAD_BUTTON_FIRST TO GAMEPAD_BUTTON_LAST
            DIM btnDown AS _BYTE
            IF gpIdx = 1 THEN
                btnDown = STRIG((b - 1) * 4 + 1)
            ELSE
                btnDown = STRIG((b - 1) * 4 + 3)
            END IF

            __Input.gp(gpIdx).btn(b).wasPressed = (btnDown _ANDALSO NOT lastGPDown(gpIdx, b))
            __Input.gp(gpIdx).btn(b).wasReleased = (NOT btnDown _ANDALSO lastGPDown(gpIdx, b))
            __Input.gp(gpIdx).btn(b).isDown = btnDown

            IF btnDown _ORELSE __Input.gp(gpIdx).btn(b).wasPressed _ORELSE __Input.gp(gpIdx).btn(b).wasReleased THEN
                __Input.isGamepadEvent = _TRUE
            END IF

            lastGPDown(gpIdx, b) = btnDown
        NEXT b
    NEXT gpIdx

    ' 5. Poll Window Events
    __Input.isWindowEvent = _FALSE
    __Input.win.shouldClose = _FALSE
    __Input.win.resized = _FALSE

    IF _RESIZE THEN
        __Input.isWindowEvent = _TRUE
        __Input.win.resized = _TRUE
        Vector2f_Set _RESIZEWIDTH, _RESIZEHEIGHT, __Input.win.size
    END IF

    IF _EXIT THEN
        __Input.isWindowEvent = _TRUE
        __Input.win.shouldClose = _TRUE
    END IF

    ' 6. Synthesize Discrete TUI Navigation Pulses
    DIM sLX AS SINGLE: sLX = __Input.gp(1).stickLX
    DIM sLY AS SINGLE: sLY = __Input.gp(1).stickLY
    DIM prevLX AS SINGLE: prevLX = __Input.gp(1).lastStickLX
    DIM prevLY AS SINGLE: prevLY = __Input.gp(1).lastStickLY

    DIM gpTiltUp AS _BYTE: gpTiltUp = (sLY < -0.5!) _ANDALSO (prevLY >= -0.5!)
    DIM gpTiltDown AS _BYTE: gpTiltDown = (sLY > 0.5!) _ANDALSO (prevLY <= 0.5!)
    DIM gpTiltLeft AS _BYTE: gpTiltLeft = (sLX < -0.5!) _ANDALSO (prevLX >= -0.5!)
    DIM gpTiltRight AS _BYTE: gpTiltRight = (sLX > 0.5!) _ANDALSO (prevLX <= 0.5!)

    __Input.navUp = (__Input.kbdKeyCode = _KEY_UP _ORELSE __Input.kbdKeyCode = 100208& _ORELSE gpTiltUp)
    __Input.navDown = (__Input.kbdKeyCode = _KEY_DOWN _ORELSE __Input.kbdKeyCode = 100202& _ORELSE gpTiltDown)
    __Input.navLeft = (__Input.kbdKeyCode = _KEY_LEFT _ORELSE __Input.kbdKeyCode = 100204& _ORELSE gpTiltLeft)
    __Input.navRight = (__Input.kbdKeyCode = _KEY_RIGHT _ORELSE __Input.kbdKeyCode = 100206& _ORELSE gpTiltRight)
    __Input.navConfirm = (__Input.kbdKeyCode = KEY_ENTER _ORELSE __Input.kbdKeyCode = 100271& _ORELSE __Input.kbdKeyCode = KEY_SPACE _ORELSE __Input.gp(1).btn(GAMEPAD_BUTTON_A).wasPressed _ORELSE __Input.gp(1).btn(GAMEPAD_BUTTON_START).wasPressed)
    __Input.navCancel = (__Input.kbdKeyCode = KEY_ESCAPE _ORELSE __Input.gp(1).btn(GAMEPAD_BUTTON_B).wasPressed _ORELSE __Input.gp(1).btn(GAMEPAD_BUTTON_BACK).wasPressed)
    __Input.navPageUp = (__Input.kbdKeyCode = _KEY_PAGEUP _ORELSE __Input.kbdKeyCode = 100209& _ORELSE __Input.gp(1).btn(GAMEPAD_BUTTON_LB).wasPressed)
    __Input.navPageDown = (__Input.kbdKeyCode = _KEY_PAGEDOWN _ORELSE __Input.kbdKeyCode = 100203& _ORELSE __Input.gp(1).btn(GAMEPAD_BUTTON_RB).wasPressed)

    __Input.gp(1).lastStickLX = sLX
    __Input.gp(1).lastStickLY = sLY
END SUB

''' @brief Alias of Input_Update for compatibility with GlyphUI code.
SUB Input_Poll
    Input_Update
END SUB

''' @brief Returns true if any event is pending (keyboard, mouse, window, or gamepad).
FUNCTION Input_HasEvent%%
    SHARED __Input AS __Input
    Input_HasEvent = __Input.kbdKeyCode <> 0 _ORELSE __Input.isMouseEvent _ORELSE __Input.isWindowEvent _ORELSE __Input.isGamepadEvent
END FUNCTION

''' @brief Returns true if a keyboard key hit is pending.
FUNCTION Input_HasKeyboardEvent%%
    SHARED __Input AS __Input
    Input_HasKeyboardEvent = __Input.kbdKeyCode <> 0
END FUNCTION

''' @brief Returns the last key code without consuming it.
FUNCTION Input_PeekKeyboardKey&
    SHARED __Input AS __Input
    Input_PeekKeyboardKey = __Input.kbdKeyCode
END FUNCTION

''' @brief Returns the last key code and consumes it.
FUNCTION Input_GetKeyboardKey&
    SHARED __Input AS __Input
    Input_GetKeyboardKey = __Input.kbdKeyCode
    __Input.kbdKeyCode = 0
END FUNCTION

''' @brief Checks if a specific key is currently held down.
FUNCTION Input_IsKeyDown%% (keyCode AS LONG)
    Input_IsKeyDown = _KEYDOWN(keyCode)
END FUNCTION

''' @brief Alias of Input_IsKeyDown for compatibility.
FUNCTION Input_IsKeyPressed%% (keyCode AS LONG)
    Input_IsKeyPressed = _KEYDOWN(keyCode)
END FUNCTION

''' @brief Returns true if Shift (left or right) is held down.
FUNCTION Input_IsShiftDown%%
    Input_IsShiftDown = _KEYDOWN(KEY_LSHIFT) _ORELSE _KEYDOWN(KEY_RSHIFT)
END FUNCTION

''' @brief Returns true if Ctrl (left or right) is held down.
FUNCTION Input_IsCtrlDown%%
    Input_IsCtrlDown = _KEYDOWN(KEY_LCTRL) _ORELSE _KEYDOWN(KEY_RCTRL)
END FUNCTION

''' @brief Returns true if Alt (left or right) is held down.
FUNCTION Input_IsAltDown%%
    Input_IsAltDown = _KEYDOWN(KEY_LALT) _ORELSE _KEYDOWN(KEY_RALT)
END FUNCTION

''' @brief Returns true if the Super/Windows/Command key is held down.
FUNCTION Input_IsSuperDown%%
    Input_IsSuperDown = _KEYDOWN(KEY_LSUPER) _ORELSE _KEYDOWN(KEY_RSUPER)
END FUNCTION

''' @brief Returns true if mouse activity occurred this frame.
FUNCTION Input_HasMouseEvent%%
    SHARED __Input AS __Input
    Input_HasMouseEvent = __Input.isMouseEvent
END FUNCTION

''' @brief Returns the current mouse X coordinate.
FUNCTION Input_GetMouseX!
    SHARED __Input AS __Input
    Input_GetMouseX = __Input.mse.position.x
END FUNCTION

''' @brief Returns the current mouse Y coordinate.
FUNCTION Input_GetMouseY!
    SHARED __Input AS __Input
    Input_GetMouseY = __Input.mse.position.y
END FUNCTION

''' @brief Gets the current mouse position in a Vector2f.
SUB Input_GetMousePosition (position AS Vector2f)
    SHARED __Input AS __Input
    position = __Input.mse.position
END SUB

''' @brief Gets the current mouse position in scalar x and y coordinates.
SUB Input_GetMousePositionXY (x AS SINGLE, y AS SINGLE)
    SHARED __Input AS __Input
    x = __Input.mse.position.x
    y = __Input.mse.position.y
END SUB

''' @brief Returns the mouse X movement delta since the last frame.
FUNCTION Input_GetMouseDeltaX!
    SHARED __Input AS __Input
    Input_GetMouseDeltaX = __Input.mse.delta.x
END FUNCTION

''' @brief Returns the mouse Y movement delta since the last frame.
FUNCTION Input_GetMouseDeltaY!
    SHARED __Input AS __Input
    Input_GetMouseDeltaY = __Input.mse.delta.y
END FUNCTION

''' @brief Gets the mouse movement delta vector.
SUB Input_GetMouseDelta (delta AS Vector2f)
    SHARED __Input AS __Input
    delta = __Input.mse.delta
END SUB

''' @brief Gets the mouse movement delta in scalar dx and dy coordinates.
SUB Input_GetMouseDeltaXY (dx AS SINGLE, dy AS SINGLE)
    SHARED __Input AS __Input
    dx = __Input.mse.delta.x
    dy = __Input.mse.delta.y
END SUB

''' @brief Returns the accumulated mouse scroll wheel delta for the frame.
FUNCTION Input_GetMouseScrollWheelValue!
    SHARED __Input AS __Input
    Input_GetMouseScrollWheelValue = __Input.mse.scrollWheelValue
END FUNCTION

''' @brief Alias of Input_GetMouseScrollWheelValue.
FUNCTION Input_GetMouseWheel!
    SHARED __Input AS __Input
    Input_GetMouseWheel = __Input.mse.scrollWheelValue
END FUNCTION

''' @brief Checks if a mouse button is currently held down.
FUNCTION Input_IsMouseButtonDown%% (button AS LONG)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        Input_IsMouseButtonDown = __Input.mse.button(button).isDown
    END IF
END FUNCTION

''' @brief Checks if a mouse button is currently held down (alias of Input_IsMouseButtonDown).
FUNCTION Input_IsMouseButtonPressed%% (button AS LONG)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        Input_IsMouseButtonPressed = __Input.mse.button(button).isDown
    END IF
END FUNCTION

''' @brief Checks if a mouse button was pressed down during this frame.
FUNCTION Input_WasMouseButtonPressed%% (button AS LONG)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        Input_WasMouseButtonPressed = __Input.mse.button(button).wasPressed
    END IF
END FUNCTION

''' @brief Checks if a mouse button was pressed down during this frame and consumes the flag.
FUNCTION Input_GetMouseButtonPressed%% (button AS LONG)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        Input_GetMouseButtonPressed = __Input.mse.button(button).wasPressed
        __Input.mse.button(button).wasPressed = _FALSE
    END IF
END FUNCTION

''' @brief Checks if a mouse button was clicked (released) during this frame.
FUNCTION Input_WasMouseButtonClicked%% (button AS LONG)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        Input_WasMouseButtonClicked = __Input.mse.button(button).wasClicked
    END IF
END FUNCTION

''' @brief Checks if a mouse button was clicked during this frame and consumes the flag.
FUNCTION Input_GetMouseButtonClicked%% (button AS LONG)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        Input_GetMouseButtonClicked = __Input.mse.button(button).wasClicked
        __Input.mse.button(button).wasClicked = _FALSE
    END IF
END FUNCTION

''' @brief Gets the position where the mouse button was pressed down.
SUB Input_GetMouseButtonDownPosition (button AS LONG, position AS Vector2f)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        position = __Input.mse.button(button).downPosition
    END IF
END SUB

''' @brief Gets the position where the mouse button was released.
SUB Input_GetMouseButtonUpPosition (button AS LONG, position AS Vector2f)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        position = __Input.mse.button(button).upPosition
    END IF
END SUB

''' @brief Gets the bounding box enclosing the mouse down and release positions.
SUB Input_GetMouseButtonClickBounds (button AS LONG, bounds AS Bounds2f)
    SHARED __Input AS __Input
    IF button >= MOUSE_BUTTON_FIRST _ANDALSO button <= MOUSE_BUTTON_LAST THEN
        bounds = __Input.mse.button(button).clickedBounds
    END IF
END SUB

''' @brief Tests if the mouse cursor is inside a rectangular region.
FUNCTION Input_IsMouseInRect%% (x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE)
    SHARED __Input AS __Input
    DIM minX AS SINGLE: minX = _MIN(x1, x2)
    DIM maxX AS SINGLE: maxX = _MAX(x1, x2)
    DIM minY AS SINGLE: minY = _MIN(y1, y2)
    DIM maxY AS SINGLE: maxY = _MAX(y1, y2)
    Input_IsMouseInRect = __Input.mse.position.x >= minX _ANDALSO __Input.mse.position.x <= maxX _ANDALSO __Input.mse.position.y >= minY _ANDALSO __Input.mse.position.y <= maxY
END FUNCTION

''' @brief Tests if the mouse cursor is inside a Bounds2f region.
FUNCTION Input_IsMouseInBounds%% (bounds AS Bounds2f)
    Input_IsMouseInBounds = Input_IsMouseInRect(bounds.lt.x, bounds.lt.y, bounds.rb.x, bounds.rb.y)
END FUNCTION

''' @brief Tests if a mouse button was clicked inside a rectangular region.
FUNCTION Input_IsMouseClickInRect%% (button AS LONG, x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE)
    SHARED __Input AS __Input
    IF button < MOUSE_BUTTON_FIRST _ORELSE button > MOUSE_BUTTON_LAST THEN EXIT FUNCTION
    IF __Input.mse.button(button).wasClicked THEN
        DIM minX AS SINGLE: minX = _MIN(x1, x2)
        DIM maxX AS SINGLE: maxX = _MAX(x1, x2)
        DIM minY AS SINGLE: minY = _MIN(y1, y2)
        DIM maxY AS SINGLE: maxY = _MAX(y1, y2)
        DIM px AS SINGLE: px = __Input.mse.button(button).upPosition.x
        DIM py AS SINGLE: py = __Input.mse.button(button).upPosition.y
        Input_IsMouseClickInRect = px >= minX _ANDALSO px <= maxX _ANDALSO py >= minY _ANDALSO py <= maxY
    END IF
END FUNCTION

''' @brief Tests if a mouse button was clicked inside a Bounds2f region.
FUNCTION Input_IsMouseClickInBounds%% (button AS LONG, bounds AS Bounds2f)
    Input_IsMouseClickInBounds = Input_IsMouseClickInRect(button, bounds.lt.x, bounds.lt.y, bounds.rb.x, bounds.rb.y)
END FUNCTION

''' @brief Tests if a mouse button was pressed inside a rectangular region.
FUNCTION Input_IsMousePressInRect%% (button AS LONG, x1 AS SINGLE, y1 AS SINGLE, x2 AS SINGLE, y2 AS SINGLE)
    SHARED __Input AS __Input
    IF button < MOUSE_BUTTON_FIRST _ORELSE button > MOUSE_BUTTON_LAST THEN EXIT FUNCTION
    IF __Input.mse.button(button).wasPressed THEN
        DIM minX AS SINGLE: minX = _MIN(x1, x2)
        DIM maxX AS SINGLE: maxX = _MAX(x1, x2)
        DIM minY AS SINGLE: minY = _MIN(y1, y2)
        DIM maxY AS SINGLE: maxY = _MAX(y1, y2)
        DIM px AS SINGLE: px = __Input.mse.button(button).downPosition.x
        DIM py AS SINGLE: py = __Input.mse.button(button).downPosition.y
        Input_IsMousePressInRect = px >= minX _ANDALSO px <= maxX _ANDALSO py >= minY _ANDALSO py <= maxY
    END IF
END FUNCTION

''' @brief Tests if a mouse button was pressed inside a Bounds2f region.
FUNCTION Input_IsMousePressInBounds%% (button AS LONG, bounds AS Bounds2f)
    Input_IsMousePressInBounds = Input_IsMousePressInRect(button, bounds.lt.x, bounds.lt.y, bounds.rb.x, bounds.rb.y)
END FUNCTION

''' @brief Returns true if gamepad activity occurred this frame.
FUNCTION Input_HasGamepadEvent%%
    SHARED __Input AS __Input
    Input_HasGamepadEvent = __Input.isGamepadEvent
END FUNCTION

''' @brief Checks if a gamepad is connected.
FUNCTION Input_IsGamepadConnected%% (gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 THEN
        Input_IsGamepadConnected = __Input.gp(gamepadIndex).isConnected
    END IF
END FUNCTION

''' @brief Returns the normalized left stick X axis [-1.0, 1.0].
FUNCTION Input_GetGamepadStickLX! (gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 THEN
        Input_GetGamepadStickLX = __Input.gp(gamepadIndex).stickLX
    END IF
END FUNCTION

''' @brief Returns the normalized left stick Y axis [-1.0, 1.0].
FUNCTION Input_GetGamepadStickLY! (gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 THEN
        Input_GetGamepadStickLY = __Input.gp(gamepadIndex).stickLY
    END IF
END FUNCTION

''' @brief Returns the normalized right stick X axis [-1.0, 1.0].
FUNCTION Input_GetGamepadStickRX! (gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 THEN
        Input_GetGamepadStickRX = __Input.gp(gamepadIndex).stickRX
    END IF
END FUNCTION

''' @brief Returns the normalized right stick Y axis [-1.0, 1.0].
FUNCTION Input_GetGamepadStickRY! (gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 THEN
        Input_GetGamepadStickRY = __Input.gp(gamepadIndex).stickRY
    END IF
END FUNCTION

''' @brief Gets the normalized left stick vector.
SUB Input_GetGamepadStickL (vec AS Vector2f, gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 THEN
        vec.x = __Input.gp(gamepadIndex).stickLX
        vec.y = __Input.gp(gamepadIndex).stickLY
    END IF
END SUB

''' @brief Gets the normalized right stick vector.
SUB Input_GetGamepadStickR (vec AS Vector2f, gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 THEN
        vec.x = __Input.gp(gamepadIndex).stickRX
        vec.y = __Input.gp(gamepadIndex).stickRY
    END IF
END SUB

''' @brief Gets a gamepad axis value by axis index (GAMEPAD_AXIS_*).
FUNCTION Input_GetGamepadAxis! (axisIndex AS LONG, gamepadIndex AS LONG)
    SELECT CASE axisIndex
        CASE GAMEPAD_AXIS_LX
            Input_GetGamepadAxis = Input_GetGamepadStickLX(gamepadIndex)
        CASE GAMEPAD_AXIS_LY
            Input_GetGamepadAxis = Input_GetGamepadStickLY(gamepadIndex)
        CASE GAMEPAD_AXIS_RX
            Input_GetGamepadAxis = Input_GetGamepadStickRX(gamepadIndex)
        CASE GAMEPAD_AXIS_RY
            Input_GetGamepadAxis = Input_GetGamepadStickRY(gamepadIndex)
    END SELECT
END FUNCTION

''' @brief Checks if a gamepad button is currently held down.
FUNCTION Input_IsGamepadButtonDown%% (buttonIndex AS LONG, gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 _ANDALSO buttonIndex >= GAMEPAD_BUTTON_FIRST _ANDALSO buttonIndex <= GAMEPAD_BUTTON_LAST THEN
        Input_IsGamepadButtonDown = __Input.gp(gamepadIndex).btn(buttonIndex).isDown
    END IF
END FUNCTION

''' @brief Checks if a gamepad button was pressed down this frame.
FUNCTION Input_WasGamepadButtonPressed%% (buttonIndex AS LONG, gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 _ANDALSO buttonIndex >= GAMEPAD_BUTTON_FIRST _ANDALSO buttonIndex <= GAMEPAD_BUTTON_LAST THEN
        Input_WasGamepadButtonPressed = __Input.gp(gamepadIndex).btn(buttonIndex).wasPressed
    END IF
END FUNCTION

''' @brief Checks if a gamepad button was pressed down this frame and consumes the flag.
FUNCTION Input_GetGamepadButtonPressed%% (buttonIndex AS LONG, gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 _ANDALSO buttonIndex >= GAMEPAD_BUTTON_FIRST _ANDALSO buttonIndex <= GAMEPAD_BUTTON_LAST THEN
        Input_GetGamepadButtonPressed = __Input.gp(gamepadIndex).btn(buttonIndex).wasPressed
        __Input.gp(gamepadIndex).btn(buttonIndex).wasPressed = _FALSE
    END IF
END FUNCTION

''' @brief Checks if a gamepad button was released this frame.
FUNCTION Input_WasGamepadButtonReleased%% (buttonIndex AS LONG, gamepadIndex AS LONG)
    SHARED __Input AS __Input
    IF gamepadIndex >= 1 _ANDALSO gamepadIndex <= 2 _ANDALSO buttonIndex >= GAMEPAD_BUTTON_FIRST _ANDALSO buttonIndex <= GAMEPAD_BUTTON_LAST THEN
        Input_WasGamepadButtonReleased = __Input.gp(gamepadIndex).btn(buttonIndex).wasReleased
    END IF
END FUNCTION

''' @brief Sets the analog stick deadzone (clamped between 0.0 and 0.99).
SUB Input_SetGamepadDeadzone (deadzone AS SINGLE)
    SHARED __Input AS __Input
    __Input.deadzone = _CLAMP(deadzone, 0!, 0.99!)
END SUB

''' @brief Returns the current analog stick deadzone.
FUNCTION Input_GetGamepadDeadzone!
    SHARED __Input AS __Input
    Input_GetGamepadDeadzone = __Input.deadzone
END FUNCTION

''' @brief Compatibility function returning raw controller stick axis (1..254).
FUNCTION Input_GetControllerAxis% (axis AS INTEGER)
    SHARED __Input AS __Input
    IF axis = 0 THEN
        Input_GetControllerAxis = CINT((__Input.gp(1).stickLX * 126.5!) + 127.5!)
    ELSEIF axis = 1 THEN
        Input_GetControllerAxis = CINT((__Input.gp(1).stickLY * 126.5!) + 127.5!)
    ELSE
        Input_GetControllerAxis = 127
    END IF
END FUNCTION

''' @brief Compatibility function returning button state for Gamepad 1.
FUNCTION Input_IsControllerButtonPressed% (button AS INTEGER)
    SHARED __Input AS __Input
    IF button >= GAMEPAD_BUTTON_FIRST _ANDALSO button <= GAMEPAD_BUTTON_LAST THEN
        Input_IsControllerButtonPressed = __Input.gp(1).btn(button).isDown
    END IF
END FUNCTION

''' @brief TUI navigation: returns true if Up navigation was triggered (Arrow Up, Keypad Up, or Stick Up pulse).
FUNCTION Input_NavUp%%
    SHARED __Input AS __Input
    Input_NavUp = __Input.navUp
END FUNCTION

''' @brief TUI navigation: returns true if Down navigation was triggered.
FUNCTION Input_NavDown%%
    SHARED __Input AS __Input
    Input_NavDown = __Input.navDown
END FUNCTION

''' @brief TUI navigation: returns true if Left navigation was triggered.
FUNCTION Input_NavLeft%%
    SHARED __Input AS __Input
    Input_NavLeft = __Input.navLeft
END FUNCTION

''' @brief TUI navigation: returns true if Right navigation was triggered.
FUNCTION Input_NavRight%%
    SHARED __Input AS __Input
    Input_NavRight = __Input.navRight
END FUNCTION

''' @brief TUI navigation: returns true if Confirm action was triggered (Enter, Space, or Gamepad Button A / Start).
FUNCTION Input_NavConfirm%%
    SHARED __Input AS __Input
    Input_NavConfirm = __Input.navConfirm
END FUNCTION

''' @brief TUI navigation: returns true if Cancel action was triggered (Escape or Gamepad Button B / Back).
FUNCTION Input_NavCancel%%
    SHARED __Input AS __Input
    Input_NavCancel = __Input.navCancel
END FUNCTION

''' @brief TUI navigation: returns true if Page Up navigation was triggered (PageUp or Left Bumper).
FUNCTION Input_NavPageUp%%
    SHARED __Input AS __Input
    Input_NavPageUp = __Input.navPageUp
END FUNCTION

''' @brief TUI navigation: returns true if Page Down navigation was triggered (PageDown or Right Bumper).
FUNCTION Input_NavPageDown%%
    SHARED __Input AS __Input
    Input_NavPageDown = __Input.navPageDown
END FUNCTION

''' @brief Returns true if window resize or close occurred.
FUNCTION Input_HasWindowEvent%%
    SHARED __Input AS __Input
    Input_HasWindowEvent = __Input.isWindowEvent
END FUNCTION

''' @brief Returns true if window close was requested.
FUNCTION Input_WindowShouldClose%%
    SHARED __Input AS __Input
    Input_WindowShouldClose = __Input.win.shouldClose
END FUNCTION

''' @brief Sets the window should close state.
SUB Input_SetWindowShouldClose (shouldClose AS _BYTE)
    SHARED __Input AS __Input
    __Input.win.shouldClose = shouldClose
END SUB

''' @brief Returns true if the window was resized this frame.
FUNCTION Input_WasWindowResized%%
    SHARED __Input AS __Input
    Input_WasWindowResized = __Input.win.resized
END FUNCTION

''' @brief Returns the new window width if resized.
FUNCTION Input_GetWindowResizeWidth!
    SHARED __Input AS __Input
    Input_GetWindowResizeWidth = __Input.win.size.x
END FUNCTION

''' @brief Returns the new window height if resized.
FUNCTION Input_GetWindowResizeHeight!
    SHARED __Input AS __Input
    Input_GetWindowResizeHeight = __Input.win.size.y
END FUNCTION

''' @brief Gets the new window size vector if resized.
SUB Input_GetWindowResizeSize (size AS Vector2f)
    SHARED __Input AS __Input
    size = __Input.win.size
END SUB
