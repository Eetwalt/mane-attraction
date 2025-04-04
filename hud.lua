local Hud = {
    converted = {},
    life = {}
}

function Hud:load()
    -- Timer font
    self.gameTimer = {
        time = 0,
        active = false,
        font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 32)
    }

    -- Converted folks counter
    self.converted.bgImage = love.graphics.newImage('assets/UI/Banners/Converted-Banner.png', { dpiscale = 1.4 })
    self.converted.peopleConverted = 0
    self.converted.peopleSaved = 0
    self.converted.totalFolks = 30
    self.converted.font = love.graphics.newFont('assets/Fonts/Condiment-Regular.ttf', 28)

    -- Life bar
    self.life.leftBlock = love.graphics.newImage('assets/UI/LifeBars/1.png', { dpiscale = 0.4 })
    self.life.middleBlock = love.graphics.newImage('assets/UI/LifeBars/3.png', { dpiscale = 0.4 })
    self.life.rightBlock = love.graphics.newImage('assets/UI/LifeBars/4.png', { dpiscale = 0.4 })
    self.life.fill = love.graphics.newImage('assets/UI/LifeBars/life-fill.png', { dpiscale = 0.4 })
    self.life.width = 250
    self.life.padding = 20
end

function Hud:draw(player)
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    if self.gameTimer.active then
        love.graphics.setFont(self.gameTimer.font)
        local minutes = math.floor(self.gameTimer.time / 60)
        local seconds = math.floor(self.gameTimer.time % 60)
        local timeStr = string.format("%02d:%02d", minutes, seconds)

        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.print(timeStr, 22, love.graphics.getHeight() - 78)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(timeStr, 20, love.graphics.getHeight() - 80)
    end

    -- Draw converted folks counter
    love.graphics.setFont(self.converted.font)
    local padding = 20
    local screenWidth = love.graphics.getWidth()
    local bgX = screenWidth - self.converted.bgImage:getWidth() - padding
    local bgY = padding
    love.graphics.draw(self.converted.bgImage, bgX, bgY)

    love.graphics.setColor(0.086, 0.11, 0.18, 1)
    local textX = bgX + 45
    local textY = bgY + 20
    love.graphics.print("Folks Converted:   " .. self.converted.peopleConverted, textX, textY)
    love.graphics.print("Folks Saved:   " .. self.converted.peopleSaved .. " / " .. self.converted.totalFolks, textX, textY + self.converted.font:getHeight() + 11)
    
    -- Draw lifebar
    love.graphics.setColor(1, 1, 1, 1)
    local lifeX = self.life.padding
    local lifeY = self.life.padding
    local leftWidth = self.life.leftBlock:getWidth()
    local rightWidth = self.life.rightBlock:getWidth()
    local middleWidth = self.life.width - leftWidth - rightWidth

    love.graphics.draw(self.life.leftBlock, lifeX, lifeY)
    
    local middleScale = middleWidth / self.life.middleBlock:getWidth()
    love.graphics.draw(self.life.middleBlock, lifeX + leftWidth, lifeY, 0, middleScale, 1)

    love.graphics.draw(self.life.rightBlock, lifeX + leftWidth + middleWidth, lifeY)

    local lifePercentage = player.life / player.maxLife
    local fillWidth = math.max(0, (self.life.width - 48) * lifePercentage)

    if fillWidth > 0 then
        local fillQuad = love.graphics.newQuad(0, 0, fillWidth, self.life.fill:getHeight(), self.life.fill:getWidth(), self.life.fill:getHeight())
        love.graphics.draw(self.life.fill, fillQuad, lifeX + 40, lifeY + 35)
    end

    love.graphics.setFont(prevFont)
    love.graphics.setColor(r, g, b, a)
end

function Hud:update(dt)
    if self.gameTimer.active then
        self.gameTimer.time = self.gameTimer.time + dt
    end
end

function Hud:reset()
    self.gameTimer.time = 0
    self.gameTimer.active = true
    self.converted.peopleConverted = 0
    self.converted.peopleSaved = 0
end

return Hud

