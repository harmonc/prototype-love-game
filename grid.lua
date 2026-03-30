require "objects"

Grid = {}
Grid.__index = Grid

function Grid.new(cellSize)
    local self = setmetatable({}, Grid)
    self.cellSize = cellSize or 50
    self.offsetX = 0
    self.offsetY = 0
    self.scrollSpeed = 10
    self.objects = {}
    self.scale = 1
    self.minScale = 0.25
    self.maxScale = 4
    return self
end

function Grid:update()
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        self.offsetY = self.offsetY + self.scrollSpeed
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        self.offsetY = self.offsetY - self.scrollSpeed
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        self.offsetX = self.offsetX + self.scrollSpeed
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        self.offsetX = self.offsetX - self.scrollSpeed
    end
end

function Grid:getKey(col, row)
    return col .. "," .. row
end

function Grid:placeObject(col, row, obj)
    self.objects[self:getKey(col, row)] = obj
end

function Grid:getObject(col, row)
    return self.objects[self:getKey(col, row)]
end

function Grid:getCellAt(mouseX, mouseY)
    local col = math.floor((mouseX / self.scale - self.offsetX) / self.cellSize)
    local row = math.floor((mouseY / self.scale - self.offsetY) / self.cellSize)
    return col, row
end

function Grid:zoom(delta, mouseX, mouseY)
    local zoomLevels = {0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4}
    local oldScale = self.scale
    local newScale = self.scale
    
    if delta > 0 then
        for i = #zoomLevels, 1, -1 do
            if zoomLevels[i] < self.scale then
                newScale = zoomLevels[i]
                break
            end
        end
    else
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
            if obj and obj.type == "circle" then
                Circle.new():draw(x, y, self.cellSize)
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            elseif obj and obj.type == "triangle" then
                Triangle.new(obj.direction):draw(x, y, self.cellSize)
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end
