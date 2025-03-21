local ShopItem = {}
ShopItem.__index = ShopItem

function ShopItem:new(button, buttonName, buttonDescription, price)
    local item = setmetatable({
        button = button,
        buttonX = button.x,
        buttonY = button.y,
        buttonWidth = button.width,
        buttonName = buttonName,
        buttonDescription = buttonDescription,
        price = price,
        time = 0,
        rand = math.random(100),
        draw = function(self)
            self.button:draw()
            love.graphics.setFont(fonts.p2psmall)
            local font = love.graphics.getFont()
            love.graphics.print(self.buttonName, self.buttonX + self.buttonWidth + 10 - font:getWidth(self.buttonName) / 2, self.buttonY + 90 + math.sin(self.time * 1.5 + self.rand))

            local priceString = "$" .. self.price
            love.graphics.setColor(Utils.color("#d1b70f"))
            love.graphics.print(priceString, self.buttonX + self.buttonWidth + 10 - font:getWidth(priceString) / 2, self.buttonY + 120)
            love.graphics.setFont(fonts.p2p)
            love.graphics.setColor(1, 1, 1)
        end,
        update = function(self, dt)
            -- update button
            self.button:update()
            -- update time
            self.time = self.time + dt

            self.button.y = self.buttonY + math.sin(self.time * 1.5 + self.rand) * 3

        end,
    }, ShopItem)

    -- initialize shop item here

    item.button.price = item.price

    return item
end

return ShopItem