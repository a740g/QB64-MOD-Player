'-----------------------------------------------------------------------------------------------------------------------
' UI_Views - Modular Views for QB64-PE MOD Player
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Math.bi'
'$INCLUDE:'Asc.bi'
'$INCLUDE:'Pathname.bi'
'$INCLUDE:'Vector2f.bi'
'$INCLUDE:'Bounds2f.bi'
'$INCLUDE:'Vector3f.bi'
'$INCLUDE:'Input.bi'
'$INCLUDE:'TUI.bi'
'$INCLUDE:'Playlist.bi'
'$INCLUDE:'AudioAnalyzer.bi'
'$INCLUDE:'MODPlayer.bi'
'$include:'MODPlayer.bm'

' View identifier constants
CONST UI_VIEW_MODE_TRACKER% = 1%
CONST UI_VIEW_MODE_MIXER% = 2%
CONST UI_VIEW_MODE_INSTRUMENTS% = 3%
CONST UI_VIEW_MODE_PLAYLIST% = 4%
CONST UI_VIEW_MODE_SONGINFO% = 5%
CONST UI_VIEW_MODE_VISUALIZER% = 6%

' UI layout constants
CONST UI_SCREEN_WIDTH& = 144&
CONST UI_SCREEN_HEIGHT& = 90&
CONST UI_TRACKER_VISIBLE_CHANNELS& = 8&

' Application UI action events
CONST UI_ACTION_NONE%% = 0%%
CONST UI_ACTION_QUIT%% = 1%%
CONST UI_ACTION_OPEN_FILE%% = 2%%
CONST UI_ACTION_OPEN_FOLDER%% = 3%%
CONST UI_ACTION_MODARCHIVE%% = 4%%
CONST UI_ACTION_PREV_TRACK%% = 5%%
CONST UI_ACTION_NEXT_TRACK%% = 6%%
CONST UI_ACTION_STOP%% = 7%%
CONST UI_ACTION_PLAY_INDEX%% = 8%%
CONST UI_ACTION_ADD_FILE%% = 9%%
CONST UI_ACTION_ADD_FOLDER%% = 10%%

' CP437 glyph and control character constants for UI rendering
CONST __UI_GLYPH_NOTE = CHR$(14) ' Music note
CONST __UI_GLYPH_STAR = CHR$(15) ' Sun / star
CONST __UI_GLYPH_RIGHT_ARROW = CHR$(16) ' Right pointer
CONST __UI_GLYPH_LEFT_ARROW = CHR$(17) ' Left pointer
CONST __UI_GLYPH_DOWN_ARROW = CHR$(25) ' Down arrow
CONST __UI_GLYPH_HLINE = CHR$(196) ' Horizontal line
CONST __UI_GLYPH_PAUSE = CHR$(186) ' Double vertical bar
CONST __UI_GLYPH_SOLID = CHR$(219) ' Full block
CONST __UI_GLYPH_HALF_BLOCK = CHR$(220) ' Lower half block
CONST __UI_GLYPH_INACTIVE_DOT = CHR$(250) ' Inactive dot
CONST __UI_GLYPH_STOP = CHR$(254) ' Square block

''' @brief Returns standard 3-character note name (e.g. "C-4", "F#5", "---", "^^^").
''' @param note Note period/semitone code from tracker pattern.
''' @return 3-character note string.
FUNCTION UI_GetNoteName$ (note AS LONG)
    IF note = __MODPLAYER_NOTE_NONE THEN
        UI_GetNoteName = "---"
    ELSEIF note = __MODPLAYER_NOTE_KEY_OFF THEN
        UI_GetNoteName = "^^^"
    ELSE
        STATIC noteNames(0 TO 11) AS STRING * 2
        STATIC initDone AS _BYTE
        IF NOT initDone THEN
            noteNames(0) = "C-"
            noteNames(1) = "C#"
            noteNames(2) = "D-"
            noteNames(3) = "D#"
            noteNames(4) = "E-"
            noteNames(5) = "F-"
            noteNames(6) = "F#"
            noteNames(7) = "G-"
            noteNames(8) = "G#"
            noteNames(9) = "A-"
            noteNames(10) = "A#"
            noteNames(11) = "B-"
            initDone = _TRUE
        END IF
        DIM octave AS LONG: octave = 1 + note \ 12
        UI_GetNoteName = noteNames(note MOD 12) + _TOSTR$(octave)
    END IF
END FUNCTION

''' @brief Returns tracker module format display name.
''' @param fmt Tracker format constant.
''' @return Short format name string.
FUNCTION UI_GetFormatName$ (fmt AS _UNSIGNED INTEGER)
    SELECT CASE fmt
        CASE MODPLAYER_FORMAT_MOD: UI_GetFormatName = "MOD"
        CASE MODPLAYER_FORMAT_S3M: UI_GetFormatName = "S3M"
        CASE MODPLAYER_FORMAT_MTM: UI_GetFormatName = "MTM"
        CASE MODPLAYER_FORMAT_FAR: UI_GetFormatName = "FAR"
        CASE MODPLAYER_FORMAT_STM: UI_GetFormatName = "STM"
        CASE MODPLAYER_FORMAT_669: UI_GetFormatName = "669"
        CASE MODPLAYER_FORMAT_RAD: UI_GetFormatName = "RAD"
        CASE MODPLAYER_FORMAT_ULT: UI_GetFormatName = "ULT"
        CASE MODPLAYER_FORMAT_MDL: UI_GetFormatName = "MDL"
        CASE MODPLAYER_FORMAT_AMF: UI_GetFormatName = "AMF"
        CASE ELSE: UI_GetFormatName = "???"
    END SELECT
END FUNCTION

