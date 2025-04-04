local Folk = {}

Folk.list = {}
Folk.sprite = nil
Folk.spriteConverted = nil
Folk.grid = nil
Folk.gridConverted = nil
Folk.animations = {}
Folk.animationsConverted = {}
Folk.sounds = {}
Folk.conversionPhrases = {
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

function Folk:load(mainSounds)
    Folk.sprite = love.graphics.newImage('assets/Factions/Knights/Troops/Pawn/Yellow/Pawn_Yellow.png')
    Folk.spriteConverted = love.graphics.newImage('assets/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png')
    Folk.grid = anim8.newGrid(192, 192, Folk.sprite:getWidth(), Folk.sprite:getHeight())
    Folk.gridConverted = anim8.newGrid(192, 192, Folk.spriteConverted:getWidth(), Folk.spriteConverted:getHeight())

    Folk.animations.idle = anim8.newAnimation(Folk.grid('1-6', 1), 0.1)
    Folk.animations.walk = anim8.newAnimation(Folk.grid('1-6', 2), 0.1)

    Folk.animationsConverted.idle = anim8.newAnimation(Folk.gridConverted('1-6', 1), 0.1)
    Folk.animationsConverted.walk = anim8.newAnimation(Folk.gridConverted('1-6', 2), 0.1)

    Folk.sounds.conversion = mainSounds.conversion
    Folk.list = {}
end

function Folk:spawn(world, count, mapW, mapH, walls, knownPositions)
    local margin = 200
    local entityRadius = 30
    local maxAttemps = 50
    local centerExclusionRadius = 1000

    for i, pos in ipairs(knownPositions) do
        local folk = {}
        folk.collider = world:newCircleCollider(pos.x, pos.y, entityRadius)
        folk.collider:setFixedRotation(true)
        folk.collider:setCollisionClass('Folk')

        folk.x = pos.x
        folk.y = pos.y
        folk.converted = false
        folk.animations = {
            idle = Folk.animations.idle:clone(),
            walk = Folk.animations.walk:clone()
        }
        folk.anim = folk.animations.idle
        folk.facingLeft = false
        folk.dialog = nil

        table.insert(Folk.list, folk)
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
        folk.animations = {
            idle = Folk.animations.idle:clone(),
            walk = Folk.animations.walk:clone()
        }
        folk.anim = folk.animations.idle
        folk.facingLeft = false
        folk.dialog = nil

        table.insert(Folk.list, folk)
    end
end

function Folk:update(dt, player, base, hud, showDialogCallback)
    local victoryConditionMet = false

    for i = #Folk.list, 1, -1 do
        local folk = Folk.list[i]

        if folk.converted and folk.collider:enter('Base') then
            hud.converted.peopleConverted = hud.converted.peopleConverted - 1
            hud.converted.peopleSaved = hud.converted.peopleSaved + 1

            local conversionSound = Folk.sounds.conversion:clone()
            conversionSound:play()

            local randomPhrase = Folk.conversionPhrases[love.math.random(#Folk.conversionPhrases)]
            showDialogCallback(folk, randomPhrase)

            folk.collider:destroy()
            table.remove(Folk.list, i)

            if hud.converted.peopleSaved >= hud.converted.totalFolks then
                victoryConditionMet = true
                return victoryConditionMet
            end
            goto continue_folk_loop
        end

        if not folk.converted and folk.collider:enter('Player') then
            folk.converted = true
            folk.animations = {
                idle = Folk.animationsConverted.idle:clone(),
                walk = Folk.animationsConverted.walk:clone()
            }
            folk.anim = folk.animations.idle
            folk.facingLeft = false
            folk.conversionOrder = hud.converted.peopleConverted
            folk.followDelay = folk.conversionOrder * 0.5
            folk.conversionTime = love.timer.getTime()

            hud.converted.peopleConverted = hud.converted.peopleConverted + 1

            folk.collider:setCollisionClass('ConvertedFolk')

            local conversionSound = Folk.sounds.conversion:clone()
            conversionSound:play()

            local randomPhrase = Folk.conversionPhrases[love.math.random(#Folk.conversionPhrases)]
            showDialogCallback(folk, randomPhrase)
        end

        folk.x = folk.collider:getX()
        folk.y = folk.collider:getY()

        if folk.anim and folk.anim.update then
           folk.anim:update(dt)
        end

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
                    for _, otherFolk in ipairs(Folk.list) do
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
                        local teleportX = targetX + math.cos(teleportAngle) * teleportOffset
                        local teleportY = targetY + math.sin(teleportAngle) * teleportOffset

                        folk.collider:setPosition(teleportX, teleportY)
                        folk.x = teleportX
                        folk.y = teleportY

                        showDialogCallback(folk, "Catching up!")
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
end

function Folk:draw()
    for _, folk in ipairs(Folk.list) do
        local sprite = folk.converted and Folk.spriteConverted or Folk.sprite
        local scaleX = folk.facingLeft and -1 or 1
        if folk.anim and folk.anim.draw and sprite then
           folk.anim:draw(sprite, folk.x, folk.y, nil, scaleX, 1, 96, 96)
        end
    end
end

function Folk:reset()
    for _, folk in ipairs(Folk.list) do
        if folk.collider and folk.collider.destroy then
            folk.collider:destroy()
        end
    end
    Folk.list = {}
end

function Folk:getList()
    return Folk.list
end

return Folk
