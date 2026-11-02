'-----------------------------------------------------------------------------------------------------------------------
' An Input Manager system for QB64-PE
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$LET TOOLBOX64_STRICT = TRUE
'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Math/Math.bi'
'$INCLUDE:'../Math/Vector2i.bi'
'$INCLUDE:'../Math/Bounds2i.bi'
'$INCLUDE:'../Core/String.bi'

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

CONST MOUSE_BUTTON_LEFT& = 1&
CONST MOUSE_BUTTON_RIGHT& = 2&
CONST MOUSE_BUTTON_CENTER& = 3&
CONST MOUSE_BUTTON_FIRST& = MOUSE_BUTTON_LEFT
CONST MOUSE_BUTTON_LAST& = MOUSE_BUTTON_CENTER

TYPE __InputManager_MouseButtonState
    isDown AS _BYTE
    wasPressed AS _BYTE
    wasClicked AS _BYTE
    downPosition AS Vector2i
    upPosition AS Vector2i
    clickedBounds AS Bounds2i
END TYPE

TYPE __InputManager_MouseEvent
    position AS Vector2i
    scrollWheelValue AS LONG
END TYPE

TYPE __InputManager_WindowEvent
    shouldClose AS _BYTE
    resized AS _BYTE
    size AS Vector2i
END TYPE

TYPE __InputManager_GamepadEvent
    axis1 AS SINGLE
    asix2 AS SINGLE
    axis3 AS SINGLE
    axis4 AS SINGLE
    button1WasDown AS _BYTE
    button1Down AS _BYTE
    button2WasDown AS _BYTE
    button2Down AS _BYTE
    button3WasDown AS _BYTE
    button3Down AS _BYTE
    button4WasDown AS _BYTE
    button4Down AS _BYTE
END TYPE

TYPE __InputManager
    kbdKeyCode AS LONG
    isMouseEvent AS _BYTE
    mse AS __InputManager_MouseEvent
    isWindowEvent AS _BYTE
    win AS __InputManager_WindowEvent
    isGamepad1Event AS _BYTE
    gp1 AS __InputManager_GamepadEvent
    isGamepad2Event AS _BYTE
    gp2 AS __InputManager_GamepadEvent
END TYPE

DIM __InputManager AS __InputManager
DIM __InputManager_MouseButtonState(MOUSE_BUTTON_FIRST TO MOUSE_BUTTON_LAST) AS __InputManager_MouseButtonState

FUNCTION __InputManager_GetNormalizeGamepadAxis! (rawValue AS LONG)
    __InputManager_GetNormalizeGamepadAxis = Math_ClampSingle((rawValue - 127.5!) / 126.5!, -1!, 1!)
END FUNCTION

''' @brief Updates the input manager internals and collects events and inputs by polling various functions.
''' Run this once in the main loop and then use the other APIs to react to events.
SUB InputManager_Update
    SHARED __InputManager AS __InputManager
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    STATIC lastMBDown(MOUSE_BUTTON_FIRST TO MOUSE_BUTTON_LAST) AS _BYTE

    ' Get keyboard input from the keyboard buffer
    __InputManager.kbdKeyCode = _KEYHIT

    ' Clear transient states
    __InputManager.isMouseEvent = _FALSE
    __InputManager.mse.scrollWheelValue = 0

    DIM i AS LONG
    FOR i = MOUSE_BUTTON_FIRST TO MOUSE_BUTTON_LAST
        __InputManager_MouseButtonState(i).wasPressed = _FALSE
        __InputManager_MouseButtonState(i).wasClicked = _FALSE
    NEXT i

    __InputManager.isWindowEvent = _FALSE
    __InputManager.win.shouldClose = _FALSE
    __InputManager.win.resized = _FALSE
    __InputManager.isGamepad1Event = _FALSE
    __InputManager.isGamepad2Event = _FALSE

    ' Process all pending mouse events
    DO WHILE _MOUSEINPUT
        __InputManager.isMouseEvent = _TRUE

        ' Update global real-time position
        Vector2i_Initialize _MOUSEX, _MOUSEY, __InputManager.mse.position

        ' Accumulate scroll wheel movement
        __InputManager.mse.scrollWheelValue = __InputManager.mse.scrollWheelValue + _MOUSEWHEEL

        ' Process button transitions for tracked buttons
        FOR i = MOUSE_BUTTON_FIRST TO MOUSE_BUTTON_LAST
            DIM currentDown AS _BYTE: currentDown = _MOUSEBUTTON(i)
            
            IF currentDown _ANDALSO NOT lastMBDown(i) THEN
                ' Pressed transition
                __InputManager_MouseButtonState(i).downPosition = __InputManager.mse.position
                __InputManager_MouseButtonState(i).clickedBounds.lt = __InputManager.mse.position
                __InputManager_MouseButtonState(i).wasPressed = _TRUE
            ELSEIF NOT currentDown _ANDALSO lastMBDown(i) THEN
                ' Clicked (Released) transition
                __InputManager_MouseButtonState(i).upPosition = __InputManager.mse.position
                __InputManager_MouseButtonState(i).clickedBounds.rb = __InputManager.mse.position
                Bounds2i_Sanitize __InputManager_MouseButtonState(i).clickedBounds
                __InputManager_MouseButtonState(i).wasClicked = _TRUE
            END IF
            
            ' Update states
            __InputManager_MouseButtonState(i).isDown = currentDown
            lastMBDown(i) = currentDown
        NEXT i
    LOOP

    ' Gather window events
    IF _RESIZE THEN
        __InputManager.isWindowEvent = _TRUE
        __InputManager.win.resized = _TRUE
        Vector2i_Initialize _RESIZEWIDTH, _RESIZEHEIGHT, __InputManager.win.size
    END IF

    IF _EXIT THEN
        __InputManager.isWindowEvent = _TRUE
        __InputManager.win.shouldClose = _TRUE
    END IF
