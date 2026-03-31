require "grid"
require "save"

function love.load()
    love.window.setMode(1280, 800, {msaa = 8})
    love.graphics.setDefaultFilter("linear", "linear")
    grid = Grid.new(50)
    
    starfield = love.graphics.newImage("pixelart_starfield.png")
    starfield:setFilter("nearest", "nearest")
    starfield:setWrap("repeat", "repeat")
    starfieldScale = 4
    local imgW, imgH = starfield:getDimensions()
    starfieldQuad = love.graphics.newQuad(0, 0, 1280 / starfieldScale, 800 / starfieldScale, imgW, imgH)
    
    debug = false
    showGrid = false
    isDragging = false
    objectType = "circle"
    triangleDirection = 0

    paused = false
    pauseMenuSelection = 1
    pauseMenuOptions = {"Save", "Screenshot", "Resume", "Quit"}
    
    showDebugMenu = false
    debugMenuSelection = 1
    debugMenuOptions = {"Clear Grid", "Clear Save & Reload", "Back"}
    pendingScreenshot = false
    screenshotCallback = nil

    inventory = {
        { type = "circle", name = "Circle" },
        { type = "triangle", name = "Triangle" },
        {}, {}, {}, {}, {}, {}, {}, {}
    }
    selectedInventorySlot = 1
    inventoryBarHeight = 80
    inventoryBarTarget = 80
    inventoryBarMin = 10
    stepButton = { x = 1080, y = 10, width = 80, height = 40 }
    playButton = { x = 1170, y = 10, width = 80, height = 40 }
    isPlaying = false
    stepTimer = 0
    stepInterval = 0.2

    leftMouseDown = false
    rightMouseDown = false
    lastPaintCol = nil
    lastPaintRow = nil

    loadGame(grid)
end

function gameStep()
    local newObjects = {}
    
    for key, obj in pairs(grid.objects) do
        if obj.type ~= "triangle" then
            newObjects[key] = obj
        end
    end
    
    local triangles = {}
    for key, obj in pairs(grid.objects) do
        if obj.type == "triangle" then
            local col, row = key:match("([^,]+),(.+)")
            table.insert(triangles, {key = key, col = tonumber(col), row = tonumber(row), obj = obj})
        end
    end
    
    table.sort(triangles, function(a, b)
        if a.col ~= b.col then return a.col < b.col end
        return a.row < b.row
    end)
    
    for _, tri in ipairs(triangles) do
        local key = tri.key
        local col = tri.col
        local row = tri.row
        local obj = tri.obj
        
        local dx, dy
        if obj.direction == 0 then dy = -1
        elseif obj.direction == 1 then dy = 1
        elseif obj.direction == 2 then dx = -1
        elseif obj.direction == 3 then dx = 1
        end
        
        local newCol = col + (dx or 0)
        local newRow = row + (dy or 0)
        local newKey = newCol .. "," .. newRow
        
        if not grid.objects[newKey] and not newObjects[newKey] then
            newObjects[newKey] = { type = "triangle", direction = obj.direction }
            print("Triangle moved from " .. key .. " to " .. newKey)
        else
            newObjects[key] = obj
        end
    end
    
    grid.objects = newObjects
    
    for key, obj in pairs(grid.objects) do
        if obj.type == "triangle" then
            obj.direction = math.random(0, 3)
        end
    end
end

function love.update(dt)
    if not paused then
        grid:update()
        if isPlaying then
            stepTimer = stepTimer + dt
            if stepTimer >= stepInterval then
                stepTimer = stepTimer - stepInterval
                gameStep()
            end
        end
    end
    
    local mouseY = love.mouse.getY()
    local threshold = 800 - 120
    if mouseY > threshold then
        inventoryBarTarget = 80
    else
        inventoryBarTarget = inventoryBarMin
    end
    inventoryBarHeight = inventoryBarHeight + (inventoryBarTarget - inventoryBarHeight) * 10 * dt
