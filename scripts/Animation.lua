local Animation = {}
Animation.__index = Animation

-- create an animation
function Animation:new(imagePath, frameCount, x, y, width, height, scaleX, scaleY, interval)
    local animation = setmetatable({
        imagePath = imagePath,
        image = nil,
        frameCount = frameCount,
        x = x,
        y = y,
        by = y,
        width = width,
        height = height,
        scaleX = scaleX,
        scaleY = scaleY,
        index = 0,
        frame = nil,
        interval = interval or .1,
        time = 0,
        draw = function(self)
            -- render animation
            love.graphics.draw(self.image, self.frame, self.x, self.y, 0, self.scaleX, self.scaleY)
        end,
        update = function(self, dt)
            local mx, my = love.mouse.getPosition()
            -- update hover state
            if mx > self.x and mx < self.x + self.width * self.scaleX and
            my > self.y and my < self.y + self.height * self.scaleY then
                self.hover = true
            else
                self.hover = false
            end

            -- update time and index
            self.time = self.time + dt
            if self.time >= self.interval then
                self.time = self.time - self.interval
                self.index = (self.index + 1) % self.frameCount
            end

            
            -- update quad if index changed
            local changed = self.index ~= prevIndex
            if changed then
                self.frame = love.graphics.newQuad(self.index * self.width, 0, self.width, self.height, self.image:getDimensions())
            end
        end,
    }, Animation)

    -- initialize image from provided path
    animation.image = love.graphics.newImage(imagePath)

    -- initialize first button frame
    animation.frame = love.graphics.newQuad(0, 0, animation.width, animation.height, animation.image:getDimensions())
    
    -- initialize image attrs
    animation.image:setFilter("nearest", "nearest")

    return animation
end

return Animation