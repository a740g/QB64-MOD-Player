'-----------------------------------------------------------------------------------------------------------------------
' TUI - Immediate-Mode Text User Interface (IMTUI) for QB64-PE
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Math.bi'
'$INCLUDE:'Asc.bi'
'$INCLUDE:'Vector2f.bi'
'$INCLUDE:'Bounds2f.bi'
'$INCLUDE:'Input.bi'

' Text mode 16-color constants (compatible with SCREEN 0 and OPTION _EXPLICIT)
CONST TUI_COLOR_BLACK& = 0&
CONST TUI_COLOR_BLUE& = 1&
CONST TUI_COLOR_GREEN& = 2&
CONST TUI_COLOR_CYAN& = 3&
CONST TUI_COLOR_RED& = 4&
CONST TUI_COLOR_MAGENTA& = 5&
CONST TUI_COLOR_BROWN& = 6&
CONST TUI_COLOR_WHITE& = 7&
CONST TUI_COLOR_GRAY& = 8&
CONST TUI_COLOR_LIGHT_BLUE& = 9&
CONST TUI_COLOR_LIGHT_GREEN& = 10&
CONST TUI_COLOR_LIGHT_CYAN& = 11&
CONST TUI_COLOR_LIGHT_RED& = 12&
CONST TUI_COLOR_LIGHT_MAGENTA& = 13&
CONST TUI_COLOR_YELLOW& = 14&
CONST TUI_COLOR_BRIGHT_WHITE& = 15&

' Channel interaction actions
CONST TUI_CHANNEL_ACTION_NONE%% = 0%%
CONST TUI_CHANNEL_ACTION_MUTE%% = 1%%
CONST TUI_CHANNEL_ACTION_SOLO%% = 2%%

' Scrubbing rate-limit cool-off interval in seconds
CONST TUI_SCRUB_COOLOFF_SECS# = 0.08#

TYPE __TUI_Context
    initialized AS _BYTE
    inFrame AS _BYTE
    widgetCount AS LONG ' Current frame auto-incremented widget counter
    totalWidgets AS LONG ' Total interactive widgets from previous frame
    focusedId AS LONG ' Currently focused widget ID (1..totalWidgets)
    hotId AS LONG ' Currently hovered widget ID
    activeId AS LONG ' Widget currently being pressed or dragged
    mousePos AS Vector2f ' Current mouse position (character column/row)
    mousePressedL AS _BYTE ' Left mouse button pressed down this frame
    mouseClickedL AS _BYTE ' Left mouse button released (clicked) this frame
    mouseDownL AS _BYTE ' Left mouse button held down this frame
    mousePressedR AS _BYTE ' Right mouse button pressed down this frame
    mouseClickedR AS _BYTE ' Right mouse button released (clicked) this frame
    navNext AS _BYTE ' Advance focus (Tab, Gamepad RB)
    navPrev AS _BYTE ' Retreat focus (Shift+Tab, Gamepad LB)
    navConfirm AS _BYTE ' Trigger focused widget (Enter, Space, Gamepad A)
    navSolo AS _BYTE ' Trigger channel solo (S, Shift+Enter, Gamepad Y/X)
    hasNavFocus AS _BYTE ' True when keyboard/gamepad focus indicator is active
    lastScrubTime AS DOUBLE ' Uptime timestamp of last seek scrub
    prevMousePos AS Vector2f ' Previous frame mouse position
END TYPE

DIM __TUI AS __TUI_Context

