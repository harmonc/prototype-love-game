JSON = {}

function JSON.encode(data)
    local function encode(val)
        if type(val) == "nil" then return "null" end
        if type(val) == "boolean" then return tostring(val) end
        if type(val) == "number" then return tostring(val) end
        if type(val) == "string" then return '"' .. val:gsub('[\\"]', '\\%1') .. '"' end
        if type(val) == "table" then
            local arr = {}
            local isArray = #val > 0
            for k, v in pairs(val) do
                if not isArray and type(k) ~= "string" then isArray = false end
                table.insert(arr, (isArray and encode(v) or encode(k) .. ":" .. encode(v)))
            end
            return (isArray and "[" or "{") .. table.concat(arr, ",") .. (isArray and "]" or "}")
        end
        return "null"
    end
    return encode(data)
end

function JSON.decode(str)
    local pos = 1
    local peek = function() return str:sub(pos, pos) end
    local get = function() local c = peek(); pos = pos + 1; return c end
    local skipSpace = function()
        while peek() and peek():match("%s") do get() end
    end
    
    local parseValue, parseString, parseNumber, parseArray, parseObject
    
    parseString = function()
        get()
        local s = ""
        while peek() and peek() ~= '"' do
            local c = get()
            if c == "\\" then s = s .. get() else s = s .. c end
        end
        get()
        return s
    end
    
    parseNumber = function()
        local n = str:match("[%-]?%d+%.?%d*[%deE%+%-]*", pos)
        pos = pos + #n
        return tonumber(n)
    end
    
    parseArray = function()
        get()
        local arr = {}
        while peek() and peek() ~= "]" do
            table.insert(arr, parseValue())
            skipSpace()
            if peek() == "," then get() end
        end
        get()
        return arr
    end
    
    parseObject = function()
        get()
        local obj = {}
        while peek() and peek() ~= "}" do
            skipSpace()
            local key = parseValue()
            skipSpace()
            get()
            local val = parseValue()
            obj[key] = val
            skipSpace()
            if peek() == "," then get() end
        end
        get()
        return obj
    end
    
    parseValue = function()
        skipSpace()
        local c = peek()
        if not c then return nil end
        if c == "n" then get(); get(); get(); get(); return nil end
        if c == "t" then get(); get(); get(); get(); return true end
        if c == "f" then get(); get(); get(); get(); get(); return false end
        if c == '"' then return parseString() end
        if c == "[" then return parseArray() end
        if c == "{" then return parseObject() end
        return parseNumber()
    end
    
    return parseValue()
end

function saveGame(grid, clear)
    print("Save directory: " .. love.filesystem.getSaveDirectory())
    if clear then
        love.filesystem.remove("save.json")
        print("Save cleared")
        grid.objects = {}
        grid.offsetX = 0
        grid.offsetY = 0
        grid.scale = 1
        print("Game reloaded fresh")
        return
    end
    local saveData = {
        objects = grid.objects,
        offsetX = grid.offsetX,
        offsetY = grid.offsetY,
        scale = grid.scale
    }
    love.filesystem.write("save.json", JSON.encode(saveData))
    print("Game saved")
end

function loadGame(grid)
    local info = love.filesystem.getInfo("save.json")
    if info then
        local data = love.filesystem.read("save.json")
        local saveData = JSON.decode(data)
        if saveData then
            grid.objects = saveData.objects or {}
            grid.offsetX = saveData.offsetX or 0
            grid.offsetY = saveData.offsetY or 0
            grid.scale = saveData.scale or 1
            print("Game loaded")
        end
    end
end
