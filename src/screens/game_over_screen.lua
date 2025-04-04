local GameOverScreen = {}

local config = {
    font = nil,
    smallFont = nil,
    buttonWidth = 200,
    buttonHeight = 60,
    gameOverSound = nil,
    soundPlayed = false
}

function GameOverScreen:load(sounds)
    config.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 48)
    config.smallFont = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 24)

    config.gameOverSound = sounds.gameover:clone()
end

function GameOverScreen:draw(gameTimer, hud)
    if not config.soundPlayed then
        config.gameOverSound:play()
        config.soundPlayed = true
    end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Game Over Text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(config.font)
    local gameOverText = "Game Over"
    love.graphics.printf(gameOverText, 0, screenH / 6, screenW, "center")

    -- Stats Text
    love.graphics.setFont(config.smallFont)
    local timeStr = "N/A"
    if gameTimer then
       timeStr = string.format("%02d:%02d",
            math.floor(gameTimer.time / 60),
            math.floor(gameTimer.time % 60)
        )
    end
    local statsText = string.format("Folks Converted: %d\nFolks Saved: %d/%d\nTime: %s",
        hud.converted.peopleConverted or 0, -- Use default if hud not ready
        hud.converted.peopleSaved or 0,
        hud.converted.totalFolks or 0,
        timeStr
    )
    love.graphics.printf(statsText, 0, screenH / 3, screenW, "center")

    -- Button
    local buttonText = "Try Again"
    local buttonX = (screenW - config.buttonWidth) / 2
    local buttonY = screenH * 0.7
    love.graphics.setColor(0.2, 0.4, 0.8, 1)
    love.graphics.rectangle("fill", buttonX, buttonY, config.buttonWidth, config.buttonHeight, 10)

    -- Button Text
    love.graphics.setColor(1, 1, 1, 1)
    local btnTextH = config.smallFont:getHeight()
    love.graphics.printf(buttonText, buttonX, buttonY + (config.buttonHeight - btnTextH) / 2, config.buttonWidth, "center")

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function GameOverScreen:mousepressed(x, y, button, GameState)
     if button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local buttonX = (screenW - config.buttonWidth) / 2
        local buttonY = screenH * 0.7

        if x >= buttonX and x <= buttonX + config.buttonWidth and
           y >= buttonY and y <= buttonY + config.buttonHeight then
            config.soundPlayed = false
            return "reset"
        end
    end
    return nil
end

function GameOverScreen:keypressed(key, GameState)
    if key == "return" or key == "kpenter" then
        config.soundPlayed = false
        return "reset"
    end
    return nil
end

return GameOverScreen