''' @brief Formats an integer to 3 digits with leading zeros (e.g. "005"), or "---" if negative.
FUNCTION __UI_Format3$ (v AS LONG)
    IF v < 0 THEN
        __UI_Format3 = "---"
    ELSE
        DIM s AS STRING: s = _TOSTR$(v)
        IF LEN(s) = 1 THEN
            __UI_Format3 = "00" + s
        ELSEIF LEN(s) = 2 THEN
            __UI_Format3 = "0" + s
        ELSE
            __UI_Format3 = s
        END IF
    END IF
END FUNCTION

''' @brief Renders the fixed top header across rows 1 to 7.
''' @param player The active MODPlayer instance.
''' @param pl The Playlist instance.
''' @param currentView In/Out: Currently selected view.
''' @param showHelpModal In/Out: Flag indicating if help overlay is visible.
''' @return UI_ACTION code if transport button was triggered.
FUNCTION UI_DrawHeader%% (player AS MODPlayer, pl AS Playlist, currentView AS INTEGER, showHelpModal AS _BYTE)
    DIM action AS _BYTE

    ' Row 1: Full-width Dark Gray Top Bar (Subtype, Song Title, and Telemetry)
    COLOR TUI_COLOR_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (1, 1), SPACE$(UI_SCREEN_WIDTH)

    ' 4-character module subtype badge (columns 2 to 7)
    DIM subTypeStr AS STRING
    IF player.song.isPlaying THEN
        subTypeStr = String_MakePrintable(player.song.subtype)
        IF LEN(subTypeStr) < 4 THEN subTypeStr = subTypeStr + SPACE$(4 - LEN(subTypeStr))
        IF LEN(subTypeStr) > 4 THEN subTypeStr = LEFT$(subTypeStr, 4)
    ELSE
        subTypeStr = "----"
    END IF
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLUE
    _PRINTSTRING (2, 1), " " + subTypeStr + " "

    ' Song title (columns 9 to 98, max 90 chars)
    DIM titleStr AS STRING
    IF player.song.isPlaying THEN
        titleStr = player.song.caption
        IF LEN(titleStr) = 0 THEN titleStr = "[Untitled Module]"
        COLOR TUI_COLOR_YELLOW, TUI_COLOR_GRAY
    ELSE
        titleStr = "No module loaded. Drag and drop a module file or click File/Folder..."
        COLOR TUI_COLOR_WHITE, TUI_COLOR_GRAY
    END IF
    IF LEN(titleStr) > 90 THEN titleStr = LEFT$(titleStr, 90)
    _PRINTSTRING (9, 1), titleStr

    ' Divider space (cols 99..100)
    COLOR TUI_COLOR_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (99, 1), "  "

    ' Telemetry: BPM, SPD, VOC, BUF (columns 101 to 143)
    DIM bpmValStr AS STRING, spdValStr AS STRING
    DIM vocValStr AS STRING, bufValStr AS STRING
    IF player.song.isPlaying THEN
        bpmValStr = RIGHT$("  " + _TOSTR$(_CLAMP(player.song.BPM, 0, 999)), 3)
        spdValStr = RIGHT$(" " + _TOSTR$(_CLAMP(player.song.speed, 0, 99)), 2)
        DIM actVoc AS LONG: actVoc = _CLAMP(SoftSynth_GetActiveVoices(player.synth), 0, 999)
        DIM totVoc AS LONG: totVoc = _CLAMP(SoftSynth_GetTotalVoices(player.synth), 0, 999)
        vocValStr = RIGHT$("  " + _TOSTR$(actVoc), 3) + "/" + RIGHT$("  " + _TOSTR$(totVoc), 3)
        DIM bufMs AS LONG: bufMs = _CLAMP(CLNG(SoftSynth_GetBufferedSoundTime(player.synth) * 1000#), 0, 999)
        bufValStr = RIGHT$("  " + _TOSTR$(bufMs), 3) + "ms"
    ELSE
        bpmValStr = "---"
        spdValStr = "--"
        vocValStr = "---/---"
        bufValStr = "---ms"
    END IF

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    _PRINTSTRING (101, 1), "BPM:"
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (105, 1), " " + bpmValStr
    _PRINTSTRING (109, 1), "  "

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    _PRINTSTRING (111, 1), "SPD:"
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (115, 1), " " + spdValStr
    _PRINTSTRING (118, 1), "  "

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    _PRINTSTRING (120, 1), "VOC:"
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (124, 1), " " + vocValStr
    _PRINTSTRING (132, 1), "  "

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    _PRINTSTRING (134, 1), "BUF:"
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (138, 1), " " + bufValStr

    ' Row 2: Full-width Dark Gray Top Bar (Scrubber, Order/Pattern/Row Counters, and Volume)
    COLOR TUI_COLOR_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (1, 2), SPACE$(UI_SCREEN_WIDTH)

    DIM curOrd AS LONG: curOrd = _IIF(player.song.isPlaying, player.song.orderPosition, 0)
    DIM maxOrd AS LONG: maxOrd = _IIF(player.song.isPlaying, _MAX(1, player.song.orders - 1), 1)

    DIM smoothOrd AS SINGLE
    IF player.song.isPlaying _ANDALSO maxOrd > 0 THEN
        DIM pRow AS LONG: pRow = player.song.patternRow
        DIM pIdx AS LONG: pIdx = player.order(curOrd)
        DIM pRows AS LONG
        pRows = _IIF(pIdx >= 0 _ANDALSO pIdx < player.song.patterns, player.pattern(pIdx).rows, 64)
        smoothOrd = CSNG(curOrd) + CSNG(pRow) / CSNG(_MAX(1, pRows))
    ELSE
        smoothOrd = 0!
    END IF

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    DIM scrubResult AS LONG
    scrubResult = TUI_ProgressBar(2, 2, 63, smoothOrd, CSNG(maxOrd), "POS:")
    IF scrubResult >= 0 _ANDALSO player.song.isPlaying THEN
        player.song.orderPosition = scrubResult
        player.song.patternRow = 0
    END IF

    ' Divider space (cols 75..76)
    COLOR TUI_COLOR_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (75, 2), "  "

    ' Position Counters: ORD: xxx/yyy, PAT: xxx/yyy, ROW: xxx/yyy (columns 77 to 116)
    DIM ordVal AS LONG, maxOrdVal AS LONG
    DIM patVal AS LONG, maxPatVal AS LONG
    DIM rowVal AS LONG, maxRowVal AS LONG
    IF player.song.isPlaying THEN
        ordVal = player.song.orderPosition
        maxOrdVal = _MAX(0, player.song.orders - 1)
        patVal = player.order(player.song.orderPosition)
        maxPatVal = _MAX(0, player.song.patterns - 1)
        rowVal = player.song.patternRow
        DIM curPatRows AS LONG
        curPatRows = _IIF(patVal >= 0 _ANDALSO patVal < player.song.patterns, player.pattern(patVal).rows, 64)
        maxRowVal = _MAX(0, curPatRows - 1)
    ELSE
        ordVal = -1
        maxOrdVal = -1
        patVal = -1
        maxPatVal = -1
        rowVal = -1
        maxRowVal = -1
    END IF

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    _PRINTSTRING (77, 2), "ORD:"
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (81, 2), " " + __UI_Format3(ordVal) + "/" + __UI_Format3(maxOrdVal)
    _PRINTSTRING (89, 2), "  "

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    _PRINTSTRING (91, 2), "PAT:"
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (95, 2), " " + __UI_Format3(patVal) + "/" + __UI_Format3(maxPatVal)
    _PRINTSTRING (103, 2), "  "

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    _PRINTSTRING (105, 2), "ROW:"
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (109, 2), " " + __UI_Format3(rowVal) + "/" + __UI_Format3(maxRowVal)

    ' Divider space (cols 117..118)
    COLOR TUI_COLOR_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (117, 2), "  "

    ' Interactive Master Volume Slider (cols 119..143)
    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
    DIM curVol AS SINGLE: curVol = SoftSynth_GetMasterVolume(player.synth)
    DIM newVol AS SINGLE
    newVol = TUI_Slider(119, 2, 16, curVol, 0!, SOFTSYNTH_MASTER_VOLUME_MAX, "VOL")
    IF newVol <> curVol THEN
        SoftSynth_SetMasterVolume player.synth, newVol
    END IF

    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK

    ' Rows 3 to 5: 3D Transport & Quick Action Toolbar
    DIM isSongPlaying AS _BYTE: isSongPlaying = player.song.isPlaying
    DIM hasMultiQueue AS _BYTE: hasMultiQueue = (pl.count > 1)
    DIM hasQueue AS _BYTE: hasQueue = (pl.count > 0)

    DIM bx AS LONG: bx = 2

    ' Group 1: Transport Controls (Cols 2..55)
    IF TUI_ButtonEx(bx, 3, 9, __UI_GLYPH_LEFT_ARROW + __UI_GLYPH_LEFT_ARROW + " Prev", NOT (isSongPlaying _ORELSE hasMultiQueue)) THEN action = UI_ACTION_PREV_TRACK
    bx = bx + 10

    IF TUI_ButtonEx(bx, 3, 7, __UI_GLYPH_LEFT_ARROW + " Rwd", NOT isSongPlaying) THEN
        IF player.song.isPlaying THEN MODPlayer_GoToPreviousPosition player
    END IF
    bx = bx + 8

    DIM playLabel AS STRING
    IF player.song.isPlaying _ANDALSO NOT player.song.isPaused THEN
        playLabel = __UI_GLYPH_PAUSE + " Pause"
    ELSE
        playLabel = __UI_GLYPH_RIGHT_ARROW + " Play "
    END IF
    DIM canPlay AS _BYTE: canPlay = isSongPlaying _ORELSE hasQueue
    IF TUI_ToggleButtonEx(bx, 3, 9, playLabel, player.song.isPlaying _ANDALSO NOT player.song.isPaused, NOT canPlay) THEN
        IF player.song.isPlaying THEN
            player.song.isPaused = NOT player.song.isPaused
        ELSEIF pl.count > 0 THEN
            action = UI_ACTION_PLAY_INDEX
        END IF
    END IF
    bx = bx + 10

    IF TUI_ButtonEx(bx, 3, 8, __UI_GLYPH_STOP + " Stop", NOT isSongPlaying) THEN action = UI_ACTION_STOP
    bx = bx + 9

    IF TUI_ButtonEx(bx, 3, 7, "Fwd " + __UI_GLYPH_RIGHT_ARROW, NOT isSongPlaying) THEN
        IF player.song.isPlaying THEN MODPlayer_GoToNextPosition player
    END IF
    bx = bx + 8

    IF TUI_ButtonEx(bx, 3, 9, "Next " + __UI_GLYPH_RIGHT_ARROW + __UI_GLYPH_RIGHT_ARROW, NOT (isSongPlaying _ORELSE hasMultiQueue)) THEN action = UI_ACTION_NEXT_TRACK
    bx = bx + 9 + 2

    ' Group 2: Playback Modes (Cols 58..81)
    DIM repLabel AS STRING
    SELECT CASE pl.repeatMode
        CASE PLAYLIST_REPEAT_NONE: repLabel = "Loop: None"
        CASE PLAYLIST_REPEAT_ALL: repLabel = "Loop: All "
        CASE PLAYLIST_REPEAT_ONE: repLabel = "Loop: Song"
    END SELECT
    IF TUI_Button(bx, 3, 12, repLabel) THEN
        DIM nextRep AS _BYTE
        SELECT CASE pl.repeatMode
            CASE PLAYLIST_REPEAT_NONE: nextRep = PLAYLIST_REPEAT_ALL
            CASE PLAYLIST_REPEAT_ALL: nextRep = PLAYLIST_REPEAT_ONE
            CASE PLAYLIST_REPEAT_ONE: nextRep = PLAYLIST_REPEAT_NONE
        END SELECT
        Playlist_SetRepeatMode pl, nextRep
        player.song.isLooping = (nextRep = PLAYLIST_REPEAT_ONE)
    END IF
    bx = bx + 13

    ' Shuffle button
    DIM shufLabel AS STRING: shufLabel = _IIF(pl.isShuffle, "Shuf: ON ", "Shuf: OFF")
    IF TUI_ToggleButton(bx, 3, 11, shufLabel, pl.isShuffle) THEN
        Playlist_SetShuffle pl, NOT pl.isShuffle
    END IF
    bx = bx + 11 + 2

    ' Group 3: File Sources (Cols 84..121)
    IF TUI_Button(bx, 3, 11, __UI_GLYPH_NOTE + " File...") THEN action = UI_ACTION_OPEN_FILE
    bx = bx + 12

    IF TUI_Button(bx, 3, 13, __UI_GLYPH_NOTE + " Folder...") THEN action = UI_ACTION_OPEN_FOLDER
    bx = bx + 14

    IF TUI_Button(bx, 3, 12, __UI_GLYPH_STAR + " ModArch") THEN action = UI_ACTION_MODARCHIVE
    bx = bx + 12 + 2

    ' Group 4: System (Cols 124..143)
    IF TUI_Button(bx, 3, 9, "Help F1") THEN showHelpModal = NOT showHelpModal
    bx = bx + 10

    IF TUI_Button(bx, 3, 10, "Quit F12") THEN action = UI_ACTION_QUIT

    ' Rows 6 to 7: 3D TabBar for Views
    STATIC tabs(1 TO 6) AS STRING
    IF LEN(tabs(1)) = 0 THEN
        tabs(1) = "F2: Tracker"
        tabs(2) = "F3: Mixer"
        tabs(3) = "F4: Instruments"
        tabs(4) = "F5: Playlist"
        tabs(5) = "F6: Song Info"
        tabs(6) = "F7: Visualizer"
    END IF

    DIM tabSel AS LONG: tabSel = currentView
    IF tabSel < 1 THEN tabSel = 1
    IF tabSel > 6 THEN tabSel = 6

    ' Bitmask for disabled tabs (bit i-1 for tab i):
    ' Tab 1: F2: Tracker (bit 0 = 1) - requires active playback
    ' Tab 2: F3: Mixer (bit 1 = 2) - requires active playback
    ' Tab 3: F4: Instruments (bit 2 = 4) - requires active playback
    ' Tab 4: F5: Playlist (bit 3 = 8) - ALWAYS enabled (mask bit remains 0)
    ' Tab 5: F6: Song Info (bit 4 = 16) - requires active playback
    ' Tab 6: F7: Visualizer (bit 5 = 32) - ALWAYS enabled (mask bit remains 0; idle shows demoscene background)
    DIM disabledMask AS _UNSIGNED LONG
    IF NOT player.song.isPlaying THEN
        disabledMask = &H01& OR &H02& OR &H04& OR &H10&
    END IF

    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    IF TUI_TabBarEx(4, 6, 1, 8, UI_SCREEN_WIDTH, 88, tabs(), 6, tabSel, disabledMask) THEN
        currentView = tabSel
    END IF

    UI_DrawHeader = action
END FUNCTION

''' @brief Determines which F-key (1-10, 30, 31) softkey text hitbox covers a text column on the bottom row.
''' @param col The 1-based text column (1 to 144).
''' @return Key index (1-10, 30, 31) if clicked within text hitbox, 0 otherwise.
FUNCTION UI_GetFooterSoftkeyAtColumn% (col AS LONG)
    IF col < 1 _ORELSE col > UI_SCREEN_WIDTH THEN EXIT FUNCTION

    DIM slot AS LONG: slot = (col - 1) \ 12 + 1
    DIM baseCol AS LONG: baseCol = (slot - 1) * 12
    DIM textStart AS LONG: textStart = _IIF(slot < 10, baseCol + 2, baseCol + 3)
    DIM textEnd AS LONG: textEnd = baseCol + 11

    IF col >= textStart _ANDALSO col <= textEnd THEN
        IF slot >= 1 _ANDALSO slot <= 10 THEN
            UI_GetFooterSoftkeyAtColumn = slot
        ELSEIF slot = 11 THEN
            UI_GetFooterSoftkeyAtColumn = 30
        ELSEIF slot = 12 THEN
            UI_GetFooterSoftkeyAtColumn = 31
        END IF
    END IF
