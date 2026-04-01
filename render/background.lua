require "src.utils"

--[[ Background renderer: Starfield with tiling support ]]

local starfield = nil
local starfieldQuad = nil
local starfieldScale = 4

function initBackground()
    starfield = love.graphics.newImage("pixelart_starfield.png")
    starfield:setFilter("nearest", "nearest")  -- Pixel art, no smoothing
    starfield:setWrap("repeat", "repeat")
    
    local imgW, imgH = starfield:getDimensions()
    starfieldQuad = love.graphics.newQuad(
        0, 0,
        SCREEN.WIDTH / starfieldScale,
        SCREEN.HEIGHT / starfieldScale,
        imgW, imgH
    )
end

function drawBackground()
    love.graphics.draw(starfield, starfieldQuad, 0, 0, 0, starfieldScale)
end
