'-----------------------------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$VERSIONINFO:CompanyName='Samuel Gomes'
$VERSIONINFO:FileDescription='QB64 MOD Player executable'
$VERSIONINFO:InternalName='QB64MODPlayer'
$VERSIONINFO:LegalCopyright='Copyright (c) 2026 Samuel Gomes'
$VERSIONINFO:LegalTrademarks='All trademarks are property of their respective owners'
$VERSIONINFO:OriginalFilename='QB64MODPlayer.exe'
$VERSIONINFO:ProductName='QB64 MOD Player'
$VERSIONINFO:Web='https://github.com/a740g'
$VERSIONINFO:Comments='https://github.com/a740g'
$VERSIONINFO:FILEVERSION#=2,2,0,0
$VERSIONINFO:PRODUCTVERSION#=2,2,0,0
$EXEICON:'./QB64MODPlayer.ico'

_DEFINE A-Z AS LONG
OPTION _EXPLICIT
OPTION BASE 1
'$STATIC

$RESIZE:SMOOTH

$COLOR:0

'$INCLUDE:'Asc.bi'
'$INCLUDE:'String.bi'
'$INCLUDE:'Math.bi'
'$INCLUDE:'Pathname.bi'
'$INCLUDE:'File.bi'
'$INCLUDE:'Vector2i.bi'
'$INCLUDE:'Vector3f.bi'
'$INCLUDE:'AudioAnalyzer.bi'
'$INCLUDE:'MODPlayer.bi'
'$INCLUDE:'MODPlayer.bm'

CONST APP_NAME = "QB64 MOD Player" ' application name
' We'll use a window with 1152 x 720 px (144 x 90 chars @ 8 x 8 px font) client area
CONST UI_TEXT_WIDTH_MIN& = 144& ' minimum width we need
CONST UI_TEXT_LINE_MAX& = 90& ' this the number of lines we need
CONST UI_TEXT_WIDTH_HEADER& = 84& ' width of the main header on the vis screen
CONST UI_MAX_VISIBLE_INSTRUMENTS& = 64& ' maximum number of instruments visible at a time
CONST UI_ANALYZER_SCALE& = 9& ' this is used to scale the fft values
CONST APP_FRAME_RATE& = 60& ' update frame rate
CONST APP_VOLUME_STEP! = 0.01! ' the amount by which the audio volume is increased or decreased
' Program events
CONST APP_EVENT_NONE%% = 0%% ' idle
CONST APP_EVENT_QUIT%% = 1%% ' user wants to quit
CONST APP_EVENT_CMDS%% = 2%% ' process command line
CONST APP_EVENT_LOAD%% = 3%% ' user want to load files
CONST APP_EVENT_DROP%% = 4%% ' user dropped files
CONST APP_EVENT_PLAY%% = 5%% ' play next song
CONST APP_EVENT_HTTP%% = 6%% ' Downloads and plays random MODs from modarchive.org
' Background constants
CONST STAR_COUNT& = 256& ' the maximum stars that we can show
CONST SNAKE_COUNT& = 48& ' the maximum snakes we can draw on the screen
' Keyboard constants
CONST KEY_SPACE& = _ASC_SPACE
CONST KEY_PLUS& = _ASC_PLUS
CONST KEY_EQUAL& = _ASC_EQUAL
CONST KEY_MINUS& = _ASC_MINUS
CONST KEY_UNDERSCORE& = _ASC_UNDERSCORE
CONST KEY_UPPER_L& = ASC_UPPER_L
CONST KEY_LOWER_L& = ASC_LOWER_L

TYPE Star
    p AS Vector3f ' position
    a AS SINGLE ' angle
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE Snake
    p AS STRING ' position buffer (x = 1 byte, y = 1 byte)
    s AS SINGLE ' speed
    t AS SINGLE ' movement counter
    d AS Vector2i ' direction
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE FFTInfo
    framesPerTick AS LONG
    frames AS LONG
    halfFrames AS LONG
    bits AS LONG
    size AS Vector2i
END TYPE

REDIM NoteTable(0) AS STRING * 2 ' this contains the note stings
DIM WindowWidth AS LONG ' the width of our windows in characters
DIM PatternDisplayWidth AS LONG ' the width of the pattern display in characters
DIM FFT AS FFTInfo ' global FFT info
DIM AnalyzerL AS AudioAnalyzer, AnalyzerR AS AudioAnalyzer ' left & right audio analyzers
REDIM AS _UNSIGNED INTEGER SpectrumAnalyzerL(0), SpectrumAnalyzerR(0) ' left & right channel FFT data
DIM Stars(1 TO STAR_COUNT) AS Star
DIM Snakes(1 TO SNAKE_COUNT) AS Snake
DIM Player AS MODPlayer
DIM InstrumentScrollOffset AS LONG ' current scroll offset in instrument list

