local VictoryScreen = {}

local config = {
    font = nil,
    smallFont = nil,
    buttonWidth = 200,
    buttonHeight = 60
}

function VictoryScreen:load()
    config.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 48)
    config.smallFont = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 24)
end

function VictoryScreen:draw(gameTimer)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Victory Text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(config.font)
    local victoryText = "Victory!"
    love.graphics.printf(victoryText, 0, screenH / 6, screenW, "center")

    -- Stats Text
    love.graphics.setFont(config.smallFont)
    local timeStr = "N/A"
    if gameTimer then
       timeStr = string.format("%02d:%02d",
            math.floor(gameTimer.time / 60),
            math.floor(gameTimer.time % 60)
        )
    end
    local statsText = string.format("Time: %s", timeStr)
    love.graphics.printf(statsText, 0, screenH / 3, screenW, "center")

    -- Button
    love.graphics.setFont(config.smallFont)
    local buttonText = "Play Again"
    local buttonX = (screenW - config.buttonWidth) / 2
    local buttonY = screenH * 0.6
    love.graphics.setColor(0.2, 0.4, 0.8, 1)
    love.graphics.rectangle("fill", buttonX, buttonY, config.buttonWidth, config.buttonHeight, 10)

    -- Button Text
    love.graphics.setColor(1, 1, 1, 1)
    local btnTextH = config.smallFont:getHeight()
    love.graphics.printf(buttonText, buttonX, buttonY + (config.buttonHeight - btnTextH) / 2, config.buttonWidth, "center")

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function VictoryScreen:mousepressed(x, y, button, GameState)
    if button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local buttonX = (screenW - config.buttonWidth) / 2
        local buttonY = screenH * 0.6

        if x >= buttonX and x <= buttonX + config.buttonWidth and
           y >= buttonY and y <= buttonY + config.buttonHeight then
            return "reset"
        end
    end
    return nil
end

function VictoryScreen:keypressed(key, GameState)
     if key == "return" or key == "kpenter" then
        return "reset"
    end
    return nil
end

return VictoryScreen
