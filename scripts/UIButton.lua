local UIButton = {}
UIButton.__index = UIButton

function UIButton:new(args)
    args = args or {}
    return setmetatable({
        x = args.x or 0,
        y = args.y or 0,
        width = args.width or 100,
        height = args.height or 100,
        text = args.text or nil,
        color = args.color or {1, 1, 1},
        hoverColor = args.hoverColor or {0.8, 0.8, 0.8},
        callback = args.callback or function() end,
        transitionSpeed = args.transitionSpeed or 4,
        transitionScale = args.transitionScale or 0,
        hot = false,
        transition = 0,
        draw = function(self)
            -- detect hover overlap
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX > self.x and mouseX < self.x + self.width and
               mouseY > self.y and mouseY < self.y + self.height then
                love.graphics.setColor(self.hoverColor)

                cursor = love.mouse.getSystemCursor("hand")
                love.mouse.setCursor(cursor)
            else
                love.graphics.setColor(self.color)
            end

            -- transition size on hover
            if self.hot then
                if(self.transition < 1) then
                    self.transition = self.transition + (self.transitionSpeed / 10)
                end
            else
                if(self.transition > 0) then
                    self.transition = self.transition - (self.transitionSpeed / 10)
                end
            end

            -- draw button
            love.graphics.rectangle("fill", self.x + 5*self.transitionScale*self.transition, self.y + 5*self.transitionScale*self.transition, self.width - 10*self.transitionScale*self.transition, self.height - 10*self.transitionScale*self.transition, 9)

            -- draw button text
            if self.text ~= nil then
                love.graphics.setColor(.2, .2, .2)
                love.graphics.printf(self.text, self.x, self.y, self.width, "center")
            end
        end
    }, UIButton)
end

return UIButton