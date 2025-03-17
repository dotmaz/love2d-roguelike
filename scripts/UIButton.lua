local UIButton = {}
UIButton.__index = UIButton


function UIButton:new(args)
    args = args or {}
    return setmetatable({
        callback = args.callback or function() end,
        scale = 2,
        width = 120,
        height = 46,
        x = args.x or love.graphics.getWidth()/2 - self.width/2,
        y = args.y or love.graphics.getHeight()/2 - self.height/2,
        hot = false,
        hover = false,
        image = love.graphics.newImage(args.image),
        cool = true,
        draw = function(self)
            -- detect hover overlap
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX > self.x and mouseX < self.x + self.width and
               mouseY > self.y and mouseY < self.y + self.height then
                self.hover = true
                cursor = love.mouse.getSystemCursor("hand")
                love.mouse.setCursor(cursor)
            else
                self.hover = false
                love.mouse.setCursor()
            end

            -- pick the right frame based on button state {0-normal, 64-hover, 128-clicked}
            local index = 0
            if self.hot then
                index = 120
            elseif self.hover then
                index = 60
            end
            self.image:setFilter("nearest", "nearest")
            firstFrame = love.graphics.newQuad(index, 0, 60, 23, self.image:getDimensions())
            love.graphics.draw(self.image, firstFrame, self.x, self.y, 0, self.scale, self.scale)
        end
    }, UIButton)
end

return UIButton