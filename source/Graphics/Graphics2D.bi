'-----------------------------------------------------------------------------------------------------------------------
' Extended graphics routines
' Copyright (c) 2025 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'../Core/Common.bi'
'$INCLUDE:'../Core/Types.bi'

' 32-bit BGRA color constants based on HTML color names
CONST BGRA_ALICEBLUE~& = &HFFF0F8FF~&
CONST BGRA_ALMOND~& = &HFFEFDECD~&
CONST BGRA_ANTIQUEBRASS~& = &HFFCD9575~&
CONST BGRA_ANTIQUEWHITE~& = &HFFFAEBD7~&
CONST BGRA_APRICOT~& = &HFFFDD9B5~&
CONST BGRA_AQUA~& = &HFF00FFFF~&
CONST BGRA_AQUAMARINE~& = &HFF7FFFD4~&
CONST BGRA_ASPARAGUS~& = &HFF87A96B~&
CONST BGRA_ATOMICTANGERINE~& = &HFFFFA474~&
CONST BGRA_AZURE~& = &HFFF0FFFF~&
CONST BGRA_BANANAMANIA~& = &HFFFAE7B5~&
CONST BGRA_BEAVER~& = &HFF9F8170~&
CONST BGRA_BEIGE~& = &HFFF5F5DC~&
CONST BGRA_BISQUE~& = &HFFFFE4C4~&
CONST BGRA_BITTERSWEET~& = &HFFFD7C6E~&
CONST BGRA_BLACK~& = &HFF000000~&
CONST BGRA_BLANCHEDALMOND~& = &HFFFFEBCD~&
CONST BGRA_BLIZZARDBLUE~& = &HFFACE5EE~&
CONST BGRA_BLUE~& = &HFF0000FF~&
CONST BGRA_BLUEBELL~& = &HFFA2A2D0~&
CONST BGRA_BLUEGRAY~& = &HFF6699CC~&
CONST BGRA_BLUEGREEN~& = &HFF0D98BA~&
CONST BGRA_BLUEVIOLET~& = &HFF8A2BE2~&
CONST BGRA_BLUSH~& = &HFFDE5D83~&
CONST BGRA_BRICKRED~& = &HFFCB4154~&
CONST BGRA_BROWN~& = &HFFA52A2A~&
CONST BGRA_BURLYWOOD~& = &HFFDEB887~&
CONST BGRA_BURNTORANGE~& = &HFFFF7F49~&
CONST BGRA_BURNTSIENNA~& = &HFFEA7E5D~&
CONST BGRA_CADETBLUE~& = &HFF5F9EA0~&
CONST BGRA_CANARY~& = &HFFFFFF99~&
CONST BGRA_CARIBBEANGREEN~& = &HFF1CD3A2~&
CONST BGRA_CARNATIONPINK~& = &HFFFFAACC~&
CONST BGRA_CERISE~& = &HFFDD4492~&
CONST BGRA_CERULEAN~& = &HFF1DACD6~&
CONST BGRA_CHARTREUSE~& = &HFF7FFF00~&
CONST BGRA_CHESTNUT~& = &HFFBC5D58~&
CONST BGRA_CHOCOLATE~& = &HFFD2691E~&
CONST BGRA_COPPER~& = &HFFDD9475~&
CONST BGRA_CORAL~& = &HFFFF7F50~&
CONST BGRA_CORNFLOWER~& = &HFF9ACEEB~&
CONST BGRA_CORNFLOWERBLUE~& = &HFF6495ED~&
CONST BGRA_CORNSILK~& = &HFFFFF8DC~&
CONST BGRA_COTTONCANDY~& = &HFFFFBCD9~&
CONST BGRA_CRAYOLAAQUAMARINE~& = &HFF78DBE2~&
CONST BGRA_CRAYOLABLUE~& = &HFF1F75FE~&
CONST BGRA_CRAYOLABLUEVIOLET~& = &HFF7366BD~&
CONST BGRA_CRAYOLABROWN~& = &HFFB4674D~&
CONST BGRA_CRAYOLACADETBLUE~& = &HFFB0B7C6~&
CONST BGRA_CRAYOLAFORESTGREEN~& = &HFF6DAE81~&
CONST BGRA_CRAYOLAGOLD~& = &HFFE7C697~&
CONST BGRA_CRAYOLAGOLDENROD~& = &HFFFCD975~&
CONST BGRA_CRAYOLAGRAY~& = &HFF95918C~&
CONST BGRA_CRAYOLAGREEN~& = &HFF1CAC78~&
CONST BGRA_CRAYOLAGREENYELLOW~& = &HFFF0E891~&
CONST BGRA_CRAYOLAINDIGO~& = &HFF5D76CB~&
CONST BGRA_CRAYOLALAVENDER~& = &HFFFCB4D5~&
CONST BGRA_CRAYOLAMAGENTA~& = &HFFF664AF~&
CONST BGRA_CRAYOLAMAROON~& = &HFFC8385A~&
CONST BGRA_CRAYOLAMIDNIGHTBLUE~& = &HFF1A4876~&
CONST BGRA_CRAYOLAORANGE~& = &HFFFF7538~&
CONST BGRA_CRAYOLAORANGERED~& = &HFFFF2B2B~&
CONST BGRA_CRAYOLAORCHID~& = &HFFE6A8D7~&
CONST BGRA_CRAYOLAPLUM~& = &HFF8E4585~&
CONST BGRA_CRAYOLARED~& = &HFFEE204D~&
CONST BGRA_CRAYOLASALMON~& = &HFFFF9BAA~&
CONST BGRA_CRAYOLASEAGREEN~& = &HFF9FE2BF~&
CONST BGRA_CRAYOLASILVER~& = &HFFCDC5C2~&
CONST BGRA_CRAYOLASKYBLUE~& = &HFF80DAEB~&
CONST BGRA_CRAYOLASPRINGGREEN~& = &HFFECEABE~&
CONST BGRA_CRAYOLATANN~& = &HFFFAA76C~&
CONST BGRA_CRAYOLATHISTLE~& = &HFFEBC7DF~&
CONST BGRA_CRAYOLAVIOLET~& = &HFF926EAE~&
CONST BGRA_CRAYOLAYELLOW~& = &HFFFCE883~&
CONST BGRA_CRAYOLAYELLOWGREEN~& = &HFFC5E384~&
CONST BGRA_CRIMSON~& = &HFFDC143C~&
CONST BGRA_CYAN~& = &HFF00FFFF~&
CONST BGRA_DANDELION~& = &HFFFDDB6D~&
CONST BGRA_DARKBLUE~& = &HFF00008B~&
CONST BGRA_DARKCYAN~& = &HFF008B8B~&
CONST BGRA_DARKGOLDENROD~& = &HFFB8860B~&
CONST BGRA_DARKGRAY~& = &HFFA9A9A9~&
CONST BGRA_DARKGREEN~& = &HFF006400~&
CONST BGRA_DARKKHAKI~& = &HFFBDB76B~&
CONST BGRA_DARKMAGENTA~& = &HFF8B008B~&
CONST BGRA_DARKOLIVEGREEN~& = &HFF556B2F~&
CONST BGRA_DARKORANGE~& = &HFFFF8C00~&
CONST BGRA_DARKORCHID~& = &HFF9932CC~&
CONST BGRA_DARKRED~& = &HFF8B0000~&
CONST BGRA_DARKSALMON~& = &HFFE9967A~&
CONST BGRA_DARKSEAGREEN~& = &HFF8FBC8F~&
CONST BGRA_DARKSLATEBLUE~& = &HFF483D8B~&
CONST BGRA_DARKSLATEGRAY~& = &HFF2F4F4F~&
CONST BGRA_DARKTURQUOISE~& = &HFF00CED1~&
CONST BGRA_DARKVIOLET~& = &HFF9400D3~&
CONST BGRA_DEEPPINK~& = &HFFFF1493~&
CONST BGRA_DEEPSKYBLUE~& = &HFF00BFFF~&
CONST BGRA_DENIM~& = &HFF2B6CC4~&
CONST BGRA_DESERTSAND~& = &HFFEFCDB8~&
CONST BGRA_DIMGRAY~& = &HFF696969~&
CONST BGRA_DODGERBLUE~& = &HFF1E90FF~&
CONST BGRA_EGGPLANT~& = &HFF6E5160~&
CONST BGRA_ELECTRICLIME~& = &HFFCEFF1D~&
CONST BGRA_FERN~& = &HFF71BC78~&
CONST BGRA_FIREBRICK~& = &HFFB22222~&
CONST BGRA_FLORALWHITE~& = &HFFFFFAF0~&
CONST BGRA_FORESTGREEN~& = &HFF228B22~&
CONST BGRA_FUCHSIA~& = &HFFC364C5~&
CONST BGRA_FUZZYWUZZY~& = &HFFCC6666~&
CONST BGRA_GAINSBORO~& = &HFFDCDCDC~&
CONST BGRA_GHOSTWHITE~& = &HFFF8F8FF~&
CONST BGRA_GOLD~& = &HFFFFD700~&
CONST BGRA_GOLDENROD~& = &HFFDAA520~&
CONST BGRA_GRANNYSMITHAPPLE~& = &HFFA8E4A0~&
CONST BGRA_GRAY~& = &HFF808080~&
CONST BGRA_GREEN~& = &HFF008000~&
CONST BGRA_GREENBLUE~& = &HFF1164B4~&
CONST BGRA_GREENYELLOW~& = &HFFADFF2F~&
CONST BGRA_HONEYDEW~& = &HFFF0FFF0~&
CONST BGRA_HOTMAGENTA~& = &HFFFF1DCE~&
CONST BGRA_HOTPINK~& = &HFFFF69B4~&
CONST BGRA_INCHWORM~& = &HFFB2EC5D~&
CONST BGRA_INDIANRED~& = &HFFCD5C5C~&
CONST BGRA_INDIGO~& = &HFF4B0082~&
CONST BGRA_IVORY~& = &HFFFFFFF0~&
CONST BGRA_JAZZBERRYJAM~& = &HFFCA3767~&
CONST BGRA_JUNGLEGREEN~& = &HFF3BB08F~&
CONST BGRA_KHAKI~& = &HFFF0E68C~&
CONST BGRA_LASERLEMON~& = &HFFFEFE22~&
CONST BGRA_LAVENDER~& = &HFFE6E6FA~&
CONST BGRA_LAVENDERBLUSH~& = &HFFFFF0F5~&
CONST BGRA_LAWNGREEN~& = &HFF7CFC00~&
CONST BGRA_LEMONCHIFFON~& = &HFFFFFACD~&
CONST BGRA_LEMONYELLOW~& = &HFFFFF44F~&
CONST BGRA_LIGHTBLUE~& = &HFFADD8E6~&
CONST BGRA_LIGHTCORAL~& = &HFFF08080~&
CONST BGRA_LIGHTCYAN~& = &HFFE0FFFF~&
CONST BGRA_LIGHTGOLDENRODYELLOW~& = &HFFFAFAD2~&
CONST BGRA_LIGHTGRAY~& = &HFFD3D3D3~&
CONST BGRA_LIGHTGREEN~& = &HFF90EE90~&
CONST BGRA_LIGHTPINK~& = &HFFFFB6C1~&
CONST BGRA_LIGHTSALMON~& = &HFFFFA07A~&
CONST BGRA_LIGHTSEAGREEN~& = &HFF20B2AA~&
CONST BGRA_LIGHTSKYBLUE~& = &HFF87CEFA~&
CONST BGRA_LIGHTSLATEGRAY~& = &HFF778899~&
CONST BGRA_LIGHTSTEELBLUE~& = &HFFB0C4DE~&
CONST BGRA_LIGHTYELLOW~& = &HFFFFFFE0~&
CONST BGRA_LIME~& = &HFF00FF00~&
CONST BGRA_LIMEGREEN~& = &HFF32CD32~&
CONST BGRA_LINEN~& = &HFFFAF0E6~&
CONST BGRA_MACARONIANDCHEESE~& = &HFFFFBD88~&
CONST BGRA_MAGENTA~& = &HFFFF00FF~&
CONST BGRA_MAGICMINT~& = &HFFAAF0D1~&
CONST BGRA_MAHOGANY~& = &HFFCD4A4C~&
CONST BGRA_MAIZE~& = &HFFEDD19C~&
CONST BGRA_MANATEE~& = &HFF979AAA~&
CONST BGRA_MANGOTANGO~& = &HFFFF8243~&
CONST BGRA_MAROON~& = &HFF800000~&
CONST BGRA_MAUVELOUS~& = &HFFEF98AA~&
CONST BGRA_MEDIUMAQUAMARINE~& = &HFF66CDAA~&
CONST BGRA_MEDIUMBLUE~& = &HFF0000CD~&
CONST BGRA_MEDIUMORCHID~& = &HFFBA55D3~&
CONST BGRA_MEDIUMPURPLE~& = &HFF9370DB~&
CONST BGRA_MEDIUMSEAGREEN~& = &HFF3CB371~&
CONST BGRA_MEDIUMSLATEBLUE~& = &HFF7B68EE~&
CONST BGRA_MEDIUMSPRINGGREEN~& = &HFF00FA9A~&
CONST BGRA_MEDIUMTURQUOISE~& = &HFF48D1CC~&
CONST BGRA_MEDIUMVIOLETRED~& = &HFFC71585~&
CONST BGRA_MELON~& = &HFFFDBCB4~&
CONST BGRA_MIDNIGHTBLUE~& = &HFF191970~&
CONST BGRA_MINTCREAM~& = &HFFF5FFFA~&
CONST BGRA_MISTYROSE~& = &HFFFFE4E1~&
CONST BGRA_MOCCASIN~& = &HFFFFE4B5~&
CONST BGRA_MOUNTAINMEADOW~& = &HFF30BA8F~&
CONST BGRA_MULBERRY~& = &HFFC54B8C~&
CONST BGRA_NAVAJOWHITE~& = &HFFFFDEAD~&
CONST BGRA_NAVY~& = &HFF000080~&
CONST BGRA_NAVYBLUE~& = &HFF1974D2~&
CONST BGRA_NEONCARROT~& = &HFFFFA343~&
CONST BGRA_OLDLACE~& = &HFFFDF5E6~&
CONST BGRA_OLIVE~& = &HFF808000~&
CONST BGRA_OLIVEDRAB~& = &HFF6B8E23~&
CONST BGRA_OLIVEGREEN~& = &HFFBAB86C~&
CONST BGRA_ORANGE~& = &HFFFFA500~&
CONST BGRA_ORANGERED~& = &HFFFF4500~&
CONST BGRA_ORANGEYELLOW~& = &HFFF8D568~&
CONST BGRA_ORCHID~& = &HFFDA70D6~&
CONST BGRA_OUTERSPACE~& = &HFF414A4C~&
CONST BGRA_OUTRAGEOUSORANGE~& = &HFFFF6E4A~&
CONST BGRA_PACIFICBLUE~& = &HFF1CA9C9~&
CONST BGRA_PALEGOLDENROD~& = &HFFEEE8AA~&
CONST BGRA_PALEGREEN~& = &HFF98FB98~&
CONST BGRA_PALETURQUOISE~& = &HFFAFEEEE~&
CONST BGRA_PALEVIOLETRED~& = &HFFDB7093~&
CONST BGRA_PAPAYAWHIP~& = &HFFFFEFD5~&
CONST BGRA_PEACH~& = &HFFFFCFAB~&
CONST BGRA_PEACHPUFF~& = &HFFFFDAB9~&
CONST BGRA_PERIWINKLE~& = &HFFC5D0E6~&
CONST BGRA_PERU~& = &HFFCD853F~&
CONST BGRA_PIGGYPINK~& = &HFFFDDDE6~&
CONST BGRA_PINEGREEN~& = &HFF158078~&
CONST BGRA_PINK~& = &HFFFFC0CB~&
CONST BGRA_PINKFLAMINGO~& = &HFFFC74FD~&
CONST BGRA_PINKSHERBET~& = &HFFF78FA7~&
CONST BGRA_PLUM~& = &HFFDDA0DD~&
CONST BGRA_POWDERBLUE~& = &HFFB0E0E6~&
CONST BGRA_PURPLE~& = &HFF800080~&
CONST BGRA_PURPLEHEART~& = &HFF7442C8~&
CONST BGRA_PURPLEMOUNTAINSMAJESTY~& = &HFF9D81BA~&
CONST BGRA_PURPLEPIZZAZZ~& = &HFFFE4EDA~&
CONST BGRA_RADICALRED~& = &HFFFF496C~&
CONST BGRA_RAWSIENNA~& = &HFFD68A59~&
CONST BGRA_RAWUMBER~& = &HFF714B23~&
CONST BGRA_RAZZLEDAZZLEROSE~& = &HFFFF48D0~&
CONST BGRA_RAZZMATAZZ~& = &HFFE3256B~&
CONST BGRA_RED~& = &HFFFF0000~&
CONST BGRA_REDORANGE~& = &HFFFF5349~&
CONST BGRA_REDVIOLET~& = &HFFC0448F~&
CONST BGRA_ROBINSEGGBLUE~& = &HFF1FCECB~&
CONST BGRA_ROSYBROWN~& = &HFFBC8F8F~&
CONST BGRA_ROYALBLUE~& = &HFF4169E1~&
CONST BGRA_ROYALPURPLE~& = &HFF7851A9~&
CONST BGRA_SADDLEBROWN~& = &HFF8B4513~&
CONST BGRA_SALMON~& = &HFFFA8072~&
CONST BGRA_SANDYBROWN~& = &HFFF4A460~&
CONST BGRA_SCARLET~& = &HFFFC2847~&
CONST BGRA_SCREAMINGREEN~& = &HFF76FF7A~&
CONST BGRA_SEAGREEN~& = &HFF2E8B57~&
CONST BGRA_SEASHELL~& = &HFFFFF5EE~&
CONST BGRA_SEPIA~& = &HFFA5694F~&
CONST BGRA_SHADOW~& = &HFF8A795D~&
CONST BGRA_SHAMROCK~& = &HFF45CEA2~&
CONST BGRA_SHOCKINGPINK~& = &HFFFB7EFD~&
CONST BGRA_SIENNA~& = &HFFA0522D~&
CONST BGRA_SILVER~& = &HFFC0C0C0~&
CONST BGRA_SKYBLUE~& = &HFF87CEEB~&
CONST BGRA_SLATEBLUE~& = &HFF6A5ACD~&
CONST BGRA_SLATEGRAY~& = &HFF708090~&
CONST BGRA_SNOW~& = &HFFFFFAFA~&
CONST BGRA_SPRINGGREEN~& = &HFF00FF7F~&
CONST BGRA_STEELBLUE~& = &HFF4682B4~&
CONST BGRA_SUNGLOW~& = &HFFFFCF48~&
CONST BGRA_SUNSETORANGE~& = &HFFFD5E53~&
CONST BGRA_TANN~& = &HFFD2B48C~&
CONST BGRA_TEAL~& = &HFF008080~&
CONST BGRA_TEALBLUE~& = &HFF18A7B5~&
CONST BGRA_THISTLE~& = &HFFD8BFD8~&
CONST BGRA_TICKLEMEPINK~& = &HFFFC89AC~&
CONST BGRA_TIMBERWOLF~& = &HFFDBD7D2~&
CONST BGRA_TOMATO~& = &HFFFF6347~&
CONST BGRA_TROPICALRAINFOREST~& = &HFF17806D~&
CONST BGRA_TUMBLEWEED~& = &HFFDEAA88~&
CONST BGRA_TURQUOISE~& = &HFF40E0D0~&
CONST BGRA_TURQUOISEBLUE~& = &HFF77DDE7~&
CONST BGRA_UNMELLOWYELLOW~& = &HFFFFFF66~&
CONST BGRA_VIOLET~& = &HFFEE82EE~&
CONST BGRA_VIOLETBLUE~& = &HFF324AB2~&
CONST BGRA_VIOLETRED~& = &HFFF75394~&
CONST BGRA_VIVIDTANGERINE~& = &HFFFFA089~&
CONST BGRA_VIVIDVIOLET~& = &HFF8F509D~&
CONST BGRA_WHEAT~& = &HFFF5DEB3~&
CONST BGRA_WHITE~& = &HFFFFFFFF~&
CONST BGRA_WHITESMOKE~& = &HFFF5F5F5~&
CONST BGRA_WILDBLUEYONDER~& = &HFFA2ADD0~&
CONST BGRA_WILDSTRAWBERRY~& = &HFFFF43A4~&
CONST BGRA_WILDWATERMELON~& = &HFFFC6C85~&
CONST BGRA_WISTERIA~& = &HFFCDA4DE~&
CONST BGRA_YELLOW~& = &HFFFFFF00~&
CONST BGRA_YELLOWGREEN~& = &HFF9ACD32~&
CONST BGRA_YELLOWORANGE~& = &HFFFFAE42~&

