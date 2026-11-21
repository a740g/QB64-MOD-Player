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
    widgetCount AS LONG                 ' Current frame auto-incremented widget counter
    totalWidgets AS LONG                ' Total interactive widgets from previous frame
    focusedId AS LONG                   ' Currently focused widget ID (1..totalWidgets)
    hotId AS LONG                       ' Currently hovered widget ID
    activeId AS LONG                    ' Widget currently being pressed or dragged
    mousePos AS Vector2f                ' Current mouse position (character column/row)
    mouseClickedL AS _BYTE              ' Left mouse button clicked this frame
    mouseDownL AS _BYTE                 ' Left mouse button held down this frame
    mouseClickedR AS _BYTE              ' Right mouse button clicked this frame
    navNext AS _BYTE                    ' Advance focus (Tab, Gamepad RB)
    navPrev AS _BYTE                    ' Retreat focus (Shift+Tab, Gamepad LB)
    navConfirm AS _BYTE                 ' Trigger focused widget (Enter, Space, Gamepad A)
    navSolo AS _BYTE                    ' Trigger channel solo (S, Shift+Enter, Gamepad Y/X)
    hasNavFocus AS _BYTE                ' True when keyboard/gamepad focus indicator is active
    lastScrubTime AS DOUBLE             ' Uptime timestamp of last seek scrub
    prevMousePos AS Vector2f            ' Previous frame mouse position
END TYPE

DIM __TUI AS __TUI_Context

''' @brief Starts a new Immediate-Mode TUI frame, polling input and updating focus state.
SUB TUI_Begin
    SHARED __TUI AS __TUI_Context

    __TUI.inFrame = _TRUE
    __TUI.widgetCount = 0
    __TUI.hotId = 0

    ' Poll mouse state
    __TUI.mouseClickedL = Input_GetMouseButtonClicked(MOUSE_BUTTON_LEFT)
    __TUI.mouseDownL = Input_IsMouseButtonDown(MOUSE_BUTTON_LEFT)
    __TUI.mouseClickedR = Input_GetMouseButtonClicked(MOUSE_BUTTON_RIGHT)

    __TUI.prevMousePos = __TUI.mousePos
    Input_GetMousePosition __TUI.mousePos

    ' If mouse moved or was clicked, prefer mouse over keyboard focus ring
    IF (INT(__TUI.mousePos.x) <> INT(__TUI.prevMousePos.x) _ORELSE INT(__TUI.mousePos.y) <> INT(__TUI.prevMousePos.y) _ORELSE __TUI.mouseClickedL _ORELSE __TUI.mouseClickedR) THEN
        __TUI.hasNavFocus = _FALSE
    END IF

    ' If mouse released, clear active drag state
    IF NOT __TUI.mouseDownL THEN
        __TUI.activeId = 0
    END IF

    ' Poll navigation keys and gamepad controls
    DIM k AS LONG: k = Input_GetKeyboardKey
    __TUI.navNext = _FALSE
    __TUI.navPrev = _FALSE

    IF k = KEY_TAB THEN
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

    ' Action confirmations
    __TUI.navConfirm = (k = KEY_ENTER _ORELSE k = KEY_SPACE _ORELSE Input_GetGamepadButtonPressed(GAMEPAD_BUTTON_A, 1))
    __TUI.navSolo = (k = KEY_UPPER_S _ORELSE k = KEY_LOWER_S _ORELSE (k = KEY_ENTER _ANDALSO Input_IsShiftDown) _ORELSE Input_GetGamepadButtonPressed(GAMEPAD_BUTTON_Y, 1))
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

''' @brief Renders an interactive push button.
''' @param x Character column.
''' @param y Character row.
''' @param text The button text (e.g. "[Prev]").
''' @return _TRUE if clicked by mouse or confirmed via keyboard/controller, _FALSE otherwise.
FUNCTION TUI_Button%% (x AS LONG, y AS LONG, text AS STRING)
    SHARED __TUI AS __TUI_Context

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM w AS LONG: w = LEN(text)
    DIM isClicked AS _BYTE: isClicked = _FALSE

    ' Hit detection
    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 0.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mouseClickedL THEN
            __TUI.activeId = thisId
            isClicked = _TRUE
        END IF
    END IF

    ' Focus & keyboard confirmation
    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.hasNavFocus _ANDALSO __TUI.navConfirm THEN
        isClicked = _TRUE
    END IF

    ' Visual rendering
    IF __TUI.activeId = thisId THEN
        COLOR TUI_COLOR_BLACK, TUI_COLOR_WHITE
    ELSEIF isHovered THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
    ELSEIF isFocused _ANDALSO __TUI.hasNavFocus THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_MAGENTA
    ELSE
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLUE
    END IF

    _PRINTSTRING (x, y), text

    TUI_Button = isClicked
END FUNCTION

''' @brief Renders an interactive toggle button with active/inactive visual styling.
''' @param x Character column.
''' @param y Character row.
''' @param text The button text.
''' @param isToggled Current toggle state (_TRUE = active/highlighted).
''' @return _TRUE if clicked/confirmed to toggle state.
FUNCTION TUI_ToggleButton%% (x AS LONG, y AS LONG, text AS STRING, isToggled AS _BYTE)
    SHARED __TUI AS __TUI_Context

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM w AS LONG: w = LEN(text)
    DIM isClicked AS _BYTE: isClicked = _FALSE

    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 0.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mouseClickedL THEN
            __TUI.activeId = thisId
            isClicked = _TRUE
        END IF
    END IF

    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.hasNavFocus _ANDALSO __TUI.navConfirm THEN
        isClicked = _TRUE
    END IF

    IF __TUI.activeId = thisId THEN
        COLOR TUI_COLOR_BLACK, TUI_COLOR_WHITE
    ELSEIF isHovered THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
    ELSEIF isFocused _ANDALSO __TUI.hasNavFocus THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_MAGENTA
    ELSEIF isToggled THEN
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GREEN
    ELSE
        COLOR TUI_COLOR_GRAY, TUI_COLOR_BLUE
    END IF

    _PRINTSTRING (x, y), text

    TUI_ToggleButton = isClicked
