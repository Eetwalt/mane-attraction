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

wf = require 'libraries/windfield'
camera = require 'libraries.camera'
anim8 = require 'libraries.anim8'
sti = require 'libraries/sti'

hud = require('src.hud')

Player = require('src.entities.player')
Goblin = require('src.entities.goblin')
Folk = require('src.entities.folk')
Dude = require('src.entities.dude')

TitleScreen = require('src.screens.title_screen')
GameOverScreen = require('src.screens.game_over_screen')
VictoryScreen = require('src.screens.victory_screen')

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

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

    spawnX = mapW / 2
    spawnY = mapH / 2

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

    sounds.grunts = {
        love.audio.newSource("sounds/grunts/grunt_4.wav", "static"),
        love.audio.newSource("sounds/grunts/grunt_12.wav", "static"),
        love.audio.newSource("sounds/grunts/grunt_21.wav", "static"),
    }

    sounds.gameover = love.audio.newSource("sounds/losetrumpet.mp3", "static")

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


    local goblinHouse = gameMap.getTileProperties

    TitleScreen:load()
    hud:load(gameTimer)
    player = Player:new(world, spawnX, spawnY, sounds)
    Dude:load(world, spawnX, spawnY)
    Folk:load(sounds)
    Goblin:load(sounds)
    Folk:spawn(world, hud.converted.totalFolks, mapW, mapH, walls)
    Goblin:spawn(world, hud.converted.totalFolks, mapW, mapH, walls)
    GameOverScreen:load(sounds)
    VictoryScreen:load()
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

    Dude:update(dt, player, showDialog)

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
        TitleScreen:draw()
        return
    elseif currentState == GameState.VICTORY then
        VictoryScreen:draw(gameTimer)
        return
    elseif currentState == GameState.GAME_OVER then
        GameOverScreen:draw(gameTimer, hud)
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

        Dude:draw()
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

        if Dude.dialog then
            drawDialog(Dude)
        end

        -- world:draw(.6)
    cam:detach()

    drawHud()
end

function love.mousepressed(x, y, button)
    local nextState = nil
    if currentState == GameState.TITLE then
        nextState = TitleScreen:mousepressed(x, y, button, GameState)
    elseif currentState == GameState.VICTORY then
        nextState = VictoryScreen:mousepressed(x, y, button, GameState)
    elseif currentState == GameState.GAME_OVER then
        nextState = GameOverScreen:mousepressed(x, y, button, GameState)
    elseif currentState == GameState.PLAYING then
        -- nothing to do
    end

    if nextState == GameState.PLAYING then
        resetGame()
    elseif nextState == "reset" then
        resetGame()
    end
end

function love.keypressed(key)
    if key == "z" then
        if sounds.music:isPlaying() == true then
            sounds.music:stop()
        else
            sounds.music:play()
        end
        return
    end

    local nextState = nil
    if currentState == GameState.TITLE then
        nextState = TitleScreen:keypressed(key, GameState)
    elseif currentState == GameState.VICTORY then
        nextState = VictoryScreen:keypressed(key, GameState)
    elseif currentState == GameState.GAME_OVER then
        nextState = GameOverScreen:keypressed(key, GameState)
    elseif currentState == GameState.PLAYING then
        if key == "space" then
            performAttack("normal")
        elseif key == "p" and not player.isAttacking and player.powerAttackCooldown <= 0 then
            performAttack("power")
        end
    end

    if nextState == GameState.PLAYING then
        resetGame()
    elseif nextState == "reset" then
        resetGame()
    end
end

function resetGame()
    currentState = GameState.PLAYING

    hud:reset()
    player:reset(spawnX, spawnY)

    Folk:reset()
    Goblin:reset()

    Folk:spawn(world, hud.converted.totalFolks, mapW, mapH, walls)
    Goblin:spawn(world, hud.converted.totalFolks, mapW, mapH, walls)

    if gameTimer then
       gameTimer.time = 0
       gameTimer.active = true
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
    if entity == Dude then
        entity.dialog = {
            text = text,
            y_offset = y_offset
        }
    else
        entity.dialog = {
            text = text,
            timer = 2,
            y_offset = y_offset
        }
    end
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

    local alpha = nil
    if entity == Dude then
        alpha = 1
    else
        alpha = math.min(1, entity.dialog.timer * 2)
    end
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
