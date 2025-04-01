function love.load()
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

    wf = require 'libraries/windfield'
    world = wf.newWorld(0, 0)
    world:addCollisionClass('Player')
    world:addCollisionClass('Folk', {enter = {'Player'}})
    world:addCollisionClass('ConvertedFolk', {ignores = {'Player', 'ConvertedFolk'}})
    world:addCollisionClass('Goblin')

    camera = require 'libraries.camera'
    cam = camera()

    anim8 = require 'libraries.anim8'

    sti = require 'libraries/sti'
    gameMap = sti('maps/map.lua')

    mapW = gameMap.width * gameMap.tilewidth
    mapH = gameMap.height * gameMap.tileheight

    local spawnX = mapW / 2
    local spawnY = mapH / 2

    player = {}
    player.collider = world:newBSGRectangleCollider(spawnX, spawnY, 45, 60, 10)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass('Player')
    player.x = spawnX
    player.y = spawnY
    player.speed = 400
    player.spriteSheet = love.graphics.newImage('assets/Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png')
    player.grid = anim8.newGrid(192, 192, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.idleRight = anim8.newAnimation(player.grid('1-6', 1), 0.1)
    player.animations.idleLeft = anim8.newAnimation(player.grid('1-6', 1), 0.1):flipH()

    player.animations.right = anim8.newAnimation(player.grid('1-6', 2), 0.1)
    player.animations.left = anim8.newAnimation(player.grid('1-6', 2), 0.1):flipH()

    player.anim = player.animations.idle
    player.facingLeft = false

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

    spawnFolks(50)

    goblins = {}
    goblinSprite = love.graphics.newImage('assets/Factions/Goblins/Troops/Torch/Red/Torch_Red.png')
    goblinGrid = anim8.newGrid(192, 192, goblinSprite:getWidth(), goblinSprite:getHeight())

    goblinAnimations = {}
    goblinAnimations.idle = anim8.newAnimation(goblinGrid('1-7', 1), 0.1)
    goblinAnimations.walk = anim8.newAnimation(goblinGrid('1-6', 2), 0.1)
    goblinAnimations.attackLeft = anim8.newAnimation(goblinGrid('1-6', 3), 0.1)
    goblinAnimations.attackDown = anim8.newAnimation(goblinGrid('1-6', 4), 0.1)
    goblinAnimations.attackUp = anim8.newAnimation(goblinGrid('1-6', 5), 0.1)

    spawnGoblins(50)

    walls = {}
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType('static')
            table.insert(walls, wall)
        end
    end

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
    sounds.lastStepIndex = 0 -- Track which sound was played last

    sounds.music = love.audio.newSource("sounds/music.mp3", "stream")
    sounds.music:setVolume(0.2)
    sounds.music:setLooping(true)
    sounds.music:play()

    hud = {}
    hud.converted = {}
    hud.converted.bgImage = love.graphics.newImage('assets/UI/Banners/Converted-Banner.png', { dpiscale = 1.4 })
    hud.converted.peopleConverted = 0
    hud.converted.font = love.graphics.newFont('assets/Fonts/Condiment-Regular.ttf', 28)

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
end

function love.update(dt)
    local isMoving = false

    local vx = 0
    local vy = 0

    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        vy = -1
        player.anim = player.animations.right
        isMoving = true
    end

    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        vy = 1
        player.anim = player.animations.right
        isMoving = true
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vx = -1
        player.anim = player.animations.left
        player.facingLeft = true
        isMoving = true
    end

    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        vx = 1
        player.anim = player.animations.right
        player.facingLeft = false
        isMoving = true
    end

    if vx ~= 0 and vy ~= 0 then
        local length = math.sqrt(vx * vx + vy * vy)
        vx = vx / length
        vy = vy /length
    end

    vx = vx * player.speed
    vy = vy * player.speed

    player.collider:setLinearVelocity(vx, vy)

    if isMoving == false then
        player.anim = player.facingLeft and player.animations.idleLeft or player.animations.idleRight
        sounds.stepTimer = 0
    else
        sounds.stepTimer = sounds.stepTimer + dt
        if sounds.stepTimer >= sounds.stepDelay then
            sounds.stepTimer = 0
            sounds.stepDelay = love.math.random(25, 35) / 100

            local nextStepIndex = sounds.lastStepIndex % 2 + 1
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

    player.anim:update(dt)

    for _, folk in ipairs(folks) do

        if player.collider:enter('Folk') and not folk.converted and player.collider:getEnterCollisionData('Folk').collider == folk.collider then
            folk.converted = true
            folk.sprite = folkSpriteConverted
            folk.animations = {
                idle = folkAnimationsConverted.idle:clone(),
                walk = folkAnimationsConverted.walk:clone()
            }
            folk.anim = folk.animations.idle
            folk.facingLeft = false
            folk.conversionOrder = hud.converted.peopleConverted
            folk.followDelay = folk.conversionOrder * 0.5  -- Half second delay per folk
            folk.conversionTime = love.timer.getTime()

            hud.converted.peopleConverted = hud.converted.peopleConverted + 1

            folk.collider:setCollisionClass('ConvertedFolk')

            local conversionSound = sounds.conversion:clone()
            conversionSound:play()

            local randomPhrase = conversionPhrases[love.math.random(#conversionPhrases)]
            showDialog(folk, randomPhrase)
        end
        
        -- Update folk position from collider
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

                -- First converted folk follows the player
                if folk.conversionOrder == 0 then
                    targetX = player.x
                    targetY = player.y
                else
                    -- Find the folk to follow
                    for _, otherFolk in ipairs(folks) do
                        if otherFolk.converted and otherFolk.conversionOrder == folk.conversionOrder - 1 then
                            targetX = otherFolk.x
                            targetY = otherFolk.y
                            break
                        end
                    end
                end

                -- Only move if we have a target
                if targetX and targetY then
                    local dx = targetX - folk.x
                    local dy = targetY - folk.y
                    local distance = math.sqrt(dx*dx + dy*dy)

                    local minDistance = 60
                    local maxDistance = 300  -- Add maximum distance to prevent stretching

                    if distance > minDistance then
                        -- Normalize direction
                        dx = dx / distance
                        dy = dy / distance

                        -- Adjust speed based on distance
                        local followSpeed = player.speed
                        if distance > maxDistance then
                            followSpeed = player.speed * 1.2  -- Speed up if too far
                        end

                        folk.collider:setLinearVelocity(dx * followSpeed, dy * followSpeed)
                        folk.anim = folk.animations.walk
                        folk.facingLeft = dx < 0
                    else
                        folk.collider:setLinearVelocity(0, 0)
                        folk.anim = folk.animations.idle
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
    end

    for _, goblin in ipairs(goblins) do
        goblin.anim:update(dt)
    end

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
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Base"])
        gameMap:drawLayer(gameMap.layers["Decor"])
        gameMap:drawLayer(gameMap.layers["Decor-2"])

        for _, folk in ipairs(folks) do
            local sprite = folk.converted and folkSpriteConverted or folkSprite
            local scaleX = folk.facingLeft and -1 or 1
            folk.anim:draw(sprite, folk.x, folk.y, nil, scaleX, 1, 96, 96)
            
            -- Draw dialog if exists
            drawDialog(folk)

        end
        for _, goblin in ipairs(goblins) do
            local sprite = goblinSprite
            local scaleX = goblin.facingLeft and -1 or 1
            goblin.anim:draw(sprite, goblin.x, goblin.y, nil, scaleX, 1, 96, 96)
        end
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, nil, nil, 96, 96)
        world:draw(.6)
    cam:detach()

    drawHud()
end

function drawHud()
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setFont(hud.converted.font)

    local padding = 20
    local screenWidth = love.graphics.getWidth()
    local bgX = screenWidth - hud.converted.bgImage:getWidth() - padding
    local bgY = 0
    love.graphics.draw(hud.converted.bgImage, bgX, bgY)

    love.graphics.setColor(0.086, 0.11, 0.18, 1)
    local textX = bgX + 45
    local textY = bgY + hud.converted.bgImage:getHeight()/2 - hud.converted.font:getHeight()/2 + 5
    love.graphics.print("Folks Converted:   " .. hud.converted.peopleConverted, textX, textY)

    love.graphics.setFont(prevFont)
    love.graphics.setColor(r, g, b, a)
end

function love.keypressed(key)
    if key == "z" then
        if sounds.music:isPlaying() == true then
            sounds.music:stop()
        else
            sounds.music:play()
        end
    end
end

function spawnFolks(count)
    local margin = 200

    for i = 1, count do
        local folk = {}

        local x = love.math.random(margin, mapW - margin)
        local y = love.math.random(margin, mapH - margin)
        
        folk.collider = world:newCircleCollider(x, y, 30)
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

function spawnGoblins(count)
    local margin = 200

    for i = 1, count do
        local goblin = {}

        local x = love.math.random(margin, mapW - margin)
        local y = love.math.random(margin, mapH - margin)
        
        goblin.collider = world:newCircleCollider(x, y, 30)
        goblin.collider:setFixedRotation(true)
        goblin.collider:setCollisionClass('Goblin')

        goblin.x = x
        goblin.y = y
        goblin.converted = false
        goblin.sprite = goblinSprite
        goblin.animations = {
            idle = goblinAnimations.idle:clone(),
            walk = goblinAnimations.walk:clone()
        }
        goblin.anim = goblin.animations.idle

        table.insert(goblins, goblin)
    end
end

function showDialog(folk, text)
    folk.dialog = {
        text = text,
        timer = 2,
        y_offset = -60
    }
end

function drawDialog(folk)
    if not folk.dialog then return end

    local prevFont = love.graphics.getFont()
    love.graphics.setFont(dialogBox.font)
    
    local text = folk.dialog.text
    local textWidth = hud.converted.font:getWidth(text)
    local textHeight = hud.converted.font:getHeight()
    
    local padding = 20
    local bgHeight = dialogBox.bgImage:getHeight()
    local minWidth = textWidth + ( padding * 2 )

    local totalSlices = math.max(3, math.ceil(minWidth / dialogBox.sliceWidth))
    local bgWidth = totalSlices * dialogBox.sliceWidth

    local bgX = folk.x - bgWidth/2
    local bgY = folk.y + folk.dialog.y_offset - bgHeight/2

    love.graphics.setColor(1, 1, 1, folk.dialog.timer)

    love.graphics.draw(dialogBox.bgImage, dialogBox.leftSlice, bgX, bgY)

    local middleWidth = bgWidth - (dialogBox.sliceWidth * 2)
    local middleScale = middleWidth / dialogBox.sliceWidth
    love.graphics.draw(dialogBox.bgImage, dialogBox.middleSlice, bgX + dialogBox.sliceWidth, bgY, 0, middleScale, 1)

    love.graphics.draw(dialogBox.bgImage, dialogBox.rightSlice, bgX + bgWidth - dialogBox.sliceWidth, bgY)

    local textX = bgX + (bgWidth - textWidth)/2 + 8
    local textY = bgY + bgHeight/2 - textHeight/2 - 3

    love.graphics.setColor(0.086, 0.11, 0.18, folk.dialog.timer)
    love.graphics.print(text, textX, textY)
    
    -- Reset graphics state
    love.graphics.setFont(prevFont)
    love.graphics.setColor(1, 1, 1, 1)
end