END FUNCTION

''' @brief Renders the footer with channel VU ribbons and detects softkey clicks on row 90.
''' @param player The active MODPlayer instance.
''' @return The key code clicked (1-10, 30, 31) or 0 if none.
FUNCTION UI_DrawFooter% (player AS MODPlayer)
    SHARED __TUI AS __TUI_Context

    ' Row 89: Mini VU Meter Ribbon across all song channels (full-width Dark Gray ribbon)
    COLOR TUI_COLOR_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (1, 89), SPACE$(UI_SCREEN_WIDTH)
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_GRAY
    _PRINTSTRING (2, 89), "CH:"

    DIM maxChans AS LONG: maxChans = _IIF(player.song.isPlaying, player.song.channels, 0)
    IF maxChans > 32 THEN maxChans = 32

    DIM c AS LONG
    FOR c = 0 TO maxChans - 1
        DIM chX AS LONG: chX = 6 + c * 4
        IF chX + 3 > UI_SCREEN_WIDTH - 2 THEN EXIT FOR

        DIM isMuted AS _BYTE: isMuted = MODPlayer_IsChannelMuted(player, c)
        DIM isSoloed AS _BYTE: isSoloed = MODPlayer_IsChannelSoloed(player, c)
        DIM vVol AS SINGLE: vVol = SoftSynth_GetVoiceVolume(player.synth, c)

        ' Channel number badge
        IF isMuted THEN
            COLOR TUI_COLOR_LIGHT_RED, TUI_COLOR_GRAY
        ELSEIF isSoloed THEN
            COLOR TUI_COLOR_YELLOW, TUI_COLOR_GRAY
        ELSE
            COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_GRAY
        END IF

        DIM chStr AS STRING: chStr = _TOSTR$(c + 1)
        IF LEN(chStr) < 2 THEN chStr = "0" + chStr
        _PRINTSTRING (chX, 89), chStr

        ' 1-character mini activity indicator
        IF isMuted THEN
            COLOR TUI_COLOR_LIGHT_RED, TUI_COLOR_GRAY
            _PRINTSTRING (chX + 2, 89), "x"
        ELSEIF vVol > 0.65! THEN
            COLOR TUI_COLOR_LIGHT_RED, TUI_COLOR_GRAY
            _PRINTSTRING (chX + 2, 89), __UI_GLYPH_SOLID
        ELSEIF vVol > 0.25! THEN
            COLOR TUI_COLOR_YELLOW, TUI_COLOR_GRAY
            _PRINTSTRING (chX + 2, 89), __UI_GLYPH_HALF_BLOCK
        ELSEIF vVol > 0.05! THEN
            COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_GRAY
            _PRINTSTRING (chX + 2, 89), __UI_GLYPH_INACTIVE_DOT
        ELSE
            COLOR TUI_COLOR_BLACK, TUI_COLOR_GRAY
            _PRINTSTRING (chX + 2, 89), " "
        END IF
    NEXT c

    ' Detect mouse click on Row 90 softkeys with drag-in / drag-off prevention
    IF __TUI.mouseClickedL _ANDALSO __TUI.activeId = 0 THEN
        IF INT(__TUI.mousePos.y) = UI_SCREEN_HEIGHT THEN
            DIM curReleaseKey AS INTEGER
            curReleaseKey = UI_GetFooterSoftkeyAtColumn(INT(__TUI.mousePos.x))
            IF curReleaseKey > 0 THEN
                DIM slot AS LONG: slot = _IIF(curReleaseKey = 30, 11, _IIF(curReleaseKey = 31, 12, curReleaseKey))
                DIM baseCol AS LONG: baseCol = (slot - 1) * 12
                DIM textStart AS LONG: textStart = _IIF(slot < 10, baseCol + 2, baseCol + 3)
                DIM textEnd AS LONG: textEnd = baseCol + 11
                IF TUI_IsMouseClickedInRect(textStart, UI_SCREEN_HEIGHT, textEnd, UI_SCREEN_HEIGHT) THEN
                    UI_DrawFooter = curReleaseKey
                    TUI_ConsumeClick
                END IF
            END IF
        END IF
    END IF
END FUNCTION

''' @brief Renders View 1: Multi-channel tracker pattern matrix with 8-channel viewport.
''' @param player The active MODPlayer instance.
''' @param chanOffset In/Out: 0-based channel viewport offset (0, 8, 16, 24...).
SUB UI_RenderTracker (player AS MODPlayer, chanOffset AS LONG)
    IF NOT player.song.isPlaying THEN EXIT SUB

    DIM totalChans AS LONG: totalChans = player.song.channels
    DIM maxOffset AS LONG: maxOffset = _MAX(0, totalChans - UI_TRACKER_VISIBLE_CHANNELS)
    chanOffset = _CLAMP(chanOffset, 0, maxOffset)

    DIM curPat AS LONG: curPat = player.order(player.song.orderPosition)
    IF curPat < 0 _ORELSE curPat >= player.song.patterns THEN EXIT SUB

    DIM endCh AS LONG: endCh = _MIN(totalChans, chanOffset + UI_TRACKER_VISIBLE_CHANNELS)
    DIM pageInfo AS STRING
    pageInfo = "Channels " + _TOSTR$(chanOffset + 1) + " - " + _TOSTR$(endCh) + " of " + _TOSTR$(totalChans)
    DIM infoX AS LONG: infoX = 72 - (LEN(pageInfo) \ 2)
    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (infoX, 9), pageInfo

    ' Horizontal channel scrollbar (columns 3 to 142, width 140, row 10)
    DIM newChOffset1 AS LONG
    newChOffset1 = TUI_ScrollBarH(3, 10, 140, chanOffset + 1, UI_TRACKER_VISIBLE_CHANNELS, totalChans)
    chanOffset = newChOffset1 - 1

    ' Pattern Header Row (row 12)
    COLOR TUI_COLOR_BLACK, TUI_COLOR_CYAN
    _PRINTSTRING (3, 12), " PAT:ROW  "

    DIM visCount AS LONG: visCount = _MIN(UI_TRACKER_VISIBLE_CHANNELS, totalChans - chanOffset)
    DIM vc AS LONG
    FOR vc = 0 TO visCount - 1
        DIM ch AS LONG: ch = chanOffset + vc
        DIM chBadgeX AS LONG: chBadgeX = 14 + vc * 16

        DIM chSub AS STRING: chSub = MODPlayer_GetChannelSubtypeCaption(player, ch)
        DIM badgeText AS STRING
        IF chSub = "PCM" THEN
            badgeText = RIGHT$("0" + _TOSTR$(ch + 1), 2)
        ELSE
            badgeText = chSub
        END IF

        DIM chAct AS _BYTE
        IF TUI_ChannelBadge(chBadgeX, 12, ch, badgeText, MODPlayer_IsChannelMuted(player, ch), MODPlayer_IsChannelSoloed(player, ch), chAct) THEN
            IF chAct = TUI_CHANNEL_ACTION_MUTE THEN
                MODPlayer_ToggleChannelMute player, ch
            ELSEIF chAct = TUI_CHANNEL_ACTION_SOLO THEN
                MODPlayer_SoloChannel player, ch
            END IF
        END IF

        COLOR TUI_COLOR_BLACK, TUI_COLOR_CYAN
        _PRINTSTRING (chBadgeX + 4, 12), " S# FX OP   "
    NEXT vc

    ' Pattern data matrix: rows 13 to 86 (74 rows visible!)
    DIM centerLine AS LONG: centerLine = 50
    DIM dispOrder AS LONG: dispOrder = player.song.orderPosition
    DIM dispRow AS LONG: dispRow = player.song.patternRow
    DIM rowsAbove AS LONG: rowsAbove = centerLine - 13

    ' Rewind dispOrder / dispRow by rowsAbove
    WHILE rowsAbove > 0
        IF dispRow >= rowsAbove THEN
            dispRow = dispRow - rowsAbove
            rowsAbove = 0
        ELSE
            rowsAbove = rowsAbove - dispRow
            IF dispOrder > 0 THEN
                dispOrder = dispOrder - 1
                DIM prevP AS LONG: prevP = player.order(dispOrder)
                IF prevP >= 0 _ANDALSO prevP < player.song.patterns THEN
                    dispRow = player.pattern(prevP).rows
                ELSE
                    dispRow = 0
                    rowsAbove = 0
                END IF
            ELSE
                dispRow = 0
                rowsAbove = 0
            END IF
        END IF
    WEND

    DIM r AS LONG
    FOR r = 13 TO 86
        DIM isValidRow AS _BYTE: isValidRow = _FALSE
        DIM drawP AS LONG: drawP = -1

        IF dispOrder >= 0 _ANDALSO dispOrder < player.song.orders THEN
            drawP = player.order(dispOrder)
            IF drawP >= 0 _ANDALSO drawP < player.song.patterns THEN
                IF dispRow >= 0 _ANDALSO dispRow < player.pattern(drawP).rows THEN
                    isValidRow = _TRUE
                END IF
            END IF
        END IF

        IF isValidRow THEN
            IF r = centerLine THEN
                COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLUE
            ELSE
                COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
            END IF

            DIM rowHdr AS STRING
            DIM pStr AS STRING: pStr = _TOSTR$(drawP)
            IF LEN(pStr) < 2 THEN pStr = "0" + pStr
            DIM rStr AS STRING: rStr = _TOSTR$(dispRow)
            IF LEN(rStr) < 2 THEN rStr = "0" + rStr
            rowHdr = "  " + pStr + ":" + rStr + "  "
            _PRINTSTRING (3, r), rowHdr

            FOR vc = 0 TO visCount - 1
                ch = chanOffset + vc
                DIM cellX AS LONG: cellX = 14 + vc * 16

                DIM nNote AS LONG: nNote = player.pattern(drawP).note(dispRow, ch).note
                DIM nSmp AS LONG: nSmp = player.pattern(drawP).note(dispRow, ch).instrument
                DIM nFx AS LONG: nFx = player.pattern(drawP).note(dispRow, ch).effect
                DIM nOp AS LONG: nOp = player.pattern(drawP).note(dispRow, ch).operand

                DIM noteStr AS STRING: noteStr = UI_GetNoteName(nNote)
                DIM smpStr AS STRING
                IF nSmp = 0 THEN smpStr = "--" ELSE smpStr = RIGHT$("0" + _TOSTR$(nSmp), 2)

                DIM fxStr AS STRING
                IF nFx = 0 _ANDALSO nOp = 0 THEN
                    fxStr = "-- --"
                ELSE
                    fxStr = RIGHT$("0" + HEX$(nFx), 2) + " " + RIGHT$("0" + HEX$(nOp), 2)
                END IF

                IF r = centerLine THEN
                    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLUE
                ELSEIF MODPlayer_IsChannelMuted(player, ch) THEN
                    COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
                ELSE
                    COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
                END IF

                _PRINTSTRING (cellX, r), " " + noteStr + " " + smpStr + " " + fxStr
            NEXT vc

            ' Advance row
            dispRow = dispRow + 1
            IF dispRow >= player.pattern(drawP).rows THEN
                dispRow = 0
                dispOrder = dispOrder + 1
            END IF
        ELSE
            COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
            _PRINTSTRING (3, r), "  --:--   " + SPACE$(129)
        END IF
    NEXT r

    ' Row 87: Voice volume & balance for visible channels
    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (3, 87), " VOL/PAN: "
    FOR vc = 0 TO visCount - 1
        ch = chanOffset + vc
        cellX = 14 + vc * 16
        DIM vV AS LONG: vV = CLNG(SoftSynth_GetVoiceVolume(player.synth, ch) * 100!)
        DIM vB AS LONG: vB = CLNG(SoftSynth_GetVoiceBalance(player.synth, ch) * 100!)
        DIM vpStr AS STRING: vpStr = "V:" + _TOSTR$(vV) + " P:" + _TOSTR$(vB)
        IF LEN(vpStr) < 14 THEN vpStr = vpStr + SPACE$(14 - LEN(vpStr))
        COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
        _PRINTSTRING (cellX, 87), " " + vpStr
    NEXT vc
