'-----------------------------------------------------------------------------------------------------------------------
' Background visual animations
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
CONST BACKGROUND_MODE_GRID& = 8&
CONST BACKGROUND_MODE_FISHTANK& = 9&
CONST BACKGROUND_MODE_FIRST& = BACKGROUND_MODE_STARS
CONST BACKGROUND_MODE_LAST& = BACKGROUND_MODE_FISHTANK&

CONST __BACKGROUND_STAR_COUNT& = 256& ' default maximum stars
CONST __BACKGROUND_SNAKE_COUNT& = 48& ' default maximum snakes
CONST __BACKGROUND_FIREWORK_ROCKETS& = 6& ' simultaneous firework rockets
CONST __BACKGROUND_FIREWORK_PARTICLES& = 192& ' total firework particle pool (32 per rocket)
CONST __BACKGROUND_BALL_COUNT& = 20& ' bouncing kinetic balls
CONST __BACKGROUND_FISH_COUNT& = 24& ' swimming aquarium fish
CONST __BACKGROUND_KELP_COUNT& = 18& ' swaying kelp stalks
CONST __BACKGROUND_BUBBLE_COUNT& = 28& ' rising aeration bubbles

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

' CP437 glyph constants for background rendering
CONST __BG_GLYPH_SMILEY = CHR$(2) ' Smiley face glyph
CONST __BG_GLYPH_LIGHT_SHADE = CHR$(176) ' Light shade block
CONST __BG_GLYPH_MEDIUM_SHADE = CHR$(177) ' Medium shade block
CONST __BG_GLYPH_DARK_SHADE = CHR$(178) ' Dark shade block
CONST __BG_GLYPH_HLINE = CHR$(196) ' Horizontal line
CONST __BG_GLYPH_SOLID = CHR$(219) ' Full solid block
CONST __BG_GLYPH_APPROX = CHR$(247) ' Approx / ripple
CONST __BG_GLYPH_DEGREE = CHR$(248) ' Degree / bubble
CONST __BG_GLYPH_BULLET = CHR$(249) ' Bullet / dot
CONST __BG_GLYPH_BLOCK = CHR$(254) ' Square block

TYPE __Background_Star
    p AS Vector3f ' position (x, y, z)
    a AS SINGLE ' angle
    c AS _UNSIGNED LONG ' color
    prevX AS SINGLE ' previous screen X position for motion trails
    prevY AS SINGLE ' previous screen Y position for motion trails
    speed AS SINGLE ' individual star velocity multiplier
END TYPE

TYPE __Background_Starfield
    _DYNAMIC stars(0 TO 0) AS __Background_Star
    count AS LONG
    rollAngle AS SINGLE
    rollSpeed AS SINGLE
    warpTimer AS LONG
    swayTimer AS SINGLE
    cometActive AS _BYTE
    cometX AS SINGLE
    cometY AS SINGLE
    cometVX AS SINGLE
    cometVY AS SINGLE
    cometLife AS LONG
    cometCooldown AS LONG
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
    _DYNAMIC decayRate(0 TO 0) AS SINGLE
    gridW AS LONG
    gridH AS LONG
    phase1 AS SINGLE
    phase2 AS SINGLE
    phase3 AS SINGLE
    flareX AS LONG
    flareIntensity AS SINGLE
    flareTimer AS LONG
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

TYPE __Background_Grid
    scrollZ AS SINGLE
    terrainPhase AS SINGLE
    sunPulse AS SINGLE
    starCount AS LONG
    stars(1 TO 32) AS Vector2f
    starBlink(1 TO 32) AS SINGLE
END TYPE

TYPE __Background_Fish
    x AS SINGLE
    y AS SINGLE
    baseY AS SINGLE
    dx AS SINGLE
    swimPhase AS SINGLE
    swimSpeed AS SINGLE
    species AS LONG
    bodyLen AS LONG
    cHead AS _UNSIGNED LONG
    cBody AS _UNSIGNED LONG
    cTail AS _UNSIGNED LONG
    layer AS LONG
END TYPE

TYPE __Background_KelpStalk
    rootX AS LONG
    height AS LONG
    swayPhase AS SINGLE
    swayFlex AS SINGLE
    layer AS LONG
END TYPE

TYPE __Background_Bubble
    x AS SINGLE
    y AS SINGLE
    baseX AS SINGLE
    speed AS SINGLE
    wobblePhase AS SINGLE
    active AS _BYTE
END TYPE

TYPE __Background_Fishtank
    fish(1 TO __BACKGROUND_FISH_COUNT) AS __Background_Fish
    kelp(1 TO __BACKGROUND_KELP_COUNT) AS __Background_KelpStalk
    bubbles(1 TO __BACKGROUND_BUBBLE_COUNT) AS __Background_Bubble
    waterPhase AS SINGLE
    crabX AS SINGLE
    crabDir AS SINGLE
    fishCount AS LONG
    kelpCount AS LONG
    bubbleCount AS LONG
END TYPE

TYPE Background
    starfield AS __Background_Starfield
    snakes AS __Background_Snakes
    fireworks AS __Background_Fireworks
    fire AS __Background_Fire
    plasma AS __Background_Plasma
    balls AS __Background_Balls
    matrix AS __Background_Matrix
    grid AS __Background_Grid
    fishtank AS __Background_Fishtank
    mode AS LONG
    viewport AS Bounds2f
    size AS Vector2f
END TYPE

''' @brief Initializes star positions and colors for background starfield effect.
''' @param ctx Background context to initialize.
SUB __Background_InitializeStars (ctx AS Background)
    DIM nStars AS LONG: nStars = __BACKGROUND_STAR_COUNT

    ctx.starfield.count = nStars
    REDIM ctx.starfield.stars(1 TO nStars) AS __BACKGROUND_STAR

    ctx.starfield.rollAngle = 0!
    ctx.starfield.rollSpeed = 0.0032!
    ctx.starfield.warpTimer = Math_GetRandomBetween(0, 300)
    ctx.starfield.swayTimer = RND * 6.2831853!
    ctx.starfield.cometActive = 0
    ctx.starfield.cometCooldown = Math_GetRandomBetween(200, 450)

    DIM maxDist AS SINGLE: maxDist = ctx.size.x * 0.85!
    IF maxDist < 20! THEN maxDist = 60!

    DIM i AS LONG
    FOR i = 1 TO nStars
        DIM ang AS SINGLE: ang = RND * 6.2831853!
        ' Area-uniform polar distribution using SQR(RND) across full 360 degrees
        DIM rad AS SINGLE: rad = 4.0! + SQR(RND) * (maxDist - 4.0!)
        ctx.starfield.stars(i).p.x = COS(ang) * rad
        ctx.starfield.stars(i).p.y = SIN(ang) * (rad * 0.58!)
        ctx.starfield.stars(i).p.z = 4100.0! + RND * 400.0!
        ctx.starfield.stars(i).a = ang
        ctx.starfield.stars(i).c = Math_GetRandomBetween(9, 15)
        ctx.starfield.stars(i).speed = 0.85! + RND * 0.45!
        ctx.starfield.stars(i).prevX = -1!
        ctx.starfield.stars(i).prevY = -1!
    NEXT i
END SUB