''' @brief Starts a new Immediate-Mode TUI frame, polling input and updating focus state.
SUB TUI_Begin
    SHARED __TUI AS __TUI_Context

    __TUI.inFrame = _TRUE
    __TUI.widgetCount = 0
    __TUI.hotId = 0

    ' Poll mouse state: track press down, held state, and click release
    __TUI.mousePressedL = Input_GetMouseButtonPressed(MOUSE_BUTTON_LEFT)
    __TUI.mouseDownL = Input_IsMouseButtonDown(MOUSE_BUTTON_LEFT)
    __TUI.mouseClickedL = Input_GetMouseButtonClicked(MOUSE_BUTTON_LEFT)
    __TUI.mousePressedR = Input_GetMouseButtonPressed(MOUSE_BUTTON_RIGHT)
    __TUI.mouseClickedR = Input_GetMouseButtonClicked(MOUSE_BUTTON_RIGHT)

    __TUI.prevMousePos = __TUI.mousePos
    Input_GetMousePosition __TUI.mousePos

    ' If mouse moved or was clicked, prefer mouse over keyboard focus ring
    IF (INT(__TUI.mousePos.x) <> INT(__TUI.prevMousePos.x) _ORELSE INT(__TUI.mousePos.y) <> INT(__TUI.prevMousePos.y) _ORELSE __TUI.mousePressedL _ORELSE __TUI.mousePressedR) THEN
        __TUI.hasNavFocus = _FALSE
    END IF

    ' If mouse released and no click was registered this frame, clear active drag state
    IF NOT __TUI.mouseDownL _ANDALSO NOT __TUI.mouseClickedL THEN
        __TUI.activeId = 0
    END IF

    ' Poll navigation keys and gamepad controls without consuming prematurely
    DIM k AS LONG: k = Input_PeekKeyboardKey
    __TUI.navNext = _FALSE
    __TUI.navPrev = _FALSE

    IF k = KEY_TAB THEN
        Input_ConsumeKeyboardKey
        IF Input_IsShiftDown THEN
            __TUI.navPrev = _TRUE
        ELSE
            __TUI.navNext = _TRUE
        END IF
        __TUI.hasNavFocus = _TRUE
    ELSEIF Input_GetGamepadButtonPressed(GAMEPAD_BUTTON_RB, 1) THEN
        __TUI.navNext = _TRUE
        __TUI.hasNavFocus = _TRUE
    ELSEIF Input_GetGamepadButtonPressed(GAMEPAD_BUTTON_LB, 1) THEN
        __TUI.navPrev = _TRUE
        __TUI.hasNavFocus = _TRUE
    END IF

    ' Cycle focused widget
    IF __TUI.navNext THEN
        __TUI.focusedId = __TUI.focusedId + 1
        IF __TUI.totalWidgets > 0 _ANDALSO __TUI.focusedId > __TUI.totalWidgets THEN
            __TUI.focusedId = 1
        END IF
    ELSEIF __TUI.navPrev THEN
        __TUI.focusedId = __TUI.focusedId - 1
        IF __TUI.totalWidgets > 0 _ANDALSO __TUI.focusedId < 1 THEN
            __TUI.focusedId = __TUI.totalWidgets
        END IF
    END IF

    ' Action confirmations (only active when nav focus is engaged)
    __TUI.navConfirm = (__TUI.hasNavFocus _ANDALSO (k = KEY_ENTER _ORELSE k = KEY_SPACE)) _ORELSE Input_GetGamepadButtonPressed(GAMEPAD_BUTTON_A, 1)
    __TUI.navSolo = (__TUI.hasNavFocus _ANDALSO (k = KEY_UPPER_S _ORELSE k = KEY_LOWER_S _ORELSE (k = KEY_ENTER _ANDALSO Input_IsShiftDown))) _ORELSE Input_GetGamepadButtonPressed(GAMEPAD_BUTTON_Y, 1)
END SUB

''' @brief Ends the Immediate-Mode TUI frame, clamping focus and flushing state.
SUB TUI_End
    SHARED __TUI AS __TUI_Context

    __TUI.totalWidgets = __TUI.widgetCount
    IF __TUI.totalWidgets > 0 THEN
        __TUI.focusedId = _CLAMP(__TUI.focusedId, 1, __TUI.totalWidgets)
    ELSE
        __TUI.focusedId = 0
    END IF

    __TUI.inFrame = _FALSE
END SUB

''' @brief Renders a non-interactive colored text label.
''' @param x Character column.
''' @param y Character row.
''' @param text The text string to render.
''' @param fgColor Foreground color index.
''' @param bgColor Background color index.
SUB TUI_Label (x AS LONG, y AS LONG, text AS STRING, fgColor AS LONG, bgColor AS LONG)
    COLOR fgColor, bgColor
    _PRINTSTRING (x, y), text
END SUB

''' @brief Internal helper to render a 3-line tall 3D button box with VB-DOS directional lighting without drop shadows.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total button width in characters (including borders).
''' @param text The button caption text.
''' @param isSunken _TRUE if button is pressed or actively toggled, _FALSE if raised.
''' @param isFocused _TRUE to draw double-line border for focused button, _FALSE for single-line.
''' @param bgCol Background color index.
''' @param fgCol Caption text color index.
''' @param hiCol Highlight border color index (simulated top-left light).
''' @param loCol Shadow border color index (simulated bottom-right shadow).
SUB __TUI_DrawButton (x AS LONG, y AS LONG, w AS LONG, text AS STRING, isSunken AS _BYTE, isFocused AS _BYTE, bgCol AS LONG, fgCol AS LONG, hiCol AS LONG, loCol AS LONG)
    DIM innerW AS LONG: innerW = _MAX(1, w - 2)
    DIM padLen AS LONG: padLen = innerW - LEN(text)
    DIM lPad AS LONG, rPad AS LONG
    IF padLen > 0 THEN
        lPad = padLen \ 2
        rPad = padLen - lPad
    ELSE
        lPad = 0
        rPad = 0
    END IF

    ' In VB-DOS 1.0, interior label does not shift when pressed;
    ' the directional lighting inversion alone simulates depression.
    DIM faceStr AS STRING
    faceStr = SPACE$(lPad) + text + SPACE$(rPad)
    IF LEN(faceStr) > innerW THEN faceStr = MID$(faceStr, 1, innerW)

    ' Select line drawing characters: double-line if focused, single-line if non-focused
    DIM chTL AS LONG, chTR AS LONG, chBL AS LONG, chBR AS LONG, chH AS LONG, chV AS LONG
    IF isFocused THEN
        chTL = 201 ' Double top-left
        chTR = 187 ' Double top-right
        chBL = 200 ' Double bottom-left
        chBR = 188 ' Double bottom-right
        chH = 205 ' Double horizontal
        chV = 186 ' Double vertical
    ELSE
        chTL = 218 ' Single top-left
        chTR = 191 ' Single top-right
        chBL = 192 ' Single bottom-left
        chBR = 217 ' Single bottom-right
        chH = 196 ' Single horizontal
        chV = 179 ' Single vertical
    END IF

    DIM hLine AS STRING: hLine = STRING$(innerW, chH)

    ' In VB-DOS directional lighting:
    ' Raised: Top and Left are highlight (hiCol), Bottom and Right are shadow (loCol).
    ' Sunken: Top and Left are shadow (loCol), Bottom and Right are highlight (hiCol).
    DIM tlCol AS LONG, brCol AS LONG
    IF isSunken THEN
        tlCol = loCol: brCol = hiCol
    ELSE
        tlCol = hiCol: brCol = loCol
    END IF

    ' Line 1: Top border (top-left corner and horizontal line in tlCol, top-right corner in brCol)
    COLOR tlCol, bgCol
    _PRINTSTRING (x, y), CHR$(chTL) + hLine
    COLOR brCol, bgCol
    _PRINTSTRING (x + w - 1, y), CHR$(chTR)

    ' Line 2: Left border (tlCol), Button face text (fgCol), Right border (brCol)
    COLOR tlCol, bgCol
    _PRINTSTRING (x, y + 1), CHR$(chV)
    COLOR fgCol, bgCol
    _PRINTSTRING (x + 1, y + 1), faceStr
    COLOR brCol, bgCol
    _PRINTSTRING (x + w - 1, y + 1), CHR$(chV)

    ' Line 3: Bottom border (bottom-left corner in tlCol, horizontal line and bottom-right corner in brCol)
    COLOR tlCol, bgCol
    _PRINTSTRING (x, y + 2), CHR$(chBL)
    COLOR brCol, bgCol
    _PRINTSTRING (x + 1, y + 2), hLine + CHR$(chBR)
