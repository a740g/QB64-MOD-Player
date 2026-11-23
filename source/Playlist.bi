'-----------------------------------------------------------------------------------------------------------------------
' Playlist - Multi-song playlist queue and playback manager
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

$UNSTABLE:TYPEFIELDS

'$INCLUDE:'Math.bi'
'$INCLUDE:'Pathname.bi'
'$INCLUDE:'File.bi'
'$INCLUDE:'String.bi'

CONST PLAYLIST_REPEAT_NONE%% = 0%%
CONST PLAYLIST_REPEAT_ALL%% = 1%%
CONST PLAYLIST_REPEAT_ONE%% = 2%%

CONST __PLAYLIST_INITIAL_CAPACITY& = 32&

TYPE PlaylistEntry
    filePath AS STRING
    fileName AS STRING
END TYPE

TYPE Playlist
    _DYNAMIC entries(0 TO 0) AS PlaylistEntry
    count AS LONG
    currentIndex AS LONG
    isShuffle AS _BYTE
    repeatMode AS _BYTE
    _DYNAMIC shuffleOrder(0 TO 0) AS LONG
    shufflePos AS LONG
END TYPE

''' @brief Initializes or resets a playlist structure to default empty state.
''' @param pl The Playlist instance to initialize.
SUB Playlist_Initialize (pl AS Playlist)
    pl.count = 0
    pl.currentIndex = 0
    pl.isShuffle = _FALSE
    pl.repeatMode = PLAYLIST_REPEAT_NONE
    pl.shufflePos = 0
    REDIM pl.entries(0 TO 0) AS PlaylistEntry
    REDIM pl.shuffleOrder(0 TO 0) AS LONG
END SUB

''' @brief Clears all entries from the playlist.
''' @param pl The Playlist instance to clear.
SUB Playlist_Clear (pl AS Playlist)
    Playlist_Initialize pl
END SUB

''' @brief Appends a song file to the playlist.
''' @param pl The Playlist instance.
''' @param filePath Absolute or relative path to the music file.
''' @return _TRUE if added successfully, _FALSE on error.
FUNCTION Playlist_Add%% (pl AS Playlist, filePath AS STRING)
    pl.count = pl.count + 1

    IF pl.count > UBOUND(pl.entries) THEN
        DIM newCap AS LONG
        IF UBOUND(pl.entries) <= 0 THEN
            newCap = __PLAYLIST_INITIAL_CAPACITY&
        ELSE
            newCap = UBOUND(pl.entries) * 2
        END IF
        IF newCap < pl.count THEN newCap = pl.count
        REDIM _PRESERVE pl.entries(1 TO newCap) AS PlaylistEntry
        REDIM _PRESERVE pl.shuffleOrder(1 TO newCap) AS LONG
    END IF

    pl.entries(pl.count).filePath = filePath
    pl.entries(pl.count).fileName = Pathname_GetFileName(filePath)

    IF pl.currentIndex = 0 THEN
        pl.currentIndex = 1
    END IF

    IF pl.isShuffle THEN
        Playlist_Shuffle pl
    END IF

    Playlist_Add = _TRUE
END FUNCTION

''' @brief Appends a song file to the playlist (subroutine version).
''' @param pl The Playlist instance.
''' @param filePath Absolute or relative path to the music file.
SUB Playlist_Add (pl AS Playlist, filePath AS STRING)
    DIM ignored AS _BYTE: ignored = Playlist_Add(pl, filePath)
END SUB

''' @brief Removes a song entry from the playlist by 1-based index.
''' @param pl The Playlist instance.
''' @param index 1-based index of entry to remove.
''' @return _TRUE if removed, _FALSE if index was out of range.
FUNCTION Playlist_Remove%% (pl AS Playlist, index AS LONG)
    IF index < 1 _ORELSE index > pl.count THEN EXIT FUNCTION

    DIM i AS LONG
    FOR i = index TO pl.count - 1
        pl.entries(i) = pl.entries(i + 1)
    NEXT i

    pl.entries(pl.count).filePath = _STR_EMPTY
    pl.entries(pl.count).fileName = _STR_EMPTY
    pl.count = pl.count - 1

    IF pl.count = 0 THEN
        pl.currentIndex = 0
        pl.shufflePos = 0
        REDIM pl.entries(0 TO 0) AS PlaylistEntry
        REDIM pl.shuffleOrder(0 TO 0) AS LONG
    ELSEIF pl.currentIndex > pl.count THEN
        pl.currentIndex = pl.count
    END IF

    IF pl.isShuffle _ANDALSO pl.count > 0 THEN
        Playlist_Shuffle pl
    END IF

    Playlist_Remove = _TRUE
END FUNCTION

''' @brief Removes a song entry from the playlist by 1-based index (subroutine version).
''' @param pl The Playlist instance.
''' @param index 1-based index of entry to remove.
SUB Playlist_Remove (pl AS Playlist, index AS LONG)
    DIM ignored AS _BYTE: ignored = Playlist_Remove(pl, index)
