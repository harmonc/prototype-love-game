require "objects.object"

Triangle = setmetatable({}, { __index = Object })
Triangle.__index = Triangle

function Triangle.new(direction)
    local self = setmetatable({}, Triangle)
    self.color = {1, 0.8, 0.2, 1}
    self.direction = direction or 0
    return self
end

function Triangle:draw(x, y, cellSize)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])
    
    local cx = x + cellSize / 2
    local cy = y + cellSize / 2
    local size = cellSize * 0.4
    
    local angle = self.direction
    
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(angle)
    
    love.graphics.polygon("fill", {
        size, 0,
        size * math.cos(2 * math.pi / 3), size * math.sin(2 * math.pi / 3),
        size * math.cos(4 * math.pi / 3), size * math.sin(4 * math.pi / 3)
    })
    
    love.graphics.pop()
end