' This matches the QB64 BGRA 32-bit style color for little endian systems
TYPE BGRAType
    b AS _UNSIGNED _BYTE
    g AS _UNSIGNED _BYTE
    r AS _UNSIGNED _BYTE
    a AS _UNSIGNED _BYTE
END TYPE

'-----------------------------------------------------------------------------------------------------------------------
' TEST CODE
'-----------------------------------------------------------------------------------------------------------------------
'$DEBUG
'$CONSOLE

'$RESIZE:STRETCH

'SCREEN _NEWIMAGE(640, 480, 32)

'SCREEN _NEWIMAGE(640, 480, 13)

'SCREEN 0: WIDTH 160, 90: _FONT 8: _BLINK OFF

'PRINT HEX$(Graphics_InterpolateColor(BGRA_WHITE, BGRA_BLACK, 0.5!))
'PRINT Graphics_GetRGBDistance(BGRA_WHITE, BGRA_BLACK)
'PRINT Graphics_GetRGBDelta(BGRA_WHITE, BGRA_BLACK)

'DIM pal(0 TO 5) AS _UNSIGNED LONG
'pal(0) = BGRA_BLACK
'pal(1) = BGRA_WHITE
'pal(2) = BGRA_RED
'pal(3) = BGRA_GREEN
'pal(4) = BGRA_BLUE
'PRINT Graphics_FindClosestColor(BGRA_ORANGERED, pal(0), 5)

