local Player = {}

function Player:new(world, spawnX, spawnY, sounds)
    local player = {}
    setmetatable(player, self)
    self.__index = self

    player.attackSettings = {
        normalAttackDuration = 0.6,
        powerAttackDuration = 0.8,
        powerAttackCooldown = 5.0,
        normalAttackRange = 80,
        powerAttackRange = 120
    }

    player.damageFlash = {
        active = false,
        duration = 1.0,
        timer = 0,
        frequency = 0.1,
        visible = true
    }

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

    player.sounds = {}
    player.sounds.grunts = sounds.grunts

    return player
end

function Player:update(dt)
    if self.invulnerableTime > 0 then
        self.invulnerableTime = self.invulnerableTime - dt
    end

    if self.damageFlash.active then
        self.damageFlash.timer = self.damageFlash.timer - dt

        if self.damageFlash.timer % self.damageFlash.frequency < self.damageFlash.frequency / 2 then
            self.damageFlash.visible = false
        else
            self.damageFlash.visible = true
        end

        if self.damageFlash.timer <= 0 then
            self.damageFlash.active = false
            self.damageFlash.visible = true
        end
    end

    if self.isAttacking then
        self.attackTimer = self.attackTimer - dt
        self.collider:setLinearVelocity(0, 0)
        if self.attackTimer <= 0 then
            self.isAttacking = false
            self.attackType = nil
            self.anim = self.facingLeft and self.animations.idleLeft or self.animations.idleRight
        end
    else
        local isMoving = false
        local vx = 0
        local vy = 0

        if self.powerAttackCooldown > 0 then
            self.powerAttackCooldown = self.powerAttackCooldown - dt
        end

        if love.keyboard.isDown("w") then
            vy = -1
            self.anim = self.animations.right
            self.lastDirection = "up"
            isMoving = true
        end

        if love.keyboard.isDown("s") then
            vy = 1
            self.anim = self.animations.right
            self.lastDirection = "down"
            isMoving = true
        end

        if love.keyboard.isDown("a") then
            vx = -1
            self.anim = self.animations.left
            self.facingLeft = true
            self.lastDirection = "left"
            isMoving = true
        end

        if love.keyboard.isDown("d") then
            vx = 1
            self.anim = self.animations.right
            self.facingLeft = false
            self.lastDirection = "right"
            isMoving = true
        end

        if vx ~= 0 and vy ~= 0 then
            local length = math.sqrt(vx * vx + vy * vy)
            vx = vx / length
            vy = vy / length
        end

        vx = vx * self.speed
        vy = vy * self.speed

        self.collider:setLinearVelocity(vx, vy)

        if not isMoving then
            self.anim = self.facingLeft and self.animations.idleLeft or self.animations.idleRight
        end
    end

    self.x = self.collider:getX()
    self.y = self.collider:getY()

    if self.anim then
        self.anim:update(dt)
    end
end

function Player:draw()
    if not self.damageFlash.active or self.damageFlash.visible then
        self.anim:draw(self.spriteSheet, self.x, self.y, nil, nil, nil, 96, 96)
    end
end

function Player:performAttack(attackType)
    if self.isAttacking then
        return false
    end

    if attackType == "power" and self.powerAttackCooldown > 0 then
        return false
    end

    self.isAttacking = true
    self.attackType = attackType

    if attackType == "normal" then
        self.attackTimer = self.attackSettings.normalAttackDuration
    elseif attackType == "power" then
        self.attackTimer = self.attackSettings.powerAttackDuration
        self.powerAttackCooldown = self.attackSettings.powerAttackCooldown
    else
        self.isAttacking = false
        self.attackType = nil
        print("Warning: Unknown attackType in Player:performAttack:", attackType)
        return false
    end

    local animSet = (attackType == "normal") and self.animations or self.animations
    local attackAnimKey = ""

    if self.lastDirection == "up" then
        attackAnimKey = (attackType == "normal") and "normalAttackUp" or "powerAttackUp"
    elseif self.lastDirection == "down" then
        attackAnimKey = (attackType == "normal") and "normalAttackDown" or "powerAttackDown"
    elseif self.lastDirection == "left" then
         attackAnimKey = (attackType == "normal") and "normalAttackLeft" or "powerAttackLeft"
    else
        attackAnimKey = (attackType == "normal") and "normalAttackRight" or "powerAttackRight"
    end

    if self.animations[attackAnimKey] then
        self.anim = self.animations[attackAnimKey]
    else
        self.anim = self.facingLeft and self.animations.idleLeft or self.animations.idleRight
    end

    return true
end

function Player:takeDamage(amount)
    if self.invulnerableTime <= 0 then
        self.life = self.life - amount
        self.invulnerableTime = self.invulnerableDuration

        self.damageFlash.active = true
        self.damageFlash.timer = self.damageFlash.duration
        self.damageFlash.visible = true

        local gruntSound = self.sounds.grunts[1]:clone()
        gruntSound:setPitch(love.math.random(80, 120) / 100)
        gruntSound:play()

        if self.life < 0 then 
            local deathSound = self.sounds.grunts[3]:clone()
            deathSound:play()
            self.life = 0 
        end

    end
end

function Player:reset(spawnX, spawnY)
    self.collider:setPosition(spawnX, spawnY)
    self.collider:setLinearVelocity(0, 0)
    self.x, self.y = self.collider:getPosition()
    self.life = self.maxLife
    self.isAttacking = false
    self.attackTimer = 0
    self.powerAttackCooldown = 0
    self.invulnerableTime = 0
    self.damageFlash.active = false
    self.damageFlash.visible = true
    self.anim = self.facingLeft and self.animations.idleLeft or self.animations.idleRight
end

return Player

