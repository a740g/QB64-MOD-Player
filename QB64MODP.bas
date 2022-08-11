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
$VersionInfo:FILEVERSION#=1,2,0,11
$VersionInfo:PRODUCTVERSION#=1,2,0,0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------
Const APP_NAME = "QB64 MOD Player"
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------
ReDim Shared NoteTable(0 To 0) As String * 2
Dim Shared InfoMode As Byte
Dim Shared WindowWidthChar As Unsigned Integer
Dim Shared Volume As Integer
Dim Shared HighQuality As Byte
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM DATA
'-----------------------------------------------------------------------------------------------------
' Note string table for UI
NoteTab:
Data 12
Data "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - Frankenstein retro TUI with drag & drop support
'-----------------------------------------------------------------------------------------------------
Title APP_NAME + " " + OS$ ' Set the program name in the titlebar
ChDir StartDir$ ' Change to the directory specifed by the environment
ControlChr Off ' Turn off control characters
AcceptFileDrop ' Enable drag and drop of files
InitializeNoteTable ' Initialize note string table
AdjustWindowSize ' Set the initial window size
AllowFullScreen SquarePixels , Smooth ' All the user to press Alt+Enter to go fullscreen
Volume = GLOBAL_VOLUME_MAX ' Set global volume to maximum
ProcessCommandLine ' Check if any files were specified in the command line

Dim k As Long

' Main loop
Do
    ProcessDroppedFiles
    PrintWelcomeScreen
    k = KeyHit
    Limit 120
Loop Until k = 27

System 0
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'-----------------------------------------------------------------------------------------------------
Sub PrintInfoHeader
    Color 0, 3
    Locate 1, 2
    Print Using " Ord: ### / ### | Pat: ### / ### | Row: ## / 63 | Chn: ### / ### | Voc: ### / ### "; Song.orderPosition; Song.orders - 1; Order(Song.orderPosition); Song.highestPattern; Song.patternRow; Song.activeChannels; Song.channels; SoftSynth.activeVoices; SoftSynth.voices;
    Locate 2, 2
    Print Using " BPM: ###       | Spd: ###       | Vol: \\ / FF |  HQ: \       \ | Rep: \       \ "; Song.bpm; Song.speed, Right$("0" + Hex$(Volume), 2), BoolToStr(HighQuality, 1); BoolToStr(Song.isLooping, 2);
    Color , 0
End Sub