'COLOR 17, 6
'Graphics_SetForegroundColor 1
'Graphics_SetBackgroundColor 14

'PRINT Graphics_GetForegroundColor, Graphics_GetBackgroundColor
'PRINT _DEFAULTCOLOR, _BACKGROUNDCOLOR

'PRINT Graphics_MakeTextColorAttribute(56, 1, 14)
'PRINT Graphics_MakeDefaultTextColorAttribute(56)

'DIM i AS _UNSIGNED LONG

'i = Graphics_GetBGRAFromWebColor("090502")
'PRINT HEX$(i)
'i = Graphics_MakeBGRA(9, 5, 2, 255)
'PRINT HEX$(i)
'i = Graphics_MakeRGBA(9, 5, 2, 255)
'PRINT HEX$(i)
'PRINT HEX$(Graphics_GetRedFromRGBA(i))
'PRINT HEX$(Graphics_GetGreenFromRGBA(i))
'PRINT HEX$(Graphics_GetBlueFromRGBA(i))
'PRINT HEX$(Graphics_GetRGB(i))
'PRINT HEX$(Graphics_SwapRedBlue(i))

'DIM t AS DOUBLE: t = TIMER

'FOR i = 1 TO 100000
'    COLOR 17, 6: _PRINTSTRING (11, 11), "8"
'    Graphics_DrawPixel 10, 10, Graphics_MakeTextColorAttribute(56, 1, 14)
'    PSET (30, 30), 14
'    Graphics_DrawPixel 30, 30, 14
'    PSET (30, 30), _RGB32(166, 22, 183)
'    Graphics_DrawPixel 30, 30, _RGB32(166, 22, 183)