END SUB

''' @brief Renders an interactive 3-line tall VB-DOS style push button with optional disabled state.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total button width in characters (including borders).
''' @param text The button caption text.
''' @param isDisabled _TRUE to render grayed out and disable all mouse/keyboard interaction.
''' @return _TRUE if clicked by mouse release or confirmed via keyboard/controller, _FALSE otherwise.
FUNCTION TUI_ButtonEx%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING, isDisabled AS _BYTE)
    SHARED __TUI AS __TUI_Context

    IF isDisabled THEN
        __TUI_DrawButton x, y, w, text, _FALSE, _FALSE, TUI_COLOR_BLACK, TUI_COLOR_GRAY, TUI_COLOR_GRAY, TUI_COLOR_GRAY
        TUI_ButtonEx = _FALSE
        EXIT FUNCTION
    END IF

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM isClicked AS _BYTE: isClicked = _FALSE

    ' Hit detection across all 3 lines
    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 2.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        ' Mouse press down captures active state
        IF __TUI.mousePressedL THEN
            __TUI.activeId = thisId
            __TUI.focusedId = thisId
        END IF
    END IF

    ' If this button is active or hovered, clicking occurs on mouse release
    IF (__TUI.activeId = thisId _ANDALSO __TUI.mouseClickedL _ANDALSO isHovered) _ORELSE (isHovered _ANDALSO __TUI.mouseClickedL) THEN
        isClicked = _TRUE
        __TUI.activeId = 0
    END IF

    ' Keyboard / Controller focus confirmation
    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.navConfirm THEN
        isClicked = _TRUE
        Input_ConsumeKeyboardKey
    END IF

    ' Button is pressed (sunken) when held down by mouse while hovering, or during keyboard confirmation
    DIM isPressed AS _BYTE
    isPressed = ((__TUI.activeId = thisId _ANDALSO __TUI.mouseDownL _ANDALSO isHovered) _ORELSE (isFocused _ANDALSO __TUI.navConfirm))

    IF isPressed THEN
        __TUI_DrawButton x, y, w, text, _TRUE, isFocused, TUI_COLOR_BLUE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isHovered THEN
        __TUI_DrawButton x, y, w, text, _FALSE, isFocused, TUI_COLOR_CYAN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isFocused THEN
        __TUI_DrawButton x, y, w, text, _FALSE, _TRUE, TUI_COLOR_BLUE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSE
        __TUI_DrawButton x, y, w, text, _FALSE, _FALSE, TUI_COLOR_BLUE, TUI_COLOR_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    END IF

    TUI_ButtonEx = isClicked
END FUNCTION

