function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
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

    attackSettings = {
        normalAttackDuration = 0.6,
        powerAttackDuration = 0.8,
        powerAttackCooldown = 5.0,
        normalAttackRange = 80,
        powerAttackRange = 120
    }

    player = {}
    player.collider = world:newBSGRectangleCollider(spawnX, spawnY, 45, 60, 10)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass('Player')
    player.x = spawnX
    player.y = spawnY
    player.speed = 400

    player.life = 100
    player.maxLife = 100
    player.invulnerableTime = 0
    player.invulnerableDuration = 1.0

    player.spriteSheet = love.graphics.newImage('assets/Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png')
    player.grid = anim8.newGrid(192, 192, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.idleRight = anim8.newAnimation(player.grid('1-6', 1), 0.1)
    player.animations.idleLeft = anim8.newAnimation(player.grid('1-6', 1), 0.1):flipH()

    player.animations.right = anim8.newAnimation(player.grid('1-6', 2), 0.1)
    player.animations.left = anim8.newAnimation(player.grid('1-6', 2), 0.1):flipH()

    player.animations.normalAttackRight = anim8.newAnimation(player.grid('1-6', 4), 0.1)
    player.animations.normalAttackLeft = anim8.newAnimation(player.grid('1-6', 4), 0.1):flipH()
    player.animations.normalAttackDown = anim8.newAnimation(player.grid('1-6', 6), 0.1)
    player.animations.normalAttackUp = anim8.newAnimation(player.grid('1-6', 8), 0.1)

    player.animations.powerAttackRight = anim8.newAnimation(player.grid('1-6', 3), 0.1)
    player.animations.powerAttackLeft = anim8.newAnimation(player.grid('1-6', 3), 0.1):flipH()
    player.animations.powerAttackDown = anim8.newAnimation(player.grid('1-6', 5), 0.1)
    player.animations.powerAttackUp = anim8.newAnimation(player.grid('1-6', 7), 0.1)

    player.anim = player.animations.idleRight
    player.facingLeft = false
    player.lastDirection = "right"
    player.isAttacking = false
    player.attackType = nil
    player.attackTimer = 0
    player.powerAttackCooldown = 0

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
    goblinAnimations.idle = anim8.newAnimation(goblinGrid('1-7', 1), 4)
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

    sounds.goblinDetections = {
        love.audio.newSource("sounds/goblin/goblin-2.wav", "static"),
        love.audio.newSource("sounds/goblin/goblin-6.wav", "static")
    }

    for _, goblinDetection in ipairs(sounds.goblinDetections) do
        goblinDetection:setVolume(0.4)
    end
    sounds.lastDetectionIndex = 0 -- Track which sound was played last

    sounds.music = love.audio.newSource("sounds/music.mp3", "stream")
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
    sounds.lastHitIndex = 0 -- Track which sound was played last

    hud = {}
    hud.converted = {}
    hud.converted.bgImage = love.graphics.newImage('assets/UI/Banners/Converted-Banner.png', { dpiscale = 1.4 })
    hud.converted.peopleConverted = 0
    hud.converted.font = love.graphics.newFont('assets/Fonts/Condiment-Regular.ttf', 28)

    hud.life = {}
    hud.life.leftBlock = love.graphics.newImage('assets/UI/LifeBars/1.png', { dpiscale = 0.4 })
    hud.life.middleBlock = love.graphics.newImage('assets/UI/LifeBars/3.png', { dpiscale = 0.4 })
    hud.life.rightBlock = love.graphics.newImage('assets/UI/LifeBars/4.png', { dpiscale = 0.4 })
    hud.life.fill = love.graphics.newImage('assets/UI/LifeBars/life-fill.png', { dpiscale = 0.4 })
    hud.life.width = 250
    hud.life.padding = 20

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
    if player.invulnerableTime > 0 then
        player.invulnerableTime = player.invulnerableTime - dt
    end

    if player.life <= 0 then
        player.life = 0
    end

    if player.isAttacking then
        print("Player attacking")
        player.attackTimer = player.attackTimer - dt
        player.collider:setLinearVelocity(0, 0)
        if player.attackTimer <= 0 then
            player.isAttacking = false
            player.attackType = nil
            player.anim = player.facingLeft and player.animations.idleLeft or player.animations.idleRight
            print("Attack finished, returning to idle")
        end
    else
        local isMoving = false
        local vx = 0
        local vy = 0

        if player.powerAttackCooldown > 0 then
            player.powerAttackCooldown = player.powerAttackCooldown - dt
        end

        if love.keyboard.isDown("w") then
            vy = -1
            player.anim = player.animations.right
            player.lastDirection = "up"
            isMoving = true
        end

        if love.keyboard.isDown("s") then
            vy = 1
            player.anim = player.animations.right
            player.lastDirection = "down"
            isMoving = true
        end

        if love.keyboard.isDown("a") then
            vx = -1
            player.anim = player.animations.left
            player.facingLeft = true
            player.lastDirection = "left"
            isMoving = true
        end

        if love.keyboard.isDown("d") then
            vx = 1
            player.anim = player.animations.right
            player.facingLeft = false
            player.lastDirection = "right"
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
    end

    world:update(dt)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    if player.anim then
        player.anim:update(dt)
    else
        print("Warning: player.anim is nil")
        player.anim = player.animations.idleRight
    end

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
        -- Update goblin position from collider
        goblin.x = goblin.collider:getX()
        goblin.y = goblin.collider:getY()
        
        -- Calculate distance to player
        local dx = player.x - goblin.x
        local dy = player.y - goblin.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        -- Define detection and attack ranges
        local detectionRange = 300  -- Starts chasing when player is within 300 pixels
        local attackRange = 100     -- Starts attacking when player is within 100 pixels
        
        if distance <= attackRange then
            -- Attack state
            goblin.state = "attacking"
            goblin.collider:setLinearVelocity(0, 0)
            
            -- Determine attack animation based on relative position
            local angle = math.atan2(dy, dx)
            goblin.facingLeft = dx < 0
            
            -- Choose attack animation based on angle
            if math.abs(dx) > math.abs(dy) then
                -- Horizontal attack
                goblin.anim = goblin.animations.attackLeft
            elseif dy > 0 then
                -- Attack downward
                goblin.anim = goblin.animations.attackDown
            else
                -- Attack upward
                goblin.anim = goblin.animations.attackUp
            end

            if player.invulnerableTime <= 0 and not goblin.hasAttacked then
                player.life = player.life - 20
                player.invulnerableTime = player.invulnerableDuration
                goblin.hasAttacked = true

                -- TODO: Add visual feedback and sfx for being hit
                local nextHitIndex = sounds.lastHitIndex % 2 + 1
                sounds.lastHitIndex = nextHitIndex
                local nextHit = sounds.hits[nextHitIndex]
                local hitClone = nextHit:clone()
                hitClone:setPitch(love.math.random(80, 120) / 100)

                hitClone:play()
            end
            
        elseif distance <= detectionRange then
            -- Chase state
            goblin.state = "chasing"
            goblin.hasAttacked = false
            
            -- Normalize direction and set velocity
            local speed = 200  -- Adjust speed as needed
            dx = dx / distance
            dy = dy / distance
            
            goblin.collider:setLinearVelocity(dx * speed, dy * speed)
            goblin.anim = goblin.animations.walk
            goblin.facingLeft = dx < 0

            local nextDetectionIndex = sounds.lastDetectionIndex % 2 + 1
            sounds.lastDetectionIndex = nextDetectionIndex
            local nextDetection = sounds.goblinDetections[nextDetectionIndex]
            local detectionClone = nextDetection:clone()
            detectionClone:setPitch(love.math.random(80, 120) / 100)

            if not goblin.hasPlayedDetectionSound then
                detectionClone:play()
                goblin.hasPlayedDetectionSound = true
            end
        else
            -- Idle state
            goblin.state = "idle"
            goblin.collider:setLinearVelocity(0, 0)
            goblin.anim = goblinAnimations.idle
        end
        
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

        if player.powerAttackCooldown > 0 then
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.print(string.format("Power Attack: %.1fs", player.powerAttackCooldown), player.x -50, player.y - 100)
            love.graphics.setColor(1, 1, 1, 1) 
        end

        for _, folk in ipairs(folks) do
            local sprite = folk.converted and folkSpriteConverted or folkSprite
            local scaleX = folk.facingLeft and -1 or 1
            folk.anim:draw(sprite, folk.x, folk.y, nil, scaleX, 1, 96, 96)
        end

        for _, goblin in ipairs(goblins) do
            local sprite = goblinSprite
            local scaleX = goblin.facingLeft and -1 or 1
            goblin.anim:draw(sprite, goblin.x, goblin.y, nil, scaleX, 1, 96, 96)
        end

        player.anim:draw(player.spriteSheet, player.x, player.y, nil, nil, nil, 96, 96)

        for _, folk in ipairs(folks) do
            if folk.dialog then
                drawDialog(folk)
            end
        end
        -- world:draw(.6)
    cam:detach()

    drawHud()
end

function love.keypressed(key)
    if key == "z" then
        if sounds.music:isPlaying() == true then
            sounds.music:stop()
        else
            sounds.music:play()
        end
    end
    if key == "x" then
        performAttack("normal")
    elseif key == "space" and not player.isAttacking and player.powerAttackCooldown <= 0 then
        performAttack("power")
        player.powerAttackCooldown = attackSettings.powerAttackCooldown
    end
end

function performAttack(attackType)
    player.isAttacking = true
    player.attackType = attackType

    if attackType == "normal" then
        player.attackTimer = attackSettings.normalAttackDuration
    else
        player.attackTimer = attackSettings.powerAttackDuration
    end

    if player.lastDirection == "up" then
        player.anim = attackType == "normal" and player.animations.normalAttackUp or player.animations.powerAttackUp
        print("Setting attack animation: up " .. attackType)
    elseif player.lastDirection == "down" then
        player.anim = attackType == "normal" and player.animations.normalAttackDown or player.animations.powerAttackDown
        print("Setting attack animation: down " .. attackType)
    elseif player.lastDirection == "left" then
        player.anim = attackType == "normal" and player.animations.normalAttackLeft or player.animations.powerAttackLeft
        print("Setting attack animation: left " .. attackType)
    elseif player.lastDirection == "right" then
        player.anim = attackType == "normal" and player.animations.normalAttackRight or player.animations.powerAttackRight
        print("Setting attack animation: right " .. attackType)
    end

    checkAttackHits(attackType)
end

function checkAttackHits(attackType)
    local attackRange = attackType == "normal" and attackSettings.normalAttackRange or attackSettings.powerAttackRange

    for i, goblin in ipairs(goblins) do
        local dx = goblin.x - player.x
        local dy = goblin.y - player.y
        local distance = math.sqrt(dx*dx + dy*dy)

        local inDirection = false

        if player.lastDirection == "up" and dy < 0 and math.abs(dy) > math.abs(dx) then
            inDirection = true
        elseif player.lastDirection == "down" and dy > 0 and math.abs(dy) > math.abs(dx) then
            inDirection = true
        elseif player.lastDirection == "left" and dx < 0 and math.abs(dx) > math.abs(dy) then
            inDirection = true
        elseif player.lastDirection == "right" and dx > 0 and math.abs(dx) > math.abs(dy) then
            inDirection = true
        end

        if distance <= attackRange and inDirection then
            table.remove(goblins, i)
            goblin.collider:destroy()
            break
        end
    end
end

function drawHud()
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    -- Draw converted folks counter
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
    
    -- Draw lifebar
    love.graphics.setColor(1, 1, 1, 1)
    local lifeX = hud.life.padding
    local lifeY = hud.life.padding
    local leftWidth = hud.life.leftBlock:getWidth()
    local rightWidth = hud.life.rightBlock:getWidth()
    local middleWidth = hud.life.width - leftWidth - rightWidth

    love.graphics.draw(hud.life.leftBlock, lifeX, lifeY)
    
    local middleScale = middleWidth / hud.life.middleBlock:getWidth()
    love.graphics.draw(hud.life.middleBlock, lifeX + leftWidth, lifeY, 0, middleScale, 1)

    love.graphics.draw(hud.life.rightBlock, lifeX + leftWidth + middleWidth, lifeY)

    local lifePercentage = player.life / player.maxLife
    local fillWidth = math.max(0, (hud.life.width - 48) * lifePercentage)

    if fillWidth > 0 then
        local fillQuad = love.graphics.newQuad(0, 0, fillWidth, hud.life.fill:getHeight(), hud.life.fill:getWidth(), hud.life.fill:getHeight())
        love.graphics.draw(hud.life.fill, fillQuad, lifeX + 40, lifeY + 35)
    end

    -- love.graphics.setColor(1, 1, 1, 1)
    -- love.graphics.print(math.floor(player.life) .. "/" .. player.maxLife, lifeX + hud.life.width/2 - 20, lifeY + 5)

    love.graphics.setFont(prevFont)
    love.graphics.setColor(r, g, b, a)
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
            walk = goblinAnimations.walk:clone(),
            attackLeft = goblinAnimations.attackLeft:clone(),
            attackDown = goblinAnimations.attackDown:clone(),
            attackUp = goblinAnimations.attackUp:clone()
        }
        goblin.anim = goblin.animations.idle
        goblin.state = "idle"
        goblin.facingLeft = false
        goblin.hasPlayedDetectionSound = false
        goblin.hasAttacked = false

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
