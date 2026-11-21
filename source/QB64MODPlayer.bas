'-----------------------------------------------------------------------------------------------------------------------
' QB64 MOD Player - Modular Workstation Audio Tracker & Player
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
'$INCLUDE:'Vector2f.bi'
'$INCLUDE:'Bounds2f.bi'
'$INCLUDE:'Vector3f.bi'
'$INCLUDE:'Background.bi'
'$INCLUDE:'AudioAnalyzer.bi'
'$INCLUDE:'MODPlayer.bi'
'$INCLUDE:'MODPlayer.bm'
'$INCLUDE:'Input.bi'
'$INCLUDE:'TUI.bi'
'$INCLUDE:'Playlist.bi'
'$INCLUDE:'UI_Views.bi'

CONST APP_NAME = "QB64 MOD Player"
CONST APP_FRAME_RATE& = 60&
CONST APP_VOLUME_STEP! = 0.02!

' Global state variables
DIM GlobalPlaylist AS Playlist
DIM CurrentView AS INTEGER
DIM TrackerChanOffset AS LONG
DIM SelectedInstrument AS LONG
DIM InstrumentScrollOffset AS LONG
DIM SelectedPlaylistItem AS LONG
DIM PlaylistScrollOffset AS LONG
DIM CommentScrollOffset AS LONG
DIM ShowHelpModal AS _BYTE
DIM SongStartTime AS DOUBLE
DIM SongElapsedTime AS DOUBLE
DIM Bg AS Background
DIM Player AS MODPlayer
DIM AnalyzerL AS AudioAnalyzer, AnalyzerR AS AudioAnalyzer

''' @brief Derives a sanitized local filename from a Mod Archive URL.
''' @param url Download URL string.
''' @return Sanitized filename string.
FUNCTION App_GetSaveFileName$ (url AS STRING)
    DIM saveFileName AS STRING: saveFileName = Pathname_GetFileName(url)
    App_GetSaveFileName = Pathname_Sanitize(MID$(saveFileName, INSTR(saveFileName, "=") + 1))
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

''' @brief Loads and starts playback of a track by 1-based playlist index.
''' @param trackIdx 1-based index in GlobalPlaylist.
SUB App_PlayTrack (trackIdx AS LONG)
    SHARED GlobalPlaylist AS Playlist
    SHARED Player AS MODPlayer
    SHARED CurrentView AS INTEGER
    SHARED SongStartTime AS DOUBLE
    SHARED SongElapsedTime AS DOUBLE
    SHARED TrackerChanOffset AS LONG
    SHARED SelectedInstrument AS LONG
    SHARED InstrumentScrollOffset AS LONG
    SHARED CommentScrollOffset AS LONG

    IF trackIdx < 1 _ORELSE trackIdx > GlobalPlaylist.count THEN EXIT SUB

    GlobalPlaylist.currentIndex = trackIdx
    DIM filePath AS STRING: filePath = GlobalPlaylist.entries(trackIdx).filePath

    IF Player.song.isPlaying THEN MODPlayer_Stop Player

    DIM success AS _BYTE
    IF _FILEEXISTS(filePath) THEN
        success = MODPlayer_LoadFromDisk(Player, filePath)
    ELSE
        DIM buffer AS STRING: buffer = File_Load(filePath)
        success = MODPlayer_LoadFromMemory(Player, buffer)
    END IF

    IF success THEN
        MODPlayer_Play Player
        Player.song.isLooping = (GlobalPlaylist.repeatMode = PLAYLIST_REPEAT_ONE)

        SongStartTime = _UPTIME
        SongElapsedTime = 0#
        TrackerChanOffset = 0
        SelectedInstrument = 1
        InstrumentScrollOffset = 1
        CommentScrollOffset = 1
        IF CurrentView = UI_VIEW_MODE_OVERVIEW THEN CurrentView = UI_VIEW_MODE_TRACKER

        DIM winTitle AS STRING
        IF LEN(Pathname_GetDriveOrScheme(filePath)) > 2 THEN
            winTitle = App_GetSaveFileName(filePath) + " - " + APP_NAME
        ELSE
            winTitle = Pathname_GetFileName(filePath) + " - " + APP_NAME
        END IF
        _TITLE winTitle
    ELSE
        _MESSAGEBOX APP_NAME, "Failed to load music module: " + filePath, "error"
    END IF
END SUB

''' @brief Advances to next track in the playlist.
SUB App_PlayNextTrack
    SHARED GlobalPlaylist AS Playlist
    SHARED Player AS MODPlayer
    SHARED CurrentView AS INTEGER

    DIM nextIdx AS LONG: nextIdx = Playlist_GetNext(GlobalPlaylist)
    IF nextIdx > 0 THEN
        App_PlayTrack nextIdx
    ELSE
        IF Player.song.isPlaying THEN MODPlayer_Stop Player
        CurrentView = UI_VIEW_MODE_OVERVIEW
        _TITLE APP_NAME + _CHR_SPACE + _OS$
    END IF