''' @brief Renders an interactive 3-line tall VB-DOS style push button.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total button width in characters (including borders).
''' @param text The button caption text.
''' @return _TRUE if clicked by mouse release or confirmed via keyboard/controller, _FALSE otherwise.
FUNCTION TUI_Button%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING)
    TUI_Button = TUI_ButtonEx(x, y, w, text, _FALSE)
END FUNCTION

''' @brief Renders an interactive 3-line tall VB-DOS style toggle button with optional disabled state.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total button width in characters (including borders).
''' @param text The button caption text.
''' @param isToggled Current toggle state (_TRUE = active/sunken).
''' @param isDisabled _TRUE to render grayed out and disable interaction.
''' @return _TRUE if clicked/confirmed to toggle state.
FUNCTION TUI_ToggleButtonEx%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING, isToggled AS _BYTE, isDisabled AS _BYTE)
    SHARED __TUI AS __TUI_Context

    IF isDisabled THEN
        __TUI_DrawButton x, y, w, text, isToggled, _FALSE, TUI_COLOR_BLACK, TUI_COLOR_GRAY, TUI_COLOR_GRAY, TUI_COLOR_GRAY
        TUI_ToggleButtonEx = _FALSE
        EXIT FUNCTION
    END IF

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM isClicked AS _BYTE: isClicked = _FALSE

    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 2.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mousePressedL THEN
            __TUI.activeId = thisId
            __TUI.focusedId = thisId
        END IF
    END IF

    IF (__TUI.activeId = thisId _ANDALSO __TUI.mouseClickedL _ANDALSO isHovered) _ORELSE (isHovered _ANDALSO __TUI.mouseClickedL) THEN
        isClicked = _TRUE
        __TUI.activeId = 0
    END IF

    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.navConfirm THEN
        isClicked = _TRUE
        Input_ConsumeKeyboardKey
    END IF

    DIM isPressed AS _BYTE
    isPressed = ((__TUI.activeId = thisId _ANDALSO __TUI.mouseDownL _ANDALSO isHovered) _ORELSE (isFocused _ANDALSO __TUI.navConfirm))
    DIM showSunken AS _BYTE: showSunken = isPressed _ORELSE isToggled

    IF isPressed THEN
        __TUI_DrawButton x, y, w, text, _TRUE, isFocused, TUI_COLOR_CYAN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isHovered THEN
        __TUI_DrawButton x, y, w, text, showSunken, isFocused, TUI_COLOR_CYAN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isToggled THEN
        __TUI_DrawButton x, y, w, text, _TRUE, isFocused, TUI_COLOR_GREEN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isFocused THEN
        __TUI_DrawButton x, y, w, text, _FALSE, _TRUE, TUI_COLOR_BLUE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSE
        __TUI_DrawButton x, y, w, text, _FALSE, _FALSE, TUI_COLOR_BLUE, TUI_COLOR_GRAY, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    END IF

    TUI_ToggleButtonEx = isClicked
END FUNCTION

''' @brief Renders an interactive 3-line tall VB-DOS style toggle button with raised/sunken state.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total button width in characters (including borders).
''' @param text The button caption text.
''' @param isToggled Current toggle state (_TRUE = active/sunken).
''' @return _TRUE if clicked/confirmed to toggle state.
FUNCTION TUI_ToggleButton%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING, isToggled AS _BYTE)
    TUI_ToggleButton = TUI_ToggleButtonEx(x, y, w, text, isToggled, _FALSE)
END FUNCTION

