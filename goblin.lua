local Goblin = {}

Goblin.list = {}
Goblin.sprite = nil
Goblin.grid = nil
Goblin.animations = {}
Goblin.settings = {}
Goblin.sounds = {}

function Goblin:load(world, mainSounds)
    Goblin.sprite = love.graphics.newImage('assets/Factions/Goblins/Troops/Torch/Red/Torch_Red.png')
    Goblin.grid = anim8.newGrid(192, 192, Goblin.sprite:getWidth(), Goblin.sprite:getHeight())

    Goblin.settings = {
        attackPrepareTime = 0.8,
        attackCooldown = 1.5,
        normalAnimSpeed = 0.1,
        prepareAnimSpeed = 0.3
    }

    Goblin.animations.idle = anim8.newAnimation(Goblin.grid('1-7', 1), Goblin.settings.normalAnimSpeed)
    Goblin.animations.walk = anim8.newAnimation(Goblin.grid('1-6', 2), Goblin.settings.normalAnimSpeed)
    Goblin.animations.attackLeft = anim8.newAnimation(Goblin.grid('1-6', 3), Goblin.settings.normalAnimSpeed)
    Goblin.animations.attackDown = anim8.newAnimation(Goblin.grid('1-6', 4), Goblin.settings.normalAnimSpeed)
    Goblin.animations.attackUp = anim8.newAnimation(Goblin.grid('1-6', 5), Goblin.settings.normalAnimSpeed)

    Goblin.animations.prepareAttackLeft = anim8.newAnimation(Goblin.grid('1-6', 3), Goblin.settings.prepareAnimSpeed, nil)
    Goblin.animations.prepareAttackDown = anim8.newAnimation(Goblin.grid('1-6', 4), Goblin.settings.prepareAnimSpeed, nil)
    Goblin.animations.prepareAttackUp = anim8.newAnimation(Goblin.grid('1-6', 5), Goblin.settings.prepareAnimSpeed, nil)

    Goblin.sounds.detections = mainSounds.goblinDetections
    Goblin.sounds.dies = mainSounds.goblinDies
    Goblin.sounds.hits = mainSounds.hits
    Goblin.sounds.lastDetectionIndex = 0
    Goblin.sounds.lastHitIndex = 0

    world:addCollisionClass('Goblin')
end

function Goblin:spawn(world, count, mapW, mapH, walls)
    local margin = 200
    local entityRadius = 30
    local maxAttemps = 50
    local centerExclusionRadius = 1000

    for i = 1, count do
        local goblin = {}
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

        goblin.collider = world:newCircleCollider(x, y, entityRadius)
        goblin.collider:setFixedRotation(true)
        goblin.collider:setCollisionClass('Goblin')

        goblin.x = x
        goblin.y = y
        goblin.animations = {
            idle = Goblin.animations.idle:clone(),
            walk = Goblin.animations.walk:clone(),
            attackLeft = Goblin.animations.attackLeft:clone(),
            attackDown = Goblin.animations.attackDown:clone(),
            attackUp = Goblin.animations.attackUp:clone(),
            prepareAttackLeft = Goblin.animations.prepareAttackLeft:clone(),
            prepareAttackDown = Goblin.animations.prepareAttackDown:clone(),
            prepareAttackUp = Goblin.animations.prepareAttackUp:clone()
        }

        goblin.anim = goblin.animations.idle
        goblin.state = love.math.random() < 0.5 and "idle" or "wandering"
        goblin.facingLeft = false
        goblin.hasPlayedDetectionSound = false
        goblin.hasAttacked = false
        goblin.attackCooldown = 0
        goblin.prepareTime = 0

        goblin.wanderTimer = 0
        goblin.wanderDuration = love.math.random(1, 3)
        goblin.idleTimer = 0
        goblin.idleDuration = love.math.random(2, 5)
        goblin.wanderSpeed = love.math.random(50, 100)
        goblin.wanderDirection = {
            x = love.math.random(-100, 100) / 100,
            y = love.math.random(-100, 100) / 100
        }

        local length = math.sqrt(goblin.wanderDirection.x^2 + goblin.wanderDirection.y^2)
        if length > 0 then
            goblin.wanderDirection.x = goblin.wanderDirection.x / length
            goblin.wanderDirection.y = goblin.wanderDirection.y / length
        end

        table.insert(Goblin.list, goblin)
    end
end

