'-----------------------------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/BitwiseOps.bi'
'$INCLUDE:'include/FileOps.bi'
'$INCLUDE:'include/StringOps.bi'
'$INCLUDE:'include/AnalyzerFFT.bi'
'$INCLUDE:'include/SoftSynth.bi'
'$INCLUDE:'include/MODPlayer.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$NOPREFIX
$RESIZE:SMOOTH
$EXEICON:'./QB64MODPlayer.ico'
$VERSIONINFO:CompanyName=Samuel Gomes
$VERSIONINFO:FileDescription=QB64 MOD Player executable
$VERSIONINFO:InternalName=QB64MODPlayer
$VERSIONINFO:LegalCopyright=Copyright (c) 2023 Samuel Gomes
$VERSIONINFO:LegalTrademarks=All trademarks are property of their respective owners
$VERSIONINFO:OriginalFilename=QB64MODPlayer.exe
$VERSIONINFO:ProductName=QB64 MOD Player
$VERSIONINFO:Web=https://github.com/a740g
$VERSIONINFO:Comments=https://github.com/a740g
$VERSIONINFO:FILEVERSION#=2,1,0,0
$VERSIONINFO:PRODUCTVERSION#=2,1,0,0
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
CONST APP_NAME = "QB64 MOD Player" ' application name
' TODO: use 1024 x 640 px (8x8 px chars)
CONST TEXT_LINE_MAX = 75 ' this the number of lines we need
CONST TEXT_WIDTH_MIN = 120 ' minimum width we need
CONST TEXT_WIDTH_HEADER = 84 ' width of the main header on the vis screen
CONST ANALYZER_SCALE = 5120 ' values after this will be clipped in the analyzer array
CONST FRAME_RATE_MIN = 60 ' minimum frame rate we'll allow
' Program events
CONST EVENT_NONE = 0 ' idle
CONST EVENT_QUIT = 1 ' user wants to quit
CONST EVENT_CMDS = 2 ' process command line
CONST EVENT_LOAD = 3 ' user want to load files
CONST EVENT_DROP = 4 ' user dropped files
CONST EVENT_PLAY = 5 ' play next song
CONST EVENT_HTTP = 6 ' Downloads and plays random MODs from modarchive.org
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
DIM SHARED GlobalVolume AS SINGLE ' this is needed because the replayer can reset volume across songs
DIM SHARED HighQuality AS BYTE ' this is needed because the replayer can reset quality across songs
REDIM SHARED NoteTable(0 TO 0) AS STRING * 2 ' this contains the note stings
DIM SHARED WindowWidth AS LONG ' the width of our windows in characters
DIM SHARED PatternDisplayWidth AS LONG ' the width of the pattern display in characters
DIM SHARED AS LONG SpectrumAnalyzerWidth, SpectrumAnalyzerHeight ' the width & height of the spectrum analyzer
REDIM SHARED AS UNSIGNED INTEGER SpectrumAnalyzerL(0 TO 0), SpectrumAnalyzerR(0 TO 0) ' left & right channel FFT data
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Frankenstein retro TUI with drag & drop support
'-----------------------------------------------------------------------------------------------------------------------
TITLE APP_NAME + " " + OS$ ' set the program name in the titlebar
CHDIR STARTDIR$ ' change to the directory specifed by the environment
ACCEPTFILEDROP ' enable drag and drop of files
InitializeNoteTable ' initialize note string table
AdjustWindowSize ' set the initial window size
ALLOWFULLSCREEN SQUAREPIXELS , SMOOTH ' allow the user to press Alt+Enter to go fullscreen
SetRandomSeed TIMER ' seed RNG
GlobalVolume = SOFTSYNTH_GLOBAL_VOLUME_MAX ' set global volume to maximum
HighQuality = TRUE ' enable interpolated mixing by default

DIM event AS BYTE: event = EVENT_CMDS ' default to command line event first

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