END SUB

''' @brief Returns true if the input manager has any event waiting to be processed.
''' @return True if the input manager has any event waiting to be processed.
FUNCTION InputManager_HasEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasEvent = __InputManager.kbdKeyCode <> _ASC_NUL _ORELSE __InputManager.isMouseEvent _ORELSE __InputManager.isWindowEvent _ORELSE __InputManager.isGamepad1Event _ORELSE __InputManager.isGamepad2Event
END FUNCTION

''' @brief Returns true if a keyboard event is waiting to be processed.
''' @return True if a keyboard event is waiting to be processed.
FUNCTION InputManager_HasKeyboardEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasKeyboardEvent = __InputManager.kbdKeyCode <> _ASC_NUL
END FUNCTION

''' @brief Returns the last key read by the input manager. But does not consume the key.
''' @return The last key read by the input manager. Or 0 is no key was read.
FUNCTION InputManager_PeekKeyboardKey&
    SHARED __InputManager AS __InputManager
    InputManager_PeekKeyboardKey = __InputManager.kbdKeyCode
END FUNCTION

''' @brief Returns the last key read by the input manager and consumes the key.
''' @return The last key read by the input manager. Or 0 is no key was read.
FUNCTION InputManager_GetKeyboardKey&
    SHARED __InputManager AS __InputManager
    InputManager_GetKeyboardKey = __InputManager.kbdKeyCode
    __InputManager.kbdKeyCode = _ASC_NUL
END FUNCTION

''' @brief Returns true if a mouse event is waiting to be processed.
''' @return True if a mouse event is waiting to be processed.
FUNCTION InputManager_HasMouseEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasMouseEvent = __InputManager.isMouseEvent
END FUNCTION

''' @brief Returns the mouse X position.
''' @return The mouse X position.
FUNCTION InputManager_GetMousePositionX&
    SHARED __InputManager AS __InputManager
    InputManager_GetMousePositionX = __InputManager.mse.position.x
END FUNCTION

''' @brief Returns the mouse Y position.
''' @return The mouse Y position.
FUNCTION InputManager_GetMousePositionY&
    SHARED __InputManager AS __InputManager
    InputManager_GetMousePositionY = __InputManager.mse.position.y
END FUNCTION

''' @brief Returns the mouse position.
''' @param position The x and y position in a Vector2i.
SUB InputManager_GetMousePosition (position AS Vector2i)
    SHARED __InputManager AS __InputManager
    position = __InputManager.mse.position
END SUB

''' @brief Returns the mouse scroll wheel value.
''' @return The mouse scroll wheel value.
FUNCTION InputManager_GetMouseScrollWheelValue&
    SHARED __InputManager AS __InputManager
    InputManager_GetMouseScrollWheelValue = __InputManager.mse.scrollWheelValue
END FUNCTION

''' @brief Returns true if a mouse button is down.
''' @return True if the mouse button is down.
FUNCTION InputManager_IsMouseButtonDown%% (button AS LONG)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    InputManager_IsMouseButtonDown = __InputManager_MouseButtonState(button).isDown
END FUNCTION

''' @brief Gets the position where the mouse button was pressed down.
''' @param button The mouse button to check.
''' @param position The x and y position in a Vector2i where the mouse button was pressed down.
SUB InputManager_GetMouseButtonDownPosition (button AS LONG, position AS Vector2i)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    position = __InputManager_MouseButtonState(button).downPosition
END SUB

''' @brief Gets the position where the mouse button was released.
''' @param button The mouse button to check.
''' @param position The x and y position in a Vector2i where the mouse button was released.
SUB InputManager_GetMouseButtonUpPosition (button AS LONG, position AS Vector2i)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    position = __InputManager_MouseButtonState(button).upPosition
END SUB