END SUB

''' @brief Renders View 3: 32-Channel Console Mixer with VU meters, pan pots, and mute/solo.
''' @param player The active MODPlayer instance.
SUB UI_RenderMixer (player AS MODPlayer)
    IF NOT player.song.isPlaying THEN
        EXIT SUB
    END IF

    COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (57, 10), "32-Channel Master Console Mixer"

    DIM totalChans AS LONG: totalChans = _MIN(32, player.song.channels)
    IF totalChans < 1 THEN EXIT SUB

    DIM stripW AS LONG
    IF totalChans <= 16 THEN stripW = 8 ELSE stripW = 4

    DIM startX AS LONG: startX = 3 + (140 - totalChans * stripW) \ 2

    DIM c AS LONG
    FOR c = 0 TO totalChans - 1
        DIM sx AS LONG: sx = startX + c * stripW
        DIM isMuted AS _BYTE: isMuted = MODPlayer_IsChannelMuted(player, c)
        DIM isSoloed AS _BYTE: isSoloed = MODPlayer_IsChannelSoloed(player, c)

        ' Channel Number (row 11)
        DIM chLabel AS STRING: chLabel = _TOSTR$(c + 1)
        IF LEN(chLabel) < 2 THEN chLabel = "0" + chLabel
        COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_BLACK
        _PRINTSTRING (sx, 11), "[" + chLabel + "]"

        ' Subtype Badge (row 13)
        DIM bText AS STRING: bText = MODPlayer_GetChannelSubtypeCaption(player, c)
        COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
        _PRINTSTRING (sx, 13), bText

        ' Interactive Mute / Solo buttons (rows 15-20)
        IF TUI_Button(sx, 15, 3, _IIF(isMuted, "M!", "M ")) THEN
            MODPlayer_ToggleChannelMute player, c
        END IF

        IF TUI_Button(sx, 18, 3, _IIF(isSoloed, "S!", "S ")) THEN
            MODPlayer_SoloChannel player, c
        END IF

        ' Tall 3D VU Meter (rows 22 to 71: 50 characters tall!)
        DIM vVol AS SINGLE: vVol = SoftSynth_GetVoiceVolume(player.synth, c)
        TUI_VUMeter sx + 1, 22, 50, vVol, vVol * 1.1!, isMuted

        ' Volume numeric readout (row 73)
        COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
        _PRINTSTRING (sx, 73), "V" + _TOSTR$(CLNG(vVol * 64!))

        ' Pan pot (row 76)
        DIM panVal AS SINGLE: panVal = SoftSynth_GetVoiceBalance(player.synth, c)
        DIM panStr AS STRING
        IF panVal < -0.1! THEN
            panStr = "L" + _TOSTR$(CLNG(ABS(panVal) * 50!))
        ELSEIF panVal > 0.1! THEN
            panStr = "R" + _TOSTR$(CLNG(panVal * 50!))
        ELSE
            panStr = "MID"
        END IF
        COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
        _PRINTSTRING (sx, 76), panStr

        ' Last Note (row 79)
        DIM lastN AS LONG: lastN = player.channel(c).note
        COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
        _PRINTSTRING (sx, 79), UI_GetNoteName(lastN)

        ' Sample # (row 82)
        COLOR TUI_COLOR_LIGHT_RED, TUI_COLOR_BLACK
        _PRINTSTRING (sx, 82), "I" + _TOSTR$(player.channel(c).instrument)
    NEXT c
