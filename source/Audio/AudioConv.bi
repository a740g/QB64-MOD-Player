'-----------------------------------------------------------------------------------------------------------------------
' Simple audio conversion and resampling library
' Copyright (c) 2024 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'

DECLARE LIBRARY "AudioConv"
    SUB AudioConv_ConvertU8ToS8 (BYVAL buffer AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG)
    SUB AudioConv_ConvertU16ToS16 (BYVAL buffer AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG)
    SUB AudioConv_ConvertS8ToF32 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertU8ToF32 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertS8ToS16 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertU8ToS16 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertS16ToF32 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertS32ToF32 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertALawToS16 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertALawToF32 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertMuLawToS16 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertMuLawToF32 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertADPCM4ToS8 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL srcLen AS _UNSIGNED LONG, compTab AS STRING, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertDualMonoToStereoS8 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertDualMonoToStereoS16 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    SUB AudioConv_ConvertDualMonoToStereoF32 (BYVAL src AS _UNSIGNED _OFFSET, BYVAL samples AS _UNSIGNED LONG, BYVAL dst AS _UNSIGNED _OFFSET)
    FUNCTION AudioConv_ResampleS16~&& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL srcSampleRate AS LONG, BYVAL dstSampleRate AS LONG, BYVAL inputSampleFrames AS _UNSIGNED _INTEGER64, BYVAL channels AS _UNSIGNED LONG)
    FUNCTION AudioConv_ResampleF32~&& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL srcSampleRate AS LONG, BYVAL dstSampleRate AS LONG, BYVAL inputSampleFrames AS _UNSIGNED _INTEGER64, BYVAL channels AS _UNSIGNED LONG)
    FUNCTION AudioConv_ResampleS32~&& (BYVAL src AS _UNSIGNED _OFFSET, BYVAL dst AS _UNSIGNED _OFFSET, BYVAL srcSampleRate AS LONG, BYVAL dstSampleRate AS LONG, BYVAL inputSampleFrames AS _UNSIGNED _INTEGER64, BYVAL channels AS _UNSIGNED LONG)
END DECLARE