''' @brief Return true if a mouse button was pressed since the last update.
''' @return True if the mouse button was pressed.
FUNCTION InputManager_WasMouseButtonPressed%% (button AS LONG)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    InputManager_WasMouseButtonPressed = __InputManager_MouseButtonState(button).wasPressed
END FUNCTION

''' @brief Return true if a mouse button was pressed since the last update and consumes the flag.
''' @return True if the mouse button was pressed.
FUNCTION InputManager_GetMouseButtonPressed%% (button AS LONG)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    InputManager_GetMouseButtonPressed = __InputManager_MouseButtonState(button).wasPressed
    __InputManager_MouseButtonState(button).wasPressed = _FALSE
END FUNCTION

''' @brief Return true if a mouse button was clicked since the last update.
''' @return True if the mouse button was clicked.
FUNCTION InputManager_WasMouseButtonClicked%% (button AS LONG)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    InputManager_WasMouseButtonClicked = __InputManager_MouseButtonState(button).wasClicked
END FUNCTION

''' @brief Return true if a mouse button was clicked since the last update and consumes the flag.
''' @return True if the mouse button was clicked.
FUNCTION InputManager_GetMouseButtonClicked%% (button AS LONG)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    InputManager_GetMouseButtonClicked = __InputManager_MouseButtonState(button).wasClicked
    __InputManager_MouseButtonState(button).wasClicked = _FALSE
END FUNCTION

''' @brief Gets the bounding box where a mouse button was pressed and released.
''' @param bounds The bounding box where the mouse button was pressed and released.
SUB InputManager_GetMouseButtonClickBounds (button AS LONG, bounds AS Bounds2i)
    SHARED __InputManager_MouseButtonState() AS __InputManager_MouseButtonState
    bounds = __InputManager_MouseButtonState(button).clickedBounds
END SUB

''' @brief Returns true if a window event is waiting to be processed.
''' @return True if a window event is waiting to be processed.
FUNCTION InputManager_HasWindowEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasWindowEvent = __InputManager.isWindowEvent
END FUNCTION

''' @brief Returns true if the window should close.
''' @return True if the window should close.
FUNCTION InputManager_WindowShouldClose%%
    SHARED __InputManager AS __InputManager
    InputManager_WindowShouldClose = __InputManager.win.shouldClose
END FUNCTION

''' @brief Sets the window should close flag.
''' @param shouldClose True if the window should close.
SUB InputManager_SetWindowShouldClose (shouldClose AS _BYTE)
    SHARED __InputManager AS __InputManager
    __InputManager.win.shouldClose = shouldClose
END SUB

''' @brief Returns true if the window was resized.
''' @return True if the window was resized.
FUNCTION InputManager_WasWindowResized%%
    SHARED __InputManager AS __InputManager
    InputManager_WasWindowResized = __InputManager.win.resized
END FUNCTION

''' @brief Return the new window width.
''' @return The new window width.
FUNCTION InputManager_GetWindowResizeWidth&
    SHARED __InputManager AS __InputManager
    InputManager_GetWindowResizeWidth = __InputManager.win.size.x
END FUNCTION

''' @brief Return the new window height.
''' @return The new window height.
FUNCTION InputManager_GetWindowResizeHeight&
    SHARED __InputManager AS __InputManager
    InputManager_GetWindowResizeHeight = __InputManager.win.size.y
END FUNCTION

''' @brief Gets the window size.
''' @param size The window size.
SUB InputManager_GetWindowResizeSize (size AS Vector2i)
    SHARED __InputManager AS __InputManager
    size = __InputManager.win.size
END SUB

''' @brief Returns true if a gamepad event is waiting to be processed.
''' @return True if a gamepad event is waiting to be processed.
FUNCTION InputManager_HasGamepadEvent%%
    SHARED __InputManager AS __InputManager
    InputManager_HasGamepadEvent = __InputManager.isGamepad1Event _ORELSE __InputManager.isGamepad2Event
END FUNCTION

''' @brief Returns true if a gamepad 1 event is waiting to be processed.
''' @return True if a gamepad 1 event is waiting to be processed.
FUNCTION InputManager_HasGamepad1Event%%
    SHARED __InputManager AS __InputManager
    InputManager_HasGamepad1Event = __InputManager.isGamepad1Event
END FUNCTION

''' @brief Returns true if a gamepad 2 event is waiting to be processed.
''' @return True if a gamepad 2 event is waiting to be processed.
FUNCTION InputManager_HasGamepad2Event%%
    SHARED __InputManager AS __InputManager
    InputManager_HasGamepad2Event = __InputManager.isGamepad2Event
END FUNCTION
