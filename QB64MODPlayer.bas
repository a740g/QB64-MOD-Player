'-----------------------------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'include/MODPlayer.bi'
'$Include:'include/AnalyzerFFT.bi'
'$Include:'include/FileOps.bi'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$NoPrefix
$Resize:Smooth
$ExeIcon:'./QB64MODPlayer.ico'
$VersionInfo:CompanyName=Samuel Gomes
$VersionInfo:FileDescription=QB64 MOD Player executable
$VersionInfo:InternalName=QB64MODPlayer
$VersionInfo:LegalCopyright=Copyright (c) 2023 Samuel Gomes
$VersionInfo:LegalTrademarks=All trademarks are property of their respective owners
$VersionInfo:OriginalFilename=QB64MODPlayer.exe
$VersionInfo:ProductName=QB64 MOD Player
$VersionInfo:Web=https://github.com/a740g
$VersionInfo:Comments=https://github.com/a740g
$VersionInfo:FILEVERSION#=2,0,0,0
$VersionInfo:PRODUCTVERSION#=2,0,0,0
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
Const APP_NAME = "QB64 MOD Player" ' application name
Const TEXT_LINE_MAX = 75 ' this the number of lines we need
Const TEXT_WIDTH_MIN = 120 ' minimum width we need
Const TEXT_WIDTH_HEADER = 84 ' width of the main header on the vis screen
Const ANALYZER_SCALE = 5120 ' values after this will be clipped in the analyzer array
Const FRAME_RATE_MIN = 60 ' minimum frame rate we'll allow
' Program events
Const EVENT_NONE = 0 ' idle
Const EVENT_QUIT = 1 ' user wants to quit
Const EVENT_CMDS = 2 ' process command line
Const EVENT_LOAD = 3 ' user want to load files
Const EVENT_DROP = 4 ' user dropped files
Const EVENT_PLAY = 5 ' play next song
Const EVENT_HTTP = 6 ' Downloads and plays random MODs from modarchive.org
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
ReDim Shared NoteTable(0 To 0) As String * 2 ' this contains the note stings
Dim Shared WindowWidth As Long ' the width of our windows in characters
Dim Shared PatternDisplayWidth As Long ' the width of the pattern display in characters
Dim Shared SpectrumAnalyzerWidth As Long ' the width of the spectrum analyzer
Dim Shared SpectrumAnalyzerHeight As Long ' the height of the spectrum analyzer
Dim Shared Volume As Integer ' this is needed because the replayer can reset volume across songs
Dim Shared HighQuality As Byte ' this is needed because the replayer can reset quality across songs
ReDim Shared SpectrumAnalyzerLeft(0 To 0) As Unsigned Integer ' left channel FFT data
ReDim Shared SpectrumAnalyzerRight(0 To 0) As Unsigned Integer ' right channel FFT data
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Frankenstein retro TUI with drag & drop support
'-----------------------------------------------------------------------------------------------------------------------
Title APP_NAME + " " + OS$ ' set the program name in the titlebar
ChDir StartDir$ ' change to the directory specifed by the environment
AcceptFileDrop ' enable drag and drop of files
InitializeNoteTable ' initialize note string table
AdjustWindowSize ' set the initial window size
AllowFullScreen SquarePixels , Smooth ' allow the user to press Alt+Enter to go fullscreen
SRand Timer ' seed RNG
Volume = GLOBAL_VOLUME_MAX ' set global volume to maximum
HighQuality = TRUE ' enable interpolated mixing by default

Dim event As Unsigned Byte

event = EVENT_CMDS ' default to command line event first

' Main loop
Do
    Select Case event
        Case EVENT_QUIT
            Exit Do

        Case EVENT_DROP
            event = ProcessDroppedFiles

        Case EVENT_LOAD
            event = ProcessSelectedFiles

        Case EVENT_CMDS
            event = ProcessCommandLine

        Case EVENT_HTTP
            event = ProcessModArchiveFiles

        Case Else
            event = DoWelcomeScreen
    End Select
Loop

