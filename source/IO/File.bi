'-----------------------------------------------------------------------------------------------------------------------
' File management routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$LET TOOLBOX64_STRICT = TRUE
'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'
'$INCLUDE:'../Core/String.bi'
'$INCLUDE:'../FS/Pathname.bi'
'$INCLUDE:'../Core/TimeOps.bi'

CONST __FILE_UPDATES_PER_SECOND_DEFAULT = 120 ' refresh happens 120 times a second
CONST __FILE_TIMEOUT_DEFAULT = 60 * 5 ' timeout happens after 5 mins by default

' These must be kept in sync with FileOps.h
CONST FILE_ATTRIBUTE_DIRECTORY = &H10~&
CONST FILE_ATTRIBUTE_REGULAR_FILE = &H20~&
CONST FILE_ATTRIBUTE_READONLY = &H01~&
CONST FILE_ATTRIBUTE_HIDDEN = &H02~&
CONST FILE_ATTRIBUTE_SYSTEM = &H04~&
CONST FILE_ATTRIBUTE_ARCHIVE = &H08~&

' This keeps track of the settings used by LoadFileFromURL()
TYPE __FileType
    initialized AS _BYTE
    updatesPerSecond AS _UNSIGNED LONG
    timeoutTicks AS _UNSIGNED _INTEGER64
    percentCompleted AS _UNSIGNED _BYTE
END TYPE

DIM __File AS __FileType

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'CONST SEARCH_URL = "https://api.modarchive.org/downloads.php?moduleid="

'File_SetDownloaderProperties 0, 0

'DIM buffer AS STRING: buffer = File_Load("https://modarchive.org/index.php?request=view_random")
'DIM bufPos AS LONG: bufPos = INSTR(buffer, SEARCH_URL)
'IF bufPos > 0 THEN
'    PRINT MID$(buffer, bufPos, INSTR(bufPos, buffer, CHR$(34)) - bufPos)
'END IF

'DIM fname AS STRING: fname = "../.gitignore"
'DIM attr AS _UNSIGNED LONG: attr = File_GetAttributes(fname)
'PRINT "File size:"; File_GetSize(fname)
'PRINT "Attributes :"; HEX$(attr)
'PRINT _IIF(attr AND FILE_ATTRIBUTE_DIRECTORY, "Is directory", "Not a directory")
'PRINT _IIF(attr AND FILE_ATTRIBUTE_REGULAR_FILE, "Is a regular file", "Not a regular file")
'PRINT _IIF(attr AND FILE_ATTRIBUTE_READONLY, "Is read-only", "Not read-only")
'PRINT _IIF(attr AND FILE_ATTRIBUTE_HIDDEN, "Is hidden", "Not hidden")
'PRINT _IIF(attr AND FILE_ATTRIBUTE_ARCHIVE, "Is archive", "Not archive")
'PRINT _IIF(attr AND FILE_ATTRIBUTE_SYSTEM, "Is system", "Not system")
'PRINT "Modified time:"; File_GetModifiedTime(fname)

'END
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "File"
    FUNCTION __File_GetAttributes~& (pathName AS STRING)
    FUNCTION __File_GetSize&& (pathName AS STRING)
    FUNCTION __File_GetModifiedTime&& (pathName AS STRING)
END DECLARE

' Load a file from a file or URL
FUNCTION File_Load$ (PathOrURL AS STRING)
    IF LEN(Pathname_GetDriveOrScheme(PathOrURL)) > 2 THEN
        File_Load = File_LoadFromURL(PathOrURL)
    ELSE
        File_Load = File_LoadFromDisk(PathOrURL)
    END IF
END FUNCTION


' Loads a whole file from disk into memory
FUNCTION File_LoadFromDisk$ (path AS STRING)
    IF _FILEEXISTS(path) THEN
        File_LoadFromDisk = _READFILE$(path)
    END IF
END FUNCTION


' Loads a whole file from a URL into memory
FUNCTION File_LoadFromURL$ (url AS STRING)
    SHARED __File AS __FileType

    ' Set default properties if this is the first time
    IF NOT __File.initialized THEN File_SetDownloaderProperties __FILE_UPDATES_PER_SECOND_DEFAULT, __FILE_TIMEOUT_DEFAULT

    __File.percentCompleted = 0

    DIM h AS LONG: h = _OPENCLIENT("HTTP:" + url)

    IF h <> NULL THEN
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


' Changes the default settings for the HTTP downloader
SUB File_SetDownloaderProperties (updatesPerSecond AS _UNSIGNED LONG, timeoutSeconds AS _UNSIGNED LONG)
    SHARED __File AS __FileType

    __File.updatesPerSecond = updatesPerSecond
    __File.timeoutTicks = 1000 * timeoutSeconds ' convert to ticks
    __File.initialized = _TRUE
END SUB


' Save a buffer to a file
FUNCTION File_Save%% (buffer AS STRING, fileName AS STRING, overwrite AS _BYTE)
    IF _FILEEXISTS(fileName) AND NOT overwrite THEN EXIT FUNCTION
    _WRITEFILE fileName, buffer
    File_Save = _TRUE
END FUNCTION


' Sub version of the above
SUB File_Save (buffer AS STRING, fileName AS STRING, overwrite AS _BYTE)
    IF _FILEEXISTS(fileName) AND NOT overwrite THEN EXIT SUB
    _WRITEFILE fileName, buffer
END SUB


' Copies file src to dst. Src file must exist and dst file must not
FUNCTION File_Copy%% (fileSrc AS STRING, fileDst AS STRING, overwrite AS _BYTE)
    File_Copy = File_Save(File_Load(fileSrc), fileDst, overwrite)
END FUNCTION


' Sub version of the above
SUB File_Copy (fileSrc AS STRING, fileDst AS STRING, overwrite AS _BYTE)
    File_Save File_Load(fileSrc), fileDst, overwrite
END SUB


' Returns the size of a file
FUNCTION File_GetSize&& (pathName AS STRING)
    File_GetSize = __File_GetSize(String_ToCStr(pathName))
END FUNCTION


' Returns the attributes of a file / directory
' See FILE_ATTRIBUTE_* CONSTs
FUNCTION File_GetAttributes~& (pathName AS STRING)
    File_GetAttributes = __File_GetAttributes(String_ToCStr(pathName))
END FUNCTION

' Returns the creation time of a file
FUNCTION File_GetModifiedTime&& (pathName AS STRING)
    File_GetModifiedTime = __File_GetModifiedTime(String_ToCStr(pathName))
END FUNCTION
