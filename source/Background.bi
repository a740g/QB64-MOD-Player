'-----------------------------------------------------------------------------------------------------------------------
' Background visual animation routines (Stars, Snakes, Fireworks, Fire, Plasma, Balls, Matrix)
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Math.bi'
'$INCLUDE:'Vector2f.bi'
'$INCLUDE:'Bounds2f.bi'
'$INCLUDE:'Vector3f.bi'

$UNSTABLE:TYPEFIELDS

' Background constants
CONST BACKGROUND_MODE_NONE& = 0&
CONST BACKGROUND_MODE_STARS& = 1&
CONST BACKGROUND_MODE_SNAKES& = 2&
CONST BACKGROUND_MODE_FIREWORKS& = 3&
CONST BACKGROUND_MODE_FIRE& = 4&
CONST BACKGROUND_MODE_PLASMA& = 5&
CONST BACKGROUND_MODE_BALLS& = 6&
CONST BACKGROUND_MODE_MATRIX& = 7&
CONST BACKGROUND_MODE_FIRST& = BACKGROUND_MODE_STARS
CONST BACKGROUND_MODE_LAST& = BACKGROUND_MODE_MATRIX

CONST __BACKGROUND_STAR_COUNT& = 256& ' default maximum stars
CONST __BACKGROUND_SNAKE_COUNT& = 48& ' default maximum snakes
CONST __BACKGROUND_FIREWORK_ROCKETS& = 6& ' simultaneous firework rockets
CONST __BACKGROUND_FIREWORK_PARTICLES& = 192& ' total firework particle pool (32 per rocket)
CONST __BACKGROUND_BALL_COUNT& = 20& ' bouncing kinetic balls

' Standard 16-color CGA/VGA palette constants for background routines
CONST __BG_COLOR_BLACK% = 0%
CONST __BG_COLOR_BLUE% = 1%
CONST __BG_COLOR_GREEN% = 2%
CONST __BG_COLOR_CYAN% = 3%
CONST __BG_COLOR_RED% = 4%
CONST __BG_COLOR_MAGENTA% = 5%
CONST __BG_COLOR_BROWN% = 6%
CONST __BG_COLOR_WHITE% = 7%
CONST __BG_COLOR_GRAY% = 8%
CONST __BG_COLOR_LIGHT_BLUE% = 9%
CONST __BG_COLOR_LIGHT_GREEN% = 10%
CONST __BG_COLOR_LIGHT_CYAN% = 11%
CONST __BG_COLOR_LIGHT_RED% = 12%
CONST __BG_COLOR_LIGHT_MAGENTA% = 13%
CONST __BG_COLOR_YELLOW% = 14%
CONST __BG_COLOR_BRIGHT_WHITE% = 15%

TYPE __Background_Star
    p AS Vector3f ' position (x, y, z)
    a AS SINGLE ' angle
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE __Background_Starfield
    _DYNAMIC stars(0 TO 0) AS __Background_Star
    count AS LONG
END TYPE

TYPE __Background_Snake
    p AS STRING ' position buffer (x = 1 byte, y = 1 byte)
    position AS Vector2f ' continuous sub-character position
    direction AS Vector2f ' continuous direction unit vector
    turnRate AS SINGLE ' angular velocity (radians per frame)
    speed AS SINGLE ' speed in characters per frame
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE __Background_Snakes
    _DYNAMIC snakes(0 TO 0) AS __Background_Snake
    _DYNAMIC grid(0 TO 0, 0 TO 0) AS _BYTE
    gridW AS LONG
    gridH AS LONG
    count AS LONG
END TYPE

TYPE __Background_Rocket
    position AS Vector2f
    velocity AS Vector2f
    targetY AS SINGLE
    state AS LONG ' 0 = idle/countdown, 1 = ascending, 2 = detonated
    timer AS LONG
    c AS _UNSIGNED LONG
END TYPE

TYPE __Background_FireworkParticle
    position AS Vector2f
    velocity AS Vector2f
    life AS SINGLE
    maxLife AS SINGLE
    c AS _UNSIGNED LONG
    active AS _BYTE
END TYPE

TYPE __Background_Fireworks
    rockets(1 TO __BACKGROUND_FIREWORK_ROCKETS) AS __Background_Rocket
    particles(1 TO __BACKGROUND_FIREWORK_PARTICLES) AS __Background_FireworkParticle
    count AS LONG
END TYPE

TYPE __Background_Fire
    _DYNAMIC grid(0 TO 0, 0 TO 0) AS _BYTE
    gridW AS LONG
    gridH AS LONG
END TYPE

TYPE __Background_Plasma
    _DYNAMIC sinLUT(0 TO 0) AS LONG
    tick1 AS LONG
    tick2 AS LONG
    tick3 AS LONG
    lutReady AS _BYTE
END TYPE

TYPE __Background_Ball
    position AS Vector2f
    velocity AS Vector2f
    radius AS SINGLE
    c AS _UNSIGNED LONG
    trailX(1 TO 4) AS LONG
    trailY(1 TO 4) AS LONG
END TYPE

TYPE __Background_Balls
    balls(1 TO __BACKGROUND_BALL_COUNT) AS __Background_Ball
    count AS LONG
    quakeTimer AS LONG
END TYPE

TYPE __Background_MatrixDrop
    y AS SINGLE
    speed AS SINGLE
    length AS LONG
    active AS _BYTE
    timer AS LONG
    charSeed AS LONG
END TYPE

TYPE __Background_Matrix
    _DYNAMIC drops(1 TO 1) AS __Background_MatrixDrop
END TYPE

TYPE Background
    starfield AS __Background_Starfield
    snakes AS __Background_Snakes
    fireworks AS __Background_Fireworks
    fire AS __Background_Fire
    plasma AS __Background_Plasma
    balls AS __Background_Balls
    matrix AS __Background_Matrix
    mode AS LONG
    viewport AS Bounds2f
    size AS Vector2f
END TYPE