''' @brief Updates starfield positions and renders stars on screen with 3D depth shading, camera roll, and warp pulses.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawStars (ctx AS Background)
    IF ctx.starfield.count <= 0 THEN EXIT SUB

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM centerX AS LONG: centerX = (minX + maxX) \ 2
    DIM centerY AS LONG: centerY = (minY + maxY) \ 2
    DIM W AS SINGLE: W = ctx.size.x
    DIM H AS SINGLE: H = ctx.size.y
    DIM maxDist AS SINGLE: maxDist = W * 0.85!
    IF maxDist < 20! THEN maxDist = 60!

    ' Dynamic camera sway (organic wandering vanishing point)
    ctx.starfield.swayTimer = ctx.starfield.swayTimer + 0.012!
    IF ctx.starfield.swayTimer > 6.2831853! THEN ctx.starfield.swayTimer = ctx.starfield.swayTimer - 6.2831853!
    DIM vanishX AS SINGLE: vanishX = CSNG(centerX) + SIN(ctx.starfield.swayTimer) * (W * 0.07!)
    DIM vanishY AS SINGLE: vanishY = CSNG(centerY) + SIN(ctx.starfield.swayTimer * 1.618!) * (H * 0.07!)

    ' Galactic camera roll rotation
    ctx.starfield.rollAngle = ctx.starfield.rollAngle + ctx.starfield.rollSpeed
    IF ctx.starfield.rollAngle > 6.2831853! THEN ctx.starfield.rollAngle = ctx.starfield.rollAngle - 6.2831853!
    DIM cosRoll AS SINGLE: cosRoll = COS(ctx.starfield.rollAngle)
    DIM sinRoll AS SINGLE: sinRoll = SIN(ctx.starfield.rollAngle)

    ' Dynamic hyperdrive warp speed pulse (every ~850 frames / ~14 seconds)
    ctx.starfield.warpTimer = ctx.starfield.warpTimer + 1
    IF ctx.starfield.warpTimer > 850 THEN ctx.starfield.warpTimer = 0

    DIM warpMult AS SINGLE: warpMult = 1.0!
    IF ctx.starfield.warpTimer >= 550 _ANDALSO ctx.starfield.warpTimer < 750 THEN
        DIM pulseProg AS SINGLE: pulseProg = CSNG(ctx.starfield.warpTimer - 550) / 200.0!
        warpMult = 1.0! + 2.2! * (0.5! - 0.5! * COS(pulseProg * 6.2831853!))
    END IF

    ' 3D Star projection and rendering loop
    DIM i AS LONG
    FOR i = 1 TO ctx.starfield.count
        DIM dZ AS SINGLE: dZ = ctx.starfield.stars(i).p.z - 4096.0!
        IF dZ < 4.0! THEN dZ = 4.0!
        DIM fScale AS SINGLE: fScale = 140.0! / dZ

        ' Rotate world star position by galactic roll angle
        DIM rotX AS SINGLE
        rotX = ctx.starfield.stars(i).p.x * cosRoll - ctx.starfield.stars(i).p.y * sinRoll
        DIM rotY AS SINGLE
        rotY = ctx.starfield.stars(i).p.x * sinRoll + ctx.starfield.stars(i).p.y * cosRoll

        DIM px AS LONG: px = CLNG(vanishX + rotX * fScale)
        DIM py AS LONG: py = CLNG(vanishY + rotY * fScale)

        ' Reset star if it exited the screen borders or passed the camera plane
        IF px < minX _ORELSE px > maxX _ORELSE py < minY _ORELSE py > maxY _ORELSE ctx.starfield.stars(i).p.z <= 4104.0! THEN
            DIM newAng AS SINGLE: newAng = RND * 6.2831853!
            DIM newRad AS SINGLE: newRad = 4.0! + SQR(RND) * (maxDist - 4.0!)
            ctx.starfield.stars(i).p.x = COS(newAng) * newRad
            ctx.starfield.stars(i).p.y = SIN(newAng) * (newRad * 0.58!)
            ctx.starfield.stars(i).p.z = 4500.0!
            ctx.starfield.stars(i).a = newAng
            ctx.starfield.stars(i).c = Math_GetRandomBetween(9, 15)
            ctx.starfield.stars(i).speed = 0.85! + RND * 0.45!
            ctx.starfield.stars(i).prevX = -1!
            ctx.starfield.stars(i).prevY = -1!

            dZ = 404.0!
            fScale = 140.0! / dZ
            rotX = ctx.starfield.stars(i).p.x * cosRoll - ctx.starfield.stars(i).p.y * sinRoll
            rotY = ctx.starfield.stars(i).p.x * sinRoll + ctx.starfield.stars(i).p.y * cosRoll
            px = CLNG(vanishX + rotX * fScale)
            py = CLNG(vanishY + rotY * fScale)
        END IF

        ' Render speed streak/motion blur trail for near stars or during warp surges
        IF ctx.starfield.stars(i).prevX >= CSNG(minX) _ANDALSO ctx.starfield.stars(i).prevX <= CSNG(maxX) _ANDALSO _
           ctx.starfield.stars(i).prevY >= CSNG(minY) _ANDALSO ctx.starfield.stars(i).prevY <= CSNG(maxY) THEN
            DIM prevPX AS LONG: prevPX = CLNG(ctx.starfield.stars(i).prevX)
            DIM prevPY AS LONG: prevPY = CLNG(ctx.starfield.stars(i).prevY)
            IF (prevPX <> px _ORELSE prevPY <> py) _ANDALSO (dZ < 90.0! _ORELSE warpMult > 1.3!) THEN
                COLOR __BG_COLOR_GRAY, __BG_COLOR_BLACK
                _PRINTSTRING (prevPX, prevPY), "."
            END IF
        END IF

        ' Select color and character glyph based on distance (depth shading)
        DIM sChar AS STRING
        DIM sCol AS _UNSIGNED LONG

        IF dZ > 250.0! THEN
            sCol = __BG_COLOR_GRAY: sChar = "."
        ELSEIF dZ > 140.0! THEN
            sCol = __BG_COLOR_WHITE: sChar = __BG_GLYPH_BULLET
        ELSEIF dZ > 65.0! THEN
            sCol = ctx.starfield.stars(i).c: sChar = "+"
        ELSEIF dZ > 30.0! THEN
            sCol = ctx.starfield.stars(i).c: sChar = "x"
        ELSE
            sCol = __BG_COLOR_BRIGHT_WHITE: sChar = "*"
        END IF

        IF px >= minX _ANDALSO px <= maxX _ANDALSO py >= minY _ANDALSO py <= maxY THEN
            COLOR sCol, __BG_COLOR_BLACK
            _PRINTSTRING (px, py), sChar
            ctx.starfield.stars(i).prevX = CSNG(px)
            ctx.starfield.stars(i).prevY = CSNG(py)
        ELSE
            ctx.starfield.stars(i).prevX = -1!
            ctx.starfield.stars(i).prevY = -1!
        END IF

        ' Move star forward toward camera
        DIM starAdvance AS SINGLE
        starAdvance = ctx.starfield.stars(i).speed * warpMult * 1.5!
        ctx.starfield.stars(i).p.z = ctx.starfield.stars(i).p.z - starAdvance
    NEXT i

    ' Periodic shooting star / comet animation
    ctx.starfield.cometCooldown = ctx.starfield.cometCooldown - 1
    IF ctx.starfield.cometCooldown <= 0 _ANDALSO ctx.starfield.cometActive = 0 THEN
        ctx.starfield.cometActive = 1
        ctx.starfield.cometX = CSNG(Math_GetRandomBetween(minX + 5, minX + (maxX - minX) \ 2))
        ctx.starfield.cometY = CSNG(minY + 2)
        ctx.starfield.cometVX = 2.2! + RND * 1.0!
        ctx.starfield.cometVY = 0.8! + RND * 0.5!
        ctx.starfield.cometLife = Math_GetRandomBetween(35, 50)
        ctx.starfield.cometCooldown = Math_GetRandomBetween(450, 850)
    END IF

    IF ctx.starfield.cometActive THEN
        ctx.starfield.cometX = ctx.starfield.cometX + ctx.starfield.cometVX
        ctx.starfield.cometY = ctx.starfield.cometY + ctx.starfield.cometVY
        ctx.starfield.cometLife = ctx.starfield.cometLife - 1

        DIM comX AS LONG: comX = CLNG(ctx.starfield.cometX)
        DIM comY AS LONG: comY = CLNG(ctx.starfield.cometY)

        IF ctx.starfield.cometLife <= 0 _ORELSE comX > maxX _ORELSE comY > maxY THEN
            ctx.starfield.cometActive = 0
        ELSE
            ' Render 4-segment trailing ion tail
            DIM tailIdx AS LONG
            FOR tailIdx = 4 TO 1 STEP -1
                DIM tailX AS LONG: tailX = CLNG(ctx.starfield.cometX - CSNG(tailIdx) * ctx.starfield.cometVX * 0.75!)
                DIM tailY AS LONG: tailY = CLNG(ctx.starfield.cometY - CSNG(tailIdx) * ctx.starfield.cometVY * 0.75!)
                IF tailX >= minX _ANDALSO tailX <= maxX _ANDALSO tailY >= minY _ANDALSO tailY <= maxY THEN
                    SELECT CASE tailIdx
                        CASE 4: COLOR __BG_COLOR_GRAY, __BG_COLOR_BLACK: _PRINTSTRING (tailX, tailY), "."
                        CASE 3: COLOR __BG_COLOR_BLUE, __BG_COLOR_BLACK: _PRINTSTRING (tailX, tailY), "."
                        CASE 2: COLOR __BG_COLOR_CYAN, __BG_COLOR_BLACK: _PRINTSTRING (tailX, tailY), __BG_GLYPH_BULLET
                        CASE 1: COLOR __BG_COLOR_LIGHT_CYAN, __BG_COLOR_BLACK: _PRINTSTRING (tailX, tailY), "+"
                    END SELECT
                END IF
            NEXT tailIdx

            ' Render brilliant comet core
            IF comX >= minX _ANDALSO comX <= maxX _ANDALSO comY >= minY _ANDALSO comY <= maxY THEN
                COLOR __BG_COLOR_BRIGHT_WHITE, __BG_COLOR_BLACK
                _PRINTSTRING (comX, comY), "*"
            END IF
        END IF
    END IF
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
    CONST SNAKE_HEAD = __BG_GLYPH_SMILEY ' Smiley head glyph
    CONST SNAKE_BODY = __BG_GLYPH_BLOCK ' Block body glyph

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
                        pCol = __BG_COLOR_GRAY: pChar = __BG_GLYPH_BULLET
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
    REDIM ctx.fire.decayRate(1 TO maxX) AS SINGLE

    DIM x AS LONG
    FOR x = 1 TO maxX
        ctx.fire.decayRate(x) = 0.50!
    NEXT x

    ctx.fire.phase1 = RND * 6.2831853!
    ctx.fire.phase2 = RND * 6.2831853!
    ctx.fire.phase3 = RND * 6.2831853!
    ctx.fire.flareX = (CLNG(ctx.viewport.lt.x) + maxX) \ 2
    ctx.fire.flareIntensity = 0!
    ctx.fire.flareTimer = Math_GetRandomBetween(45, 120)
END SUB

''' @brief Updates retro cellular automata fire simulation and renders flames.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawFire (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM H AS LONG: H = CLNG(ctx.size.y)
    IF H < 5 THEN EXIT SUB

    ' Base flame height scales gently with viewport height (approx 44% of viewport height)
    DIM baseFlameHeight AS SINGLE: baseFlameHeight = CSNG(H) * 0.44!
    DIM maxFlameReach AS LONG: maxFlameReach = CLNG(CSNG(H) * 0.64!)
    DIM topFireY AS LONG: topFireY = _MAX(minY + 1, maxY - maxFlameReach)

    ' Gradually advance traveling wave phases for subtle, organic undulations
    ctx.fire.phase1 = ctx.fire.phase1 + 0.012!
    IF ctx.fire.phase1 > 6.2831853! THEN ctx.fire.phase1 = ctx.fire.phase1 - 6.2831853!

    ctx.fire.phase2 = ctx.fire.phase2 + 0.008!
    IF ctx.fire.phase2 > 6.2831853! THEN ctx.fire.phase2 = ctx.fire.phase2 - 6.2831853!

    ctx.fire.phase3 = ctx.fire.phase3 + 0.016!
    IF ctx.fire.phase3 > 6.2831853! THEN ctx.fire.phase3 = ctx.fire.phase3 - 6.2831853!

    ' Update subtle random flare-up bursts
    ctx.fire.flareIntensity = ctx.fire.flareIntensity * 0.95!
    ctx.fire.flareTimer = ctx.fire.flareTimer - 1
    IF ctx.fire.flareTimer <= 0 THEN
        DIM safeMinX AS LONG: safeMinX = _MIN(minX + 5, maxX)
        DIM safeMaxX AS LONG: safeMaxX = _MAX(minX, maxX - 5)
        IF safeMinX > safeMaxX THEN safeMinX = minX: safeMaxX = maxX
        ctx.fire.flareX = Math_GetRandomBetween(safeMinX, safeMaxX)
        ctx.fire.flareIntensity = 0.12! + RND * 0.16!
        ctx.fire.flareTimer = Math_GetRandomBetween(60, 160)
    END IF

    ' 1D precomputation across columns: calculate dynamic flame height and smoothed decay rate
    DIM x AS LONG
    FOR x = minX TO maxX
        ' Organic traveling harmonic wave modulation
        DIM waveMod AS SINGLE
        waveMod = 0.16! * SIN(CSNG(x) * 0.065! + ctx.fire.phase1) + _
                  0.10! * SIN(CSNG(x) * 0.125! - ctx.fire.phase2) + _
                  0.06! * COS(CSNG(x) * 0.032! + ctx.fire.phase3)

        ' Localized subtle flare-up influence with smooth cosine bell curve
        DIM flareMod AS SINGLE: flareMod = 0!
        IF ctx.fire.flareIntensity > 0.01! THEN
            DIM distToFlare AS SINGLE: distToFlare = ABS(CSNG(x - ctx.fire.flareX))
            IF distToFlare < 12! THEN
                flareMod = ctx.fire.flareIntensity * 0.5! * (1.0! + COS(distToFlare * 3.14159265! / 12!))
            END IF
        END IF

        DIM heightFactor AS SINGLE: heightFactor = _CLAMP(1.0! + waveMod + flareMod, 0.60!, 1.35!)
        DIM colTargetH AS SINGLE: colTargetH = _CLAMP(baseFlameHeight * heightFactor, 5!, CSNG(maxY - topFireY))

        ' Target decay rate per vertical row step, smoothed with exponential moving average
        DIM targetRate AS SINGLE: targetRate = 15.5! / colTargetH
        ctx.fire.decayRate(x) = ctx.fire.decayRate(x) * 0.88! + targetRate * 0.12!

        ' Seed bottom line (row maxY): continuously glowing hot coal bed without dark gaps
        DIM baseHeat AS LONG
        baseHeat = CLNG(14! + 3! * (heightFactor - 0.60!) / 0.75! + (RND * 2! - 1!))
        ctx.fire.grid(x, maxY) = _CLAMP(baseHeat, 13, 18)
    NEXT x

    ' Propagate heat upward with 3-tap horizontal diffusion and column-dependent decay
    DIM y AS LONG
    FOR y = topFireY TO maxY - 1
        FOR x = minX TO maxX
            DIM wind AS LONG: wind = Math_GetRandomBetween(-1, 1)
            DIM cx AS LONG: cx = _CLAMP(x + wind, minX, maxX)
            DIM lx AS LONG: lx = _CLAMP(cx - 1, minX, maxX)
            DIM rx AS LONG: rx = _CLAMP(cx + 1, minX, maxX)

            ' 3-tap horizontal diffusion [1, 2, 1] / 4 to eliminate harsh vertical striping
            DIM belowHeat AS LONG
            belowHeat = (CLNG(ctx.fire.grid(lx, y + 1)) + _
                         CLNG(ctx.fire.grid(cx, y + 1)) * 2 + _
                         CLNG(ctx.fire.grid(rx, y + 1))) \ 4

            DIM rate AS SINGLE: rate = ctx.fire.decayRate(cx)
            DIM decay AS LONG: decay = 0
            IF rate <= 1.0! THEN
                IF RND < rate THEN decay = 1
            ELSE
                decay = 1
                IF RND < (rate - 1.0!) THEN decay = 2
            END IF

            DIM heat AS LONG: heat = belowHeat - decay
            IF heat < 0 THEN heat = 0
            ctx.fire.grid(x, y) = heat
        NEXT x
    NEXT y

    ' Render flame rows with horizontal run-length batching and balanced color ramp
    DIM startRenderY AS LONG: startRenderY = topFireY
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
                CASE 1
                    c = __BG_COLOR_GRAY: ch = "."
                CASE 2 TO 3
                    c = __BG_COLOR_BROWN: ch = "."
                CASE 4 TO 5
                    c = __BG_COLOR_RED: ch = __BG_GLYPH_LIGHT_SHADE
                CASE 6 TO 7
                    c = __BG_COLOR_RED: ch = __BG_GLYPH_MEDIUM_SHADE
                CASE 8 TO 9
                    c = __BG_COLOR_LIGHT_RED: ch = __BG_GLYPH_MEDIUM_SHADE
                CASE 10 TO 11
                    c = __BG_COLOR_LIGHT_RED: ch = __BG_GLYPH_DARK_SHADE
                CASE 12 TO 13
                    c = __BG_COLOR_YELLOW: ch = __BG_GLYPH_DARK_SHADE
                CASE 14 TO 16
                    c = __BG_COLOR_YELLOW: ch = __BG_GLYPH_SOLID
                CASE ELSE
                    c = __BG_COLOR_BRIGHT_WHITE: ch = __BG_GLYPH_SOLID
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
                    c = __BG_COLOR_LIGHT_BLUE: ch = __BG_GLYPH_LIGHT_SHADE
                CASE 4 TO 5
                    c = __BG_COLOR_CYAN: ch = __BG_GLYPH_LIGHT_SHADE
                CASE 6 TO 7
                    c = __BG_COLOR_LIGHT_CYAN: ch = __BG_GLYPH_MEDIUM_SHADE
                CASE 8 TO 9
                    c = __BG_COLOR_BRIGHT_WHITE: ch = __BG_GLYPH_DARK_SHADE
                CASE 10 TO 11
                    c = __BG_COLOR_LIGHT_MAGENTA: ch = __BG_GLYPH_MEDIUM_SHADE
                CASE 12 TO 13
                    c = __BG_COLOR_MAGENTA: ch = __BG_GLYPH_LIGHT_SHADE
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
            _PRINTSTRING (bx, by), __BG_GLYPH_SMILEY
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

''' @brief Initializes 3D retro cyber grid terrain and sky state.
''' @param ctx Background context to initialize.
SUB __Background_InitializeGrid (ctx AS Background)
    ctx.grid.scrollZ = 0!
    ctx.grid.terrainPhase = 0!
    ctx.grid.sunPulse = 0!
    ctx.grid.starCount = 32

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM H AS LONG: H = CLNG(ctx.size.y)
    DIM horizonY AS LONG: horizonY = minY + CLNG(CSNG(H) * 0.40!)

    DIM i AS LONG
    FOR i = 1 TO 32
        ctx.grid.stars(i).x = CSNG(Math_GetRandomBetween(minX + 1, maxX - 1))
        ctx.grid.stars(i).y = CSNG(Math_GetRandomBetween(minY + 1, _MAX(minY + 1, horizonY - 2)))
        ctx.grid.starBlink(i) = RND * 6.2831853!
    NEXT i
END SUB

''' @brief Updates and renders 3D Retro Cyber Grid with rolling terrain, segmented sunset, and starry sky.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawGrid (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM W AS LONG: W = CLNG(ctx.size.x)
    DIM H AS LONG: H = CLNG(ctx.size.y)
    IF W < 10 _ORELSE H < 10 THEN EXIT SUB

    DIM centerX AS LONG: centerX = (minX + maxX) \ 2
    DIM horizonY AS LONG: horizonY = minY + CLNG(CSNG(H) * 0.40!)
    IF horizonY <= minY + 2 THEN horizonY = minY + 3
    IF horizonY >= maxY - 4 THEN horizonY = maxY - 5

    ' Advance animation phases
    ctx.grid.scrollZ = ctx.grid.scrollZ + 0.024!
    IF ctx.grid.scrollZ >= 1.0! THEN ctx.grid.scrollZ = ctx.grid.scrollZ - 1.0!

    ctx.grid.terrainPhase = ctx.grid.terrainPhase + 0.018!
    IF ctx.grid.terrainPhase > 6.2831853! THEN ctx.grid.terrainPhase = ctx.grid.terrainPhase - 6.2831853!

    ctx.grid.sunPulse = ctx.grid.sunPulse + 0.035!
    IF ctx.grid.sunPulse > 6.2831853! THEN ctx.grid.sunPulse = ctx.grid.sunPulse - 6.2831853!

    ' -------------------------------------------------------------
    ' 1. Sky & Stars (Above Horizon)
    ' -------------------------------------------------------------
    DIM i AS LONG
    FOR i = 1 TO ctx.grid.starCount
        ctx.grid.starBlink(i) = ctx.grid.starBlink(i) + 0.045!
        IF ctx.grid.starBlink(i) > 6.2831853! THEN ctx.grid.starBlink(i) = ctx.grid.starBlink(i) - 6.2831853!

        DIM sx AS LONG: sx = CLNG(ctx.grid.stars(i).x)
        DIM sy AS LONG: sy = CLNG(ctx.grid.stars(i).y)

        IF sx >= minX _ANDALSO sx <= maxX _ANDALSO sy >= minY _ANDALSO sy < horizonY - 1 THEN
            DIM bVal AS SINGLE: bVal = SIN(ctx.grid.starBlink(i))
            IF bVal > 0.4! THEN
                COLOR __BG_COLOR_BRIGHT_WHITE, __BG_COLOR_BLACK
                _PRINTSTRING (sx, sy), "*"
            ELSEIF bVal > -0.2! THEN
                COLOR __BG_COLOR_LIGHT_CYAN, __BG_COLOR_BLACK
                _PRINTSTRING (sx, sy), __BG_GLYPH_BULLET
            ELSE
                COLOR __BG_COLOR_GRAY, __BG_COLOR_BLACK
                _PRINTSTRING (sx, sy), "."
            END IF
        END IF
    NEXT i

    ' -------------------------------------------------------------
    ' 2. Segmented Synthwave Sun (On the Horizon)
    ' -------------------------------------------------------------
    DIM sunRadY AS LONG: sunRadY = _CLAMP(H \ 7, 4, 12)
    DIM sunRadX AS LONG: sunRadX = _CLAMP(CLNG(CSNG(sunRadY) * 1.85!), 8, 25)
    DIM sunCenterY AS LONG: sunCenterY = horizonY - 1

    DIM syRow AS LONG
    FOR syRow = sunCenterY - sunRadY TO horizonY
        IF syRow >= minY _ANDALSO syRow <= horizonY THEN
            DIM relY AS SINGLE: relY = CSNG(syRow - sunCenterY) / CSNG(sunRadY)
            IF ABS(relY) <= 1.0! THEN
                DIM halfW AS LONG: halfW = CLNG(CSNG(sunRadX) * SQR(1.0! - relY * relY))
                DIM sunLeft AS LONG: sunLeft = _MAX(minX, centerX - halfW)
                DIM sunRight AS LONG: sunRight = _MIN(maxX, centerX + halfW)

                ' Classic horizontal scanline slats in lower half of sun
                DIM isSlat AS _BYTE: isSlat = _FALSE
                DIM distFromHoriz AS LONG: distFromHoriz = horizonY - syRow
                IF distFromHoriz <= (sunRadY * 3) \ 4 THEN
                    IF (distFromHoriz MOD 2 = 0) _ORELSE (distFromHoriz <= 2) THEN
                        isSlat = _TRUE
                    END IF
                END IF

                IF NOT isSlat _ANDALSO sunLeft <= sunRight THEN
                    DIM sunCol AS LONG, sunChar AS STRING
                    IF relY < -0.35! THEN
                        sunCol = __BG_COLOR_YELLOW: sunChar = __BG_GLYPH_SOLID
                    ELSEIF relY < 0.25! THEN
                        sunCol = __BG_COLOR_LIGHT_RED: sunChar = __BG_GLYPH_SOLID
                    ELSE
                        sunCol = __BG_COLOR_LIGHT_MAGENTA: sunChar = __BG_GLYPH_DARK_SHADE
                    END IF

                    DIM sunW AS LONG: sunW = sunRight - sunLeft + 1
                    COLOR sunCol, __BG_COLOR_BLACK
                    _PRINTSTRING (sunLeft, syRow), STRING$(sunW, sunChar)
                END IF
            END IF
        END IF
    NEXT syRow

    ' -------------------------------------------------------------
    ' 3. Distant Mountain Silhouette & Horizon Line
    ' -------------------------------------------------------------
    DIM mx AS LONG
    FOR mx = minX TO maxX
        DIM mH AS LONG
        mH = CLNG(1.8! * SIN(CSNG(mx) * 0.075! + 1.2!) + 1.2! * COS(CSNG(mx) * 0.16! - 0.5!))
        IF mH < 0 THEN mH = 0
        DIM mPeakY AS LONG: mPeakY = horizonY - mH
        IF mPeakY < horizonY THEN
            DIM my AS LONG
            FOR my = mPeakY TO horizonY - 1
                IF my >= minY THEN
                    COLOR __BG_COLOR_BLUE, __BG_COLOR_BLACK
                    _PRINTSTRING (mx, my), __BG_GLYPH_LIGHT_SHADE
                END IF
            NEXT my
        END IF
    NEXT mx

    ' Glowing horizon neon line
    COLOR __BG_COLOR_LIGHT_CYAN, __BG_COLOR_BLACK
    _PRINTSTRING (minX, horizonY), STRING$(maxX - minX + 1, __BG_GLYPH_HLINE)

    ' -------------------------------------------------------------
    ' 4. 3D Wireframe Perspective Ground Grid (Scrolling Forward)
    ' -------------------------------------------------------------
    DIM groundH AS LONG: groundH = maxY - horizonY
    IF groundH < 3 THEN EXIT SUB

    ' Precompute perspective transverse horizontal grid lines
    DIM numTransverse AS LONG: numTransverse = _CLAMP(groundH \ 3, 6, 16)
    DIM isTransLine(0 TO 255) AS _BYTE
    DIM k AS LONG
    FOR k = 0 TO 255: isTransLine(k) = _FALSE: NEXT k

    FOR k = 1 TO numTransverse
        DIM vFrac AS SINGLE: vFrac = 1.0! / (CSNG(k) + (1.0! - ctx.grid.scrollZ))
        DIM gLineY AS LONG: gLineY = horizonY + CLNG(vFrac * CSNG(groundH) * 1.18!)
        IF gLineY > horizonY _ANDALSO gLineY <= maxY THEN
            isTransLine(gLineY - minY) = _TRUE
        END IF
    NEXT k

    ' Render ground rows with longitudinal rays and intersection crosses
    DIM gy AS LONG
    FOR gy = horizonY + 1 TO maxY
        DIM depthV AS SINGLE: depthV = CSNG(gy - horizonY) / CSNG(groundH)
        DIM isHLine AS _BYTE: isHLine = isTransLine(gy - minY)

        ' Depth-based color shading
        DIM gridCol AS LONG, crossCol AS LONG
        IF depthV > 0.65! THEN
            gridCol = __BG_COLOR_CYAN: crossCol = __BG_COLOR_BRIGHT_WHITE
        ELSEIF depthV > 0.35! THEN
            gridCol = __BG_COLOR_LIGHT_MAGENTA: crossCol = __BG_COLOR_LIGHT_CYAN
        ELSEIF depthV > 0.15! THEN
            gridCol = __BG_COLOR_MAGENTA: crossCol = __BG_COLOR_LIGHT_MAGENTA
        ELSE
            gridCol = __BG_COLOR_BLUE: crossCol = __BG_COLOR_BLUE
        END IF

        DIM runStart AS LONG: runStart = 0
        DIM lastCol AS LONG: lastCol = -1
        DIM runStr AS STRING: runStr = ""

        DIM gx AS LONG
        FOR gx = minX TO maxX
            DIM xDist AS SINGLE: xDist = CSNG(gx - centerX)
            DIM rayFrac AS SINGLE: rayFrac = (xDist / depthV)
            DIM rayIdx AS SINGLE: rayIdx = rayFrac / 14.0!
            DIM isVLine AS _BYTE
            isVLine = (ABS(rayIdx - CSNG(CLNG(rayIdx))) < (0.18! / (depthV * 0.8! + 0.2!)))

            DIM c AS LONG: c = -1
            DIM ch AS STRING: ch = " "

            IF isHLine _ANDALSO isVLine THEN
                c = crossCol: ch = "+"
            ELSEIF isHLine THEN
                c = gridCol: ch = __BG_GLYPH_HLINE
            ELSEIF isVLine THEN
                c = gridCol: ch = "|"
            END IF

            IF c <> lastCol THEN
                IF runStart > 0 _ANDALSO lastCol >= 0 THEN
                    COLOR lastCol, __BG_COLOR_BLACK
                    _PRINTSTRING (runStart, gy), runStr
                END IF
                runStart = gx
                lastCol = c
                runStr = ch
            ELSE
                runStr = runStr + ch
            END IF
        NEXT gx

        IF runStart > 0 _ANDALSO lastCol >= 0 THEN
            COLOR lastCol, __BG_COLOR_BLACK
            _PRINTSTRING (runStart, gy), runStr
        END IF
    NEXT gy
END SUB

''' @brief Initializes fish, swaying kelp, aeration bubbles, and seabed for aquarium simulation.
''' @param ctx Background context to initialize.
SUB __Background_InitializeFishtank (ctx AS Background)
    ctx.fishtank.fishCount = __BACKGROUND_FISH_COUNT
    ctx.fishtank.kelpCount = __BACKGROUND_KELP_COUNT
    ctx.fishtank.bubbleCount = __BACKGROUND_BUBBLE_COUNT
    ctx.fishtank.waterPhase = 0!

    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM W AS LONG: W = CLNG(ctx.size.x)
    DIM H AS LONG: H = CLNG(ctx.size.y)
    DIM centerX AS LONG: centerX = (minX + maxX) \ 2

    ctx.fishtank.crabX = CSNG(centerX)
    ctx.fishtank.crabDir = 0.12!

    ' Initialize Fish species, colors, layers, and swimming lanes
    DIM i AS LONG
    FOR i = 1 TO __BACKGROUND_FISH_COUNT
        ctx.fishtank.fish(i).x = CSNG(Math_GetRandomBetween(minX + 4, maxX - 4))
        ctx.fishtank.fish(i).baseY = CSNG(Math_GetRandomBetween(minY + 3, _MAX(minY + 3, maxY - 4)))
        ctx.fishtank.fish(i).y = ctx.fishtank.fish(i).baseY
        ctx.fishtank.fish(i).swimPhase = RND * 6.2831853!
        ctx.fishtank.fish(i).swimSpeed = 0.10! + RND * 0.08!
        ctx.fishtank.fish(i).species = (i - 1) MOD 4
        ctx.fishtank.fish(i).layer = (i - 1) MOD 3 ' 0 = deep background, 1 = midground, 2 = foreground

        ' Horizontal speed and orientation
        DIM spd AS SINGLE: spd = 0.28! + RND * 0.35!
        IF ctx.fishtank.fish(i).layer = 0 THEN spd = spd * 0.65!
        IF ctx.fishtank.fish(i).layer = 2 THEN spd = spd * 1.35!

        IF RND > 0.5! THEN
            ctx.fishtank.fish(i).dx = -spd
        ELSE
            ctx.fishtank.fish(i).dx = spd
        END IF

        ' Species-specific body length and vibrant colors
        SELECT CASE ctx.fishtank.fish(i).species
            CASE 0 ' Neon Tetra (electric cyan head, neon red body, bright white tail)
                ctx.fishtank.fish(i).bodyLen = 2
                IF ctx.fishtank.fish(i).layer = 0 THEN
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_CYAN
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_RED
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_GRAY
                ELSE
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_LIGHT_CYAN
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_LIGHT_RED
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_BRIGHT_WHITE
                END IF

            CASE 1 ' Clownfish (gold/orange with white stripes)
                ctx.fishtank.fish(i).bodyLen = 3
                IF ctx.fishtank.fish(i).layer = 0 THEN
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_BROWN
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_RED
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_BROWN
                ELSE
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_YELLOW
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_LIGHT_RED
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_YELLOW
                END IF

            CASE 2 ' Angelfish (diamond shaped, majestic gold/cyan)
                ctx.fishtank.fish(i).bodyLen = 3
                IF ctx.fishtank.fish(i).layer = 0 THEN
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_GRAY
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_BROWN
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_GRAY
                ELSE
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_BRIGHT_WHITE
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_YELLOW
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_LIGHT_CYAN
                END IF

            CASE ELSE ' Silver Guppy (quick minnows)
                ctx.fishtank.fish(i).bodyLen = 1
                IF ctx.fishtank.fish(i).layer = 0 THEN
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_GRAY
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_BLUE
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_GRAY
                ELSE
                    ctx.fishtank.fish(i).cHead = __BG_COLOR_BRIGHT_WHITE
                    ctx.fishtank.fish(i).cBody = __BG_COLOR_LIGHT_CYAN
                    ctx.fishtank.fish(i).cTail = __BG_COLOR_WHITE
                END IF
        END SELECT
    NEXT i

    ' Initialize Swaying Kelp Forest
    DIM k AS LONG
    FOR k = 1 TO __BACKGROUND_KELP_COUNT
        ctx.fishtank.kelp(k).rootX = minX + CLNG((CSNG(k) - 0.5!) * (CSNG(W) / CSNG(__BACKGROUND_KELP_COUNT))) + Math_GetRandomBetween(-2, 2)
        ctx.fishtank.kelp(k).rootX = _CLAMP(ctx.fishtank.kelp(k).rootX, minX + 2, maxX - 2)
        ctx.fishtank.kelp(k).height = Math_GetRandomBetween(_MAX(10, H \ 3), _MAX(12, (H * 4) \ 5))
        ctx.fishtank.kelp(k).swayPhase = RND * 6.2831853!
        ctx.fishtank.kelp(k).swayFlex = 0.7! + RND * 0.6!
        ctx.fishtank.kelp(k).layer = k MOD 2 ' 0 = background, 1 = foreground
    NEXT k

    ' Initialize Aeration Bubbles
    DIM b AS LONG
    FOR b = 1 TO __BACKGROUND_BUBBLE_COUNT
        DIM emCol AS LONG
        emCol = minX + CLNG((CSNG(b MOD 5) + 0.5!) * (CSNG(W) / 5.0!)) + Math_GetRandomBetween(-2, 2)
        ctx.fishtank.bubbles(b).baseX = CSNG(_CLAMP(emCol, minX + 2, maxX - 2))
        ctx.fishtank.bubbles(b).x = ctx.fishtank.bubbles(b).baseX
        ctx.fishtank.bubbles(b).y = CSNG(maxY - 2 - Math_GetRandomBetween(0, _MAX(1, H - 4)))
        ctx.fishtank.bubbles(b).speed = 0.35! + RND * 0.38!
        ctx.fishtank.bubbles(b).wobblePhase = RND * 6.2831853!
        ctx.fishtank.bubbles(b).active = _TRUE
    NEXT b
END SUB

''' @brief Updates and renders living aquarium with fish species, swaying kelp, rising bubbles, and seabed.
''' @param ctx Background context.
SUB __Background_UpdateAndDrawFishtank (ctx AS Background)
    DIM minX AS LONG: minX = CLNG(ctx.viewport.lt.x)
    DIM maxX AS LONG: maxX = CLNG(ctx.viewport.rb.x)
    DIM minY AS LONG: minY = CLNG(ctx.viewport.lt.y)
    DIM maxY AS LONG: maxY = CLNG(ctx.viewport.rb.y)
    DIM W AS LONG: W = CLNG(ctx.size.x)
    DIM H AS LONG: H = CLNG(ctx.size.y)
    IF W < 10 _ORELSE H < 8 THEN EXIT SUB

    ' Advance fluid ocean current
    ctx.fishtank.waterPhase = ctx.fishtank.waterPhase + 0.024!
    IF ctx.fishtank.waterPhase > 6.2831853! THEN ctx.fishtank.waterPhase = ctx.fishtank.waterPhase - 6.2831853!

    ' -------------------------------------------------------------
    ' 1. Shimmering Water Surface at top of aquarium (minY)
    ' -------------------------------------------------------------
    DIM wx AS LONG
    FOR wx = minX TO maxX
        DIM waveVal AS SINGLE
        waveVal = SIN(CSNG(wx) * 0.22! + ctx.fishtank.waterPhase * 2.2!)
        DIM surfChar AS STRING, surfCol AS LONG
        IF waveVal > 0.4! THEN
            surfChar = "~": surfCol = __BG_COLOR_LIGHT_CYAN
        ELSEIF waveVal > -0.3! THEN
            surfChar = __BG_GLYPH_APPROX: surfCol = __BG_COLOR_CYAN
        ELSE
            surfChar = "-": surfCol = __BG_COLOR_BLUE
        END IF
        COLOR surfCol, __BG_COLOR_BLACK
        _PRINTSTRING (wx, minY), surfChar
    NEXT wx

    DIM i AS LONG

    ' --- Pass 1: Deep Background Fish (behind kelp) ---
    FOR i = 1 TO ctx.fishtank.fishCount
        IF ctx.fishtank.fish(i).layer = 0 THEN
            ctx.fishtank.fish(i).x = ctx.fishtank.fish(i).x + ctx.fishtank.fish(i).dx
            ctx.fishtank.fish(i).swimPhase = ctx.fishtank.fish(i).swimPhase + ctx.fishtank.fish(i).swimSpeed

            ' Screen boundary wrapping
            IF ctx.fishtank.fish(i).dx < 0! _ANDALSO ctx.fishtank.fish(i).x < CSNG(minX - 10) THEN
                ctx.fishtank.fish(i).x = CSNG(maxX + 2)
                ctx.fishtank.fish(i).baseY = CSNG(Math_GetRandomBetween(minY + 3, _MAX(minY + 3, maxY - 4)))
            ELSEIF ctx.fishtank.fish(i).dx > 0! _ANDALSO ctx.fishtank.fish(i).x > CSNG(maxX + 10) THEN
                ctx.fishtank.fish(i).x = CSNG(minX - 8)
                ctx.fishtank.fish(i).baseY = CSNG(Math_GetRandomBetween(minY + 3, _MAX(minY + 3, maxY - 4)))
            END IF

            DIM py0 AS LONG: py0 = CLNG(ctx.fishtank.fish(i).baseY + SIN(ctx.fishtank.fish(i).swimPhase) * 0.7!)
            DIM px0 AS LONG: px0 = CLNG(ctx.fishtank.fish(i).x)

            ' Tail wagging animation frame
            DIM tailWag0 AS LONG: tailWag0 = CLNG(ctx.fishtank.fish(i).swimPhase * 1.8!) MOD 2
            DIM fStr0 AS STRING

            IF ctx.fishtank.fish(i).dx < 0! THEN
                IF tailWag0 = 0 THEN
                    fStr0 = "<*)" + STRING$(ctx.fishtank.fish(i).bodyLen, ")") + ">{"
                ELSE
                    fStr0 = "<*)" + STRING$(ctx.fishtank.fish(i).bodyLen, ")") + ">~"
                END IF
            ELSE
                IF tailWag0 = 0 THEN
                    fStr0 = "}<" + STRING$(ctx.fishtank.fish(i).bodyLen, "(") + "(*>"
                ELSE
                    fStr0 = "~<" + STRING$(ctx.fishtank.fish(i).bodyLen, "(") + "(*>"
                END IF
            END IF

            DIM cIdx0 AS LONG
            FOR cIdx0 = 1 TO LEN(fStr0)
                DIM drwX0 AS LONG: drwX0 = px0 + cIdx0 - 1
                IF drwX0 >= minX _ANDALSO drwX0 <= maxX _ANDALSO py0 >= minY + 1 _ANDALSO py0 <= maxY - 2 THEN
                    COLOR ctx.fishtank.fish(i).cBody, __BG_COLOR_BLACK
                    _PRINTSTRING (drwX0, py0), MID$(fStr0, cIdx0, 1)
                END IF
            NEXT cIdx0
        END IF
    NEXT i

    ' --- Pass 2: Swaying Kelp Forest ---
    DIM k AS LONG
    FOR k = 1 TO ctx.fishtank.kelpCount
        DIM rootX AS LONG: rootX = ctx.fishtank.kelp(k).rootX
        DIM kH AS LONG: kH = ctx.fishtank.kelp(k).height
        DIM isFg AS _BYTE: isFg = (ctx.fishtank.kelp(k).layer = 1)

        DIM j AS LONG
        FOR j = 1 TO kH
            DIM rowY AS LONG: rowY = maxY - j
            IF rowY >= minY + 1 THEN
                DIM hFrac AS SINGLE: hFrac = CSNG(j) / CSNG(kH)
                DIM swayOffset AS SINGLE
                swayOffset = SIN(ctx.fishtank.waterPhase + CSNG(j) * 0.14! + ctx.fishtank.kelp(k).swayPhase) * (hFrac * hFrac * ctx.fishtank.kelp(k).swayFlex * 4.5!)
                DIM stemX AS LONG: stemX = rootX + CLNG(swayOffset)

                IF stemX >= minX _ANDALSO stemX <= maxX THEN
                    DIM kelpChar AS STRING, kelpCol AS LONG
                    IF isFg THEN
                        IF hFrac > 0.70! THEN
                            kelpCol = __BG_COLOR_LIGHT_CYAN
                        ELSE
                            kelpCol = __BG_COLOR_LIGHT_GREEN
                        END IF
                    ELSE
                        kelpCol = __BG_COLOR_GREEN
                    END IF

                    IF j = kH THEN
                        kelpChar = "~"
                    ELSEIF (j MOD 4 = 1) THEN
                        kelpChar = "("
                    ELSEIF (j MOD 4 = 3) THEN
                        kelpChar = ")"
                    ELSE
                        kelpChar = "|"
                    END IF

                    COLOR kelpCol, __BG_COLOR_BLACK
                    _PRINTSTRING (stemX, rowY), kelpChar
                END IF
            END IF
        NEXT j
    NEXT k

    ' --- Pass 3: Rising Aeration Bubbles ---
    DIM b AS LONG
    FOR b = 1 TO ctx.fishtank.bubbleCount
        ctx.fishtank.bubbles(b).y = ctx.fishtank.bubbles(b).y - ctx.fishtank.bubbles(b).speed
        ctx.fishtank.bubbles(b).wobblePhase = ctx.fishtank.bubbles(b).wobblePhase + 0.15!
        ctx.fishtank.bubbles(b).x = ctx.fishtank.bubbles(b).baseX + SIN(ctx.fishtank.bubbles(b).wobblePhase) * 1.3!

        DIM bPX AS LONG: bPX = CLNG(ctx.fishtank.bubbles(b).x)
        DIM bPY AS LONG: bPY = CLNG(ctx.fishtank.bubbles(b).y)

        IF bPY <= minY + 1 THEN
            ctx.fishtank.bubbles(b).y = CSNG(maxY - 2)
            ctx.fishtank.bubbles(b).wobblePhase = RND * 6.2831853!
        ELSEIF bPX >= minX _ANDALSO bPX <= maxX _ANDALSO bPY >= minY _ANDALSO bPY <= maxY - 2 THEN
            DIM bubChar AS STRING, bubCol AS LONG
            IF bPY > maxY - 15 THEN
                bubChar = ".": bubCol = __BG_COLOR_LIGHT_CYAN
            ELSEIF bPY > minY + 12 THEN
                bubChar = __BG_GLYPH_DEGREE: bubCol = __BG_COLOR_BRIGHT_WHITE
            ELSE
                bubChar = "o": bubCol = __BG_COLOR_BRIGHT_WHITE
            END IF
            COLOR bubCol, __BG_COLOR_BLACK
            _PRINTSTRING (bPX, bPY), bubChar
        END IF
    NEXT b

    ' --- Pass 4: Midground & Foreground Fish (in front of kelp!) ---
    FOR i = 1 TO ctx.fishtank.fishCount
        IF ctx.fishtank.fish(i).layer >= 1 THEN
            ctx.fishtank.fish(i).x = ctx.fishtank.fish(i).x + ctx.fishtank.fish(i).dx
            ctx.fishtank.fish(i).swimPhase = ctx.fishtank.fish(i).swimPhase + ctx.fishtank.fish(i).swimSpeed

            ' Screen boundary wrapping
            IF ctx.fishtank.fish(i).dx < 0! _ANDALSO ctx.fishtank.fish(i).x < CSNG(minX - 10) THEN
                ctx.fishtank.fish(i).x = CSNG(maxX + 2)
                ctx.fishtank.fish(i).baseY = CSNG(Math_GetRandomBetween(minY + 3, _MAX(minY + 3, maxY - 4)))
            ELSEIF ctx.fishtank.fish(i).dx > 0! _ANDALSO ctx.fishtank.fish(i).x > CSNG(maxX + 10) THEN
                ctx.fishtank.fish(i).x = CSNG(minX - 8)
                ctx.fishtank.fish(i).baseY = CSNG(Math_GetRandomBetween(minY + 3, _MAX(minY + 3, maxY - 4)))
            END IF

            DIM py AS LONG: py = CLNG(ctx.fishtank.fish(i).baseY + SIN(ctx.fishtank.fish(i).swimPhase) * 0.9!)
            DIM px AS LONG: px = CLNG(ctx.fishtank.fish(i).x)

            ' Tail wagging animation frame
            DIM tailWag AS LONG: tailWag = CLNG(ctx.fishtank.fish(i).swimPhase * 2.0!) MOD 2
            DIM fHead AS STRING, fBody AS STRING, fTail AS STRING

            SELECT CASE ctx.fishtank.fish(i).species
                CASE 0 ' Neon Tetra
                    IF ctx.fishtank.fish(i).dx < 0! THEN
                        fHead = "<*"
                        fBody = "=="
                        IF tailWag = 0 THEN fTail = ">{" ELSE fTail = ">~"
                    ELSE
                        IF tailWag = 0 THEN fTail = "}<" ELSE fTail = "~<"
                        fBody = "=="
                        fHead = "*>"
                    END IF

                CASE 1 ' Clownfish
                    IF ctx.fishtank.fish(i).dx < 0! THEN
                        fHead = "<o"
                        fBody = "()()"
                        IF tailWag = 0 THEN fTail = ">{" ELSE fTail = ">~"
                    ELSE
                        IF tailWag = 0 THEN fTail = "}<" ELSE fTail = "~<"
                        fBody = "()()"
                        fHead = "o>"
                    END IF

                CASE 2 ' Angelfish
                    IF ctx.fishtank.fish(i).dx < 0! THEN
                        fHead = "<+"
                        fBody = "###"
                        IF tailWag = 0 THEN fTail = "><" ELSE fTail = ">~"
                    ELSE
                        IF tailWag = 0 THEN fTail = "<>" ELSE fTail = "~<"
                        fBody = "###"
                        fHead = "+>"
                    END IF

                CASE ELSE ' Silver Guppy
                    IF ctx.fishtank.fish(i).dx < 0! THEN
                        fHead = "<"
                        fBody = __BG_GLYPH_BULLET
                        fTail = "{"
                    ELSE
                        fTail = "}"
                        fBody = __BG_GLYPH_BULLET
                        fHead = ">"
                    END IF
            END SELECT

            ' Render fish components with individual species colors
            DIM curX AS LONG: curX = px

            IF ctx.fishtank.fish(i).dx < 0! THEN
                ' Left-facing: Head -> Body -> Tail
                DIM cj AS LONG
                FOR cj = 1 TO LEN(fHead)
                    IF curX >= minX _ANDALSO curX <= maxX _ANDALSO py >= minY + 1 _ANDALSO py <= maxY - 2 THEN
                        COLOR ctx.fishtank.fish(i).cHead, __BG_COLOR_BLACK
                        _PRINTSTRING (curX, py), MID$(fHead, cj, 1)
                    END IF
                    curX = curX + 1
                NEXT cj

                FOR cj = 1 TO LEN(fBody)
                    IF curX >= minX _ANDALSO curX <= maxX _ANDALSO py >= minY + 1 _ANDALSO py <= maxY - 2 THEN
                        COLOR ctx.fishtank.fish(i).cBody, __BG_COLOR_BLACK
                        _PRINTSTRING (curX, py), MID$(fBody, cj, 1)
                    END IF
                    curX = curX + 1
                NEXT cj

                FOR cj = 1 TO LEN(fTail)
                    IF curX >= minX _ANDALSO curX <= maxX _ANDALSO py >= minY + 1 _ANDALSO py <= maxY - 2 THEN
                        COLOR ctx.fishtank.fish(i).cTail, __BG_COLOR_BLACK
                        _PRINTSTRING (curX, py), MID$(fTail, cj, 1)
                    END IF
                    curX = curX + 1
                NEXT cj
            ELSE
                ' Right-facing: Tail -> Body -> Head
                FOR cj = 1 TO LEN(fTail)
                    IF curX >= minX _ANDALSO curX <= maxX _ANDALSO py >= minY + 1 _ANDALSO py <= maxY - 2 THEN
                        COLOR ctx.fishtank.fish(i).cTail, __BG_COLOR_BLACK
                        _PRINTSTRING (curX, py), MID$(fTail, cj, 1)
                    END IF
                    curX = curX + 1
                NEXT cj

                FOR cj = 1 TO LEN(fBody)
                    IF curX >= minX _ANDALSO curX <= maxX _ANDALSO py >= minY + 1 _ANDALSO py <= maxY - 2 THEN
                        COLOR ctx.fishtank.fish(i).cBody, __BG_COLOR_BLACK
                        _PRINTSTRING (curX, py), MID$(fBody, cj, 1)
                    END IF
                    curX = curX + 1
                NEXT cj

                FOR cj = 1 TO LEN(fHead)
                    IF curX >= minX _ANDALSO curX <= maxX _ANDALSO py >= minY + 1 _ANDALSO py <= maxY - 2 THEN
                        COLOR ctx.fishtank.fish(i).cHead, __BG_COLOR_BLACK
                        _PRINTSTRING (curX, py), MID$(fHead, cj, 1)
                    END IF
                    curX = curX + 1
                NEXT cj
            END IF
        END IF
    NEXT i

    ' --- Pass 5: Living Seabed Gravel, Coral Anemones & Scuttling Crab ---
    DIM sx AS LONG
    FOR sx = minX TO maxX
        DIM gravelPattern AS LONG: gravelPattern = (sx * 7 + 13) MOD 11
        DIM gCh AS STRING, gCol AS LONG
        SELECT CASE gravelPattern
            CASE 0, 1: gCh = __BG_GLYPH_LIGHT_SHADE: gCol = __BG_COLOR_BROWN
            CASE 2, 3: gCh = __BG_GLYPH_MEDIUM_SHADE: gCol = __BG_COLOR_GRAY
            CASE 4: gCh = __BG_GLYPH_BULLET: gCol = __BG_COLOR_WHITE
            CASE 5, 6: gCh = ".": gCol = __BG_COLOR_BROWN
            CASE ELSE: gCh = __BG_GLYPH_LIGHT_SHADE: gCol = __BG_COLOR_GRAY
        END SELECT
        COLOR gCol, __BG_COLOR_BLACK
        _PRINTSTRING (sx, maxY), gCh
    NEXT sx

    ' Coral anemone tufts at fixed intervals along seabed
    DIM anemCol AS LONG
    FOR anemCol = minX + 8 TO maxX - 8 STEP 24
        DIM anemPhase AS SINGLE: anemPhase = SIN(ctx.fishtank.waterPhase + CSNG(anemCol) * 0.15!)
        DIM anemChar AS STRING
        IF anemPhase > 0.0! THEN anemChar = "\|/" ELSE anemChar = "/|\"
        COLOR __BG_COLOR_LIGHT_MAGENTA, __BG_COLOR_BLACK
        _PRINTSTRING (anemCol, maxY - 1), anemChar
    NEXT anemCol

    ' Cute little animated scuttling crab
    ctx.fishtank.crabX = ctx.fishtank.crabX + ctx.fishtank.crabDir
    IF ctx.fishtank.crabX < CSNG(minX + 4) THEN ctx.fishtank.crabDir = 0.12!
    IF ctx.fishtank.crabX > CSNG(maxX - 8) THEN ctx.fishtank.crabDir = -0.12!

    DIM crbX AS LONG: crbX = CLNG(ctx.fishtank.crabX)
    IF crbX >= minX _ANDALSO crbX + 4 <= maxX THEN
        DIM crabClaws AS STRING
        IF (CLNG(ctx.fishtank.waterPhase * 6.0!) MOD 2) = 0 THEN
            crabClaws = "(\_/)"
        ELSE
            crabClaws = "(\~/)"
        END IF
        COLOR __BG_COLOR_LIGHT_RED, __BG_COLOR_BLACK
        _PRINTSTRING (crbX, maxY - 1), crabClaws
    END IF
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
        ctx.viewport.rb.x = _MAX(_WIDTH, 1)
        ctx.viewport.rb.y = _MAX(_HEIGHT, 1)
    END IF

    ctx.size.x = Bounds2f_GetDiscreteWidth(ctx.viewport)
    ctx.size.y = Bounds2f_GetDiscreteHeight(ctx.viewport)

    IF ctx.size.x < 1! _ORELSE ctx.size.y < 1! THEN
        ctx.viewport.lt.x = 1!
        ctx.viewport.lt.y = 1!
        ctx.viewport.rb.x = _MAX(_WIDTH, 1)
        ctx.viewport.rb.y = _MAX(_HEIGHT, 1)
        ctx.size.x = _MAX(_WIDTH, 1)
        ctx.size.y = _MAX(_HEIGHT, 1)
    END IF

    __Background_InitializeStars ctx
    __Background_InitializeSnakes ctx
    __Background_InitializeFireworks ctx
    __Background_InitializeFire ctx
    __Background_InitializePlasma ctx
    __Background_InitializeBalls ctx
    __Background_InitializeMatrix ctx
    __Background_InitializeGrid ctx
    __Background_InitializeFishtank ctx

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
        CASE BACKGROUND_MODE_GRID: __Background_UpdateAndDrawGrid ctx
        CASE BACKGROUND_MODE_FISHTANK: __Background_UpdateAndDrawFishtank ctx
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
        CASE BACKGROUND_MODE_GRID: Background_GetModeName = "Cyber Grid"
        CASE BACKGROUND_MODE_FISHTANK: Background_GetModeName = "Fishtank"
        CASE ELSE: Background_GetModeName = "None"
    END SELECT
END FUNCTION
