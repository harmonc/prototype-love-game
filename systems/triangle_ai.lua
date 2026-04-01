require "src.utils"

--[[
    Triangle AI: Random behavior each turn
    Uses configurable probabilities from TRIANGLE in utils.lua
]]
function processTriangle(tri, grid, newObjects)
    local key = tri.key
    local col = tri.col
    local row = tri.row
    local obj = tri.obj
    
    -- Get probabilities
    local moveChance = TRIANGLE.MOVE_FORWARD_CHANCE
    local rotateCWChance = TRIANGLE.ROTATE_CW_CHANCE
    
    -- Random roll (0 to 1)
    local roll = math.random()
    
    if roll < moveChance then
        -- Try moving forward
        local dx, dy = dirToDxDy(obj.direction)
        local newCol = col + dx
        local newRow = row + dy
        local newKey = makeKey(newCol, newRow)
        
        if not grid.objects[newKey] and not newObjects[newKey] then
            newObjects[newKey] = { type = "triangle", direction = obj.direction }
            grid:recordAnimation(newKey, col, row, newCol, newRow, obj.direction, obj.direction)
            print("Triangle moved from " .. key .. " to " .. newKey)
            return true
        end
        -- Blocked - stay in place
        newObjects[key] = obj
        print("Triangle at " .. key .. " blocked, stayed")
        return false
        
    elseif roll < moveChance + rotateCWChance then
        -- Rotate clockwise
        local newDir = rotateCW(obj.direction)
        newObjects[key] = { type = "triangle", direction = newDir }
        grid:recordAnimation(key, col, row, col, row, obj.direction, newDir)
        print("Triangle at " .. key .. " rotated CW from " .. obj.direction .. " to " .. newDir)
        return true
        
    else
        -- Rotate counter-clockwise
        local newDir = rotateCCW(obj.direction)
        newObjects[key] = { type = "triangle", direction = newDir }
        grid:recordAnimation(key, col, row, col, row, obj.direction, newDir)
        print("Triangle at " .. key .. " rotated CCW from " .. obj.direction .. " to " .. newDir)
        return true
    end
end
