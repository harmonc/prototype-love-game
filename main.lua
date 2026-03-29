require "grid"
require "save"

function love.load()
    love.window.setMode(1280, 800, {msaa = 8})
    love.graphics.setDefaultFilter("linear", "linear")
    grid = Grid.new(50)
    debug = false
    showGrid = true
    isDragging = false

    loadGame(grid)
end

function love.update(dt)
    grid:update()
end

function love.draw()
    love.graphics.setColor(0.05, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 800)
    
    grid:draw(1280, 800, showGrid)

    local mouseX, mouseY = love.mouse.getPosition()
    local col, row = grid:getCellAt(mouseX, mouseY)
    local highlightX = (col * grid.cellSize + grid.offsetX) * grid.scale
    local highlightY = (row * grid.cellSize + grid.offsetY) * grid.scale
    local highlightSize = grid.cellSize * grid.scale
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle("fill", highlightX, highlightY, highlightSize, highlightSize)
    love.graphics.setColor(1, 1, 1, 1)
    
    if debug then
        love.graphics.setColor(0.1, 0.15, 0.2, 0.8)
        love.graphics.rectangle("fill", 5, 5, 150, 85)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Zoom: " .. string.format("%.2f", grid.scale), 10, 10)
        love.graphics.print("Grid X: " .. string.format("%.0f", grid.offsetX), 10, 25)
        love.graphics.print("Grid Y: " .. string.format("%.0f", grid.offsetY), 10, 40)
        love.graphics.print("Cell: " .. col .. ", " .. row, 10, 55)
        love.graphics.print("Grid Lines: " .. (showGrid and "ON" or "OFF"), 10, 70)
    end
end

function love.mousepressed(x, y, button)
    if button == "m" or button == 3 then
        dragWorldX = x / grid.scale - grid.offsetX
        dragWorldY = y / grid.scale - grid.offsetY
        isDragging = true
        return
    end

    local col, row = grid:getCellAt(x, y)
    local key = col .. "," .. row
    
    if button == "l" or button == 1 then
        local existing = grid.objects[key]
        if existing then
            print("Replacing object at " .. key)
        else
            print("Placing new object at " .. key)
        end
        grid.objects[key] = { type = "circle" }
    elseif button == "r" or button == 2 then
        local existing = grid.objects[key]
        if existing then
            print("Removing object at " .. key)
            grid.objects[key] = nil
        end
    end
end

function love.mousereleased(x, y, button)
    if button == "m" or button == 3 then
        isDragging = false
    end
end

function love.mousemoved(x, y, dx, dy)
    if isDragging then
        grid.offsetX = x / grid.scale - dragWorldX
        grid.offsetY = y / grid.scale - dragWorldY
    end
end

function love.wheelmoved(x, y)
    local mouseX, mouseY = love.mouse.getPosition()
    grid:zoom(y, mouseX, mouseY)
end

function love.keypressed(key)
    if key == "g" then
        debug = not debug
    elseif key == "h" then
        showGrid = not showGrid
    elseif key == "s" then
        saveGame(grid)
    end
end
