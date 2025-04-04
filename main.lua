local GameState = {
    TITLE = "title",
    PLAYING = "playing",
    VICTORY = "victory",
    GAME_OVER = "game_over"
}

local currentState = GameState.TITLE

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    wf = require 'libraries/windfield'
    camera = require 'libraries.camera'
    anim8 = require 'libraries.anim8'
    sti = require 'libraries/sti'

    hud = require('hud')
    Player = require('player')
    Goblin = require('goblin')

    world = wf.newWorld(0, 0)
    world:addCollisionClass('Player')
    world:addCollisionClass('Folk', {enter = {'Player'}})
    world:addCollisionClass('ConvertedFolk', {ignores = {'Player', 'ConvertedFolk'}})
    world:addCollisionClass('Base', {enter = {'ConvertedFolk'}, ignores = {'Player'}})
    world:addCollisionClass('Dude')

    cam = camera()

    gameMap = sti('maps/map.lua')

    mapW = gameMap.width * gameMap.tilewidth
    mapH = gameMap.height * gameMap.tileheight

    local spawnX = mapW / 2
    local spawnY = mapH / 2

    player = Player:new(world, spawnX, spawnY)

    hud:load()

    titleScreen = {}
    titleScreen.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 72)
    titleScreen.buttonFont = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 36)
    titleScreen.bgImage = love.graphics.newImage('assets/UI/Banners/Title-Banner.png')
    titleScreen.buttonWidth = 200
    titleScreen.buttonHeight = 80

    conversionPhrases = {
        "I see the light!",
        "Show me the way!",
        "I understand now!",
        "Lead us forward!",
        "My eyes are opened!",
        "Together we rise!",
        "The truth reveals itself!",
        "A new purpose!",
        "I'll follow you!",
        "Enlightened at last!",
        "The path is clear!",
        "Count me in!",
        "What was I thinking before?",
        "This feels right!",
        "Let's change the world!"
    }

    base = {}
    base.bgImage = love.graphics.newImage('assets/Factions/Knights/Buildings/Castle_Blue.png')
    base.width = base.bgImage:getWidth()
    base.height = base.bgImage:getHeight() - 40
    base.collider = world:newBSGRectangleCollider(spawnX - 135, spawnY - 210, base.width, base.height, 10)
    base.collider:setFixedRotation(true)
    base.collider:setCollisionClass('Base')
    base.collider:setType('static')
    base.x = spawnX - 135
    base.y = spawnY - 250

    dude = {}
    dude.collider = world:newCircleCollider(spawnX + 155, spawnY + 90, 30)
    dude.collider:setFixedRotation(true)
    dude.collider:setCollisionClass('Dude')
    dude.collider:setType('static')
    dude.x = spawnX + 155
    dude.y = spawnY + 90
    dude.interactionRadius = 120
    dude.dialogText = "Great gallopin’ griffons! There’s folks in distress - time to save the day!"
    dude.dialog = nil
    dude.dialogTimerDuration = 4.0
    dude.dialogYOffset = -80

    dude.speadSheet = love.graphics.newImage('assets/Factions/Knights/Troops/Archer/Archer_Blue.png')
    dude.grid = anim8.newGrid(192, 192, dude.speadSheet:getWidth(), dude.speadSheet:getHeight())
    dude.animations = {}
    dude.animations.idle = anim8.newAnimation(dude.grid('1-6', 1), 0.1)
    dude.anim = dude.animations.idle

    folks = {}
    folkSprite = love.graphics.newImage('assets/Factions/Knights/Troops/Pawn/Yellow/Pawn_Yellow.png')
    folkSpriteConverted = love.graphics.newImage('assets/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png')
    folkGrid = anim8.newGrid(192, 192, folkSprite:getWidth(), folkSprite:getHeight())
    folkGridConverted = anim8.newGrid(192, 192, folkSpriteConverted:getWidth(), folkSpriteConverted:getHeight())

    folkAnimations = {}
    folkAnimations.idle = anim8.newAnimation(folkGrid('1-6', 1), 0.1)
    folkAnimations.walk = anim8.newAnimation(folkGrid('1-6', 2), 0.1)

    folkAnimationsConverted = {}
    folkAnimationsConverted.idle = anim8.newAnimation(folkGridConverted('1-6', 1), 0.1)
    folkAnimationsConverted.walk = anim8.newAnimation(folkGridConverted('1-6', 2), 0.1)

    sounds = {}
    sounds.conversion = love.audio.newSource("sounds/wololo.mp3", "static")
    sounds.conversion:setVolume(0.3)
    sounds.steps = {
        love.audio.newSource("sounds/step_grass-1.flac", "static"),
        love.audio.newSource("sounds/step_grass-2.flac", "static")
    }

    for _, step in ipairs(sounds.steps) do
        step:setVolume(0.4)
    end
    sounds.stepTimer = 0
    sounds.stepDelay = 0.3
    sounds.lastStepIndex = 0

    sounds.goblinDetections = {
        love.audio.newSource("sounds/goblin/goblin-2.wav", "static"),
        love.audio.newSource("sounds/goblin/goblin-6.wav", "static")
    }
    sounds.goblinDies = {
        love.audio.newSource("sounds/goblin/goblin-3.wav", "static"),
    }

    for _, goblinDie in ipairs(sounds.goblinDies) do
        goblinDie:setVolume(0.4)
    end
    for _, goblinDetection in ipairs(sounds.goblinDetections) do
        goblinDetection:setVolume(0.4)
    end

    sounds.music = love.audio.newSource("sounds/music.mp3", "static")
    sounds.music:setVolume(0.2)
    sounds.music:setLooping(true)
    sounds.music:play()

    sounds.hits = {
        love.audio.newSource("sounds/hits/hit01.mp3.flac", "static"),
        love.audio.newSource("sounds/hits/hit02.mp3.flac", "static"),
        love.audio.newSource("sounds/hits/hit03.mp3.flac", "static")
    }

    for _, hit in ipairs(sounds.hits) do
        hit:setVolume(0.4)
    end

    victory = {}
    victory.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 48)
    victory.smallFont = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 24)
    victory.isActive = false
    victory.buttonWidth = 200
    victory.buttonHeight = 60

    gameOver = {}
    gameOver.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 48)
    gameOver.smallFont = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 24)
    gameOver.buttonWidth = 200
    gameOver.buttonHeight = 60

    dialogBox = {}
    dialogBox.bgImage = love.graphics.newImage('assets/UI/Buttons/Button_Disable_3Slides.png')
    dialogBox.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 16)

    local imgW = dialogBox.bgImage:getWidth()
    local imgH = dialogBox.bgImage:getHeight()
    local sliceWidth = imgW / 3

    dialogBox.leftSlice = love.graphics.newQuad(0,0, sliceWidth, imgH, imgW, imgH)
    dialogBox.middleSlice = love.graphics.newQuad(sliceWidth,0, sliceWidth, imgH, imgW, imgH)
    dialogBox.rightSlice = love.graphics.newQuad(sliceWidth*2,0, sliceWidth, imgH, imgW, imgH)
    dialogBox.sliceWidth = sliceWidth

    effects = {}
    effects.explosionSprite = love.graphics.newImage('assets/Effects/Explosions.png')
    effects.explosionGrid = anim8.newGrid(192, 192, effects.explosionSprite:getWidth(), effects.explosionSprite:getHeight())
    effects.explosionAnimation = anim8.newAnimation(effects.explosionGrid('1-9', 1), 0.1)
    effects.activeExplosions = {}

    walls = {}
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType('static')
            wall.width = obj.width
            wall.height = obj.height
            table.insert(walls, wall)
        end
    end

    Goblin:load(world, sounds)
    spawnFolks(hud.converted.totalFolks)
    Goblin:spawn(world, hud.converted.totalFolks, mapW, mapH, walls) -- Spawn goblins via the module
