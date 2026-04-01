require "src.utils"

--[[ Input handlers and UI logic - separated for clarity ]]

-- Internal state
local inventoryBarTarget = UI.INVENTORY_HEIGHT
local inventoryBarMin = UI.INVENTORY_MIN
local inventoryBarHeight = UI.INVENTORY_HEIGHT
local pauseMenuSelection = 1
local pauseMenuOptions = {"Save", "Screenshot", "Resume", "Quit"}
local debugMenuSelection = 1
local debugMenuOptions = {"Clear Grid", "Clear Save & Reload", "Back"}

-- NOTE: stepButton, playButton, dragWorldX, dragWorldY are globals from main.lua

-- Update inventory bar animation
function updateInventoryBar(dt)
    if not love.mouse then return end
    local mouseY = love.mouse.getY and love.mouse.getY() or 800
    local threshold = SCREEN.HEIGHT - 120
    if mouseY > threshold then
        inventoryBarTarget = UI.INVENTORY_HEIGHT
    else
        inventoryBarTarget = inventoryBarMin
    end
    inventoryBarHeight = inventoryBarHeight + (inventoryBarTarget - inventoryBarHeight) * 10 * dt
end

-- Handle click on grid or inventory
function handleGridInput(x, y, button)
    local barY = SCREEN.HEIGHT - inventoryBarHeight
    
    -- Inventory bar click
    if y > barY then
        handleInventoryClick(x, y, barY)
        return
    end
    
    -- Middle mouse for panning
    if button == "m" or button == 3 then
        dragWorldX = x / grid.scale - grid.offsetX
        dragWorldY = y / grid.scale - grid.offsetY
        isDragging = true
        return
    end
    
    -- Left/right click for painting
    local col, row = grid:getCellAt(x, y)
    local key = makeKey(col, row)
    
    if button == "l" or button == 1 then
        leftMouseDown = true
        lastPaintCol = col
        lastPaintRow = row
        placeObject(key)
    elseif button == "r" or button == 2 then
        rightMouseDown = true
        lastPaintCol = col
        lastPaintRow = row
        grid.objects[key] = nil
    end
end

-- Handle painting while dragging
function handleGridPaint(x, y)
    local col, row = grid:getCellAt(x, y)
    if col == lastPaintCol and row == lastPaintRow then return end
    local key = makeKey(col, row)
    
    if leftMouseDown then
        placeObject(key)
    elseif rightMouseDown then
        grid.objects[key] = nil
    end
    lastPaintCol = col
    lastPaintRow = row
end

-- Place current object at key
function placeObject(key)
    local currentObj = inventory[selectedInventorySlot]
    if currentObj and currentObj.type then
        if currentObj.type == "circle" then
            grid.objects[key] = { type = "circle" }
        else
            grid.objects[key] = { type = "triangle", direction = triangleDirection }
        end
    end
end

-- Handle inventory slot click
function handleInventoryClick(x, y, barY)
    local slotCount = UI.TOTAL_SLOTS * (UI.SLOT_SIZE + UI.SLOT_PADDING) - UI.SLOT_PADDING
    local startX = (SCREEN.WIDTH - slotCount) / 2
    
    for i = 1, UI.TOTAL_SLOTS do
        local slotX = startX + (i - 1) * (UI.SLOT_SIZE + UI.SLOT_PADDING)
        local slotY = barY + (inventoryBarHeight - UI.SLOT_SIZE) / 2
        
        if x >= slotX and x <= slotX + UI.SLOT_SIZE and y >= slotY and y <= slotY + UI.SLOT_SIZE then
            if inventory[i] and inventory[i].type then
                selectedInventorySlot = i
                objectType = inventory[i].type
                print("Selected: " .. inventory[i].name)
            end
            return
        end
    end
end

-- Game input (when not paused)
function handleGameInput(key)
    if key == "g" then
        debug = not debug
    elseif key == "h" then
        showGrid = not showGrid
    elseif key == "t" then
        objectType = (objectType == "circle" and "triangle" or "circle")
        print("Object type: " .. objectType)
    elseif key == "space" then
        gameStep()
    elseif key == "r" then
        triangleDirection = rotateCW(triangleDirection)
        local dirNames = {"up", "right", "down", "left"}
        print("Triangle direction: " .. dirNames[triangleDirection + 1])
    elseif tonumber(key) then
        local num = tonumber(key)
        if num == 0 then num = 10 end
        if inventory[num] and inventory[num].type then
            selectedInventorySlot = num
            objectType = inventory[num].type
            print("Selected: " .. inventory[num].name)
        end
    end
end

-- Pause menu input
function handlePauseInput(key)
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
        elseif pauseMenuSelection == 3 then
            paused = false
        elseif pauseMenuSelection == 4 then
            saveGame(grid)
            love.event.quit()
        end
    end
end

-- Debug menu input
function handleDebugInput(key)
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
end

-- Screenshot capture
function captureScreenshot()
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