END SUB

''' @brief Generates a randomized permutation of playlist indices for shuffle playback.
''' @param pl The Playlist instance.
SUB Playlist_Shuffle (pl AS Playlist)
    IF pl.count <= 0 THEN
        pl.shufflePos = 0
        EXIT SUB
    END IF

    IF UBOUND(pl.shuffleOrder) < pl.count THEN
        REDIM _PRESERVE pl.shuffleOrder(1 TO pl.count) AS LONG
    END IF

    DIM i AS LONG
    FOR i = 1 TO pl.count
        pl.shuffleOrder(i) = i
    NEXT i

    ' Fisher-Yates shuffle
    FOR i = pl.count TO 2 STEP -1
        DIM j AS LONG: j = 1 + INT(RND * i)
        DIM tmp AS LONG: tmp = pl.shuffleOrder(i)
        pl.shuffleOrder(i) = pl.shuffleOrder(j)
        pl.shuffleOrder(j) = tmp
    NEXT i

    ' If currentIndex is active, find its position in shuffleOrder
    pl.shufflePos = 1
    IF pl.currentIndex >= 1 _ANDALSO pl.currentIndex <= pl.count THEN
        FOR i = 1 TO pl.count
            IF pl.shuffleOrder(i) = pl.currentIndex THEN
                ' Swap with pos 1 so current song continues smoothly
                tmp = pl.shuffleOrder(1)
                pl.shuffleOrder(1) = pl.shuffleOrder(i)
                pl.shuffleOrder(i) = tmp
                EXIT FOR
            END IF
        NEXT i
    END IF
END SUB

''' @brief Enables or disables shuffle mode.
''' @param pl The Playlist instance.
''' @param enable _TRUE to enable shuffle, _FALSE to disable.
SUB Playlist_SetShuffle (pl AS Playlist, enable AS _BYTE)
    pl.isShuffle = enable
    IF enable THEN
        Playlist_Shuffle pl
    ELSE
        pl.shufflePos = 0
    END IF
END SUB

''' @brief Sets the playlist repeat mode.
''' @param pl The Playlist instance.
''' @param mode PLAYLIST_REPEAT_NONE, PLAYLIST_REPEAT_ALL, or PLAYLIST_REPEAT_ONE.
SUB Playlist_SetRepeatMode (pl AS Playlist, mode AS _BYTE)
    pl.repeatMode = mode
END SUB

''' @brief Advances to the next track in the playlist based on repeat mode and shuffle.
''' @param pl The Playlist instance.
''' @return 1-based index of next track, or 0 if end of playlist is reached.
FUNCTION Playlist_GetNext& (pl AS Playlist)
    IF pl.count <= 0 THEN EXIT FUNCTION

    IF pl.repeatMode = PLAYLIST_REPEAT_ONE THEN
        Playlist_GetNext = pl.currentIndex
        EXIT FUNCTION
    END IF

    IF pl.isShuffle THEN
        IF pl.shufflePos < pl.count THEN
            pl.shufflePos = pl.shufflePos + 1
            pl.currentIndex = pl.shuffleOrder(pl.shufflePos)
            Playlist_GetNext = pl.currentIndex
        ELSE
            IF pl.repeatMode = PLAYLIST_REPEAT_ALL THEN
                Playlist_Shuffle pl
                pl.currentIndex = pl.shuffleOrder(1)
                Playlist_GetNext = pl.currentIndex
            END IF
        END IF
    ELSE
        IF pl.currentIndex < pl.count THEN
            pl.currentIndex = pl.currentIndex + 1
            Playlist_GetNext = pl.currentIndex
        ELSE
            IF pl.repeatMode = PLAYLIST_REPEAT_ALL THEN
                pl.currentIndex = 1
                Playlist_GetNext = pl.currentIndex
            END IF
        END IF
    END IF
END FUNCTION

''' @brief Returns to the previous track in the playlist.
''' @param pl The Playlist instance.
''' @return 1-based index of previous track, or 1 if at start and not repeating.
FUNCTION Playlist_GetPrevious& (pl AS Playlist)
    IF pl.count <= 0 THEN EXIT FUNCTION

    IF pl.repeatMode = PLAYLIST_REPEAT_ONE THEN
        Playlist_GetPrevious = pl.currentIndex
        EXIT FUNCTION
    END IF

    IF pl.isShuffle THEN
        IF pl.shufflePos > 1 THEN
            pl.shufflePos = pl.shufflePos - 1
            pl.currentIndex = pl.shuffleOrder(pl.shufflePos)
            Playlist_GetPrevious = pl.currentIndex
        ELSE
            IF pl.repeatMode = PLAYLIST_REPEAT_ALL THEN
                pl.shufflePos = pl.count
                pl.currentIndex = pl.shuffleOrder(pl.shufflePos)
                Playlist_GetPrevious = pl.currentIndex
            ELSE
                Playlist_GetPrevious = pl.currentIndex
            END IF
        END IF
    ELSE
        IF pl.currentIndex > 1 THEN
            pl.currentIndex = pl.currentIndex - 1
            Playlist_GetPrevious = pl.currentIndex
        ELSE
            IF pl.repeatMode = PLAYLIST_REPEAT_ALL THEN
                pl.currentIndex = pl.count
                Playlist_GetPrevious = pl.currentIndex
            ELSE
                Playlist_GetPrevious = 1
            END IF
        END IF
    END IF