''' @brief Initializes star positions and colors for background starfield effect.
''' @param ctx Background context to initialize.
''' @param starCount Number of stars to allocate (defaults to BACKGROUND_STAR_COUNT if <= 0).
SUB __Background_InitializeStars (ctx AS Background)
    CONST Z_DIVIDER = 4096!

    DIM nStars AS LONG: nStars = __BACKGROUND_STAR_COUNT

    ctx.starfield.count = nStars
    REDIM ctx.starfield.stars(1 TO nStars) AS __BACKGROUND_STAR

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM centerX AS LONG: centerX = (minX + maxX) \ 2
    DIM centerY AS LONG: centerY = (minY + maxY) \ 2
    DIM maxDist AS SINGLE: maxDist = ctx.size.x * 0.5!

    DIM i AS LONG
    FOR i = 1 TO nStars
        DIM ang AS SINGLE: ang = RND * _PI(2!)
        DIM dist AS SINGLE: dist = 2! + RND * maxDist
        ctx.starfield.stars(i).p.x = CSNG(centerX) + COS(ang) * dist
        ctx.starfield.stars(i).p.y = CSNG(centerY) + SIN(ang) * dist * 0.6!
        ctx.starfield.stars(i).p.z = Z_DIVIDER + RND * 80!
        ctx.starfield.stars(i).a = ang
        ctx.starfield.stars(i).c = Math_GetRandomBetween(9, 15)
    NEXT i
END SUB

''' @brief Updates starfield positions and renders stars on screen with 3D depth shading.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawStars (ctx AS Background)
    CONST Z_DIVIDER = 4096!
    CONST STAR_SPEED! = 1.2!

    IF ctx.starfield.count <= 0 THEN EXIT SUB

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM centerX AS LONG: centerX = (minX + maxX) \ 2
    DIM centerY AS LONG: centerY = (minY + maxY) \ 2

    DIM i AS LONG
    FOR i = 1 TO ctx.starfield.count
        IF ctx.starfield.stars(i).p.x < CSNG(minX) _ORELSE ctx.starfield.stars(i).p.x > CSNG(maxX) _ORELSE ctx.starfield.stars(i).p.y < CSNG(minY) _ORELSE ctx.starfield.stars(i).p.y > CSNG(maxY) _ORELSE ctx.starfield.stars(i).p.z > 4220! THEN
            DIM ang AS SINGLE: ang = RND * _PI(2!)
            DIM dist AS SINGLE: dist = 2! + RND * 18!
            ctx.starfield.stars(i).p.x = CSNG(centerX) + COS(ang) * dist
            ctx.starfield.stars(i).p.y = CSNG(centerY) + SIN(ang) * dist * 0.6!
            ctx.starfield.stars(i).p.z = Z_DIVIDER
            ctx.starfield.stars(i).a = ang
            ctx.starfield.stars(i).c = Math_GetRandomBetween(9, 15)
        END IF

        DIM sZ AS SINGLE: sZ = ctx.starfield.stars(i).p.z
        DIM sChar AS STRING
        DIM sCol AS _UNSIGNED LONG

        IF sZ < 4115! THEN
            sCol = __BG_COLOR_GRAY: sChar = "."
        ELSEIF sZ < 4140! THEN
            sCol = __BG_COLOR_WHITE: sChar = CHR$(249)
        ELSEIF sZ < 4168! THEN
            sCol = ctx.starfield.stars(i).c: sChar = "+"
        ELSEIF sZ < 4195! THEN
            sCol = __BG_COLOR_BRIGHT_WHITE: sChar = "x"
        ELSE
            sCol = __BG_COLOR_BRIGHT_WHITE: sChar = "*"
        END IF

        DIM px AS LONG: px = CLNG(ctx.starfield.stars(i).p.x)
        DIM py AS LONG: py = CLNG(ctx.starfield.stars(i).p.y)

        IF px >= minX _ANDALSO px <= maxX _ANDALSO py >= minY _ANDALSO py <= maxY THEN
            COLOR sCol, __BG_COLOR_BLACK
            _PRINTSTRING (px, py), sChar
        END IF

        ctx.starfield.stars(i).p.z = ctx.starfield.stars(i).p.z + STAR_SPEED
        ctx.starfield.stars(i).a = ctx.starfield.stars(i).a + 0.008!
        DIM zd AS SINGLE: zd = ctx.starfield.stars(i).p.z / Z_DIVIDER
        ctx.starfield.stars(i).p.x = ((ctx.starfield.stars(i).p.x - CSNG(centerX)) * zd) + CSNG(centerX) + COS(ctx.starfield.stars(i).a * 0.5!) * 0.4!
        ctx.starfield.stars(i).p.y = ((ctx.starfield.stars(i).p.y - CSNG(centerY)) * zd) + CSNG(centerY) + SIN(ctx.starfield.stars(i).a * 1.5!) * 0.4!
    NEXT i
END SUB