END SUB

''' @brief Renders View 4: Instrument & Sample Bank with detailed synth inspector.
''' @param player The active MODPlayer instance.
''' @param selectedInst In/Out: 1-based index of selected instrument.
''' @param scrollOffset In/Out: 1-based top visible index in instrument list.
SUB UI_RenderInstruments (player AS MODPlayer, selectedInst AS LONG, scrollOffset AS LONG)
    SHARED __TUI AS __TUI_Context
    IF NOT player.song.isPlaying THEN
        EXIT SUB
    END IF

    DIM totalInsts AS LONG: totalInsts = player.song.instruments
    selectedInst = _CLAMP(selectedInst, 1, _MAX(1, totalInsts))

    ' Left Panel: Instrument Table (columns 3 to 82, rows 10 to 86)
    TUI_Panel 3, 10, 80, 77, "Sample & Instrument Bank (" + _TOSTR$(totalInsts) + ")", _TRUE

    COLOR TUI_COLOR_BLACK, TUI_COLOR_CYAN
    _PRINTSTRING (5, 12), " #  NAME                     VOL C2SPD   LEN    LOOP TYPE "

    DIM maxRows AS LONG: maxRows = 73
    scrollOffset = _CLAMP(scrollOffset, 1, _MAX(1, totalInsts - maxRows + 1))

    DIM r AS LONG
    FOR r = 0 TO maxRows - 1
        DIM instIdx AS LONG: instIdx = scrollOffset + r
        DIM drawY AS LONG: drawY = 13 + r

        IF instIdx <= totalInsts THEN
            DIM iName AS STRING: iName = player.instrument(instIdx - 1).caption
            IF LEN(iName) > 23 THEN iName = LEFT$(iName, 23) ELSE iName = iName + SPACE$(23 - LEN(iName))

            DIM iVol AS STRING: iVol = _TOSTR$(player.instrument(instIdx - 1).volume)
            IF LEN(iVol) < 3 THEN iVol = SPACE$(3 - LEN(iVol)) + iVol

            DIM iSpd AS STRING: iSpd = _TOSTR$(player.instrument(instIdx - 1).c2Spd)
            IF LEN(iSpd) < 6 THEN iSpd = SPACE$(6 - LEN(iSpd)) + iSpd

            DIM iLen AS STRING: iLen = _TOSTR$(player.instrument(instIdx - 1).length)
            IF LEN(iLen) < 6 THEN iLen = SPACE$(6 - LEN(iLen)) + iLen

            DIM iLoop AS STRING
            IF player.instrument(instIdx - 1).playMode = SOFTSYNTH_VOICE_PLAY_FORWARD_LOOP THEN
                iLoop = "Yes "
            ELSEIF player.instrument(instIdx - 1).playMode = SOFTSYNTH_VOICE_PLAY_BIDIRECTIONAL_LOOP THEN
                iLoop = "Bidi"
            ELSE
                iLoop = "No  "
            END IF

            DIM iType AS STRING
            SELECT CASE player.instrument(instIdx - 1).subtype
                CASE __MODPLAYER_INSTRUMENT_AM_SYNTH: iType = "AM "
                CASE __MODPLAYER_INSTRUMENT_FM_MELODY: iType = "OPL"
                CASE __MODPLAYER_INSTRUMENT_FM_BASSDRUM: iType = "BD "
                CASE __MODPLAYER_INSTRUMENT_FM_SNAREDRUM: iType = "SD "
                CASE __MODPLAYER_INSTRUMENT_FM_TOMTOM: iType = "TT "
                CASE __MODPLAYER_INSTRUMENT_FM_CYMBAL: iType = "CY "
                CASE __MODPLAYER_INSTRUMENT_FM_HIHAT: iType = "HH "
                CASE ELSE: iType = "PCM"
            END SELECT

            DIM isSel AS _BYTE: isSel = (instIdx = selectedInst)
            IF isSel THEN
                COLOR TUI_COLOR_BLACK, TUI_COLOR_BRIGHT_WHITE
            ELSE
                COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
            END IF

            DIM rowStr AS STRING
            DIM numStr AS STRING: numStr = _TOSTR$(instIdx)
            IF LEN(numStr) < 2 THEN numStr = "0" + numStr
            rowStr = numStr + " " + iName + " " + iVol + " " + iSpd + " " + iLen + " " + iLoop + " " + iType

            _PRINTSTRING (5, drawY), rowStr

            ' Mouse click row selection
            DIM rowB AS Bounds2f
            Bounds2f_Set 5, drawY, 80, drawY + 0.999!, rowB
            IF __TUI.activeId = 0 _ANDALSO TUI_IsMouseClickedInBounds(rowB) THEN
                selectedInst = instIdx
                TUI_ConsumeClick
            END IF
        END IF
    NEXT r

    ' Standalone Vertical Scrollbar at column 81 (rows 13 to 85, height 73)
    scrollOffset = TUI_ScrollBarV(81, 13, maxRows, scrollOffset, maxRows, totalInsts)

    ' Right Panel: Detailed Synth Inspector (columns 85 to 142, rows 10 to 86)
    TUI_Panel 85, 10, 58, 77, "Instrument Inspector", _TRUE

    DIM selIdx0 AS LONG: selIdx0 = selectedInst - 1
    COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
    _PRINTSTRING (88, 12), "Slot: #" + _TOSTR$(selectedInst) + " - " + player.instrument(selIdx0).caption

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
    DIM subName AS STRING
    SELECT CASE player.instrument(selIdx0).subtype
        CASE __MODPLAYER_INSTRUMENT_AM_SYNTH: subName = "StarTrekker AM Synthesizer Voice"
        CASE __MODPLAYER_INSTRUMENT_FM_MELODY: subName = "AdLib OPL2 FM Melodic Instrument"
        CASE __MODPLAYER_INSTRUMENT_FM_BASSDRUM TO __MODPLAYER_INSTRUMENT_FM_HIHAT: subName = "AdLib OPL2 FM Percussion Voice"
        CASE ELSE: subName = "Digital PCM Sample"
    END SELECT
    _PRINTSTRING (88, 14), "Type: " + subName

    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (88, 17), "Volume:       " + _TOSTR$(player.instrument(selIdx0).volume) + " / 64"
    _PRINTSTRING (88, 19), "Sample Rate:  " + _TOSTR$(player.instrument(selIdx0).c2Spd) + " Hz (C-2 Spd)"
    _PRINTSTRING (88, 21), "Length:       " + _TOSTR$(player.instrument(selIdx0).length) + " bytes"
    _PRINTSTRING (88, 23), "Loop Start:   " + _TOSTR$(player.instrument(selIdx0).loopStart)
    _PRINTSTRING (88, 25), "Loop End:     " + _TOSTR$(player.instrument(selIdx0).loopEnd)

    IF player.instrument(selIdx0).subtype = __MODPLAYER_INSTRUMENT_AM_SYNTH THEN
        ' StarTrekker AM Synth Card
        COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
        _PRINTSTRING (88, 29), "-- StarTrekker AM Synth Parameters --"
        COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
        DIM waveName AS STRING
        SELECT CASE player.instrument(selIdx0).am.waveform
            CASE 0: waveName = "Sine"
            CASE 1: waveName = "Sawtooth"
            CASE 2: waveName = "Square"
            CASE 3: waveName = "Noise"
            CASE ELSE: waveName = "Unknown"
        END SELECT
        _PRINTSTRING (88, 32), "Waveform:     " + waveName
        _PRINTSTRING (88, 34), "Attack 1 Spd: " + _TOSTR$(player.instrument(selIdx0).am.attack1Speed)
        _PRINTSTRING (88, 36), "Attack 1 Lvl: " + _TOSTR$(player.instrument(selIdx0).am.attack1Level)
        _PRINTSTRING (88, 38), "Attack 2 Spd: " + _TOSTR$(player.instrument(selIdx0).am.attack2Speed)
        _PRINTSTRING (88, 40), "Attack 2 Lvl: " + _TOSTR$(player.instrument(selIdx0).am.attack2Level)
        _PRINTSTRING (88, 42), "Decay Speed:  " + _TOSTR$(player.instrument(selIdx0).am.decaySpeed)
        _PRINTSTRING (88, 44), "Sustain Time: " + _TOSTR$(player.instrument(selIdx0).am.sustainTime)
        _PRINTSTRING (88, 46), "Release Spd:  " + _TOSTR$(player.instrument(selIdx0).am.releaseSpeed)
        _PRINTSTRING (88, 48), "Vibrato Spd:  " + _TOSTR$(player.instrument(selIdx0).am.vibSpeed)
        _PRINTSTRING (88, 50), "Vibrato Amp:  " + _TOSTR$(player.instrument(selIdx0).am.vibAmp)
        _PRINTSTRING (88, 52), "Octave Trans: " + _TOSTR$(player.instrument(selIdx0).am.octave)
    ELSEIF player.instrument(selIdx0).subtype >= __MODPLAYER_INSTRUMENT_FM_MELODY _ANDALSO player.instrument(selIdx0).subtype <= __MODPLAYER_INSTRUMENT_FM_HIHAT THEN
        ' OPL2 FM Synth Card
        COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
        _PRINTSTRING (88, 29), "-- AdLib OPL2 FM Synthesis Register Card --"
        COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
        _PRINTSTRING (88, 32), "Modulator Parameters (D00-D05):"
        _PRINTSTRING (90, 34), "Mult/KSR/EGT/VIB/AM: &H" + HEX$(player.instrument(selIdx0).adlib(0))
        _PRINTSTRING (90, 36), "KSL / Total Level:   &H" + HEX$(player.instrument(selIdx0).adlib(2))
        _PRINTSTRING (90, 38), "Attack / Decay Rate: &H" + HEX$(player.instrument(selIdx0).adlib(4))
        _PRINTSTRING (90, 40), "Sustain / Release:   &H" + HEX$(player.instrument(selIdx0).adlib(6))
        _PRINTSTRING (90, 42), "Waveform Select:     &H" + HEX$(player.instrument(selIdx0).adlib(8))

        _PRINTSTRING (88, 45), "Carrier Parameters (D06-D0B):"
        _PRINTSTRING (90, 47), "Mult/KSR/EGT/VIB/AM: &H" + HEX$(player.instrument(selIdx0).adlib(1))
        _PRINTSTRING (90, 49), "KSL / Total Level:   &H" + HEX$(player.instrument(selIdx0).adlib(3))
        _PRINTSTRING (90, 51), "Attack / Decay Rate: &H" + HEX$(player.instrument(selIdx0).adlib(5))
        _PRINTSTRING (90, 53), "Sustain / Release:   &H" + HEX$(player.instrument(selIdx0).adlib(7))
        _PRINTSTRING (90, 55), "Waveform Select:     &H" + HEX$(player.instrument(selIdx0).adlib(9))

        _PRINTSTRING (88, 58), "Feedback / Connect:  &H" + HEX$(player.instrument(selIdx0).adlib(10))
    ELSE
        ' Digital PCM Waveform Box
        COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
        _PRINTSTRING (88, 29), "-- PCM Sample Waveform Preview --"
        DIM waveY AS LONG: waveY = 34
        COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
        DIM colW AS LONG
        FOR colW = 0 TO 51
            _PRINTSTRING (88 + colW, waveY), __UI_GLYPH_HLINE
        NEXT colW
        COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
        _PRINTSTRING (88, 38), "Direct digital PCM sample playback buffer"
    END IF