end

function love.draw()
    love.graphics.draw(starfield, starfieldQuad, 0, 0, 0, starfieldScale)
    
    grid:draw(1280, 800, showGrid)

    local mouseX, mouseY = love.mouse.getPosition()
    local col, row = grid:getCellAt(mouseX, mouseY)
    local highlightX = (col * grid.cellSize + grid.offsetX) * grid.scale
    local highlightY = (row * grid.cellSize + grid.offsetY) * grid.scale
    local highlightSize = grid.cellSize * grid.scale
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.rectangle("fill", highlightX, highlightY, highlightSize, highlightSize)
    love.graphics.setColor(1, 1, 1, 1)

    if not paused then
        local currentObj = inventory[selectedInventorySlot]
        if currentObj and currentObj.type then
            if currentObj.type == "circle" then
                local preview = Circle.new()
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.5}
                preview:draw(highlightX, highlightY, highlightSize)
            elseif currentObj.type == "triangle" then
                local preview = Triangle.new(triangleDirection)
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.5}
                preview:draw(highlightX, highlightY, highlightSize)
            end
        end
    end
    
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

    love.graphics.setColor(0.2, 0.6, 0.3, 1)
    love.graphics.rectangle("fill", stepButton.x, stepButton.y, stepButton.width, stepButton.height)
    love.graphics.setColor(0.3, 0.8, 0.4, 1)
    love.graphics.rectangle("line", stepButton.x, stepButton.y, stepButton.width, stepButton.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("STEP", stepButton.x, stepButton.y + 12, stepButton.width, "center")

    if isPlaying then
        love.graphics.setColor(0.8, 0.3, 0.3, 1)
    else
        love.graphics.setColor(0.3, 0.6, 0.8, 1)
    end
    love.graphics.rectangle("fill", playButton.x, playButton.y, playButton.width, playButton.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", playButton.x, playButton.y, playButton.width, playButton.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(isPlaying and "STOP" or "PLAY", playButton.x, playButton.y + 12, playButton.width, "center")

    local barY = 800 - inventoryBarHeight
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, barY, 1280, inventoryBarHeight)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("line", 0, barY, 1280, inventoryBarHeight)

    local maxSlotSize = 60
    local slotPadding = 10
    local totalSlots = 10
    local slotScale = inventoryBarHeight / 80
    local slotSize = maxSlotSize * slotScale
    local slotOffset = (80 - inventoryBarHeight) / 2
    local startX = (1280 - (totalSlots * (maxSlotSize + slotPadding) - slotPadding)) / 2

    for i = 1, totalSlots do
        local slotX = startX + (i - 1) * (maxSlotSize + slotPadding)
        local slotY = barY + slotOffset

        if i == selectedInventorySlot then
            love.graphics.setColor(0.4, 0.4, 0.5, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.25, 1)
        end
        love.graphics.rectangle("fill", slotX, slotY, maxSlotSize, maxSlotSize)
        love.graphics.setColor(0.5, 0.5, 0.6, 1)
        love.graphics.rectangle("line", slotX, slotY, maxSlotSize, maxSlotSize)

        local item = inventory[i]
        if item and item.type then
            if item.type == "circle" then
                local preview = Circle.new()
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.8}
                preview:draw(slotX, slotY, maxSlotSize)
            elseif item.type == "triangle" then
                local preview = Triangle.new(0)
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.8}
                preview:draw(slotX, slotY, maxSlotSize)
            end
        end
    end

    if paused and not pendingScreenshot then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 1280, 800)
        
        local menuWidth = 300
        local menuHeight = 220
        local menuX = (1280 - menuWidth) / 2
        local menuY = (800 - menuHeight) / 2
        
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("PAUSED", menuX, menuY + 20, menuWidth, "center")
        
        for i, option in ipairs(pauseMenuOptions) do
            if i == pauseMenuSelection then
                love.graphics.setColor(1, 0.8, 0.2, 1)
                love.graphics.print("> " .. option, menuX + 30, menuY + 60 + (i - 1) * 30)
            else
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
                love.graphics.print("  " .. option, menuX + 30, menuY + 60 + (i - 1) * 30)
            end
        end
        
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.print("Press Enter/Space to select", menuX + 30, menuY + menuHeight - 25)
    end
    
    if showDebugMenu then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 1280, 800)
        
        local menuWidth = 300
        local menuHeight = 180
        local menuX = (1280 - menuWidth) / 2
        local menuY = (800 - menuHeight) / 2
        
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("DEBUG MENU", menuX, menuY + 20, menuWidth, "center")
        
        for i, option in ipairs(debugMenuOptions) do
            if i == debugMenuSelection then
                love.graphics.setColor(1, 0.8, 0.2, 1)
                love.graphics.print("> " .. option, menuX + 30, menuY + 60 + (i - 1) * 30)
            else
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
                love.graphics.print("  " .. option, menuX + 30, menuY + 60 + (i - 1) * 30)
            end
        end
        
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.print("Press F1 to toggle, Enter/Space to select", menuX + 30, menuY + menuHeight - 25)
    end
    
    if pendingScreenshot then
        love.graphics.captureScreenshot(function(imageData)
            local filename = "screenshot_" .. os.time() .. ".png"
            local file = love.filesystem.newFile(filename, "w")
            local encoded = imageData:encode("png")
            file:write(encoded)
            file:close()
            print("Screenshot saved: " .. love.filesystem.getSaveDirectory() .. "/" .. filename)
            pendingScreenshot = false
            paused = true
        end)
    end
