--[[
    Space Auto Battler - Main Entry Point
    Coordinates rendering, input, and game simulation
]]

require "src.utils"
require "src.grid"
require "systems.save"
require "src.game"
require "systems.handlers"
require "render.renderer"

-- Globals for LÖVE callbacks
grid = nil
inventory = {}
selectedInventorySlot = 1

-- Game state
paused = false
isPlaying = false
stepTimer = 0

-- Input state (globals for handlers.lua)
isDragging = false
leftMouseDown = false
rightMouseDown = false
lastPaintCol = nil
lastPaintRow = nil

-- UI toggles
debug = false
showGrid = false
showDebugMenu = false

-- Placement state
objectType = "circle"
triangleDirection = DIR.UP

-- Screenshot state
pendingScreenshot = false

-- Button definitions
stepButton = { x = 1080, y = 10, width = 90, height = 50 }
playButton = { x = 1170, y = 10, width = 80, height = 40 }
dragWorldX = 0
dragWorldY = 0

--[[ Initialize game on startup ]]
function love.load()
    love.window.setMode(SCREEN.WIDTH, SCREEN.HEIGHT, {msaa = 8})
    love.graphics.setDefaultFilter("linear", "linear")
    
    grid = Grid.new(GRID.CELL_SIZE)
    initBackground()
    
    inventory = {
        { type = "circle", name = "Circle" },
        { type = "triangle", name = "Triangle" },
        {}, {}, {}, {}, {}, {}, {}, {}
    }
    
    loadGame(grid)
end

--[[ Update loop ]]
function love.update(dt)
    grid:update(dt)
    
    if not paused then
        if isPlaying and not grid.animating then
            stepTimer = stepTimer + dt
            if stepTimer >= STEP_INTERVAL then
                stepTimer = stepTimer - STEP_INTERVAL
                gameStep()
            end
        end
    end
    
    updateInventoryBar(dt)
end

--[[ Render loop ]]
function love.draw()
    drawGame()
end

--[[ Mouse handlers ]]
function love.mousepressed(x, y, button)
    if paused then return end
    if checkButtonClick(x, y) then return end
    handleGridInput(x, y, button)
end

function love.mousereleased(x, y, button)
    if button == "l" or button == 1 then
        leftMouseDown = false
    elseif button == "r" or button == 2 then
        rightMouseDown = false
    elseif button == "m" or button == 3 then
        isDragging = false
    end
    lastPaintCol = nil
    lastPaintRow = nil
end

function love.mousemoved(x, y, dx, dy)
    if paused then return end
    handleDrag(x, y)
    handleGridPaint(x, y)
end

function love.wheelmoved(x, y)
    if paused then return end
    local mouseX, mouseY = love.mouse.getPosition()
    grid:zoom(y, mouseX, mouseY)
end

--[[ Keyboard handler ]]
function love.keypressed(key)
    if key == "f1" then
        showDebugMenu = not showDebugMenu
        paused = showDebugMenu
        return
    end
    
    if showDebugMenu then
        handleDebugInput(key)
        return
    end
    
    if key == "escape" or key == "p" then
        paused = not paused
        return
    end
    
    if paused then
        handlePauseInput(key)
        return
    end
    
    handleGameInput(key)
end

-- Helper: check if button was clicked
function checkButtonClick(x, y)
    if x >= stepButton.x and x <= stepButton.x + stepButton.width and
       y >= stepButton.y and y <= stepButton.y + stepButton.height then
        gameStep()
        return true
    end
    
    if x >= playButton.x and x <= playButton.x + playButton.width and
       y >= playButton.y and y <= playButton.y + playButton.height then
        isPlaying = not isPlaying
        return true
    end
    
    return false
end

-- Helper: handle drag
function handleDrag(x, y)
    if isDragging then
        grid.offsetX = x / grid.scale - dragWorldX
        grid.offsetY = y / grid.scale - dragWorldY
    end
end