END FUNCTION

''' @brief Loads tracks from an M3U or M3U8 playlist file.
''' @param pl The Playlist instance.
''' @param m3uFilePath Path to the .m3u / .m3u8 file.
''' @return _TRUE if at least one track was loaded, _FALSE otherwise.
FUNCTION Playlist_LoadM3U%% (pl AS Playlist, m3uFilePath AS STRING)
    DIM content AS STRING: content = File_Load$(m3uFilePath)
    IF LEN(content) = 0 THEN EXIT FUNCTION

    DIM m3uDir AS STRING: m3uDir = Pathname_GetPath(m3uFilePath)
    DIM countBefore AS LONG: countBefore = pl.count

    DIM pStart AS LONG: pStart = 1
    DIM cLen AS LONG: cLen = LEN(content)

    WHILE pStart <= cLen
        DIM pEnd AS LONG: pEnd = INSTR(pStart, content, _STR_LF)
        DIM lineStr AS STRING

        IF pEnd > 0 THEN
            lineStr = MID$(content, pStart, pEnd - pStart)
            pStart = pEnd + 1
        ELSE
            lineStr = MID$(content, pStart)
            pStart = cLen + 1
        END IF

        ' Trim carriage return and whitespace
        lineStr = _TRIM$(lineStr)
        IF RIGHT$(lineStr, 1) = _CHR_CR THEN lineStr = LEFT$(lineStr, LEN(lineStr) - 1)
        lineStr = _TRIM$(lineStr)

        IF LEN(lineStr) > 0 THEN
            IF LEFT$(lineStr, 1) = "#" THEN
                ' Directive or comment (#EXTM3U, #EXTINF, etc.); ignore
            ELSE
                ' File path entry
                DIM resolvedPath AS STRING: resolvedPath = lineStr
                IF NOT Pathname_IsAbsolute(resolvedPath) THEN
                    resolvedPath = m3uDir + resolvedPath
                END IF

                DIM added AS _BYTE
                added = Playlist_Add(pl, resolvedPath)
            END IF
        END IF
    WEND

    Playlist_LoadM3U = (pl.count > countBefore)
END FUNCTION

''' @brief Loads tracks from an M3U or M3U8 playlist file (subroutine version).
''' @param pl The Playlist instance.
''' @param m3uFilePath Path to the .m3u / .m3u8 file.
SUB Playlist_LoadM3U (pl AS Playlist, m3uFilePath AS STRING)
    DIM ignored AS _BYTE: ignored = Playlist_LoadM3U(pl, m3uFilePath)
END SUB

''' @brief Saves current playlist entries to an M3U file.
''' @param pl The Playlist instance.
''' @param m3uFilePath Target file path.
''' @return _TRUE if saved successfully, _FALSE otherwise.
FUNCTION Playlist_SaveM3U%% (pl AS Playlist, m3uFilePath AS STRING)
    IF pl.count <= 0 THEN EXIT FUNCTION

    DIM outStr AS STRING: outStr = "#EXTM3U" + _STR_CRLF

    DIM i AS LONG
    FOR i = 1 TO pl.count
        outStr = outStr + "#EXTINF:-1," + pl.entries(i).fileName + _STR_CRLF
        outStr = outStr + pl.entries(i).filePath + _STR_CRLF
    NEXT i

    Playlist_SaveM3U = File_Save(outStr, m3uFilePath, _TRUE)
END FUNCTION

''' @brief Saves current playlist entries to an M3U file (subroutine version).
''' @param pl The Playlist instance.
''' @param m3uFilePath Target file path.
SUB Playlist_SaveM3U (pl AS Playlist, m3uFilePath AS STRING)
    DIM ignored AS _BYTE: ignored = Playlist_SaveM3U(pl, m3uFilePath)
END SUB