END SUB

''' @brief Renders View 5: Multi-song Playlist Queue Manager.
''' @param pl The Playlist instance.
''' @param selectedItem In/Out: 1-based index of selected playlist track.
''' @param scrollOffset In/Out: 1-based top visible index.
''' @return UI_ACTION code if an action was triggered.
FUNCTION UI_RenderPlaylist%% (pl AS Playlist, selectedItem AS LONG, scrollOffset AS LONG)
    SHARED __TUI AS __TUI_Context
    DIM action AS _BYTE

    ' Left Panel: Playlist Queue Table (columns 3 to 94, rows 10 to 86)
    TUI_Panel 3, 10, 92, 77, "Playback Queue (" + _TOSTR$(pl.count) + " Tracks)", _TRUE

    DIM maxNameLen AS LONG: maxNameLen = 80
    DIM i AS LONG
    FOR i = 1 TO pl.count
        IF LEN(pl.entries(i).fileName) > maxNameLen THEN maxNameLen = LEN(pl.entries(i).fileName)
    NEXT i

    STATIC plHScroll AS LONG
    IF plHScroll < 1 THEN plHScroll = 1
    DIM visRows AS LONG: visRows = 72
    DIM maxScroll AS LONG: maxScroll = _MAX(1, pl.count - visRows + 1)
    scrollOffset = _CLAMP(scrollOffset, 1, maxScroll)

    DIM activated AS LONG
    DIM r AS LONG
    FOR r = 0 TO visRows - 1
        DIM itemIdx AS LONG: itemIdx = scrollOffset + r
        DIM drawY AS LONG: drawY = 12 + r

        IF itemIdx <= pl.count THEN
            DIM mark AS STRING: mark = _IIF(itemIdx = pl.currentIndex, __UI_GLYPH_RIGHT_ARROW + " ", "  ")
            DIM pfx AS STRING: pfx = mark + RIGHT$("00" + _TOSTR$(itemIdx), 3) + ". "

            DIM rawName AS STRING: rawName = pl.entries(itemIdx).fileName
            DIM visName AS STRING
            IF plHScroll > 1 THEN
                IF LEN(rawName) >= plHScroll THEN
                    visName = MID$(rawName, plHScroll, 80)
                ELSE
                    visName = ""
                END IF
            ELSE
                visName = MID$(rawName, 1, 80)
            END IF
            IF LEN(visName) < 80 THEN visName = visName + SPACE$(80 - LEN(visName))

            DIM isSelected AS _BYTE: isSelected = (itemIdx = selectedItem)
            DIM rowBounds AS Bounds2f
            Bounds2f_Set 5, drawY, 91, drawY + 0.999!, rowBounds
            DIM isRowHovered AS _BYTE
            IF NOT __TUI_IsInputBlockedByModal THEN
                isRowHovered = Bounds2f_ContainsPoint(rowBounds, __TUI.mousePos) _ANDALSO __TUI.activeId = 0
            END IF

            IF isRowHovered _ANDALSO __TUI.activeId = 0 _ANDALSO TUI_IsMouseClickedInBounds(rowBounds) THEN
                selectedItem = itemIdx
                activated = itemIdx
                TUI_ConsumeClick
            END IF

            IF isSelected THEN
                COLOR TUI_COLOR_BLACK, TUI_COLOR_WHITE
            ELSEIF isRowHovered THEN
                COLOR TUI_COLOR_BRIGHT_WHITE, TUI_COLOR_CYAN
            ELSE
                COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
            END IF

            _PRINTSTRING (5, drawY), pfx + visName
        ELSE
            COLOR TUI_COLOR_BLACK, TUI_COLOR_BLACK
            _PRINTSTRING (5, drawY), SPACE$(87)
        END IF
    NEXT r

    ' Standalone Vertical Scrollbar at column 92 (rows 12 to 83, height 72)
    scrollOffset = TUI_ScrollBarV(92, 12, visRows, scrollOffset, visRows, pl.count)

    ' Standalone Horizontal Scrollbar at row 84 (columns 12 to 91, width 80)
    plHScroll = TUI_ScrollBarH(12, 84, 80, plHScroll, 80, maxNameLen)

    ' Corner junction cell at (92, 84)
    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (92, 84), __TUI_GLYPH_CORNER_BR

    IF activated > 0 THEN
        pl.currentIndex = activated
        action = UI_ACTION_PLAY_INDEX
    END IF

    ' Right Panel: Playlist Controls (columns 97 to 142, rows 10 to 86)
    TUI_Panel 97, 10, 46, 77, "Queue Manager", _TRUE

    DIM bY AS LONG: bY = 13
    IF TUI_Button(106, bY, 28, __UI_GLYPH_NOTE + " Add File(s)...") THEN action = UI_ACTION_ADD_FILE
    bY = bY + 4

    IF TUI_Button(106, bY, 28, __UI_GLYPH_NOTE + " Add Folder...") THEN action = UI_ACTION_ADD_FOLDER
    bY = bY + 4

    IF TUI_Button(106, bY, 28, "- Remove Selected") THEN
        IF selectedItem >= 1 _ANDALSO selectedItem <= pl.count THEN
            Playlist_Remove pl, selectedItem
        END IF
    END IF
    bY = bY + 4

    IF TUI_Button(106, bY, 28, "Clear Playlist") THEN
        Playlist_Clear pl
    END IF
    bY = bY + 6

    ' Shuffle toggle
    IF TUI_ToggleButton(106, bY, 28, _IIF(pl.isShuffle, "Shuffle: ON ", "Shuffle: OFF"), pl.isShuffle) THEN
        Playlist_SetShuffle pl, NOT pl.isShuffle
    END IF
    bY = bY + 4

    ' Repeat mode toggle
    DIM rLabel AS STRING
    SELECT CASE pl.repeatMode
        CASE PLAYLIST_REPEAT_NONE: rLabel = "Loop: None"
        CASE PLAYLIST_REPEAT_ALL: rLabel = "Loop: All "
        CASE PLAYLIST_REPEAT_ONE: rLabel = "Loop: Song"
    END SELECT
    IF TUI_Button(106, bY, 28, rLabel) THEN
        DIM nextR AS _BYTE
        SELECT CASE pl.repeatMode
            CASE PLAYLIST_REPEAT_NONE: nextR = PLAYLIST_REPEAT_ALL
            CASE PLAYLIST_REPEAT_ALL: nextR = PLAYLIST_REPEAT_ONE
            CASE PLAYLIST_REPEAT_ONE: nextR = PLAYLIST_REPEAT_NONE
        END SELECT
        Playlist_SetRepeatMode pl, nextR
    END IF
    bY = bY + 6

    IF TUI_Button(106, bY, 28, "Save M3U Playlist") THEN
        DIM saveM3UPath AS STRING
        saveM3UPath = _OPENFILEDIALOG$("Save Playlist M3U", , "*.m3u|*.m3u8", "M3U Playlist Files", _FALSE)
        IF LEN(saveM3UPath) > 0 THEN Playlist_SaveM3U pl, saveM3UPath
    END IF
    bY = bY + 4

    IF TUI_Button(106, bY, 28, "Load M3U Playlist") THEN
        DIM loadM3UPath AS STRING
        loadM3UPath = _OPENFILEDIALOG$("Load Playlist M3U", , "*.m3u|*.m3u8", "M3U Playlist Files", _FALSE)
        IF LEN(loadM3UPath) > 0 THEN Playlist_LoadM3U pl, loadM3UPath
    END IF
    bY = bY + 8

    COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
    _PRINTSTRING (106, bY), "Queue Statistics:"
    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (106, bY + 2), "Total Tracks:  " + _TOSTR$(pl.count)
    _PRINTSTRING (106, bY + 4), "Current Index: " + _TOSTR$(pl.currentIndex)

    UI_RenderPlaylist = action
END FUNCTION

''' @brief Renders View 6: Song Metadata, Technical Specifications, and Lyrics / Comments.
''' @param player The active MODPlayer instance.
''' @param commentScroll In/Out: Scroll offset for song comment text lines.
SUB UI_RenderSongInfo (player AS MODPlayer, commentScroll AS LONG)
    IF NOT player.song.isPlaying THEN
        EXIT SUB
    END IF

    ' Top Panel: Technical Specifications (columns 3 to 142, rows 10 to 37)
    TUI_Panel 3, 10, 140, 28, "Technical Specifications & Tracker Features", _TRUE

    COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
    _PRINTSTRING (6, 12), "Song Name:     " + player.song.caption
    _PRINTSTRING (6, 14), "Format Type:   " + UI_GetFormatName(player.song.format) + " (" + player.song.subtype + ")"
    _PRINTSTRING (6, 16), "Channels:      " + _TOSTR$(player.song.channels)
    _PRINTSTRING (6, 18), "Orders:        " + _TOSTR$(player.song.orders)
    _PRINTSTRING (6, 20), "Patterns:      " + _TOSTR$(player.song.patterns)
    _PRINTSTRING (6, 22), "Instruments:   " + _TOSTR$(player.song.instruments)

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
    _PRINTSTRING (50, 12), "Default BPM:   " + _TOSTR$(player.song.defaultBPM)
    _PRINTSTRING (50, 14), "Default Speed: " + _TOSTR$(player.song.defaultSpeed)
    _PRINTSTRING (50, 16), "Mixer Rate:    " + _TOSTR$(SoftSynth_GetSampleRate(player.synth)) + " Hz"
    _PRINTSTRING (50, 18), "Mixer Voices:  " + _TOSTR$(SoftSynth_GetTotalVoices(player.synth))
    _PRINTSTRING (50, 20), "Stereo Mode:   " + _IIF(player.song.isStereo, "Stereo Panning", "Mono")

    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (95, 12), "Engine Flags & Hardware Features:"
    _PRINTSTRING (97, 14), "Amiga Low-Pass Filter: " + _IIF(player.song.useAmigaLPF, "Yes", "No")
    _PRINTSTRING (97, 16), "Amiga Hardware Slides: " + _IIF(player.song.useAmigaSlides, "Yes", "No")
    _PRINTSTRING (97, 18), "Amiga Period Limits:   " + _IIF(player.song.useAmigaLimits, "Yes", "No")
    _PRINTSTRING (97, 20), "ST2 Vibrato Mode:      " + _IIF(player.song.useST2Vibrato, "Yes", "No")
    _PRINTSTRING (97, 22), "ST3 Volume Slides:     " + _IIF(player.song.useST300VolumeSlides, "Yes", "No")
    _PRINTSTRING (97, 24), "AdLib FM Channels:     " + _IIF(player.song.hasFMChannels, "Yes", "No")

    ' Bottom Panel: Song Message / Comments / Lyrics (columns 3 to 142, rows 39 to 86)
    TUI_Panel 3, 39, 140, 48, "Song Message / Comments / Lyrics", _TRUE

    DIM commentText AS STRING: commentText = player.song.comment
    IF LEN(commentText) = 0 THEN
        COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
        _PRINTSTRING (6, 42), "No author comments or message embedded in this module."
        EXIT SUB
    END IF

    ' Split comments into lines
    REDIM cLines(1 TO 500) AS STRING
    DIM numLines AS LONG
    DIM pS AS LONG: pS = 1
    DIM tL AS LONG: tL = LEN(commentText)

    WHILE pS <= tL _ANDALSO numLines < 500
        DIM pE AS LONG: pE = INSTR(pS, commentText, _STR_LF)
        DIM lStr AS STRING
        IF pE > 0 THEN
            lStr = MID$(commentText, pS, pE - pS)
            pS = pE + 1
        ELSE
            lStr = MID$(commentText, pS)
            pS = tL + 1
        END IF
        IF RIGHT$(lStr, 1) = _CHR_CR THEN lStr = LEFT$(lStr, LEN(lStr) - 1)
        numLines = numLines + 1
        cLines(numLines) = lStr
    WEND

    DIM visLines AS LONG: visLines = 44
    commentScroll = _CLAMP(commentScroll, 1, _MAX(1, numLines - visLines + 1))

    DIM li AS LONG
    FOR li = 0 TO visLines - 1
        DIM lineIdx AS LONG: lineIdx = commentScroll + li
        IF lineIdx <= numLines THEN
            COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
            _PRINTSTRING (6, 41 + li), cLines(lineIdx)
        END IF
    NEXT li

    ' Standalone Vertical Scrollbar at column 141 (rows 41 to 84, height 44)
    commentScroll = TUI_ScrollBarV(141, 41, visLines, commentScroll, visLines, numLines)