AutoDisplay
System
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------------------------
' This "prints" the current playing MODs visualization on the screen
Sub PrintVisualization
    ' These are internal variables and arrays used by the MODPlayer library
    Shared __Song As __SongType
    Shared __Order() As Unsigned Byte
    Shared __Pattern() As __NoteType
    Shared __Sample() As __SampleType
    Shared SoftSynth As SoftSynthType
    Shared Voice() As VoiceType
    Shared MixerBufferLeft() As Single
    Shared MixerBufferRight() As Single

    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then __Order(__Song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    If __Song.orderPosition >= __Song.orders Then Exit Sub

    Cls , 0 ' clear the framebuffer to black color

    Dim x As Long
    x = 1 + WindowWidth \ 2 - TEXT_WIDTH_HEADER \ 2 ' find x so that we can center everything

    ' Print song type and name
    Color 15, 5
    Locate 1, x: Print Using "  \  \: \                                                                        \  "; __Song.subtype; __Song.songName

    ' Print the header
    Color 16, 15
    Locate , x: Print Using "  ORD: ### / ### | PAT: ### / ### | ROW: ## / 63 | CHN: ### / ### | VOC: ### / ###  "; __Song.orderPosition; __Song.orders - 1; __Order(__Song.orderPosition); __Song.highestPattern; __Song.patternRow; __Song.activeChannels; __Song.channels; SoftSynth.activeVoices; SoftSynth.voices
    Locate , x: Print Using "  BPM: ###       | SPD: ###       | VOL: \\ / FF |  HQ: \       \ | REP: \       \  "; __Song.bpm; __Song.speed; Right$("0" + Hex$(Volume), 2); BoolToStr(HighQuality, 1); BoolToStr(__Song.isLooping, 2)

    ' Print the sample list header
    Color 16, 3
    Locate , x: Print "  S#  SAMPLE-NAME              VOLUME C2SPD LENGTH LOOP-LENGTH LOOP-START LOOP-END  "

    ' Print the sample information
    Dim As Long i, j
    For i = 0 To __Song.samples - 1
        Color 14, 0
        For j = 0 To __Song.channels - 1
            If i + 1 = __Pattern(__Order(__Song.orderPosition), __Song.patternRow, j).sample Then
                Color 13, 1
            End If
        Next
        Locate , x: Print Using " ###: \                    \ ######## ##### ###### ########### ########## ########  "; i + 1; __Sample(i).sampleName; __Sample(i).volume; __Sample(i).c2Spd; __Sample(i).length; __Sample(i).loopLength; __Sample(i).loopStart; __Sample(i).loopEnd
    Next

    x = 1 + WindowWidth \ 2 - PatternDisplayWidth \ 2 ' find x so that we can center everything

    ' Print the pattern header
    Color 16, 3
    Locate , x: Print " PAT RW ";
    For i = 1 To __Song.channels
        Print " CHAN NOT S# FX OP ";
    Next
    Print

    Dim As Long startRow, startPat, nNote, nChan

    ' Get the current line number
    j = CsrLin

    ' Find thw pattern and row we print
    startPat = __Order(__Song.orderPosition)
    startRow = __Song.patternRow - (1 + TEXT_LINE_MAX - j) \ 2
    If startRow < 0 Then
        startRow = 1 + __PATTERN_ROW_MAX + startRow
        startPat = startPat - 1
    End If

    ' Now just dump everything to the screen
    For i = j To TEXT_LINE_MAX - 1
        Locate i, x
        Color 15, 0

        If startPat >= 0 And startPat <= __Song.highestPattern Then
            If i = j + (1 + TEXT_LINE_MAX - j) \ 2 Then
                Color 15, 1
            End If

            Print Using " ### ##:"; startPat; startRow;

            For nChan = 0 To __Song.channels - 1
                Color 14
                Print Using " (##)"; nChan + 1;
                nNote = __Pattern(startPat, startRow, nChan).note
                Color 10
                If nNote = __NOTE_NONE Then
                    Print "  -  ";
                ElseIf nNote = __NOTE_KEY_OFF Then
                    Print " ^^^ ";
                Else
                    Print Using " &# "; NoteTable(nNote Mod 12); nNote \ 12;
                End If
                Color 13
                Print Using "## "; __Pattern(startPat, startRow, nChan).sample;
                Color 11
                Print Right$(" " + Hex$(__Pattern(startPat, startRow, nChan).effect), 2); " ";
                Print Right$(" " + Hex$(__Pattern(startPat, startRow, nChan).operand), 2); " ";
            Next
        Else
            Print Space$(PatternDisplayWidth);
        End If

        startRow = startRow + 1
        ' Wrap if needed
        If startRow > __PATTERN_ROW_MAX Then
            startRow = 0
            startPat = startPat + 1
        End If
    Next

    ' Print the footer
    Color 16, 7
    Locate TEXT_LINE_MAX, x: Print Using " ####ms "; SndRawLen(SoftSynth.soundHandle) * 1000;
    For i = 0 To __Song.channels - 1
        Print Using " (##) V: ## P: ### "; i + 1, Voice(i).volume; Voice(i).panning;
    Next

    Dim As Long fftSamples, fftSamplesHalf, fftBits

    fftSamples = RoundDownToPowerOf2(__Song.samplesPerTick) ' we need power of 2 for our FFT function
    fftSamplesHalf = fftSamples \ 2
    fftBits = LeftShiftOneCount(fftSamples) ' Get the count of bits that the FFT routine will need

    ' Setup the FFT arrays (half of fftSamples)
    ReDim SpectrumAnalyzerLeft(0 To fftSamplesHalf - 1) As Unsigned Integer
    ReDim SpectrumAnalyzerRight(0 To fftSamplesHalf - 1) As Unsigned Integer

    AnalyzerFFTSingle Offset(SpectrumAnalyzerLeft(0)), Offset(MixerBufferLeft(0)), 1, fftBits ' the left samples first
    AnalyzerFFTSingle Offset(SpectrumAnalyzerRight(0)), Offset(MixerBufferRight(0)), 1, fftBits ' and now the right ones

    Color , 0

    For i = 0 To fftSamplesHalf - 1
        j = (i * SpectrumAnalyzerHeight) \ fftSamplesHalf ' this is the y location where we need to draw the bar

        ' First calculate and draw a bar on the left
        If SpectrumAnalyzerLeft(i) >= ANALYZER_SCALE Then
            x = SpectrumAnalyzerWidth - 1
        Else
            x = (SpectrumAnalyzerLeft(i) * (SpectrumAnalyzerWidth - 1)) \ ANALYZER_SCALE
        End If

        TextHLine SpectrumAnalyzerWidth - x, 1 + j, SpectrumAnalyzerWidth

        ' Next calculate for the one on the right and draw
        If SpectrumAnalyzerRight(i) >= ANALYZER_SCALE Then
            x = SpectrumAnalyzerWidth - 1
        Else
            x = (SpectrumAnalyzerRight(i) * (SpectrumAnalyzerWidth - 1)) \ ANALYZER_SCALE
        End If

        TextHLine 1 + SpectrumAnalyzerWidth + TEXT_WIDTH_HEADER, 1 + j, 1 + SpectrumAnalyzerWidth + TEXT_WIDTH_HEADER + x
    Next

    Display ' flip the framebuffer
End Sub


' Welcome screen loop
Function DoWelcomeScreen~%%
    Dim As Single starX(1 To TEXT_LINE_MAX), starY(1 To TEXT_LINE_MAX)
    Dim As Long starZ(1 To TEXT_LINE_MAX), starC(1 To TEXT_LINE_MAX)
    Dim k As Long, e As Unsigned Byte

    Do
        Cls , 0 ' clear the framebuffer to black color

        Locate 1, 1
        Color 14, 0
        Print "                                                 *        )  (       (                                                  "
        Print "                       (     (   (         )   (  `    ( /(  )\ )    )\ )  (                                            "
        Print "                     ( )\  ( )\  )\ )   ( /(   )\))(   )\())(()/(   (()/(  )\    )  (       (   (                       "
        Print "                     )((_) )((_)(()/(   )\()) ((_)()\ ((_)\  /(_))   /(_))((_)( /(  )\ )   ))\  )(                      "
        Print "                    ((_)_ ((_)_  /(_)) ((_)\  (_()((_)  ((_)(_))_   (_))   _  )(_))(()/(  /((_)(()\                     "
        Print "                     / _ \ | _ )(_) / | | (_) |  \/  | / _ \ |   \  | _ \ | |((_)_  )(_))(_))   ((_)                    "
        Print "                    | (_) || _ \ / _ \|_  _|  | |\/| || (_) || |) | |  _/ | |/ _` || || |/ -_) | '_|                    "
        Print "_.___________________\__\_\|___/ \___/  |_|   |_|  |_| \___/ |___/  |_|   |_|\__,_| \_, |\___| |_|____________________._"
        Print "                                                                                    |__/                                "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "F1";: Color 8: Print " ............ ";: Color 13: Print "MULTI-SELECT FILES";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "F2";: Color 8: Print " .......... ";: Color 13: Print "PLAY FROM MODARCHIVE";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "ESC";: Color 8: Print " .................... ";: Color 13: Print "NEXT/QUIT";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "SPC";: Color 8: Print " ........................ ";: Color 13: Print "PAUSE";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "=|+";: Color 8: Print " .............. ";: Color 13: Print "INCREASE VOLUME";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "-|_";: Color 8: Print " .............. ";: Color 13: Print "DECREASE VOLUME";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "L|l";: Color 8: Print " ......................... ";: Color 13: Print "LOOP";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "Q|q";: Color 8: Print " ................ ";: Color 13: Print "INTERPOLATION";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "<-";: Color 8: Print " ........................ ";: Color 13: Print "REWIND";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print "->";: Color 8: Print " ....................... ";: Color 13: Print "FORWARD";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                     ";: Color 9: Print "DRAG AND DROP MULTIPLE MOD FILES ON THIS WINDOW TO PLAY THEM SEQUENTIALLY.";: Color 14: Print "                     | "
        Print " |                                                                                                                    | "
        Print " |                     ";: Color 9: Print "YOU CAN ALSO START THE PROGRAM WITH MULTIPLE FILES FROM THE COMMAND LINE.";: Color 14: Print "                      | "
        Print " |                                                                                                                    | "
        Print " |                    ";: Color 9: Print "THIS WAS WRITTEN PURELY IN QB64 AND THE SOURCE CODE IS AVAILABLE ON GITHUB.";: Color 14: Print "                     | "
        Print " |                                                                                                                    | "
        Print " |                                     ";: Color 9: Print "https://github.com/a740g/QB64-MOD-Player";: Color 14: Print "                                       | "
        Print "_|_                                                                                                                  _|_"
        Print " `/__________________________________________________________________________________________________________________\' ";

        ' Text mode starfield. Hell yeah!
        For k = 1 To TEXT_LINE_MAX
            If starX(k) < 1 Or starX(k) > WindowWidth Or starY(k) < 1 Or starY(k) > TEXT_LINE_MAX Then

                starX(k) = RandomBetween(1 + WindowWidth \ 4, WindowWidth - WindowWidth \ 4)
                starY(k) = RandomBetween(1 + TEXT_LINE_MAX \ 4, TEXT_LINE_MAX - TEXT_LINE_MAX \ 4)
                starZ(k) = 4096
                starC(k) = RandomBetween(9, 15)
            End If

            Locate starY(k), starX(k)
            Color starC(k)
            Print "*";

            starZ(k) = starZ(k) + 1
            starX(k) = ((starX(k) - (WindowWidth / 2)) * (starZ(k) / 4096)) + (WindowWidth / 2)
            starY(k) = ((starY(k) - (TEXT_LINE_MAX / 2)) * (starZ(k) / 4096)) + (TEXT_LINE_MAX / 2)
        Next

        k = KeyHit

        If k = KEY_ESCAPE Then
            e = EVENT_QUIT
        ElseIf TotalDroppedFiles > 0 Then
            e = EVENT_DROP
        ElseIf k = KEY_F1 Then
            e = EVENT_LOAD
        ElseIf k = KEY_F2 Then
            e = EVENT_HTTP
        End If

        Display ' flip the framebuffer

        Limit FRAME_RATE_MIN
    Loop While e = EVENT_NONE

    DoWelcomeScreen = e
End Function


' Loads the note string table
Sub InitializeNoteTable
    Dim As Unsigned Byte n, v
    Restore NoteTab
    Read v
    ReDim NoteTable(0 To v - 1) As String * 2
    For n = 0 To v - 1
        Read NoteTable(n)
    Next

    ' Note string table for UI
    NoteTab:
    Data 12
    Data "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"
End Sub


' Automatically selects, sets the window size and saves the text width
Sub AdjustWindowSize
    Shared __Song As __SongType

    If __Song.isPlaying Then
        PatternDisplayWidth = 8 + __Song.channels * 19 ' find the actual width
        WindowWidth = PatternDisplayWidth
        If WindowWidth < TEXT_WIDTH_MIN Then WindowWidth = TEXT_WIDTH_MIN ' we don't want the width to be too small
        SpectrumAnalyzerWidth = (WindowWidth - TEXT_WIDTH_HEADER) \ 2
        If PatternDisplayWidth <= TEXT_WIDTH_HEADER Then
            SpectrumAnalyzerHeight = TEXT_LINE_MAX
        Else
            SpectrumAnalyzerHeight = 4 + __Song.samples
        End If
    Else
        PatternDisplayWidth = 0
        WindowWidth = TEXT_WIDTH_MIN ' we don't want the width to be too small
        SpectrumAnalyzerWidth = 0
        SpectrumAnalyzerHeight = 0
    End If

    Width WindowWidth, TEXT_LINE_MAX ' we need 75 lines for the vizualization stuff
    ControlChr Off ' turn off control characters
    Font 8 ' force 8x8 pixel font
    Blink Off ' we want high intensity colors
    Cls ' clear the screen
    Locate , , FALSE ' turn cursor off
End Sub


' Initializes, loads and plays a mod file
' Also checks for input, shows info etc
Function PlaySong~%% (fileName As String)
    Shared __Song As __SongType
    Shared SoftSynth As SoftSynthType

    PlaySong = EVENT_PLAY ' default event is to play next song

    Dim buffer As String: buffer = LoadFile(fileName) ' load the whole file to memory

    If Not LoadMODFromMemory(buffer) Then
        MessageBox APP_NAME, "Failed to load: " + fileName, "error"

        Exit Function
    End If

    ' Set the app title to display the file name
    Dim windowTitle As String: windowTitle = APP_NAME + " - " + GetFileNameFromPathOrURL(fileName)
    Title windowTitle

    StartMODPlayer
    AdjustWindowSize

    SetGlobalVolume Volume
    EnableHQMixer HighQuality

    Dim As Long k, nFPS

    Do
        UpdateMODPlayer

        PrintVisualization

        k = KeyHit

        Select Case k
            Case KEY_SPACE_BAR
                __Song.isPaused = Not __Song.isPaused

            Case KEY_PLUS, KEY_EQUALS
                SetGlobalVolume Volume + 1
                Volume = SoftSynth.volume

            Case KEY_MINUS, KEY_UNDERSCORE
                SetGlobalVolume Volume - 1
                Volume = SoftSynth.volume

            Case KEY_UPPER_L, KEY_LOWER_L
                __Song.isLooping = Not __Song.isLooping

            Case KEY_UPPER_Q, KEY_LOWER_Q
                HighQuality = Not HighQuality
                EnableHQMixer HighQuality

            Case KEY_LEFT_ARROW
                __Song.orderPosition = __Song.orderPosition - 1
                If __Song.orderPosition < 0 Then __Song.orderPosition = __Song.orders - 1
                __Song.patternRow = 0

            Case KEY_RIGHT_ARROW
                __Song.orderPosition = __Song.orderPosition + 1
                If __Song.orderPosition >= __Song.orders Then __Song.orderPosition = 0
                __Song.patternRow = 0

            Case KEY_F1
                PlaySong = EVENT_LOAD
                Exit Do

            Case KEY_F6 ' quick save for files loaded from ModArchive
                OnQuickSave buffer, fileName

            Case 21248 ' Shift + Delete - you known what it does
                If Len(GetDriveOrSchemeFromPathOrURL(fileName)) > 2 Then
                    MessageBox APP_NAME, "You cannot delete " + fileName + "!", "error"
                Else
                    If MessageBox(APP_NAME, "Are you sure you want to delete " + fileName + " permanently?", "yesno", "question", 0) = 1 Then
                        Kill fileName
                        Exit Do
                    End If
                End If
        End Select

        If TotalDroppedFiles > 0 Then
            PlaySong = EVENT_DROP

            Exit Do
        End If

        HighQuality = SoftSynth.useHQMixer ' Since this can be changed by the playing MOD

        nFPS = MaxLong(FRAME_RATE_MIN, (12 * __Song.bpm * (31 - __Song.speed)) \ 625) ' we'll only update at the rate we really need
        If GetTicks Mod 15 = 0 Then Title windowTitle + " (" + LTrim$(Str$(nFPS)) + " FPS)"

        Limit nFPS
    Loop Until Not __Song.isPlaying Or k = KEY_ESCAPE

    StopMODPlayer
    AdjustWindowSize

    Title APP_NAME + " " + OS$ ' Set app title to the way it was
End Function


' Processes the command line one file at a time
Function ProcessCommandLine~%%
    Dim i As Unsigned Long
    Dim e As Unsigned Byte: e = EVENT_NONE

    If (Command$(1) = "/?" Or Command$(1) = "-?") Then
        MessageBox APP_NAME, APP_NAME + Chr$(13) + "Syntax: QB64MODP [modfile.mod]" + Chr$(13) + "    /?: Shows this message" + String$(2, 13) + "Copyright (c) 2023, Samuel Gomes" + String$(2, 13) + "https://github.com/a740g/", "info"
        e = EVENT_QUIT
    Else
        For i = 1 To CommandCount
            e = PlaySong(Command$(i))
            If e <> EVENT_PLAY Then Exit For
        Next
    End If

    ProcessCommandLine = e
End Function


' Processes dropped files one file at a time
Function ProcessDroppedFiles~%%
    ' Make a copy of the dropped file and clear the list
    ReDim fileNames(1 To TotalDroppedFiles) As String
    Dim i As Unsigned Long
    Dim e As Unsigned Byte: e = EVENT_NONE

    For i = 1 To TotalDroppedFiles
        fileNames(i) = DroppedFile(i)
    Next
    FinishDrop ' This is critical

    ' Now play the dropped file one at a time
    For i = LBound(fileNames) To UBound(fileNames)
        e = PlaySong(fileNames(i))
        If e <> EVENT_PLAY Then Exit For
    Next

    ProcessDroppedFiles = e
End Function


' Processes a list of files selected by the user
Function ProcessSelectedFiles~%%
    Dim ofdList As String
    Dim e As Unsigned Byte: e = EVENT_NONE

    ofdList = OpenFileDialog$(APP_NAME, "", "*.mod|*.MOD|*.Mod", "Music Tracker Files", TRUE)

    If ofdList = NULLSTRING Then Exit Function

    ReDim fileNames(0 To 0) As String
    Dim As Long i, j

    j = TokenizeString(ofdList, "|", NULLSTRING, FALSE, fileNames())

    For i = 0 To j - 1
        e = PlaySong(fileNames(i))
        If e <> EVENT_PLAY Then Exit For
    Next

    ProcessSelectedFiles = e
End Function


' Loads and plays random MODs from modarchive.org
Function ProcessModArchiveFiles~%%
    Dim e As Unsigned Byte: e = EVENT_NONE
    Dim modArchiveFileName As String

    Do
        Do
            modArchiveFileName = GetRandomModArchiveFileName$

            Title APP_NAME + " - Downloading: " + GetFileNameFromPathOrURL(modArchiveFileName)

            If TotalDroppedFiles > 0 Then
                e = EVENT_DROP
                Exit Do
            End If

            If KeyHit = KEY_F1 Then
                e = EVENT_LOAD
                Exit Do
            End If
        Loop Until LCase$(GetFileExtensionFromPathOrURL(modArchiveFileName)) = ".mod"

        If e <> EVENT_NONE And e <> EVENT_PLAY Then Exit Do

        e = PlaySong(modArchiveFileName)
    Loop

    Title APP_NAME + " " + OS$ ' Set app title to the way it was

    ProcessModArchiveFiles = e
End Function


' Draw a horizontal line using text and colors it too! Sweet! XD
Sub TextHLine (xs As Long, y As Long, xe As Long)
    Dim l As Long
    l = 1 + xe - xs
    Color 9 + l Mod 7
    Locate y, xs
    Print String$(l, 254);
End Sub


' Gets a random file URL from www.modarchive.org
Function GetRandomModArchiveFileName$
    Const THE_MOD_ARCHIVE_SEARCH_URL = "https://api.modarchive.org/downloads.php?moduleid="

    Dim buffer As String: buffer = LoadFileFromURL("https://modarchive.org/index.php?request=view_random")
    Dim bufPos As Long: bufPos = InStr(buffer, THE_MOD_ARCHIVE_SEARCH_URL)

    If bufPos > 0 Then
        GetRandomModArchiveFileName = Mid$(buffer, bufPos, InStr(bufPos, buffer, Chr$(34)) - bufPos)
    End If
End Function


' Saves a file loaded from the internet
Sub OnQuickSave (buffer As String, fileName As String)
    Static savePath As String, alwaysUseSamePath As Byte, stopNagging As Byte

    If Len(GetDriveOrSchemeFromPathOrURL(fileName)) > 2 Then
        ' This is a file from the web
        If Not DirExists(savePath) Or Not alwaysUseSamePath Then ' only get the path if path does not exist or user wants to use a new path
            savePath = SelectFolderDialog$("Select a folder to save the file:", savePath)
            If savePath = NULLSTRING Then Exit Sub ' exit if user cancelled

            savePath = FixPathDirectoryName(savePath)
        End If

        Dim saveFileName As String: saveFileName = savePath + GetLegalFileName(fileName)

        If FileExists(saveFileName) Then
            If MessageBox(APP_NAME, "Overwrite " + saveFileName + "?", "yesno", "warning", 0) = 0 Then Exit Sub
        End If

        If SaveFile(buffer, saveFileName, TRUE) Then MessageBox APP_NAME, saveFileName + " saved.", "info"

        ' Check if user want to use the same path in the future
        If Not stopNagging Then
            Select Case MessageBox(APP_NAME, "Do you want to use " + savePath + " for future saves?", "yesnocancel", "question", 1)
                Case 0
                    stopNagging = TRUE
                Case 1
                    alwaysUseSamePath = TRUE
                Case 2
                    alwaysUseSamePath = FALSE
            End Select
        End If
    Else
        ' This is a local file - do nothing
        MessageBox APP_NAME, "You cannot save local file " + fileName + "!", "error"
    End If
End Sub


' Generates a legal filename from a modarchive download URL
Function GetLegalFileName$ (url As String)
    Dim fileName As String: fileName = GetFileNameFromPathOrURL(url)
    fileName = Mid$(fileName, InStr(fileName, "=") + 1) ' this will get a file name of type: 12312313#filename.mod

    Dim i As Long, s As String, c As Unsigned Byte

    ' Clean any unwanted characters
    For i = 1 To Len(fileName)
        c = Asc(fileName, i)
        Select Case c
            Case 92, 47, 42, 63, 124
                s = s + "_"
            Case 58
                s = s + "-"
            Case 60
                s = s + "{"
            Case 62
                s = s + "}"
            Case 34
                s = s + "'"
            Case Else
                s = s + Chr$(c)
        End Select
    Next

    GetLegalFileName = s
End Function
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------------------------
'$Include:'include/MODPlayer.bas'
'$Include:'include/StringOps.bas'
'$Include:'include/FileOps.bas'
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------
