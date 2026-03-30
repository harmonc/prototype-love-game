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
    
    local angles = {
        [0] = -math.pi / 2,
        [1] = math.pi / 2,
        [2] = math.pi,
        [3] = 0
    }
    local baseAngle = angles[self.direction] or -math.pi / 2
    
    local points = {}
    for i = 0, 2 do
        local angle = baseAngle + (i * 2 * math.pi / 3)
        points[i * 2 + 1] = cx + size * math.cos(angle)
        points[i * 2 + 2] = cy + size * math.sin(angle)
    end
    
    love.graphics.polygon("fill", points)
end
