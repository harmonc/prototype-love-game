require "objects.object"

Target = setmetatable({}, { __index = Object })
Target.__index = Target

function Target.new()
    local self = setmetatable({}, Target)
    self.color = {0.2, 0.9, 0.3, 1}
    return self
end

function Target:draw(x, y, cellSize)
    local cx = x + cellSize / 2
    local cy = y + cellSize / 2
    local radius = cellSize * 0.35
    
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.4)
    love.graphics.circle("fill", cx, cy, radius)
    
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    love.graphics.circle("line", cx, cy, radius)
    love.graphics.circle("line", cx, cy, radius * 0.5)
    
    love.graphics.setLineWidth(2)
    love.graphics.line(cx - radius * 0.3, cy - radius * 0.3, cx + radius * 0.3, cy + radius * 0.3)
    love.graphics.line(cx + radius * 0.3, cy - radius * 0.3, cx - radius * 0.3, cy + radius * 0.3)
    love.graphics.setLineWidth(1)
end