end

function love.update(dt)
    if currentState == GameState.TITLE then
        return
    end

    for i = #effects.activeExplosions, 1, -1 do
        local explosion = effects.activeExplosions[i]
        explosion.animation:update(dt)

        if explosion.isDone then
            table.remove(effects.activeExplosions, i)
        end
    end

    if currentState == GameState.PLAYING then
        hud:update(dt)
    end

    dude.anim:update(dt)

    player:update(dt)

    if player.life <= 0 then
        player.life = 0
        gameTimer.active = false
        currentState = GameState.GAME_OVER
    end

    if player.isAttacking or (player.collider:getLinearVelocity()) == 0 then
        sounds.stepTimer = 0
    else
        sounds.stepTimer = sounds.stepTimer + dt
        if sounds.stepTimer >= sounds.stepDelay then
            sounds.stepTimer = 0
            sounds.stepDelay = love.math.random(25, 35) / 100

            local nextStepIndex = sounds.lastStepIndex % #sounds.steps + 1
            sounds.lastStepIndex = nextStepIndex

            local nextStep = sounds.steps[nextStepIndex]

            local stepClone = nextStep:clone()
            stepClone:setPitch(love.math.random(80, 120) / 100)
            stepClone:play()
        end
    end

    world:update(dt)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    local dx_dude = player.x - dude.x
    local dy_dude = player.y - dude.y
    local distance_to_dude = math.sqrt(dx_dude * dx_dude + dy_dude * dy_dude)

    if distance_to_dude < dude.interactionRadius then
        if not dude.dialog then
            dude.dialog = {
                text = dude.dialogText,
                timer = dude.dialogTimerDuration,
                y_offset = dude.dialogYOffset
            }
        end
    else
        dude.dialog = nil
    end

    if dude.dialog then
        dude.dialog.timer = dude.dialog.timer - dt
        if dude.dialog.timer <= 0 then
            dude.dialog = nil
        end
    end

    for i = #folks, 1, -1 do
        local folk = folks[i]
        if base.collider:enter('ConvertedFolk') and folk.converted then
            local collisionData = base.collider:getEnterCollisionData('ConvertedFolk')
            if collisionData and collisionData.collider == folk.collider then
                hud.converted.peopleConverted = hud.converted.peopleConverted - 1
                hud.converted.peopleSaved = hud.converted.peopleSaved + 1

                local conversionSound = sounds.conversion:clone()
                conversionSound:play()

                local randomPhrase = conversionPhrases[love.math.random(#conversionPhrases)]
                showDialog(folk, randomPhrase)

                folk.collider:destroy()
                table.remove(folks, i)

                if hud.converted.peopleSaved >= hud.converted.totalFolks then
                    currentState = GameState.VICTORY
                    victory.isActive = true
                    gameTimer.active = false
                end
                goto continue_folk_loop -- Skip rest of update for this removed folk
            end
        end

        if player.collider:enter('Folk') and not folk.converted then
             local collisionData = player.collider:getEnterCollisionData('Folk')
             if collisionData and collisionData.collider == folk.collider then
                folk.converted = true
                folk.sprite = folkSpriteConverted
                folk.animations = {
                    idle = folkAnimationsConverted.idle:clone(),
                    walk = folkAnimationsConverted.walk:clone()
                }
                folk.anim = folk.animations.idle
                folk.facingLeft = false
                folk.conversionOrder = hud.converted.peopleConverted
                folk.followDelay = folk.conversionOrder * 0.5
                folk.conversionTime = love.timer.getTime()

                hud.converted.peopleConverted = hud.converted.peopleConverted + 1

                folk.collider:setCollisionClass('ConvertedFolk')

                local conversionSound = sounds.conversion:clone()
                conversionSound:play()

                local randomPhrase = conversionPhrases[love.math.random(#conversionPhrases)]
                showDialog(folk, randomPhrase)
             end
        end

        folk.x = folk.collider:getX()
        folk.y = folk.collider:getY()

        folk.anim:update(dt)

        if folk.dialog then
            folk.dialog.timer = folk.dialog.timer - dt
            if folk.dialog.timer <= 0 then
                folk.dialog = nil
            end
        end

        if folk.converted then
            local currentTime = love.timer.getTime()
            if currentTime - folk.conversionTime >= folk.followDelay then
                local targetX, targetY

                if folk.conversionOrder == 0 then
                    targetX = player.x
                    targetY = player.y
                else
                    local folkToFollow = nil
                    for _, otherFolk in ipairs(folks) do
                        if otherFolk.converted and otherFolk.conversionOrder == folk.conversionOrder - 1 then
                            folkToFollow = otherFolk
                            break
                        end
                    end
                    if folkToFollow then
                       targetX = folkToFollow.x
                       targetY = folkToFollow.y
                    end
                end

                if targetX and targetY then
                    local dx = targetX - folk.x
                    local dy = targetY - folk.y
                    local distance = math.sqrt(dx*dx + dy*dy)

                    local minDistance = 60
                    local maxDistance = 300
                    local teleportDistance = 600

                    if distance > minDistance then
                        dx = dx / distance
                        dy = dy / distance

                        local followSpeed = player.speed
                        if distance > maxDistance then
                            followSpeed = player.speed * 1.2
                        end

                        folk.collider:setLinearVelocity(dx * followSpeed, dy * followSpeed)
                        folk.anim = folk.animations.walk
                        folk.facingLeft = dx < 0
                    else
                        folk.collider:setLinearVelocity(0, 0)
                        folk.anim = folk.animations.idle
                    end

                    if distance > teleportDistance then
                        local teleportOffset = 100
                        local teleportAngle = love.math.random() * math.pi * 2
                        local telportX = targetX + math.cos(teleportAngle) * teleportOffset
                        local telportY = targetY + math.sin(teleportAngle) * teleportOffset

                        folk.collider:setPosition(telportX, telportY)
                        folk.x = telportX
                        folk.y = telportY

                        showDialog(folk, "Catching up!")
                    end
                end
            else
                folk.collider:setLinearVelocity(0, 0)
                folk.anim = folk.animations.idle
            end
        else
            folk.collider:setLinearVelocity(0, 0)
            folk.anim = folk.animations.idle
        end
        ::continue_folk_loop::
    end

    Goblin:update(dt, player, mapW, mapH) -- Pass necessary parameters

    cam:lookAt(player.x, player.y)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if cam.x < w/2 then
        cam.x = w/2
    end
    if cam.y < h/2 then
        cam.y = h/2
    end

    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end
    if cam.y > (mapH - h/2) then
        cam.y = (mapH - h/2)
    end

end

function love.draw()
    if currentState == GameState.TITLE then
        drawTitleScreen()
        return
    elseif currentState == GameState.VICTORY then
        drawVictoryScreen()
        return
    elseif currentState == GameState.GAME_OVER then
        drawGameOverScreen()
        return
    end


    cam:attach()
        gameMap:drawLayer(gameMap.layers["Pre-Base"])
        gameMap:drawLayer(gameMap.layers["Base"])
        gameMap:drawLayer(gameMap.layers["Shadows"])
        gameMap:drawLayer(gameMap.layers["Cliffs"])
        gameMap:drawLayer(gameMap.layers["Bridges"])
        gameMap:drawLayer(gameMap.layers["Decor"])

        love.graphics.draw(base.bgImage, base.x, base.y)

        dude.anim:draw(dude.speadSheet, dude.x, dude.y, nil, nil, nil, 96, 96)


        for _, folk in ipairs(folks) do
            local sprite = folk.converted and folkSpriteConverted or folkSprite
            local scaleX = folk.facingLeft and -1 or 1
            folk.anim:draw(sprite, folk.x, folk.y, nil, scaleX, 1, 96, 96)
        end

        Goblin:draw()

        player:draw()

        for _, explosion in ipairs(effects.activeExplosions) do
            explosion.animation:draw(effects.explosionSprite, explosion.x, explosion.y, nil, nil, nil, 96, 96)
        end

        for _, folk in ipairs(folks) do
            if folk.dialog then
                drawDialog(folk)
            end
        end

        if dude.dialog then
            drawDialog(dude)
        end

        -- world:draw(.6)
    cam:detach()

    drawHud()
end

function drawTitleScreen()
    love.graphics.setColor(0.1, 0.15, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(titleScreen.font)
    local title = "Mane Attraction"
    local titleW = titleScreen.font:getWidth(title)
    local titleH = titleScreen.font:getHeight()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local bannerScale = 1.5
    local bannerW = titleScreen.bgImage:getWidth() * bannerScale
    local bannerH = titleScreen.bgImage:getHeight() * bannerScale
    local bannerX = (screenW - bannerW) / 2
    local bannerY = screenH / 3.5 - bannerH / 2

    love.graphics.draw(titleScreen.bgImage, bannerX, bannerY, 0, bannerScale, bannerScale)

    love.graphics.setColor(0.086, 0.11, 0.18, 1)
    love.graphics.print(title, (screenW - titleW) / 2, screenH / 4 - titleH / 2)

    love.graphics.setFont(titleScreen.buttonFont)
    local buttonText = "Play"
    local buttonX = (screenW - titleScreen.buttonWidth) / 2
    local buttonY = screenH * 0.6

    love.graphics.setColor(0.2, 0.4, 0.8, 1)
    love.graphics.rectangle("fill", buttonX, buttonY, titleScreen.buttonWidth, titleScreen.buttonHeight, 10)

    love.graphics.setColor(1, 1, 1, 1)
    local btnTextW = titleScreen.buttonFont:getWidth(buttonText)
    local btnTextH = titleScreen.buttonFont:getHeight()
    love.graphics.print(buttonText,
        buttonX + (titleScreen.buttonWidth - btnTextW) / 2,
        buttonY + (titleScreen.buttonHeight - btnTextH) / 2
    )
end


function drawVictoryScreen()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(victory.font)
    local victoryText = "Victory!"
    local textW = victory.font:getWidth(victoryText)
    local textH = victory.font:getHeight()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    love.graphics.print(victoryText, (screenW - textW) / 2, screenH / 6)

    love.graphics.setFont(gameOver.smallFont)
    local statsText = string.format("Time: %02d:%02d",
        math.floor(gameTimer.time / 60),
        math.floor(gameTimer.time % 60)
    )
    local statsW = gameOver.smallFont:getWidth(statsText)
    love.graphics.printf(statsText, (screenW - statsW) / 2, screenH / 3, statsW, "left")

    love.graphics.setFont(victory.smallFont)
    local buttonText = "Play Again"
    local buttonX = (screenW - victory.buttonWidth) / 2
    local buttonY = screenH * 0.6

    love.graphics.setColor(0.2, 0.4, 0.8, 1)
    love.graphics.rectangle("fill", buttonX, buttonY, victory.buttonWidth, victory.buttonHeight, 10)

    love.graphics.setColor(1, 1, 1, 1)
    local btnTextW = victory.smallFont:getWidth(buttonText)
    local btnTextH = victory.smallFont:getHeight()
    love.graphics.print(buttonText,
        buttonX + (victory.buttonWidth - btnTextW) / 2,
        buttonY + (victory.buttonHeight - btnTextH) / 2
    )
end

function drawGameOverScreen()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(gameOver.font)
    local gameOverText = "Game Over"
    local textW = gameOver.font:getWidth(gameOverText)
    local textH = gameOver.font:getHeight()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    love.graphics.print(gameOverText, (screenW - textW) / 2, screenH / 6)

    love.graphics.setFont(gameOver.smallFont)
    local statsText = string.format("Folks Converted: %d\nFolks Saved: %d/%d\nTime: %02d:%02d",
        hud.converted.peopleConverted,
        hud.converted.peopleSaved,
        hud.converted.totalFolks,
        math.floor(gameTimer.time / 60),
        math.floor(gameTimer.time % 60)
    )
    local statsW = gameOver.smallFont:getWidth(statsText)
    love.graphics.printf(statsText, (screenW - statsW) / 2, screenH / 3, statsW, "left")

    local buttonText = "Try Again"
    local buttonX = (screenW - gameOver.buttonWidth) / 2
    local buttonY = screenH * 0.7

    love.graphics.setColor(0.2, 0.4, 0.8, 1)
    love.graphics.rectangle("fill", buttonX, buttonY, gameOver.buttonWidth, gameOver.buttonHeight, 10)

    love.graphics.setColor(1, 1, 1, 1)
    local btnTextW = gameOver.smallFont:getWidth(buttonText)
    local btnTextH = gameOver.smallFont:getHeight()
    love.graphics.print(buttonText,
        buttonX + (gameOver.buttonWidth - btnTextW) / 2,
        buttonY + (gameOver.buttonHeight - btnTextH) / 2
    )
end

function love.mousepressed(x, y, button)
    if currentState == GameState.TITLE and button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local buttonX = (screenW - victory.buttonWidth) / 2
        local buttonY = screenH * 0.6

        if x >= buttonX and x <= buttonX + victory.buttonWidth and
           y >= buttonY and y <= buttonY + victory.buttonHeight then
            currentState = GameState.PLAYING
            resetGame()
        end
    elseif currentState == GameState.VICTORY or currentState == GameState.GAME_OVER and button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local buttonWidth = currentState == GameState.VICTORY and victory.buttonWidth or gameOver.buttonWidth
        local buttonHeight = currentState == GameState.VICTORY and victory.buttonHeight or gameOver.buttonHeight
        local buttonY = currentState == GameState.VICTORY and screenH * 0.6 or screenH * 0.7
        local buttonX = (screenW - buttonWidth) / 2

        if x >= buttonX and x <= buttonX + buttonWidth and
           y >= buttonY and y <= buttonY + buttonHeight then
            resetGame()
        end
    end
end

function resetGame()
    currentState = GameState.PLAYING
    victory.isActive = false
    hud:reset()
    player.life = player.maxLife

    for _, folk in ipairs(folks) do
        if folk.collider and folk.collider.destroy then
             folk.collider:destroy()
        end
    end
    folks = {}

    Goblin:reset()

    spawnFolks(hud.converted.totalFolks)
    Goblin:spawn(world, hud.converted.totalFolks, mapW, mapH, walls)

    local spawnX = mapW / 2
    local spawnY = mapH / 2
    player.collider:setPosition(spawnX, spawnY)
end

function love.keypressed(key)
    if key == "z" then
        if sounds.music:isPlaying() == true then
            sounds.music:stop()
        else
            sounds.music:play()
        end
    end

    if key == "return" or key == "kpenter" then
        if currentState == GameState.TITLE then
            currentState = GameState.PLAYING
            resetGame()
        elseif currentState == GameState.VICTORY or currentState == GameState.GAME_OVER then
            resetGame()
        end
    end

    if key == "space" then
        performAttack("normal")
    elseif key == "p" and not player.isAttacking and player.powerAttackCooldown <= 0 then
        performAttack("power")
        player.powerAttackCooldown = player.attackSettings.powerAttackCooldown
    end
end

function performAttack(attackType)
    if player:performAttack(attackType) then
        checkAttackHits(attackType)
    end
end

function checkAttackHits(attackType)
    local attackRange = attackType == "normal" and player.attackSettings.normalAttackRange or player.attackSettings.powerAttackRange

    local hit = Goblin:checkHits(player.x, player.y, attackRange, player.lastDirection, createExplosion)
end


function drawHud()
    hud:draw(player)
end


function spawnFolks(count)
    local margin = 200
    local entityRadius = 30
    local maxAttemps = 50
    local centerExclusionRadius = 1000

    local knownPositions = {
        {x = 140 * 64 + 15, y = 55 * 64 + 15},
        {x = 158 * 64 + 15, y = 65 * 64 + 15},
        {x = 192 * 64 + 15, y = 63 * 64 + 15},
        {x = 140 * 64 + 15, y = 21 * 64 + 15},
        {x = 46 * 64 + 15, y = 3 * 64 + 15},
    }

    for i, pos in ipairs(knownPositions) do
        local folk = {}
        folk.collider = world:newCircleCollider(pos.x, pos.y, entityRadius)
        folk.collider:setFixedRotation(true)
        folk.collider:setCollisionClass('Folk')

        folk.x = pos.x
        folk.y = pos.y
        folk.converted = false
        folk.sprite = folkSprite
        folk.animations = {
            idle = folkAnimations.idle:clone(),
            walk = folkAnimations.walk:clone()
        }
        folk.anim = folk.animations.idle

        table.insert(folks, folk)
    end

    for i = #knownPositions + 1, count do
        local folk = {}
        local validPosition = false
        local attemps = 0
        local x,y

        while not validPosition and attemps < maxAttemps do
            attemps = attemps + 1
            x = love.math.random(margin, mapW - margin)
            y = love.math.random(margin, mapH - margin)

            local distanceFromCenter = math.sqrt(
                (x - mapW/2)^2 +
                (y - mapH/2)^2
            )

            validPosition = distanceFromCenter > centerExclusionRadius
            if validPosition then
                for _, wall in ipairs(walls) do
                    local wx, wy = wall:getPosition()
                    local ww, wh = wall.width, wall.height

                    local closestX = math.max(wx - ww/2, math.min(x, wx + ww/2))
                    local closestY = math.max(wy - wh/2, math.min(y, wy + wh/2))

                    local distanceX = x - closestX
                    local distanceY = y - closestY
                    local distanceSquared = distanceX * distanceX + distanceY * distanceY

                    if distanceSquared < entityRadius * entityRadius then
                        validPosition = false
                        break
                    end
                end
            end
        end

        folk.collider = world:newCircleCollider(x, y, entityRadius)
        folk.collider:setFixedRotation(true)
        folk.collider:setCollisionClass('Folk')

        folk.x = x
        folk.y = y
        folk.converted = false
        folk.sprite = folkSprite
        folk.animations = {
            idle = folkAnimations.idle:clone(),
            walk = folkAnimations.walk:clone()
        }
        folk.anim = folk.animations.idle

        table.insert(folks, folk)
    end
end

function showDialog(entity, text)
    entity.dialog = {
        text = text,
        timer = 2,
        y_offset = entity == dude and dude.dialogYOffset or -60 -- Adjust offset based on entity
    }
end

function drawDialog(entity)
    if not entity.dialog then return end

    local prevFont = love.graphics.getFont()
    love.graphics.setFont(dialogBox.font)

    local text = entity.dialog.text
    local textWidth = dialogBox.font:getWidth(text) -- Use dialog font for width calc
    local textHeight = dialogBox.font:getHeight()

    local padding = 20
    local bgHeight = dialogBox.bgImage:getHeight()
    local minWidth = textWidth + ( padding * 2 )

    local totalSlices = math.max(3, math.ceil(minWidth / dialogBox.sliceWidth))
    local bgWidth = totalSlices * dialogBox.sliceWidth

    local bgX = entity.x - bgWidth/2
    local bgY = entity.y + entity.dialog.y_offset - bgHeight/2

    local alpha = math.min(1, entity.dialog.timer * 2) -- Fade out effect
    love.graphics.setColor(1, 1, 1, alpha)

    love.graphics.draw(dialogBox.bgImage, dialogBox.leftSlice, bgX, bgY)

    local middleWidth = bgWidth - (dialogBox.sliceWidth * 2)
    local middleScale = middleWidth / dialogBox.sliceWidth
    love.graphics.draw(dialogBox.bgImage, dialogBox.middleSlice, bgX + dialogBox.sliceWidth, bgY, 0, middleScale, 1)

    love.graphics.draw(dialogBox.bgImage, dialogBox.rightSlice, bgX + bgWidth - dialogBox.sliceWidth, bgY)

    local textX = bgX + (bgWidth - textWidth)/2 + 8 -- Centering text
    local textY = bgY + bgHeight/2 - textHeight/2 - 3

    love.graphics.setColor(0.086, 0.11, 0.18, alpha) -- Text color
    love.graphics.print(text, textX, textY)

    love.graphics.setFont(prevFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function createExplosion(x, y)
    local explosion = {
        x = x,
        y = y,
        animation = effects.explosionAnimation:clone(),
        isDone = false
    }

    explosion.animation.onLoop = function(anim)
        explosion.isDone = true
    end

    table.insert(effects.activeExplosions, explosion)
end
