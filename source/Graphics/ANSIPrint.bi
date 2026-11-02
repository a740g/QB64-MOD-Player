'-----------------------------------------------------------------------------------------------------------------------
' ANSI Escape Sequence Emulator
' Copyright (c) 2026 Samuel Gomes
'
' TODO:
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#screen-colors
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#window-title
'   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#soft-reset
'   https://github.com/a740g/ANSIPrint/blob/master/docs/ansimtech.txt
'   https://conemu.github.io/en/AnsiEscapeCodes.html
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'Graphics2D.bi'
'$INCLUDE:'../Resource/SAUCE.bi'
'$INCLUDE:'../Math/Vector2i.bi'

' ANSI constants
CONST ANSI_ESC_DECSC = 55 ' Save Cursor Position in Memory
CONST ANSI_ESC_DECSR = 56 ' Restore Cursor Position from Memory
CONST ANSI_ESC_CSI_CUU = 65 ' Cursor Up
CONST ANSI_ESC_CSI_CUD = 66 ' Cursor Down
CONST ANSI_ESC_CSI_CUF = 67 ' Cursor Forward/Right
CONST ANSI_ESC_CSI_CUB = 68 ' Cursor Back/Left
CONST ANSI_ESC_CSI_CNL = 69 ' Cursor Next Line
CONST ANSI_ESC_CSI_CPL = 70 ' Cursor Previous Line
CONST ANSI_ESC_CSI_CHA = 71 ' Cursor Horizontal Absolute
CONST ANSI_ESC_CSI_CUP = 72 ' Cursor Position
CONST ANSI_ESC_CSI_ED = 74 ' Erase in Display
CONST ANSI_ESC_CSI_EL = 75 ' Erase in Line
CONST ANSI_ESC_CSI_IL = 76 ' ANSI.SYS: Insert line
CONST ANSI_ESC_CSI_DL = 77 ' ANSI.SYS: Delete line
CONST ANSI_ESC_RI = 77 ' Reverse Index
CONST ANSI_ESC_SS2 = 78 ' Single Shift Two
CONST ANSI_ESC_SS3 = 79 ' Single Shift Three
CONST ANSI_ESC_DCS = 80 ' Device Control String
CONST ANSI_ESC_CSI_SU = 83 ' Scroll Up
CONST ANSI_ESC_CSI_SD = 84 ' Scroll Down
CONST ANSI_ESC_SOS = 88 ' Start of String
CONST ANSI_ESC_CSI = 91 ' Control Sequence Introducer
CONST ANSI_ESC_ST = 92 ' String Terminator
CONST ANSI_ESC_OSC = 93 ' Operating System Command
CONST ANSI_ESC_PM = 94 ' Privacy Message
CONST ANSI_ESC_APC = 95 ' Application Program Command
CONST ANSI_ESC_CSI_VPA = 100 ' Vertical Line Position Absolute
CONST ANSI_ESC_CSI_HVP = 102 ' Horizontal Vertical Position
CONST ANSI_ESC_CSI_SM = 104 ' ANSI.SYS: Set screen mode
CONST ANSI_ESC_CSI_RM = 108 ' ANSI.SYS: Reset screen mode
CONST ANSI_ESC_CSI_SGR = 109 ' Select Graphic Rendition
CONST ANSI_ESC_CSI_DSR = 110 ' Device status report
CONST ANSI_ESC_CSI_DECSCUSR = 113 ' Cursor Shape
CONST ANSI_ESC_CSI_SCP = 115 ' Save Current Cursor Position
CONST ANSI_ESC_CSI_PABLODRAW_24BPP = 116 ' PabloDraw 24-bit ANSI sequences
CONST ANSI_ESC_CSI_RCP = 117 ' Restore Saved Cursor Position
' Parser state
CONST __ANSI_STATE_TEXT = 0 ' when parsing regular text & control characters
CONST __ANSI_STATE_BEGIN = 1 ' when beginning an escape sequence
CONST __ANSI_STATE_SEQUENCE = 2 ' when parsing a control sequence introducer
CONST __ANSI_STATE_END = 3 ' when the end of the character stream has been reached
' Some defaults
CONST __ANSI_DEFAULT_COLOR_FOREGROUND = 7
CONST __ANSI_DEFAULT_COLOR_BACKGROUND = 0
CONST __ANSI_ARG_COUNT = 10 ' number of argument slots that we'll start with

TYPE __ANSIEmulatorType
    isInitialized AS LONG ' was the library initialized?
    state AS LONG ' the current parser state
    argIndex AS LONG ' the current CSI argument index & count; 0 means no arguments
    fC AS _UNSIGNED LONG ' foreground color
    bC AS _UNSIGNED LONG ' background color
    isBold AS LONG ' text attributes - high intensity bg color
    isBlink AS LONG ' text attributes - we make this high intensity as well
    isInvert AS LONG ' text attributes - inverted colors (fg <--> bg)
    posDEC AS Vector2i ' DEC saved cursor position
    posSCO AS Vector2i ' SCO saved cursor position
    lastChar AS _UNSIGNED _BYTE ' last character rendered
    lastCharX AS LONG ' the x position of the last "printed" character
    CPS AS LONG ' characters / second
END TYPE

DIM __ANSIEmu AS __ANSIEmulatorType ' emulator state
DIM __ANSIColorLUT(0 TO 255) AS BGRAType ' this table is used to get the RGB for legacy ANSI colors
REDIM __ANSIArg(1 TO __ANSI_ARG_COUNT) AS LONG ' CSI dynamic argument list