'    Graphics_DrawHorizontalLine 0, 45, 159, Graphics_MakeTextColorAttribute(56, 1, 14)
'    LINE (0, 240)-(639, 240), 14
'    Graphics_DrawHorizontalLine 0, 240, 639, 14
'    LINE (0, 240)-(639, 240), _RGB32(166, 22, 183)
'    Graphics_DrawHorizontalLine 0, 240, 639, _RGB32(166, 22, 183)

'    Graphics_DrawVerticalLine 80, 0, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
'    LINE (320, 0)-(320, 479), 14
'    Graphics_DrawVerticalLine 320, 0, 479, 14
'    LINE (320, 0)-(320, 479), _RGB32(166, 22, 183)
'    Graphics_DrawVerticalLine 320, 0, 479, _RGB32(166, 22, 183)

'    Graphics_DrawLine 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
'    LINE (0, 0)-(639, 479), 14
'    Graphics_DrawLine 0, 0, 639, 479, 14
'    LINE (0, 0)-(639, 479), _RGB32(166, 22, 183)
'    Graphics_DrawLine 0, 0, 639, 479, _RGB32(166, 22, 183)

'    Graphics_DrawRectangle 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
'    LINE (0, 0)-(639, 479), 14, B
'    Graphics_DrawRectangle 0, 0, 639, 479, 14
'    LINE (0, 0)-(639, 479), _RGB32(166, 22, 183), B
'    Graphics_DrawRectangle 0, 0, 639, 479, _RGB32(166, 22, 183)

