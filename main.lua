require "grid"
require "save"
require "levels.levelLoader"

function love.load()
    love.window.setMode(1280, 800, {msaa = 8})
    love.graphics.setDefaultFilter("linear", "linear")
    grid = Grid.new(50)
    debug = false
    showGrid = true
    isDragging = false
    objectType = "circle"
    triangleDirection = 0

    paused = false
    pauseMenuSelection = 1
    pauseMenuOptions = {"Save", "Load", "Screenshot", "Resume", "Quit"}
    pendingScreenshot = false
    screenshotCallback = nil

    currentLevel = 1
    levelWon = false
    
    inventory = {
        { type = "circle", name = "Circle", cost = 10, limit = 5 },
        { type = "triangle", name = "Triangle", cost = 20, limit = 3 },
        { type = "block", name = "Block", cost = 0, limit = 1 },
        { type = "target", name = "Target", cost = 0, limit = 1 },
        {}, {}, {}, {}, {}, {}
    }
    inventoryUsage = {
        circle = 0,
        triangle = 0,
        block = 0,
        target = 0
    }
    selectedInventorySlot = 1
    inventoryBarHeight = 80
    stepButton = { x = 1080, y = 10, width = 90, height = 40 }

    leftMouseDown = false
    rightMouseDown = false
    lastPaintCol = nil
    lastPaintRow = nil

    loadLevel(currentLevel)
end

function loadLevel(levelNum)
    local level = LevelLoader.loadLevel(levelNum)
    if not level then
        print("Failed to load level " .. levelNum)
        return
    end
    
    currentLevelNum = level.level
    levelName = level.name
    budget = level.budget
    
    for k, v in pairs(level.inventory) do
        for i, item in ipairs(inventory) do
            if item.type == k then
                item.cost = v.cost
                item.limit = v.limit
            end
        end
    end
    
    local preplaced = LevelLoader.getPreplacedObjects(level)
    grid.objects = preplaced
    
    inventoryUsage = {
        circle = 0,
        triangle = 0,
        block = 0,
        target = 0
    }
    
    for key, obj in pairs(grid.objects) do
        if obj.type == "block" then inventoryUsage.block = 1
        elseif obj.type == "target" then inventoryUsage.target = 1
        end
    end
    
    levelWon = false
    print("Loaded level: " .. levelName)
    
    loadLevelProgress(levelNum)
end

function saveLevelProgress(levelNum)
    local saveData = {
        objects = grid.objects,
        offsetX = grid.offsetX,
        offsetY = grid.offsetY,
        scale = grid.scale
    }
    love.filesystem.write("level_" .. levelNum .. ".json", JSON.encode(saveData))
    print("Level " .. levelNum .. " saved")
end

function loadLevelProgress(levelNum)
    local filename = "level_" .. levelNum .. ".json"
    local info = love.filesystem.getInfo(filename)
    if info then
        local data = love.filesystem.read(filename)
        local saveData = JSON.decode(data)
        if saveData then
            grid.objects = saveData.objects or {}
            grid.offsetX = saveData.offsetX or 0
            grid.offsetY = saveData.offsetY or 0
            grid.scale = saveData.scale or 1
            print("Level " .. levelNum .. " progress loaded")
        end
    end
end

function gameStep()
    if levelWon then return end
    
    local newObjects = {}
    local triangleMoved = {}
    local blockMoved = nil
    local blockOnTarget = false
    
    for key, obj in pairs(grid.objects) do
        if obj.type == "triangle" then
            local col, row = key:match("([^,]+),(.+)")
            col = tonumber(col)
            row = tonumber(row)
            
            local dx, dy
            if obj.direction == 0 then dy = -1
            elseif obj.direction == 1 then dy = 1
            elseif obj.direction == 2 then dx = -1
            elseif obj.direction == 3 then dx = 1
            end
            
            local newCol = col + (dx or 0)
            local newRow = row + (dy or 0)
            local newKey = newCol .. "," .. newRow
            
            local targetObj = grid.objects[newKey]
            
            if targetObj and targetObj.type == "block" then
                local blockDx = dx or 0
                local blockDy = dy or 0
                local blockNewCol = newCol + blockDx
                local blockNewRow = newRow + blockDy
                local blockNewKey = blockNewCol .. "," .. blockNewRow
                
                local blockTarget = grid.objects[blockNewKey]
                
                if blockTarget and blockTarget.type == "target" then
                    newObjects[newKey] = { type = "triangle", direction = obj.direction }
                    triangleMoved[key] = true
                    blockMoved = newKey
                    blockOnTarget = true
                    print("Triangle pushed block onto target!")
                elseif not blockTarget and not newObjects[blockNewKey] then
                    newObjects[blockNewKey] = { type = "block" }
                    newObjects[newKey] = { type = "triangle", direction = obj.direction }
                    triangleMoved[key] = true
                    blockMoved = newKey
                    print("Triangle pushed block from " .. newKey .. " to " .. blockNewKey)
                else
                    newObjects[key] = obj
                end
            elseif not targetObj and not newObjects[newKey] then
                newObjects[newKey] = { type = "triangle", direction = obj.direction }
                triangleMoved[key] = true
            else
                newObjects[key] = obj
            end
        elseif obj.type == "block" then
            if key ~= blockMoved then
                newObjects[key] = obj
            end
        else
            newObjects[key] = obj
        end
    end
    
    grid.objects = newObjects
    
    if blockOnTarget then
        levelWon = true
        print("LEVEL COMPLETE! Press N for next level")
    end
