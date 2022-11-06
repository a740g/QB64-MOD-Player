'-----------------------------------------------------------------------------------------------------
' QB64 MOD Player
' Copyright (c) 2022 Samuel Gomes
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
$VersionInfo:FILEVERSION#=1,5,0,11
$VersionInfo:PRODUCTVERSION#=1,5,0,0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
Const APP_NAME = "QB64 MOD Player" ' application name
Const TEXT_LINE_MAX = 75 ' this the number of lines we need
Const TEXT_WIDTH_MIN = 120 ' minimum width we need
Const TEXT_WIDTH_HEADER = 84 ' width of the main header on the vis screen
Const FRAME_RATE_MAX = 120 ' maximum frame rate we'll allow
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
' FFT arrays
ReDim Shared As Single lSig(0 To 0), rSig(0 To 0)
ReDim Shared As Single FFTr(0 To 0), FFTi(0 To 0)
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Frankenstein retro TUI with drag & drop support
'-----------------------------------------------------------------------------------------------------
Title APP_NAME + " " + OS$ ' Set the program name in the titlebar
ChDir StartDir$ ' Change to the directory specifed by the environment
AcceptFileDrop ' Enable drag and drop of files
InitializeNoteTable ' Initialize note string table
AdjustWindowSize ' Set the initial window size
AllowFullScreen SquarePixels , Smooth ' Allow the user to press Alt+Enter to go fullscreen
Volume = GLOBAL_VOLUME_MAX ' Set global volume to maximum
HighQuality = TRUE ' Enable interpolated mixing by default
ProcessCommandLine ' Check if any files were specified in the command line

Dim k As Long

' Main loop
Do
    ProcessDroppedFiles
    PrintWelcomeScreen
    k = KeyHit

    If k = 15104 Then ProcessSelectedFiles ' Shows open file dialog

    Limit FRAME_RATE_MAX
Loop Until k = 27

