'-----------------------------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/BitwiseOps.bi'
'$INCLUDE:'include/Pathname.bi'
'$INCLUDE:'include/File.bi'
'$INCLUDE:'include/StringOps.bi'
'$INCLUDE:'include/AudioAnalyzerFFT.bi'
'$INCLUDE:'include/MODPlayer.bi'
'$INCLUDE:'include/Base64.bi'
'$INCLUDE:'include/ANSIPrint.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$RESIZE:SMOOTH
$EXEICON:'./QB64MODPlayer.ico'
$VERSIONINFO:CompanyName='Samuel Gomes'
$VERSIONINFO:FileDescription='QB64 MOD Player executable'
$VERSIONINFO:InternalName='QB64MODPlayer'
$VERSIONINFO:LegalCopyright='Copyright (c) 2024 Samuel Gomes'
$VERSIONINFO:LegalTrademarks='All trademarks are property of their respective owners'
$VERSIONINFO:OriginalFilename='QB64MODPlayer.exe'
$VERSIONINFO:ProductName='QB64 MOD Player'
$VERSIONINFO:Web='https://github.com/a740g'
$VERSIONINFO:Comments='https://github.com/a740g'
$VERSIONINFO:FILEVERSION#=2,1,3,0
$VERSIONINFO:PRODUCTVERSION#=2,1,3,0
$COLOR:0
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
CONST APP_NAME = "QB64 MOD Player" ' application name
' We'll use a window with 1152 x 720 px (144 x 90 chars @ 8 x 8 px font) client area
CONST TEXT_WIDTH_MIN& = 144& ' minimum width we need
CONST TEXT_LINE_MAX& = 90& ' this the number of lines we need
CONST TEXT_WIDTH_HEADER& = 84& ' width of the main header on the vis screen
CONST MAX_VISIBLE_INSTRUMENTS& = 64& ' maximum number of instruments visible at a time
CONST ANALYZER_SCALE& = 9& ' this is used to scale the fft values
CONST FRAME_RATE& = 60& ' update frame rate
CONST VOLUME_STEP! = 0.01! ' the amount by which the audio volume is increased or decreased
' Program events
CONST EVENT_NONE%% = 0%% ' idle
CONST EVENT_QUIT%% = 1%% ' user wants to quit
CONST EVENT_CMDS%% = 2%% ' process command line
CONST EVENT_LOAD%% = 3%% ' user want to load files
CONST EVENT_DROP%% = 4%% ' user dropped files
CONST EVENT_PLAY%% = 5%% ' play next song
CONST EVENT_HTTP%% = 6%% ' Downloads and plays random MODs from modarchive.org
' Background constants
CONST STAR_COUNT& = 256& ' the maximum stars that we can show
CONST SNAKE_COUNT& = 48& ' the maximum snakes we can draw on the screen
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'-----------------------------------------------------------------------------------------------------------------------
TYPE StarType
    p AS Vector3FType ' position
    a AS SINGLE ' angle
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE SnakeType
    p AS STRING ' position buffer (x = 1 byte, y = 1 byte)
    s AS SINGLE ' speed
    t AS SINGLE ' movement counter
    d AS Vector2LType ' direction
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE FFTType
    framesPerTick AS LONG
    frames AS LONG
    halfFrames AS LONG
    bits AS LONG
    size AS Vector2LType
END TYPE
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
REDIM SHARED NoteTable(0 TO 0) AS STRING * 2 ' this contains the note stings
DIM SHARED WindowWidth AS LONG ' the width of our windows in characters
DIM SHARED PatternDisplayWidth AS LONG ' the width of the pattern display in characters
DIM SHARED FFT AS FFTType ' global FFT info
REDIM AS _UNSIGNED INTEGER SpectrumAnalyzerL(0 TO 0), SpectrumAnalyzerR(0 TO 0) ' left & right channel FFT data
DIM Stars(1 TO STAR_COUNT) AS StarType
DIM Snakes(1 TO SNAKE_COUNT) AS SnakeType
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Frankenstein retro TUI with drag & drop support
'-----------------------------------------------------------------------------------------------------------------------
_TITLE APP_NAME + " " + _OS$ ' set the program name in the titlebar
CHDIR _STARTDIR$ ' change to the directory specifed by the environment
_ACCEPTFILEDROP ' enable drag and drop of files
InitializeNoteTable ' initialize note string table
AdjustWindowSize ' set the initial window size
_ALLOWFULLSCREEN _SQUAREPIXELS , _SMOOTH ' allow the user to press Alt+Enter to go fullscreen
Math_SetRandomSeed TIMER ' seed RNG
InitializeStars Stars()
InitializeSnakes Snakes()

DIM event AS _BYTE: event = EVENT_CMDS ' default to command line event first