END SUB

''' @brief Retreats to previous track in the playlist.
SUB App_PlayPrevTrack
    SHARED GlobalPlaylist AS Playlist
    SHARED Player AS MODPlayer

    DIM prevIdx AS LONG: prevIdx = Playlist_GetPrevious(GlobalPlaylist)
    IF prevIdx > 0 THEN
        App_PlayTrack prevIdx
    END IF
END SUB

''' @brief Stops playback and resets title.
SUB App_StopPlayback
    SHARED Player AS MODPlayer
    SHARED CurrentView AS INTEGER

    IF Player.song.isPlaying THEN MODPlayer_Stop Player
    CurrentView = UI_VIEW_MODE_OVERVIEW
    _TITLE APP_NAME + _CHR_SPACE + _OS$
END SUB

''' @brief Scans a directory for supported tracker files and adds them to the playlist.
''' @param folderPath Path to folder.
SUB App_AddFolderToPlaylist (folderPath AS STRING)
    SHARED GlobalPlaylist AS Playlist
    IF NOT _DIREXISTS(folderPath) THEN EXIT SUB

    DIM sepFolder AS STRING: sepFolder = Pathname_AddDirectorySeparator(folderPath)
    DIM patterns(1 TO 10) AS STRING
    patterns(1) = "*.mod"
    patterns(2) = "*.s3m"
    patterns(3) = "*.mtm"
    patterns(4) = "*.far"
    patterns(5) = "*.stm"
    patterns(6) = "*.669"
    patterns(7) = "*.rad"
    patterns(8) = "*.ult"
    patterns(9) = "*.mdl"
    patterns(10) = "*.amf"

    DIM p AS LONG
    FOR p = 1 TO 10
        DIM fName AS STRING: fName = _FILES$(sepFolder + patterns(p))
        DO WHILE LEN(fName) > 0
            IF RIGHT$(fName, 1) <> PATHNAME_DIR_SEPARATOR_WIN _ANDALSO RIGHT$(fName, 1) <> PATHNAME_DIR_SEPARATOR_NIX THEN
                Playlist_Add GlobalPlaylist, sepFolder + fName, "", 0#
            END IF
            fName = _FILES$
        LOOP
    NEXT p
END SUB