END FUNCTION

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
SUB __TUI_DrawButton3D (x AS LONG, y AS LONG, w AS LONG, text AS STRING, isSunken AS _BYTE, isFocused AS _BYTE, bgCol AS LONG, fgCol AS LONG, hiCol AS LONG, loCol AS LONG)
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
        chH = 205  ' Double horizontal
        chV = 186  ' Double vertical
    ELSE
        chTL = 218 ' Single top-left
        chTR = 191 ' Single top-right
        chBL = 192 ' Single bottom-left
        chBR = 217 ' Single bottom-right
        chH = 196  ' Single horizontal
        chV = 179  ' Single vertical
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

''' @brief Renders a 3-line tall VB-DOS style 3D beveled push button using directional lighting.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total button width in characters (including borders).
''' @param text The button caption text.
''' @return _TRUE if clicked by mouse or confirmed via keyboard/controller, _FALSE otherwise.
FUNCTION TUI_Button3D%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING)
    SHARED __TUI AS __TUI_Context

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM isClicked AS _BYTE: isClicked = _FALSE

    ' Hit detection across all 3 lines
    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 2.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mouseClickedL THEN
            __TUI.activeId = thisId
            __TUI.focusedId = thisId
            isClicked = _TRUE
        END IF
    END IF

    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.navConfirm THEN
        isClicked = _TRUE
    END IF

    DIM isPressed AS _BYTE: isPressed = (__TUI.activeId = thisId _ANDALSO __TUI.mouseDownL)

    IF isPressed THEN
        __TUI_DrawButton3D x, y, w, text, _TRUE, isFocused, TUI_COLOR_BLUE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isHovered THEN
        __TUI_DrawButton3D x, y, w, text, _FALSE, isFocused, TUI_COLOR_CYAN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isFocused THEN
        __TUI_DrawButton3D x, y, w, text, _FALSE, _TRUE, TUI_COLOR_BLUE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSE
        __TUI_DrawButton3D x, y, w, text, _FALSE, _FALSE, TUI_COLOR_BLUE, TUI_COLOR_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    END IF

    TUI_Button3D = isClicked
END FUNCTION

''' @brief Renders a 3-line tall VB-DOS style 3D toggle button with raised/sunken state.
''' @param x Character column of top-left corner.
''' @param y Character row of top-left corner.
''' @param w Total button width in characters (including borders).
''' @param text The button caption text.
''' @param isToggled Current toggle state (_TRUE = active/sunken).
''' @return _TRUE if clicked/confirmed to toggle state.
FUNCTION TUI_ToggleButton3D%% (x AS LONG, y AS LONG, w AS LONG, text AS STRING, isToggled AS _BYTE)
    SHARED __TUI AS __TUI_Context

    __TUI.widgetCount = __TUI.widgetCount + 1
    DIM thisId AS LONG: thisId = __TUI.widgetCount
    DIM isClicked AS _BYTE: isClicked = _FALSE

    DIM b AS Bounds2f
    Bounds2f_Set x, y, x + w - 0.001!, y + 2.999!, b
    DIM isHovered AS _BYTE: isHovered = Bounds2f_ContainsPoint(b, __TUI.mousePos)

    IF isHovered THEN
        __TUI.hotId = thisId
        IF __TUI.mouseClickedL THEN
            __TUI.activeId = thisId
            __TUI.focusedId = thisId
            isClicked = _TRUE
        END IF
    END IF

    DIM isFocused AS _BYTE: isFocused = (__TUI.focusedId = thisId)
    IF isFocused _ANDALSO __TUI.navConfirm THEN
        isClicked = _TRUE
    END IF

    DIM isPressed AS _BYTE: isPressed = (__TUI.activeId = thisId _ANDALSO __TUI.mouseDownL)
    DIM showSunken AS _BYTE: showSunken = isPressed _ORELSE isToggled

    IF isPressed THEN
        __TUI_DrawButton3D x, y, w, text, _TRUE, isFocused, TUI_COLOR_CYAN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isHovered THEN
        __TUI_DrawButton3D x, y, w, text, showSunken, isFocused, TUI_COLOR_CYAN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isToggled THEN
        __TUI_DrawButton3D x, y, w, text, _TRUE, isFocused, TUI_COLOR_GREEN, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSEIF isFocused THEN
        __TUI_DrawButton3D x, y, w, text, _FALSE, _TRUE, TUI_COLOR_BLUE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    ELSE
        __TUI_DrawButton3D x, y, w, text, _FALSE, _FALSE, TUI_COLOR_BLUE, TUI_COLOR_GRAY, TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    END IF

    TUI_ToggleButton3D = isClicked
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
        ELSEIF __TUI.navConfirm THEN
            outAction = TUI_CHANNEL_ACTION_MUTE
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
        ELSEIF Input_NavRight THEN
            targetVal = _MIN(maxVal, curVal + 1)
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
        ELSEIF Input_NavRight THEN
            updatedVal = _CLAMP(curVal + stepSize, minVal, maxVal)
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
