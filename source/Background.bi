'-----------------------------------------------------------------------------------------------------------------------
' Background visual animation routines (Starfield & Snakes)
' Copyright (c) 2026 Samuel Gomes
'-----------------------------------------------------------------------------------------------------------------------

$INCLUDEONCE

'$INCLUDE:'Math.bi'
'$INCLUDE:'Vector2f.bi'
'$INCLUDE:'Vector3f.bi'

$UNSTABLE:TYPEFIELDS

' Background constants
CONST BACKGROUND_STAR_COUNT& = 256& ' default maximum stars that we can show
CONST BACKGROUND_SNAKE_COUNT& = 48& ' default maximum snakes we can draw on the screen
CONST BACKGROUND_MODE_STARS% = 0% ' starfield background mode
CONST BACKGROUND_MODE_SNAKES% = 1% ' snake background mode
CONST BACKGROUND_MODE_MAX% = 1% ' highest background mode index

TYPE BackgroundStar
    p AS Vector3f ' position
    a AS SINGLE ' angle
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE BackgroundStarfield
    stars(0 TO 0) _DYNAMIC AS BackgroundStar
    count AS LONG
END TYPE

TYPE BackgroundSnake
    p AS STRING ' position buffer (x = 1 byte, y = 1 byte)
    position AS Vector2f ' continuous sub-character position
    direction AS Vector2f ' continuous direction unit vector
    turnRate AS SINGLE ' angular velocity (radians per frame)
    speed AS SINGLE ' speed in characters per frame
    c AS _UNSIGNED LONG ' color
END TYPE

TYPE BackgroundSnakes
    snakes(0 TO 0) _DYNAMIC AS BackgroundSnake
    grid(0 TO 0, 0 TO 0) _DYNAMIC AS _BYTE
    gridW AS LONG
    gridH AS LONG
    count AS LONG
END TYPE

TYPE Background
    starfield AS BackgroundStarfield
    snakes AS BackgroundSnakes
    mode AS LONG
END TYPE