''' @brief Displays native file open dialog and queues/plays selected files.
SUB App_OpenFileDialog
    SHARED GlobalPlaylist AS Playlist
    SHARED Player AS MODPlayer

    DIM ofdList AS STRING
    ofdList = _OPENFILEDIALOG$(APP_NAME, , "*.mod|*.MOD|*.Mod|*.mtm|*.MTM|*.Mtm|*.s3m|*.S3M|*.S3m|*.far|*.FAR|*.Far|*.stm|*.STM|*.Stm|*.669|*.rad|*.RAD|*.Rad|*.ult|*.ULT|*.Ult|*.mdl|*.MDL|*.Mdl|*.amf|*.AMF|*.Amf|*.stk|*.STK|*.Stk|*.m15|*.M15|*.M15", "Music Tracker Files", _TRUE)
    IF LEN(ofdList) = 0 THEN EXIT SUB

    REDIM fileNames(0 TO 0) AS STRING
    DIM j AS LONG: j = String_Tokenize(ofdList, "|", _STR_LF, _FALSE, fileNames())

    DIM firstAdded AS LONG: firstAdded = GlobalPlaylist.count + 1
    DIM i AS LONG
    FOR i = 0 TO j - 1
        IF LEN(fileNames(i)) > 0 THEN
            Playlist_Add GlobalPlaylist, fileNames(i), "", 0#
        END IF
    NEXT i

    IF NOT Player.song.isPlaying _ANDALSO firstAdded <= GlobalPlaylist.count THEN
        App_PlayTrack firstAdded
    END IF
END SUB

''' @brief Displays native folder selection dialog and queues music files.
SUB App_OpenFolderDialog
    SHARED GlobalPlaylist AS Playlist
    SHARED Player AS MODPlayer

    DIM folderPath AS STRING
    folderPath = _SELECTFOLDERDIALOG$("Select folder containing module music:", "")
    IF LEN(folderPath) = 0 THEN EXIT SUB

    DIM firstAdded AS LONG: firstAdded = GlobalPlaylist.count + 1
    App_AddFolderToPlaylist folderPath

    IF NOT Player.song.isPlaying _ANDALSO firstAdded <= GlobalPlaylist.count THEN
        App_PlayTrack firstAdded
    END IF
END SUB

''' @brief Fetches and streams a random tune from modarchive.org.
SUB App_PlayModArchiveRandom
    SHARED GlobalPlaylist AS Playlist
    _TITLE "Contacting ModArchive for random module..."
    DIM url AS STRING: url = ModArchive_GetRandomFileName$
    DIM ext AS STRING: ext = LCASE$(Pathname_GetFileExtension(url))

    IF ext = ".mod" _ORELSE ext = ".mtm" _ORELSE ext = ".s3m" _ORELSE ext = ".far" _ORELSE ext = ".stm" _ORELSE ext = ".669" _ORELSE ext = ".rad" _ORELSE ext = ".ult" _ORELSE ext = ".mdl" _ORELSE ext = ".amf" _ORELSE ext = ".stk" _ORELSE ext = ".m15" THEN
        Playlist_Add GlobalPlaylist, url, App_GetSaveFileName(url), 0#
        App_PlayTrack GlobalPlaylist.count
    ELSE
        _MESSAGEBOX APP_NAME, "Failed to retrieve module from ModArchive.", "warning"
        _TITLE APP_NAME + _CHR_SPACE + _OS$
    END IF
END SUB

''' @brief Processes files dropped onto the window via drag & drop.
SUB App_ProcessDroppedFiles
    SHARED GlobalPlaylist AS Playlist
    SHARED Player AS MODPlayer

    IF _TOTALDROPPEDFILES <= 0 THEN EXIT SUB

    REDIM dropFiles(1 TO _TOTALDROPPEDFILES) AS STRING
    DIM count AS LONG: count = _TOTALDROPPEDFILES
    DIM i AS LONG
    FOR i = 1 TO count
        dropFiles(i) = _DROPPEDFILE$(i)
    NEXT i
    _FINISHDROP

    DIM firstAdded AS LONG: firstAdded = GlobalPlaylist.count + 1
    FOR i = 1 TO count
        IF _DIREXISTS(dropFiles(i)) THEN
            App_AddFolderToPlaylist dropFiles(i)
        ELSE
            Playlist_Add GlobalPlaylist, dropFiles(i), "", 0#
        END IF
    NEXT i

    IF firstAdded <= GlobalPlaylist.count THEN
        App_PlayTrack firstAdded
    END IF
END SUB