''' @brief Renders an interactive channel badge with live Mute and Solo indicators.
''' @param x Character column.
''' @param y Character row.
''' @param ch Channel index (0-based).
''' @param badgeText Channel subtype badge text (e.g. "PCM", "AM ", "FMm", "FMd").
''' @param isMuted Whether the channel is currently muted.
''' @param isSoloed Whether the channel is currently soloed.
''' @param outAction Output action code: TUI_CHANNEL_ACTION_NONE, TUI_CHANNEL_ACTION_MUTE, or TUI_CHANNEL_ACTION_SOLO.
''' @return _TRUE if an action occurred, _FALSE otherwise.
FUNCTION TUI_ChannelBadge%% (x AS LONG, y AS LONG, ch AS LONG, badgeText AS STRING, isMuted AS _BYTE, isSoloed AS _BYTE, outAction AS _BYTE)
    SHARED __TUI AS __TUI_Context

    outAction = TUI_CHANNEL_ACTION_NONE
    IF ch < 0 THEN EXIT FUNCTION

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM w AS LONG: w = 4 ' fixed 4 character cell width: "[AM]" or " PCM"

    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 0.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mouseClickedL THEN
            __TUI.activeId = thisId
            outAction = TUI_CHANNEL_ACTION_MUTE
        ELSEIF __TUI.mouseClickedR THEN
            outAction = TUI_CHANNEL_ACTION_SOLO
        END IF
    END IF

    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.hasNavFocus THEN
        IF __TUI.navSolo THEN
            outAction = TUI_CHANNEL_ACTION_SOLO
            Input_ConsumeKeyboardKey
        ELSEIF __TUI.navConfirm THEN
            outAction = TUI_CHANNEL_ACTION_MUTE
            Input_ConsumeKeyboardKey
        END IF
    END IF

    ' Display text formatting
    DIM dispText AS STRING
    IF isSoloed THEN
        dispText = "[SLO]"
    ELSEIF isMuted THEN
        dispText = "[MUT]"
    ELSE
        dispText = " " + RTRIM$(LTRIM$(badgeText)) + " "
        IF LEN(dispText) < 4 THEN dispText = dispText + SPACE$(4 - LEN(dispText))
    END IF

    ' Visual colors
    IF isSoloed THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_LIGHT_MAGENTA
    ELSEIF isMuted THEN
        COLOR TUI_COLOR_LIGHT_RED, TUI_COLOR_BLACK
    ELSEIF isHovered THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
    ELSEIF isFocused _ANDALSO __TUI.hasNavFocus THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_MAGENTA
    ELSE
        SELECT CASE RTRIM$(LTRIM$(badgeText))
            CASE "AM"
                COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
            CASE "FMm"
                COLOR TUI_COLOR_LIGHT_MAGENTA, TUI_COLOR_BLACK
            CASE "FMd"
                COLOR TUI_COLOR_LIGHT_RED, TUI_COLOR_BLACK
            CASE ELSE
                COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
        END SELECT
    END IF

    _PRINTSTRING (x, y), dispText

    TUI_ChannelBadge = (outAction <> TUI_CHANNEL_ACTION_NONE)
END FUNCTION

''' @brief Renders an interactive song order / row progress bar with real-time scrub & cool-off.
''' @param x Character column.
''' @param y Character row.
''' @param w Total bar width in characters including brackets.
''' @param curVal Current value.
''' @param maxVal Maximum value.
''' @return Target position if clicked, dragged, or nudged; or -1 if no interaction occurred.
FUNCTION TUI_ProgressBar& (x AS LONG, y AS LONG, w AS LONG, curVal AS LONG, maxVal AS LONG)
    SHARED __TUI AS __TUI_Context

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM targetVal AS LONG: targetVal = -1&

    DIM innerW AS LONG: innerW = _MAX(1, w - 2)

    ' Hit detection
    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 0.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mouseClickedL THEN
            __TUI.activeId = thisId
        END IF
    END IF

    ' Mouse drag / click scrubbing
    IF __TUI.activeId = thisId _ANDALSO __TUI.mouseDownL THEN
        DIM colFrac AS SINGLE
        colFrac = (INT(__TUI.mousePos.x) - (x + 1)) / CSNG(_MAX(1, innerW - 1))
        colFrac = _CLAMP(colFrac, 0!, 1!)
        DIM candidateVal AS LONG: candidateVal = CLNG(colFrac * maxVal)

        DIM nowUptime AS DOUBLE: nowUptime = _UPTIME
        IF nowUptime - __TUI.lastScrubTime >= TUI_SCRUB_COOLOFF_SECS# _ORELSE __TUI.mouseClickedL THEN
            __TUI.lastScrubTime = nowUptime
            targetVal = candidateVal
        END IF
    END IF

    ' Keyboard focus navigation (Left/Right arrow nudge)
    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.hasNavFocus THEN
        IF Input_NavLeft THEN
            targetVal = _MAX(0, curVal - 1)
            Input_ConsumeKeyboardKey
        ELSEIF Input_NavRight THEN
            targetVal = _MIN(maxVal, curVal + 1)
            Input_ConsumeKeyboardKey
        END IF
    END IF

    ' Rendering
    DIM filledChars AS LONG
    IF maxVal > 0 THEN
        filledChars = _CLAMP(CLNG((CSNG(curVal) / CSNG(maxVal)) * innerW), 0, innerW)
    ELSE
        filledChars = 0
    END IF

    DIM barStr AS STRING
    barStr = "[" + STRING$(filledChars, "=") + STRING$(innerW - filledChars, "-") + "]"

    IF isFocused _ANDALSO __TUI.hasNavFocus THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_MAGENTA
    ELSEIF isHovered _ORELSE __TUI.activeId = thisId THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
    ELSE
        COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
    END IF

    _PRINTSTRING (x, y), barStr

    TUI_ProgressBar = targetVal
END FUNCTION

