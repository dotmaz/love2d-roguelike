Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y, targetPlayer)
    local self = setmetatable({}, Enemy)
    self.x = x or love.graphics.getWidth() / 2 -- x position of player
    self.y = y or love.graphics.getHeight() / 2 - 10 -- y position of player
    self.health = 10
    self.hit = false -- hit state
    self.hitDuration = 0.1 -- hit duration
    self.hitCooldown = 0 -- hit cooldown
    self.targetPlayer = targetPlayer -- target player to follow
    self.width = 64 -- width of player
    self.height = 64 -- height of player
    self.fx = 0 -- force x
    self.fy = 0 -- force y
    self.speed = 80 -- movement speed,
    self.animation = SpriteAnimation:new("sprites/enemy.png", 32, 32, {
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
        for i = 1, 30 do
            self.animation:draw(self.x, self.y)
        end
        love.graphics.setBlendMode("alpha")
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
    local dx = self.targetPlayer.x - self.x
    local dy = self.targetPlayer.y - self.y
    local length = math.sqrt(dx^2 + dy^2)
    if length > 0 then
        dx = dx / length
        dy = dy / length
    end

    -- If within range, move towards player, otherwise idle
    if(length < 300) then
        self.animation:setState("move")
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
    else
        self.animation:setState("idle")
    end

    -- update hit state
    if self.hit then
        self.hitDuration = self.hitDuration - dt
        if self.hitDuration <= 0 then
            self.hit = false
            self.hitDuration = 0.2
        end
    elseif self.hitCooldown > 0 then
        self.hitCooldown = self.hitCooldown - dt
        if self.hitCooldown <= 0 then
            self.hitCooldown = 0
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