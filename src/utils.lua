-- Direction constants: 0=up, 1=right, 2=down, 3=left
DIR = {
    UP = 0,
    RIGHT = 1,
    DOWN = 2,
    LEFT = 3
}

DIR_TO_ANGLE = {
    [0] = -math.pi / 2,
    [1] = 0,
    [2] = math.pi / 2,
    [3] = math.pi
}

-- Screen dimensions
SCREEN = {
    WIDTH = 1280,
    HEIGHT = 800
}

-- Grid constants
GRID = {
    CELL_SIZE = 50,
    MIN_SCALE = 0.25,
    MAX_SCALE = 4,
    SCROLL_SPEED = 10
}

-- Game timing
STEP_INTERVAL = 0.2        -- seconds between steps (5 per second)
ANIMATION_DURATION = 0.3   -- seconds for move/rotate animation (slower)

-- Triangle AI probabilities (must sum to 1.0)
TRIANGLE = {
    MOVE_FORWARD_CHANCE = 0.5,    -- 50% chance to move forward
    ROTATE_CW_CHANCE = 0.25,       -- 25% chance to rotate clockwise
    -- ROTATE_CCW is remaining: 1 - MOVE_FORWARD_CHANCE - ROTATE_CW_CHANCE = 0.25
}

-- UI constants
UI = {
    INVENTORY_HEIGHT = 80,
    INVENTORY_MIN = 10,
    SLOT_SIZE = 60,
    SLOT_PADDING = 10,
    TOTAL_SLOTS = 10
}

-- Convert direction to delta movement
function dirToDxDy(dir)
    if dir == DIR.UP then return 0, -1 end
    if dir == DIR.DOWN then return 0, 1 end
    if dir == DIR.LEFT then return -1, 0 end
    if dir == DIR.RIGHT then return 1, 0 end
    return 0, 0
end

-- Rotate direction clockwise
function rotateCW(dir)
    return (dir + 1) % 4
end

-- Rotate direction counter-clockwise
function rotateCCW(dir)
    return (dir + 3) % 4
end

-- Parse grid key "col,row" into numbers
function parseKey(key)
    local col, row = key:match("([^,]+),(.+)")
    return tonumber(col), tonumber(row)
end

-- Create grid key from col,row
function makeKey(col, row)
    return col .. "," .. row
end

-- Smooth easing function (smoothstep)
function smoothstep(t)
    return t * t * (3 - 2 * t)
end
