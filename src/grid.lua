require "src.utils"

--[[
    Grid: Core game board data structure
    - Stores objects by cell position (key = "col,row")
    - Supports pan, zoom, object placement
    - Animation system for smooth movement/rotation
]]

Grid = {}
Grid.__index = Grid

function Grid.new(cellSize)
    local self = setmetatable({}, Grid)
    self.cellSize = cellSize or GRID.CELL_SIZE
    self.offsetX = 0
    self.offsetY = 0
    self.objects = {}
    self.scale = 1
    
    -- Animation state
    self.animations = {}
    self.animating = false
    self.animationDuration = ANIMATION_DURATION
    
    return self
end

-- Convert col,row to key
function Grid:getKey(col, row)
    return makeKey(col, row)
end

-- Place object at position
function Grid:placeObject(col, row, obj)
    self.objects[self:getKey(col, row)] = obj
end

-- Get object at position
function Grid:getObject(col, row)
    return self.objects[self:getKey(col, row)]
end

-- Convert screen coords to grid cell
function Grid:getCellAt(mouseX, mouseY)
    local col = math.floor((mouseX / self.scale - self.offsetX) / self.cellSize)
    local row = math.floor((mouseY / self.scale - self.offsetY) / self.cellSize)
    return col, row
end

-- Record animation for a cell (triangle movement/rotation)
function Grid:recordAnimation(key, fromCol, fromRow, toCol, toRow, fromDir, toDir)
    self.animations[key] = {
        fromCol = fromCol,
        fromRow = fromRow,
        toCol = toCol,
        toRow = toRow,
        fromDir = fromDir,
        toDir = toDir,
        elapsed = 0
    }
end

-- Update animations each frame
function Grid:updateAnimations(dt)
    local animating = false
    for key, anim in pairs(self.animations) do
        anim.elapsed = anim.elapsed + dt
        if anim.elapsed >= self.animationDuration then
            self.animations[key] = nil
        else
            animating = true
        end
    end
    self.animating = animating
end

-- Pan grid with WASD/arrows
function Grid:update()
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        self.offsetY = self.offsetY + GRID.SCROLL_SPEED
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        self.offsetY = self.offsetY - GRID.SCROLL_SPEED
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        self.offsetX = self.offsetX + GRID.SCROLL_SPEED
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        self.offsetX = self.offsetX - GRID.SCROLL_SPEED
    end
    
    self:updateAnimations(dt or 0.016)
end

--[[ Render the grid and all objects with animations ]]
function Grid:draw(screenWidth, screenHeight, showGrid)
    love.graphics.push()
    love.graphics.scale(self.scale)
    love.graphics.translate(self.offsetX, self.offsetY)

    local startCol = math.floor(-self.offsetX / self.cellSize)
    local endCol = startCol + math.ceil(screenWidth / self.scale / self.cellSize) + 1
    local startRow = math.floor(-self.offsetY / self.cellSize)
    local endRow = startRow + math.ceil(screenHeight / self.scale / self.cellSize) + 1

    love.graphics.setLineWidth(1 / self.scale)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)

    for col = startCol, endCol do
        for row = startRow, endRow do
            local x = col * self.cellSize
            local y = row * self.cellSize
            
            if showGrid then
                love.graphics.rectangle("line", x, y, self.cellSize, self.cellSize)
            end

            local obj = self:getObject(col, row)
            
            if obj and obj.type == "triangle" then
                local anim = self.animations[col .. "," .. row]
                local drawX, drawY, drawDir
                
                if anim then
                    local t = smoothstep(anim.elapsed / self.animationDuration)
                    
                    drawX = anim.fromCol * self.cellSize + (anim.toCol - anim.fromCol) * self.cellSize * t
                    drawY = anim.fromRow * self.cellSize + (anim.toRow - anim.fromRow) * self.cellSize * t
                    
                    local fromAngle = DIR_TO_ANGLE[anim.fromDir] or 0
                    local toAngle = DIR_TO_ANGLE[anim.toDir] or 0
                    
                    local diff = toAngle - fromAngle
                    if diff >= math.pi then
                        diff = diff - 2 * math.pi
                    elseif diff <= -math.pi then
                        diff = diff + 2 * math.pi
                    end
                    
                    drawDir = fromAngle + diff * t
                else
                    drawX = x
                    drawY = y
                    drawDir = DIR_TO_ANGLE[obj.direction] or 0
                end
                
                Triangle.new(drawDir):draw(drawX, drawY, self.cellSize)
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            elseif obj and obj.type == "circle" then
                Circle.new():draw(x, y, self.cellSize)
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
    love.graphics.setLineWidth(1)
end

--[[ Zoom at mouse position ]]
function Grid:zoom(delta, mouseX, mouseY)
    local zoomLevels = {0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4}
    local oldScale = self.scale
    local newScale = self.scale
    
    if delta > 0 then  -- zoom out
        for i = #zoomLevels, 1, -1 do
            if zoomLevels[i] < self.scale then
                newScale = zoomLevels[i]
                break
            end
        end
    else  -- zoom in
        for i = 1, #zoomLevels do
            if zoomLevels[i] > self.scale then
                newScale = zoomLevels[i]
                break
            end
        end
    end
    
    if newScale ~= self.scale then
        local worldX = mouseX / oldScale - self.offsetX
        local worldY = mouseY / oldScale - self.offsetY
        self.scale = newScale
        self.offsetX = mouseX / self.scale - worldX
        self.offsetY = mouseY / self.scale - worldY
    end
end