'-------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-------------------------------------------------------------------------------------------------------------------
'OPTION _EXPLICIT
'$DEBUG
'SCREEN _NEWIMAGE(8 * 80, 16 * 28, 32)
'SCREEN _NEWIMAGE(8 * 80, 16 * 28, 9)
'SCREEN _NEWIMAGE(8 * 80, 16 * 28, 12)
'SCREEN _NEWIMAGE(8 * 80, 16 * 28, 13)
'SCREEN _NEWIMAGE(80, 28, 0)
'_FONT 16

'DO
'    DIM ansFile AS STRING: ansFile = _OPENFILEDIALOG$("Open", "", "*.ans|*.asc|*.diz|*.nfo|*.txt", "ANSI Art Files")
'    IF NOT _FILEEXISTS(ansFile) THEN EXIT DO

'    DIM fh AS LONG: fh = FREEFILE
'    OPEN ansFile FOR BINARY ACCESS READ AS fh
'    COLOR _RGB(170, 170, 170), _RGB(0, 0, 0)
'    CLS
'    ANSI_Print INPUT$(LOF(fh), fh)
'    CLOSE fh
'    _TITLE "Press any key to open another file...": SLEEP 3600
'LOOP

'END
'-------------------------------------------------------------------------------------------------------------------

' Initializes library global variables and tables and then sets the init flag to true
SUB ANSI_InitializeEmulator
    SHARED __ANSIEmu AS __ANSIEmulatorType
    SHARED __ANSIColorLUT() AS BGRAType
    SHARED __ANSIArg() AS LONG

    IF __ANSIEmu.isInitialized THEN EXIT SUB ' leave if we have already initialized

    ' The first 16 are the standard 16 ANSI colors (matches QB64's VGA palette but with different color indices!)
    __ANSIColorLUT(0).r = 0: __ANSIColorLUT(0).g = 0: __ANSIColorLUT(0).b = 0: __ANSIColorLUT(0).a = 255 '            0: _RGB32(0,   0,   0)   (black)
    __ANSIColorLUT(1).r = 170: __ANSIColorLUT(1).g = 0: __ANSIColorLUT(1).b = 0: __ANSIColorLUT(1).a = 255 '          1: _RGB32(170, 0,   0)   (red)
    __ANSIColorLUT(2).r = 0: __ANSIColorLUT(2).g = 170: __ANSIColorLUT(2).b = 0: __ANSIColorLUT(2).a = 255 '          2: _RGB32(0,   170, 0)   (green)
    __ANSIColorLUT(3).r = 170: __ANSIColorLUT(3).g = 85: __ANSIColorLUT(3).b = 0: __ANSIColorLUT(3).a = 255 '         3: _RGB32(170, 85,  0)   (brown)
    __ANSIColorLUT(4).r = 0: __ANSIColorLUT(4).g = 0: __ANSIColorLUT(4).b = 170: __ANSIColorLUT(4).a = 255 '          4: _RGB32(0,   0,   170) (blue)
    __ANSIColorLUT(5).r = 170: __ANSIColorLUT(5).g = 0: __ANSIColorLUT(5).b = 170: __ANSIColorLUT(5).a = 255 '        5: _RGB32(170, 0,   170) (magenta)
    __ANSIColorLUT(6).r = 0: __ANSIColorLUT(6).g = 170: __ANSIColorLUT(6).b = 170: __ANSIColorLUT(6).a = 255 '        6: _RGB32(0,   170, 170) (cyan)
    __ANSIColorLUT(7).r = 170: __ANSIColorLUT(7).g = 170: __ANSIColorLUT(7).b = 170: __ANSIColorLUT(7).a = 255 '      7: _RGB32(170, 170, 170) (white)
    __ANSIColorLUT(8).r = 85: __ANSIColorLUT(8).g = 85: __ANSIColorLUT(8).b = 85: __ANSIColorLUT(8).a = 255 '         8: _RGB32(85,  85,  85)  (grey)
    __ANSIColorLUT(9).r = 255: __ANSIColorLUT(9).g = 85: __ANSIColorLUT(9).b = 85: __ANSIColorLUT(9).a = 255 '        9: _RGB32(255, 85,  85)  (bright red)
    __ANSIColorLUT(10).r = 85: __ANSIColorLUT(10).g = 255: __ANSIColorLUT(10).b = 85: __ANSIColorLUT(10).a = 255 '   10: _RGB32(85,  255, 85)  (bright green)
    __ANSIColorLUT(11).r = 255: __ANSIColorLUT(11).g = 255: __ANSIColorLUT(11).b = 85: __ANSIColorLUT(11).a = 255 '  11: _RGB32(255, 255, 85)  (bright yellow)
    __ANSIColorLUT(12).r = 85: __ANSIColorLUT(12).g = 85: __ANSIColorLUT(12).b = 255: __ANSIColorLUT(12).a = 255 '   12: _RGB32(85,  85,  255) (bright blue)
    __ANSIColorLUT(13).r = 255: __ANSIColorLUT(13).g = 85: __ANSIColorLUT(13).b = 255: __ANSIColorLUT(13).a = 255 '  13: _RGB32(255, 85,  255) (bright magenta)
    __ANSIColorLUT(14).r = 85: __ANSIColorLUT(14).g = 255: __ANSIColorLUT(14).b = 255: __ANSIColorLUT(14).a = 255 '  14: _RGB32(85,  255, 255) (bright cyan)
    __ANSIColorLUT(15).r = 255: __ANSIColorLUT(15).g = 255: __ANSIColorLUT(15).b = 255: __ANSIColorLUT(15).a = 255 ' 15: _RGB32(255, 255, 255) (bright white)

    ' The next 216 colors (16 - 231) are formed by a 3bpc RGB value offset by 16
    DIM AS LONG c, i
    FOR c = 16 TO 231
        i = ((c - 16) \ 36) MOD 6
        IF i = 0 THEN __ANSIColorLUT(c).r = 0 ELSE __ANSIColorLUT(c).r = (14135 + 10280 * i) \ 256

        i = ((c - 16) \ 6) MOD 6
        IF i = 0 THEN __ANSIColorLUT(c).g = 0 ELSE __ANSIColorLUT(c).g = (14135 + 10280 * i) \ 256

        i = ((c - 16) \ 1) MOD 6
        IF i = 0 THEN __ANSIColorLUT(c).b = 0 ELSE __ANSIColorLUT(c).b = (14135 + 10280 * i) \ 256

        __ANSIColorLUT(c).a = 255
    NEXT

    ' The final 24 colors (232 - 255) are grayscale starting from a shade slighly lighter than black, ranging up to shade slightly darker than white
    FOR c = 232 TO 255
        i = (2056 + 2570 * (c - 232)) \ 256
        __ANSIColorLUT(c).r = i
        __ANSIColorLUT(c).g = i
        __ANSIColorLUT(c).b = i
        __ANSIColorLUT(c).a = 255
    NEXT

    REDIM __ANSIArg(1 TO UBOUND(__ANSIArg)) AS LONG ' reset the CSI arg list

    __ANSIEmu.state = __ANSI_STATE_TEXT ' we will start parsing regular text by default
    __ANSIEmu.argIndex = 0 ' reset argument index

    ' Reset the foreground and background color
    __ANSIEmu.fC = __ANSI_DEFAULT_COLOR_FOREGROUND
    ANSI_SetTextCanvasColor __ANSIEmu.fC, _FALSE, _TRUE
    __ANSIEmu.bC = __ANSI_DEFAULT_COLOR_BACKGROUND
    ANSI_SetTextCanvasColor __ANSIEmu.bC, _TRUE, _TRUE

    ' Reset text attributes
    __ANSIEmu.isBold = _FALSE
    __ANSIEmu.isBlink = _FALSE
    __ANSIEmu.isInvert = _FALSE

    ' Get the current cursor position
    __ANSIEmu.posDEC.x = POS(0)
    __ANSIEmu.posDEC.y = CSRLIN
    __ANSIEmu.posSCO = __ANSIEmu.posDEC

    __ANSIEmu.lastChar = NULL
    __ANSIEmu.lastCharX = NULL

    __ANSIEmu.CPS = 0 ' disable any speed control

    IF _PIXELSIZE = 0 THEN
        _BLINK OFF ' use ICE colors
    ELSE
        _PRINTMODE _FILLBACKGROUND ' set _PRINTMODE to fill the background for graphics mode
    END IF

    _CONTROLCHR ON ' get assist from QB64's control character handling (only for tabs; we are pretty much doing the rest ourselves)

    __ANSIEmu.isInitialized = _TRUE ' set to true to indicate init is done
