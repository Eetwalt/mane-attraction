local TitleScreen = {}

local config = {
    font = nil,
    buttonFont = nil,
    bgImage = nil,
    buttonWidth = 200,
    buttonHeight = 80,
    bannerScale = 1.5
}

function TitleScreen:load()
    config.font = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 72)
    config.buttonFont = love.graphics.newFont('assets/Fonts/InknutAntiqua-SemiBold.ttf', 36)
    config.bgImage = love.graphics.newImage('assets/UI/Banners/Title-Banner.png')
end

function TitleScreen:draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Background
    love.graphics.setColor(0.1, 0.15, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Banner
    love.graphics.setColor(1, 1, 1, 1)
    local bannerW = config.bgImage:getWidth() * config.bannerScale
    local bannerH = config.bgImage:getHeight() * config.bannerScale
    local bannerX = (screenW - bannerW) / 2
    local bannerY = screenH / 3.5 - bannerH / 2
    love.graphics.draw(config.bgImage, bannerX, bannerY, 0, config.bannerScale, config.bannerScale)

    -- Title Text
    love.graphics.setFont(config.font)
    local title = "Mane Attraction"
    local titleW = config.font:getWidth(title)
    local titleH = config.font:getHeight()
    love.graphics.setColor(0.086, 0.11, 0.18, 1) -- Text color inside banner
    love.graphics.printf(title, 0, screenH / 4 - titleH / 2, screenW, "center")

    -- Button
    love.graphics.setFont(config.buttonFont)
    local buttonText = "Play"
    local buttonX = (screenW - config.buttonWidth) / 2
    local buttonY = screenH * 0.6
    love.graphics.setColor(0.2, 0.4, 0.8, 1) -- Button color
    love.graphics.rectangle("fill", buttonX, buttonY, config.buttonWidth, config.buttonHeight, 10)

    -- Button Text
    love.graphics.setColor(1, 1, 1, 1) -- Button text color
    local btnTextW = config.buttonFont:getWidth(buttonText)
    local btnTextH = config.buttonFont:getHeight()
    love.graphics.printf(buttonText, buttonX, buttonY + (config.buttonHeight - btnTextH) / 2, config.buttonWidth, "center")

    -- Reset color and font
    love.graphics.setColor(1, 1, 1, 1)
end

function TitleScreen:mousepressed(x, y, button, GameState)
    if button == 1 then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local buttonX = (screenW - config.buttonWidth) / 2
        local buttonY = screenH * 0.6

        if x >= buttonX and x <= buttonX + config.buttonWidth and
           y >= buttonY and y <= buttonY + config.buttonHeight then
            return GameState.PLAYING
        end
    end
    return nil
end

function TitleScreen:keypressed(key, GameState)
    if key == "return" or key == "kpenter" then
        return GameState.PLAYING
    end
    return nil
end

return TitleScreen