'    Graphics_DrawFilledRectangle 0, 0, 159, 89, Graphics_MakeTextColorAttribute(56, 1, 14)
'    LINE (0, 0)-(639, 479), 14, BF
'    Graphics_DrawFilledRectangle 0, 0, 639, 479, 14
'    LINE (0, 0)-(639, 479), _RGB32(166, 22, 183), BF
'    Graphics_DrawFilledRectangle 0, 0, 639, 479, _RGB32(166, 22, 183)

'    Graphics_DrawCircle 80, 45, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
'    CIRCLE (320, 240), 200, 14
'    Graphics_DrawCircle 320, 240, 200, 14
'    CIRCLE (320, 240), 200, _RGB32(166, 22, 183)
'    Graphics_DrawCircle 320, 240, 200, _RGB32(166, 22, 183)

'    Graphics_DrawFilledCircle 80, 45, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
'    Graphics_DrawFilledCircle 320, 240, 200, 14
'    Graphics_DrawFilledCircle 320, 240, 200, _RGB32(166, 22, 183)

'    Graphics_DrawEllipse 80, 45, 60, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
'    Graphics_DrawEllipse 320, 240, 300, 200, 14
'    Graphics_DrawEllipse 320, 240, 300, 200, _RGB32(166, 22, 183)

'    Graphics_DrawFilledEllipse 80, 45, 60, 40, Graphics_MakeTextColorAttribute(56, 1, 14)
'    Graphics_DrawFilledEllipse 320, 240, 300, 200, 14
'    Graphics_DrawFilledEllipse 320, 240, 300, 200, _RGB32(166, 22, 183)

'    Graphics_DrawTriangle 2, 2, 14, 88, 158, 80, Graphics_MakeTextColorAttribute(56, 1, 14)
'    Graphics_DrawTriangle 20, 10, 70, 469, 629, 469, 14
'    Graphics_DrawTriangle 20, 10, 70, 469, 629, 469, _RGB32(166, 22, 183)

'    Graphics_DrawFilledTriangle 2, 2, 14, 88, 158, 80, Graphics_MakeTextColorAttribute(56, 1, 14)
'    Graphics_DrawFilledTriangle 20, 10, 70, 469, 629, 469, 14
'    Graphics_DrawFilledTriangle 20, 10, 70, 469, 629, 469, _RGB32(166, 22, 183)
'NEXT

'PRINT USING "###.### seconds to complete."; TIMER - t#

'_DISPLAY
'Graphics_DrawFilledTriangle 20, 10, 70, 469, 629, 469, _RGB32(166, 22, 183)
'Graphics_FadeScreen -1, 60, 100
'Graphics_DrawLine -40, -50, 639, 479, _RGB32(166, 22, 183)

'DIM txtImg AS LONG: txtImg = _NEWIMAGE(9, 9, 0)
'PRINT txtImg

'_DEST txtImg: _FONT 8 ' Switch to 8x8 font
'Graphics_DrawFilledCircle 4, 4, 4, Graphics_MakeTextColorAttribute(3, 1, 14)
'Graphics_DrawFilledRectangle 0, 0, 9, 9, Graphics_MakeTextColorAttribute(3, 1, 14)
'_DEST 0

'_CLEARCOLOR txtImg, Graphics_MakeTextColorAttribute(3, 1, 14)

'DO
'    DIM AS LONG x, y

'    WHILE _MOUSEINPUT
'        x = _MOUSEX
'        y = _MOUSEY
'    WEND

'    CLS

'    IF _PIXELSIZE = 0 THEN
'        _PUTIMAGE txtImg, x - 5, y - 5
'    ELSE
'        _PUTIMAGE txtImg, x - 36, y - 36
'    END IF

'    _DISPLAY

'    _LIMIT 60
'LOOP UNTIL _KEYHIT = 27

'Graphics_FadeScreen _TRUE, 60, 100

'END
'-----------------------------------------------------------------------------------------------------------------------