AUTODISPLAY
SYSTEM
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------
' This "prints" the current playing MODs visualization on the screen
SUB PrintVisualization
    ' These are internal variables and arrays used by the MODPlayer library and are used for showing internal info and visualization
    ' In a general use case, accessing these directly is not required at all
    SHARED __Song AS __SongType
    SHARED __Order() AS UNSIGNED INTEGER
    SHARED __Pattern() AS __NoteType
    SHARED __Sample() AS __SampleType
    SHARED __MixerBuffer() AS SINGLE

    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then __Order(__Song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    IF __Song.orderPosition >= __Song.orders THEN EXIT SUB

    CLS , 0 ' clear the framebuffer to black color

    DIM x AS LONG
    x = 1 + WindowWidth \ 2 - TEXT_WIDTH_HEADER \ 2 ' find x so that we can center everything

    ' Print song type and name
    COLOR 15, 5
    LOCATE 1, x: PRINT USING "  \  \: \                                                                        \  "; __Song.subtype; __Song.songName

    ' Print the header
    COLOR 16, 15
    LOCATE , x: PRINT USING "  ORD: ### / ### | PAT: ### / ### | ROW: ## / 63 | CHN: ### / ### | VOC: ### / ###  "; __Song.orderPosition; __Song.orders - 1; __Order(__Song.orderPosition); __Song.patterns - 1; __Song.patternRow; __Song.activeChannels; __Song.channels; SampleMixer_GetActiveVoices; SampleMixer_GetTotalVoices
    LOCATE , x: PRINT USING "  BPM: ###       | SPD: ###       | VOL: ###%    |  HQ: \       \ | REP: \       \  "; __Song.bpm; __Song.speed; GlobalVolume * 100.0!; FormatBoolean(HighQuality, 3); FormatBoolean(__Song.isLooping, 4)

    ' Print the sample list header
    COLOR 16, 3
    LOCATE , x: PRINT "  S#  SAMPLE-NAME              VOLUME C2SPD LENGTH LOOP-LENGTH LOOP-START LOOP-END  "

    ' Print the sample information
    DIM AS LONG i, j
    FOR i = 0 TO __Song.samples - 1
        COLOR 14, 0
        FOR j = 0 TO __Song.channels - 1
            IF i + 1 = __Pattern(__Order(__Song.orderPosition), __Song.patternRow, j).sample THEN
                COLOR 13, 1
            END IF
        NEXT
        LOCATE , x: PRINT USING " ###: \                    \ ######## ##### ###### ########### ########## ########  "; i + 1; __Sample(i).sampleName; __Sample(i).volume; __Sample(i).c2Spd; __Sample(i).length; __Sample(i).loopLength; __Sample(i).loopStart; __Sample(i).loopEnd
    NEXT

    x = 1 + WindowWidth \ 2 - PatternDisplayWidth \ 2 ' find x so that we can center everything

    ' Print the pattern header
    COLOR 16, 3
    LOCATE , x: PRINT " PAT RW ";
    FOR i = 1 TO __Song.channels
        PRINT " CHAN NOT S# FX OP ";
    NEXT
    PRINT

    DIM AS LONG startRow, startPat, nNote, nChan, nSample, nEffect, nOperand

    ' Get the current line number
    j = CSRLIN

    ' Find the pattern and row we need to print
    startPat = __Order(__Song.orderPosition)
    startRow = __Song.patternRow - (1 + TEXT_LINE_MAX - j) \ 2
    IF startRow < 0 THEN
        startRow = __Song.rows + startRow
        startPat = startPat - 1
    END IF

    ' Now just dump everything to the screen
    FOR i = j TO TEXT_LINE_MAX - 1
        LOCATE i, x
        COLOR 15, 0

        IF startPat >= 0 AND startPat < __Song.patterns THEN
            IF i = j + (1 + TEXT_LINE_MAX - j) \ 2 THEN
                COLOR 15, 1
            END IF

            PRINT USING " ### ##:"; startPat; startRow;

            FOR nChan = 0 TO __Song.channels - 1
                COLOR 11
                PRINT USING " (##)"; nChan + 1;
                nNote = __Pattern(startPat, startRow, nChan).note
                IF nNote = __NOTE_NONE THEN
                    COLOR 8
                    PRINT "  -  ";
                ELSEIF nNote = __NOTE_KEY_OFF THEN
                    COLOR 2
                    PRINT " ^^^ ";
                ELSE
                    COLOR 10
                    PRINT USING " &# "; NoteTable(nNote MOD 12); nNote \ 12;
                END IF

                nSample = __Pattern(startPat, startRow, nChan).sample
                IF nSample = 0 THEN
                    COLOR 8
                    PRINT "-- ";
                ELSE
                    COLOR 14
                    PRINT FormatLong(nSample, "%.2i ");
                END IF

                nEffect = __Pattern(startPat, startRow, nChan).effect
                nOperand = __Pattern(startPat, startRow, nChan).operand

                IF nEffect = 0 AND nOperand = 0 THEN
                    COLOR 8
                    PRINT "-- ";
                ELSE
                    COLOR 13
                    PRINT FormatLong(nEffect, "%.2X ");
                END IF

                IF nOperand = 0 THEN
                    COLOR 8
                    PRINT "-- ";
                ELSE
                    COLOR 12
                    PRINT FormatLong(nOperand, "%.2X ");
                END IF
            NEXT
        ELSE
            PRINT SPACE$(PatternDisplayWidth);
        END IF

        startRow = startRow + 1
        ' Wrap if needed
        IF startRow >= __Song.rows THEN
            startRow = 0
            startPat = startPat + 1
        END IF
    NEXT

    ' Print the footer
    COLOR 16, 7
    LOCATE TEXT_LINE_MAX, x: PRINT USING " ####ms "; SampleMixer_GetBufferedSoundTime * 1000;
    FOR i = 0 TO __Song.channels - 1
        PRINT FormatLong(i + 1, " (%2i)"); FormatSingle(SampleMixer_GetVoiceVolume(i) * 100.0!, " V:%3.0f"); FormatSingle(SampleMixer_GetVoicePanning(i) * 100.0!, " P:%+4.0f ");
    NEXT

    DIM AS LONG fftSamples, fftSamplesHalf, fftBits

    fftSamples = RoundLongDownToPowerOf2(__Song.samplesPerTick) ' we need power of 2 for our FFT function
    fftSamplesHalf = fftSamples \ 2
    fftBits = LeftShiftOneCount(fftSamples) ' Get the count of bits that the FFT routine will need

    ' Setup the FFT arrays (half of fftSamples)
    REDIM AS UNSIGNED INTEGER SpectrumAnalyzerL(0 TO fftSamplesHalf - 1), SpectrumAnalyzerR(0 TO fftSamplesHalf - 1)

    AnalyzerFFTSingle SpectrumAnalyzerL(0), __MixerBuffer(0), 2, fftBits ' the left samples first
    AnalyzerFFTSingle SpectrumAnalyzerR(0), __MixerBuffer(1), 2, fftBits ' and now the right ones

    COLOR , 0

    FOR i = 0 TO fftSamplesHalf - 1
        j = (i * SpectrumAnalyzerHeight) \ fftSamplesHalf ' this is the y location where we need to draw the bar

        ' First calculate and draw a bar on the left
        IF SpectrumAnalyzerL(i) >= ANALYZER_SCALE THEN
            x = SpectrumAnalyzerWidth - 1
        ELSE
            x = (SpectrumAnalyzerL(i) * (SpectrumAnalyzerWidth - 1)) \ ANALYZER_SCALE
        END IF

        TextHLine SpectrumAnalyzerWidth - x, 1 + j, SpectrumAnalyzerWidth

        ' Next calculate for the one on the right and draw
        IF SpectrumAnalyzerR(i) >= ANALYZER_SCALE THEN
            x = SpectrumAnalyzerWidth - 1
        ELSE
            x = (SpectrumAnalyzerR(i) * (SpectrumAnalyzerWidth - 1)) \ ANALYZER_SCALE
        END IF

        TextHLine 1 + SpectrumAnalyzerWidth + TEXT_WIDTH_HEADER, 1 + j, 1 + SpectrumAnalyzerWidth + TEXT_WIDTH_HEADER + x
    NEXT

    DISPLAY ' flip the framebuffer
END SUB


' Welcome screen loop
FUNCTION OnWelcomeScreen%%
    DIM starP(1 TO TEXT_WIDTH_MIN) AS Vector3FType
    DIM starC(1 TO TEXT_WIDTH_MIN) AS UNSIGNED LONG
    DIM k AS LONG, e AS BYTE

    DO
        CLS , 0 ' clear the framebuffer to black color

        LOCATE 1, 1
        COLOR 14, 0
        PRINT "                                                 *        )  (       (                                                  "
        PRINT "                       (     (   (         )   (  `    ( /(  )\ )    )\ )  (                                            "
        PRINT "                     ( )\  ( )\  )\ )   ( /(   )\))(   )\())(()/(   (()/(  )\    )  (       (   (                       "
        PRINT "                     )((_) )((_)(()/(   )\()) ((_)()\ ((_)\  /(_))   /(_))((_)( /(  )\ )   ))\  )(                      "
        PRINT "                    ((_)_ ((_)_  /(_)) ((_)\  (_()((_)  ((_)(_))_   (_))   _  )(_))(()/(  /((_)(()\                     "
        PRINT "                     / _ \ | _ )(_) / | | (_) |  \/  | / _ \ |   \  | _ \ | |((_)_  )(_))(_))   ((_)                    "
        PRINT "                    | (_) || _ \ / _ \|_  _|  | |\/| || (_) || |) | |  _/ | |/ _` || || |/ -_) | '_|                    "
        PRINT "_.___________________\__\_\|___/ \___/  |_|   |_|  |_| \___/ |___/  |_|   |_|\__,_| \_, |\___| |_|____________________._"
        PRINT "                                                                                    |__/                                "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "F1";: COLOR 8: PRINT " ............ ";: COLOR 13: PRINT "MULTI-SELECT FILES";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "F2";: COLOR 8: PRINT " .......... ";: COLOR 13: PRINT "PLAY FROM MODARCHIVE";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "ESC";: COLOR 8: PRINT " .................... ";: COLOR 13: PRINT "NEXT/QUIT";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "SPC";: COLOR 8: PRINT " ........................ ";: COLOR 13: PRINT "PAUSE";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "=|+";: COLOR 8: PRINT " .............. ";: COLOR 13: PRINT "INCREASE VOLUME";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "-|_";: COLOR 8: PRINT " .............. ";: COLOR 13: PRINT "DECREASE VOLUME";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "L|l";: COLOR 8: PRINT " ......................... ";: COLOR 13: PRINT "LOOP";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "Q|q";: COLOR 8: PRINT " ................ ";: COLOR 13: PRINT "INTERPOLATION";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "<-";: COLOR 8: PRINT " ........................ ";: COLOR 13: PRINT "REWIND";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                         ";: COLOR 11: PRINT "->";: COLOR 8: PRINT " ....................... ";: COLOR 13: PRINT "FORWARD";: COLOR 14: PRINT "                                         | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                                                                                                    | "
        PRINT " |                     ";: COLOR 9: PRINT "DRAG AND DROP MULTIPLE MOD FILES ON THIS WINDOW TO PLAY THEM SEQUENTIALLY.";: COLOR 14: PRINT "                     | "
        PRINT " |                                                                                                                    | "
        PRINT " |                     ";: COLOR 9: PRINT "YOU CAN ALSO START THE PROGRAM WITH MULTIPLE FILES FROM THE COMMAND LINE.";: COLOR 14: PRINT "                      | "
        PRINT " |                                                                                                                    | "
        PRINT " |                    ";: COLOR 9: PRINT "THIS WAS WRITTEN PURELY IN QB64 AND THE SOURCE CODE IS AVAILABLE ON GITHUB.";: COLOR 14: PRINT "                     | "
        PRINT " |                                                                                                                    | "
        PRINT " |                                     ";: COLOR 9: PRINT "https://github.com/a740g/QB64-MOD-Player";: COLOR 14: PRINT "                                       | "
        PRINT "_|_                                                                                                                  _|_"
        PRINT " `/__________________________________________________________________________________________________________________\' ";

        ' Text mode starfield. Hell yeah!
        FOR k = LBOUND(starP) TO UBOUND(starP)
            IF starP(k).x < 1! OR starP(k).x > WindowWidth OR starP(k).y < 1! OR starP(k).y > TEXT_LINE_MAX THEN
                starP(k).x = GetRandomBetween(1 + WindowWidth \ 4, WindowWidth - WindowWidth \ 4)
                starP(k).y = GetRandomBetween(1 + TEXT_LINE_MAX \ 4, TEXT_LINE_MAX - TEXT_LINE_MAX \ 4)
                starP(k).z = 4096!
                starC(k) = GetRandomBetween(9, 15)
            END IF

            COLOR starC(k)
            IF starP(k).z < 4160! THEN
                PRINTSTRING (starP(k).x, starP(k).y), CHR$(249)
            ELSEIF starP(k).z < 4224! THEN
                PRINTSTRING (starP(k).x, starP(k).y), "+"
            ELSE
                PRINTSTRING (starP(k).x, starP(k).y), "*"
            END IF

            starP(k).z = starP(k).z + 1!
            starP(k).x = ((starP(k).x - SHR(WindowWidth, 1)) * (starP(k).z / 4096!)) + SHR(WindowWidth, 1) + RND * 0.01! - RND * 0.01!
            starP(k).y = ((starP(k).y - SHR(TEXT_LINE_MAX, 1)) * (starP(k).z / 4096!)) + SHR(TEXT_LINE_MAX, 1)
        NEXT

        k = KEYHIT

        IF k = KEY_ESCAPE THEN
            e = EVENT_QUIT
        ELSEIF TOTALDROPPEDFILES > 0 THEN
            e = EVENT_DROP
        ELSEIF k = KEY_F1 THEN
            e = EVENT_LOAD
        ELSEIF k = KEY_F2 THEN
            e = EVENT_HTTP
        END IF

        DISPLAY ' flip the framebuffer

        LIMIT FRAME_RATE_MIN
    LOOP WHILE e = EVENT_NONE

    OnWelcomeScreen = e
END FUNCTION


' Loads the note string table
SUB InitializeNoteTable
    DIM AS UNSIGNED BYTE n, v
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

    IF __Song.isPlaying THEN
        PatternDisplayWidth = 8 + __Song.channels * 19 ' find the actual width
        WindowWidth = PatternDisplayWidth
        IF WindowWidth < TEXT_WIDTH_MIN THEN WindowWidth = TEXT_WIDTH_MIN ' we don't want the width to be too small
        SpectrumAnalyzerWidth = (WindowWidth - TEXT_WIDTH_HEADER) \ 2
        IF PatternDisplayWidth <= TEXT_WIDTH_HEADER THEN
            SpectrumAnalyzerHeight = TEXT_LINE_MAX
        ELSE
            SpectrumAnalyzerHeight = 4 + __Song.samples
        END IF
    ELSE
        PatternDisplayWidth = 0
        WindowWidth = TEXT_WIDTH_MIN ' we don't want the width to be too small
        SpectrumAnalyzerWidth = 0
        SpectrumAnalyzerHeight = 0
    END IF

    WIDTH WindowWidth, TEXT_LINE_MAX ' we need 75 lines for the vizualization stuff
    CONTROLCHR OFF ' turn off control characters
    FONT 8 ' force 8x8 pixel font
    BLINK OFF ' we want high intensity colors
    CLS ' clear the screen
    LOCATE , , FALSE ' turn cursor off
END SUB


' Initializes, loads and plays a mod file
' Also checks for input, shows info etc
FUNCTION OnPlayTune%% (fileName AS STRING)
    SHARED __Song AS __SongType

    OnPlayTune = EVENT_PLAY ' default event is to play next song

    DIM buffer AS STRING: buffer = LoadFile(fileName) ' load the whole file to memory

    IF NOT MODPlayer_LoadFromMemory(buffer) THEN
        MESSAGEBOX APP_NAME, "Failed to load: " + fileName, "error"

        EXIT FUNCTION
    END IF

    ' Set the app title to display the file name
    DIM windowTitle AS STRING
    IF LEN(GetDriveOrSchemeFromPathOrURL(fileName)) > 2 THEN
        windowTitle = GetSaveFileName(fileName) + " - " + APP_NAME
    ELSE
        windowTitle = GetFileNameFromPathOrURL(fileName) + " - " + APP_NAME
    END IF
    TITLE windowTitle

    MODPlayer_Play
    AdjustWindowSize

    SampleMixer_SetGlobalVolume GlobalVolume
    SampleMixer_SetHighQuality HighQuality

    DIM AS LONG k, nFPS

    DO
        MODPlayer_Update

        PrintVisualization

        k = KEYHIT

        SELECT CASE k
            CASE KEY_SPACE
                __Song.isPaused = NOT __Song.isPaused

            CASE KEY_PLUS, KEY_EQUALS
                SampleMixer_SetGlobalVolume GlobalVolume + 0.01!
                GlobalVolume = SampleMixer_GetGlobalVolume

            CASE KEY_MINUS, KEY_UNDERSCORE
                SampleMixer_SetGlobalVolume GlobalVolume - 0.01!
                GlobalVolume = SampleMixer_GetGlobalVolume

            CASE KEY_UPPER_L, KEY_LOWER_L
                MODPlayer_Loop NOT MODPlayer_IsLooping

            CASE KEY_UPPER_Q, KEY_LOWER_Q
                HighQuality = NOT HighQuality
                SampleMixer_SetHighQuality HighQuality

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
                IF LEN(GetDriveOrSchemeFromPathOrURL(fileName)) > 2 THEN
                    MESSAGEBOX APP_NAME, "You cannot delete " + fileName + "!", "error"
                ELSE
                    IF MESSAGEBOX(APP_NAME, "Are you sure you want to delete " + fileName + " permanently?", "yesno", "question", 0) = 1 THEN
                        KILL fileName
                        EXIT DO
                    END IF
                END IF
        END SELECT

        IF TOTALDROPPEDFILES > 0 THEN
            OnPlayTune = EVENT_DROP

            EXIT DO
        END IF

        HighQuality = SampleMixer_IsHighQuality ' Since this can be changed by the playing MOD

        nFPS = MaxLong(FRAME_RATE_MIN, (12 * __Song.bpm * (31 - __Song.speed)) \ 625) ' we'll only update at the rate we really need
        IF GetTicks MOD 15 = 0 THEN TITLE windowTitle + " (" + LTRIM$(STR$(nFPS)) + " FPS)"

        LIMIT nFPS
    LOOP UNTIL NOT MODPlayer_IsPlaying OR k = KEY_ESCAPE

    MODPlayer_Stop
    AdjustWindowSize

    TITLE APP_NAME + " " + OS$ ' Set app title to the way it was
END FUNCTION


' Processes the command line one file at a time
FUNCTION OnCommandLine%%
    DIM e AS BYTE: e = EVENT_NONE

    IF (COMMAND$(1) = "/?" OR COMMAND$(1) = "-?") THEN
        MESSAGEBOX APP_NAME, APP_NAME + CHR$(13) + "Syntax: QB64MODP [modfile.mod]" + CHR$(13) + "    /?: Shows this message" + STRING$(2, 13) + "Copyright (c) 2023, Samuel Gomes" + STRING$(2, 13) + "https://github.com/a740g/", "info"
        e = EVENT_QUIT
    ELSE
        DIM i AS LONG: FOR i = 1 TO COMMANDCOUNT
            e = OnPlayTune(COMMAND$(i))
            IF e <> EVENT_PLAY THEN EXIT FOR
        NEXT
    END IF

    OnCommandLine = e
END FUNCTION


' Processes dropped files one file at a time
FUNCTION OnDroppedFiles%%
    ' Make a copy of the dropped file and clear the list
    REDIM fileNames(1 TO TOTALDROPPEDFILES) AS STRING

    DIM e AS BYTE: e = EVENT_NONE

    DIM i AS LONG: FOR i = 1 TO TOTALDROPPEDFILES
        fileNames(i) = DROPPEDFILE(i)
    NEXT
    FINISHDROP ' This is critical

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
    DIM e AS BYTE: e = EVENT_NONE

    ofdList = OPENFILEDIALOG$(APP_NAME, "", "*.mod|*.MOD|*.Mod|*.mtm|*.MTM|*.Mtm", "Music Tracker Files", TRUE)

    IF ofdList = EMPTY_STRING THEN EXIT FUNCTION

    REDIM fileNames(0 TO 0) AS STRING

    DIM j AS LONG: j = TokenizeString(ofdList, "|", EMPTY_STRING, FALSE, fileNames())

    DIM i AS LONG: FOR i = 0 TO j - 1
        e = OnPlayTune(fileNames(i))
        IF e <> EVENT_PLAY THEN EXIT FOR
    NEXT

    OnSelectedFiles = e
END FUNCTION


' Loads and plays random MODs from modarchive.org
FUNCTION OnModArchiveFiles%%
    DIM e AS BYTE: e = EVENT_NONE
    DIM AS STRING modArchiveFileName, fileExtension

    DO
        DO
            IF TOTALDROPPEDFILES > 0 THEN
                e = EVENT_DROP
                EXIT DO
            ELSEIF KEYHIT = KEY_F1 THEN
                e = EVENT_LOAD
                EXIT DO
            END IF

            modArchiveFileName = GetRandomModArchiveFileName$
            fileExtension = LCASE$(GetFileExtensionFromPathOrURL(modArchiveFileName))

            TITLE "Downloading: " + GetSaveFileName(modArchiveFileName) + " - " + APP_NAME
        LOOP UNTIL fileExtension = ".mod" OR fileExtension = ".mtm"

        e = OnPlayTune(modArchiveFileName)
    LOOP WHILE e = EVENT_NONE OR e = EVENT_PLAY

    TITLE APP_NAME + " " + OS$ ' Set app title to the way it was

    OnModArchiveFiles = e
END FUNCTION


' Draw a horizontal line using text and colors it too! Sweet! XD
SUB TextHLine (xs AS LONG, y AS LONG, xe AS LONG)
    DIM l AS LONG: l = 1 + xe - xs
    COLOR 9 + l MOD 7
    PRINTSTRING (xs, y), STRING$(l, 254)
END SUB


' Gets a random file URL from www.modarchive.org
FUNCTION GetRandomModArchiveFileName$
    DIM buffer AS STRING: buffer = LoadFileFromURL("https://modarchive.org/index.php?request=view_random")
    DIM bufPos AS LONG: bufPos = INSTR(buffer, "https://api.modarchive.org/downloads.php?moduleid=")

    IF bufPos > 0 THEN
        GetRandomModArchiveFileName = MID$(buffer, bufPos, INSTR(bufPos, buffer, CHR$(34)) - bufPos)
    END IF
END FUNCTION


' Returns a good file name for a modarchive file
FUNCTION GetSaveFileName$ (url AS STRING)
    DIM saveFileName AS STRING: saveFileName = GetFileNameFromPathOrURL(url)
    GetSaveFileName = GetLegalFileName(MID$(saveFileName, INSTR(saveFileName, "=") + 1)) ' this will get a file name of type: 12312313#filename.mod
END FUNCTION


' Saves a file loaded from the internet
SUB QuickSave (buffer AS STRING, url AS STRING)
    STATIC savePath AS STRING, alwaysUseSamePath AS BYTE, stopNagging AS BYTE

    IF LEN(GetDriveOrSchemeFromPathOrURL(url)) > 2 THEN
        ' This is a file from the web
        IF NOT DIREXISTS(savePath) OR NOT alwaysUseSamePath THEN ' only get the path if path does not exist or user wants to use a new path
            savePath = SELECTFOLDERDIALOG$("Select a folder to save the file:", savePath)
            IF savePath = EMPTY_STRING THEN EXIT SUB ' exit if user cancelled

            savePath = FixPathDirectoryName(savePath)
        END IF

        DIM saveFileName AS STRING: saveFileName = savePath + GetSaveFileName(url)

        IF FILEEXISTS(saveFileName) THEN
            IF MESSAGEBOX(APP_NAME, "Overwrite " + saveFileName + "?", "yesno", "warning", 0) = 0 THEN EXIT SUB
        END IF

        IF SaveFile(buffer, saveFileName, TRUE) THEN MESSAGEBOX APP_NAME, saveFileName + " saved.", "info"

        ' Check if user want to use the same path in the future
        IF NOT stopNagging THEN
            SELECT CASE MESSAGEBOX(APP_NAME, "Do you want to use " + savePath + " for future saves?", "yesnocancel", "question", 1)
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
        MESSAGEBOX APP_NAME, "You cannot save local file " + url + "!", "error"
    END IF
END SUB
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/FileOps.bas'
'$INCLUDE:'include/StringOps.bas'
'$INCLUDE:'include/SoftSynth.bas'
'$INCLUDE:'include/MODPlayer.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------
