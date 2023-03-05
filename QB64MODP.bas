'-----------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2023 Samuel Gomes
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------
'$Include:'./include/MODPlayer.bi'
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------
$ExeIcon:'./QB64MODP.ico'
$VersionInfo:CompanyName='Samuel Gomes'
$VersionInfo:FileDescription='QB64 MOD Player executable'
$VersionInfo:InternalName='QB64 MOD Player'
$VersionInfo:LegalCopyright='Copyright (c) 2022, Samuel Gomes'
$VersionInfo:LegalTrademarks='All trademarks are property of their respective owners'
$VersionInfo:OriginalFilename='QB64MODP.exe'
$VersionInfo:ProductName='QB64 MOD Player'
$VersionInfo:Web='https://github.com/a740g'
$VersionInfo:Comments='https://github.com/a740g'
$VersionInfo:FILEVERSION#=1,8,0,0
$VersionInfo:PRODUCTVERSION#=1,8,0,0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
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
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' EXTERNAL LIBRARIES
'-----------------------------------------------------------------------------------------------------
Declare CustomType Library "./fft"
    Sub fft_analyze_short (ByVal ana As Offset, Byval samp As Offset, Byval inc As Long, Byval bits As Long)
    Sub fft_analyze_float (ByVal ana As Offset, Byval samp As Offset, Byval inc As Long, Byval bits As Long)
    Function fft_previous_power_of_two~& (ByVal x As Unsigned Long)
    Function fft_left_shift_one_count~& (ByVal x As Unsigned Long)
End Declare
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------
ReDim Shared NoteTable(0 To 0) As String * 2 ' this contains the note stings
Dim Shared WindowWidth As Long ' the width of our windows in characters
Dim Shared PatternDisplayWidth As Long ' the width of the pattern display in characters
Dim Shared SpectrumAnalyzerWidth As Long ' the width of the spectrum analyzer
Dim Shared SpectrumAnalyzerHeight As Long ' the height of the spectrum analyzer
Dim Shared Volume As Integer ' this is needed because the replayer can reset volume across songs
Dim Shared HighQuality As Byte ' this is needed because the replayer can reset quality across songs
ReDim Shared SpectrumAnalyzerLeft(0 To 0) As Unsigned Integer ' left channel FFT data
ReDim Shared SpectrumAnalyzerRight(0 To 0) As Unsigned Integer ' right channel FFT data
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Frankenstein retro TUI with drag & drop support
'-----------------------------------------------------------------------------------------------------
Title APP_NAME + " " + OS$ ' set the program name in the titlebar
ChDir StartDir$ ' change to the directory specifed by the environment
AcceptFileDrop ' enable drag and drop of files
InitializeNoteTable ' initialize note string table
AdjustWindowSize ' set the initial window size
AllowFullScreen SquarePixels , Smooth ' allow the user to press Alt+Enter to go fullscreen
Randomize Timer ' seed RNG
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

        Case Else
            event = DoWelcomeScreen
    End Select
Loop

