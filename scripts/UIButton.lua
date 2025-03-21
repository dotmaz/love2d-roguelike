local UIButton = {}
UIButton.__index = UIButton

-- Create a button object from a 3-frame sprite sheet horizontally arranged
-- 1: normal   2: hover   3: clicked
function UIButton:new(imagePath, x, y, width, height, scaleX, scaleY, triggerOnClick, text, font, callbackParam, toggleable)
    local button = setmetatable({
        imagePath = imagePath,
        image = nil,
        x = x,
        y = y,
        scaleX = scaleX,
        scaleY = scaleY,
        callback = nil,
        width = width,
        height = height,
        scaleX = scaleX,
        scaleY = scaleY,
        triggerOnClick = triggerOnClick, -- True: callback on click, False: callback on release
        hot = false,
        hover = false,
        index = 0,
        frame = nil,
        text = text or nil,
        textX = nil,
        textY = nil,
        font = font,
        toggleable = toggleable or false,
        pressed = false, -- used for toggleable buttons
        id = tostring(os.time()) .. tostring(math.random(999999999)), -- unique id for each button
        price = nil,
        draw = function(self)
            -- render button
            love.graphics.draw(self.image, self.frame, self.x, self.y, 0, self.scaleX, self.scaleY)

            -- render text
            if self.text then
                -- get font currently first
                local originalFont = love.graphics.getFont()
                self.font:setFilter("nearest", "nearest")
                love.graphics.setFont(font)
                love.graphics.print(self.text, self.textX, self.textY)
                love.graphics.setFont(originalFont)
            end

            -- draw center point debug
            -- love.graphics.setColor(1, 0, 0)
            -- love.graphics.circle("fill", self.x + self.width * self.scaleX / 2, self.y + self.height * self.scaleY / 2, 3)
            -- love.graphics.setColor(1, 1, 1)
        end,
        update = function(self)
            local mx, my = love.mouse.getPosition()
            -- update hover state
            if mx > self.x and mx < self.x + self.width * self.scaleX and
            my > self.y and my < self.y + self.height * self.scaleY then
                self.hover = true
            else
                self.hover = false
            end

            -- update sprite X index based on state
            local prevIndex = self.index
            if self.hot or self.pressed then
                self.index = self.width*2
            elseif self.hover then
                self.index = self.width
            else
                self.index = 0
            end

            -- update quad if index changed
            local changed = self.index ~= prevIndex
            if changed then
                self.frame = love.graphics.newQuad(self.index, 0, self.width, self.height, self.image:getDimensions())
            end

            -- update text position
            if self.font and self.text then
                self.textX = self.x + self.width * self.scaleX / 2 - self.font:getWidth(self.text) / 2 + 2 -- add offset when hot
                self.textY = self.y + self.height * self.scaleY / 2 - self.font:getHeight(self.text) / 2 - 2

                if self.hot or self.pressed then
                    self.textX = self.textX - 1*self.scaleX -- add offset when hot
                    self.textY = self.textY + 2*self.scaleY
                end
            end
        end,
    }, UIButton)

    print("initialized button with id " .. button.id)

    -- initialize image from provided path
    button.image = love.graphics.newImage(imagePath)

    -- initialize first button frame
    button.frame = love.graphics.newQuad(0, 0, button.width, button.height, button.image:getDimensions())
    
    -- initialize image attrs
    button.image:setFilter("nearest", "nearest")

    -- initialize callback
    if button.toggleable then
        button.callback = function(showHitText, count)
            -- make it pressed
            button.pressed = not button.pressed
            callbackParam(button.id, button.pressed, showHitText, count)
        end
    else
        button.callback = function(showHitText, count)
            if button.price ~= nil then
                if game.money < button.price or #keys >= 10 then
                    local s = sounds.point:clone()
                    s:play()
                    return -- not enough money
                end
                game.money = game.money - button.price
            end
            callbackParam(button.id, button.pressed, showHitText, count)
        end
    end

    return button
end

return UIButton