''' @brief Processes initial command-line arguments.
SUB App_ProcessCommandLine
    SHARED GlobalPlaylist AS Playlist
    IF _COMMANDCOUNT > 0 THEN
        IF COMMAND$(1) = "/?" _ORELSE COMMAND$(1) = "-?" THEN
            _MESSAGEBOX APP_NAME, APP_NAME + _STR_LF + "Syntax: " + Pathname_GetFileName(COMMAND$(0)) + " [file1.mod file2.s3m ...]" + _STR_LF + "    /?: Shows this message" + _STR_LF + _STR_LF + "Copyright (c) 2026, Samuel Gomes" + _STR_LF + "https://github.com/a740g/", "info"
            SYSTEM
        END IF

        DIM i AS LONG
        FOR i = 1 TO _COMMANDCOUNT
            Playlist_Add GlobalPlaylist, COMMAND$(i), "", 0#
        NEXT i

        IF GlobalPlaylist.count > 0 THEN
            App_PlayTrack 1
        END IF
    END IF
END SUB

'-----------------------------------------------------------------------------------------------------------------------
' APPLICATION INITIALIZATION & MAIN WORKSTATION LOOP
'-----------------------------------------------------------------------------------------------------------------------
WIDTH UI_SCREEN_WIDTH, UI_SCREEN_HEIGHT
_CONTROLCHR OFF
_FONT 8
_BLINK OFF
LOCATE , , _FALSE
CLS

_TITLE APP_NAME + _CHR_SPACE + _OS$
CHDIR _STARTDIR$
_ACCEPTFILEDROP
_ALLOWFULLSCREEN _SQUAREPIXELS, _SMOOTH
RANDOMIZE TIMER

Playlist_Initialize GlobalPlaylist
Background_Initialize Bg
CurrentView = UI_VIEW_MODE_OVERVIEW
TrackerChanOffset = 0
SelectedInstrument = 1
InstrumentScrollOffset = 1
SelectedPlaylistItem = 1
PlaylistScrollOffset = 1
CommentScrollOffset = 1
ShowHelpModal = _FALSE

App_ProcessCommandLine

DO
    ' Audio synthesis & playback update
    IF Player.song.isPlaying THEN
        MODPlayer_Update Player, SOFTSYNTH_SOUND_BUFFER_TIME_DEFAULT

        ' Auto-advance when song finishes
        IF NOT MODPlayer_IsPlaying(Player) THEN
            App_PlayNextTrack
        ELSEIF NOT Player.song.isPaused THEN
            SongElapsedTime = _UPTIME - SongStartTime
        END IF
    END IF

    ' Input polling
    Input_Update

    IF Input_WindowShouldClose THEN EXIT DO
    IF _TOTALDROPPEDFILES > 0 THEN App_ProcessDroppedFiles

    ' Clear framebuffer
    CLS , Black

    ' Begin TUI frame
    TUI_Begin

    DIM estDur AS DOUBLE: estDur = 0#
    IF GlobalPlaylist.currentIndex >= 1 _ANDALSO GlobalPlaylist.currentIndex <= GlobalPlaylist.count THEN
        estDur = GlobalPlaylist.entries(GlobalPlaylist.currentIndex).duration
    END IF

    DIM topAction AS _BYTE
    topAction = UI_DrawHeader(Player, GlobalPlaylist, SongElapsedTime, estDur, CurrentView, ShowHelpModal)

    SELECT CASE CurrentView
        CASE UI_VIEW_MODE_OVERVIEW
            DIM ovAction AS _BYTE: ovAction = UI_RenderOverview(Bg, GlobalPlaylist)
            IF ovAction = UI_ACTION_OPEN_FILE THEN App_OpenFileDialog
            IF ovAction = UI_ACTION_OPEN_FOLDER THEN App_OpenFolderDialog
            IF ovAction = UI_ACTION_MODARCHIVE THEN App_PlayModArchiveRandom
            IF ovAction = UI_ACTION_PLAY_INDEX THEN CurrentView = UI_VIEW_MODE_PLAYLIST

        CASE UI_VIEW_MODE_TRACKER
            UI_RenderTracker Player, TrackerChanOffset

        CASE UI_VIEW_MODE_MIXER
            UI_RenderMixer Player

        CASE UI_VIEW_MODE_INSTRUMENTS
            UI_RenderInstruments Player, SelectedInstrument, InstrumentScrollOffset

        CASE UI_VIEW_MODE_PLAYLIST
            DIM plAction AS _BYTE: plAction = UI_RenderPlaylist(GlobalPlaylist, SelectedPlaylistItem, PlaylistScrollOffset)
            IF plAction = UI_ACTION_OPEN_FILE THEN App_OpenFileDialog
            IF plAction = UI_ACTION_OPEN_FOLDER THEN App_OpenFolderDialog
            IF plAction = UI_ACTION_PLAY_INDEX THEN App_PlayTrack SelectedPlaylistItem

        CASE UI_VIEW_MODE_SONGINFO
            UI_RenderSongInfo Player, CommentScrollOffset

        CASE UI_VIEW_MODE_VISUALIZER
            UI_RenderVisualizer Player, AnalyzerL, AnalyzerR
    END SELECT

    UI_DrawFooter Player

    IF ShowHelpModal THEN
        UI_RenderHelpModal ShowHelpModal
    END IF

    TUI_End

    ' Process transport actions triggered from header
    SELECT CASE topAction
        CASE UI_ACTION_QUIT: EXIT DO
        CASE UI_ACTION_OPEN_FILE: App_OpenFileDialog
        CASE UI_ACTION_OPEN_FOLDER: App_OpenFolderDialog
        CASE UI_ACTION_MODARCHIVE: App_PlayModArchiveRandom
        CASE UI_ACTION_PREV_TRACK: App_PlayPrevTrack
        CASE UI_ACTION_NEXT_TRACK: App_PlayNextTrack
        CASE UI_ACTION_STOP: App_StopPlayback
        CASE UI_ACTION_PLAY_INDEX
            IF GlobalPlaylist.currentIndex >= 1 _ANDALSO GlobalPlaylist.currentIndex <= GlobalPlaylist.count THEN
                App_PlayTrack GlobalPlaylist.currentIndex
            END IF
    END SELECT

    ' Mouse wheel handling based on active view
    DIM mWheel AS SINGLE: mWheel = Input_GetMouseScrollWheelValue
    IF mWheel <> 0! THEN
        SELECT CASE CurrentView
            CASE UI_VIEW_MODE_TRACKER
                IF mWheel > 0! THEN
                    TrackerChanOffset = _MAX(0, TrackerChanOffset - UI_TRACKER_VISIBLE_CHANNELS)
                ELSE
                    TrackerChanOffset = _MIN(_MAX(0, ((Player.song.channels - 1) \ UI_TRACKER_VISIBLE_CHANNELS) * UI_TRACKER_VISIBLE_CHANNELS), TrackerChanOffset + UI_TRACKER_VISIBLE_CHANNELS)
                END IF
            CASE UI_VIEW_MODE_INSTRUMENTS
                InstrumentScrollOffset = _CLAMP(InstrumentScrollOffset - CLNG(mWheel * 3!), 1, _MAX(1, Player.song.instruments))
            CASE UI_VIEW_MODE_SONGINFO
                CommentScrollOffset = _CLAMP(CommentScrollOffset - CLNG(mWheel * 3!), 1, 500)
        END SELECT
    END IF

    ' Gamepad navigation
    IF Input_GetGamepadButtonPressed(GAMEPAD_BUTTON_X, 1) THEN
        IF Player.song.isPlaying THEN Player.song.isPaused = NOT Player.song.isPaused
    END IF

    IF Input_IsGamepadButtonDown(GAMEPAD_BUTTON_RT, 1) THEN
        SoftSynth_SetMasterVolume Player.synth, _CLAMP(SoftSynth_GetMasterVolume(Player.synth) + APP_VOLUME_STEP, 0!, SOFTSYNTH_MASTER_VOLUME_MAX)
    END IF

    IF Input_IsGamepadButtonDown(GAMEPAD_BUTTON_LT, 1) THEN
        SoftSynth_SetMasterVolume Player.synth, _CLAMP(SoftSynth_GetMasterVolume(Player.synth) - APP_VOLUME_STEP, 0!, SOFTSYNTH_MASTER_VOLUME_MAX)
    END IF

    ' Keyboard navigation & shortcuts
    DIM k AS LONG: k = Input_GetKeyboardKey
    SELECT CASE k
        CASE _KEY_ESC
            IF ShowHelpModal THEN
                ShowHelpModal = _FALSE
            ELSEIF Player.song.isPlaying THEN
                App_StopPlayback
            ELSE
                EXIT DO
            END IF

        CASE _KEY_F1: ShowHelpModal = NOT ShowHelpModal
        CASE _KEY_F2: CurrentView = UI_VIEW_MODE_TRACKER
        CASE _KEY_F3: CurrentView = UI_VIEW_MODE_MIXER
        CASE _KEY_F4: CurrentView = UI_VIEW_MODE_INSTRUMENTS
        CASE _KEY_F5: CurrentView = UI_VIEW_MODE_PLAYLIST
        CASE _KEY_F6: CurrentView = UI_VIEW_MODE_SONGINFO
        CASE _KEY_F7: CurrentView = UI_VIEW_MODE_VISUALIZER

        CASE _KEY_LEFT
            IF Player.song.isPlaying THEN MODPlayer_GoToPreviousPosition Player

        CASE _KEY_RIGHT
            IF Player.song.isPlaying THEN MODPlayer_GoToNextPosition Player

        CASE KEY_SPACE
            IF Player.song.isPlaying THEN
                Player.song.isPaused = NOT Player.song.isPaused
                IF Player.song.isPaused THEN
                    SongStartTime = _UPTIME - SongElapsedTime
                ELSE
                    SongStartTime = _UPTIME - SongElapsedTime
                END IF
            END IF

        CASE KEY_PLUS, KEY_EQUAL
            SoftSynth_SetMasterVolume Player.synth, _CLAMP(SoftSynth_GetMasterVolume(Player.synth) + APP_VOLUME_STEP, 0!, SOFTSYNTH_MASTER_VOLUME_MAX)

        CASE KEY_MINUS, KEY_UNDERSCORE
            SoftSynth_SetMasterVolume Player.synth, _CLAMP(SoftSynth_GetMasterVolume(Player.synth) - APP_VOLUME_STEP, 0!, SOFTSYNTH_MASTER_VOLUME_MAX)

        CASE KEY_UPPER_L, KEY_LOWER_L
            IF Player.song.isPlaying THEN
                Player.song.isLooping = NOT Player.song.isLooping
            END IF

        CASE _KEY_PAGEUP
            IF CurrentView = UI_VIEW_MODE_TRACKER THEN
                TrackerChanOffset = _MAX(0, TrackerChanOffset - UI_TRACKER_VISIBLE_CHANNELS)
            ELSEIF CurrentView = UI_VIEW_MODE_INSTRUMENTS THEN
                InstrumentScrollOffset = _MAX(1, InstrumentScrollOffset - 10)
            ELSEIF CurrentView = UI_VIEW_MODE_SONGINFO THEN
                CommentScrollOffset = _MAX(1, CommentScrollOffset - 10)
            END IF

        CASE _KEY_PAGEDOWN
            IF CurrentView = UI_VIEW_MODE_TRACKER THEN
                TrackerChanOffset = _MIN(_MAX(0, ((Player.song.channels - 1) \ UI_TRACKER_VISIBLE_CHANNELS) * UI_TRACKER_VISIBLE_CHANNELS), TrackerChanOffset + UI_TRACKER_VISIBLE_CHANNELS)
            ELSEIF CurrentView = UI_VIEW_MODE_INSTRUMENTS THEN
                InstrumentScrollOffset = _MIN(_MAX(1, Player.song.instruments), InstrumentScrollOffset + 10)
            ELSEIF CurrentView = UI_VIEW_MODE_SONGINFO THEN
                CommentScrollOffset = _MIN(500, CommentScrollOffset + 10)
            END IF
    END SELECT

    _DISPLAY
    _LIMIT APP_FRAME_RATE
LOOP

MODPlayer_Stop Player
SYSTEM