' Main loop
DO
    SELECT CASE event
        CASE EVENT_QUIT
            EXIT DO

        CASE EVENT_DROP
            event = OnDroppedFiles

        CASE EVENT_LOAD
            event = OnSelectedFiles

        CASE EVENT_CMDS
            event = OnCommandLine

        CASE EVENT_HTTP
            event = OnModArchiveFiles

        CASE ELSE
            event = OnWelcomeScreen
    END SELECT
LOOP

_AUTODISPLAY
SYSTEM
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------
' This displays the current playing MODs visualization on the screen
SUB DrawVisualization
    SHARED AS _UNSIGNED INTEGER SpectrumAnalyzerL(), SpectrumAnalyzerR()

    ' These are internal variables and arrays used by the MODPlayer library and are used for showing internal info and visualization
    ' In a general use case, accessing these directly is not required at all
    SHARED __Song AS __SongType
    SHARED __Order() AS _UNSIGNED INTEGER
    SHARED __Pattern() AS __NoteType
    SHARED __Instrument() AS __InstrumentType
    SHARED __SoftSynth_SoundBuffer() AS SINGLE

    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then __Order(__Song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    IF __Song.orderPosition >= __Song.orders THEN EXIT SUB

    DIM startPat AS LONG: startPat = __Order(__Song.orderPosition)

    IF startPat >= __Song.patterns THEN EXIT SUB ' this can happen when S3M tunes contain marker / end-of-song patterns

    CLS , Black ' clear the framebuffer to black color

    DIM x AS LONG: x = 1 + WindowWidth \ 2 - TEXT_WIDTH_HEADER \ 2 ' find x so that we can center everything

    ' Print song type and name
    COLOR BrightWhite, Magenta
    _PRINTSTRING (x, 1), String_FormatString(__Song.subtype, "  %-4.4s: ") + String_FormatString(__Song.caption, "%-74.74s  ")

    ' Print the header
    COLOR Blink, BrightWhite
    _PRINTSTRING (x, 2), String_FormatLong(__Song.orderPosition, "  ORD: %3d / ") + _
        String_FormatLong(__Song.orders - 1, "%3d | ") + _
        String_FormatLong(startPat, "PAT: %3d / ") + _
        String_FormatLong(__Song.patterns - 1, "%3d | ") + _
        String_FormatLong(__Song.patternRow, "ROW: %2d / 63 | ") + _
        String_FormatLong(__Song.activeChannels, "CHN: %3d / ") + _
        String_FormatLong(__Song.channels, "%3d | ") + _
        String_FormatLong(SoftSynth_GetActiveVoices, "VOC: %3d / ") + _
        String_FormatLong(SoftSynth_GetTotalVoices, "%3d  ")

    _PRINTSTRING (x, 3), String_FormatLong(__Song.bpm, "  BPM: %3d       | ") + _
        String_FormatLong(__Song.speed, "SPD: %3d       | ") + _
        String_FormatSingle(SoftSynth_GetMasterVolume * 100!, "VOL: %3.0f%%    | ") + _
        String_FormatDouble(SoftSynth_GetBufferedSoundTime * 1000#, "BUF: %7.0fms | ") + _
        String_FormatString(String_FormatBoolean(__Song.isLooping, 4), "REP: %-9.9s  ")

    ' Print the sample list header
    COLOR Blink, Cyan
    _PRINTSTRING (x, 4), "  S#  SAMPLE-NAME                 VOLUME C2SPD LENGTH LOOPING LOOP-START LOOP-STOP  "

    ' Print the sample information
    DIM AS LONG i, j
    WHILE i < __Song.instruments
        COLOR Yellow, Black

        j = 0
        WHILE j < __Song.channels
            IF i + 1 = __Pattern(startPat, __Song.patternRow, j).instrument THEN
                COLOR LightMagenta, Blue
            END IF

            j = j + 1
        WEND

        _PRINTSTRING (x, 5 + i), String_FormatLong(i + 1, " %3d: ") + _
            String_FormatString(__Instrument(i).caption, "%-25.25s ") + _
            String_FormatLong(__Instrument(i).volume, "%8d ") + _
            String_FormatLong(__Instrument(i).c2Spd, "%5d ") + _
            String_FormatLong(__Instrument(i).length, "%6d ") + _
            String_FormatString(String_FormatBoolean(__Instrument(i).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP, 6), "%-7.7s ") + _
            String_FormatLong(__Instrument(i).loopStart, "%10d ") + _
            String_FormatLong(__Instrument(i).loopEnd, "%9d  ")

        i = i + 1

        IF i >= MAX_VISIBLE_INSTRUMENTS THEN EXIT WHILE ' FIXME: allow user to scroll and see the entire instrument list
    WEND

    j = 5 + i ' we starting updating from this line next
    x = 1 + WindowWidth \ 2 - PatternDisplayWidth \ 2 ' find x so that we can center everything

    ' Print the pattern header
    COLOR Blink, Cyan
    _PRINTSTRING (x, j), " PAT RW "
    i = 0
    WHILE i < __Song.channels
        _PRINTSTRING (x + 8 + i * 19, j), " CHAN NOT S# FX OP "
        i = i + 1
    WEND

    DIM AS LONG startRow, nNote, nChan, nSample, nEffect, nOperand

    j = j + 1 ' move to the current line number

    ' Find the pattern and row we need to print
    startRow = __Song.patternRow - (1 + TEXT_LINE_MAX - j) \ 2
    IF startRow < 0 THEN
        startRow = __Song.rows + startRow
        startPat = startPat - 1
    END IF

    ' Now just dump everything to the screen
    DIM AS LONG p, cLine: cLine = j + (1 + TEXT_LINE_MAX - j) \ 2
    i = j
    WHILE i < TEXT_LINE_MAX
        COLOR BrightWhite, Black

        IF startPat >= 0 AND startPat < __Song.patterns THEN
            IF i = cLine THEN
                COLOR BrightWhite, Blue
            END IF

            p = x

            _PRINTSTRING (p, i), String_FormatLong(startPat, " %3d ") + String_FormatLong(startRow, "%2d:")

            p = p + 8

            nChan = 0
            WHILE nChan < __Song.channels
                COLOR LightCyan

                _PRINTSTRING (p, i), String_FormatLong(nChan + 1, " (%2d)")

                p = p + 5

                nNote = __Pattern(startPat, startRow, nChan).note
                IF nNote = __NOTE_NONE THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "  -  "
                ELSEIF nNote = __NOTE_KEY_OFF THEN
                    COLOR Green
                    _PRINTSTRING (p, i), " ^^^ "
                ELSE
                    COLOR LightGreen
                    _PRINTSTRING (p, i), String_FormatLong(1 + nNote \ 12, " " + NoteTable(nNote MOD 12) + "%1d")
                END IF

                p = p + 5

                nSample = __Pattern(startPat, startRow, nChan).instrument
                IF nSample = 0 THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "-- "
                ELSE
                    COLOR Yellow
                    _PRINTSTRING (p, i), String_FormatLong(nSample, "%.2i ")
                END IF

                p = p + 3

                nEffect = __Pattern(startPat, startRow, nChan).effect
                nOperand = __Pattern(startPat, startRow, nChan).operand

                IF nEffect = 0 AND nOperand = 0 THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "-- "
                ELSE
                    COLOR LightMagenta
                    _PRINTSTRING (p, i), String_FormatLong(nEffect, "%.2X ")
                END IF

                p = p + 3

                IF nOperand = 0 THEN
                    COLOR Gray
                    _PRINTSTRING (p, i), "-- "
                ELSE
                    COLOR LightRed
                    _PRINTSTRING (p, i), String_FormatLong(nOperand, "%.2X ")
                END IF

                p = p + 3

                nChan = nChan + 1
            WEND
        ELSE
            _PRINTSTRING (x, i), SPACE$(PatternDisplayWidth)
        END IF

        startRow = startRow + 1
        ' Wrap if needed
        IF startRow >= __Song.rows THEN
            startRow = 0
            startPat = startPat + 1
        END IF

        i = i + 1
    WEND

    j = i ' save the line number

    ' Print the footer
    COLOR Blink, White
    IF __Song.isPaused THEN
        _PRINTSTRING (x, j), "   ||  :"
    ELSE
        _PRINTSTRING (x, j), "   >>  :"
    END IF

    i = 0
    WHILE i < __Song.channels
        _PRINTSTRING (x + 8 + i * 19, j), String_FormatLong(i + 1, " (%2i)") + _
            String_FormatSingle(SoftSynth_GetVoiceVolume(i) * 100.0!, " V:%3.0f") + _
            String_FormatSingle(SoftSynth_GetVoiceBalance(i) * 100.0!, " B:%+4.0f ")

        i = i + 1
    WEND

    ' Only re-allocate the array if __Song.samplesPerTick has changed
    IF FFT.framesPerTick <> __Song.framesPerTick THEN
        ' We need power of 2 for our FFT function
        FFT.frames = Math_RoundDownLongToPowerOf2(__Song.framesPerTick)

        ' We need this too
        FFT.halfFrames = FFT.frames \ 2

        ' Get the count of bits that the FFT routine will need
        FFT.bits = LeftShiftOneCount(FFT.frames)

        ' Setup the FFT arrays (half of fftSamples)
        REDIM AS _UNSIGNED INTEGER SpectrumAnalyzerL(0 TO FFT.halfFrames - 1), SpectrumAnalyzerR(0 TO FFT.halfFrames - 1)

        ' Save the frames / tick value
        FFT.framesPerTick = __Song.framesPerTick
    END IF

    ' Get the FFT data and ignore the audio intensity level (for now)
    DIM ignored AS SINGLE
    ignored = AudioAnalyzerFFT_DoSingle(SpectrumAnalyzerL(0), __SoftSynth_SoundBuffer(0), 2, FFT.bits)
    ignored = AudioAnalyzerFFT_DoSingle(SpectrumAnalyzerR(0), __SoftSynth_SoundBuffer(1), 2, FFT.bits)

    COLOR Black, Black

    i = 0
    WHILE i < FFT.halfFrames
        j = (i * FFT.size.y) \ FFT.halfFrames ' this is the y location where we need to draw the bar

        ' First calculate and draw a bar on the left
        x = _SHR(SpectrumAnalyzerL(i), ANALYZER_SCALE)
        IF x > 0 THEN ' only do something if x has a value > 0
            IF x > FFT.size.x THEN x = FFT.size.x
            p = FFT.size.x - 1 ' this is starting x position of the bar
            Graphics_DrawHorizontalLine p, j, p - x + 1, Graphics_MakeTextColorAttribute(254, LightGreen + x MOD Brown, Black)
        END IF

        ' Next calculate for the one on the right and draw
        x = _SHR(SpectrumAnalyzerR(i), ANALYZER_SCALE)
        IF x > 0 THEN ' only do something if x has a value > 0
            IF x > FFT.size.x THEN x = FFT.size.x
            p = FFT.size.x + TEXT_WIDTH_HEADER ' this is starting x position of the bar
            Graphics_DrawHorizontalLine p, j, p + x - 1, Graphics_MakeTextColorAttribute(254, LightGreen + x MOD Brown, Black)
        END IF

        i = i + 1
    WEND

    _DISPLAY ' flip the framebuffer
END SUB


' Welcome screen loop
FUNCTION OnWelcomeScreen%%
    SHARED Stars() AS StarType
    SHARED Snakes() AS SnakeType

    ' Save the current destination
    DIM oldDest AS LONG: oldDest = _DEST

    ' Now create a new image
    DIM img AS LONG: img = _NEWIMAGE(TEXT_WIDTH_MIN * 8, (1 + TEXT_LINE_MAX) * 8, 32) ' We'll allocate some extra height to avoid any scrolling
    _FONT 8, img ' Change the font
    _DEST img ' Change destination
    RESTORE data_qb64modplayer_ans_15162
    DIM buffer AS STRING: buffer = Base64_LoadResourceData ' Load the ANSI art data
    ANSI_Print buffer ' Render the ANSI art

    _DEST oldDest ' Restore destination

    ' Capture rendered image to another image
    DIM imgANSI AS LONG: imgANSI = _NEWIMAGE(TEXT_WIDTH_MIN * 8, TEXT_LINE_MAX * 8, 32)
    _PUTIMAGE (0, 0), img, imgANSI ' Any excess height will simply get clipped
    _CLEARCOLOR BGRA_BLACK, imgANSI ' Set all black pixels to be transparent

    _FREEIMAGE img ' Free the old image

    ' Create a hardware image
    img = _COPYIMAGE(imgANSI, 33)

    _FREEIMAGE imgANSI ' Free the rendered ANSI image

    DIM bgType AS LONG: bgType = Math_GetRandomBetween(0, 1)

    DIM e AS _BYTE: e = EVENT_NONE

    DO
        CLS , Black ' Clear the framebuffer to black color

        ' Draw the background
        SELECT CASE bgType
            CASE 1
                UpdateAndDrawSnakes Snakes()

            CASE ELSE
                UpdateAndDrawStars Stars(), 1!
        END SELECT

        _PUTIMAGE (0, 0), img ' Blit the hardware image

        DIM k AS LONG: k = _KEYHIT

        IF k = KEY_ESCAPE THEN
            e = EVENT_QUIT
        ELSEIF _TOTALDROPPEDFILES > 0 THEN
            e = EVENT_DROP
        ELSEIF k = KEY_F1 THEN
            e = EVENT_LOAD
        ELSEIF k = KEY_F2 THEN
            e = EVENT_HTTP
        END IF

        _DISPLAY ' Flip the framebuffer

        _LIMIT FRAME_RATE
    LOOP WHILE e = EVENT_NONE

    _FREEIMAGE img ' Free the hardware image

    OnWelcomeScreen = e

    ' Welcome screen (144 x 90 chars)
    data_qb64modplayer_ans_15162:
    DATA 15162,1188,-1
    DATA eNqSjjbIlY42tDY2zlWgBAAoH6vbWKMYCD9fSA/fW+zQacjSbCFucbem6Iwcxp/MGriZTEJMGRv86u/v4WPiVIPn7oTzCsjy0PkwSZA10QCDarhM
    DATA 54rMiPRwctZ7a8ftZYTScdCHCk+ynAtWKJPJ3r12nRZ+iNrAmjjwwxUKU+DB3ggYAQKPRu0a5XXM9kIUjQzGoml21VAL+vkCCnqa3myjwP/4OEQ+
    DATA RMbENC1QQ9O1mn6+6LQwZIELnTx1fW+11+q35Jfz909JpWpJi3Kk1Tg6zLTf7Uq68/KOXav38PzDc3kUqtt2KdAU1ABdDLKQeB1Qh+0CsG8WOm7E
    DATA QAD9j4pGWAynjM6uk1g1bGxvQFAOSaFj/Kh+Ys8bH4fKBzOC0MLT5K3Z8zH/eyAbsiEbsiEbsiEbsiEbsiHbdWbzPY9Cdvh9pZjdpflnfRvPeoTh
    DATA zl/98CtE7d4/GZZzyVeQPhPul8dDEXPLUoZyGlgoM06NP80df7vzj9bkvTUXnIk4aUFZKwFChUQHVVan198af/ivl4joy5Ozvly0phaz4L0hdeqK
    DATA Ge8LPq9oDTXBqTaz1ZG0aTNH/li0Bqmn1photjUXqyoSGyxrPDVa8/rwobdmhitMBpoSQ6GueCzQGk+N1qQOP863JqRoDVLPsIYfDrw1i6sorlSE
    DATA 1iD11JpXqVWaNZo2mAzRGk+NNdQbb80iacpKN4hGa27VCLYPnKVANmRDNmRDNmQ7V73CFQrP9a8xERMxEdOfWxyGmlSAyBBCrSJIVkhEnIJQ4XSF
    DATA BCgJtsoMuE64aoBVkEyJ2yoVYGgtptIywnkrfe6umNiWiiEgEgg3Cowl2rqcQaRVRRMBDWarJ+n2qS5rJZKDAiWE+084kzTtO4y3urj3OZ2KSAw0
    DATA NLOWSmASaqUnxVREk+v4w1zqXBqNinXgshlSYAZInTBOSpw6pyvMVuOSlxa1nZvy3ubmZONFJtPtb/a2vqS/joeZz0+L2W4mybtQYSoafN5rr3tL
    DATA sZVyFTBPN4ldofCbxO4ESkhr+5uDNmx8XW+3R9AZr4PTKal1pjqlYXEE48neer/b24R7X++D+Tzcag+gMh62Nx5BPpsvwJKYpzWsGIbEAc1mL1DD
    DATA jJh1WT4etRvjQQfOhKPO5bKFH/tiycDAyDiBIYoBBJiZPZ18FcLcHU0NGJABAJPUQiY=
END FUNCTION


' Loads the note string table
SUB InitializeNoteTable
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


' Automatically selects, sets the window size and saves the text width
SUB AdjustWindowSize
    SHARED __Song AS __SongType
    SHARED FFT AS FFTType

    IF __Song.isPlaying THEN
        PatternDisplayWidth = 8 + __Song.channels * 19 ' find the actual width
        WindowWidth = PatternDisplayWidth
        IF WindowWidth < TEXT_WIDTH_MIN THEN WindowWidth = TEXT_WIDTH_MIN ' we don't want the width to be too small
        FFT.size.x = (WindowWidth - TEXT_WIDTH_HEADER) \ 2
        IF PatternDisplayWidth <= TEXT_WIDTH_HEADER THEN
            FFT.size.y = TEXT_LINE_MAX
        ELSE
            FFT.size.y = 4 + Math_GetMinLong(__Song.instruments, MAX_VISIBLE_INSTRUMENTS)
        END IF
    ELSE
        PatternDisplayWidth = 0
        WindowWidth = TEXT_WIDTH_MIN ' we don't want the width to be too small
        FFT.size.x = 0
        FFT.size.y = 0
    END IF

    WIDTH WindowWidth, TEXT_LINE_MAX ' we need 75 lines for the vizualization stuff
    _CONTROLCHR OFF ' turn off control characters
    _FONT 8 ' force 8x8 pixel font
    _BLINK OFF ' we want high intensity colors
    CLS ' clear the screen
    LOCATE , , FALSE ' turn cursor off
END SUB


' Initializes, loads and plays a mod file
' Also checks for input, shows info etc
FUNCTION OnPlayTune%% (fileName AS STRING)
    SHARED __Song AS __SongType

    OnPlayTune = EVENT_PLAY ' default event is to play next song

    DIM buffer AS STRING: buffer = File_Load(fileName) ' load the whole file to memory

    IF NOT MODPlayer_LoadFromMemory(buffer) THEN
        _MESSAGEBOX APP_NAME, "Failed to load: " + fileName, "error"

        EXIT FUNCTION
    END IF

    ' Set the app _TITLE to display the file name
    DIM windowTitle AS STRING
    IF LEN(Pathname_GetDriveOrScheme(fileName)) > 2 THEN
        windowTitle = GetSaveFileName(fileName) + " - " + APP_NAME
    ELSE
        windowTitle = Pathname_GetFileName(fileName) + " - " + APP_NAME
    END IF
    _TITLE windowTitle

    MODPlayer_Play
    AdjustWindowSize

    DIM AS LONG k

    DO
        MODPlayer_Update SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT

        DrawVisualization

        k = _KEYHIT

        SELECT CASE k
            CASE KEY_ESCAPE
                EXIT DO

            CASE KEY_SPACE
                __Song.isPaused = NOT __Song.isPaused

            CASE KEY_PLUS, KEY_EQUALS
                SoftSynth_SetMasterVolume SoftSynth_GetMasterVolume + VOLUME_STEP

            CASE KEY_MINUS, KEY_UNDERSCORE
                SoftSynth_SetMasterVolume SoftSynth_GetMasterVolume - VOLUME_STEP

            CASE KEY_UPPER_L, KEY_LOWER_L
                MODPlayer_Loop NOT MODPlayer_IsLooping

            CASE KEY_LEFT_ARROW
                MODPlayer_GoToPreviousPosition

            CASE KEY_RIGHT_ARROW
                MODPlayer_GoToNextPosition

            CASE KEY_F1
                OnPlayTune = EVENT_LOAD
                EXIT DO

            CASE KEY_F6 ' quick save for files loaded from ModArchive
                QuickSave buffer, fileName

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
            OnPlayTune = EVENT_DROP

            EXIT DO
        END IF

        _LIMIT FRAME_RATE
    LOOP WHILE MODPlayer_IsPlaying

    MODPlayer_Stop
    AdjustWindowSize

    _TITLE APP_NAME + " " + _OS$ ' Set app title to the way it was
END FUNCTION


' Processes the command line one file at a time
FUNCTION OnCommandLine%%
    DIM e AS _BYTE: e = EVENT_NONE

    IF (COMMAND$(1) = "/?" OR COMMAND$(1) = "-?") THEN
        _MESSAGEBOX APP_NAME, APP_NAME + STRING_LF + "Syntax: " + Pathname_GetFileName(COMMAND$(0)) + " [modfile.mod]" + STRING_LF + "    /?: Shows this message" + STRING_LF + STRING_LF + "Copyright (c) 2024, Samuel Gomes" + STRING_LF + STRING_LF + "https://github.com/a740g/", "info"
        e = EVENT_QUIT
    ELSE
        DIM i AS LONG: FOR i = 1 TO _COMMANDCOUNT
            e = OnPlayTune(COMMAND$(i))
            IF e <> EVENT_PLAY THEN EXIT FOR
        NEXT
    END IF

    OnCommandLine = e
END FUNCTION


' Processes dropped files one file at a time
FUNCTION OnDroppedFiles%%
    ' Make a copy of the dropped file and clear the list
    REDIM fileNames(1 TO _TOTALDROPPEDFILES) AS STRING

    DIM e AS _BYTE: e = EVENT_NONE

    DIM i AS LONG: FOR i = 1 TO _TOTALDROPPEDFILES
        fileNames(i) = _DROPPEDFILE(i)
    NEXT
    _FINISHDROP ' This is critical

    ' Now play the dropped file one at a time
    FOR i = LBOUND(fileNames) TO UBOUND(fileNames)
        e = OnPlayTune(fileNames(i))
        IF e <> EVENT_PLAY THEN EXIT FOR
    NEXT

    OnDroppedFiles = e
END FUNCTION


' Processes a list of files selected by the user
FUNCTION OnSelectedFiles%%
    DIM ofdList AS STRING
    DIM e AS _BYTE: e = EVENT_NONE

    ofdList = _OPENFILEDIALOG$(APP_NAME, "", "*.mod|*.MOD|*.Mod|*.mtm|*.MTM|*.Mtm|*.s3m|*.S3M|*.S3m", "Music Tracker Files", TRUE)

    IF LEN(ofdList) = NULL THEN EXIT FUNCTION

    REDIM fileNames(0 TO 0) AS STRING

    DIM j AS LONG: j = String_Tokenize(ofdList, "|", STRING_EMPTY, FALSE, fileNames())

    DIM i AS LONG: FOR i = 0 TO j - 1
        e = OnPlayTune(fileNames(i))
        IF e <> EVENT_PLAY THEN EXIT FOR
    NEXT

    OnSelectedFiles = e
END FUNCTION


' Loads and plays random MODs from modarchive.org
FUNCTION OnModArchiveFiles%%
    DIM e AS _BYTE: e = EVENT_NONE
    DIM AS STRING modArchiveFileName, fileExtension

    DO
        DO
            IF _TOTALDROPPEDFILES > 0 THEN
                e = EVENT_DROP
                EXIT DO
            ELSEIF _KEYHIT = KEY_F1 THEN
                e = EVENT_LOAD
                EXIT DO
            END IF

            modArchiveFileName = GetRandomModArchiveFileName$
            fileExtension = LCASE$(Pathname_GetFileExtension(modArchiveFileName))

            _TITLE "Downloading: " + GetSaveFileName(modArchiveFileName) + " - " + APP_NAME
        LOOP UNTIL fileExtension = ".mod" OR fileExtension = ".mtm" OR fileExtension = ".s3m"

        e = OnPlayTune(modArchiveFileName)
    LOOP WHILE e = EVENT_NONE OR e = EVENT_PLAY

    _TITLE APP_NAME + " " + _OS$ ' Set app title to the way it was

    OnModArchiveFiles = e
END FUNCTION


' Gets a random file URL from www.modarchive.org
FUNCTION GetRandomModArchiveFileName$
    DIM buffer AS STRING: buffer = File_LoadFromURL("https://modarchive.org/index.php?request=view_random")
    DIM bufPos AS LONG: bufPos = INSTR(buffer, "https://api.modarchive.org/downloads.php?moduleid=")

    IF bufPos > 0 THEN
        GetRandomModArchiveFileName = MID$(buffer, bufPos, INSTR(bufPos, buffer, STRING_QUOTE) - bufPos)
    END IF
END FUNCTION


' Returns a good file name for a modarchive file
FUNCTION GetSaveFileName$ (url AS STRING)
    DIM saveFileName AS STRING: saveFileName = Pathname_GetFileName(url)
    GetSaveFileName = Pathname_MakeLegalFileName(MID$(saveFileName, INSTR(saveFileName, "=") + 1)) ' this will get a file name of type: 12312313#filename.mod
END FUNCTION


' Saves a file loaded from the internet
SUB QuickSave (buffer AS STRING, url AS STRING)
    STATIC savePath AS STRING, alwaysUseSamePath AS _BYTE, stopNagging AS _BYTE

    IF LEN(Pathname_GetDriveOrScheme(url)) > 2 THEN
        ' This is a file from the web
        IF NOT _DIREXISTS(savePath) OR NOT alwaysUseSamePath THEN ' only get the path if path does not exist or user wants to use a new path
            savePath = _SELECTFOLDERDIALOG$("Select a folder to save the file:", savePath)
            IF LEN(savePath) = NULL THEN EXIT SUB ' exit if user cancelled

            savePath = Pathname_FixDirectoryName(savePath)
        END IF

        DIM saveFileName AS STRING: saveFileName = savePath + GetSaveFileName(url)

        IF _FILEEXISTS(saveFileName) THEN
            IF _MESSAGEBOX(APP_NAME, "Overwrite " + saveFileName + "?", "yesno", "warning", 0) = 0 THEN EXIT SUB
        END IF

        IF File_Save(buffer, saveFileName, TRUE) THEN _MESSAGEBOX APP_NAME, saveFileName + " saved.", "info"

        ' Check if user want to use the same path in the future
        IF NOT stopNagging THEN
            SELECT CASE _MESSAGEBOX(APP_NAME, "Do you want to use " + savePath + " for future saves?", "yesnocancel", "question", 1)
                CASE 0
                    stopNagging = TRUE
                CASE 1
                    alwaysUseSamePath = TRUE
                CASE 2
                    alwaysUseSamePath = FALSE
            END SELECT
        END IF
    ELSE
        ' This is a local file - do nothing
        _MESSAGEBOX APP_NAME, "You cannot save local file " + url + "!", "error"
    END IF
END SUB


SUB InitializeStars (stars() AS StarType)
    CONST Z_DIVIDER = 4096!

    DIM L AS LONG: L = LBOUND(stars)
    DIM U AS LONG: U = UBOUND(stars)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    DIM i AS LONG: FOR i = L TO U
        stars(i).p.x = Math_GetRandomBetween(0, W - 1)
        stars(i).p.y = Math_GetRandomBetween(0, H - 1)
        stars(i).p.z = Z_DIVIDER
        stars(i).c = Math_GetRandomBetween(9, 15)
    NEXT i
END SUB


SUB UpdateAndDrawStars (stars() AS StarType, speed AS SINGLE)
    CONST Z_DIVIDER = 4096!

    DIM L AS LONG: L = LBOUND(stars)
    DIM U AS LONG: U = UBOUND(stars)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT
    DIM W_Half AS LONG: W_Half = W \ 2
    DIM H_Half AS LONG: H_Half = H \ 2

    DIM i AS LONG: FOR i = L TO U
        IF stars(i).p.x < 0 OR stars(i).p.x >= W OR stars(i).p.y < 0 OR stars(i).p.y >= H THEN
            stars(i).p.x = Math_GetRandomBetween(0, W - 1)
            stars(i).p.y = Math_GetRandomBetween(0, H - 1)
            stars(i).p.z = Z_DIVIDER
            stars(i).c = Math_GetRandomBetween(9, 15)
        END IF

        SELECT CASE stars(i).p.z
            CASE IS < 4119!
                Graphics_DrawPixel stars(i).p.x, stars(i).p.y, Graphics_MakeTextColorAttribute(249, stars(i).c, 0)

            CASE IS < 4149!
                Graphics_DrawPixel stars(i).p.x, stars(i).p.y, Graphics_MakeTextColorAttribute(7, stars(i).c, 0)

            CASE IS < 4166!
                Graphics_DrawPixel stars(i).p.x, stars(i).p.y, Graphics_MakeTextColorAttribute(43, stars(i).c, 0)

            CASE IS < 4190!
                Graphics_DrawPixel stars(i).p.x, stars(i).p.y, Graphics_MakeTextColorAttribute(120, stars(i).c, 0)

            CASE ELSE
                Graphics_DrawPixel stars(i).p.x, stars(i).p.y, Graphics_MakeTextColorAttribute(42, stars(i).c, 0)
        END SELECT

        stars(i).p.z = stars(i).p.z + speed
        stars(i).a = stars(i).a + 0.01!
        DIM zd AS SINGLE: zd = stars(i).p.z / Z_DIVIDER
        stars(i).p.x = ((stars(i).p.x - W_Half) * zd) + W_Half + COS(stars(i).a * 0.5!) * 0.5!
        stars(i).p.y = ((stars(i).p.y - H_Half) * zd) + H_Half + SIN(stars(i).a * 1.5!) * 0.5!
    NEXT i
END SUB


SUB InitializeSnakes (snakes() AS SnakeType)
    CONST SNAKE_SIZE_MIN = 5
    CONST SNAKE_SIZE_MAX = 25

    DIM L AS LONG: L = LBOUND(snakes)
    DIM U AS LONG: U = UBOUND(snakes)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    DIM i AS LONG: FOR i = L TO U
        snakes(i).p = SPACE$(Math_GetRandomBetween(SNAKE_SIZE_MIN, SNAKE_SIZE_MAX) * 2)
        snakes(i).s = 0.1! + RND * 0.9!
        snakes(i).c = Math_GetRandomBetween(1, 8)
        snakes(i).d.x = Math_GetRandomBetween(0, 1) * 2 - 1 ' -1 or 1
        snakes(i).d.y = Math_GetRandomBetween(0, 1) * 2 - 1 ' -1 or 1

        DIM size AS LONG: size = LEN(snakes(i).p)
        DIM x AS LONG: x = Math_GetRandomBetween(0, W - 1)
        DIM y AS LONG: y = Math_GetRandomBetween(0, H - 1)

        DIM j AS LONG: j = 1
        WHILE j <= size
            ASC(snakes(i).p, j) = x
            j = j + 1
            ASC(snakes(i).p, j) = y
            j = j + 1
        WEND
    NEXT i
END SUB


SUB UpdateAndDrawSnakes (snakes() AS SnakeType)
    DIM L AS LONG: L = LBOUND(snakes)
    DIM U AS LONG: U = UBOUND(snakes)
    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    DIM i AS LONG: FOR i = L TO U
        snakes(i).t = snakes(i).t + snakes(i).s

        DIM p AS Vector2LType
        DIM s AS LONG: s = LEN(snakes(i).p)

        ' Only run movement code when it is time to move
        IF snakes(i).t > 1! THEN
            snakes(i).t = 0!

            ' Get the position of the head and add velocity
            p.x = ASC(snakes(i).p, 1) + snakes(i).d.x
            p.y = ASC(snakes(i).p, 2) + snakes(i).d.y

            IF p.x < 0 OR p.x >= W THEN snakes(i).d.x = -snakes(i).d.x
            IF p.y < 0 OR p.y >= H THEN snakes(i).d.y = -snakes(i).d.y

            DIM j AS LONG: j = s - 2
            WHILE j > 0
                ASC(snakes(i).p, j + 2) = ASC(snakes(i).p, j)
                j = j - 1
            WEND
            ASC(snakes(i).p, 1) = ASC(snakes(i).p, 1) + snakes(i).d.x
            ASC(snakes(i).p, 2) = ASC(snakes(i).p, 2) + snakes(i).d.y

            IF Math_GetRandomBetween(1, 100) <= 5 THEN ' change direction with a 5% chance
                DO
                    snakes(i).d.x = Math_GetRandomBetween(-1, 1)
                    snakes(i).d.y = Math_GetRandomBetween(-1, 1)
                LOOP WHILE snakes(i).d.x = 0 AND snakes(i).d.y = 0
            END IF
        END IF

        j = s - 2
        WHILE j > 2
            p.y = ASC(snakes(i).p, j)
            j = j - 1
            p.x = ASC(snakes(i).p, j)
            j = j - 1
            Graphics_DrawPixel p.x, p.y, Graphics_MakeTextColorAttribute(254, snakes(i).c, 0)
        WEND

        p.x = ASC(snakes(i).p, 1)
        p.y = ASC(snakes(i).p, 2)
        Graphics_DrawPixel p.x, p.y, Graphics_MakeTextColorAttribute(15, snakes(i).c, 0)
    NEXT i
END SUB
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/Pathname.bas'
'$INCLUDE:'include/File.bas'
'$INCLUDE:'include/StringOps.bas'
'$INCLUDE:'include/MODPlayer.bas'
'$INCLUDE:'include/Base64.bas'
'$INCLUDE:'include/ANSIPrint.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------