END SUB

''' @brief Renders View 7: Full-width stereo visualizer (Spectrum Analyzer & Oscilloscope) or demoscene background when idle.
''' @param player The active MODPlayer instance.
''' @param analyzerL Left channel AudioAnalyzer.
''' @param analyzerR Right channel AudioAnalyzer.
''' @param bg Background context for idle demoscene animation.
SUB UI_RenderVisualizer (player AS MODPlayer, analyzerL AS AudioAnalyzer, analyzerR AS AudioAnalyzer, bg AS Background)
    IF NOT player.song.isPlaying THEN
        Background_UpdateAndDraw bg
        EXIT SUB
    END IF

    ' Top Panel: Stereo FFT Spectrum Analyzer (columns 3 to 142, rows 10 to 47)
    TUI_Panel 3, 10, 140, 38, "Stereo FFT Spectrum Analyzer (Left & Right Channels)", _TRUE

    ' Calculate 64-band FFT for Left and Right channels
    REDIM specL(0 TO 63) AS _UNSIGNED INTEGER
    REDIM specR(0 TO 63) AS _UNSIGNED INTEGER
    AudioAnalyzer_CalculateFFT analyzerL, specL(), player.synth.soundBuffer(), 0, 2, 7
    AudioAnalyzer_CalculateFFT analyzerR, specR(), player.synth.soundBuffer(), 1, 2, 7

    ' Draw 64 bars on Left half (columns 6 to 69) and 64 bars on Right half (columns 76 to 139)
    DIM b AS LONG
    FOR b = 0 TO 63
        DIM valL AS LONG: valL = _CLAMP(CLNG(_SHR(specL(b), 7)), 0, 33)
        DIM valR AS LONG: valR = _CLAMP(CLNG(_SHR(specR(b), 7)), 0, 33)

        ' Left channel vertical bar
        TUI_VUMeter 6 + b, 13, 33, valL / 33!, valL / 33!, _FALSE

        ' Right channel vertical bar
        TUI_VUMeter 76 + b, 13, 33, valR / 33!, valR / 33!, _FALSE
    NEXT b

    ' Bottom Panel: Real-time Oscilloscope (columns 3 to 142, rows 49 to 86)
    TUI_Panel 3, 49, 140, 38, "Stereo Real-time Waveform Oscilloscope", _TRUE

    DIM oscMidL AS LONG: oscMidL = 58
    DIM oscMidR AS LONG: oscMidR = 76

    COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
    _PRINTSTRING (6, oscMidL), STRING$(134, 196)
    _PRINTSTRING (6, oscMidR), STRING$(134, 196)

    COLOR TUI_COLOR_LIGHT_CYAN, TUI_COLOR_BLACK
    _PRINTSTRING (6, 51), "Left Audio Channel"
    COLOR TUI_COLOR_LIGHT_MAGENTA, TUI_COLOR_BLACK
    _PRINTSTRING (6, 69), "Right Audio Channel"

    ' Plot samples from soundBuffer
    DIM bufSamples AS LONG: bufSamples = player.synth.soundBufferSamples
    IF bufSamples >= 268 THEN
        DIM sI AS LONG
        FOR sI = 0 TO 133
            DIM frameIdx AS LONG: frameIdx = sI * 2
            DIM fL AS SINGLE: fL = player.synth.soundBuffer(frameIdx)
            DIM fR AS SINGLE: fR = player.synth.soundBuffer(frameIdx + 1)

            DIM yL AS LONG: yL = _CLAMP(oscMidL - CLNG(fL * 7!), 52, 64)
            DIM yR AS LONG: yR = _CLAMP(oscMidR - CLNG(fR * 7!), 70, 82)

            COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
            _PRINTSTRING (6 + sI, yL), __UI_GLYPH_STOP

            COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
            _PRINTSTRING (6 + sI, yR), __UI_GLYPH_STOP
        NEXT sI
    END IF
END SUB

''' @brief Renders the pop-up Help & Controls Reference modal dialog.
''' @param showHelpModal In/Out: Flag indicating if modal is visible.
SUB UI_RenderHelpModal (showHelpModal AS _BYTE)
    TUI_ModalBegin

    ' Centered on screen (144x90): x=15 (margin 14 left/right), y=25 (margin 24 top/bottom), w=116, h=41
    TUI_Panel 15, 25, 116, 41, "Help & About Reference", _TRUE

    COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
    _PRINTSTRING (98, 27), "QB64 MOD Player by Samuel Gomes"

    COLOR TUI_COLOR_LIGHT_GREEN, TUI_COLOR_BLACK
    DIM promptMsg AS STRING
    promptMsg = __UI_GLYPH_DOWN_ARROW + " Drag & Drop: Drag any module, folder, or M3U playlist file into the window to play! " + __UI_GLYPH_DOWN_ARROW
    _PRINTSTRING (27, 29), promptMsg

    COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
    _PRINTSTRING (18, 31), "View Navigation (Function Keys & Tabs):"
    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (20, 32), "F1 / ? Help           Help & Reference dialog"
    _PRINTSTRING (74, 32), "F5: Playlist View     Queue manager, search & M3U"
    _PRINTSTRING (20, 33), "F2: Tracker View      Pattern matrix & solo/mute"
    _PRINTSTRING (74, 33), "F6: Song Info View    Header specs, message & lyrics"
    _PRINTSTRING (20, 34), "F3: Mixer View        32-ch console & VU meters"
    _PRINTSTRING (74, 34), "F7: Visualizer View   Stereo 64-band FFT & scope"
    _PRINTSTRING (20, 35), "F4: Instruments View  Samples & synth parameters"
    _PRINTSTRING (74, 35), "Tabs 1 - 6            Click tabs to switch views"

    COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
    _PRINTSTRING (18, 37), "Playback & Transport Controls:"
    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (20, 38), "F8 / Space / Pad X    Play / Pause playback"
    _PRINTSTRING (74, 38), "Left / Right / DPad   Jump previous / next order"
    _PRINTSTRING (20, 39), "F9                    Previous track in playlist"
    _PRINTSTRING (74, 39), "+ / - / Pad Triggers  Master volume up / down"
    _PRINTSTRING (20, 40), "F10                   Next track in playlist"
    _PRINTSTRING (74, 40), "S / M                 Solo / Mute channel"
    _PRINTSTRING (20, 41), "F11 / L               Toggle song loop mode"
    _PRINTSTRING (74, 41), "Home / End            Top / bottom of active list"
    _PRINTSTRING (20, 42), "F12                   Quit MOD Player"
    _PRINTSTRING (74, 42), "PageUp / PageDown     Fast scroll pattern / lists"
    _PRINTSTRING (20, 43), "Esc                   Close Help / Stop / Quit"
    _PRINTSTRING (74, 43), "B                     Cycle background effect"

    COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
    _PRINTSTRING (18, 45), "Loading Files & Command Line:"
    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (20, 46), "File... / Folder...   Browse files or recursive folder via toolbar or Playlist (F5)"
    _PRINTSTRING (20, 47), "ModArchive Random     Click 'ModArch...' on toolbar to stream a random module online"
    _PRINTSTRING (20, 48), "Command Line (CLI)    Launch from terminal: QB64MODPlayer.exe [file/folder/URL]"

    COLOR TUI_COLOR_YELLOW, TUI_COLOR_BLACK
    _PRINTSTRING (18, 50), "Mouse, Keyboard & Controller Navigation:"
    COLOR TUI_COLOR_WHITE, TUI_COLOR_BLACK
    _PRINTSTRING (20, 51), "Tab / Shift+Tab       Cycle focus between buttons and tabs (double border shows focus)"
    _PRINTSTRING (20, 52), "Enter / Space / Pad A Activate focused button, tab stop, or select list item"
    _PRINTSTRING (20, 53), "Left Click / Drag     Click buttons/tabs, drag volume slider, seek bar, scrollbars"
    _PRINTSTRING (20, 54), "Right Click           Quick-solo channel in Tracker and Mixer views"
    _PRINTSTRING (20, 55), "Mouse Wheel           Scroll pattern rows, channels, playlist, or instruments"

    COLOR TUI_COLOR_GRAY, TUI_COLOR_BLACK
    _PRINTSTRING (25, 57), "Background Effects (8 Modes): Stars, Snakes, Fireworks, Fire, Plasma, Balls, Matrix, Fish Tank"

    IF TUI_Button(59, 60, 28, "Close Help (F1 / Esc)") THEN
        showHelpModal = _FALSE
    END IF

    ' Absorb any unhandled mouse click while modal dialog is active
    SHARED __TUI AS __TUI_Context
    IF __TUI.mouseClickedL THEN
        TUI_ConsumeClick
    END IF

    TUI_ModalEnd
END SUB