''' @brief Initializes bouncing snake positions and colors with collision-free placement.
''' @param ctx Background context to initialize.
''' @param snakeCount Number of snakes to allocate (defaults to BACKGROUND_SNAKE_COUNT if <= 0).
SUB __Background_InitializeSnakes (ctx AS Background)
    CONST SNAKE_SIZE_MIN = 6
    CONST SNAKE_SIZE_MAX = 28

    DIM nSnakes AS LONG: nSnakes = __BACKGROUND_SNAKE_COUNT

    ctx.snakes.count = nSnakes
    REDIM ctx.snakes.snakes(1 TO nSnakes) AS __BACKGROUND_SNAKE

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)

    ctx.snakes.gridW = maxX
    ctx.snakes.gridH = maxY
    REDIM ctx.snakes.grid(1 TO maxX, 1 TO maxY) AS _BYTE

    REDIM spawnGrid(1 TO maxX, 1 TO maxY) AS _BYTE

    DIM i AS LONG
    FOR i = 1 TO nSnakes
        ctx.snakes.snakes(i).p = SPACE$(Math_GetRandomBetween(SNAKE_SIZE_MIN, SNAKE_SIZE_MAX) * 2)
        ctx.snakes.snakes(i).speed = 0.22! + RND * 0.38!
        ctx.snakes.snakes(i).c = Math_GetRandomBetween(9, 14)
        DIM angle AS SINGLE: angle = RND * _PI(2!)
        Vector2f_FromAngle angle, 1!, ctx.snakes.snakes(i).direction
        ctx.snakes.snakes(i).turnRate = 0!

        DIM x AS LONG, y AS LONG, tries AS LONG
        DO
            x = Math_GetRandomBetween(minX + 2, maxX - 2)
            y = Math_GetRandomBetween(minY + 2, maxY - 2)
            tries = tries + 1
        LOOP WHILE spawnGrid(x, y) <> 0 AND tries < 500
        spawnGrid(x, y) = 1

        Vector2f_Initialize CSNG(x), CSNG(y), ctx.snakes.snakes(i).position

        DIM size AS LONG: size = LEN(ctx.snakes.snakes(i).p)
        DIM j AS LONG
        FOR j = 1 TO size STEP 2
            ASC(ctx.snakes.snakes(i).p, j) = x
            ASC(ctx.snakes.snakes(i).p, j + 1) = y
        NEXT j
    NEXT i
END SUB

''' @brief Updates snake segments with collision detection/avoidance and renders bouncing snakes on screen.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawSnakes (ctx AS Background)
    CONST SNAKE_HEAD = CHR$(2) ' Smiley head glyph
    CONST SNAKE_BODY = CHR$(254) ' Block body glyph

    IF ctx.snakes.count <= 0 THEN EXIT SUB

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)

    DIM mema AS _MEM: mema = _MEM(ctx.snakes.grid())
    _MEMFILL mema, mema.OFFSET, mema.SIZE, 0%% AS _BYTE
    _MEMFREE mema

    DIM i AS LONG
    FOR i = 1 TO ctx.snakes.count
        DIM pLen AS LONG: pLen = LEN(ctx.snakes.snakes(i).p)
        DIM j AS LONG
        FOR j = 1 TO pLen STEP 2
            DIM sx AS LONG: sx = ASC(ctx.snakes.snakes(i).p, j)
            DIM sy AS LONG: sy = ASC(ctx.snakes.snakes(i).p, j + 1)
            IF sx >= minX _ANDALSO sx <= maxX _ANDALSO sy >= minY _ANDALSO sy <= maxY THEN
                ctx.snakes.grid(sx, sy) = i
            END IF
        NEXT j
    NEXT i

    ' Proximity deflection between heads
    FOR i = 1 TO ctx.snakes.count - 1
        FOR j = i + 1 TO ctx.snakes.count
            DIM dSq AS SINGLE
            dSq = Vector2f_DistanceSquared(ctx.snakes.snakes(i).position, ctx.snakes.snakes(j).position)
            IF dSq < 4.0! THEN
                DIM rep AS Vector2f
                Vector2f_Subtract ctx.snakes.snakes(i).position, ctx.snakes.snakes(j).position, rep
                IF Vector2f_IsNull(rep) THEN Vector2f_Set (RND - 0.5!), (RND - 0.5!), rep
                Vector2f_Normalize rep, rep
                ctx.snakes.snakes(i).direction = rep
                Vector2f_Negate rep, ctx.snakes.snakes(j).direction
                ctx.snakes.snakes(i).turnRate = (RND - 0.5!) * 0.2!
                ctx.snakes.snakes(j).turnRate = (RND - 0.5!) * 0.2!
            END IF
        NEXT j
    NEXT i

    ' Steering, collision avoidance, and movement
    FOR i = 1 TO ctx.snakes.count
        DIM lookDist AS SINGLE: lookDist = 2.0!
        DIM aheadX AS SINGLE: aheadX = ctx.snakes.snakes(i).position.x + ctx.snakes.snakes(i).direction.x * lookDist
        DIM aheadY AS SINGLE: aheadY = ctx.snakes.snakes(i).position.y + ctx.snakes.snakes(i).direction.y * lookDist
        DIM ax AS LONG: ax = _CLAMP(CINT(aheadX), minX, maxX)
        DIM ay AS LONG: ay = _CLAMP(CINT(aheadY), minY, maxY)

        DIM aheadBlocked AS _BYTE
        aheadBlocked = (aheadX < CSNG(minX) + 1.5! _ORELSE aheadX > CSNG(maxX) - 1.5! _ORELSE aheadY < CSNG(minY) + 1.5! _ORELSE aheadY > CSNG(maxY) - 1.5!)
        IF NOT aheadBlocked THEN
            IF ctx.snakes.grid(ax, ay) <> 0 _ANDALSO ctx.snakes.grid(ax, ay) <> i THEN aheadBlocked = _TRUE
        END IF

        IF aheadBlocked THEN
            DIM leftDir AS Vector2f, rightDir AS Vector2f
            Vector2f_Rotate ctx.snakes.snakes(i).direction, 1.047!, leftDir
            Vector2f_Rotate ctx.snakes.snakes(i).direction, -1.047!, rightDir

            DIM lx AS LONG: lx = _CLAMP(CINT(ctx.snakes.snakes(i).position.x + leftDir.x * lookDist), minX, maxX)
            DIM ly AS LONG: ly = _CLAMP(CINT(ctx.snakes.snakes(i).position.y + leftDir.y * lookDist), minY, maxY)
            DIM leftBlocked AS _BYTE
            leftBlocked = (lx <= minX + 1 _ORELSE lx >= maxX - 1 _ORELSE ly <= minY + 1 _ORELSE ly >= maxY - 1)
            IF NOT leftBlocked THEN
                IF ctx.snakes.grid(lx, ly) <> 0 _ANDALSO ctx.snakes.grid(lx, ly) <> i THEN leftBlocked = _TRUE
            END IF

            DIM rx AS LONG: rx = _CLAMP(CINT(ctx.snakes.snakes(i).position.x + rightDir.x * lookDist), minX, maxX)
            DIM ry AS LONG: ry = _CLAMP(CINT(ctx.snakes.snakes(i).position.y + rightDir.y * lookDist), minY, maxY)
            DIM rightBlocked AS _BYTE
            rightBlocked = (rx <= minX + 1 _ORELSE rx >= maxX - 1 _ORELSE ry <= minY + 1 _ORELSE ry >= maxY - 1)
            IF NOT rightBlocked THEN
                IF ctx.snakes.grid(rx, ry) <> 0 _ANDALSO ctx.snakes.grid(rx, ry) <> i THEN rightBlocked = _TRUE
            END IF

            IF NOT leftBlocked _ANDALSO rightBlocked THEN
                ctx.snakes.snakes(i).turnRate = 0.25!
            ELSEIF NOT rightBlocked _ANDALSO leftBlocked THEN
                ctx.snakes.snakes(i).turnRate = -0.25!
            ELSEIF NOT leftBlocked _ANDALSO NOT rightBlocked THEN
                IF ctx.snakes.snakes(i).turnRate >= 0! THEN ctx.snakes.snakes(i).turnRate = 0.25! ELSE ctx.snakes.snakes(i).turnRate = -0.25!
            ELSE
                Vector2f_Rotate ctx.snakes.snakes(i).direction, _PI * 0.75!, ctx.snakes.snakes(i).direction
                ctx.snakes.snakes(i).turnRate = (RND - 0.5!) * 0.2!
            END IF
        ELSE
            DIM r AS SINGLE: r = RND
            IF r < 0.04! THEN
                ctx.snakes.snakes(i).turnRate = (RND - 0.5!) * 0.12!
            ELSEIF r < 0.08! THEN
                ctx.snakes.snakes(i).turnRate = 0!
            END IF
        END IF

        IF ctx.snakes.snakes(i).turnRate <> 0! THEN
            Vector2f_Rotate ctx.snakes.snakes(i).direction, ctx.snakes.snakes(i).turnRate, ctx.snakes.snakes(i).direction
            Vector2f_Normalize ctx.snakes.snakes(i).direction, ctx.snakes.snakes(i).direction
        END IF

        DIM nextX AS SINGLE: nextX = ctx.snakes.snakes(i).position.x + ctx.snakes.snakes(i).direction.x * ctx.snakes.snakes(i).speed
        DIM nextY AS SINGLE: nextY = ctx.snakes.snakes(i).position.y + ctx.snakes.snakes(i).direction.y * ctx.snakes.snakes(i).speed

        IF nextX < CSNG(minX) THEN
            Vector2f_FlipHorizontal ctx.snakes.snakes(i).direction, ctx.snakes.snakes(i).direction
            nextX = CSNG(minX)
            ctx.snakes.snakes(i).turnRate = -ctx.snakes.snakes(i).turnRate
        ELSEIF nextX > CSNG(maxX) THEN
            Vector2f_FlipHorizontal ctx.snakes.snakes(i).direction, ctx.snakes.snakes(i).direction
            nextX = CSNG(maxX)
            ctx.snakes.snakes(i).turnRate = -ctx.snakes.snakes(i).turnRate
        END IF

        IF nextY < CSNG(minY) THEN
            Vector2f_FlipVertical ctx.snakes.snakes(i).direction, ctx.snakes.snakes(i).direction
            nextY = CSNG(minY)
            ctx.snakes.snakes(i).turnRate = -ctx.snakes.snakes(i).turnRate
        ELSEIF nextY > CSNG(maxY) THEN
            Vector2f_FlipVertical ctx.snakes.snakes(i).direction, ctx.snakes.snakes(i).direction
            nextY = CSNG(maxY)
            ctx.snakes.snakes(i).turnRate = -ctx.snakes.snakes(i).turnRate
        END IF

        DIM targetCellX AS LONG: targetCellX = _CLAMP(CINT(nextX), minX, maxX)
        DIM targetCellY AS LONG: targetCellY = _CLAMP(CINT(nextY), minY, maxY)

        IF ctx.snakes.grid(targetCellX, targetCellY) <> 0 _ANDALSO ctx.snakes.grid(targetCellX, targetCellY) <> i THEN
            DIM foundEscape AS _BYTE: foundEscape = _FALSE
            DIM testIdx AS LONG
            FOR testIdx = 1 TO 5
                DIM testAngle AS SINGLE
                SELECT CASE testIdx
                    CASE 1: testAngle = 1.570796!
                    CASE 2: testAngle = -1.570796!
                    CASE 3: testAngle = 2.356194!
                    CASE 4: testAngle = -2.356194!
                    CASE 5: testAngle = 3.141593!
                END SELECT

                DIM candDir AS Vector2f
                Vector2f_Rotate ctx.snakes.snakes(i).direction, testAngle, candDir
                Vector2f_Normalize candDir, candDir

                DIM candX AS SINGLE: candX = ctx.snakes.snakes(i).position.x + candDir.x * ctx.snakes.snakes(i).speed
                DIM candY AS SINGLE: candY = ctx.snakes.snakes(i).position.y + candDir.y * ctx.snakes.snakes(i).speed
                DIM candCellX AS LONG: candCellX = _CLAMP(CINT(candX), minX, maxX)
                DIM candCellY AS LONG: candCellY = _CLAMP(CINT(candY), minY, maxY)

                IF candX >= CSNG(minX) _ANDALSO candX <= CSNG(maxX) _ANDALSO candY >= CSNG(minY) _ANDALSO candY <= CSNG(maxY) THEN
                    IF ctx.snakes.grid(candCellX, candCellY) = 0 _ORELSE ctx.snakes.grid(candCellX, candCellY) = i THEN
                        ctx.snakes.snakes(i).direction = candDir
                        ctx.snakes.snakes(i).turnRate = testAngle * 0.1!
                        nextX = candX: nextY = candY
                        targetCellX = candCellX: targetCellY = candCellY
                        foundEscape = _TRUE
                        EXIT FOR
                    END IF
                END IF
            NEXT testIdx

            IF NOT foundEscape THEN
                nextX = ctx.snakes.snakes(i).position.x
                nextY = ctx.snakes.snakes(i).position.y
                targetCellX = ASC(ctx.snakes.snakes(i).p, 1)
                targetCellY = ASC(ctx.snakes.snakes(i).p, 2)
            END IF
        END IF

        ctx.snakes.snakes(i).position.x = nextX
        ctx.snakes.snakes(i).position.y = nextY

        IF targetCellX <> ASC(ctx.snakes.snakes(i).p, 1) _ORELSE targetCellY <> ASC(ctx.snakes.snakes(i).p, 2) THEN
            DIM sLen AS LONG: sLen = LEN(ctx.snakes.snakes(i).p)
            DIM oldTailX AS LONG: oldTailX = ASC(ctx.snakes.snakes(i).p, sLen - 1)
            DIM oldTailY AS LONG: oldTailY = ASC(ctx.snakes.snakes(i).p, sLen)

            DIM k AS LONG: k = sLen - 2
            WHILE k > 0
                ASC(ctx.snakes.snakes(i).p, k + 2) = ASC(ctx.snakes.snakes(i).p, k)
                k = k - 1
            WEND
            ASC(ctx.snakes.snakes(i).p, 1) = targetCellX
            ASC(ctx.snakes.snakes(i).p, 2) = targetCellY

            DIM tailStillOccupied AS _BYTE: tailStillOccupied = _FALSE
            DIM chk AS LONG
            FOR chk = 1 TO sLen STEP 2
                IF ASC(ctx.snakes.snakes(i).p, chk) = oldTailX AND ASC(ctx.snakes.snakes(i).p, chk + 1) = oldTailY THEN
                    tailStillOccupied = _TRUE
                    EXIT FOR
                END IF
            NEXT chk

            IF NOT tailStillOccupied THEN
                IF oldTailX >= minX _ANDALSO oldTailX <= maxX _ANDALSO oldTailY >= minY _ANDALSO oldTailY <= maxY THEN
                    IF ctx.snakes.grid(oldTailX, oldTailY) = i THEN ctx.snakes.grid(oldTailX, oldTailY) = 0
                END IF
            END IF
            ctx.snakes.grid(targetCellX, targetCellY) = i
        END IF

        ' Render glowing body segments fading toward tail
        DIM sLenDraw AS LONG: sLenDraw = LEN(ctx.snakes.snakes(i).p)
        DIM segIdx AS LONG: segIdx = 0
        j = sLenDraw - 2
        WHILE j > 2
            DIM py AS LONG: py = ASC(ctx.snakes.snakes(i).p, j)
            j = j - 1
            DIM px AS LONG: px = ASC(ctx.snakes.snakes(i).p, j)
            j = j - 1

            DIM bodyCol AS _UNSIGNED LONG
            IF j <= 8 THEN
                bodyCol = ctx.snakes.snakes(i).c
            ELSEIF j <= 16 THEN
                bodyCol = _MAX(1, ctx.snakes.snakes(i).c - 8)
            ELSE
                bodyCol = __BG_COLOR_GRAY
            END IF

            IF px >= minX _ANDALSO px <= maxX _ANDALSO py >= minY _ANDALSO py <= maxY THEN
                COLOR bodyCol, __BG_COLOR_BLACK
                _PRINTSTRING (px, py), SNAKE_BODY
            END IF
        WEND

        ' Render bright glowing head
        DIM hx AS LONG: hx = ASC(ctx.snakes.snakes(i).p, 1)
        DIM hy AS LONG: hy = ASC(ctx.snakes.snakes(i).p, 2)
        IF hx >= minX _ANDALSO hx <= maxX _ANDALSO hy >= minY _ANDALSO hy <= maxY THEN
            COLOR __BG_COLOR_BRIGHT_WHITE, __BG_COLOR_BLACK
            _PRINTSTRING (hx, hy), SNAKE_HEAD
        END IF
    NEXT i
