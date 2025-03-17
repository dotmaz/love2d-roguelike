Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y, targetPlayer)
    local self = setmetatable({}, Enemy)
    self.x = x -- World x position of enemy
    self.y = y -- World y position of enemy
    self.health = 50
    self.hit = false -- hit state
    self.hitDuration = 0.08 -- hit duration
    self.hitTime = self.hitDuration
    self.targetPlayer = targetPlayer -- target player to follow
    self.targetRange = 900 -- range to follow player
    self.width = 128 -- width of player
    self.height = 128 -- height of player
    self.fx = 0 -- force x
    self.fy = 0 -- force y
    self.speed = 160 -- movement speed,
    self.animation = SpriteAnimation:new("sprites/enemy.png", 32, 32, 2, 2, {
        move = {1, 9, 0.1}, -- row 1, 9 frames, 100ms per frame
        idle = {2, 11, 0.1} -- row 2, 11 frames, 100ms per frame
    })
    return self
end

function Enemy:draw()
    -- Draw enemy
    love.graphics.setColor(1, 1, 1)
    sprites.player:setFilter("nearest", "nearest")
    self.animation:draw(self.x, self.y)
    if self.hit then
        love.graphics.setBlendMode("add")
        for i = 1, 25 do --n't judge me
            self.animation:draw(self.x, self.y)
        end
        love.graphics.setBlendMode("alpha")
    end


    -- draw hitbox
    if player.debugMode then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Enemy:update(dt)
    -- Update animation
    self.animation:update(dt)

    -- If no target player, return to idle state
    if not self.targetPlayer then
        self.animation:setState("idle")
        return
    end

    -- Calculate distance from player
    local dx = self.targetPlayer.worldX - self.x
    local dy = self.targetPlayer.worldY - self.y
    local length = math.sqrt(dx^2 + dy^2)
    if length > 0 then
        dx = dx / length
        dy = dy / length
    end

    -- If within range, move towards player, otherwise idle
    if(length < self.targetRange) then
        self.animation:setState("move")
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
    else
        self.animation:setState("idle")
    end

    -- update hit state
    
    if self.hit then
        self.hitTime = self.hitTime - dt
        if self.hitTime <= 0 then
            self.hit = false
            self.hitTime = self.hitDuration
        end
    end

    -- force
    if self.fx ~= 0 or self.fy ~= 0 then
        -- apply force
        self.x = self.x + self.fx * dt
        self.y = self.y + self.fy * dt
        -- apply friction
        if math.abs(self.fx) < 0.1 then self.fx = 0 else self.fx = self.fx * 0.9 end
        if math.abs(self.fy) < 0.1 then self.fy = 0 else self.fy = self.fy * 0.9 end
    end    
end

function Enemy:applyForce(angle, force)
    -- apply force in direction of angle
    self.fx = self.fx + math.cos(angle) * force
    self.fy = self.fy + math.sin(angle) * force
end

return Enemy