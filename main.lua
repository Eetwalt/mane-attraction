local GameState = {
    TITLE = "title",
    PLAYING = "playing",
    VICTORY = "victory",
    GAME_OVER = "game_over"
}

local currentState = GameState.TITLE

local gameTimer = {
    time = 0,
    active = false,
    font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 32)
}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    

    wf = require 'libraries/windfield'
    camera = require 'libraries.camera'
    anim8 = require 'libraries.anim8'
    sti = require 'libraries/sti'

    hud = require('hud')
    Player = require('player')
    Goblin = require('goblin')
    Folk = require('folk')

    world = wf.newWorld(0, 0)
    world:addCollisionClass('Player')
    world:addCollisionClass('Base', {ignores = {'Player'}})
    world:addCollisionClass('Dude')
    world:addCollisionClass('Goblin')
    world:addCollisionClass('Folk', {enter = {'Player'}})
    world:addCollisionClass('ConvertedFolk', {
        ignores = {'Player', 'ConvertedFolk'},
        enter = {'Base'}
    })

    cam = camera()

    gameMap = sti('maps/map.lua')

    mapW = gameMap.width * gameMap.tilewidth
    mapH = gameMap.height * gameMap.tileheight

    local spawnX = mapW / 2
    local spawnY = mapH / 2

    player = Player:new(world, spawnX, spawnY)

    hud:load(gameTimer)

    titleScreen = {}
    titleScreen.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 72)
    titleScreen.buttonFont = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 36)
    titleScreen.bgImage = love.graphics.newImage('assets/UI/Banners/Title-Banner.png')
    titleScreen.buttonWidth = 200
    titleScreen.buttonHeight = 80

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

    local knownFolkPositions = {
        {x = 140 * 64 + 15, y = 55 * 64 + 15},
        {x = 158 * 64 + 15, y = 65 * 64 + 15},
        {x = 192 * 64 + 15, y = 63 * 64 + 15},
        {x = 140 * 64 + 15, y = 21 * 64 + 15},
        {x = 46 * 64 + 15, y = 3 * 64 + 15},
    }

    Folk:load(sounds, conversionPhrases)
    Goblin:load(sounds)
    Folk:spawn(world, hud.converted.totalFolks, mapW, mapH, walls, knownFolkPositions)
    Goblin:spawn(world, hud.converted.totalFolks, mapW, mapH, walls)
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
        if gameTimer then gameTimer.active = false end
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
           showDialog(dude, dude.dialogText)
           if dude.dialog then dude.dialog.timer = dude.dialogTimerDuration end
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

    local victoryMet = Folk:update(dt, player, base, hud, showDialog)

    if victoryMet and currentState == GameState.PLAYING then
        currentState = GameState.VICTORY
        victory.isActive = true
        if gameTimer then gameTimer.active = false end
    end

    Goblin:update(dt, player, mapW, mapH)

    cam:lookAt(player.x, player.y)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    cam.x = math.max(w/2, math.min(cam.x, mapW - w/2))
    cam.y = math.max(h/2, math.min(cam.y, mapH - h/2))

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

        Folk:draw()

        Goblin:draw()

        player:draw()

        for _, explosion in ipairs(effects.activeExplosions) do
            explosion.animation:draw(effects.explosionSprite, explosion.x, explosion.y, nil, nil, nil, 96, 96)
        end

        for _, folk in ipairs(Folk:getList()) do
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
    local timeStr = "N/A"
    if gameTimer then
       timeStr = string.format("%02d:%02d",
            math.floor(gameTimer.time / 60),
            math.floor(gameTimer.time % 60)
        )
    end
    local statsText = string.format("Time: %s", timeStr)
    local statsW = gameOver.smallFont:getWidth(statsText)
    love.graphics.printf(statsText, 0, screenH / 3, screenW, "center") -- Use printf for centering

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
     local timeStr = "N/A"
    if gameTimer then
       timeStr = string.format("%02d:%02d",
            math.floor(gameTimer.time / 60),
            math.floor(gameTimer.time % 60)
        )
    end
    local statsText = string.format("Folks Converted: %d\nFolks Saved: %d/%d\nTime: %s",
        hud.converted.peopleConverted,
        hud.converted.peopleSaved,
        hud.converted.totalFolks,
        timeStr
    )
    local statsW = gameOver.smallFont:getWidth(statsText) -- Approx width for centering
    love.graphics.printf(statsText, 0, screenH / 3, screenW, "center") -- Use printf for centering

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
        local buttonX = (screenW - titleScreen.buttonWidth) / 2 -- Use titleScreen dimensions
        local buttonY = screenH * 0.6
        local buttonWidth = titleScreen.buttonWidth
        local buttonHeight = titleScreen.buttonHeight

        if x >= buttonX and x <= buttonX + buttonWidth and
           y >= buttonY and y <= buttonY + buttonHeight then
            currentState = GameState.PLAYING
            resetGame()
        end
    elseif (currentState == GameState.VICTORY or currentState == GameState.GAME_OVER) and button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local buttonWidth = (currentState == GameState.VICTORY) and victory.buttonWidth or gameOver.buttonWidth
        local buttonHeight = (currentState == GameState.VICTORY) and victory.buttonHeight or gameOver.buttonHeight
        local buttonY = (currentState == GameState.VICTORY) and screenH * 0.6 or screenH * 0.7
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
    player.invulnerableTime = 0

    Folk:reset()
    Goblin:reset()

    local knownFolkPositions = {
        {x = 140 * 64 + 15, y = 55 * 64 + 15},
        {x = 158 * 64 + 15, y = 65 * 64 + 15},
        {x = 192 * 64 + 15, y = 63 * 64 + 15},
        {x = 140 * 64 + 15, y = 21 * 64 + 15},
        {x = 46 * 64 + 15, y = 3 * 64 + 15},
    }

    Folk:spawn(world, hud.converted.totalFolks, mapW, mapH, walls, knownFolkPositions)
    Goblin:spawn(world, hud.converted.totalFolks, mapW, mapH, walls)

    local spawnX = mapW / 2
    local spawnY = mapH / 2
    player.collider:setPosition(spawnX, spawnY)
    player.collider:setLinearVelocity(0, 0)

    if gameTimer then
       gameTimer.time = 0
       gameTimer.active = true
    end
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

    if currentState == GameState.PLAYING then
        if key == "space" then
            performAttack("normal")
        elseif key == "p" and not player.isAttacking and player.powerAttackCooldown <= 0 then
            performAttack("power")
        end
    end
