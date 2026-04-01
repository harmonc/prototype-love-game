require "objects"
require "render.background"
require "render.ui"

--[[
    Main renderer: Coordinates all visual output
    1. Background (starfield)
    2. Grid (with animations)
    3. UI (buttons, inventory, menus)
    4. Overlays (pause, debug)
]]
function drawGame()
    -- Background layer
    drawBackground()
    
    -- Grid layer (includes object rendering with animations)
    grid:draw(SCREEN.WIDTH, SCREEN.HEIGHT, showGrid)
    
    -- Mouse highlight
    drawHighlight()
    
    -- Preview of selected object
    drawPreview()
    
    -- Debug info
    drawDebugInfo()
    
    -- Buttons layer
    drawButtons()
    
    -- Inventory bar
    drawInventory()
    
    -- Pause/Debug menus (conditional)
    if paused and not pendingScreenshot then
        drawPauseMenu()
    end
    
    if showDebugMenu then
        drawDebugMenu()
    end
    
    -- Screenshot capture
    if pendingScreenshot then
        captureScreenshot()
    end
end

-- Mouse cursor cell highlight
function drawHighlight()
    local mouseX, mouseY = love.mouse.getPosition()
    local col, row = grid:getCellAt(mouseX, mouseY)
    
    local highlightX = (col * grid.cellSize + grid.offsetX) * grid.scale
    local highlightY = (row * grid.cellSize + grid.offsetY) * grid.scale
    local highlightSize = grid.cellSize * grid.scale
    
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle("fill", highlightX, highlightY, highlightSize, highlightSize)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw preview of selected inventory item at mouse position
function drawPreview()
    if paused then return end
    
    local mouseX, mouseY = love.mouse.getPosition()
    local col, row = grid:getCellAt(mouseX, mouseY)
    
    local highlightX = (col * grid.cellSize + grid.offsetX) * grid.scale
    local highlightY = (row * grid.cellSize + grid.offsetY) * grid.scale
    local highlightSize = grid.cellSize * grid.scale
    
    local currentObj = inventory[selectedInventorySlot]
    if currentObj and currentObj.type then
        local preview = (currentObj.type == "circle" and Circle.new() or Triangle.new(triangleDirection))
        preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.5}
        preview:draw(highlightX, highlightY, highlightSize)
    end
end

-- Debug info overlay
function drawDebugInfo()
    if not debug then return end
    
    local mouseX, mouseY = love.mouse.getPosition()
    local col, row = grid:getCellAt(mouseX, mouseY)
    
    love.graphics.setColor(0.1, 0.15, 0.2, 0.8)
    love.graphics.rectangle("fill", 5, 5, 150, 85)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Zoom: " .. string.format("%.2f", grid.scale), 10, 10)
    love.graphics.print("Grid X: " .. string.format("%.0f", grid.offsetX), 10, 25)
    love.graphics.print("Grid Y: " .. string.format("%.0f", grid.offsetY), 10, 40)
    love.graphics.print("Cell: " .. col .. ", " .. row, 10, 55)
    love.graphics.print("Grid Lines: " .. (showGrid and "ON" or "OFF"), 10, 70)
end