function Goblin:update(dt, player, mapW, mapH)
    for i=#Goblin.list, 1, -1 do
        local goblin = Goblin.list[i]

        goblin.x = goblin.collider:getX()
        goblin.y = goblin.collider:getY()

        if goblin.attackCooldown > 0 then
            goblin.attackCooldown = goblin.attackCooldown - dt
        end

        local dx = player.x - goblin.x
        local dy = player.y - goblin.y
        local distance = math.sqrt(dx*dx + dy*dy)

        local detectionRange = 300
        local attackRange = 100

        if distance <= attackRange then
            goblin.collider:setLinearVelocity(0, 0)

            local angle = math.atan2(dy, dx)
            goblin.facingLeft = dx < 0

            if math.abs(dx) > math.abs(dy) then
                goblin.anim = goblin.animations.attackLeft
            elseif dy > 0 then
                goblin.anim = goblin.animations.attackDown
            else
                goblin.anim = goblin.animations.attackUp
            end

            if goblin.state ~= "preparing" and goblin.state ~= "attacking" and goblin.attackCooldown <= 0 then
                goblin.state = "preparing"
                goblin.prepareTime = Goblin.settings.attackPrepareTime

                if goblin.anim == goblin.animations.attackLeft then
                    goblin.anim = goblin.animations.prepareAttackLeft
                elseif goblin.anim == goblin.animations.attackDown then
                    goblin.anim = goblin.animations.prepareAttackDown
                elseif goblin.anim == goblin.animations.attackUp then
                    goblin.anim = goblin.animations.prepareAttackUp
                end
            end

            if goblin.state == "preparing" then
                goblin.prepareTime = goblin.prepareTime - dt

                if goblin.prepareTime <= 0 then
                    goblin.state = "attacking"
                    goblin.hasAttacked = false

                    if goblin.anim == goblin.animations.prepareAttackLeft then
                        goblin.anim = goblin.animations.attackLeft
                        goblin.anim:gotoFrame(1)
                    elseif goblin.anim == goblin.animations.prepareAttackDown then
                        goblin.anim = goblin.animations.attackDown
                        goblin.anim:gotoFrame(1)
                    elseif goblin.anim == goblin.animations.prepareAttackUp then
                        goblin.anim = goblin.animations.attackUp
                        goblin.anim:gotoFrame(1)
                    end
                end
            end

            if goblin.state == "attacking" and player.invulnerableTime <=0 and not goblin.hasAttacked then
                player.life = player.life - 20
                player.invulnerableTime = player.invulnerableDuration
                goblin.hasAttacked = true
                goblin.attackCooldown = Goblin.settings.attackCooldown

                local nextHitIndex = Goblin.sounds.lastHitIndex % #Goblin.sounds.hits + 1
                Goblin.sounds.lastHitIndex = nextHitIndex
                local nextHit = Goblin.sounds.hits[nextHitIndex]
                local hitClone = nextHit:clone()
                hitClone:setPitch(love.math.random(80, 120) / 100)

                hitClone:play()
            end

            goblin.wanderTimer = 0
            goblin.idleTimer = 0
            goblin.hasPlayedDetectionSound = false

        elseif distance <= detectionRange then
            if goblin.state ~= "preparing" and goblin.state ~= "attacking" then
                goblin.state = "chasing"
            end

            goblin.hasAttacked = false

            local speed = 200
            dx = dx / distance
            dy = dy / distance

            goblin.collider:setLinearVelocity(dx * speed, dy * speed)
            goblin.anim = goblin.animations.walk
            goblin.facingLeft = dx < 0

            local nextDetectionIndex = Goblin.sounds.lastDetectionIndex % #Goblin.sounds.detections + 1
            Goblin.sounds.lastDetectionIndex = nextDetectionIndex
            local nextDetection = Goblin.sounds.detections[nextDetectionIndex]
            local detectionClone = nextDetection:clone()
            detectionClone:setPitch(love.math.random(80, 120) / 100)

            if not goblin.hasPlayedDetectionSound then
                detectionClone:play()
                goblin.hasPlayedDetectionSound = true
            end

            goblin.wanderTimer = 0
            goblin.idleTimer = 0
        else
            goblin.hasPlayedDetectionSound = false

            if goblin.state == "preparing" or goblin.state == "attacking" then
                goblin.state = "idle"
                goblin.idleTimer = 0

                if goblin.state == "preparing" then
                    if goblin.anim == goblin.animations.prepareAttackLeft then
                        goblin.anim = goblin.animations.attackLeft
                    elseif goblin.anim == goblin.animations.prepareAttackDown then
                        goblin.anim = goblin.animations.attackDown
                    elseif goblin.anim == goblin.animations.prepareAttackUp then
                        goblin.anim = goblin.animations.attackUp
                    end
                end
            end

            if goblin.state == "wandering" then
                goblin.wanderTimer = goblin.wanderTimer + dt

                local nextX = goblin.x + goblin.wanderDirection.x * goblin.wanderSpeed * dt
                local nextY = goblin.y + goblin.wanderDirection.y * goblin.wanderSpeed * dt

                local margin = 100
                local needNewDirection = false

                if nextX < margin or nextX > mapW - margin or nextY < margin or nextY > mapH - margin then
                    needNewDirection = true
                end

                if goblin.wanderTimer >= goblin.wanderDuration or needNewDirection then
                    goblin.state = "idle"
                    goblin.idleTimer = 0
                    goblin.collider:setLinearVelocity(0, 0)
                    goblin.anim = goblin.animations.idle
                else
                    goblin.collider:setLinearVelocity(goblin.wanderDirection.x * goblin.wanderSpeed, goblin.wanderDirection.y * goblin.wanderSpeed)
                    goblin.anim = goblin.animations.walk
                    goblin.facingLeft = goblin.wanderDirection.x < 0
                end
            elseif goblin.state == "idle" then
                goblin.idleTimer = goblin.idleTimer + dt
                goblin.collider:setLinearVelocity(0, 0)
                goblin.anim = goblin.animations.idle

                if goblin.idleTimer >= goblin.idleDuration then
                    goblin.state = "wandering"
                    goblin.wanderTimer = 0
                    goblin.wanderDuration = love.math.random(1, 3)

                    goblin.wanderDirection = {
                        x = love.math.random(-100, 100) / 100,
                        y = love.math.random(-100, 100) / 100
                    }
                    local length = math.sqrt(goblin.wanderDirection.x^2 + goblin.wanderDirection.y^2)
                    if length > 0 then
                        goblin.wanderDirection.x = goblin.wanderDirection.x / length
                        goblin.wanderDirection.y = goblin.wanderDirection.y / length
                    end

                    goblin.wanderSpeed = love.math.random(50, 100)
                end
            else
                 if goblin.state ~= "idle" and goblin.state ~= "wandering" then
                    goblin.state = love.math.random() < 0.5 and "idle" or "wandering"

                    if goblin.state == "wandering" then
                        goblin.wanderTimer = 0
                        goblin.wanderDuration = love.math.random(1, 3)
                        goblin.wanderDirection = {
                            x = love.math.random(-100, 100) / 100,
                            y = love.math.random(-100, 100) / 100
                        }
                        local length = math.sqrt(goblin.wanderDirection.x^2 + goblin.wanderDirection.y^2)
                        if length > 0 then
                            goblin.wanderDirection.x = goblin.wanderDirection.x / length
                            goblin.wanderDirection.y = goblin.wanderDirection.y / length
                        end

                        goblin.wanderSpeed = love.math.random(50, 100)
                    else
                        goblin.state = "idle"
                        goblin.idleTimer = 0
                        goblin.idleDuration = love.math.random(2, 5)
                        goblin.collider:setLinearVelocity(0, 0)
                        goblin.anim = goblin.animations.idle
                    end
                else
                    goblin.state = "idle"
                    goblin.idleTimer = 0
                    goblin.collider:setLinearVelocity(0, 0)
                    goblin.anim = goblin.animations.idle
                end
            end
        end

        if goblin.anim and goblin.anim.update then
           goblin.anim:update(dt)
        end
    end
