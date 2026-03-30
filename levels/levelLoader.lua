LevelLoader = {}

function LevelLoader.loadLevel(levelNum)
    local filename = "levels/level" .. levelNum .. ".json"
    
    if not love.filesystem.exists(filename) then
        print("Level " .. levelNum .. " not found")
        return nil
    end
    
    local data = love.filesystem.read(filename)
    local level = JSON.decode(data)
    
    return level
end

function LevelLoader.getPreplacedObjects(level)
    local objects = {}
    
    if level.preplaced then
        if level.preplaced.block then
            local pos = level.preplaced.block
            local key = pos.col .. "," .. pos.row
            objects[key] = { type = "block" }
        end
        if level.preplaced.target then
            local pos = level.preplaced.target
            local key = pos.col .. "," .. pos.row
            objects[key] = { type = "target" }
        end
    end
    
    return objects
end