AutoDisplay
System
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------
' This "prints" the current playing MODs visualization on the screen
Sub PrintVisualization
    ' These are internal variables and arrays used by the MODPlayer library
    Shared Song As SongType
    Shared Order() As Unsigned Byte
    Shared Pattern() As NoteType
    Shared Sample() As SampleType
    Shared SoftSynth As SoftSynthType
    Shared Voice() As VoiceType
    Shared MixerBufferLeft() As Single
    Shared MixerBufferRight() As Single

    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then Order(Song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    If Song.orderPosition >= Song.orders Then Exit Sub

    Cls , 0 ' clear the framebuffer to black color

    Dim x As Long
    x = 1 + WindowWidth \ 2 - TEXT_WIDTH_HEADER \ 2 ' find x so that we can center everything

    ' Print song type and name
    Color 15, 5
    Locate 1, x: Print Using "  \  \: \                                                                        \  "; Song.subtype; Song.songName

    ' Print the header
    Color 16, 15
    Locate , x: Print Using "  ORD: ### / ### | PAT: ### / ### | ROW: ## / 63 | CHN: ### / ### | VOC: ### / ###  "; Song.orderPosition; Song.orders - 1; Order(Song.orderPosition); Song.highestPattern; Song.patternRow; Song.activeChannels; Song.channels; SoftSynth.activeVoices; SoftSynth.voices
    Locate , x: Print Using "  BPM: ###       | SPD: ###       | VOL: \\ / FF |  HQ: \       \ | REP: \       \  "; Song.bpm; Song.speed; Right$("0" + Hex$(Volume), 2); BoolToStr(HighQuality, 1); BoolToStr(Song.isLooping, 2)

    ' Print the sample list header
    Color 16, 3
    Locate , x: Print "  S#  SAMPLE-NAME              VOLUME C2SPD LENGTH LOOP-LENGTH LOOP-START LOOP-END  "

    ' Print the sample information
    Dim As Long i, j
    For i = 0 To Song.samples - 1
        Color 14, 0
        For j = 0 To Song.channels - 1
            If i + 1 = Pattern(Order(Song.orderPosition), Song.patternRow, j).sample Then
                Color 13, 1
            End If
        Next
        Locate , x: Print Using " ###: \                    \ ######## ##### ###### ########### ########## ########  "; i + 1; Sample(i).sampleName; Sample(i).volume; Sample(i).c2Spd; Sample(i).length; Sample(i).loopLength; Sample(i).loopStart; Sample(i).loopEnd
    Next

    x = 1 + WindowWidth \ 2 - PatternDisplayWidth \ 2 ' find x so that we can center everything

    ' Print the pattern header
    Color 16, 3
    Locate , x: Print " PAT RW ";
    For i = 1 To Song.channels
        Print " CHAN NOT S# FX OP ";
    Next
    Print

    Dim As Long startRow, startPat, nNote, nChan

    ' Get the current line number
    j = CsrLin

    ' Find thw pattern and row we print
    startPat = Order(Song.orderPosition)
    startRow = Song.patternRow - (1 + TEXT_LINE_MAX - j) \ 2
    If startRow < 0 Then
        startRow = 1 + PATTERN_ROW_MAX + startRow
        startPat = startPat - 1
    End If

    ' Now just dump everything to the screen
    For i = j To TEXT_LINE_MAX - 1
        Locate i, x
        Color 15, 0

        If startPat >= 0 And startPat <= Song.highestPattern Then
            If i = j + (1 + TEXT_LINE_MAX - j) \ 2 Then
                Color 15, 1
            End If

            Print Using " ### ##:"; startPat; startRow;

            For nChan = 0 To Song.channels - 1
                Color 14
                Print Using " (##)"; nChan + 1;
                nNote = Pattern(startPat, startRow, nChan).note
                Color 10
                If nNote = NOTE_NONE Then
                    Print "  -  ";
                ElseIf nNote = NOTE_KEY_OFF Then
                    Print " ^^^ ";
                Else
                    Print Using " &# "; NoteTable(nNote Mod 12); nNote \ 12;
                End If
                Color 13
                Print Using "## "; Pattern(startPat, startRow, nChan).sample;
                Color 11
                Print Right$(" " + Hex$(Pattern(startPat, startRow, nChan).effect), 2); " ";
                Print Right$(" " + Hex$(Pattern(startPat, startRow, nChan).operand), 2); " ";
            Next
        Else
            Print Space$(PatternDisplayWidth);
        End If

        startRow = startRow + 1
        ' Wrap if needed
        If startRow > PATTERN_ROW_MAX Then
            startRow = 0
            startPat = startPat + 1
        End If
    Next

    ' Print the footer
    Color 16, 7
    Locate TEXT_LINE_MAX, x: Print Using " ####ms "; SndRawLen(SoftSynth.soundHandle) * 1000;
    For i = 0 To Song.channels - 1
        Print Using " (##) V: ## P: ### "; i + 1, Voice(i).volume; Voice(i).panning;
    Next

    Dim As Long fftSamples, fftSamplesHalf, fftBits

    fftSamples = fft_previous_power_of_two(Song.samplesPerTick) ' we need power of 2 for our FFT function
    fftSamplesHalf = fftSamples \ 2
    fftBits = fft_left_shift_one_count(fftSamples) ' Get the count of bits that the FFT routine will need

    ' Setup the FFT arrays (half of fftSamples)
    ReDim SpectrumAnalyzerLeft(0 To fftSamplesHalf - 1) As Unsigned Integer
    ReDim SpectrumAnalyzerRight(0 To fftSamplesHalf - 1) As Unsigned Integer

    fft_analyze_float Offset(SpectrumAnalyzerLeft(0)), Offset(MixerBufferLeft(0)), 1, fftBits ' the left samples first
    fft_analyze_float Offset(SpectrumAnalyzerRight(0)), Offset(MixerBufferRight(0)), 1, fftBits ' and now the right ones

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
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print " F1";: Color 8: Print " ........... ";: Color 13: Print "MULTI-SELECT FILES";: Color 14: Print "                                         | "
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
        Print " |                                         ";: Color 11: Print " <-";: Color 8: Print " ....................... ";: Color 13: Print "REWIND";: Color 14: Print "                                         | "
        Print " |                                                                                                                    | "
        Print " |                                                                                                                    | "
        Print " |                                         ";: Color 11: Print " ->";: Color 8: Print " ...................... ";: Color 13: Print "FORWARD";: Color 14: Print "                                         | "
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
    Shared Song As SongType

    If Song.isPlaying Then
        PatternDisplayWidth = 8 + Song.channels * 19 ' find the actual width
        WindowWidth = PatternDisplayWidth
        If WindowWidth < TEXT_WIDTH_MIN Then WindowWidth = TEXT_WIDTH_MIN ' we don't want the width to be too small
        SpectrumAnalyzerWidth = (WindowWidth - TEXT_WIDTH_HEADER) \ 2
        If PatternDisplayWidth <= TEXT_WIDTH_HEADER Then
            SpectrumAnalyzerHeight = TEXT_LINE_MAX
        Else
            SpectrumAnalyzerHeight = 4 + Song.samples
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
    Shared Song As SongType
    Shared SoftSynth As SoftSynthType

    PlaySong = EVENT_PLAY ' default event is to play next song

    If Not LoadMODFile(fileName) Then
        MessageBox APP_NAME, "Failed to load: " + fileName, "error"

        Exit Function
    End If

    ' Set the app title to display the file name
    Title APP_NAME + " - " + GetFileNameFromPath(fileName)

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
                Song.isPaused = Not Song.isPaused

            Case KEY_PLUS, KEY_EQUALS
                SetGlobalVolume Volume + 1
                Volume = SoftSynth.volume

            Case KEY_MINUS, KEY_UNDERSCORE
                SetGlobalVolume Volume - 1
                Volume = SoftSynth.volume

            Case KEY_UPPER_L, KEY_LOWER_L
                Song.isLooping = Not Song.isLooping

            Case KEY_UPPER_Q, KEY_LOWER_Q
                HighQuality = Not HighQuality
                EnableHQMixer HighQuality

            Case KEY_LEFT_ARROW
                Song.orderPosition = Song.orderPosition - 1
                If Song.orderPosition < 0 Then Song.orderPosition = Song.orders - 1
                Song.patternRow = 0

            Case KEY_RIGHT_ARROW
                Song.orderPosition = Song.orderPosition + 1
                If Song.orderPosition >= Song.orders Then Song.orderPosition = 0
                Song.patternRow = 0

            Case KEY_F1
                PlaySong = EVENT_LOAD
                Exit Do

            Case 21248 ' Shift + Delete - you known what it does
                If MessageBox(APP_NAME, "Are you sure you want to delete " + fileName + " permanently?", "yesno", "question", 0) = 1 Then
                    Kill fileName

                    Exit Do
                End If
        End Select

        If TotalDroppedFiles > 0 Then
            PlaySong = EVENT_DROP

            Exit Do
        End If

        HighQuality = SoftSynth.useHQMixer ' Since this can be changed by the playing MOD

        ' We'll only update at the rate we really need
        nFPS = (12 * Song.bpm * (31 - Song.speed)) \ 625 ' XD
        If nFPS < FRAME_RATE_MIN Then nFPS = FRAME_RATE_MIN ' clamp it to 60 min
        Limit nFPS
    Loop Until Not Song.isPlaying Or k = KEY_ESCAPE

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

    j = ParseOpenFileDialogList(ofdList, fileNames())

    For i = 0 To j - 1
        e = PlaySong(fileNames(i))
        If e <> EVENT_PLAY Then Exit For
    Next

    ProcessSelectedFiles = e
End Function


' Gets the filename portion from a file path
Function GetFileNameFromPath$ (pathName As String)
    Dim i As Unsigned Long

    ' Retrieve the position of the first / or \ in the parameter from the
    For i = Len(pathName) To 1 Step -1
        If Asc(pathName, i) = 47 Or Asc(pathName, i) = 92 Then Exit For
    Next

    ' Return the full string if pathsep was not found
    If i = 0 Then
        GetFileNameFromPath = pathName
    Else
        GetFileNameFromPath = Right$(pathName, Len(pathName) - i)
    End If
End Function


' Gets a string form of the boolean value passed
Function BoolToStr$ (expression As Long, style As Unsigned Byte)
    Select Case style
        Case 1
            If expression Then BoolToStr = "On" Else BoolToStr = "Off"
        Case 2
            If expression Then BoolToStr = "Enabled" Else BoolToStr = "Disabled"
        Case 3
            If expression Then BoolToStr = "1" Else BoolToStr = "0"
        Case Else
            If expression Then BoolToStr = "True" Else BoolToStr = "False"
    End Select
End Function


' Generates a random number between lo & hi
Function RandomBetween& (lo As Long, hi As Long)
    RandomBetween = lo + Rnd * (hi - lo)
End Function


' Draw a horizontal line using text and colors it too! Sweet! XD
Sub TextHLine (xs As Long, y As Long, xe As Long)
    Dim l As Long
    l = 1 + xe - xs
    Color 9 + l Mod 7
    Locate y, xs
    Print String$(l, 254);
End Sub


' This is a simple text parser that can take an input string from OpenFileDialog$ and spit out discrete filepaths in an array
' Returns the number of strings parsed
Function ParseOpenFileDialogList& (ofdList As String, ofdArray() As String)
    Dim As Long p, c
    Dim ts As String

    ReDim ofdArray(0 To 0) As String
    ts = ofdList

    Do
        p = InStr(ts, "|")

        If p = 0 Then
            ofdArray(c) = ts

            ParseOpenFileDialogList& = c + 1
            Exit Function
        End If

        ofdArray(c) = Left$(ts, p - 1)
        ts = Mid$(ts, p + 1)

        c = c + 1
        ReDim Preserve ofdArray(0 To c) As String
    Loop
End Function
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------
'$Include:'./include/MODPlayer.bas'
'-----------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------

