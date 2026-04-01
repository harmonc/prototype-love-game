--[[ UI renderer: Buttons, inventory, menus ]]

-- Internal UI state
local pauseMenuSelection = 1
local pauseMenuOptions = {"Save", "Screenshot", "Resume", "Quit"}
local debugMenuSelection = 1
local debugMenuOptions = {"Clear Grid", "Clear Save & Reload", "Back"}

-- NOTE: stepButton, playButton are globals from main.lua
local inventoryBarHeight = UI.INVENTORY_HEIGHT

-- Draw step/play buttons
function drawButtons()
    -- Step button
    love.graphics.setColor(0.2, 0.6, 0.3, 1)
    love.graphics.rectangle("fill", stepButton.x, stepButton.y, stepButton.width, stepButton.height)
    love.graphics.setColor(0.3, 0.8, 0.4, 1)
    love.graphics.rectangle("line", stepButton.x, stepButton.y, stepButton.width, stepButton.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("STEP", stepButton.x, stepButton.y + 12, stepButton.width, "center")
    
    if grid.animating then
        love.graphics.setColor(0.8, 0.6, 0.2, 1)
        love.graphics.printf("ANIMATING", stepButton.x + 5, stepButton.y + 28, stepButton.width - 10, "center")
    end
    
    -- Play/Stop button
    if isPlaying then
        love.graphics.setColor(0.8, 0.3, 0.3, 1)  -- Red when playing
    else
        love.graphics.setColor(0.3, 0.6, 0.8, 1)  -- Blue when stopped
    end
    love.graphics.rectangle("fill", playButton.x, playButton.y, playButton.width, playButton.height)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", playButton.x, playButton.y, playButton.width, playButton.height)
    love.graphics.printf(isPlaying and "STOP" or "PLAY", playButton.x, playButton.y + 12, playButton.width, "center")
end

-- Draw inventory bar with animation
function drawInventory()
    local barY = SCREEN.HEIGHT - inventoryBarHeight
    
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, barY, SCREEN.WIDTH, inventoryBarHeight)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("line", 0, barY, SCREEN.WIDTH, inventoryBarHeight)
    
    local slotScale = inventoryBarHeight / UI.INVENTORY_HEIGHT
    local slotOffset = (UI.INVENTORY_HEIGHT - inventoryBarHeight) / 2
    
    local slotCount = UI.TOTAL_SLOTS * (UI.SLOT_SIZE + UI.SLOT_PADDING) - UI.SLOT_PADDING
    local startX = (SCREEN.WIDTH - slotCount) / 2
    
    for i = 1, UI.TOTAL_SLOTS do
        local slotX = startX + (i - 1) * (UI.SLOT_SIZE + UI.SLOT_PADDING)
        local slotY = barY + slotOffset
        
        love.graphics.setColor(i == selectedInventorySlot and 0.4 or 0.2, 0.4, 0.5, 1)
        love.graphics.rectangle("fill", slotX, slotY, UI.SLOT_SIZE, UI.SLOT_SIZE)
        love.graphics.setColor(0.5, 0.5, 0.6, 1)
        love.graphics.rectangle("line", slotX, slotY, UI.SLOT_SIZE, UI.SLOT_SIZE)
        
        local item = inventory[i]
        if item and item.type then
            local preview = (item.type == "circle" and Circle.new() or Triangle.new(0))
            preview.color = {preview.color[1], preview.color[2], preview.color[3], 0.8}
            preview:draw(slotX, slotY, UI.SLOT_SIZE)
        end
    end
end

-- Draw pause menu
function drawPauseMenu()
    local menuWidth = 300
    local menuHeight = 220
    local menuX = (SCREEN.WIDTH - menuWidth) / 2
    local menuY = (SCREEN.HEIGHT - menuHeight) / 2
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, SCREEN.WIDTH, SCREEN.HEIGHT)
    
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("PAUSED", menuX, menuY + 20, menuWidth, "center")
    
    for i, option in ipairs(pauseMenuOptions) do
        love.graphics.setColor(i == pauseMenuSelection and 1 or 0.7, 0.8, 0.2, 1)
        local prefix = i == pauseMenuSelection and "> " or "  "
        love.graphics.print(prefix .. option, menuX + 30, menuY + 60 + (i - 1) * 30)
    end
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print("Press Enter/Space to select", menuX + 30, menuY + menuHeight - 25)
end

-- Draw debug menu
function drawDebugMenu()
    local menuWidth = 300
    local menuHeight = 180
    local menuX = (SCREEN.WIDTH - menuWidth) / 2
    local menuY = (SCREEN.HEIGHT - menuHeight) / 2
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, SCREEN.WIDTH, SCREEN.HEIGHT)
    
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("DEBUG MENU", menuX, menuY + 20, menuWidth, "center")
    
    for i, option in ipairs(debugMenuOptions) do
        love.graphics.setColor(i == debugMenuSelection and 1 or 0.7, 0.8, 0.2, 1)
        local prefix = i == debugMenuSelection and "> " or "  "
        love.graphics.print(prefix .. option, menuX + 30, menuY + 60 + (i - 1) * 30)
    end
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print("Press F1 to toggle, Enter/Space to select", menuX + 30, menuY + menuHeight - 25)
end