System 0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------
' This "prints" the current playing MODs visualization on the screen
Sub PrintVisualization
    Shared Song As SongType
    Shared Order() As Unsigned Byte
    Shared Pattern() As NoteType
    Shared Sample() As SampleType
    Shared SoftSynth As SoftSynthType
    Shared MixerBuffer() As Single

    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then Order(Song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    If Song.orderPosition >= Song.orders Then Exit Sub

    Screen , , 1, 0 ' we'll do all writes to an invisible page and then simply copy that page once we are done
    Cls ' clear the page

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

    ' Now just dump everything top to the screen
    For i = j To TEXT_LINE_MAX
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

    Dim samples As Long

    samples = RoundDownPower2(Song.samplesPerTick) ' we need power of 2 for our FFT function

    ' Setup the FFT arrays
    ReDim As Single lSig(0 To samples - 1), rSig(0 To samples - 1)
    ReDim As Single FFTr(0 To samples - 1), FFTi(0 To samples - 1)

    ' Fill the FFT arrays with sample data
    For i = 0 To samples - 1
        lSig(i) = MixerBuffer(MIXER_CHANNEL_LEFT, i)
        rSig(i) = MixerBuffer(MIXER_CHANNEL_RIGHT, i)
    Next

    ' TODO: The scaling (* 0.4) and frequency (\ 6) factors are hard coded and this not good
    '   Esp. since the width and height of the spectrum alalyzers can change
    '   So, these hard coded values should be dynamic based on the width and height

    RFFT FFTr(), FFTi(), lSig(), samples ' the left samples first

    For i = 0 To SpectrumAnalyzerHeight - 1
        x = i * (samples \ 6) \ SpectrumAnalyzerHeight
        j = Clamp(Sqr((FFTr(x) * FFTr(x)) + (FFTi(x) * FFTi(x))) * 0.4, 0, SpectrumAnalyzerWidth - 1)
        TextHLine SpectrumAnalyzerWidth - j, 1 + i, SpectrumAnalyzerWidth
    Next

    RFFT FFTr(), FFTi(), rSig(), samples ' and now the right ones

    For i = 0 To SpectrumAnalyzerHeight - 1
        x = i * (samples \ 6) \ SpectrumAnalyzerHeight
        j = Clamp(Sqr((FFTr(x) * FFTr(x)) + (FFTi(x) * FFTi(x))) * 0.4, 0, SpectrumAnalyzerWidth - 1)
        TextHLine 1 + SpectrumAnalyzerWidth + TEXT_WIDTH_HEADER, 1 + i, 1 + SpectrumAnalyzerWidth + TEXT_WIDTH_HEADER + j
    Next

    PCopy 1, 0 ' now just copy the working page to the visual page
    Screen , , 0, 0 ' set the the visual page as the working page
End Sub


' Print the welcome screen
Sub PrintWelcomeScreen
    Static As Single starX(1 To TEXT_LINE_MAX), starY(1 To TEXT_LINE_MAX)
    Static As Long starZ(1 To TEXT_LINE_MAX), starC(1 To TEXT_LINE_MAX)

    Screen , , 1, 0 ' this is for the starfield stuff
    Cls ' same as above
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
    Print " |                                                                                                                    | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print " F1";: Color 8: Print " ........... ";: Color 13: Print "MULTI-SELECT FILES";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "ESC";: Color 8: Print " .................... ";: Color 13: Print "NEXT/QUIT";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "SPC";: Color 8: Print " ........................ ";: Color 13: Print "PAUSE";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "=|+";: Color 8: Print " .............. ";: Color 13: Print "INCREASE VOLUME";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "-|_";: Color 8: Print " .............. ";: Color 13: Print "DECREASE VOLUME";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "L|l";: Color 8: Print " ......................... ";: Color 13: Print "LOOP";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "Q|q";: Color 8: Print " ................ ";: Color 13: Print "INTERPOLATION";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "<|,";: Color 8: Print " ....................... ";: Color 13: Print "REWIND";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print ">|.";: Color 8: Print " ...................... ";: Color 13: Print "FORWARD";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "I|i";: Color 8: Print " ............. ";: Color 13: Print "INFORMATION VIEW";: Color 14: Print "                                         | "
    Print " |                                                                                                                    | "
    Print " |                                         ";: Color 11: Print "V|v";: Color 8: Print " ................. ";: Color 13: Print "PATTERN VIEW";: Color 14: Print "                                         | "
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
    Dim i As Long
    For i = 1 To TEXT_LINE_MAX
        If starX(i) < 1 Or starX(i) > WindowWidth Or starY(i) < 1 Or starY(i) > TEXT_LINE_MAX Then

            starX(i) = RandomBetween(1 + WindowWidth \ 4, WindowWidth - WindowWidth \ 4)
            starY(i) = RandomBetween(1 + TEXT_LINE_MAX \ 4, TEXT_LINE_MAX - TEXT_LINE_MAX \ 4)
            starZ(i) = 4096
            starC(i) = RandomBetween(9, 15)
        End If

        Locate starY(i), starX(i)
        Color starC(i)
        Print "*";

        starZ(i) = starZ(i) + 1
        starX(i) = ((starX(i) - (WindowWidth / 2)) * (starZ(i) / 4096)) + (WindowWidth / 2)
        starY(i) = ((starY(i) - (TEXT_LINE_MAX / 2)) * (starZ(i) / 4096)) + (TEXT_LINE_MAX / 2)
    Next

    PCopy 1, 0 ' now just copy the working page to the visual page
    Screen , , 0, 0 ' set the the visual page as the working page
End Sub


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

    Width WindowWidth, TEXT_LINE_MAX ' we need 52 lines for the vizualization stuff
    ControlChr Off ' turn off control characters
    Font 8 ' force 8x8 pixel font
    Blink Off ' we want high intensity colors
    Cls ' clear the screen
    Locate , , FALSE ' turn cursor off
End Sub


' Initializes, loads and plays a mod file
' Also checks for input, shows info etc
Sub PlaySong (fileName As String)
    Shared Song As SongType
    Shared SoftSynth As SoftSynthType

    If Not LoadMODFile(fileName) Then
        Color 12
        Print: Print "Failed to load "; fileName; "!"
        Sleep 5
        Exit Sub
    End If

    ' Set the app title to display the file name
    Title APP_NAME + " - " + GetFileNameFromPath(fileName)

    StartMODPlayer
    AdjustWindowSize

    Dim k As Long

    SetGlobalVolume Volume
    EnableHQMixer HighQuality

    Do
        UpdateMODPlayer
        PrintVisualization

        k = KeyHit

        Select Case k
            Case 32
                Song.isPaused = Not Song.isPaused

            Case 43, 61
                SetGlobalVolume Volume + 1
                Volume = SoftSynth.volume

            Case 45, 95
                SetGlobalVolume Volume - 1
                Volume = SoftSynth.volume

            Case 76, 108
                Song.isLooping = Not Song.isLooping

            Case 81, 113
                HighQuality = Not HighQuality
                EnableHQMixer HighQuality

            Case 44, 60
                Song.orderPosition = Song.orderPosition - 1
                If Song.orderPosition < 0 Then Song.orderPosition = Song.orders - 1
                Song.patternRow = 0

            Case 46, 62
                Song.orderPosition = Song.orderPosition + 1
                If Song.orderPosition >= Song.orders Then Song.orderPosition = 0
                Song.patternRow = 0
        End Select

        HighQuality = SoftSynth.useHQMixer ' Since this can be changed by the playing MOD

        Limit FRAME_RATE_MAX
    Loop Until Not Song.isPlaying Or k = 27 Or TotalDroppedFiles > 0

    StopMODPlayer
    AdjustWindowSize

    Title APP_NAME + " " + OS$ ' Set app title to the way it was
End Sub


' Processes the command line one file at a time
Sub ProcessCommandLine
    Dim i As Unsigned Long

    For i = 1 To CommandCount
        PlaySong Command$(i)
        If TotalDroppedFiles > 0 Then Exit For ' Exit the loop if we have dropped files
    Next
End Sub


' Processes dropped files one file at a time
Sub ProcessDroppedFiles
    If TotalDroppedFiles > 0 Then
        ' Make a copy of the dropped file and clear the list
        ReDim fileNames(1 To TotalDroppedFiles) As String
        Dim i As Unsigned Long

        For i = 1 To TotalDroppedFiles
            fileNames(i) = DroppedFile(i)
        Next
        FinishDrop ' This is critical

        ' Now play the dropped file one at a time
        For i = LBound(fileNames) To UBound(fileNames)
            PlaySong fileNames(i)
            If TotalDroppedFiles > 0 Then Exit For ' Exit the loop if we have dropped files
        Next
    End If
End Sub


' Processes a list of files selected by the user
Sub ProcessSelectedFiles
    Dim ofdList As String

    ofdList = OpenFileDialog$(APP_NAME, "", "*.mod|*.MOD|*.Mod", "Music Tracker Files", TRUE)

    If ofdList = NULLSTRING Then Exit Sub

    ReDim fileNames(0 To 0) As String
    Dim As Long i, j

    j = ParseOpenFileDialogList(ofdList, fileNames())

    For i = 0 To j - 1
        PlaySong fileNames(i)
        If TotalDroppedFiles > 0 Then Exit For ' Exit the loop if we have dropped files
    Next
End Sub


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


' Vince's FFT routine - https://qb64phoenix.com/forum/showthread.php?tid=270&pid=2005#pid2005
' Modified for efficiency and performance
Sub RFFT (xx_r() As Single, xx_i() As Single, x_r() As Single, n As Long)
    Dim As Single w_r, w_i, wm_r, wm_i, u_r, u_i, v_r, v_i, xpr, xpi, xmr, xmi
    Dim As Long log2n, rev, i, j, k, m, p, q

    log2n = Log(n \ 2) / Log(2)

    For i = 0 To n \ 2 - 1
        rev = 0
        For j = 0 To log2n - 1
            If i And (2 ^ j) Then rev = rev + (2 ^ (log2n - 1 - j))
        Next

        xx_r(i) = x_r(2 * rev)
        xx_i(i) = x_r(2 * rev + 1)
    Next

    For i = 1 To log2n
        m = 2 ^ i
        wm_r = Cos(-2 * Pi / m)
        wm_i = Sin(-2 * Pi / m)

        For j = 0 To n \ 2 - 1 Step m
            w_r = 1
            w_i = 0

            For k = 0 To m \ 2 - 1
                p = j + k
                q = p + (m \ 2)

                u_r = w_r * xx_r(q) - w_i * xx_i(q)
                u_i = w_r * xx_i(q) + w_i * xx_r(q)
                v_r = xx_r(p)
                v_i = xx_i(p)

                xx_r(p) = v_r + u_r
                xx_i(p) = v_i + u_i
                xx_r(q) = v_r - u_r
                xx_i(q) = v_i - u_i

                u_r = w_r
                u_i = w_i
                w_r = u_r * wm_r - u_i * wm_i
                w_i = u_r * wm_i + u_i * wm_r
            Next
        Next
    Next

    xx_r(n \ 2) = xx_r(0)
    xx_i(n \ 2) = xx_i(0)

    For i = 1 To n \ 2 - 1
        xx_r(n \ 2 + i) = xx_r(n \ 2 - i)
        xx_i(n \ 2 + i) = xx_i(n \ 2 - i)
    Next

    For i = 0 To n \ 2 - 1
        xpr = (xx_r(i) + xx_r(n \ 2 + i)) / 2
        xpi = (xx_i(i) + xx_i(n \ 2 + i)) / 2

        xmr = (xx_r(i) - xx_r(n \ 2 + i)) / 2
        xmi = (xx_i(i) - xx_i(n \ 2 + i)) / 2

        xx_r(i) = xpr + xpi * Cos(2 * Pi * i / n) - xmr * Sin(2 * Pi * i / n)
        xx_i(i) = xmi - xpi * Sin(2 * Pi * i / n) - xmr * Cos(2 * Pi * i / n)
    Next

    ' symmetry, complex conj
    For i = 0 To n \ 2 - 1
        xx_r(n \ 2 + i) = xx_r(n \ 2 - 1 - i)
        xx_i(n \ 2 + i) = -xx_i(n \ 2 - 1 - i)
    Next
End Sub


' Rounds down a number to a lower power of 2
Function RoundDownPower2~& (i As Unsigned Long)
    Dim j As Unsigned Long
    j = i
    j = j Or ShR(j, 1)
    j = j Or ShR(j, 2)
    j = j Or ShR(j, 4)
    j = j Or ShR(j, 8)
    j = j Or ShR(j, 16)
    RoundDownPower2 = j - ShR(j, 1)
End Function


' Clamps v between lo and hi
Function Clamp& (v As Long, lo As Long, hi As Long)
    If v < lo Then
        Clamp = lo
    ElseIf v > hi Then
        Clamp = hi
    Else
        Clamp = v
    End If
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