''' @brief Initializes star positions and colors for background starfield effect.
''' @param ctx BackgroundStarfield context to initialize.
''' @param starCount Number of stars to allocate (defaults to BACKGROUND_STAR_COUNT if <= 0).
SUB Background_InitializeStars (ctx AS BackgroundStarfield, starCount AS LONG)
    CONST Z_DIVIDER = 4096!

    DIM nStars AS LONG: nStars = starCount
    IF nStars <= 0 THEN nStars = BACKGROUND_STAR_COUNT

    ctx.count = nStars
    REDIM ctx.stars(1 TO nStars) AS BACKGROUNDSTAR

    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    DIM i AS LONG
    FOR i = 1 TO nStars
        ctx.stars(i).p.x = Math_GetRandomBetween(1, W)
        ctx.stars(i).p.y = Math_GetRandomBetween(1, H)
        ctx.stars(i).p.z = Z_DIVIDER
        ctx.stars(i).c = Math_GetRandomBetween(9, 15)
    NEXT i
END SUB

''' @brief Updates starfield positions and renders stars on screen.
''' @param ctx BackgroundStarfield context.
SUB Background_UpdateAndDrawStars (ctx AS BackgroundStarfield)
    CONST Z_DIVIDER = 4096!
    CONST STAR_249 = CHR$(249)
    CONST STAR_7 = CHR$(7)
    CONST STAR_43 = CHR$(43)
    CONST STAR_120 = CHR$(120)
    CONST STAR_42 = CHR$(42)
    CONST STAR_SPEED! = 1!

    IF ctx.count <= 0 THEN EXIT SUB

    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT
    DIM W_Half AS LONG: W_Half = W \ 2
    DIM H_Half AS LONG: H_Half = H \ 2

    DIM i AS LONG
    FOR i = 1 TO ctx.count
        IF ctx.stars(i).p.x < 1 _ORELSE _CAST(LONG, ctx.stars(i).p.x) > W _ORELSE ctx.stars(i).p.y < 1 _ORELSE _CAST(LONG, ctx.stars(i).p.y) > H THEN
            ctx.stars(i).p.x = Math_GetRandomBetween(1, W)
            ctx.stars(i).p.y = Math_GetRandomBetween(1, H)
            ctx.stars(i).p.z = Z_DIVIDER
            ctx.stars(i).c = Math_GetRandomBetween(9, 15)
        END IF

        COLOR ctx.stars(i).c, 0

        SELECT CASE ctx.stars(i).p.z
            CASE IS < 4119!
                _PRINTSTRING (ctx.stars(i).p.x, ctx.stars(i).p.y), STAR_249

            CASE IS < 4149!
                _PRINTSTRING (ctx.stars(i).p.x, ctx.stars(i).p.y), STAR_7

            CASE IS < 4166!
                _PRINTSTRING (ctx.stars(i).p.x, ctx.stars(i).p.y), STAR_43

            CASE IS < 4190!
                _PRINTSTRING (ctx.stars(i).p.x, ctx.stars(i).p.y), STAR_120

            CASE ELSE
                _PRINTSTRING (ctx.stars(i).p.x, ctx.stars(i).p.y), STAR_42

        END SELECT

        ctx.stars(i).p.z = ctx.stars(i).p.z + STAR_SPEED
        ctx.stars(i).a = ctx.stars(i).a + 0.01!
        DIM zd AS SINGLE: zd = ctx.stars(i).p.z / Z_DIVIDER
        ctx.stars(i).p.x = ((ctx.stars(i).p.x - W_Half) * zd) + W_Half + COS(ctx.stars(i).a * 0.5!) * 0.5!
        ctx.stars(i).p.y = ((ctx.stars(i).p.y - H_Half) * zd) + H_Half + SIN(ctx.stars(i).a * 1.5!) * 0.5!
    NEXT i
END SUB

''' @brief Initializes bouncing snake positions and colors with collision-free placement.
''' @param ctx BackgroundSnakes context to initialize.
''' @param snakeCount Number of snakes to allocate (defaults to BACKGROUND_SNAKE_COUNT if <= 0).
SUB Background_InitializeSnakes (ctx AS BackgroundSnakes, snakeCount AS LONG)
    CONST SNAKE_SIZE_MIN = 5
    CONST SNAKE_SIZE_MAX = 30

    DIM nSnakes AS LONG: nSnakes = snakeCount
    IF nSnakes <= 0 THEN nSnakes = BACKGROUND_SNAKE_COUNT

    ctx.count = nSnakes
    REDIM ctx.snakes(1 TO nSnakes) AS BACKGROUNDSNAKE
    ctx.gridW = 0
    ctx.gridH = 0

    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    REDIM spawnGrid(1 TO W, 1 TO H) AS _BYTE

    DIM i AS LONG
    FOR i = 1 TO nSnakes
        ctx.snakes(i).p = SPACE$(Math_GetRandomBetween(SNAKE_SIZE_MIN, SNAKE_SIZE_MAX) * 2)
        ctx.snakes(i).speed = 0.2! + RND * 0.4!
        ctx.snakes(i).c = Math_GetRandomBetween(1, 8)
        DIM angle AS SINGLE: angle = RND * _PI(2!)
        Vector2f_FromAngle angle, 1!, ctx.snakes(i).direction
        ctx.snakes(i).turnRate = 0!

        ' Find a spawn position not occupied by another snake
        DIM x AS LONG, y AS LONG, tries AS LONG
        DO
            x = Math_GetRandomBetween(2, W - 1)
            y = Math_GetRandomBetween(2, H - 1)
            tries = tries + 1
        LOOP WHILE spawnGrid(x, y) <> 0 AND tries < 500
        spawnGrid(x, y) = 1

        Vector2f_Initialize CSNG(x), CSNG(y), ctx.snakes(i).position

        DIM size AS LONG: size = LEN(ctx.snakes(i).p)
        DIM j AS LONG
        FOR j = 1 TO size STEP 2
            ASC(ctx.snakes(i).p, j) = x
            ASC(ctx.snakes(i).p, j + 1) = y
        NEXT j
    NEXT i
END SUB