end

function performAttack(attackType)
    if player:performAttack(attackType) then
        checkAttackHits(attackType)
    end
end

function checkAttackHits(attackType)
    local attackRange = attackType == "normal" and player.attackSettings.normalAttackRange or player.attackSettings.powerAttackRange

    Goblin:checkHits(player.x, player.y, attackRange, player.lastDirection, createExplosion)
end


function drawHud()
    hud:draw(player)
end

function showDialog(entity, text)
    local y_offset = -60
    if entity == dude then y_offset = dude.dialogYOffset end

    entity.dialog = {
        text = text,
        timer = 2,
        y_offset = y_offset
    }
end

function drawDialog(entity)
    if not entity.dialog then return end

    local prevFont = love.graphics.getFont()
    love.graphics.setFont(dialogBox.font)

    local text = entity.dialog.text
    local textWidth = dialogBox.font:getWidth(text)
    local textHeight = dialogBox.font:getHeight()

    local padding = 20
    local bgHeight = dialogBox.bgImage:getHeight()
    local minWidth = textWidth + ( padding * 2 )

    local totalSlices = math.max(3, math.ceil(minWidth / dialogBox.sliceWidth))
    local bgWidth = totalSlices * dialogBox.sliceWidth

    local bgX = entity.x - bgWidth/2
    local bgY = entity.y + entity.dialog.y_offset - bgHeight/2

    local alpha = math.min(1, entity.dialog.timer * 2)
    love.graphics.setColor(1, 1, 1, alpha)

    love.graphics.draw(dialogBox.bgImage, dialogBox.leftSlice, bgX, bgY)

    local middleWidth = bgWidth - (dialogBox.sliceWidth * 2)
    local middleScale = middleWidth / dialogBox.sliceWidth
    love.graphics.draw(dialogBox.bgImage, dialogBox.middleSlice, bgX + dialogBox.sliceWidth, bgY, 0, middleScale, 1)

    love.graphics.draw(dialogBox.bgImage, dialogBox.rightSlice, bgX + bgWidth - dialogBox.sliceWidth, bgY)

    local textX = bgX + (bgWidth - textWidth)/2 + 8
    local textY = bgY + bgHeight/2 - textHeight/2 - 3

    love.graphics.setColor(0.086, 0.11, 0.18, alpha)
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