' Dumps MOD info along with the channel that is playing
Sub PrintMODInfo
    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then Order(Song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    If Song.orderPosition >= Song.orders Then Exit Sub
    PrintInfoHeader

    Color 10
    Print Song.subtype; ": "; Song.songName
    Print
    Color 15
    Print "_.________________________________________________________________________________._"
    Print " |                                                                                |"
    Print " |";: Color 12: Print " #  SAMPLE-NAME             VOLUME C2SPD LENGTH LOOP-LENGTH LOOP-START LOOP-END";: Color 15: Print " |"
    Print "_|_                                                                              _|_"
    Print " `/______________________________________________________________________________\'"
    Print

    Dim As Unsigned Byte i, j
    For i = 0 To Song.samples - 1
        Color 14, 0
        For j = 0 To Song.channels - 1
            If i + 1 = Pattern(Order(Song.orderPosition), Song.patternRow, j).sample Then
                Color 13, 1
            End If
        Next
        Print Using " ###: & ####### ##### ###### ########### ########## ########   "; i + 1; Sample(i).sampleName; Sample(i).volume; Sample(i).c2Spd; Sample(i).length; Sample(i).loopLength; Sample(i).loopStart; Sample(i).loopEnd
    Next
    Color , 0
End Sub


' Dumps current pattern information on the screen
Sub PrintPatternInfo
    Dim As Integer startRow, startPat, nNote, nChan, i

    ' Subscript out of range bugfix for player when song is 128 orders long and the song reaches the end
    ' In this case if the sub is allowed to proceed then Order(Song.orderPosition) will cause "subscript out of range"
    ' Note this is only a problem with this demo and not the actual library since we are trying to access internal stuff directly
    If Song.orderPosition >= Song.orders Then Exit Sub
    PrintInfoHeader

    startPat = Order(Song.orderPosition)
    startRow = Song.patternRow - 19
    If startRow < 0 Then
        startRow = 1 + PATTERN_ROW_MAX + startRow
        startPat = startPat - 1
    End If

    For i = 3 To 42
        Locate i, 1

        If startPat >= 0 And startPat <= Song.highestPattern Then
            If i = 22 Then
                Color 15, 1
            Else
                Color 15, 0
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

            Color , 0
        Else
            Print Space$(WindowWidthChar);
        End If

        startRow = startRow + 1
        If startRow > PATTERN_ROW_MAX Then
            startRow = 0
            startPat = startPat + 1
        End If
    Next
End Sub


' Print the welcome screen
Sub PrintWelcomeScreen
    Locate 1, 1
    Color 12, 0
    Print "   _____ ___   _____ _  _           _____ ___     ___   _                           "
    Color 12
    If Timer Mod 7 = 0 Then
        Print "  (  _  )  _ \(  ___) )( )   / \_/ \  _  )  _ \  (  _ \(_ )                    (+_+)"
    ElseIf Timer Mod 13 = 0 Then
        Print "  (  _  )  _ \(  ___) )( )   / \_/ \  _  )  _ \  (  _ \(_ )                    (*_*)"
    Else
        Print "  (  _  )  _ \(  ___) )( )   / \_/ \  _  )  _ \  (  _ \(_ )                    (ù_ù)"
    End If
    Color 12
    Print "  | ( ) | (_) ) (__ | || |   |     | ( ) | | ) | | |_) )| |   _ _ _   _   __  _ __  "
    Color 15
    Print "  | | | |  _ (|  _  \ || |_  | (_) | | | | | | ) |  __/ | | / _  ) ) ( )/ __ \  __) "
    Color 15
    Print "  | (( \| (_) ) (_) |__  __) | | | | (_) | |_) | | |    | |( (_| | (_) |  ___/ |    "
    Color 10
    Print "_.(___\_)____/ \___/   (_)   (_) (_)_____)____/  (_)   (___)\__ _)\__  |\____)_)__._"
    Color 10
    Print " |                                                               ( )_| |          | "
    Color 10
    Print " |                                                                \___/           | "
    Color 14
    Print " |                                                                                | "
    Print " |                                                                                | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "ESC";: Color 8: Print " .................... ";: Color 13: Print "NEXT/QUIT";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "SPC";: Color 8: Print " ........................ ";: Color 13: Print "PAUSE";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "=|+";: Color 8: Print " .............. ";: Color 13: Print "INCREASE VOLUME";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "-|_";: Color 8: Print " .............. ";: Color 13: Print "DECREASE VOLUME";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "L|l";: Color 8: Print " ......................... ";: Color 13: Print "LOOP";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "Q|q";: Color 8: Print " ................ ";: Color 13: Print "INTERPOLATION";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "<|,";: Color 8: Print " ....................... ";: Color 13: Print "REWIND";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print ">|.";: Color 8: Print " ...................... ";: Color 13: Print "FORWARD";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "I|i";: Color 8: Print " ............. ";: Color 13: Print "INFORMATION VIEW";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                       ";: Color 11: Print "V|v";: Color 8: Print " ................. ";: Color 13: Print "PATTERN VIEW";: Color 14: Print "                       | "
    Print " |                                                                                | "
    Print " |                                                                                | "
    Print " |                                                                                | "
    Print " |   ";: Color 9: Print "DRAG AND DROP MULTIPLE MOD FILES ON THIS WINDOW TO PLAY THEM SEQUENTIALLY.";: Color 14: Print "   | "
    Print " |                                                                                | "
    Print " |   ";: Color 9: Print "YOU CAN ALSO START THE PROGRAM WITH MULTIPLE FILES FROM THE COMMAND LINE.";: Color 14: Print "    | "
    Print " |                                                                                | "
    Print " |  ";: Color 9: Print "THIS WAS WRITTEN PURELY IN QB64 AND THE SOURCE CODE IS AVAILABLE ON GITHUB.";: Color 14: Print "   | "
    Print " |                                                                                | "
    Print " |                   ";: Color 9: Print "https://github.com/a740g/QB64-MOD-Player";: Color 14: Print "                     | "
    Print "_|_                                                                              _|_"
    Print " `/_______________________________________________________________________________\'";
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
End Sub


' Automatically selects, sets the window size and saves the text width
Sub AdjustWindowSize
    If Song.channels < 5 Or Not Song.isPlaying Or InfoMode Then
        WindowWidthChar = 84 ' we don't want the width to be too small
    Else
        WindowWidthChar = 8 + Song.channels * 19
    End If

    ' We need 43 lines minimum
    Width WindowWidthChar, 43
    ' Clear the screen
    Cls
End Sub


' Initializes, loads and plays a mod file
' Also checks for input, shows info etc
Sub PlaySong (fileName As String)
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

        If InfoMode Then
            PrintMODInfo
        Else
            PrintPatternInfo
        End If

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

            Case 73, 105
                InfoMode = TRUE
                AdjustWindowSize

            Case 86, 118
                InfoMode = FALSE
                AdjustWindowSize
        End Select

        HighQuality = SoftSynth.useHQMixer ' Since this can be changed by the playing MOD

        Limit 120
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
            If Not expression Then BoolToStr = "Off" Else BoolToStr = "On"
        Case 2
            If Not expression Then BoolToStr = "Disabled" Else BoolToStr = "Enabled"
        Case 3
            If Not expression Then BoolToStr = "0" Else BoolToStr = "1"
        Case Else
            If Not expression Then BoolToStr = "False" Else BoolToStr = "True"
    End Select
End Function
'-----------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------
' MODULE FILES
'-----------------------------------------------------------------------------------------------------
'$Include:'./include/MODPlayer.bas'
'-----------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------

