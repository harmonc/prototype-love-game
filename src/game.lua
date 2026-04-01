require "src.utils"
require "systems.triangle_ai"

--[[
    Core game simulation step
    1. Copy non-triangle objects (circles)
    2. Get all triangles, sorted by position
    3. Process each triangle with AI
    4. Update grid
]]
function gameStep()
    local newObjects = {}
    
    -- Copy non-triangle objects (circles are static)
    for key, obj in pairs(grid.objects) do
        if obj.type ~= "triangle" then
            newObjects[key] = obj
        end
    end
    
    -- Collect triangles with position data
    local triangles = {}
    for key, obj in pairs(grid.objects) do
        if obj.type == "triangle" then
            local col, row = parseKey(key)
            table.insert(triangles, {key = key, col = col, row = row, obj = obj})
        end
    end
    
    -- Sort by column, then row (consistent processing order)
    table.sort(triangles, function(a, b)
        if a.col ~= b.col then return a.col < b.col end
        return a.row < b.row
    end)
    
    -- Process each triangle
    for _, tri in ipairs(triangles) do
        processTriangle(tri, grid, newObjects)
    end
    
    grid.objects = newObjects
end
