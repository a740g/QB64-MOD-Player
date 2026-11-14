'-----------------------------------------------------------------------------------------------------------------------
' File management routines
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Pathname.bi'
'$INCLUDE:'Time.bi'

CONST __FILE_UPDATES_PER_SECOND_DEFAULT = 120 ' refresh happens 120 times a second
CONST __FILE_TIMEOUT_DEFAULT = 60 * 5 ' timeout happens after 5 mins by default

' This keeps track of the settings used by LoadFileFromURL()
TYPE __FileType
    initialized AS _BYTE
    updatesPerSecond AS _UNSIGNED LONG
    timeoutTicks AS _UNSIGNED _INTEGER64
    percentCompleted AS _UNSIGNED _BYTE
END TYPE

DIM __File AS __FileType

''' @brief Loads a file from disk or from a URL into memory.
''' @param PathOrURL The local file path or URL to load.
''' @return The loaded file content as a string, or empty string on failure.
FUNCTION File_Load$ (PathOrURL AS STRING)
    IF LEN(Pathname_GetDriveOrScheme(PathOrURL)) > 2 THEN
        File_Load = File_LoadFromURL(PathOrURL)
    ELSE
        File_Load = File_LoadFromDisk(PathOrURL)
    END IF
END FUNCTION

''' @brief Loads a whole file from disk into memory.
''' @param path The local file path to load.
''' @return The loaded file content as a string, or empty string if file does not exist.
FUNCTION File_LoadFromDisk$ (path AS STRING)
    IF _FILEEXISTS(path) THEN
        File_LoadFromDisk = _READFILE$(path)
    END IF
END FUNCTION

''' @brief Loads a whole file from an HTTP URL into memory.
''' @param url The URL to download from.
''' @return The downloaded content as a string, or empty string on failure.
FUNCTION File_LoadFromURL$ (url AS STRING)
    SHARED __File AS __FileType

    ' Set default properties if this is the first time
    IF NOT __File.initialized THEN File_SetDownloaderProperties __FILE_UPDATES_PER_SECOND_DEFAULT, __FILE_TIMEOUT_DEFAULT

    __File.percentCompleted = 0

    DIM h AS LONG: h = _OPENCLIENT("HTTP:" + url)

    IF h <> 0 THEN
        DIM startTick AS _UNSIGNED _INTEGER64: startTick = Time_GetTicks ' record the current tick
        DIM AS STRING content, buffer

        WHILE NOT EOF(h)
            GET h, , buffer
            content = content + buffer
            IF __File.updatesPerSecond > 0 THEN _LIMIT __File.updatesPerSecond
            IF __File.timeoutTicks > 0 AND (Time_GetTicks - startTick) > __File.timeoutTicks THEN EXIT WHILE
            __File.percentCompleted = (LEN(content) / LOF(h)) * 100!
        WEND

        CLOSE h

        File_LoadFromURL = content
    END IF
END FUNCTION

''' @brief Configures properties for the HTTP file downloader.
''' @param updatesPerSecond The maximum number of download loop cycles per second (refresh rate).
''' @param timeoutSeconds The timeout in seconds before download aborts.
SUB File_SetDownloaderProperties (updatesPerSecond AS _UNSIGNED LONG, timeoutSeconds AS _UNSIGNED LONG)
    SHARED __File AS __FileType

    __File.updatesPerSecond = updatesPerSecond
    __File.timeoutTicks = 1000 * timeoutSeconds ' convert to ticks
    __File.initialized = _TRUE
END SUB

''' @brief Saves a buffer to a file on disk.
''' @param buffer The string buffer to save.
''' @param fileName The path of the file to save to.
''' @param overwrite If _FALSE and the file already exists, the file will not be overwritten.
''' @return _TRUE if the file was written, _FALSE if skipped due to existing file.
FUNCTION File_Save%% (buffer AS STRING, fileName AS STRING, overwrite AS _BYTE)
    IF _FILEEXISTS(fileName) AND NOT overwrite THEN EXIT FUNCTION
    _WRITEFILE fileName, buffer
    File_Save = _TRUE
END FUNCTION

''' @brief Saves a buffer to a file on disk.
''' @param buffer The string buffer to save.
''' @param fileName The path of the file to save to.
''' @param overwrite If _FALSE and the file already exists, the file will not be overwritten.
SUB File_Save (buffer AS STRING, fileName AS STRING, overwrite AS _BYTE)
    IF _FILEEXISTS(fileName) AND NOT overwrite THEN EXIT SUB
    _WRITEFILE fileName, buffer
END SUB

''' @brief Copies a source file to a destination file.
''' @param fileSrc The path of the source file.
''' @param fileDst The path of the destination file.
''' @param overwrite If _FALSE and the destination file already exists, it will not be overwritten.
''' @return _TRUE if the copy succeeded, _FALSE otherwise.
FUNCTION File_Copy%% (fileSrc AS STRING, fileDst AS STRING, overwrite AS _BYTE)
    File_Copy = File_Save(File_Load(fileSrc), fileDst, overwrite)
END FUNCTION

''' @brief Copies a source file to a destination file.
''' @param fileSrc The path of the source file.
''' @param fileDst The path of the destination file.
''' @param overwrite If _FALSE and the destination file already exists, it will not be overwritten.
SUB File_Copy (fileSrc AS STRING, fileDst AS STRING, overwrite AS _BYTE)
    File_Save File_Load(fileSrc), fileDst, overwrite
END SUB