END SUB


' This simply resets the emulator to a clean state
SUB ANSI_ResetEmulator
    SHARED __ANSIEmu AS __ANSIEmulatorType

    __ANSIEmu.isInitialized = _FALSE ' set the init flag to false
    ANSI_InitializeEmulator ' call the init routine
END SUB


' Sets the emulation speed
' nCPS - characters / second (bigger numbers means faster; <= 0 to disable)
SUB ANSI_SetEmulationSpeed (nCPS AS LONG)
    SHARED __ANSIEmu AS __ANSIEmulatorType

    __ANSIEmu.CPS = nCPS
END SUB


' Processes a single byte and decides what to do with it based on the current emulation state
FUNCTION ANSI_PrintCharacter%% (ch AS _UNSIGNED _BYTE)
    SHARED __ANSIEmu AS __ANSIEmulatorType
    SHARED __ANSIArg() AS LONG

    ANSI_PrintCharacter = _TRUE ' by default we will return true to tell the caller to keep going

    DIM AS LONG x, y, z ' temp variables used in many places (usually as counter / index)

    SELECT CASE __ANSIEmu.state
        CASE __ANSI_STATE_TEXT ' handle normal characters (including some control characters)
            SELECT CASE ch
                CASE _ASC_SUB ' stop processing and exit loop on EOF (usually put by SAUCE blocks)
                    __ANSIEmu.state = __ANSI_STATE_END

                CASE _ASC_BEL ' handle Bell - because QB64 does not (even with ControlChr On)
                    BEEP

                CASE _ASC_BS ' handle Backspace - because QB64 does not (even with ControlChr On)
                    x = POS(0) - 1
                    IF x > 0 THEN LOCATE , x ' move to the left only if we are not on the edge

                CASE _ASC_LF ' handle Line Feed (including EOL CRLF special case)
                    PRINT STRING$(1 - (_ASC_CR = __ANSIEmu.lastChar AND ANSI_GetTextCanvasWidth = __ANSIEmu.lastCharX), ch);

                CASE _ASC_FF ' handle Form Feed - because QB64 does not (even with ControlChr On)
                    LOCATE 1, 1

                CASE _ASC_CR ' handle Carriage Return because QB64 screws this up and moves the cursor to the beginning of the next line
                    LOCATE , 1

                    'Case ANSI_DEL ' TODO: Check what to do with this

                CASE _ASC_ESC ' handle escape character
                    __ANSIEmu.state = __ANSI_STATE_BEGIN ' beginning a new escape sequence

                CASE _ASC_RS, _ASC_US ' QB64 does non-ANSI stuff with these two when ControlChar is On
                    _CONTROLCHR OFF
                    __ANSIEmu.lastCharX = POS(0)
                    PRINT CHR$(ch); ' print escaped ESC character
                    _CONTROLCHR ON
                    IF __ANSIEmu.CPS > 0 THEN _LIMIT __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value

                CASE ELSE ' print the character
                    __ANSIEmu.lastCharX = POS(0)
                    PRINT CHR$(ch);
                    IF __ANSIEmu.CPS > 0 THEN _LIMIT __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value

            END SELECT

        CASE __ANSI_STATE_BEGIN ' handle escape sequence
            SELECT CASE ch
                CASE IS < _ASC_SPACE ' handle escaped character
                    _CONTROLCHR OFF
                    __ANSIEmu.lastCharX = POS(0)
                    PRINT CHR$(ch); ' print escaped ESC character
                    _CONTROLCHR ON
                    IF __ANSIEmu.CPS > 0 THEN _LIMIT __ANSIEmu.CPS ' limit the loop speed if char/sec is a positive value
                    __ANSIEmu.state = __ANSI_STATE_TEXT

                CASE ANSI_ESC_DECSC ' Save Cursor Position in Memory
                    __ANSIEmu.posDEC.x = POS(0)
                    __ANSIEmu.posDEC.y = CSRLIN
                    __ANSIEmu.state = __ANSI_STATE_TEXT

                CASE ANSI_ESC_DECSR ' Restore Cursor Position from Memory
                    LOCATE __ANSIEmu.posDEC.y, __ANSIEmu.posDEC.x
                    __ANSIEmu.state = __ANSI_STATE_TEXT

                CASE ANSI_ESC_RI ' Reverse Index
                    y = CSRLIN - 1
                    IF y > 0 THEN LOCATE y
                    __ANSIEmu.state = __ANSI_STATE_TEXT

                CASE ANSI_ESC_CSI ' handle CSI
                    REDIM __ANSIArg(1 TO UBOUND(__ANSIArg)) AS LONG ' reset the control sequence arguments, but don't loose the allocated memory
                    __ANSIEmu.argIndex = 0 ' reset argument index
                    'leadInPrefix = 0 ' reset lead-in prefix
                    __ANSIEmu.state = __ANSI_STATE_SEQUENCE

                CASE ELSE ' throw an error for stuff we are not handling
                    ERROR _ERR_FEATURE_UNAVAILABLE

            END SELECT

        CASE __ANSI_STATE_SEQUENCE ' handle CSI sequence
            SELECT CASE ch
                CASE ASC_0 TO _ASC_QUESTION ' argument bytes
                    IF __ANSIEmu.argIndex < 1 THEN __ANSIEmu.argIndex = 1 ' set the argument index to one if this is the first time

                    SELECT CASE ch
                        CASE ASC_0 TO ASC_9 ' handle sequence numeric arguments
                            __ANSIArg(__ANSIEmu.argIndex) = __ANSIArg(__ANSIEmu.argIndex) * 10 + ch - ASC_0

                        CASE _ASC_SEMICOLON ' handle sequence argument seperators
                            __ANSIEmu.argIndex = __ANSIEmu.argIndex + 1 ' increment the argument index
                            IF __ANSIEmu.argIndex > UBOUND(__ANSIArg) THEN REDIM _PRESERVE __ANSIArg(1 TO __ANSIEmu.argIndex) AS LONG ' dynamically expand the argument list if needed

                        CASE _ASC_EQUAL, _ASC_GREATERTHAN, _ASC_QUESTION ' handle lead-in prefix
                            ' NOP: leadInPrefix = ch ' just save the prefix type

                        CASE ELSE ' throw an error for stuff we are not handling
                            ERROR _ERR_FEATURE_UNAVAILABLE

                    END SELECT

                CASE _ASC_SPACE TO _ASC_FORWARDSLASH ' intermediate bytes
                    SELECT CASE ch
                        CASE _ASC_SPACE ' ignore spaces
                            ' NOP

                        CASE ELSE ' throw an error for stuff we are not handling
                            ERROR _ERR_FEATURE_UNAVAILABLE

                    END SELECT

                CASE _ASC_ATSIGN TO _ASC_TILDE ' final byte
                    SELECT CASE ch
                        CASE ANSI_ESC_CSI_SM, ANSI_ESC_CSI_RM ' Set and reset screen mode
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            SELECT CASE __ANSIArg(1)
                                CASE 0 TO 6, 14 TO 18 ' all mode changes are ignored. the screen type must be set by the caller
                                    ' NOP

                                CASE 7 ' Enable / disable line wrapping
                                    ' NOP: QB64 does line wrapping by default
                                    IF ANSI_ESC_CSI_RM = ch THEN ' ANSI_ESC_CSI_RM disable line wrapping unsupported
                                        ERROR _ERR_FEATURE_UNAVAILABLE
                                    END IF

                                CASE 12 ' Text Cursor Enable / Disable Blinking
                                    ' NOP

                                CASE 25 ' make cursor visible / invisible
                                    IF ANSI_ESC_CSI_SM = ch THEN ' ANSI_ESC_CSI_SM make cursor visible
                                        LOCATE , , 1
                                    ELSE ' ANSI_ESC_CSI_RM make cursor invisible
                                        LOCATE , , 0
                                    END IF

                                CASE ELSE ' throw an error for stuff we are not handling
                                    ERROR _ERR_FEATURE_UNAVAILABLE

                            END SELECT

                        CASE ANSI_ESC_CSI_ED ' Erase in Display
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            SELECT CASE __ANSIArg(1)
                                CASE 0 ' clear from cursor to end of screen
                                    ANSI_ClearTextCanvasArea POS(0), CSRLIN, ANSI_GetTextCanvasWidth, CSRLIN ' first clear till the end of the line starting from the cursor
                                    ANSI_ClearTextCanvasArea 1, CSRLIN + 1, ANSI_GetTextCanvasWidth, ANSI_GetTextCanvasHeight ' next clear the whole canvas below the cursor

                                CASE 1 ' clear from cursor to beginning of the screen
                                    ANSI_ClearTextCanvasArea 1, CSRLIN, POS(0), CSRLIN ' first clear from the beginning of the line till the cursor
                                    ANSI_ClearTextCanvasArea 1, 1, ANSI_GetTextCanvasWidth, CSRLIN - 1 ' next clear the whole canvas above the cursor

                                CASE 2 ' clear entire screen (and moves cursor to upper left like ANSI.SYS)
                                    CLS

                                CASE 3 ' clear entire screen and delete all lines saved in the scrollback buffer (scrollback stuff not supported)
                                    ANSI_ClearTextCanvasArea 1, 1, ANSI_GetTextCanvasWidth, ANSI_GetTextCanvasHeight

                                CASE ELSE ' throw an error for stuff we are not handling
                                    ERROR _ERR_FEATURE_UNAVAILABLE

                            END SELECT

                        CASE ANSI_ESC_CSI_EL ' Erase in Line
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            SELECT CASE __ANSIArg(1)
                                CASE 0 ' erase from cursor to end of line
                                    ANSI_ClearTextCanvasArea POS(0), CSRLIN, ANSI_GetTextCanvasWidth, CSRLIN

                                CASE 1 ' erase start of line to the cursor
                                    ANSI_ClearTextCanvasArea 1, CSRLIN, POS(0), CSRLIN

                                CASE 2 ' erase the entire line
                                    ANSI_ClearTextCanvasArea 1, CSRLIN, ANSI_GetTextCanvasWidth, CSRLIN

                                CASE ELSE ' throw an error for stuff we are not handling
                                    ERROR _ERR_FEATURE_UNAVAILABLE

                            END SELECT

                        CASE ANSI_ESC_CSI_SGR ' Select Graphic Rendition
                            x = 1 ' start with the first argument
                            IF __ANSIEmu.argIndex < 1 THEN __ANSIEmu.argIndex = 1 ' this allows '[m' to be treated as [0m
                            DO WHILE x <= __ANSIEmu.argIndex ' loop through the argument list and process each argument
                                SELECT CASE __ANSIArg(x)
                                    CASE 0 ' reset all modes (styles and colors)
                                        __ANSIEmu.fC = __ANSI_DEFAULT_COLOR_FOREGROUND
                                        __ANSIEmu.bC = __ANSI_DEFAULT_COLOR_BACKGROUND
                                        __ANSIEmu.isBold = _FALSE
                                        __ANSIEmu.isBlink = _FALSE
                                        __ANSIEmu.isInvert = _FALSE
                                        ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE
                                        ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE

                                    CASE 1 ' enable high intensity colors
                                        IF __ANSIEmu.fC < 8 THEN __ANSIEmu.fC = __ANSIEmu.fC + 8
                                        __ANSIEmu.isBold = _TRUE
                                        ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE

                                    CASE 2, 22 ' enable low intensity, disable high intensity colors
                                        IF __ANSIEmu.fC > 7 THEN __ANSIEmu.fC = __ANSIEmu.fC - 8
                                        __ANSIEmu.isBold = _FALSE
                                        ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE

                                    CASE 3, 4, 23, 24 ' set / reset italic & underline mode ignored
                                        ' NOP: This can be used if we load monospaced TTF fonts using 'italics', 'underline' properties

                                    CASE 5, 6 ' turn blinking on
                                        IF __ANSIEmu.bC < 8 THEN __ANSIEmu.bC = __ANSIEmu.bC + 8
                                        __ANSIEmu.isBlink = _TRUE
                                        ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE

                                    CASE 7 ' enable reverse video
                                        IF NOT __ANSIEmu.isInvert THEN
                                            __ANSIEmu.isInvert = _TRUE
                                            ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE
                                            ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE
                                        END IF

                                    CASE 25 ' turn blinking off
                                        IF __ANSIEmu.bC > 7 THEN __ANSIEmu.bC = __ANSIEmu.bC - 8
                                        __ANSIEmu.isBlink = _FALSE
                                        ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE

                                    CASE 27 ' disable reverse video
                                        IF __ANSIEmu.isInvert THEN
                                            __ANSIEmu.isInvert = _FALSE
                                            ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE
                                            ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE
                                        END IF

                                    CASE 30 TO 37 ' set foreground color
                                        __ANSIEmu.fC = __ANSIArg(x) - 30
                                        IF __ANSIEmu.isBold THEN __ANSIEmu.fC = __ANSIEmu.fC + 8
                                        ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE

                                    CASE 38 ' set 8-bit 256 or 24-bit RGB foreground color
                                        z = __ANSIEmu.argIndex - x ' get the number of arguments remaining

                                        IF __ANSIArg(x + 1) = 2 AND z >= 4 THEN ' 32bpp color with 5 arguments
                                            __ANSIEmu.fC = _RGB32(__ANSIArg(x + 2) AND &HFF, __ANSIArg(x + 3) AND &HFF, __ANSIArg(x + 4) AND &HFF)
                                            ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _FALSE

                                            x = x + 4 ' skip to last used arg

                                        ELSEIF __ANSIArg(x + 1) = 5 AND z >= 2 THEN ' 256 color with 3 arguments
                                            __ANSIEmu.fC = __ANSIArg(x + 2)
                                            ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE

                                            x = x + 2 ' skip to last used arg

                                        ELSE
                                            ERROR _ERR_CANNOT_CONTINUE

                                        END IF

                                    CASE 39 ' set default foreground color
                                        __ANSIEmu.fC = __ANSI_DEFAULT_COLOR_FOREGROUND
                                        ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE

                                    CASE 40 TO 47 ' set background color
                                        __ANSIEmu.bC = __ANSIArg(x) - 40
                                        IF __ANSIEmu.isBlink THEN __ANSIEmu.bC = __ANSIEmu.bC + 8
                                        ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE

                                    CASE 48 ' set 8-bit 256 or 24-bit RGB background color
                                        z = __ANSIEmu.argIndex - x ' get the number of arguments remaining

                                        IF __ANSIArg(x + 1) = 2 AND z >= 4 THEN ' 32bpp color with 5 arguments
                                            __ANSIEmu.bC = _RGB32(__ANSIArg(x + 2) AND &HFF, __ANSIArg(x + 3) AND &HFF, __ANSIArg(x + 4) AND &HFF)
                                            ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _FALSE

                                            x = x + 4 ' skip to last used arg

                                        ELSEIF __ANSIArg(x + 1) = 5 AND z >= 2 THEN ' 256 color with 3 arguments
                                            __ANSIEmu.bC = __ANSIArg(x + 2)
                                            ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE

                                            x = x + 2 ' skip to last used arg

                                        ELSE
                                            ERROR _ERR_CANNOT_CONTINUE

                                        END IF

                                    CASE 49 ' set default background color
                                        __ANSIEmu.bC = __ANSI_DEFAULT_COLOR_BACKGROUND
                                        ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE

                                    CASE 90 TO 97 ' set high intensity foreground color
                                        __ANSIEmu.fC = 8 + __ANSIArg(x) - 90
                                        ANSI_SetTextCanvasColor __ANSIEmu.fC, __ANSIEmu.isInvert, _TRUE

                                    CASE 100 TO 107 ' set high intensity background color
                                        __ANSIEmu.bC = 8 + __ANSIArg(x) - 100
                                        ANSI_SetTextCanvasColor __ANSIEmu.bC, NOT __ANSIEmu.isInvert, _TRUE

                                    CASE ELSE ' throw an error for stuff we are not handling
                                        ERROR _ERR_FEATURE_UNAVAILABLE

                                END SELECT

                                x = x + 1 ' move to the next argument
                            LOOP

                        CASE ANSI_ESC_CSI_SCP ' Save Current Cursor Position (SCO)
                            IF __ANSIEmu.argIndex > 0 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting args

                            __ANSIEmu.posSCO.x = POS(0)
                            __ANSIEmu.posSCO.y = CSRLIN

                        CASE ANSI_ESC_CSI_RCP ' Restore Saved Cursor Position (SCO)
                            IF __ANSIEmu.argIndex > 0 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting args

                            LOCATE __ANSIEmu.posSCO.y, __ANSIEmu.posSCO.x

                        CASE ANSI_ESC_CSI_PABLODRAW_24BPP ' PabloDraw 24-bit ANSI sequences
                            IF __ANSIEmu.argIndex <> 4 THEN ERROR _ERR_CANNOT_CONTINUE ' we need 4 arguments

                            ANSI_SetTextCanvasColor _RGB32(__ANSIArg(2) AND &HFF, __ANSIArg(3) AND &HFF, __ANSIArg(4) AND &HFF), __ANSIArg(1) = _FALSE, _FALSE

                        CASE ANSI_ESC_CSI_CUP, ANSI_ESC_CSI_HVP ' Cursor position or Horizontal and vertical position
                            IF __ANSIEmu.argIndex > 2 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 2 args

                            y = ANSI_GetTextCanvasHeight
                            IF __ANSIArg(1) < 1 THEN
                                __ANSIArg(1) = 1
                            ELSEIF __ANSIArg(1) > y THEN
                                __ANSIArg(1) = y
                            END IF

                            x = ANSI_GetTextCanvasWidth
                            IF __ANSIArg(2) < 1 THEN
                                __ANSIArg(2) = 1
                            ELSEIF __ANSIArg(2) > x THEN
                                __ANSIArg(2) = x
                            END IF

                            LOCATE __ANSIArg(1), __ANSIArg(2) ' line #, column #

                        CASE ANSI_ESC_CSI_CUU ' Cursor up
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                            y = CSRLIN - __ANSIArg(1)
                            IF y < 1 THEN y = 1
                            LOCATE y

                        CASE ANSI_ESC_CSI_CUD ' Cursor down
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                            y = CSRLIN + __ANSIArg(1)
                            z = ANSI_GetTextCanvasHeight
                            IF y > z THEN y = z
                            LOCATE y

                        CASE ANSI_ESC_CSI_CUF ' Cursor forward
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                            x = POS(0) + __ANSIArg(1)
                            z = ANSI_GetTextCanvasWidth
                            IF x > z THEN x = z
                            LOCATE , x

                        CASE ANSI_ESC_CSI_CUB ' Cursor back
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                            x = POS(0) - __ANSIArg(1)
                            IF x < 1 THEN x = 1
                            LOCATE , x

                        CASE ANSI_ESC_CSI_CNL ' Cursor Next Line
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                            y = CSRLIN + __ANSIArg(1)
                            z = ANSI_GetTextCanvasHeight
                            IF y > z THEN y = z
                            LOCATE y, 1

                        CASE ANSI_ESC_CSI_CPL ' Cursor Previous Line
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            IF __ANSIArg(1) < 1 THEN __ANSIArg(1) = 1
                            y = CSRLIN - __ANSIArg(1)
                            IF y < 1 THEN y = 1
                            LOCATE y, 1

                        CASE ANSI_ESC_CSI_CHA ' Cursor Horizontal Absolute
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            x = ANSI_GetTextCanvasWidth
                            IF __ANSIArg(1) < 1 THEN
                                __ANSIArg(1) = 1
                            ELSEIF __ANSIArg(1) > x THEN
                                __ANSIArg(1) = x
                            END IF
                            LOCATE , __ANSIArg(1)

                        CASE ANSI_ESC_CSI_VPA ' Vertical Line Position Absolute
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            y = ANSI_GetTextCanvasHeight
                            IF __ANSIArg(1) < 1 THEN
                                __ANSIArg(1) = 1
                            ELSEIF __ANSIArg(1) > y THEN
                                __ANSIArg(1) = y
                            END IF
                            LOCATE __ANSIArg(1)

                        CASE ANSI_ESC_CSI_DECSCUSR
                            IF __ANSIEmu.argIndex > 1 THEN ERROR _ERR_CANNOT_CONTINUE ' was not expecting more than 1 arg

                            SELECT CASE __ANSIArg(1)
                                CASE 0, 3, 4 ' Default, Blinking & Steady underline cursor shape
                                    LOCATE , , , 29, 31 ' this should give a nice underline cursor

                                CASE 1, 2 ' Blinking & Steady block cursor shape
                                    LOCATE , , , 0, 31 ' this should give a full block cursor

                                CASE 5, 6 ' Blinking & Steady bar cursor shape
                                    LOCATE , , , 16, 31 ' since we cannot get a bar cursor in QB64, we'll just use a half-block cursor

                                CASE ELSE ' throw an error for stuff we are not handling
                                    ERROR _ERR_FEATURE_UNAVAILABLE

                            END SELECT

                        CASE ELSE ' throw an error for stuff we are not handling
                            ERROR _ERR_FEATURE_UNAVAILABLE

                    END SELECT

                    ' End of sequence
                    __ANSIEmu.state = __ANSI_STATE_TEXT

                CASE ELSE ' throw an error for stuff we are not handling
                    ERROR _ERR_FEATURE_UNAVAILABLE

            END SELECT

        CASE __ANSI_STATE_END ' end of the stream has been reached
            ANSI_PrintCharacter = _FALSE ' tell the caller the we should stop processing the rest of the stream
            EXIT FUNCTION ' and then leave

        CASE ELSE ' this should never happen
            ERROR _ERR_CANNOT_CONTINUE

    END SELECT

    __ANSIEmu.lastChar = ch ' save the character
END FUNCTION


' Processes the whole string instead of a character like PrintANSICharacter()
' This simply wraps PrintANSICharacter()
' It returns True when EOF is encountered
FUNCTION ANSI_PrintString%% (s AS STRING)
    ANSI_PrintString = _TRUE

    DIM AS LONG i: FOR i = 1 TO LEN(s)
        IF NOT ANSI_PrintCharacter(ASC(s, i)) THEN
            ANSI_PrintString = _FALSE ' signal end of stream
            EXIT FUNCTION
        END IF
    NEXT i
END FUNCTION


' A simple routine that wraps pretty much the whole library
' It will reset the library, do the setup and then render the whole ANSI string in one go
' _PRINTMODE and _CONTROLCHR is properly restored
SUB ANSI_Print (sANSI AS STRING)
    ' Save _PRINTMODE (if not in SCREEN 0)
    IF _PIXELSIZE <> 0 THEN
        DIM pm AS LONG: pm = _PRINTMODE
    END IF

    ' Save _CONTROLCHR
    DIM cc AS LONG: cc = _CONTROLCHR

    ANSI_ResetEmulator ' reset the emulator

    DIM dummy AS _BYTE: dummy = ANSI_PrintString(sANSI) ' print the ANSI string and ignore the return value

    ' Set _CONTROLCHR the way we found it
    ' Ewww :(
    IF cc THEN
        _CONTROLCHR OFF
    ELSE
        _CONTROLCHR ON
    END IF

    ' Set _PRINTMODE the way we found it (if not in SCREEN 0)
    IF _PIXELSIZE <> 0 THEN
        ' Ewww :(
        SELECT CASE pm
            CASE 1
                _PRINTMODE _KEEPBACKGROUND

            CASE 2
                _PRINTMODE _ONLYBACKGROUND

            CASE ELSE
                _PRINTMODE _FILLBACKGROUND
        END SELECT
    END IF
END SUB


' Set the foreground or background color
SUB ANSI_SetTextCanvasColor (c AS _UNSIGNED LONG, isBackground AS LONG, isLegacy AS LONG)
    SHARED __ANSIColorLUT() AS BGRAType

    DIM nRGB AS _UNSIGNED LONG

    ' Use _RGB to get the closest matching color index for palatted mode
    ' For 32-bit surfaces, it will simply return the 32-bit BGRA color passed
    ' This way we can support all types of modes (i.e. SCREEN 0 - 13 and 32-bit)
    ' Note that this will obviously hurt performance. But then, does it really matter?
    IF isLegacy THEN
        nRGB = _RGB(__ANSIColorLUT(c).r, __ANSIColorLUT(c).g, __ANSIColorLUT(c).b)
    ELSE
        nRGB = _RGB(_RED32(c), _GREEN32(c), _BLUE32(c))
    END IF

    ' Graphics_SetBackgroundColor & Graphics_SetForegroundColor has the logic to deal with SCREEN 0 color nonsense
    IF isBackground THEN
        Graphics_SetBackgroundColor nRGB
    ELSE
        Graphics_SetForegroundColor nRGB
    END IF
END SUB


' Returns the number of characters per line
FUNCTION ANSI_GetTextCanvasWidth&
    IF _PIXELSIZE = 0 THEN
        ANSI_GetTextCanvasWidth = _WIDTH
    ELSE
        DIM fw AS LONG: fw = _FONTWIDTH
        IF fw = 0 THEN fw = _PRINTWIDTH("W") ' :(
        ANSI_GetTextCanvasWidth = _WIDTH \ fw
    END IF
END FUNCTION


' Returns the number of lines
FUNCTION ANSI_GetTextCanvasHeight&
    IF _PIXELSIZE = 0 THEN
        ANSI_GetTextCanvasHeight = _HEIGHT
    ELSE
        ANSI_GetTextCanvasHeight = _HEIGHT \ _FONTHEIGHT
    END IF
END FUNCTION


' Clears a given portion of screen without disturbing the cursor location and colors
SUB ANSI_ClearTextCanvasArea (l AS LONG, t AS LONG, r AS LONG, b AS LONG)
    DIM w AS LONG: w = 1 + r - l ' calculate width

    IF w > 0 AND t <= b THEN ' only proceed is width is > 0 and height is > 0
        ' Save some stuff
        DIM fc AS _UNSIGNED LONG: fc = _DEFAULTCOLOR
        DIM bc AS _UNSIGNED LONG: bc = _BACKGROUNDCOLOR
        DIM x AS LONG: x = POS(0)
        DIM y AS LONG: y = CSRLIN

        COLOR _RGB(0, 0, 0), _RGB(0, 0, 0) ' lights out

        DIM blankLine AS STRING: blankLine = SPACE$(w) ' do this only once

        DIM i AS LONG: FOR i = t TO b
            LOCATE i, l: PRINT blankLine; ' fill with SPACE
        NEXT i

        ' Restore saved stuff
        COLOR fc, bc
        LOCATE y, x
    END IF
END SUB


FUNCTION ANSI_GetFontHeight~%% (sauce AS SAUCEType)
    CONST __ANSI_F8_1 = "IBM VGA50"
    CONST __ANSI_F8_2 = "IBM EGA43"
    CONST __ANSI_F14_1 = "IBM EGA"
    CONST __ANSI_F8_3 = "AMIGA"
    CONST __ANSI_F8_5 = "ATARI"
    CONST __ANSI_F8_4 = "C64"

    DIM sauceTypeInfoString AS STRING: sauceTypeInfoString = SAUCE_GetTypeInfoString(sauce)

    IF UCASE$(LEFT$(sauceTypeInfoString, LEN(__ANSI_F8_1))) = __ANSI_F8_1 THEN
        ANSI_GetFontHeight = 8
    ELSEIF UCASE$(LEFT$(sauceTypeInfoString, LEN(__ANSI_F8_2))) = __ANSI_F8_2 THEN
        ANSI_GetFontHeight = 8
    ELSEIF UCASE$(LEFT$(sauceTypeInfoString, LEN(__ANSI_F14_1))) = __ANSI_F14_1 THEN
        ANSI_GetFontHeight = 14
    ELSEIF UCASE$(LEFT$(sauceTypeInfoString, LEN(__ANSI_F8_3))) = __ANSI_F8_3 THEN
        ANSI_GetFontHeight = 8
    ELSEIF UCASE$(LEFT$(sauceTypeInfoString, LEN(__ANSI_F8_5))) = __ANSI_F8_5 THEN
        ANSI_GetFontHeight = 8
    ELSEIF UCASE$(LEFT$(sauceTypeInfoString, LEN(__ANSI_F8_4))) = __ANSI_F8_4 THEN
        ANSI_GetFontHeight = 8
    ELSE
        ANSI_GetFontHeight = 16
    END IF
END FUNCTION


FUNCTION ANSI_GetWidth& (sauce AS SAUCEType)
    DIM w AS LONG: w = SAUCE_GetTypeInfoLong1(sauce)

    IF w THEN
        ANSI_GetWidth = w
    ELSE
        ANSI_GetWidth = 80
    END IF
END FUNCTION


FUNCTION ANSI_GetHeight& (sauce AS SAUCEType)
    DIM h AS LONG: h = SAUCE_GetTypeInfoLong2(sauce)

    IF h THEN
        ANSI_GetHeight = h
    ELSE
        ANSI_GetHeight = 25
    END IF
END FUNCTION