end

function Goblin:draw()
    for _, goblin in ipairs(Goblin.list) do
        local scaleX = goblin.facingLeft and -1 or 1
        if goblin.anim and goblin.anim.draw then
           goblin.anim:draw(Goblin.sprite, goblin.x, goblin.y, nil, scaleX, 1, 96, 96)
        end
    end
end

function Goblin:reset()
    for _, goblin in ipairs(Goblin.list) do
        if goblin.collider and goblin.collider.destroy then
            goblin.collider:destroy()
        end
    end
    Goblin.list = {}
end

function Goblin:checkHits(playerX, playerY, attackRange, attackDirection, createExplosion)
    for i = #Goblin.list, 1, -1 do
        local goblin = Goblin.list[i]
        local dx = goblin.x - playerX
        local dy = goblin.y - playerY
        local distance = math.sqrt(dx*dx + dy*dy)

        local inDirection = false

        if attackDirection == "up" and dy < 0 and math.abs(dy) > math.abs(dx) then
            inDirection = true
        elseif attackDirection == "down" and dy > 0 and math.abs(dy) > math.abs(dx) then
            inDirection = true
        elseif attackDirection == "left" and dx < 0 and math.abs(dx) > math.abs(dy) then
            inDirection = true
        elseif attackDirection == "right" and dx > 0 and math.abs(dx) > math.abs(dy) then
            inDirection = true
        end

        if distance <= attackRange and inDirection then
            createExplosion(goblin.x, goblin.y)

            local deathSound = Goblin.sounds.dies[1]:clone()
            deathSound:setPitch(love.math.random(80, 120) / 100)
            deathSound:play()

            goblin.collider:destroy()
            table.remove(Goblin.list, i)
            return true -- Indicate a hit occurred
        end
    end
    return false -- Indicate no hit occurred
end


return Goblin