end

function love.mousepressed(x, y, button)
    if paused then return end

    if x >= stepButton.x and x <= stepButton.x + stepButton.width and
       y >= stepButton.y and y <= stepButton.y + stepButton.height then
        gameStep()
        return
    end
    
    if x >= playButton.x and x <= playButton.x + playButton.width and
       y >= playButton.y and y <= playButton.y + playButton.height then
        isPlaying = not isPlaying
        return
    end

    local barY = 800 - inventoryBarHeight
    if y > barY then
        local slotSize = 60
        local slotPadding = 10
        local totalSlots = 10
        local startX = (1280 - (totalSlots * (slotSize + slotPadding) - slotPadding)) / 2

        for i = 1, totalSlots do
            local slotX = startX + (i - 1) * (slotSize + slotPadding)
            local slotY = barY + (inventoryBarHeight - slotSize) / 2

            if x >= slotX and x <= slotX + slotSize and y >= slotY and y <= slotY + slotSize then
                if inventory[i] and inventory[i].type then
                    selectedInventorySlot = i
                    objectType = inventory[i].type
                    print("Selected: " .. inventory[i].name)
                end
                return
            end
        end
        return
    end

    if button == "m" or button == 3 then
        dragWorldX = x / grid.scale - grid.offsetX
        dragWorldY = y / grid.scale - grid.offsetY
        isDragging = true
        return
    end

    local col, row = grid:getCellAt(x, y)
    local key = col .. "," .. row
    
    if button == "l" or button == 1 then
        leftMouseDown = true
        lastPaintCol = col
        lastPaintRow = row
        local currentObj = inventory[selectedInventorySlot]
        if currentObj and currentObj.type then
            if currentObj.type == "circle" then
                grid.objects[key] = { type = "circle" }
            else
                grid.objects[key] = { type = "triangle", direction = triangleDirection }
            end
        end
    elseif button == "r" or button == 2 then
        rightMouseDown = true
        lastPaintCol = col
        lastPaintRow = row
        grid.objects[key] = nil
    end
end

function love.mousereleased(x, y, button)
    if button == "m" or button == 3 then
        isDragging = false
    elseif button == "l" or button == 1 then
        leftMouseDown = false
        lastPaintCol = nil
        lastPaintRow = nil
    elseif button == "r" or button == 2 then
        rightMouseDown = false
        lastPaintCol = nil
        lastPaintRow = nil
    end