''' @brief Updates snake segments with collision detection/avoidance and renders bouncing snakes on screen.
''' @param ctx BackgroundSnakes context.
SUB Background_UpdateAndDrawSnakes (ctx AS BackgroundSnakes)
    CONST SNAKE_HEAD = CHR$(15)
    CONST SNAKE_BODY = CHR$(254)

    IF ctx.count <= 0 THEN EXIT SUB

    DIM W AS LONG: W = _WIDTH
    DIM H AS LONG: H = _HEIGHT

    ' Ensure encapsulated occupancy grid matches screen dimensions
    IF W <> ctx.gridW _ORELSE H <> ctx.gridH THEN
        ctx.gridW = W: ctx.gridH = H
        REDIM ctx.grid(1 TO W, 1 TO H) AS _BYTE
    END IF

    ' Clear encapsulated occupancy grid
    DIM mema AS _MEM: mema = _MEM(ctx.grid())
    _MEMFILL mema, mema.OFFSET, mema.SIZE, 0%% AS _BYTE
    _MEMFREE mema

    ' Populate occupancy grid with all current snake segments
    DIM i AS LONG
    FOR i = 1 TO ctx.count
        DIM pLen AS LONG: pLen = LEN(ctx.snakes(i).p)
        DIM j AS LONG
        FOR j = 1 TO pLen STEP 2
            DIM sx AS LONG: sx = ASC(ctx.snakes(i).p, j)
            DIM sy AS LONG: sy = ASC(ctx.snakes(i).p, j + 1)
            IF sx >= 1 _ANDALSO sx <= W _ANDALSO sy >= 1 _ANDALSO sy <= H THEN
                ctx.grid(sx, sy) = i
            END IF
        NEXT j
    NEXT i

    ' Head-to-head proximity deflection
    FOR i = 1 TO ctx.count - 1
        FOR j = i + 1 TO ctx.count
            DIM dSq AS SINGLE
            dSq = Vector2f_DistanceSquared(ctx.snakes(i).position, ctx.snakes(j).position)
            IF dSq < 4.0! THEN
                DIM rep AS Vector2f
                Vector2f_Subtract ctx.snakes(i).position, ctx.snakes(j).position, rep
                IF Vector2f_IsNull(rep) THEN
                    Vector2f_Set (RND - 0.5!), (RND - 0.5!), rep
                END IF
                Vector2f_Normalize rep, rep
                ctx.snakes(i).direction = rep
                Vector2f_Negate rep, ctx.snakes(j).direction
                ctx.snakes(i).turnRate = (RND - 0.5!) * 0.2!
                ctx.snakes(j).turnRate = (RND - 0.5!) * 0.2!
            END IF
        NEXT j
    NEXT i

    ' Update each snake
    FOR i = 1 TO ctx.count
        ' Probe ahead for obstacles (walls or other snakes)
        DIM lookDist AS SINGLE: lookDist = 2.0!
        DIM aheadX AS SINGLE: aheadX = ctx.snakes(i).position.x + ctx.snakes(i).direction.x * lookDist
        DIM aheadY AS SINGLE: aheadY = ctx.snakes(i).position.y + ctx.snakes(i).direction.y * lookDist
        DIM ax AS LONG: ax = _CLAMP(CINT(aheadX), 1, W)
        DIM ay AS LONG: ay = _CLAMP(CINT(aheadY), 1, H)

        DIM aheadBlocked AS _BYTE
        aheadBlocked = (aheadX < 1.5! _ORELSE aheadX > CSNG(W) - 0.5! _ORELSE aheadY < 1.5! _ORELSE aheadY > CSNG(H) - 0.5!)
        IF NOT aheadBlocked THEN
            IF ctx.grid(ax, ay) <> 0 _ANDALSO ctx.grid(ax, ay) <> i THEN aheadBlocked = _TRUE
        END IF

        IF aheadBlocked THEN
            ' Evaluate left (+60 deg) and right (-60 deg) alternatives
            DIM leftDir AS Vector2f, rightDir AS Vector2f
            Vector2f_Rotate ctx.snakes(i).direction, 1.047!, leftDir
            Vector2f_Rotate ctx.snakes(i).direction, -1.047!, rightDir

            DIM lx AS LONG: lx = _CLAMP(CINT(ctx.snakes(i).position.x + leftDir.x * lookDist), 1, W)
            DIM ly AS LONG: ly = _CLAMP(CINT(ctx.snakes(i).position.y + leftDir.y * lookDist), 1, H)
            DIM leftBlocked AS _BYTE
            leftBlocked = (lx <= 1 _ORELSE lx >= W _ORELSE ly <= 1 _ORELSE ly >= H)
            IF NOT leftBlocked THEN
                IF ctx.grid(lx, ly) <> 0 _ANDALSO ctx.grid(lx, ly) <> i THEN leftBlocked = _TRUE
            END IF

            DIM rx AS LONG: rx = _CLAMP(CINT(ctx.snakes(i).position.x + rightDir.x * lookDist), 1, W)
            DIM ry AS LONG: ry = _CLAMP(CINT(ctx.snakes(i).position.y + rightDir.y * lookDist), 1, H)
            DIM rightBlocked AS _BYTE
            rightBlocked = (rx <= 1 _ORELSE rx >= W _ORELSE ry <= 1 _ORELSE ry >= H)
            IF NOT rightBlocked THEN
                IF ctx.grid(rx, ry) <> 0 _ANDALSO ctx.grid(rx, ry) <> i THEN rightBlocked = _TRUE
            END IF

            IF NOT leftBlocked _ANDALSO rightBlocked THEN
                ctx.snakes(i).turnRate = 0.25!
            ELSEIF NOT rightBlocked _ANDALSO leftBlocked THEN
                ctx.snakes(i).turnRate = -0.25!
            ELSEIF NOT leftBlocked _ANDALSO NOT rightBlocked THEN
                IF ctx.snakes(i).turnRate >= 0! THEN ctx.snakes(i).turnRate = 0.25! ELSE ctx.snakes(i).turnRate = -0.25!
            ELSE
                Vector2f_Rotate ctx.snakes(i).direction, _PI * 0.75!, ctx.snakes(i).direction
                ctx.snakes(i).turnRate = (RND - 0.5!) * 0.2!
            END IF
        ELSE
            ' Free wandering steering
            DIM r AS SINGLE: r = RND
            IF r < 0.04! THEN
                ctx.snakes(i).turnRate = (RND - 0.5!) * 0.12!
            ELSEIF r < 0.08! THEN
                ctx.snakes(i).turnRate = 0!
            END IF
        END IF

        ' Rotate direction vector smoothly
        IF ctx.snakes(i).turnRate <> 0! THEN
            Vector2f_Rotate ctx.snakes(i).direction, ctx.snakes(i).turnRate, ctx.snakes(i).direction
            Vector2f_Normalize ctx.snakes(i).direction, ctx.snakes(i).direction
        END IF

        ' Compute next continuous position
        DIM nextX AS SINGLE: nextX = ctx.snakes(i).position.x + ctx.snakes(i).direction.x * ctx.snakes(i).speed
        DIM nextY AS SINGLE: nextY = ctx.snakes(i).position.y + ctx.snakes(i).direction.y * ctx.snakes(i).speed

        ' Screen border bounces
        IF nextX < 1! THEN
            Vector2f_FlipHorizontal ctx.snakes(i).direction, ctx.snakes(i).direction
            nextX = 1!
            ctx.snakes(i).turnRate = -ctx.snakes(i).turnRate
        ELSEIF nextX > CSNG(W) THEN
            Vector2f_FlipHorizontal ctx.snakes(i).direction, ctx.snakes(i).direction
            nextX = CSNG(W)
            ctx.snakes(i).turnRate = -ctx.snakes(i).turnRate
        END IF

        IF nextY < 1! THEN
            Vector2f_FlipVertical ctx.snakes(i).direction, ctx.snakes(i).direction
            nextY = 1!
            ctx.snakes(i).turnRate = -ctx.snakes(i).turnRate
        ELSEIF nextY > CSNG(H) THEN
            Vector2f_FlipVertical ctx.snakes(i).direction, ctx.snakes(i).direction
            nextY = CSNG(H)
            ctx.snakes(i).turnRate = -ctx.snakes(i).turnRate
        END IF

        ' Hard collision prevention: ensure target cell is not occupied by another snake
        DIM targetCellX AS LONG: targetCellX = _CLAMP(CINT(nextX), 1, W)
        DIM targetCellY AS LONG: targetCellY = _CLAMP(CINT(nextY), 1, H)

        IF ctx.grid(targetCellX, targetCellY) <> 0 _ANDALSO ctx.grid(targetCellX, targetCellY) <> i THEN
            DIM foundEscape AS _BYTE: foundEscape = _FALSE
            DIM testIdx AS LONG
            FOR testIdx = 1 TO 5
                DIM testAngle AS SINGLE
                SELECT CASE testIdx
                    CASE 1: testAngle = 1.570796! ' +90 deg
                    CASE 2: testAngle = -1.570796! ' -90 deg
                    CASE 3: testAngle = 2.356194! ' +135 deg
                    CASE 4: testAngle = -2.356194! ' -135 deg
                    CASE 5: testAngle = 3.141593! ' 180 deg
                END SELECT

                DIM candDir AS Vector2f
                Vector2f_Rotate ctx.snakes(i).direction, testAngle, candDir
                Vector2f_Normalize candDir, candDir

                DIM candX AS SINGLE: candX = ctx.snakes(i).position.x + candDir.x * ctx.snakes(i).speed
                DIM candY AS SINGLE: candY = ctx.snakes(i).position.y + candDir.y * ctx.snakes(i).speed
                DIM candCellX AS LONG: candCellX = _CLAMP(CINT(candX), 1, W)
                DIM candCellY AS LONG: candCellY = _CLAMP(CINT(candY), 1, H)

                IF candX >= 1! _ANDALSO candX <= CSNG(W) _ANDALSO candY >= 1! _ANDALSO candY <= CSNG(H) THEN
                    IF ctx.grid(candCellX, candCellY) = 0 _ORELSE ctx.grid(candCellX, candCellY) = i THEN
                        ctx.snakes(i).direction = candDir
                        ctx.snakes(i).turnRate = testAngle * 0.1!
                        nextX = candX
                        nextY = candY
                        targetCellX = candCellX
                        targetCellY = candCellY
                        foundEscape = _TRUE
                        EXIT FOR
                    END IF
                END IF
            NEXT testIdx

            IF NOT foundEscape THEN
                nextX = ctx.snakes(i).position.x
                nextY = ctx.snakes(i).position.y
                targetCellX = ASC(ctx.snakes(i).p, 1)
                targetCellY = ASC(ctx.snakes(i).p, 2)
            END IF
        END IF

        ctx.snakes(i).position.x = nextX
        ctx.snakes(i).position.y = nextY

        ' Shift body segments when entering a new character cell
        IF targetCellX <> ASC(ctx.snakes(i).p, 1) _ORELSE targetCellY <> ASC(ctx.snakes(i).p, 2) THEN
            DIM sLen AS LONG: sLen = LEN(ctx.snakes(i).p)
            DIM oldTailX AS LONG: oldTailX = ASC(ctx.snakes(i).p, sLen - 1)
            DIM oldTailY AS LONG: oldTailY = ASC(ctx.snakes(i).p, sLen)

            DIM k AS LONG: k = sLen - 2
            WHILE k > 0
                ASC(ctx.snakes(i).p, k + 2) = ASC(ctx.snakes(i).p, k)
                k = k - 1
            WEND
            ASC(ctx.snakes(i).p, 1) = targetCellX
            ASC(ctx.snakes(i).p, 2) = targetCellY

            ' Only clear old tail cell if no other segment of snake i remains there
            DIM tailStillOccupied AS _BYTE: tailStillOccupied = _FALSE
            DIM chk AS LONG
            FOR chk = 1 TO sLen STEP 2
                IF ASC(ctx.snakes(i).p, chk) = oldTailX AND ASC(ctx.snakes(i).p, chk + 1) = oldTailY THEN
                    tailStillOccupied = _TRUE
                    EXIT FOR
                END IF
            NEXT chk

            IF NOT tailStillOccupied THEN
                IF oldTailX >= 1 _ANDALSO oldTailX <= W _ANDALSO oldTailY >= 1 _ANDALSO oldTailY <= H THEN
                    IF ctx.grid(oldTailX, oldTailY) = i THEN ctx.grid(oldTailX, oldTailY) = 0
                END IF
            END IF
            ctx.grid(targetCellX, targetCellY) = i
        END IF

        ' Draw body segments
        DIM sLenDraw AS LONG: sLenDraw = LEN(ctx.snakes(i).p)
        j = sLenDraw - 2
        WHILE j > 2
            DIM py AS LONG: py = ASC(ctx.snakes(i).p, j)
            j = j - 1
            DIM px AS LONG: px = ASC(ctx.snakes(i).p, j)
            j = j - 1

            COLOR ctx.snakes(i).c, 0
            _PRINTSTRING (px, py), SNAKE_BODY
        WEND

        ' Draw head
        COLOR ctx.snakes(i).c, 0
        _PRINTSTRING (ASC(ctx.snakes(i).p, 1), ASC(ctx.snakes(i).p, 2)), SNAKE_HEAD
    NEXT i
END SUB

''' @brief Initializes a unified Background context including starfield and snakes.
''' @param ctx Background context to initialize.
SUB Background_Initialize (ctx AS Background)
    Background_InitializeStars ctx.starfield, BACKGROUND_STAR_COUNT
    Background_InitializeSnakes ctx.snakes, BACKGROUND_SNAKE_COUNT
    ctx.mode = BACKGROUND_MODE_STARS
END SUB

''' @brief Updates and renders the active background effect.
''' @param ctx Background context.
SUB Background_UpdateAndDraw (ctx AS Background)
    SELECT CASE ctx.mode
        CASE BACKGROUND_MODE_SNAKES
            Background_UpdateAndDrawSnakes ctx.snakes

        CASE ELSE
            Background_UpdateAndDrawStars ctx.starfield
    END SELECT
END SUB