DECLARE LIBRARY "Graphics2D"
    FUNCTION Graphics_BGRATypeToBGRA~& (bgra AS BGRAType)
    SUB Graphics_DrawPixel (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    FUNCTION Graphics_GetPixel~& (BYVAL x AS LONG, BYVAL y AS LONG)
    FUNCTION Graphics_MakeTextColorAttribute~% (BYVAL character AS _UNSIGNED _BYTE, BYVAL fColor AS _UNSIGNED _BYTE, BYVAL bColor AS _UNSIGNED _BYTE)
    FUNCTION Graphics_MakeDefaultTextColorAttribute~% (BYVAL character AS _UNSIGNED _BYTE)
    FUNCTION Graphics_GetTextAttributeCharacter~%% (BYVAL clrAtr AS _UNSIGNED LONG)
    FUNCTION Graphics_GetTextAttributeForegroundColor~%% (BYVAL clrAtr AS _UNSIGNED LONG)
    FUNCTION Graphics_GetTextAttributeBackgroundColor~%% (BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_SetForegroundColor (BYVAL fColor AS _UNSIGNED LONG)
    FUNCTION Graphics_GetForegroundColor~&
    SUB Graphics_SetBackgroundColor (BYVAL bColor AS _UNSIGNED LONG)
    FUNCTION Graphics_GetBackgroundColor~&
    SUB Graphics_DrawHorizontalLine (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawVerticalLine (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawRectangle (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledRectangle (BYVAL lx AS LONG, BYVAL ty AS LONG, BYVAL rx AS LONG, BYVAL by AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawLine (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawCircle (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL radius AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledCircle (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL radius AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawEllipse (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL rx AS LONG, BYVAL ry AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledEllipse (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL rx AS LONG, BYVAL ry AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawTriangle (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, BYVAL x3 AS LONG, BYVAL y3 AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    SUB Graphics_DrawFilledTriangle (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG, BYVAL x3 AS LONG, BYVAL y3 AS LONG, BYVAL clrAtr AS _UNSIGNED LONG)
    FUNCTION Graphics_MakeBGRA~& ALIAS "image_make_bgra" (BYVAL r AS _UNSIGNED _BYTE, BYVAL g AS _UNSIGNED _BYTE, BYVAL b AS _UNSIGNED _BYTE, BYVAL a AS _UNSIGNED _BYTE)
    FUNCTION Graphics_MakeBGR~& ALIAS "image_make_bgra" (BYVAL r AS _UNSIGNED _BYTE, BYVAL g AS _UNSIGNED _BYTE, BYVAL b AS _UNSIGNED _BYTE)
    FUNCTION Graphics_GetRedFromBGRA~%% ALIAS "image_get_bgra_red" (BYVAL bgra AS _UNSIGNED LONG)
    FUNCTION Graphics_GetGreenFromBGRA~%% ALIAS "image_get_bgra_green" (BYVAL bgra AS _UNSIGNED LONG)
    FUNCTION Graphics_GetBlueFromBGRA~%% ALIAS "image_get_bgra_blue" (BYVAL bgra AS _UNSIGNED LONG)
    FUNCTION Graphics_GetAlphaFromBGRA~%% ALIAS "image_get_bgra_alpha" (BYVAL bgra AS _UNSIGNED LONG)
    FUNCTION Graphics_MakeRGBA~& (BYVAL r AS _UNSIGNED _BYTE, BYVAL g AS _UNSIGNED _BYTE, BYVAL b AS _UNSIGNED _BYTE, BYVAL a AS _UNSIGNED _BYTE)
    FUNCTION Graphics_GetRedFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetGreenFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetBlueFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetAlphaFromRGBA~%% (BYVAL rgba AS _UNSIGNED LONG)
    FUNCTION Graphics_GetRGB~& ALIAS "image_get_bgra_bgr" (BYVAL clr AS _UNSIGNED LONG)
    FUNCTION Graphics_SwapRedBlue~& ALIAS "image_swap_red_blue" (BYVAL clr AS _UNSIGNED LONG)
    FUNCTION Graphics_ClampColorComponent~%% ALIAS "image_clamp_color_component" (BYVAL c AS LONG)
    FUNCTION Graphics_GetRGBDistance! (BYVAL c1 AS _UNSIGNED LONG, BYVAL c2 AS _UNSIGNED LONG)
    FUNCTION Graphics_GetRGBDelta~& (BYVAL c1 AS _UNSIGNED LONG, BYVAL c2 AS _UNSIGNED LONG)
    FUNCTION Graphics_InterpolateColor~& (BYVAL colorA AS _UNSIGNED LONG, BYVAL colorB AS _UNSIGNED LONG, BYVAL factor AS SINGLE)
    SUB Graphics_RenderASCIIArt (BYVAL srcImage AS LONG, BYVAL dstImage AS LONG)
    FUNCTION Graphics_FindClosestColor~& (BYVAL clr AS _UNSIGNED LONG, paletteArray AS _UNSIGNED LONG, BYVAL paletteColors AS _UNSIGNED LONG)
END DECLARE


' Converts a web color in hex format to a 32-bit RGB color
FUNCTION Graphics_GetBGRAFromWebColor~& (webColor AS STRING)
    IF LEN(webColor) <> 6 THEN ERROR _ERR_ILLEGAL_FUNCTION_CALL
    Graphics_GetBGRAFromWebColor = Graphics_MakeBGRA(VAL("&H" + LEFT$(webColor, 2)), VAL("&H" + MID$(webColor, 3, 2)), VAL("&H" + RIGHT$(webColor, 2)), 255)
END FUNCTION


' This will progressively change the palette of dstImg to that of srcImg
' Keep calling this repeatedly until it returns true
FUNCTION Graphics_MorphPalette%% (dstImage AS LONG, srcImage AS LONG, startIndex AS _UNSIGNED _BYTE, stopIndex AS _UNSIGNED _BYTE)
    Graphics_MorphPalette = _TRUE ' Assume completed

    DIM i AS LONG: FOR i = startIndex TO stopIndex
        ' Get both src and dst colors of the current index
        DIM srcColor AS _UNSIGNED LONG: srcColor = _PALETTECOLOR(i, srcImage)
        DIM dstColor AS _UNSIGNED LONG: dstColor = _PALETTECOLOR(i, dstImage)

        ' Break down the colors into individual components
        DIM srcR AS _UNSIGNED _BYTE: srcR = _RED32(srcColor)
        DIM srcG AS _UNSIGNED _BYTE: srcG = _GREEN32(srcColor)
        DIM srcB AS _UNSIGNED _BYTE: srcB = _BLUE32(srcColor)
        DIM dstR AS _UNSIGNED _BYTE: dstR = _RED32(dstColor)
        DIM dstG AS _UNSIGNED _BYTE: dstG = _GREEN32(dstColor)
        DIM dstB AS _UNSIGNED _BYTE: dstB = _BLUE32(dstColor)

        ' Change red
        IF dstR < srcR THEN
            Graphics_MorphPalette = _FALSE
            dstR = dstR + 1
        ELSEIF dstR > srcR THEN
            Graphics_MorphPalette = _FALSE
            dstR = dstR - 1
        END IF

        ' Change green
        IF dstG < srcG THEN
            Graphics_MorphPalette = _FALSE
            dstG = dstG + 1
        ELSEIF dstG > srcG THEN
            Graphics_MorphPalette = _FALSE
            dstG = dstG - 1
        END IF

        ' Change blue
        IF dstB < srcB THEN
            Graphics_MorphPalette = _FALSE
            dstB = dstB + 1
        ELSEIF dstB > srcB THEN
            Graphics_MorphPalette = _FALSE
            dstB = dstB - 1
        END IF

        ' Set the palette index color
        _PALETTECOLOR i, Graphics_MakeBGRA(dstR, dstG, dstB, 255), dstImage
    NEXT i
END FUNCTION


' Rotates an image palette left or right
SUB Graphics_RotatePalette (dstImage AS LONG, isForward AS _BYTE, startIndex AS _UNSIGNED _BYTE, stopIndex AS _UNSIGNED _BYTE)
    IF stopIndex > startIndex THEN
        DIM tempColor AS _UNSIGNED LONG, i AS LONG

        IF isForward THEN
            ' Save the last color
            tempColor = _PALETTECOLOR(stopIndex, dstImage)

            ' Shift places for the remaining colors
            FOR i = stopIndex TO startIndex + 1 STEP -1
                _PALETTECOLOR i, _PALETTECOLOR(i - 1, dstImage), dstImage
            NEXT i

            ' Set first to last
            _PALETTECOLOR startIndex, tempColor, dstImage
        ELSE
            ' Save the first color
            tempColor = _PALETTECOLOR(startIndex, dstImage)

            ' Shift places for the remaining colors
            FOR i = startIndex TO stopIndex - 1
                _PALETTECOLOR i, _PALETTECOLOR(i + 1, dstImage), dstImage
            NEXT i

            ' Set last to first
            _PALETTECOLOR stopIndex, tempColor, dstImage
        END IF
    END IF
END SUB


' Sets the complete palette to a single color
SUB Graphics_ResetPalette (dstImage AS LONG, resetColor AS _UNSIGNED LONG)
    DIM i AS LONG: FOR i = 0 TO 255
        _PALETTECOLOR i, resetColor, dstImage
    NEXT i
END SUB


' Generates a gradient palette
SUB Graphics_SetGradientPalette (dstImage AS LONG, s AS _UNSIGNED _BYTE, e AS _UNSIGNED _BYTE, rs AS _UNSIGNED _BYTE, gs AS _UNSIGNED _BYTE, bs AS _UNSIGNED _BYTE, re AS _UNSIGNED _BYTE, ge AS _UNSIGNED _BYTE, be AS _UNSIGNED _BYTE)
    ' Calculate gradient height
    DIM h AS SINGLE: h = 1! + CSNG(e) - CSNG(s)

    ' Set initial rgb values
    DIM r AS SINGLE: r = rs
    DIM g AS SINGLE: g = gs
    DIM b AS SINGLE: b = bs

    ' Calculate RGB stepping
    DIM rStep AS SINGLE: rStep = (CSNG(re) - CSNG(rs)) / h
    DIM gStep AS SINGLE: gStep = (CSNG(ge) - CSNG(gs)) / h
    DIM bStep AS SINGLE: bStep = (CSNG(be) - CSNG(bs)) / h

    ' Generate palette
    DIM i AS LONG: FOR i = s TO e
        _PALETTECOLOR i, Graphics_MakeBGRA(r, g, b, 255), dstImage

        r = r + rStep
        g = g + gStep
        b = b + bStep
    NEXT i
END SUB


' Palletize src using the palette in dst. The resulting image is stored in dst
' @param LONG dst The destination image. This must be an 8bpp image with the palette already loaded
' @param LONG src The source image. This must be an 8bpp image with its own palette
SUB Graphics_PalettizeImage (dst AS LONG, src AS LONG)
    ' Set the destination image
    DIM oldDst AS LONG: oldDst = _DEST
    _DEST dst

    ' Set the source image
    DIM oldSrc AS LONG: oldSrc = _SOURCE
    _SOURCE src

    ' Calculate image limits just once
    DIM maxX AS LONG: maxX = _WIDTH(src) - 1
    DIM maxY AS LONG: maxY = _HEIGHT(src) - 1

    DIM AS LONG x, y

    ' Remap and write the pixels to img_pal
    IF _PIXELSIZE(src) = 4 THEN
        FOR y = 0 TO maxY
            FOR x = 0 TO maxX
                DIM pc32 AS _UNSIGNED LONG: pc32 = POINT(x, y)
                PSET (x, y), _RGB(_RED32(pc32), _GREEN32(pc32), _BLUE32(pc32), dst)
            NEXT x
        NEXT y
    ELSE
        FOR y = 0 TO maxY
            FOR x = 0 TO maxX
                DIM pc AS _UNSIGNED _BYTE: pc = POINT(x, y)
                PSET (x, y), _RGB(_RED(pc, src), _GREEN(pc, src), _BLUE(pc, src), dst)
            NEXT x
        NEXT y
    END IF

    ' Restore destination and source
    _SOURCE oldSrc
    _DEST oldDst
END SUB


' Loads a GPL color palette into an 8bpp image
' @param STRING gpl_file Filename of GPL palette to load
' @param LONG dst The destination image. This must be an 8bpp image where the palette is loaded
SUB Graphics_LoadGPLPalette (gplFileName AS STRING, dst AS LONG)
    DIM fh AS LONG: fh = FREEFILE
    OPEN gplFileName FOR INPUT AS fh

    ' Read the header
    DIM lin AS STRING: LINE INPUT #fh, lin

    IF lin = "GIMP Palette" THEN
        ' Clear the palette
        DIM i AS LONG: FOR i = 0 TO 255
            _PALETTECOLOR i, &HFF000000~&, dst
        NEXT i

        DIM c AS LONG

        WHILE NOT EOF(fh)
            LINE INPUT #fh, lin
            lin = LTRIM$(lin) ' trim leading spaces

            ' Proceed only if we have something to process
            IF LEN(lin) <> 0 THEN
                DIM char AS _UNSIGNED _BYTE: char = ASC(lin, 1) ' fetch the first character

                ' Skip comments and other junk (i.e. first character is not a digit)
                IF char >= 48 AND char <= 57 THEN
                    ' Parse and read the 3 color components
                    DIM comp AS LONG: comp = 0
                    DIM lastChar AS _UNSIGNED _BYTE: lastChar = 0
                    REDIM clr(0 TO 2) AS _UNSIGNED LONG

                    FOR i = 1 TO LEN(lin)
                        char = ASC(lin, i)

                        IF char >= 48 AND char <= 57 THEN
                            clr(comp) = clr(comp) * 10 + (char - 48)
                        ELSE
                            ' Move to the next component only if the we are fresh out of a successful component read
                            IF lastChar >= 48 AND lastChar <= 57 THEN comp = comp + 1
                        END IF

                        ' Set the color and bail if we have all 3 components
                        IF comp > 2 OR (comp > 1 AND i = LEN(lin)) THEN
                            _PALETTECOLOR c, _RGB32(clr(0), clr(1), clr(2)), dst

                            c = c + 1

                            EXIT FOR
                        END IF

                        lastChar = char
                    NEXT i
                END IF
            END IF
        WEND
    END IF

    CLOSE fh
END SUB


' Fades the current _DEST to the screen to / from black (works on all kinds of screen)
' Note for paletted display the display palette will be modified
' img - image to use. can be the screen or _DEST
' isIn - True or False. True is fade in, False is fade out
' fps& - speed (updates / second)
' stopPercent - %age when to bail out (use for partial fades)
SUB Graphics_FadeScreen (isIn AS _BYTE, maxFPS AS _UNSIGNED INTEGER, stopPercent AS _BYTE)
    DIM AS LONG dspImg, tmpImg, oldDest

    dspImg = _DISPLAY ' Get the image handle of the screen being displayed

    SELECT CASE _PIXELSIZE(dspImg)
        CASE 0, 1 ' Text mode and other index graphics screens. We'll simply fade the image palette in either direction based on isIn
            ' Make a copy of the destination image along with the palette
            tmpImg = _COPYIMAGE(_DEST)

            IF isIn THEN
                ' If we are fading in the just reset the display image to all black
                Graphics_ResetPalette dspImg, BGRA_BLACK
            ELSE
                ' If we are fading out then first copy the image pallete to the display and then reset the image paletter to all black
                _COPYPALETTE tmpImg, dspImg
                Graphics_ResetPalette tmpImg, BGRA_BLACK
            END IF

            oldDest = _DEST ' Save the old destination
            _DEST _DISPLAY ' Set destination to the screen

            ' Stretch and blit the image to the screen just once
            _PUTIMAGE , tmpImg, _DISPLAY

            DO
                ' Change the palette in small increments
                DIM done AS _BYTE: done = Graphics_MorphPalette(dspImg, tmpImg, 0, 255)

                _DISPLAY

                IF maxFPS > 0 THEN _LIMIT maxFPS
            LOOP UNTIL done

            _DEST oldDest ' Restore destination

            _FREEIMAGE tmpImg
        CASE ELSE ' 32bpp BGRA graphics. We'll draw a filled rectangle over the screen with varying aplha values
            ' Make a copy of the destination image
            tmpImg = _COPYIMAGE(_DEST)

            DIM maxX AS LONG: maxX = _WIDTH(tmpImg) - 1
            DIM maxY AS LONG: maxY = _HEIGHT(tmpImg) - 1

            DIM i AS LONG: FOR i = 0 TO 255
                IF stopPercent < (i * 100) \ 255 THEN EXIT FOR ' bail if < 100% we hit the limit

                ' Stretch and blit the image to the screen
                _PUTIMAGE , tmpImg, _DISPLAY

                IF isIn THEN
                    'LINE (0, 0)-(maxX, maxY), _RGBA32(0, 0, 0, 255 - i), BF
                    Graphics_DrawFilledRectangle 0, 0, maxX, maxY, Graphics_MakeBGRA(0, 0, 0, 255 - i)
                ELSE
                    'LINE (0, 0)-(maxX, maxY), _RGBA32(0, 0, 0, i), BF
                    Graphics_DrawFilledRectangle 0, 0, maxX, maxY, Graphics_MakeBGRA(0, 0, 0, i)
                END IF

                _DISPLAY

                IF maxFPS > 0 THEN _LIMIT maxFPS
            NEXT i

            _FREEIMAGE tmpImg
    END SELECT
END SUB


' Loads an image and returns and image handle
' fileName - filename or memory buffer of the image
' is8bpp - image will be loaded as an 8-bit image if this is true (not supported by hardware images)
' isHardware - image will be loaded as a hardware image (is8bpp must not be true for this to work)
' otherOptions - other image loading options like "memory", "adaptive" and the various image scalers
' transparentColor - if this is >= 0 then the color specified by this becomes the transparency color key
FUNCTION Graphics_LoadImage& (fileName AS STRING, is8bpp AS _BYTE, isHardware AS _BYTE, otherOptions AS STRING, transparentColor AS _INTEGER64)
    DIM handle AS LONG

    IF is8bpp THEN
        handle = _LOADIMAGE(fileName, 256, otherOptions)
    ELSE
        handle = _LOADIMAGE(fileName, 32, otherOptions)
    END IF

    IF handle < -1 THEN
        IF transparentColor >= 0 THEN _CLEARCOLOR transparentColor, handle

        IF isHardware THEN
            DIM handleHW AS LONG: handleHW = _COPYIMAGE(handle, 33)
            _FREEIMAGE handle
            handle = handleHW
        END IF
    END IF

    Graphics_LoadImage = handle
END FUNCTION