''' @brief Renders an interactive master volume slider.
''' @param x Character column.
''' @param y Character row.
''' @param w Width of slider bar in characters.
''' @param curVal Current single-precision value.
''' @param minVal Minimum allowed value.
''' @param maxVal Maximum allowed value.
''' @param label Text prefix label (e.g. "VOL").
''' @return Updated value if changed, or curVal if unchanged.
FUNCTION TUI_Slider! (x AS LONG, y AS LONG, w AS LONG, curVal AS SINGLE, minVal AS SINGLE, maxVal AS SINGLE, label AS STRING)
    SHARED __TUI AS __TUI_Context

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM updatedVal AS SINGLE: updatedVal = curVal

    DIM labelLen AS LONG: labelLen = LEN(label)
    DIM barStart AS LONG: barStart = x + labelLen + 1
    DIM innerW AS LONG: innerW = _MAX(1, w - 2)

    ' Entire slider bounding box
    DIM totalW AS LONG: totalW = labelLen + 1 + w + 5 ' includes percentage display
    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + totalW - 0.001!, y + 0.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mouseClickedL THEN
            __TUI.activeId = thisId
        END IF
    END IF

    IF __TUI.activeId = thisId _ANDALSO __TUI.mouseDownL THEN
        DIM ratio AS SINGLE
        ratio = (INT(__TUI.mousePos.x) - (barStart + 1)) / CSNG(_MAX(1, innerW - 1))
        ratio = _CLAMP(ratio, 0!, 1!)
        updatedVal = minVal + ratio * (maxVal - minVal)
    END IF

    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.hasNavFocus THEN
        DIM stepSize AS SINGLE: stepSize = (maxVal - minVal) * 0.05!
        IF Input_NavLeft THEN
            updatedVal = _CLAMP(curVal - stepSize, minVal, maxVal)
            Input_ConsumeKeyboardKey
        ELSEIF Input_NavRight THEN
            updatedVal = _CLAMP(curVal + stepSize, minVal, maxVal)
            Input_ConsumeKeyboardKey
        END IF
    END IF

    ' Rendering
    DIM range AS SINGLE: range = _MAX(0.0001!, maxVal - minVal)
    DIM normVal AS SINGLE: normVal = _CLAMP((updatedVal - minVal) / range, 0!, 1!)
    DIM filledChars AS LONG: filledChars = _CLAMP(CLNG(normVal * innerW), 0, innerW)

    DIM percentStr AS STRING: percentStr = STR$(CLNG(normVal * 100!)) + "%"
    percentStr = SPACE$(4 - LEN(percentStr)) + percentStr

    DIM sliderStr AS STRING
    sliderStr = label + " [" + STRING$(filledChars, "=") + STRING$(innerW - filledChars, "-") + "]" + percentStr

    IF isFocused _ANDALSO __TUI.hasNavFocus THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_MAGENTA
    ELSEIF isHovered _ORELSE __TUI.activeId = thisId THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
    ELSE
        COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
    END IF

    _PRINTSTRING (x, y), sliderStr

    TUI_Slider = updatedVal
END FUNCTION

''' @brief Renders a bordered panel container with optional title, border style, and opacity.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total panel width in characters.
''' @param h Total panel height in characters.
''' @param title Optional title string embedded in top border.
''' @param isDoubleBorder _TRUE for double-line border, _FALSE for single-line.
''' @param isOpaque _TRUE to fill interior with background spaces, _FALSE for transparent.
SUB TUI_PanelEx (x AS LONG, y AS LONG, w AS LONG, h AS LONG, title AS STRING, isDoubleBorder AS _BYTE, isOpaque AS _BYTE)
    IF w < 2 _ORELSE h < 2 THEN EXIT SUB

    DIM innerW AS LONG: innerW = w - 2
    DIM innerH AS LONG: innerH = h - 2

    DIM chTL AS LONG, chTR AS LONG, chBL AS LONG, chBR AS LONG, chH AS LONG, chV AS LONG
    IF isDoubleBorder THEN
        chTL = 201: chTR = 187: chBL = 200: chBR = 188: chH = 205: chV = 186
    ELSE
        chTL = 218: chTR = 191: chBL = 192: chBR = 217: chH = 196: chV = 179
    END IF

    DIM topBar AS STRING
    IF LEN(title) > 0 _ANDALSO innerW > LEN(title) + 2 THEN
        DIM tStr AS STRING: tStr = " " + title + " "
        DIM rLen AS LONG: rLen = innerW - 1 - LEN(tStr)
        topBar = CHR$(chH) + tStr + STRING$(rLen, chH)
    ELSE
        topBar = STRING$(innerW, chH)
    END IF

    DIM botBar AS STRING: botBar = STRING$(innerW, chH)
    DIM vChar AS STRING: vChar = CHR$(chV)
    DIM fillStr AS STRING
    IF isOpaque THEN fillStr = SPACE$(innerW)

    ' Top border
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (x, y), CHR$(chTL) + topBar
    COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
    _PRINTSTRING (x + w - 1, y), CHR$(chTR)

    ' Side borders and interior
    DIM row AS LONG
    FOR row = 1 TO innerH
        IF isOpaque THEN
            COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
            _PRINTSTRING (x, y + row), vChar + fillStr
        ELSE
            COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
            _PRINTSTRING (x, y + row), vChar
        END IF
        COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
        _PRINTSTRING (x + w - 1, y + row), vChar
    NEXT row

    ' Bottom border
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (x, y + h - 1), CHR$(chBL)
    COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
    _PRINTSTRING (x + 1, y + h - 1), botBar + CHR$(chBR)
END SUB

''' @brief Renders a bordered panel container with optional title and border style (opaque by default).
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total panel width in characters.
''' @param h Total panel height in characters.
''' @param title Optional title string embedded in top border.
''' @param isDoubleBorder _TRUE for double-line border, _FALSE for single-line.
SUB TUI_Panel (x AS LONG, y AS LONG, w AS LONG, h AS LONG, title AS STRING, isDoubleBorder AS _BYTE)
    TUI_PanelEx x, y, w, h, title, isDoubleBorder, _TRUE
END SUB

