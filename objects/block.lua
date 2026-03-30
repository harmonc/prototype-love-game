require "objects.object"

Block = setmetatable({}, { __index = Object })
Block.__index = Block

function Block.new()
    local self = setmetatable({}, Block)
    self.color = {0.6, 0.5, 0.4, 1}
    return self
end

function Block:draw(x, y, cellSize)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])
    local padding = cellSize * 0.15
    love.graphics.rectangle("fill", x + padding, y + padding, cellSize - padding * 2, cellSize - padding * 2)
    
    love.graphics.setColor(0.4, 0.35, 0.3, 1)
    love.graphics.rectangle("line", x + padding, y + padding, cellSize - padding * 2, cellSize - padding * 2)
end