end

function checkWinCondition()
    local blockPos = nil
    local targetPos = nil
    
    for key, obj in pairs(grid.objects) do
        if obj.type == "block" then
            blockPos = key
        elseif obj.type == "target" then
            targetPos = key
        end
    end
    
    if blockPos and targetPos and blockPos == targetPos then
        levelWon = true
        print("LEVEL COMPLETE! Press N for next level")
    end
end

function love.update(dt)
    if not paused then
        grid:update()
    end
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

    if not paused and not levelWon then
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
            elseif currentObj.type == "block" then
                local preview = Block.new()
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.5}
                preview:draw(highlightX, highlightY, highlightSize)
            elseif currentObj.type == "target" then
                local preview = Target.new()
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

    local barY = 800 - inventoryBarHeight
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, barY, 1280, inventoryBarHeight)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("line", 0, barY, 1280, inventoryBarHeight)

    local slotSize = 60
    local slotPadding = 10
    local totalSlots = 10
    local startX = (1280 - (totalSlots * (slotSize + slotPadding) - slotPadding)) / 2

    for i = 1, totalSlots do
        local slotX = startX + (i - 1) * (slotSize + slotPadding)
        local slotY = barY + (inventoryBarHeight - slotSize) / 2

        if i == selectedInventorySlot then
            love.graphics.setColor(0.4, 0.4, 0.5, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.25, 1)
        end
        love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize)
        love.graphics.setColor(0.5, 0.5, 0.6, 1)
        love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize)

        local item = inventory[i]
        if item and item.type then
            if item.type == "circle" then
                local preview = Circle.new()
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.8}
                preview:draw(slotX, slotY, slotSize)
            elseif item.type == "triangle" then
                local preview = Triangle.new(0)
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.8}
                preview:draw(slotX, slotY, slotSize)
            elseif item.type == "block" then
                local preview = Block.new()
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.8}
                preview:draw(slotX, slotY, slotSize)
            elseif item.type == "target" then
                local preview = Target.new()
                preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.8}
                preview:draw(slotX, slotY, slotSize)
            end
            
            if item.limit then
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                love.graphics.print(item.limit, slotX + slotSize - 12, slotY + slotSize - 12)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Budget: " .. budget, 10, 720)
    if levelName then
        love.graphics.print(levelName, 10, 740)
    end
    if levelWon then
        love.graphics.setColor(0.2, 0.9, 0.3, 1)
        love.graphics.print("LEVEL COMPLETE! Press N for next level", 10, 60)
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
            local canPlace = true
            local objType = currentObj.type
            
            if currentObj.limit and currentObj.limit > 0 then
                local currentCount = 0
                for k, v in pairs(grid.objects) do
                    if v.type == objType then currentCount = currentCount + 1 end
                end
                if currentCount >= currentObj.limit then
                    canPlace = false
                    print("Cannot place " .. objType .. " - limit reached")
                end
            end
            
            if canPlace then
                if objType == "circle" then
                    grid.objects[key] = { type = "circle" }
                elseif objType == "triangle" then
                    grid.objects[key] = { type = "triangle", direction = triangleDirection }
                elseif objType == "block" then
                    grid.objects[key] = { type = "block" }
                elseif objType == "target" then
                    grid.objects[key] = { type = "target" }
                end
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
                local canPlace = true
                local objType = currentObj.type
                
                if currentObj.limit and currentObj.limit > 0 then
                    local currentCount = 0
                    for k, v in pairs(grid.objects) do
                        if v.type == objType then currentCount = currentCount + 1 end
                    end
                    if currentCount >= currentObj.limit then
                        canPlace = false
                    end
                end
                
                if canPlace then
                    if objType == "circle" then
                        grid.objects[key] = { type = "circle" }
                    elseif objType == "triangle" then
                        grid.objects[key] = { type = "triangle", direction = triangleDirection }
                    elseif objType == "block" then
                        grid.objects[key] = { type = "block" }
                    elseif objType == "target" then
                        grid.objects[key] = { type = "target" }
                    end
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
                saveLevelProgress(currentLevel)
                paused = false
            elseif pauseMenuSelection == 2 then
                loadLevelProgress(currentLevel)
                paused = false
            elseif pauseMenuSelection == 3 then
                pendingScreenshot = true
                paused = false
                return
            elseif pauseMenuSelection == 4 then
                paused = false
            elseif pauseMenuSelection == 5 then
                saveLevelProgress(currentLevel)
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
    elseif key == "n" and levelWon then
        saveLevelProgress(currentLevel)
        currentLevel = currentLevel + 1
        loadLevel(currentLevel)
    end
end

function love.quit()
    saveLevelProgress(currentLevel)
    print("Level progress saved on quit")
end