end

function love.mousemoved(x, y, dx, dy)
    if paused then return end
    if isDragging then
        grid.offsetX = x / grid.scale - dragWorldX
        grid.offsetY = y / grid.scale - dragWorldY
    end

    local col, row = grid:getCellAt(x, y)
    if col ~= lastPaintCol or row ~= lastPaintRow then
        local key = col .. "," .. row
        
        if leftMouseDown then
            local currentObj = inventory[selectedInventorySlot]
            if currentObj and currentObj.type then
                if currentObj.type == "circle" then
                    grid.objects[key] = { type = "circle" }
                else
                    grid.objects[key] = { type = "triangle", direction = triangleDirection }
                end
            end
            lastPaintCol = col
            lastPaintRow = row
        elseif rightMouseDown then
            grid.objects[key] = nil
            lastPaintCol = col
            lastPaintRow = row
        end
    end
end

function love.wheelmoved(x, y)
    if paused then return end
    local mouseX, mouseY = love.mouse.getPosition()
    grid:zoom(y, mouseX, mouseY)
end

function love.keypressed(key)
    if key == "f1" then
        showDebugMenu = not showDebugMenu
        debugMenuSelection = 1
        paused = showDebugMenu
        return
    end
    
    if showDebugMenu then
        if key == "up" or key == "w" then
            debugMenuSelection = debugMenuSelection - 1
            if debugMenuSelection < 1 then debugMenuSelection = #debugMenuOptions end
        elseif key == "down" or key == "s" then
            debugMenuSelection = debugMenuSelection + 1
            if debugMenuSelection > #debugMenuOptions then debugMenuSelection = 1 end
        elseif key == "return" or key == "space" then
            if debugMenuSelection == 1 then
                grid.objects = {}
                print("Grid cleared!")
                showDebugMenu = false
                paused = false
            elseif debugMenuSelection == 2 then
                saveGame(grid, true)
                print("Save cleared and game reloaded!")
            elseif debugMenuSelection == 3 then
                showDebugMenu = false
                paused = false
            end
        end
        return
    end

    if key == "escape" or key == "p" then
        paused = not paused
        pauseMenuSelection = 1
        return
    end

    if paused then
        if key == "up" or key == "w" then
            pauseMenuSelection = pauseMenuSelection - 1
            if pauseMenuSelection < 1 then pauseMenuSelection = #pauseMenuOptions end
        elseif key == "down" or key == "s" then
            pauseMenuSelection = pauseMenuSelection + 1
            if pauseMenuSelection > #pauseMenuOptions then pauseMenuSelection = 1 end
        elseif key == "return" or key == "space" then
            if pauseMenuSelection == 1 then
                saveGame(grid)
                paused = false
            elseif pauseMenuSelection == 2 then
                pendingScreenshot = true
                paused = false
                return
            elseif pauseMenuSelection == 3 then
                paused = false
            elseif pauseMenuSelection == 4 then
                saveGame(grid)
                love.event.quit()
            end
        end
        return
    end

    if key == "g" then
        debug = not debug
    elseif key == "h" then
        showGrid = not showGrid
    elseif key == "t" then
        objectType = objectType == "circle" and "triangle" or "circle"
        print("Object type: " .. objectType)
    elseif tonumber(key) then
        local num = tonumber(key)
        if num == 0 then num = 10 end
        if inventory[num] and inventory[num].type then
            selectedInventorySlot = num
            objectType = inventory[num].type
            print("Selected: " .. inventory[num].name)
        end
    elseif key == "r" then
        local rotationCycle = { [0]=3, [3]=1, [1]=2, [2]=0 }
        triangleDirection = rotationCycle[triangleDirection]
        local dirNames = {"up", "right", "down", "left"}
        print("Triangle direction: " .. dirNames[triangleDirection + 1])
    elseif key == "space" then
        gameStep()
    end
end