END SUB

''' @brief Initializes firework rockets and particle pool.
''' @param ctx Background context to initialize.
SUB __Background_InitializeFireworks (ctx AS Background)
    ctx.fireworks.count = __BACKGROUND_FIREWORK_ROCKETS

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)

    DIM r AS LONG
    FOR r = 1 TO __BACKGROUND_FIREWORK_ROCKETS
        ctx.fireworks.rockets(r).state = 0
        ctx.fireworks.rockets(r).timer = Math_GetRandomBetween(5, 50 * r)
        ctx.fireworks.rockets(r).position.x = CSNG(Math_GetRandomBetween(minX + 5, maxX - 5))
        ctx.fireworks.rockets(r).position.y = CSNG(maxY)
        ctx.fireworks.rockets(r).c = Math_GetRandomBetween(9, 14)
    NEXT r

    DIM p AS LONG
    FOR p = 1 TO __BACKGROUND_FIREWORK_PARTICLES
        ctx.fireworks.particles(p).active = _FALSE
    NEXT p
END SUB

''' @brief Updates ascending rockets and exploding spark particles.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawFireworks (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM H AS LONG: H = CLNG(ctx.size.y)

    DIM r AS LONG
    FOR r = 1 TO __BACKGROUND_FIREWORK_ROCKETS
        SELECT CASE ctx.fireworks.rockets(r).state
            CASE 0 ' Countdown to launch
                ctx.fireworks.rockets(r).timer = ctx.fireworks.rockets(r).timer - 1
                IF ctx.fireworks.rockets(r).timer <= 0 THEN
                    ctx.fireworks.rockets(r).state = 1
                    ctx.fireworks.rockets(r).position.x = CSNG(Math_GetRandomBetween(minX + 5, maxX - 5))
                    ctx.fireworks.rockets(r).position.y = CSNG(maxY - 1)
                    ctx.fireworks.rockets(r).velocity.x = (RND - 0.5!) * 0.4!
                    ctx.fireworks.rockets(r).velocity.y = -1.1! - RND * 0.7!
                    ctx.fireworks.rockets(r).targetY = CSNG(Math_GetRandomBetween(minY + H \ 6, minY + (H * 3) \ 4))
                    ctx.fireworks.rockets(r).c = Math_GetRandomBetween(9, 14)
                END IF

            CASE 1 ' Ascending rocket
                ctx.fireworks.rockets(r).position.x = ctx.fireworks.rockets(r).position.x + ctx.fireworks.rockets(r).velocity.x
                ctx.fireworks.rockets(r).position.y = ctx.fireworks.rockets(r).position.y + ctx.fireworks.rockets(r).velocity.y
                ctx.fireworks.rockets(r).velocity.y = ctx.fireworks.rockets(r).velocity.y + 0.012!

                DIM rx AS LONG: rx = CLNG(ctx.fireworks.rockets(r).position.x)
                DIM ry AS LONG: ry = CLNG(ctx.fireworks.rockets(r).position.y)

                IF rx >= minX _ANDALSO rx <= maxX _ANDALSO ry >= minY _ANDALSO ry <= maxY THEN
                    COLOR __BG_COLOR_BRIGHT_WHITE, __BG_COLOR_BLACK
                    _PRINTSTRING (rx, ry), "^"
                    IF ry < maxY THEN
                        COLOR ctx.fireworks.rockets(r).c, __BG_COLOR_BLACK
                        _PRINTSTRING (rx, ry + 1), "."
                    END IF
                END IF

                IF ctx.fireworks.rockets(r).position.y <= ctx.fireworks.rockets(r).targetY _ORELSE ctx.fireworks.rockets(r).velocity.y >= -0.05! THEN
                    ctx.fireworks.rockets(r).state = 2
                    DIM pStart AS LONG: pStart = (r - 1) * 32 + 1
                    DIM pEnd AS LONG: pEnd = r * 32
                    DIM p AS LONG
                    FOR p = pStart TO pEnd
                        ctx.fireworks.particles(p).active = _TRUE
                        ctx.fireworks.particles(p).position.x = ctx.fireworks.rockets(r).position.x
                        ctx.fireworks.particles(p).position.y = ctx.fireworks.rockets(r).position.y
                        DIM ang AS SINGLE: ang = RND * _PI(2!)
                        DIM spd AS SINGLE: spd = 0.35! + RND * 1.35!
                        ctx.fireworks.particles(p).velocity.x = COS(ang) * spd * 1.8!
                        ctx.fireworks.particles(p).velocity.y = SIN(ang) * spd * 0.9!
                        ctx.fireworks.particles(p).maxLife = 24! + RND * 26!
                        ctx.fireworks.particles(p).life = ctx.fireworks.particles(p).maxLife
                        ctx.fireworks.particles(p).c = ctx.fireworks.rockets(r).c
                    NEXT p
                END IF

            CASE 2 ' Detonated
                DIM allDone AS _BYTE: allDone = _TRUE
                pStart = (r - 1) * 32 + 1
                pEnd = r * 32
                FOR p = pStart TO pEnd
                    IF ctx.fireworks.particles(p).active THEN
                        allDone = _FALSE
                        EXIT FOR
                    END IF
                NEXT p
                IF allDone THEN
                    ctx.fireworks.rockets(r).state = 0
                    ctx.fireworks.rockets(r).timer = Math_GetRandomBetween(15, 75)
                END IF
        END SELECT
    NEXT r

    FOR p = 1 TO __BACKGROUND_FIREWORK_PARTICLES
        IF ctx.fireworks.particles(p).active THEN
            ctx.fireworks.particles(p).life = ctx.fireworks.particles(p).life - 1!
            IF ctx.fireworks.particles(p).life <= 0! THEN
                ctx.fireworks.particles(p).active = _FALSE
            ELSE
                ctx.fireworks.particles(p).position.x = ctx.fireworks.particles(p).position.x + ctx.fireworks.particles(p).velocity.x
                ctx.fireworks.particles(p).position.y = ctx.fireworks.particles(p).position.y + ctx.fireworks.particles(p).velocity.y
                ctx.fireworks.particles(p).velocity.y = ctx.fireworks.particles(p).velocity.y + 0.032!
                ctx.fireworks.particles(p).velocity.x = ctx.fireworks.particles(p).velocity.x * 0.98!
                ctx.fireworks.particles(p).velocity.y = ctx.fireworks.particles(p).velocity.y * 0.98!

                DIM px AS LONG: px = CLNG(ctx.fireworks.particles(p).position.x)
                DIM py AS LONG: py = CLNG(ctx.fireworks.particles(p).position.y)

                IF px >= minX _ANDALSO px <= maxX _ANDALSO py >= minY _ANDALSO py <= maxY THEN
                    DIM ratio AS SINGLE: ratio = ctx.fireworks.particles(p).life / ctx.fireworks.particles(p).maxLife
                    DIM pChar AS STRING
                    DIM pCol AS _UNSIGNED LONG
                    IF ratio > 0.72! THEN
                        pCol = __BG_COLOR_BRIGHT_WHITE: pChar = "*"
                    ELSEIF ratio > 0.40! THEN
                        pCol = ctx.fireworks.particles(p).c: pChar = "+"
                    ELSEIF ratio > 0.18! THEN
                        pCol = _MAX(1, ctx.fireworks.particles(p).c - 8): pChar = "x"
                    ELSE
                        pCol = __BG_COLOR_GRAY: pChar = CHR$(249)
                    END IF
                    COLOR pCol, __BG_COLOR_BLACK
                    _PRINTSTRING (px, py), pChar
                ELSE
                    ctx.fireworks.particles(p).active = _FALSE
                END IF
            END IF
        END IF
    NEXT p
END SUB

''' @brief Initializes cellular fire grid buffer.
''' @param ctx Background context to initialize.
SUB __Background_InitializeFire (ctx AS Background)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)

    ctx.fire.gridW = maxX: ctx.fire.gridH = maxY
    REDIM ctx.fire.grid(1 TO maxX, 1 TO maxY) AS _BYTE
END SUB

''' @brief Updates retro cellular automata fire simulation and renders flames.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawFire (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM H AS LONG: H = CLNG(ctx.size.y)

    ' Seed bottom line (row maxY) with hot flame energy
    DIM x AS LONG
    FOR x = minX TO maxX
        IF RND < 0.68! THEN
            ctx.fire.grid(x, maxY) = Math_GetRandomBetween(13, 17)
        ELSE
            ctx.fire.grid(x, maxY) = 0
        END IF
    NEXT x

    ' Propagate heat upward with decay and wind
    DIM topFireY AS LONG: topFireY = minY + (H * 3) \ 10
    DIM y AS LONG
    FOR y = topFireY TO maxY - 1
        FOR x = minX TO maxX
            DIM decay AS LONG: decay = Math_GetRandomBetween(0, 2)
            DIM wind AS LONG: wind = Math_GetRandomBetween(-1, 1)
            DIM srcX AS LONG: srcX = _CLAMP(x + wind, minX, maxX)
            DIM heat AS LONG: heat = CLNG(ctx.fire.grid(srcX, y + 1)) - decay
            IF heat < 0 THEN heat = 0
            ctx.fire.grid(x, y) = heat
        NEXT x
    NEXT y

    ' Render flame rows with horizontal run-length batching
    DIM startRenderY AS LONG: startRenderY = topFireY + 2
    FOR y = startRenderY TO maxY
        DIM runStart AS LONG: runStart = 0
        DIM lastCol AS LONG: lastCol = -1
        DIM runStr AS STRING: runStr = ""

        FOR x = minX TO maxX
            DIM hVal AS LONG: hVal = ctx.fire.grid(x, y)
            DIM c AS LONG: c = -1
            DIM ch AS STRING: ch = " "

            SELECT CASE hVal
                CASE IS <= 0
                    c = -1: ch = " "
                CASE 1 TO 2
                    c = __BG_COLOR_GRAY: ch = "."
                CASE 3 TO 4
                    c = __BG_COLOR_BROWN: ch = "."
                CASE 5 TO 6
                    c = __BG_COLOR_RED: ch = CHR$(176)
                CASE 7 TO 8
                    c = __BG_COLOR_LIGHT_RED: ch = CHR$(176)
                CASE 9 TO 10
                    c = __BG_COLOR_LIGHT_RED: ch = CHR$(177)
                CASE 11 TO 12
                    c = __BG_COLOR_YELLOW: ch = CHR$(177)
                CASE 13 TO 14
                    c = __BG_COLOR_YELLOW: ch = CHR$(178)
                CASE ELSE
                    c = __BG_COLOR_BRIGHT_WHITE: ch = CHR$(219)
            END SELECT

            IF c <> lastCol THEN
                IF runStart > 0 _ANDALSO lastCol >= 0 THEN
                    COLOR lastCol, __BG_COLOR_BLACK
                    _PRINTSTRING (runStart, y), runStr
                END IF
                runStart = x
                lastCol = c
                runStr = ch
            ELSE
                runStr = runStr + ch
            END IF
        NEXT x

        IF runStart > 0 _ANDALSO lastCol >= 0 THEN
            COLOR lastCol, __BG_COLOR_BLACK
            _PRINTSTRING (runStart, y), runStr
        END IF
    NEXT y
END SUB

''' @brief Initializes 512-entry sine LUT for demoscene plasma.
''' @param ctx Background context to initialize.
SUB __Background_InitializePlasma (ctx AS Background)
    REDIM ctx.plasma.sinLUT(0 TO 511) AS LONG
    DIM i AS LONG
    FOR i = 0 TO 511
        ctx.plasma.sinLUT(i) = CLNG((SIN(CSNG(i) * 6.2831853! / 512!) + 1!) * 32!)
    NEXT i
    ctx.plasma.tick1 = 0
    ctx.plasma.tick2 = 0
    ctx.plasma.tick3 = 0
    ctx.plasma.lutReady = _TRUE
END SUB

''' @brief Updates and renders multi-frequency demoscene plasma interference waves.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawPlasma (ctx AS Background)
    IF NOT ctx.plasma.lutReady THEN __Background_InitializePlasma ctx

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)

    ctx.plasma.tick1 = (ctx.plasma.tick1 + 2) AND 511
    ctx.plasma.tick2 = (ctx.plasma.tick2 + 3) AND 511
    ctx.plasma.tick3 = (ctx.plasma.tick3 + 1) AND 511

    DIM t1 AS LONG: t1 = ctx.plasma.tick1
    DIM t2 AS LONG: t2 = ctx.plasma.tick2
    DIM t3 AS LONG: t3 = ctx.plasma.tick3

    DIM y AS LONG, x AS LONG
    FOR y = minY TO maxY
        DIM rowTerm AS LONG: rowTerm = ctx.plasma.sinLUT((y * 5 + t2) AND 511)
        DIM runStart AS LONG: runStart = 0
        DIM lastCol AS LONG: lastCol = -1
        DIM runStr AS STRING: runStr = ""

        FOR x = minX TO maxX
            DIM pVal AS LONG
            pVal = (ctx.plasma.sinLUT((x * 4 + t1) AND 511) + rowTerm + ctx.plasma.sinLUT((x * 2 + y * 3 + t3) AND 511)) \ 8

            DIM c AS LONG
            DIM ch AS STRING
            SELECT CASE pVal AND 15
                CASE 0 TO 1
                    c = __BG_COLOR_BLUE: ch = "."
                CASE 2 TO 3
                    c = __BG_COLOR_LIGHT_BLUE: ch = CHR$(176)
                CASE 4 TO 5
                    c = __BG_COLOR_CYAN: ch = CHR$(176)
                CASE 6 TO 7
                    c = __BG_COLOR_LIGHT_CYAN: ch = CHR$(177)
                CASE 8 TO 9
                    c = __BG_COLOR_BRIGHT_WHITE: ch = CHR$(178)
                CASE 10 TO 11
                    c = __BG_COLOR_LIGHT_MAGENTA: ch = CHR$(177)
                CASE 12 TO 13
                    c = __BG_COLOR_MAGENTA: ch = CHR$(176)
                CASE ELSE
                    c = __BG_COLOR_GRAY: ch = "."
            END SELECT

            IF c <> lastCol THEN
                IF runStart > 0 THEN
                    COLOR lastCol, __BG_COLOR_BLACK
                    _PRINTSTRING (runStart, y), runStr
                END IF
                runStart = x
                lastCol = c
                runStr = ch
            ELSE
                runStr = runStr + ch
            END IF
        NEXT x

        IF runStart > 0 THEN
            COLOR lastCol, __BG_COLOR_BLACK
            _PRINTSTRING (runStart, y), runStr
        END IF
    NEXT y
END SUB

''' @brief Initializes kinetic bouncing balls with physics attributes.
''' @param ctx Background context to initialize.
SUB __Background_InitializeBalls (ctx AS Background)
    ctx.balls.count = __BACKGROUND_BALL_COUNT
    ctx.balls.quakeTimer = Math_GetRandomBetween(150, 240)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)

    DIM i AS LONG
    FOR i = 1 TO __BACKGROUND_BALL_COUNT
        ctx.balls.balls(i).position.x = CSNG(Math_GetRandomBetween(minX + 3, maxX - 3))
        ctx.balls.balls(i).position.y = CSNG(Math_GetRandomBetween(minY + 3, maxY - 3))
        ctx.balls.balls(i).velocity.x = (RND - 0.5!) * 1.5!
        ctx.balls.balls(i).velocity.y = (RND - 0.5!) * 0.9!
        ctx.balls.balls(i).radius = 1.0! + RND * 0.8!
        ctx.balls.balls(i).c = Math_GetRandomBetween(9, 14)

        DIM t AS LONG
        FOR t = 1 TO 4
            ctx.balls.balls(i).trailX(t) = CLNG(ctx.balls.balls(i).position.x)
            ctx.balls.balls(i).trailY(t) = CLNG(ctx.balls.balls(i).position.y)
        NEXT t
    NEXT i
END SUB

''' @brief Updates ball physics, wall rebounds, elastic collisions, and motion trails.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawBalls (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM H AS LONG: H = CLNG(ctx.size.y)
    DIM i AS LONG, j AS LONG

    ' Periodic floor trampoline pulse (popcorn effect every 3-4 seconds)
    ctx.balls.quakeTimer = ctx.balls.quakeTimer - 1
    IF ctx.balls.quakeTimer <= 0 THEN
        ctx.balls.quakeTimer = Math_GetRandomBetween(180, 260)
        DIM qFloorY AS SINGLE: qFloorY = CSNG(maxY) - CSNG(H) * 0.28!
        FOR i = 1 TO ctx.balls.count
            IF ctx.balls.balls(i).position.y >= qFloorY THEN
                ctx.balls.balls(i).velocity.y = -1.1! - RND * 0.75!
                ctx.balls.balls(i).velocity.x = ctx.balls.balls(i).velocity.x + (RND - 0.5!) * 1.5!
                ctx.balls.balls(i).c = Math_GetRandomBetween(9, 14)
            END IF
        NEXT i
    END IF

    FOR i = 1 TO ctx.balls.count - 1
        FOR j = i + 1 TO ctx.balls.count
            DIM dx AS SINGLE: dx = ctx.balls.balls(j).position.x - ctx.balls.balls(i).position.x
            DIM dy AS SINGLE: dy = (ctx.balls.balls(j).position.y - ctx.balls.balls(i).position.y) * 2.0!
            DIM distSq AS SINGLE: distSq = dx * dx + dy * dy
            DIM minDist AS SINGLE: minDist = ctx.balls.balls(i).radius + ctx.balls.balls(j).radius
            IF distSq < minDist * minDist _ANDALSO distSq > 0.001! THEN
                DIM dist AS SINGLE: dist = SQR(distSq)
                DIM nx AS SINGLE: nx = dx / dist
                DIM ny AS SINGLE: ny = dy / dist
                DIM kx AS SINGLE: kx = ctx.balls.balls(i).velocity.x - ctx.balls.balls(j).velocity.x
                DIM ky AS SINGLE: ky = ctx.balls.balls(i).velocity.y - ctx.balls.balls(j).velocity.y
                DIM p AS SINGLE: p = 2.04! * (nx * kx + ny * ky) / 2.0!
                IF p > 0! THEN
                    ctx.balls.balls(i).velocity.x = ctx.balls.balls(i).velocity.x - p * nx
                    ctx.balls.balls(i).velocity.y = ctx.balls.balls(i).velocity.y - p * ny * 0.5!
                    ctx.balls.balls(j).velocity.x = ctx.balls.balls(j).velocity.x + p * nx
                    ctx.balls.balls(j).velocity.y = ctx.balls.balls(j).velocity.y + p * ny * 0.5!
                END IF
            END IF
        NEXT j
    NEXT i

    FOR i = 1 TO ctx.balls.count
        ctx.balls.balls(i).velocity.y = ctx.balls.balls(i).velocity.y + 0.038!
        ctx.balls.balls(i).position.x = ctx.balls.balls(i).position.x + ctx.balls.balls(i).velocity.x
        ctx.balls.balls(i).position.y = ctx.balls.balls(i).position.y + ctx.balls.balls(i).velocity.y

        ' Left and right wall rebounds (high elasticity)
        IF ctx.balls.balls(i).position.x < CSNG(minX + 1) THEN
            ctx.balls.balls(i).position.x = CSNG(minX + 1)
            ctx.balls.balls(i).velocity.x = ABS(ctx.balls.balls(i).velocity.x) * 0.98!
            IF ctx.balls.balls(i).velocity.x < 0.3! THEN ctx.balls.balls(i).velocity.x = 0.4! + RND * 0.4!
        ELSEIF ctx.balls.balls(i).position.x > CSNG(maxX - 1) THEN
            ctx.balls.balls(i).position.x = CSNG(maxX - 1)
            ctx.balls.balls(i).velocity.x = -ABS(ctx.balls.balls(i).velocity.x) * 0.98!
            IF ctx.balls.balls(i).velocity.x > -0.3! THEN ctx.balls.balls(i).velocity.x = -0.4! - RND * 0.4!
        END IF

        ' Top ceiling rebound
        IF ctx.balls.balls(i).position.y < CSNG(minY + 1) THEN
            ctx.balls.balls(i).position.y = CSNG(minY + 1)
            ctx.balls.balls(i).velocity.y = ABS(ctx.balls.balls(i).velocity.y) * 0.94!
        ' Bottom floor trampoline rebound
        ELSEIF ctx.balls.balls(i).position.y > CSNG(maxY - 1) THEN
            ctx.balls.balls(i).position.y = CSNG(maxY - 1)
            DIM reboundVy AS SINGLE: reboundVy = ABS(ctx.balls.balls(i).velocity.y) * 0.94!
            ' Trampoline spring threshold: if rebound velocity is small, give it a spring-loaded kick
            IF reboundVy < 0.65! THEN
                reboundVy = 0.85! + RND * 0.65!
                ctx.balls.balls(i).velocity.x = ctx.balls.balls(i).velocity.x + (RND - 0.5!) * 0.6!
            END IF
            ctx.balls.balls(i).velocity.y = -reboundVy
            ctx.balls.balls(i).velocity.x = ctx.balls.balls(i).velocity.x * 0.99!
        END IF

        ' Anti-stagnation failsafe: if total velocity drops too low, kick it back into action
        IF ABS(ctx.balls.balls(i).velocity.x) + ABS(ctx.balls.balls(i).velocity.y) < 0.3! THEN
            ctx.balls.balls(i).velocity.y = -0.9! - RND * 0.6!
            ctx.balls.balls(i).velocity.x = (RND - 0.5!) * 1.4!
        END IF

        DIM bx AS LONG: bx = CLNG(ctx.balls.balls(i).position.x)
        DIM by AS LONG: by = CLNG(ctx.balls.balls(i).position.y)

        ctx.balls.balls(i).trailX(4) = ctx.balls.balls(i).trailX(3)
        ctx.balls.balls(i).trailY(4) = ctx.balls.balls(i).trailY(3)
        ctx.balls.balls(i).trailX(3) = ctx.balls.balls(i).trailX(2)
        ctx.balls.balls(i).trailY(3) = ctx.balls.balls(i).trailY(2)
        ctx.balls.balls(i).trailX(2) = ctx.balls.balls(i).trailX(1)
        ctx.balls.balls(i).trailY(2) = ctx.balls.balls(i).trailY(1)
        ctx.balls.balls(i).trailX(1) = bx
        ctx.balls.balls(i).trailY(1) = by

        IF ctx.balls.balls(i).trailX(4) >= minX _ANDALSO ctx.balls.balls(i).trailX(4) <= maxX _ANDALSO ctx.balls.balls(i).trailY(4) >= minY _ANDALSO ctx.balls.balls(i).trailY(4) <= maxY THEN
            COLOR __BG_COLOR_GRAY, __BG_COLOR_BLACK
            _PRINTSTRING (ctx.balls.balls(i).trailX(4), ctx.balls.balls(i).trailY(4)), "."
        END IF
        IF ctx.balls.balls(i).trailX(3) >= minX _ANDALSO ctx.balls.balls(i).trailX(3) <= maxX _ANDALSO ctx.balls.balls(i).trailY(3) >= minY _ANDALSO ctx.balls.balls(i).trailY(3) <= maxY THEN
            COLOR _MAX(1, ctx.balls.balls(i).c - 8), __BG_COLOR_BLACK
            _PRINTSTRING (ctx.balls.balls(i).trailX(3), ctx.balls.balls(i).trailY(3)), "o"
        END IF
        IF ctx.balls.balls(i).trailX(2) >= minX _ANDALSO ctx.balls.balls(i).trailX(2) <= maxX _ANDALSO ctx.balls.balls(i).trailY(2) >= minY _ANDALSO ctx.balls.balls(i).trailY(2) <= maxY THEN
            COLOR ctx.balls.balls(i).c, __BG_COLOR_BLACK
            _PRINTSTRING (ctx.balls.balls(i).trailX(2), ctx.balls.balls(i).trailY(2)), "O"
        END IF

        IF bx >= minX _ANDALSO bx <= maxX _ANDALSO by >= minY _ANDALSO by <= maxY THEN
            COLOR __BG_COLOR_BRIGHT_WHITE, __BG_COLOR_BLACK
            _PRINTSTRING (bx, by), CHR$(2)
        END IF
    NEXT i
END SUB

''' @brief Initializes digital matrix rain streams.
''' @param ctx Background context to initialize.
SUB __Background_InitializeMatrix (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM H AS LONG: H = CLNG(ctx.size.y)

    REDIM ctx.matrix.drops(1 TO maxX) AS __BACKGROUND_MATRIXDROP

    DIM c AS LONG
    FOR c = minX TO maxX
        ctx.matrix.drops(c).y = CSNG(Math_GetRandomBetween(minY, maxY))
        ctx.matrix.drops(c).speed = 0.28! + RND * 0.65!
        ctx.matrix.drops(c).length = Math_GetRandomBetween(8, _MIN(24, H \ 2))
        ctx.matrix.drops(c).active = (RND < 0.45!)
        ctx.matrix.drops(c).timer = Math_GetRandomBetween(0, 80)
        ctx.matrix.drops(c).charSeed = Math_GetRandomBetween(33, 126)
    NEXT c
END SUB

''' @brief Updates and renders green falling matrix code streams.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawMatrix (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM H AS LONG: H = CLNG(ctx.size.y)

    DIM c AS LONG
    FOR c = minX TO maxX
        IF NOT ctx.matrix.drops(c).active THEN
            ctx.matrix.drops(c).timer = ctx.matrix.drops(c).timer - 1
            IF ctx.matrix.drops(c).timer <= 0 THEN
                ctx.matrix.drops(c).active = _TRUE
                ctx.matrix.drops(c).y = CSNG(minY)
                ctx.matrix.drops(c).speed = 0.28! + RND * 0.65!
                ctx.matrix.drops(c).length = Math_GetRandomBetween(8, _MIN(24, H \ 2))
                ctx.matrix.drops(c).charSeed = Math_GetRandomBetween(33, 126)
            END IF
        ELSE
            ctx.matrix.drops(c).y = ctx.matrix.drops(c).y + ctx.matrix.drops(c).speed

            DIM headY AS LONG: headY = CLNG(ctx.matrix.drops(c).y)
            DIM lenDrop AS LONG: lenDrop = ctx.matrix.drops(c).length

            DIM sg AS LONG
            FOR sg = 0 TO lenDrop - 1
                DIM sy AS LONG: sy = headY - sg
                IF sy >= minY _ANDALSO sy <= maxY THEN
                    DIM chCode AS LONG
                    chCode = (ctx.matrix.drops(c).charSeed + c * 7 + sy * 13) MOD 94 + 33

                    IF sg = 0 THEN
                        COLOR __BG_COLOR_BRIGHT_WHITE, __BG_COLOR_BLACK
                    ELSEIF sg <= 2 THEN
                        COLOR __BG_COLOR_LIGHT_GREEN, __BG_COLOR_BLACK
                    ELSEIF sg < lenDrop - 3 THEN
                        COLOR __BG_COLOR_GREEN, __BG_COLOR_BLACK
                    ELSE
                        COLOR __BG_COLOR_GRAY, __BG_COLOR_BLACK
                    END IF

                    _PRINTSTRING (c, sy), CHR$(chCode)
                END IF
            NEXT sg

            IF headY - lenDrop > maxY THEN
                ctx.matrix.drops(c).active = _FALSE
                ctx.matrix.drops(c).timer = Math_GetRandomBetween(10, 80)
            END IF
        END IF
    NEXT c
END SUB

''' @brief Initializes all visual background effects within a specified viewport.
''' @param ctx Background context to initialize.
''' @param viewport Rectangular viewport defining rendering bounds.
SUB Background_InitializeEx (ctx AS Background, viewport AS Bounds2f)
    ctx.viewport = viewport
    Bounds2f_Sanitize ctx.viewport

    IF ctx.viewport.lt.x < 1! _ORELSE ctx.viewport.lt.y < 1! _ORELSE ctx.viewport.rb.x < 1! _ORELSE ctx.viewport.rb.y < 1! THEN
        ctx.viewport.lt.x = 1!
        ctx.viewport.lt.y = 1!
        ctx.viewport.rb.x = _WIDTH
        ctx.viewport.rb.y = _HEIGHT
    END IF 

    ctx.size.x = Bounds2f_GetDiscreteWidth(ctx.viewport)
    ctx.size.y = Bounds2f_GetDiscreteHeight(ctx.viewport)

    IF ctx.size.x < 1! _ORELSE ctx.size.y < 1! THEN
        ctx.viewport.lt.x = 1!
        ctx.viewport.lt.y = 1!
        ctx.viewport.rb.x = _WIDTH
        ctx.viewport.rb.y = _HEIGHT
        ctx.size.x = _WIDTH
        ctx.size.y = _HEIGHT
    END IF

    __Background_InitializeStars ctx
    __Background_InitializeSnakes ctx
    __Background_InitializeFireworks ctx
    __Background_InitializeFire ctx
    __Background_InitializePlasma ctx
    __Background_InitializeBalls ctx
    __Background_InitializeMatrix ctx

    Background_SetRandomMode ctx
END SUB

''' @brief Initializes all visual background effects using full-screen bounds (0, 0) - (_WIDTH, _HEIGHT).
''' @param ctx Background context to initialize.
SUB Background_Initialize (ctx AS Background)
    DIM vp AS Bounds2f
    Background_InitializeEx ctx, vp ' Background_InitializeEx will sanitize the viewport to full screen if invalid.
END SUB

''' @brief Updates and renders the active background effect.
''' @param ctx Background context.
SUB Background_UpdateAndDraw (ctx AS Background)
    SELECT CASE ctx.mode
        CASE BACKGROUND_MODE_STARS: __Background_UpdateAndDrawStars ctx
        CASE BACKGROUND_MODE_SNAKES: __Background_UpdateAndDrawSnakes ctx
        CASE BACKGROUND_MODE_FIREWORKS: __Background_UpdateAndDrawFireworks ctx
        CASE BACKGROUND_MODE_FIRE: __Background_UpdateAndDrawFire ctx
        CASE BACKGROUND_MODE_PLASMA: __Background_UpdateAndDrawPlasma ctx
        CASE BACKGROUND_MODE_BALLS: __Background_UpdateAndDrawBalls ctx
        CASE BACKGROUND_MODE_MATRIX: __Background_UpdateAndDrawMatrix ctx
    END SELECT
END SUB

''' @brief Randomly selects a background mode from the available modes.
''' @param ctx Background context.
SUB Background_SetRandomMode (ctx AS Background)
    ctx.mode = Math_GetRandomBetween(BACKGROUND_MODE_FIRST, BACKGROUND_MODE_LAST)
END SUB

''' @brief Cycles to the next available background effect mode.
''' @param ctx Background context.
SUB Background_CycleMode (ctx AS Background)
    ctx.mode = ctx.mode + 1
    IF ctx.mode > BACKGROUND_MODE_LAST THEN ctx.mode = BACKGROUND_MODE_FIRST
END SUB

''' @brief Returns human-readable name of the given background mode.
''' @param mode Background mode ID.
''' @return Mode name string.
FUNCTION Background_GetModeName$ (mode AS LONG)
    SELECT CASE mode
        CASE BACKGROUND_MODE_STARS: Background_GetModeName = "Starfield"
        CASE BACKGROUND_MODE_SNAKES: Background_GetModeName = "Kinetic Snakes"
        CASE BACKGROUND_MODE_FIREWORKS: Background_GetModeName = "Fireworks"
        CASE BACKGROUND_MODE_FIRE: Background_GetModeName = "Retro Fire"
        CASE BACKGROUND_MODE_PLASMA: Background_GetModeName = "Demoscene Plasma"
        CASE BACKGROUND_MODE_BALLS: Background_GetModeName = "Bouncing Balls"
        CASE BACKGROUND_MODE_MATRIX: Background_GetModeName = "Digital Matrix Rain"
        CASE ELSE: Background_GetModeName = "None"
    END SELECT
END FUNCTION