''' @brief Renders a 3D tab bar where clicking or activating a tab selects it, with focus & disabled support.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param tabCaptions() Array of tab caption strings.
''' @param tabCount Number of tabs in tabCaptions().
''' @param selectedIdx In/Out: 1-based index of currently selected tab.
''' @param isDisabled _TRUE to render all tabs grayed out and non-interactive.
''' @return _TRUE if tab selection changed this frame, _FALSE otherwise.
FUNCTION TUI_TabBarEx%% (x AS LONG, y AS LONG, tabCaptions() AS STRING, tabCount AS LONG, selectedIdx AS LONG, isDisabled AS _BYTE)
    SHARED __TUI AS __TUI_Context

    DIM changed AS _BYTE: changed = _FALSE
    DIM curX AS LONG: curX = x

    DIM i AS LONG
    FOR i = 1 TO tabCount
        DIM tabText AS STRING: tabText = tabCaptions(i)
        DIM tabW AS LONG: tabW = LEN(tabText) + 4
        DIM isSelected AS _BYTE: isSelected = (i = selectedIdx)

        IF isDisabled THEN
            ' Render disabled tab (flat single-line border in dark gray, gray text on black)
            DIM hLineDis AS STRING: hLineDis = STRING$(tabW - 2, 196)
            COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
            _PRINTSTRING (curX, y), CHR$(218) + hLineDis + CHR$(191)
            _PRINTSTRING (curX, y + 1), CHR$(179) + " " + tabText + " " + CHR$(179)
        ELSE
            __TUI.widgetCount = __TUI.widgetCount + 1
            DIM thisId AS LONG: thisId = __TUI.widgetCount

            DIM b AS Bounds2f
            Bounds2f_Set curX, y, curX + tabW - 0.001!, y + 1.999!, b
            DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

            IF isHovered THEN
                __TUI.hotId = thisId
                IF __TUI.mousePressedL THEN
                    __TUI.activeId = thisId
                    __TUI.focusedId = thisId
                END IF
            END IF

            IF (__TUI.activeId = thisId _ANDALSO __TUI.mouseClickedL _ANDALSO isHovered) _ORELSE (isHovered _ANDALSO __TUI.mouseClickedL) THEN
                IF selectedIdx <> i THEN
                    selectedIdx = i
                    changed = _TRUE
                END IF
                __TUI.activeId = 0
            END IF

            DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
            IF isFocused _ANDALSO __TUI.navConfirm THEN
                IF selectedIdx <> i THEN
                    selectedIdx = i
                    changed = _TRUE
                END IF
                Input_ConsumeKeyboardKey
            END IF

            ' Line characters: double-line if focused, single-line if non-focused
            DIM chTL AS LONG, chTR AS LONG, chH AS LONG, chV AS LONG
            IF isFocused THEN
                chTL = 201: chTR = 187: chH = 205: chV = 186
            ELSE
                chTL = 218: chTR = 191: chH = 196: chV = 179
            END IF

            DIM hLine AS STRING: hLine = STRING$(tabW - 2, chH)

            ' Visual rendering of tab
            IF isSelected THEN
                IF isFocused THEN
                    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLUE
                    _PRINTSTRING (curX, y), CHR$(chTL) + hLine + CHR$(chTR)
                    _PRINTSTRING (curX, y + 1), CHR$(chV) + " " + tabText + " " + CHR$(chV)
                ELSE
                    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLUE
                    _PRINTSTRING (curX, y), CHR$(chTL) + hLine + CHR$(chTR)
                    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLUE
                    _PRINTSTRING (curX, y + 1), CHR$(chV) + " " + tabText + " " + CHR$(chV)
                END IF
            ELSEIF isHovered THEN
                COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
                _PRINTSTRING (curX, y), CHR$(chTL) + hLine + CHR$(chTR)
                _PRINTSTRING (curX, y + 1), CHR$(chV) + " " + tabText + " " + CHR$(chV)
            ELSEIF isFocused THEN
                COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
                _PRINTSTRING (curX, y), CHR$(chTL) + hLine + CHR$(chTR)
                _PRINTSTRING (curX, y + 1), CHR$(chV) + " " + tabText + " " + CHR$(chV)
            ELSE
                COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
                _PRINTSTRING (curX, y), CHR$(chTL) + hLine + CHR$(chTR)
                COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
                _PRINTSTRING (curX, y + 1), CHR$(chV) + " " + tabText + " " + CHR$(chV)
            END IF
        END IF

        curX = curX + tabW + 1
    NEXT i

    TUI_TabBarEx = changed
END FUNCTION

''' @brief Renders a 3D tab bar where clicking or activating a tab selects it.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param tabCaptions() Array of tab caption strings.
''' @param tabCount Number of tabs in tabCaptions().
''' @param selectedIdx In/Out: 1-based index of currently selected tab.
''' @return _TRUE if tab selection changed this frame, _FALSE otherwise.
FUNCTION TUI_TabBar%% (x AS LONG, y AS LONG, tabCaptions() AS STRING, tabCount AS LONG, selectedIdx AS LONG)
    TUI_TabBar = TUI_TabBarEx(x, y, tabCaptions(), tabCount, selectedIdx, _FALSE)
END FUNCTION

''' @brief Renders a vertical 1-column VU meter with peak indicator dot.
''' @param x Character column.
''' @param y Character row of top of meter.
''' @param h Total height in characters.
''' @param level Normalized volume level (0.0 to 1.0).
''' @param peak Normalized peak level (0.0 to 1.0).
''' @param isMuted _TRUE if channel is muted (renders in gray).
SUB TUI_VUMeter (x AS LONG, y AS LONG, h AS LONG, level AS SINGLE, peak AS SINGLE, isMuted AS _BYTE)
    IF h < 1 THEN EXIT SUB

    DIM nLevel AS SINGLE: nLevel = _CLAMP(level, 0!, 1!)
    DIM nPeak AS SINGLE: nPeak = _CLAMP(peak, 0!, 1!)

    DIM filledRows AS LONG: filledRows = _CLAMP(CLNG(nLevel * h), 0, h)
    DIM peakRow AS LONG: peakRow = _CLAMP(CLNG(nPeak * (h - 1)), 0, h - 1)

    DIM r AS LONG
    FOR r = 0 TO h - 1
        DIM rowFromBot AS LONG: rowFromBot = h - 1 - r
        DIM drawY AS LONG: drawY = y + r

        ' Color graduation: lower 60% green, middle 25% yellow, top 15% red
        DIM fgCol AS LONG
        IF isMuted THEN
            fgCol = TUI_COLOR_GRAY
        ELSEIF r < CLNG(h * 0.15!) THEN
            fgCol = TUI_COLOR_LIGHT_RED
        ELSEIF r < CLNG(h * 0.40!) THEN
            fgCol = TUI_COLOR_YELLOW
        ELSE
            fgCol = TUI_COLOR_LIGHT_GREEN
        END IF

        COLOR fgCol, TUI_COLOR_BLACK

        IF rowFromBot < filledRows THEN
            _PRINTSTRING (x, drawY), CHR$(219) ' solid block
        ELSEIF rowFromBot = peakRow _ANDALSO nPeak > 0.05! THEN
            _PRINTSTRING (x, drawY), CHR$(223) ' top half block peak dot
        ELSE
            COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
            _PRINTSTRING (x, drawY), CHR$(250) ' inactive dot
        END IF
    NEXT r
