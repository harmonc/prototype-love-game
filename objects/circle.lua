require "objects.object"

Circle = setmetatable({}, { __index = Object })
Circle.__index = Circle

function Circle.new()
    local self = setmetatable({}, Circle)
    self.color = {0.2, 0.9, 1, 1}
    return self
end

function Circle:draw(x, y, cellSize)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])
    local radius = cellSize * 0.35
    local segments = 64
    love.graphics.circle("fill", x + cellSize / 2, y + cellSize / 2, radius, segments)
end
