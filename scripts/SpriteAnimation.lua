SpriteAnimation = {}
SpriteAnimation.__index = SpriteAnimation

function SpriteAnimation:new(imagePath, frameWidth, frameHeight, animations)
    local self = setmetatable({}, SpriteAnimation)
    self.image = love.graphics.newImage(imagePath)
    self.frameWidth = frameWidth
    self.frameHeight = frameHeight
    self.animations = animations -- {state = {row, frames, speed}}
    self.currentState = "idle"
    self.currentFrame = 1
    self.timer = 0
    self.quads = {}
    
    -- Generate quads for each animation
    for state, anim in pairs(animations) do
        local row, frames = anim[1], anim[2]
        self.quads[state] = {}
        for i = 1, frames do
            table.insert(self.quads[state], love.graphics.newQuad(
                (i - 1) * frameWidth, (row - 1) * frameHeight, 
                frameWidth, frameHeight, 
                self.image:getDimensions()
            ))
        end
    end
    
    return self
end

function SpriteAnimation:setState(state)
    if self.animations[state] and state ~= self.currentState then
        self.currentState = state
        self.currentFrame = 1
        self.timer = 0
    end
end

function SpriteAnimation:update(dt)
    local anim = self.animations[self.currentState]
    if not anim then return end
    
    self.timer = self.timer + dt
    if self.timer >= anim[3] then
        self.timer = self.timer - anim[3]
        self.currentFrame = self.currentFrame % anim[2] + 1
    end
end

function SpriteAnimation:draw(x, y)
    self.image:setFilter("nearest", "nearest")
    love.graphics.draw(self.image, self.quads[self.currentState][self.currentFrame], x, y, 0, 2, 2)
end

return SpriteAnimation