END SUB

''' @brief Renders a scrollable selection list with item hover, selection, and scrollbar.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total list width in characters.
''' @param h Total visible lines.
''' @param items() Array of string items.
''' @param totalItems Number of valid items in items().
''' @param selectedIdx In/Out: 1-based index of currently selected item.
''' @param scrollOffset In/Out: 1-based index of top visible item.
''' @return 1-based index of item activated by mouse click, or 0 if none.
FUNCTION TUI_ScrollList& (x AS LONG, y AS LONG, w AS LONG, h AS LONG, items() AS STRING, totalItems AS LONG, selectedIdx AS LONG, scrollOffset AS LONG)
    SHARED __TUI AS __TUI_Context

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM itemActivated AS LONG: itemActivated = 0

    IF h < 1 _ORELSE w < 3 THEN EXIT FUNCTION

    DIM maxScroll AS LONG: maxScroll = _MAX(1, totalItems - h + 1)
    scrollOffset = _CLAMP(scrollOffset, 1, maxScroll)

    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + h - 0.001!, b
    DIM isListHovered AS _BYTE: isListHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isListHovered THEN
        __TUI.hotId = thisId
        ' Mouse wheel scrolls the list
        DIM wheel AS SINGLE: wheel = Input_GetMouseScrollWheelValue
        IF wheel <> 0! THEN
            scrollOffset = _CLAMP(scrollOffset - CLNG(wheel * 3!), 1, maxScroll)
        END IF
    END IF

    DIM textW AS LONG: textW = w - 2 ' leave 1 column for border/scrollbar, 1 for padding

    ' Draw items
    DIM r AS LONG
    FOR r = 0 TO h - 1
        DIM itemIdx AS LONG: itemIdx = scrollOffset + r
        DIM drawY AS LONG: drawY = y + r

        IF itemIdx <= totalItems THEN
            DIM itemStr AS STRING: itemStr = items(itemIdx)
            IF LEN(itemStr) > textW THEN
                itemStr = MID$(itemStr, 1, textW)
            ELSE
                itemStr = itemStr + SPACE$(textW - LEN(itemStr))
            END IF

            DIM isSelected AS _BYTE: isSelected = (itemIdx = selectedIdx)
            DIM rowBounds AS Bounds2f
            Bounds2f_Set x, drawY, x + textW - 0.001!, drawY + 0.999!, rowBounds
            DIM isRowHovered AS _BYTE: isRowHovered = Bounds2f_ContainsPoint(rowBounds, __TUI.mousePos)

            IF isRowHovered _ANDALSO __TUI.mouseClickedL THEN
                selectedIdx = itemIdx
                itemActivated = itemIdx
            END IF

            IF isSelected THEN
                COLOR TUI_COLOR_BLACK, TUI_COLOR_WHITE
            ELSEIF isRowHovered THEN
                COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
            ELSE
                COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
            END IF

            _PRINTSTRING (x, drawY), itemStr
        ELSE
            COLOR TUI_COLOR_BLACK, TUI_COLOR_BLACK
            _PRINTSTRING (x, drawY), SPACE$(textW)
        END IF

        ' Right border / scrollbar indicator
        COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
        IF r = 0 THEN
            _PRINTSTRING (x + w - 1, drawY), CHR$(30) ' Up arrow
        ELSEIF r = h - 1 THEN
            _PRINTSTRING (x + w - 1, drawY), CHR$(31) ' Down arrow
        ELSE
            ' Scroll thumb position
            DIM thumbPos AS LONG
            IF totalItems > h THEN
                thumbPos = 1 + CLNG(((scrollOffset - 1) / CSNG(maxScroll - 1)) * (h - 3))
            ELSE
                thumbPos = -1
            END IF
            IF r = thumbPos THEN
                COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
                _PRINTSTRING (x + w - 1, drawY), CHR$(219) ' Scroll thumb
            ELSE
                COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
                _PRINTSTRING (x + w - 1, drawY), CHR$(179) ' Scroll track
            END IF
        END IF
    NEXT r

    TUI_ScrollList = itemActivated
END FUNCTION
