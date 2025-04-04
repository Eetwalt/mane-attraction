local Dude = {}

function Dude:load(world, spawnX, spawnY)
    Dude.spriteSheet = love.graphics.newImage('assets/Factions/Knights/Troops/Archer/Archer_Blue.png')
    Dude.grid = anim8.newGrid(192, 192, Dude.spriteSheet:getWidth(), Dude.spriteSheet:getHeight())

    Dude.animations = {}
    Dude.animations.idle = anim8.newAnimation(Dude.grid('1-6', 1), 0.1)
    Dude.anim = Dude.animations.idle

    Dude.collider = world:newCircleCollider(spawnX + 155, spawnY + 90, 30)
    Dude.collider:setFixedRotation(true)
    Dude.collider:setCollisionClass('Dude')
    Dude.collider:setType('static')
    Dude.x = spawnX + 155
    Dude.y = spawnY + 90
    Dude.interactionRadius = 120
    Dude.dialogText = "Great gallopin’ griffons! There’s folks in distress - time to save the day!"
    Dude.dialog = nil
end

function Dude:update(dt, player, showDialogCallback)
    local dx_dude = player.x - self.x
    local dy_dude = player.y - self.y
    local distance_to_dude = math.sqrt(dx_dude * dx_dude + dy_dude * dy_dude)

    if distance_to_dude < self.interactionRadius then
        if not self.dialog then
           showDialogCallback(self, self.dialogText)
        end
    else
        self.dialog = nil
    end

    if self.anim then
        self.anim:update(dt)
    end
end

function Dude:draw()
    self.anim:draw(self.spriteSheet, self.x, self.y, nil, nil, nil, 96, 96)
end

return Dude