''' @brief Draws a horizontal text character line across the screen.
''' @param lx Left X coordinate.
''' @param ty Y coordinate.
''' @param rx Right X coordinate.
''' @param char ASCII character code to draw.
SUB UI_DrawHorizontalLine (lx AS LONG, ty AS LONG, rx AS LONG, char AS _UNSIGNED _BYTE)
    STATIC buffer AS STRING

    DIM l AS LONG: l = lx
    DIM r AS LONG: r = rx
    IF l > r THEN SWAP l, r
    buffer = STRING$(1 + r - l, char)

    _PRINTSTRING (l, ty), buffer
END SUB

''' @brief Renders the tracker visualizer, pattern data, and FFT spectrum analyzers.
SUB Visualizer_Draw
    SHARED NoteTable() AS STRING * 2
    SHARED WindowWidth AS LONG
    SHARED PatternDisplayWidth AS LONG
    SHARED FFT AS FFTInfo
    SHARED AS AudioAnalyzer AnalyzerL, AnalyzerR
    SHARED AS _UNSIGNED INTEGER SpectrumAnalyzerL(), SpectrumAnalyzerR()

    ' These are internal variables and arrays used by the MODPlayer library and are used for showing internal info and visualization
    ' In a general use case, accessing these directly is not required at all
    SHARED Player AS MODPlayer
    SHARED InstrumentScrollOffset AS LONG

    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then Player.order(Player.song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    IF Player.song.orderPosition >= Player.song.orders THEN EXIT SUB

    DIM startPat AS LONG: startPat = Player.order(Player.song.orderPosition)

    IF startPat >= Player.song.patterns THEN EXIT SUB ' this can happen when S3M tunes contain marker / end-of-song patterns

    CLS , Black ' clear the framebuffer to black color

    DIM x AS LONG: x = 1 + WindowWidth \ 2 - UI_TEXT_WIDTH_HEADER \ 2 ' find x so that we can center everything

    ' Print song type and name
    COLOR BrightWhite, Magenta
    LOCATE 1, x: PRINT USING " \  \: \                                                                          \ "; Player.song.subtype; Player.song.caption;

    ' Print the header
    COLOR Blink, BrightWhite
    DIM curPatRows AS LONG
    IF startPat < Player.song.patterns THEN curPatRows = Player.pattern(startPat).rows ELSE curPatRows = 64
    LOCATE 2, x: PRINT USING " ORD: ### / ### | PAT: ### / ### | ROW: ### / ### | CHN: ### / ### | VOC: ### / ### "; Player.song.orderPosition; Player.song.orders - 1; startPat; Player.song.patterns - 1; Player.song.patternRow; curPatRows - 1; Player.song.activeChannels; Player.song.channels; SoftSynth_GetActiveVoices(Player.synth); SoftSynth_GetTotalVoices(Player.synth);

    LOCATE 3, x: PRINT USING " BPM: ###       | SPD: ###       | VOL: ###%      | BUF: #######ms | REP: \       \ "; Player.song.BPM; Player.song.speed; SoftSynth_GetMasterVolume(Player.synth) * 100!; SoftSynth_GetBufferedSoundTime(Player.synth) * 1000#; _IIF(Player.song.isLooping, "Enabled", "Disabled");

    ' Clamp instrument scroll offset
    IF InstrumentScrollOffset > Player.song.instruments - UI_MAX_VISIBLE_INSTRUMENTS THEN
        InstrumentScrollOffset = Player.song.instruments - UI_MAX_VISIBLE_INSTRUMENTS
    END IF
    IF InstrumentScrollOffset < 0 THEN InstrumentScrollOffset = 0

    ' Print the sample list header
    COLOR Blink, Cyan
    IF Player.song.instruments > UI_MAX_VISIBLE_INSTRUMENTS THEN
        _PRINTSTRING (x, 4), "  S#  SAMPLE-NAME [Scroll:Up/Dn]  VOLUME C2SPD LENGTH LOOPING LOOP-START LOOP-STOP  "
    ELSE
        _PRINTSTRING (x, 4), "  S#  SAMPLE-NAME                 VOLUME C2SPD LENGTH LOOPING LOOP-START LOOP-STOP  "
    END IF

    ' Print the sample information
    DIM AS LONG i, j, rowIdx, maxInst
    maxInst = _MIN(Player.song.instruments, InstrumentScrollOffset + UI_MAX_VISIBLE_INSTRUMENTS)
    rowIdx = 0
    FOR i = InstrumentScrollOffset TO maxInst - 1
        COLOR Yellow, Black

        j = 0
        WHILE j < Player.song.channels
            IF i + 1 = Player.pattern(startPat).note(Player.song.patternRow, j).instrument THEN
                COLOR LightMagenta, Blue
            END IF

            j = j + 1
        WEND

        LOCATE 5 + rowIdx, x: PRINT USING " ###: \                       \ ######## ##### ###### \     \ ########## #########  "; i + 1; Player.instrument(i).caption; Player.instrument(i).volume; Player.instrument(i).c2Spd; Player.instrument(i).length; _IIF(Player.instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP, "Yes", "No"); Player.instrument(i).loopStart; Player.instrument(i).loopEnd;

        rowIdx = rowIdx + 1
    NEXT

    j = 5 + rowIdx ' we starting updating from this line next
    x = 1 + WindowWidth \ 2 - PatternDisplayWidth \ 2 ' find x so that we can center everything

    ' Print the pattern header
    COLOR Blink, Cyan
    _PRINTSTRING (x, j), " PAT RW "
    i = 0
    WHILE i < Player.song.channels
        DIM chanBadge AS STRING: chanBadge = MODPlayer_GetChannelSubtypeCaption(Player, i)
        COLOR Blink, Cyan
        _PRINTSTRING (x + 8 + i * 19, j), " "
        SELECT CASE chanBadge
            CASE "[AM ]"
                COLOR Blink, Yellow
            CASE "[FMm]"
                COLOR Blink, LightMagenta
            CASE "[FMd]"
                COLOR Blink, LightRed
            CASE ELSE
                COLOR Blink, LightCyan
        END SELECT
        _PRINTSTRING (x + 8 + i * 19 + 1, j), chanBadge
        COLOR Blink, Cyan
        _PRINTSTRING (x + 8 + i * 19 + 6, j), " NOT S# FX OP "
        i = i + 1
    WEND

    DIM AS LONG startRow, nNote, nChan, nSample, nEffect, nOperand

    j = j + 1 ' move to the current line number

    ' Find the pattern and row we need to print
    startRow = Player.song.patternRow - (1 + UI_TEXT_LINE_MAX - j) \ 2
    IF startRow < 0 THEN
        IF startPat > 0 THEN
            startRow = Player.pattern(startPat - 1).rows + startRow
            startPat = startPat - 1
        ELSE
            startRow = 0
        END IF
    END IF

    ' Now just dump everything to the screen
    DIM AS LONG p, cLine: cLine = j + (1 + UI_TEXT_LINE_MAX - j) \ 2
    i = j
    WHILE i < UI_TEXT_LINE_MAX
        COLOR BrightWhite, Black

        IF startPat >= 0 _ANDALSO startPat < Player.song.patterns THEN
            IF i = cLine THEN
                COLOR BrightWhite, Blue
            END IF

            p = x

            LOCATE i, p: PRINT USING " ### ##:"; startPat; startRow;

            p = p + 8

            nChan = 0
            WHILE nChan < Player.song.channels
                COLOR LightCyan

                LOCATE i, p: PRINT USING " (##)"; nChan + 1;

                p = p + 5

                nNote = Player.pattern(startPat).note(startRow, nChan).note
                IF nNote = __MODPLAYER_NOTE_NONE THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "  -  "
                ELSEIF nNote = __MODPLAYER_NOTE_KEY_OFF THEN
                    COLOR Green
                    _PRINTSTRING (p, i), " ^^^ "
                ELSE
                    COLOR LightGreen
                    LOCATE i, p: PRINT USING " &# "; NoteTable(nNote MOD 12); 1 + nNote \ 12;
                END IF

                p = p + 5

                nSample = Player.pattern(startPat).note(startRow, nChan).instrument
                IF nSample = 0 THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "-- "
                ELSE
                    COLOR Yellow
                    LOCATE i, p: PRINT USING "## "; nSample;
                END IF

                p = p + 3

                nEffect = Player.pattern(startPat).note(startRow, nChan).effect
                nOperand = Player.pattern(startPat).note(startRow, nChan).operand

                IF nEffect = 0 _ANDALSO nOperand = 0 THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "-- "
                ELSE
                    COLOR LightMagenta
                    LOCATE i, p: PRINT RIGHT$("0" + HEX$(nEffect), 2); " ";
                END IF

                p = p + 3

                IF nOperand = 0 THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "-- "
                ELSE
                    COLOR LightRed
                    LOCATE i, p: PRINT RIGHT$("0" + HEX$(nOperand), 2); " ";
                END IF

                p = p + 3

                nChan = nChan + 1
            WEND
        ELSE
            _PRINTSTRING (x, i), SPACE$(PatternDisplayWidth)
        END IF

        startRow = startRow + 1
        ' Wrap if needed
        IF startPat < Player.song.patterns THEN
            IF startRow >= Player.pattern(startPat).rows THEN
                startRow = 0
                startPat = startPat + 1
            END IF
        END IF

        i = i + 1
    WEND

    j = i ' save the line number

    ' Print the footer
    COLOR Blink, White
    IF Player.song.isPaused THEN
        _PRINTSTRING (x, j), "   ||  :"
    ELSE
        _PRINTSTRING (x, j), "   >>  :"
    END IF

    i = 0
    WHILE i < Player.song.channels
        LOCATE j, x + 8 + i * 19: PRINT USING " (##) V:### B:+### "; i + 1; SoftSynth_GetVoiceVolume(Player.synth, i) * 100!; SoftSynth_GetVoiceBalance(Player.synth, i) * 100!;

        i = i + 1
    WEND

    ' Only re-allocate the array if Player.song.samplesPerTick has changed
    IF FFT.framesPerTick <> Player.song.framesPerTick THEN
        ' We need power of 2 for our FFT function
        FFT.frames = Math_RoundDownToPowerOf2(Player.song.framesPerTick)

        ' We need this too
        FFT.halfFrames = FFT.frames \ 2

        ' Get the count of bits that the FFT routine will need
        FFT.bits = Math_GetHighestSetBitIndex(FFT.frames)

        ' Setup the FFT arrays (half of fftSamples)
        REDIM AS _UNSIGNED INTEGER SpectrumAnalyzerL(0 TO FFT.halfFrames - 1), SpectrumAnalyzerR(0 TO FFT.halfFrames - 1)

        ' Save the frames / tick value
        FFT.framesPerTick = Player.song.framesPerTick
    END IF

    ' Calculate stereo FFT data
    AudioAnalyzer_CalculateFFT AnalyzerL, SpectrumAnalyzerL(), Player.synth.soundBuffer(), 0, 2, FFT.bits
    AudioAnalyzer_CalculateFFT AnalyzerR, SpectrumAnalyzerR(), Player.synth.soundBuffer(), 1, 2, FFT.bits

    COLOR Black, Black

    i = 0
    WHILE i < FFT.halfFrames
        j = 1 + (i * FFT.size.y) \ FFT.halfFrames ' this is the y location where we need to draw the bar

        ' First calculate and draw a bar on the left
        x = _SHR(SpectrumAnalyzerL(i), UI_ANALYZER_SCALE)
        IF x > 0 THEN ' only do something if x has a value > 0
            IF x > FFT.size.x THEN x = FFT.size.x
            p = FFT.size.x ' this is starting x position of the bar
            COLOR LightGreen + x MOD Brown, Black
            UI_DrawHorizontalLine p, j, p - x + 1, 254
        END IF

        ' Next calculate for the one on the right and draw
        x = _SHR(SpectrumAnalyzerR(i), UI_ANALYZER_SCALE)
        IF x > 0 THEN ' only do something if x has a value > 0
            IF x > FFT.size.x THEN x = FFT.size.x
            p = FFT.size.x + UI_TEXT_WIDTH_HEADER + 1 ' this is starting x position of the bar
            COLOR LightGreen + x MOD Brown, Black
            UI_DrawHorizontalLine p, j, p + x - 1, 254
        END IF

        i = i + 1
    WEND

    _DISPLAY ' flip the framebuffer
END SUB

''' @brief Renders compressed ANSI art onto a graphic image canvas.
''' @param img QB64 image handle to render onto.
''' @param s Decompressed ANSI text data string.
SUB UI_RenderTitleScreen (img AS LONG, s AS STRING)
    ' ANSI to QB SCREEN 0 color mapping table:
    ' ANSI 0 (Black), 1 (Red), 2 (Green), 3 (Yellow), 4 (Blue), 5 (Magenta), 6 (Cyan), 7 (White)
    STATIC ansi2qb(0 TO 7) AS _UNSIGNED _BYTE
    IF ansi2qb(White) = 0 THEN
        ansi2qb(0) = Black
        ansi2qb(1) = Red
        ansi2qb(2) = Green
        ansi2qb(3) = Brown
        ansi2qb(4) = Blue
        ansi2qb(5) = Magenta
        ansi2qb(6) = Cyan
        ansi2qb(7) = White
    END IF

    DIM oldDest AS LONG: oldDest = _DEST

    _DEST img

    DIM fg AS LONG: fg = White
    DIM bg AS LONG: bg = Black
    DIM bright AS _BYTE

    COLOR fg, bg

    DIM AS LONG col, row
    DIM l AS LONG: l = LEN(s)
    DIM i AS LONG: i = 1
    DIM imgW AS LONG: imgW = _WIDTH(img)

    WHILE i <= l
        DIM ch AS _UNSIGNED _BYTE: ch = ASC(s, i)

        SELECT CASE ch
            CASE _ASC_SUB ' Ctrl+Z / EOF
                EXIT WHILE

            CASE _ASC_ESC
                ' CSI SGR sequence?
                IF MID$(s, i + 1, 1) = "[" THEN

                    DIM j AS LONG
                    j = i + 2

                    DO WHILE j <= l
                        IF MID$(s, j, 1) = "m" THEN EXIT DO
                        j = j + 1
                    LOOP

                    IF j <= l THEN
                        DIM seq AS STRING
                        seq = MID$(s, i + 2, j - i - 2)

                        DIM token AS STRING
                        DIM p AS LONG

                        p = 1

                        DO
                            DIM sep AS LONG
                            sep = INSTR(p, seq, ";")

                            IF sep THEN
                                token = MID$(seq, p, sep - p)
                                p = sep + 1
                            ELSE
                                token = MID$(seq, p)
                            END IF

                            DIM code AS LONG
                            IF LEN(token) THEN
                                code = VAL(token)
                            ELSE
                                code = 0
                            END IF

                            SELECT CASE code
                                CASE 0
                                    fg = White
                                    bg = Black
                                    bright = 0

                                CASE 1
                                    bright = -1
                                    IF fg < 8 THEN fg = fg + 8

                                CASE 2, 22
                                    bright = 0
                                    IF fg > 7 THEN fg = fg - 8

                                CASE 30 TO 37
                                    fg = ansi2qb(code - 30)
                                    IF bright THEN fg = fg + 8

                                CASE 39
                                    fg = White
                                    IF bright THEN fg = fg + 8

                                CASE 40 TO 47
                                    bg = ansi2qb(code - 40)

                                CASE 49
                                    bg = Black

                                CASE 90 TO 97
                                    fg = ansi2qb(code - 90) + 8

                                CASE 100 TO 107
                                    bg = ansi2qb(code - 100) + 8
                            END SELECT

                            IF sep = 0 THEN EXIT DO
                        LOOP

                        COLOR fg, bg

                        i = j + 1
                        _CONTINUE
                    END IF
                END IF

                i = i + 1

            CASE _ASC_CR
                col = 0
                i = i + 1

            CASE _ASC_LF
                row = row + 1
                col = 0
                i = i + 1

            CASE ELSE
                IF ch <> _ASC_SPACE THEN ' Skip spaces to keep background transparent
                    _PRINTSTRING (1 + col, 1 + row), CHR$(ch)
                END IF

                col = col + 1

                IF col >= imgW THEN
                    col = 0
                    row = row + 1
                END IF

                i = i + 1
        END SELECT
    WEND

    _DEST oldDest
END SUB

''' @brief Runs the interactive welcome screen event loop.
''' @return Next application event code.
FUNCTION App_OnWelcomeScreen%%
    ' Welcome ANSI (144 x 90 chars)
    CONST SIZE_QB64MODPLAYER_ANS_15162& = 15162&
    CONST DATA_QB64MODPLAYER_ANS_15162 = _
        "eNqSjjbIlY42tDY2zlWgBAAoH6vbWKMYCD9fSA/fW+zQacjSbCFucbem6Iwcxp/MGriZTEJMGRv86u/v4WPiVIPn7oTzCsjy0PkwSZA10QCDarhM" + _
        "54rMiPRwctZ7a8ftZYTScdCHCk+ynAtWKJPJ3r12nRZ+iNrAmjjwwxUKU+DB3ggYAQKPRu0a5XXM9kIUjQzGoml21VAL+vkCCnqa3myjwP/4OEQ+" + _
        "RMbENC1QQ9O1mn6+6LQwZIELnTx1fW+11+q35Jfz909JpWpJi3Kk1Tg6zLTf7Uq68/KOXav38PzDc3kUqtt2KdAU1ABdDLKQeB1Qh+0CsG8WOm7E" + _
        "QAD9j4pGWAynjM6uk1g1bGxvQFAOSaFj/Kh+Ys8bH4fKBzOC0MLT5K3Z8zH/eyAbsiEbsiEbsiEbsiEbsiHbdWbzPY9Cdvh9pZjdpflnfRvPeoTh" + _
        "zl/98CtE7d4/GZZzyVeQPhPul8dDEXPLUoZyGlgoM06NP80df7vzj9bkvTUXnIk4aUFZKwFChUQHVVan198af/ivl4joy5Ozvly0phaz4L0hdeqK" + _
        "Ge8LPq9oDTXBqTaz1ZG0aTNH/li0Bqmn1photjUXqyoSGyxrPDVa8/rwobdmhitMBpoSQ6GueCzQGk+N1qQOP863JqRoDVLPsIYfDrw1i6sorlSE" + _
        "1iD11JpXqVWaNZo2mAzRGk+NNdQbb80iacpKN4hGa27VCLYPnKVANmRDNmRDNmQ7V73CFQrP9a8xERMxEdOfWxyGmlSAyBBCrSJIVkhEnIJQ4XSF" + _
        "BCgJtsoMuE64aoBVkEyJ2yoVYGgtptIywnkrfe6umNiWiiEgEgg3Cowl2rqcQaRVRRMBDWarJ+n2qS5rJZKDAiWE+084kzTtO4y3urj3OZ2KSAw0" + _
        "NLOWSmASaqUnxVREk+v4w1zqXBqNinXgshlSYAZInTBOSpw6pyvMVuOSlxa1nZvy3ubmZONFJtPtb/a2vqS/joeZz0+L2W4mybtQYSoafN5rr3tL" + _
        "sZVyFTBPN4ldofCbxO4ESkhr+5uDNmx8XW+3R9AZr4PTKal1pjqlYXEE48neer/b24R7X++D+Tzcag+gMh62Nx5BPpsvwJKYpzWsGIbEAc1mL1DD" + _
        "jJh1WT4etRvjQQfOhKPO5bKFH/tiycDAyDiBIYoBBJiZPZ18FcLcHU0NGJABAJPUQiY="

    SHARED Stars() AS Star
    SHARED Snakes() AS Snake

    ' Load the ANSI art data and render it to a text surface
    DIM titlePage AS LONG: titlePage = _NEWIMAGE(UI_TEXT_WIDTH_MIN, UI_TEXT_LINE_MAX, 0)
    UI_RenderTitleScreen titlePage, _INFLATE$(_BASE64DECODE$(DATA_QB64MODPLAYER_ANS_15162), SIZE_QB64MODPLAYER_ANS_15162)
    _CLEARCOLOR _ASC_SPACE + _SHL(White, 8), titlePage ' Set all blank cells to be transparent

    DIM bgType AS LONG: bgType = Math_GetRandomBetween(0, 1)

    DIM e AS _BYTE: e = APP_EVENT_NONE

    DO
        CLS , Black ' Clear the framebuffer to black color

        ' Draw the background
        SELECT CASE bgType
            CASE 1
                Snake_UpdateAndDraw Snakes()

            CASE ELSE
                Star_UpdateAndDraw Stars(), 1!
        END SELECT

        _PUTIMAGE , titlePage

        DIM k AS LONG: k = _KEYHIT

        IF k = _KEY_ESC THEN
            e = APP_EVENT_QUIT
        ELSEIF _TOTALDROPPEDFILES > 0 THEN
            e = APP_EVENT_DROP
        ELSEIF k = _KEY_F1 THEN
            e = APP_EVENT_LOAD
        ELSEIF k = _KEY_F2 THEN
            e = APP_EVENT_HTTP
        END IF

        _DISPLAY ' Flip the framebuffer

        _LIMIT APP_FRAME_RATE
    LOOP WHILE e = APP_EVENT_NONE

    _FREEIMAGE titlePage

    App_OnWelcomeScreen = e
END FUNCTION

''' @brief Loads note name string lookup table for UI display.
SUB Visualizer_InitializeNoteTable
    SHARED NoteTable() AS STRING * 2

    DIM AS _UNSIGNED _BYTE n, v
    RESTORE NoteTab
    READ v
    REDIM NoteTable(0 TO v - 1) AS STRING * 2
    FOR n = 0 TO v - 1
        READ NoteTable(n)
    NEXT

    ' Note string table for UI
    NoteTab:
    DATA 12
    DATA "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"
END SUB

''' @brief Dynamically resizes the console window based on song channel count.
SUB App_AdjustWindowSize
    SHARED Player AS MODPlayer
    SHARED WindowWidth AS LONG
    SHARED PatternDisplayWidth AS LONG
    SHARED FFT AS FFTInfo

    IF Player.song.isPlaying THEN
        PatternDisplayWidth = 8 + Player.song.channels * 19 ' find the actual width
        WindowWidth = PatternDisplayWidth
        IF WindowWidth < UI_TEXT_WIDTH_MIN THEN WindowWidth = UI_TEXT_WIDTH_MIN ' we don't want the width to be too small
        FFT.size.x = (WindowWidth - UI_TEXT_WIDTH_HEADER) \ 2
        IF PatternDisplayWidth <= UI_TEXT_WIDTH_HEADER THEN
            FFT.size.y = UI_TEXT_LINE_MAX
        ELSE
            FFT.size.y = 4 + _MIN(Player.song.instruments, UI_MAX_VISIBLE_INSTRUMENTS)
        END IF
    ELSE
        PatternDisplayWidth = 0
        WindowWidth = UI_TEXT_WIDTH_MIN ' we don't want the width to be too small
        FFT.size.x = 0
        FFT.size.y = 0
    END IF

    WIDTH WindowWidth, UI_TEXT_LINE_MAX ' we need 75 lines for the vizualization stuff
    _CONTROLCHR OFF ' turn off control characters
    _FONT 8 ' force 8x8 pixel font
    _BLINK OFF ' we want high intensity colors
    CLS ' clear the screen
    LOCATE , , _FALSE ' turn cursor off
END SUB

''' @brief Loads and plays a module file, handling UI redraw and user input loop.
''' @param fileName File path or URL to play.
''' @return Next application event code.
FUNCTION App_OnPlayTune%% (fileName AS STRING)
    SHARED Player AS MODPlayer
    SHARED InstrumentScrollOffset AS LONG

    InstrumentScrollOffset = 0 ' reset scroll position on song load
    App_OnPlayTune = APP_EVENT_PLAY ' default event is to play next song

    DIM buffer AS STRING
    DIM success AS _BYTE

    IF _FILEEXISTS(fileName) THEN
        success = MODPlayer_LoadFromDisk(Player, fileName)
    ELSE
        buffer = File_Load(fileName)
        success = MODPlayer_LoadFromMemory(Player, buffer)
    END IF

    IF NOT success THEN
        _MESSAGEBOX APP_NAME, "Failed to load: " + fileName, "error"

        EXIT FUNCTION
    END IF

    ' Set the app _TITLE to display the file name
    DIM windowTitle AS STRING
    IF LEN(Pathname_GetDriveOrScheme(fileName)) > 2 THEN
        windowTitle = App_GetSaveFileName(fileName) + " - " + APP_NAME
    ELSE
        windowTitle = Pathname_GetFileName(fileName) + " - " + APP_NAME
    END IF
    _TITLE windowTitle

    MODPlayer_Play Player
    App_AdjustWindowSize

    DIM AS LONG k

    DO
        MODPlayer_Update Player, SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT

        Visualizer_Draw

        k = _KEYHIT

        SELECT CASE k
            CASE _KEY_ESC
                EXIT DO

            CASE KEY_SPACE
                Player.song.isPaused = NOT Player.song.isPaused

            CASE KEY_PLUS, KEY_EQUAL
                SoftSynth_SetMasterVolume Player.synth, SoftSynth_GetMasterVolume(Player.synth) + APP_VOLUME_STEP

            CASE KEY_MINUS, KEY_UNDERSCORE
                SoftSynth_SetMasterVolume Player.synth, SoftSynth_GetMasterVolume(Player.synth) - APP_VOLUME_STEP

            CASE KEY_UPPER_L, KEY_LOWER_L
                MODPlayer_Loop Player, NOT MODPlayer_IsLooping(Player)

            CASE _KEY_LEFT
                MODPlayer_GoToPreviousPosition Player

            CASE _KEY_RIGHT
                MODPlayer_GoToNextPosition Player

            CASE _KEY_UP
                IF InstrumentScrollOffset > 0 THEN InstrumentScrollOffset = InstrumentScrollOffset - 1

            CASE _KEY_DOWN
                IF InstrumentScrollOffset < Player.song.instruments - UI_MAX_VISIBLE_INSTRUMENTS THEN
                    InstrumentScrollOffset = InstrumentScrollOffset + 1
                END IF

            CASE _KEY_PAGEUP
                InstrumentScrollOffset = InstrumentScrollOffset - 10
                IF InstrumentScrollOffset < 0 THEN InstrumentScrollOffset = 0

            CASE _KEY_PAGEDOWN
                DIM maxScrollDown AS LONG: maxScrollDown = Player.song.instruments - UI_MAX_VISIBLE_INSTRUMENTS
                IF maxScrollDown < 0 THEN maxScrollDown = 0
                InstrumentScrollOffset = InstrumentScrollOffset + 10
                IF InstrumentScrollOffset > maxScrollDown THEN InstrumentScrollOffset = maxScrollDown

            CASE _KEY_HOME
                InstrumentScrollOffset = 0

            CASE _KEY_END
                DIM maxScrollEnd AS LONG: maxScrollEnd = Player.song.instruments - UI_MAX_VISIBLE_INSTRUMENTS
                IF maxScrollEnd < 0 THEN maxScrollEnd = 0
                InstrumentScrollOffset = maxScrollEnd

            CASE _KEY_F1
                App_OnPlayTune = APP_EVENT_LOAD
                EXIT DO

            CASE _KEY_F6 ' quick save for files loaded from ModArchive
                IF LEN(buffer) = 0 THEN buffer = File_Load(fileName)
                App_QuickSave buffer, fileName

            CASE 21248 ' Shift + Delete - you known what it does
                IF LEN(Pathname_GetDriveOrScheme(fileName)) > 2 THEN
                    _MESSAGEBOX APP_NAME, "You cannot delete " + fileName + "!", "error"
                ELSE
                    IF _MESSAGEBOX(APP_NAME, "Are you sure you want to delete " + fileName + " permanently?", "yesno", "question", 0) = 1 THEN
                        KILL fileName
                        EXIT DO
                    END IF
                END IF
        END SELECT

        IF _TOTALDROPPEDFILES > 0 THEN
            App_OnPlayTune = APP_EVENT_DROP

            EXIT DO
        END IF

        _LIMIT APP_FRAME_RATE
    LOOP WHILE MODPlayer_IsPlaying(Player)

    MODPlayer_Stop Player
    App_AdjustWindowSize

    _TITLE APP_NAME + _CHR_SPACE + _OS$ ' Set app title to the way it was
END FUNCTION

''' @brief Processes files passed via the application command-line arguments.
''' @return Next application event code.
FUNCTION App_OnCommandLine%%
    DIM e AS _BYTE: e = APP_EVENT_NONE

    IF (COMMAND$(1) = "/?" _ORELSE COMMAND$(1) = "-?") THEN
        _MESSAGEBOX APP_NAME, APP_NAME + _STR_LF + "Syntax: " + Pathname_GetFileName(COMMAND$(0)) + " [modfile.mod / .s3m / .mtm / .far]" + _STR_LF + "    /?: Shows this message" + _STR_LF + _STR_LF + "Copyright (c) 2024, Samuel Gomes" + _STR_LF + _STR_LF + "https://github.com/a740g/", "info"
        e = APP_EVENT_QUIT
    ELSE
        DIM i AS LONG: FOR i = 1 TO _COMMANDCOUNT
            e = App_OnPlayTune(COMMAND$(i))
            IF e <> APP_EVENT_PLAY THEN EXIT FOR
        NEXT
    END IF

    App_OnCommandLine = e
END FUNCTION

''' @brief Processes files drag-and-dropped onto the application window.
''' @return Next application event code.
FUNCTION App_OnDroppedFiles%%
    ' Make a copy of the dropped file and clear the list
    REDIM fileNames(1 TO _TOTALDROPPEDFILES) AS STRING

    DIM e AS _BYTE: e = APP_EVENT_NONE

    DIM i AS LONG: FOR i = 1 TO _TOTALDROPPEDFILES
        fileNames(i) = _DROPPEDFILE$(i)
    NEXT
    _FINISHDROP ' This is critical

    ' Now play the dropped file one at a time
    FOR i = LBOUND(fileNames) TO UBOUND(fileNames)
        e = App_OnPlayTune(fileNames(i))
        IF e <> APP_EVENT_PLAY THEN EXIT FOR
    NEXT

    App_OnDroppedFiles = e
END FUNCTION

''' @brief Displays file open dialog and plays user-selected files.
''' @return Next application event code.
FUNCTION App_OnSelectedFiles%%
    DIM ofdList AS STRING
    DIM e AS _BYTE: e = APP_EVENT_NONE

    ofdList = _OPENFILEDIALOG$(APP_NAME, , "*.mod|*.MOD|*.Mod|*.mtm|*.MTM|*.Mtm|*.s3m|*.S3M|*.S3m|*.far|*.FAR|*.Far", "Music Tracker Files", _TRUE)

    IF LEN(ofdList) = 0 THEN EXIT FUNCTION

    REDIM fileNames(0 TO 0) AS STRING

    DIM j AS LONG: j = String_Tokenize(ofdList, "|", _STR_LF, _FALSE, fileNames())

    DIM i AS LONG: FOR i = 0 TO j - 1
        e = App_OnPlayTune(fileNames(i))
        IF e <> APP_EVENT_PLAY THEN EXIT FOR
    NEXT

    App_OnSelectedFiles = e
END FUNCTION

''' @brief Downloads and plays random tunes streamed from modarchive.org.
''' @return Next application event code.
FUNCTION App_OnModArchiveFiles%%
    DIM e AS _BYTE: e = APP_EVENT_NONE
    DIM AS STRING modArchiveFileName, fileExtension

    DO
        DO
            IF _TOTALDROPPEDFILES > 0 THEN
                e = APP_EVENT_DROP
                EXIT DO
            ELSEIF _KEYHIT = _KEY_F1 THEN
                e = APP_EVENT_LOAD
                EXIT DO
            END IF

            modArchiveFileName = ModArchive_GetRandomFileName$
            fileExtension = LCASE$(Pathname_GetFileExtension(modArchiveFileName))

            _TITLE "Downloading: " + App_GetSaveFileName(modArchiveFileName) + " - " + APP_NAME
        LOOP UNTIL fileExtension = ".mod" _ORELSE fileExtension = ".mtm" _ORELSE fileExtension = ".s3m" _ORELSE fileExtension = ".far"

        e = App_OnPlayTune(modArchiveFileName)
    LOOP WHILE e = APP_EVENT_NONE _ORELSE e = APP_EVENT_PLAY

    _TITLE APP_NAME + _CHR_SPACE + _OS$ ' Set app title to the way it was

    App_OnModArchiveFiles = e
END FUNCTION

''' @brief Scrapes modarchive.org for a random module download URL.
''' @return Direct module download URL string.
FUNCTION ModArchive_GetRandomFileName$
    DIM buffer AS STRING: buffer = File_LoadFromURL("https://modarchive.org/index.php?request=view_random")
    DIM bufPos AS LONG: bufPos = INSTR(buffer, "https://api.modarchive.org/downloads.php?moduleid=")

    IF bufPos > 0 THEN
        ModArchive_GetRandomFileName = MID$(buffer, bufPos, INSTR(bufPos, buffer, _CHR_QUOTE) - bufPos)
    END IF
END FUNCTION

''' @brief Derives a sanitized local filename from a Mod Archive URL.
''' @param url Download URL string.
''' @return Sanitized filename string.
FUNCTION App_GetSaveFileName$ (url AS STRING)
    DIM saveFileName AS STRING: saveFileName = Pathname_GetFileName(url)
    App_GetSaveFileName = Pathname_Sanitize(MID$(saveFileName, INSTR(saveFileName, "=") + 1)) ' this will get a file name of type: 12312313#filename.mod
END FUNCTION

''' @brief Prompts user and saves a downloaded module buffer to disk.
''' @param buffer Binary file data to save.
''' @param url Source URL used to generate destination filename.
SUB App_QuickSave (buffer AS STRING, url AS STRING)
    STATIC savePath AS STRING, alwaysUseSamePath AS _BYTE, stopNagging AS _BYTE

    IF LEN(Pathname_GetDriveOrScheme(url)) > 2 THEN
        ' This is a file from the web
        IF NOT _DIREXISTS(savePath) _ORELSE NOT alwaysUseSamePath THEN ' only get the path if path does not exist or user wants to use a new path
            savePath = _SELECTFOLDERDIALOG$("Select a folder to save the file:", savePath)
            IF LEN(savePath) = 0 THEN EXIT SUB ' exit if user cancelled

            savePath = Pathname_AddDirectorySeparator(savePath)
        END IF

        DIM saveFileName AS STRING: saveFileName = savePath + App_GetSaveFileName(url)

        IF _FILEEXISTS(saveFileName) THEN
            IF _MESSAGEBOX(APP_NAME, "Overwrite " + saveFileName + "?", "yesno", "warning", 0) = 0 THEN EXIT SUB
        END IF

        IF File_Save(buffer, saveFileName, _TRUE) THEN _MESSAGEBOX APP_NAME, saveFileName + " saved.", "info"

        ' Check if user want to use the same path in the future
        IF NOT stopNagging THEN
            SELECT CASE _MESSAGEBOX(APP_NAME, "Do you want to use " + savePath + " for future saves?", "yesnocancel", "question", 1)
                CASE 0
                    stopNagging = _TRUE
                CASE 1
                    alwaysUseSamePath = _TRUE
                CASE 2
                    alwaysUseSamePath = _FALSE
            END SELECT
        END IF
    ELSE
        ' This is a local file - do nothing
        _MESSAGEBOX APP_NAME, "You cannot save local file " + url + "!", "error"
    END IF
END SUB

''' @brief Initializes star positions and colors for background starfield effect.
''' @param stars() Array of Star structures to initialize.
SUB Star_InitializeAll (stars() AS Star)
    CONST Z_DIVIDER = 4096!

    DIM L AS LONG: L = LBOUND(stars)
    DIM U AS LONG: U = UBOUND(stars)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    DIM i AS LONG
    FOR i = L TO U
        stars(i).p.x = Math_GetRandomBetween(1, W)
        stars(i).p.y = Math_GetRandomBetween(1, H)
        stars(i).p.z = Z_DIVIDER
        stars(i).c = Math_GetRandomBetween(9, 15)
    NEXT i
END SUB

''' @brief Updates starfield positions and renders stars on screen.
''' @param stars() Array of Star structures.
''' @param speed Forward star travel speed.
SUB Star_UpdateAndDraw (stars() AS Star, speed AS SINGLE)
    CONST Z_DIVIDER = 4096!
    CONST STAR_249 = CHR$(249)
    CONST STAR_7 = CHR$(7)
    CONST STAR_43 = CHR$(43)
    CONST STAR_120 = CHR$(120)
    CONST STAR_42 = CHR$(42)

    DIM L AS LONG: L = LBOUND(stars)
    DIM U AS LONG: U = UBOUND(stars)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT
    DIM W_Half AS LONG: W_Half = W \ 2
    DIM H_Half AS LONG: H_Half = H \ 2

    DIM i AS LONG
    FOR i = L TO U
        IF stars(i).p.x < 1 _ORELSE _CAST(LONG, stars(i).p.x) > W _ORELSE stars(i).p.y < 1 _ORELSE _CAST(LONG, stars(i).p.y) > H THEN
            stars(i).p.x = Math_GetRandomBetween(1, W)
            stars(i).p.y = Math_GetRandomBetween(1, H)
            stars(i).p.z = Z_DIVIDER
            stars(i).c = Math_GetRandomBetween(9, 15)
        END IF

        COLOR stars(i).c, Black

        SELECT CASE stars(i).p.z
            CASE IS < 4119!
                _PRINTSTRING (stars(i).p.x, stars(i).p.y), STAR_249

            CASE IS < 4149!
                _PRINTSTRING (stars(i).p.x, stars(i).p.y), STAR_7

            CASE IS < 4166!
                _PRINTSTRING (stars(i).p.x, stars(i).p.y), STAR_43

            CASE IS < 4190!
                _PRINTSTRING (stars(i).p.x, stars(i).p.y), STAR_120

            CASE ELSE
                _PRINTSTRING (stars(i).p.x, stars(i).p.y), STAR_42

        END SELECT

        stars(i).p.z = stars(i).p.z + speed
        stars(i).a = stars(i).a + 0.01!
        DIM zd AS SINGLE: zd = stars(i).p.z / Z_DIVIDER
        stars(i).p.x = ((stars(i).p.x - W_Half) * zd) + W_Half + COS(stars(i).a * 0.5!) * 0.5!
        stars(i).p.y = ((stars(i).p.y - H_Half) * zd) + H_Half + SIN(stars(i).a * 1.5!) * 0.5!
    NEXT i
END SUB

''' @brief Initializes bouncing snake positions and colors.
''' @param snakes() Array of Snake structures to initialize.
SUB Snake_InitializeAll (snakes() AS Snake)
    CONST SNAKE_SIZE_MIN = 5
    CONST SNAKE_SIZE_MAX = 25

    DIM L AS LONG: L = LBOUND(snakes)
    DIM U AS LONG: U = UBOUND(snakes)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    DIM i AS LONG
    FOR i = L TO U
        snakes(i).p = SPACE$(Math_GetRandomBetween(SNAKE_SIZE_MIN, SNAKE_SIZE_MAX) * 2)
        snakes(i).s = 0.1! + RND * 0.9!
        snakes(i).c = Math_GetRandomBetween(1, 8)
        Vector2i_Initialize Math_GetRandomBetween(0, 1) * 2 - 1, Math_GetRandomBetween(0, 1) * 2 - 1, snakes(i).d ' -1 or 1

        DIM size AS LONG: size = LEN(snakes(i).p)
        DIM x AS LONG: x = Math_GetRandomBetween(1, W)
        DIM y AS LONG: y = Math_GetRandomBetween(1, H)

        DIM j AS LONG
        FOR j = 1 TO size STEP 2
            ASC(snakes(i).p, j) = x
            ASC(snakes(i).p, j + 1) = y
        NEXT j
    NEXT i
END SUB

''' @brief Updates snake segments and renders bouncing snakes on screen.
''' @param snakes() Array of Snake structures.
SUB Snake_UpdateAndDraw (snakes() AS Snake)
    CONST SNAKE_HEAD = CHR$(15)
    CONST SNAKE_BODY = CHR$(254)

    DIM L AS LONG: L = LBOUND(snakes)
    DIM U AS LONG: U = UBOUND(snakes)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    DIM i AS LONG
    FOR i = L TO U
        snakes(i).t = snakes(i).t + snakes(i).s

        DIM p AS Vector2i
        DIM s AS LONG: s = LEN(snakes(i).p)

        ' Only run movement code when it is time to move
        IF snakes(i).t > 1! THEN
            snakes(i).t = 0!

            ' Get the position of the head and add velocity
            Vector2i_AddXY snakes(i).d, ASC(snakes(i).p, 1), ASC(snakes(i).p, 2), p

            IF p.x < 1 _ORELSE p.x > W THEN Vector2i_FlipHorizontal snakes(i).d, snakes(i).d
            IF p.y < 1 _ORELSE p.y > H THEN Vector2i_FlipVertical snakes(i).d, snakes(i).d

            DIM j AS LONG: j = s - 2
            WHILE j > 0
                ASC(snakes(i).p, j + 2) = ASC(snakes(i).p, j)
                j = j - 1
            WEND
            ASC(snakes(i).p, 1) = ASC(snakes(i).p, 1) + snakes(i).d.x
            ASC(snakes(i).p, 2) = ASC(snakes(i).p, 2) + snakes(i).d.y

            IF Math_GetRandomBetween(1, 100) <= 5 THEN ' change direction with a 5% chance
                DO
                    Vector2i_Initialize Math_GetRandomBetween(-1, 1), Math_GetRandomBetween(-1, 1), snakes(i).d
                LOOP WHILE Vector2i_IsNull(snakes(i).d)
            END IF
        END IF

        j = s - 2
        WHILE j > 2
            p.y = ASC(snakes(i).p, j)
            j = j - 1
            p.x = ASC(snakes(i).p, j)
            j = j - 1

            COLOR snakes(i).c, Black
            _PRINTSTRING (p.x, p.y), SNAKE_BODY
        WEND

        p.x = ASC(snakes(i).p, 1)
        p.y = ASC(snakes(i).p, 2)

        COLOR snakes(i).c, Black
        _PRINTSTRING (p.x, p.y), SNAKE_HEAD
    NEXT i
END SUB

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Frankenstein retro TUI with drag & drop support
'-----------------------------------------------------------------------------------------------------------------------
_TITLE APP_NAME + _CHR_SPACE + _OS$ ' set the program name in the titlebar
CHDIR _STARTDIR$ ' change to the directory specifed by the environment
_ACCEPTFILEDROP ' enable drag and drop of files
Visualizer_InitializeNoteTable ' initialize note string table
App_AdjustWindowSize ' set the initial window size
_ALLOWFULLSCREEN _SQUAREPIXELS , _SMOOTH ' allow the user to press Alt+Enter to go fullscreen
RANDOMIZE TIMER
Star_InitializeAll Stars()
Snake_InitializeAll Snakes()

DIM event AS _BYTE: event = APP_EVENT_CMDS ' default to command line event first

' Main loop
DO
    SELECT CASE event
        CASE APP_EVENT_QUIT
            EXIT DO

        CASE APP_EVENT_DROP
            event = App_OnDroppedFiles

        CASE APP_EVENT_LOAD
            event = App_OnSelectedFiles

        CASE APP_EVENT_CMDS
            event = App_OnCommandLine

        CASE APP_EVENT_HTTP
            event = App_OnModArchiveFiles

        CASE ELSE
            event = App_OnWelcomeScreen
    END SELECT
LOOP

_AUTODISPLAY

SYSTEM
