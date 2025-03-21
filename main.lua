-- Pressed
-- Author: Mazin Abubeker

--============  Global Setup  ============--

-- Custom objects
UIButton = require("scripts.UIButton")
Utils = require("scripts.Utils")
Animation = require("scripts.Animation")
ShopItem = require("scripts.ShopItem")

-- Global variables
sounds = {
    click = love.audio.newSource("sounds/generic1.ogg", "static"),
    money = love.audio.newSource("sounds/coin1.ogg", "static"),
    money2 = love.audio.newSource("sounds/coin2.ogg", "static"),
    point = love.audio.newSource("sounds/tarot1.ogg", "static"),
    cancel = love.audio.newSource("sounds/cancel.ogg", "static"),
    win = love.audio.newSource("sounds/holo1.ogg", "static"),
    mult = love.audio.newSource("sounds/multhit1.ogg", "static"),
    mult2 = love.audio.newSource("sounds/multhit2.ogg", "static"),
    negative = love.audio.newSource("sounds/negative.ogg", "static"),
    foil = love.audio.newSource("sounds/foil1.ogg", "static"),
    dice = love.audio.newSource("sounds/other1.ogg", "static"),
    
    music = love.audio.newSource("sounds/music1.ogg", "stream")
}

fonts = {
    p2plarge = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 64),
    p2p = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 48),
    p2pmedium = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 32),
    p2pmediumsmall = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 24),
    p2psmall = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 16),
    p2pbutton3 = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 24)
}

-- Global states
keys = {} -- table of all pressable keys

uikeys = {}

game = {
    goal = 5,
    points = 0,
    roundPoints = 0,
    startingClicks = 5,
    clicks = 5,
    base = 1,
    money = 0,
    round = 1
}

shopManager = {
    sceneTransitionTime = 1,
    timeElapsed = 0,
    animation = nil,
    items = {}
}

soundManager = {
    moneySoundTimer = 0,
    moneySoundCount = 0,
    moneySoundInterval = 0.1
}

activeModifiers = {} -- table of active modifiers

modifierTimelineManager = {
    time = 0,
    interval = 2,
    active = false,
    score = 0,
    count = 0,
    lastModifier = nil,
    update = function(self, dt)
        if not self.active then
            return
        end
        self.time = self.time + dt
        if self.time >= self.interval then
            -- remove first modifier
            if #activeModifiers > 0 then
                local modifier = activeModifiers[1]
                if modifier.type ~= "echo" then
                    self.lastModifier = modifier
                end
                if modifier.type == "mult" then -- IF MODIFIER IS MULT
                    self.score = self.score * modifier.value
                    game.roundPoints = self.score
                    
                    -- unpress the button and play mult sound
                    for i, key in ipairs(keys) do
                        if key.id == modifier.id then
                            
                            key.callback(true, self.count)
                            local multsound = nil;
                            if self.count > 5 then
                                multsound = sounds.mult2:clone()
                            else
                                multsound = sounds.mult:clone()
                            end
                            multsound:setPitch(1 + self.count / 50)
                            multsound:play()

                            camera:shake(0.2, 5 * self.count + 10)

                            self.count = self.count + 1
                            break
                        end
                    end
                elseif modifier.type == "echo" then
                    -- find last key pressed using self.lastModifier
                    if self.lastModifier then 
                        if self.lastModifier.type == "mult" then                                       --
                            self.score = self.score * self.lastModifier.value                          --
                            game.roundPoints = self.score                                              -- this is actually horrible
                            local multsound = nil;                                                     --
                            if self.count > 5 then                                                     --
                                multsound = sounds.mult2:clone()                                       --
                            else                                                                       --
                                multsound = sounds.mult:clone()
                            end
                            multsound:setPitch(1 + self.count / 50)
                            multsound:play()
                        elseif self.lastModifier.type == "dice" then 
                            self.score = self.score + self.lastModifier.value
                            game.roundPoints = self.score
                            local dice = sounds.dice:clone()
                            dice:setVolume(2)
                            dice:setPitch(1 + self.count / 50)
                            
                            dice:play()
                        end
                    end

                    for i, key in ipairs(keys) do
                        if key.id == modifier.id then
                            
                            key.callback(true, self.count)

                            -- play echo sound tarot
                            local echo = sounds.foil:clone()
                            echo:setVolume(0.5)
                            echo:setPitch(1 + self.count / 50)
                            
                            echo:play()

                            camera:shake(0.2, 5 * self.count + 10)

                            self.count = self.count + 1

                            break
                        end
                    end
                elseif modifier.type == "dice" then
                    self.score = self.score + modifier.value
                    game.roundPoints = self.score
                    for i, key in ipairs(keys) do
                        if key.id == modifier.id then
                            
                            key.callback(true, self.count)

                            -- play dice sound
                            local dice = sounds.dice:clone()
                            dice:setVolume(2)
                            dice:setPitch(1 + self.count / 50)
                            
                            dice:play()

                            camera:shake(0.2, 5 * self.count + 10)

                            self.count = self.count + 1

                            break
                        end
                    end
                end
            else
                game.points = game.points + self.score
                game.roundPoints = 0
                self.active = false

                -- check if goal is reached
                if game.points >= game.goal then
                    roundEnd()
                    return
                end

                if game.clicks <= 0 then
                    inRound = false
                    inShop = false
                    isGameOver = true
                    local s = sounds.cancel:clone()
                    s:play()
                    local n = sounds.negative:clone()
                    n:play()
                    camera:shake(0.5, 10)
                    return
                end

                self.count = 0
            end
            if self.interval > 0.1 then
                self.interval = self.interval * 0.95
            else
                self.interval = 0.1
            end
            self.time = 0
        end
    end,
}


-- Add this at the top with your global variables
camera = {
    x = 0,
    y = 0,
    shakeTimer = 0,
    shakeDuration = 0,
    shakeMagnitude = 0
}

-- Add this function to handle the camera shake
function camera:shake(duration, magnitude)
    self.shakeTimer = duration
    self.shakeDuration = duration
    self.shakeMagnitude = magnitude
end

-- Add this to your love.update function
function camera:update(dt)
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        
        -- Calculate shake intensity (fades out over time)
        local intensity = self.shakeMagnitude * (self.shakeTimer / self.shakeDuration)
        
        -- Use LOVE's built-in noise function for smooth random movement
        local time = love.timer.getTime()
        self.x = love.math.noise(time * 2, 0) * intensity * 2 - intensity
        self.y = love.math.noise(0, time * 2) * intensity * 2 - intensity
        
        -- Ensure camera returns to center when shake ends
        if self.shakeTimer <= 0 then
            self.x = 0
            self.y = 0
            self.shakeTimer = 0
        end
    end
end


modifierHitTexts = {
    texts = {},
    update = function(self, dt)
        for i, text in ipairs(self.texts) do
            text.time = text.time + dt
            text.y = text.y - dt * 20 -- move up
            if text.time >= .3 then
                table.remove(self.texts, i)
            end
        end
    end,
    draw = function(self)
        for _, text in ipairs(self.texts) do
            love.graphics.setFont(fonts.p2psmall)
            if text.count ~= nil then
                if (text.count > 3 and text.count < 6) then
                    love.graphics.setFont(fonts.p2pmediumsmall)
                elseif (text.count >= 6 and text.count < 9) then
                    love.graphics.setFont(fonts.p2pmedium)
                elseif (text.count >= 9) then
                    love.graphics.setFont(fonts.p2p)
                end
            end
            love.graphics.setColor(Utils.color("#ffffff"))
            love.graphics.print(text.text, text.x, text.y)
            love.graphics.setColor(text.color)--Utils.color("#ff6a3d")
            
            love.graphics.print(text.text, text.x + 2, text.y + 2)
            love.graphics.setFont(fonts.p2p)
            love.graphics.setColor(1, 1, 1)
        end
    end,
} -- table of text that displays near button when modifier is hit


--====== HIT ======-

inRound = true
inShop = false

-- TODO: so many things here obviously 1) factor out reused code 2) fix how objects are addded to the shop make it not bad
function hit()
    if #activeModifiers == 0 then
        -- hit with no modifiers
        -- increment points
        game.clicks = game.clicks - 1
        game.points = game.points + game.base
    
        -- play sound
        local click = sounds.click:clone()
        click:play()


        -- check if goal is reached
        if game.points >= game.goal then
            roundEnd()
            return
        end

        if game.clicks <= 0 then
            inRound = false
            isGameOver = true
            local s = sounds.cancel:clone()
            s:play()
            local n = sounds.negative:clone()
            n:play()
            camera:shake(0.5, 10)
            return
        end
    else
        game.clicks = game.clicks - 1
        -- play sound
        local click = sounds.click:clone()
        click:play()
        game.roundPoints = game.base
        modifierTimelineManager.score = game.base
        modifierTimelineManager.active = true
        modifierTimelineManager.time = 0
        modifierTimelineManager.count = 0
        modifierTimelineManager.interval = 1
        modifierTimelineManager.lastModifier = nil
        -- hit_with_modifiers()
    end

    
end

function mult(buttonId, toggleState, showHitText, count)
    -- play sound; if arg is not passed, play sound
    if playSound == nil then
        playSound = true
    end
    if playSound then
        local click = sounds.click:clone()
        click:play()
    end 
    

    -- add active modifier
    if toggleState then
        table.insert(activeModifiers, {id = buttonId, type = "mult", value = 2})
    else
        for i, modifier in ipairs(activeModifiers) do
            if modifier.id == buttonId then
                table.remove(activeModifiers, i)
                break
            end
        end
    end


    if showHitText == true then
        for i, key in ipairs(keys) do
            if key.id == buttonId then
                -- set pressed state to true
                table.insert(modifierHitTexts.texts, {time = 0, count=count, color=Utils.color(randomHexColor()), text = "x2", x = key.x + math.random(key.width*key.scaleX-20), y = key.y})
                break
            end
        end
    end
end

function randomHexColor()
    return string.format("#%06X", love.math.random(0, 0xFFFFFF))
end

function echo(buttonId, toggleState, showHitText, count)
    local click = sounds.click:clone()
    click:play()
    
     -- add active modifier
    if toggleState then
        table.insert(activeModifiers, {id = buttonId, type = "echo"})
    else
        for i, modifier in ipairs(activeModifiers) do
            if modifier.id == buttonId then
                table.remove(activeModifiers, i)
                break
            end
        end
    end

    if showHitText == true then
        for i, key in ipairs(keys) do
            if key.id == buttonId then
                -- set pressed state to true
                local hitText = ""
                if modifierTimelineManager.lastModifier then
                    hitText = modifierTimelineManager.lastModifier.type
                else
                    hitText = "none"
                end
                table.insert(modifierHitTexts.texts, {time = 0, count=count, color=Utils.color(randomHexColor()), text = hitText, x = key.x + math.random(key.width*key.scaleX-20), y = key.y})
                break
            end
        end
    end
end

function dice(buttonId, toggleState, showHitText, count)
    local click = sounds.click:clone()
    click:play()

    local value = math.random(1, 6)
    
     -- add active modifier
    if toggleState then
        table.insert(activeModifiers, {id = buttonId, type = "dice", value = value})
    else
        for i, modifier in ipairs(activeModifiers) do
            if modifier.id == buttonId then
                table.remove(activeModifiers, i)
                break
            end
        end
    end

    if showHitText == true then
        for i, key in ipairs(keys) do
            if key.id == buttonId then
                -- set pressed state to true
                table.insert(modifierHitTexts.texts, {time = 0, count=count, color=Utils.color(randomHexColor()), text = "+" .. value, x = key.x + math.random(key.width*key.scaleX-20), y = key.y})
                break
            end
        end
    end
end

function roundEnd()
    inRound = false
    -- reset points and goal
    soundManager.moneySoundTimer = 0
    soundManager.moneySoundCount = 4 + math.floor(game.round * 1.5) + math.floor(game.money/5)
    game.round = game.round + 1

    local win = sounds.win:clone()
    win:setPitch(1.5)
    win:play()
end

--============  LOVE Hooks  ============--

function getNewKeyPos()
    local numKeys = #keys - 1
    local rowSize = 3
    local row = math.floor(numKeys / rowSize)
    local col = numKeys % rowSize
    local x = love.graphics.getWidth()/2 - 116 + 88*col
    local y = love.graphics.getHeight()/2 + 30 + 88*(row+1)
    return x, y
end

function love.load()
    -- Set up the window
    love.window.setMode(2400, 1200, {resizable = false})
    love.window.setTitle("Keys")
    love.graphics.setBackgroundColor(Utils.color("#c0cfbe"))
    love.graphics.setFont(fonts.p2p)

    -- play music at 3/4 speed
    sounds.music:setLooping(true)
    sounds.music:setPitch(.5)
    sounds.music:setVolume(0.3) 
    sounds.music:play()


    

    -- table.insert(keys, UIButton:new("sprites/buy-button.png", love.graphics.getWidth()/2 - 60, love.graphics.getHeight()/2 - 23, 60, 23, 2, 2, false, nil, fonts.p2psmall, function() 
    --     local s = sounds.click:clone()
    --     local m = sounds.point:clone()
    --     -- set random pitch on click
    --     s:setPitch(math.random(9.5, 10.5) / 10)
    --     m:setVolume(0.5)
    --     s:play()
    --     m:play()
    --     game.points = game.points + 1
    -- end))

    -- insert hit button
    table.insert(keys, UIButton:new("sprites/sell-button-clear.png", love.graphics.getWidth()/2 - 85, love.graphics.getHeight()/2 - 23 , 60, 23, 3, 3, false, "HIT", fonts.p2psmall, hit))

    -- insert shop items
    table.insert(shopManager.items, ShopItem:new(UIButton:new("sprites/mult-button.png", love.graphics.getWidth()/2 - 260, 135 , 22, 23, 3, 3, false, "x2", fonts.p2psmall, function() 
        local click = sounds.click:clone()
        local money = sounds.money2:clone()
        money:setVolume(0.35)
        money:play()
        click:play()  
        local xpos, ypos = getNewKeyPos()
        table.insert(keys, UIButton:new("sprites/mult-button.png", xpos, ypos , 22, 23, 3, 3, false, "x2", fonts.p2psmall, mult, true))
    end), "X2", "Doubles your points", 5))
    table.insert(shopManager.items, ShopItem:new(UIButton:new("sprites/echo-button.png", love.graphics.getWidth()/2 - 40, 135 , 22, 23, 3, 3, false, "", fonts.p2psmall, function() 
        local click = sounds.click:clone()
        local money = sounds.money2:clone()
        money:setVolume(0.35)
        click:play()
        money:play()
        local xpos, ypos = getNewKeyPos()
        table.insert(keys, UIButton:new("sprites/echo-button.png", xpos, ypos , 22, 23, 3, 3, false, "", fonts.p2psmall, echo, true))
    end), "Echo", "Retrigger last pressed key", 8))
    table.insert(shopManager.items, ShopItem:new(UIButton:new("sprites/dice-button.png", love.graphics.getWidth()/2 + 180, 135 , 22, 23, 3, 3, false, "", fonts.p2psmall, function() 
        local click = sounds.click:clone()
        local money = sounds.money2:clone()
        money:setVolume(0.35)
        click:play()
        money:play()
        local xpos, ypos = getNewKeyPos()
        table.insert(keys, UIButton:new("sprites/dice-button.png", xpos, ypos, 22, 23, 3, 3, false, "", fonts.p2psmall, dice, true))
    end), "Dice", "Roll a dice and add the value", 4))



    -- insert ui keys


    -- next round button
    table.insert(uikeys, UIButton:new("sprites/sell-button-clear.png", love.graphics.getWidth()/2 - 600, 200, 60, 23, 3, 3, false, "NEXT", fonts.p2psmall, function()
        local click = sounds.click:clone() 
        click:play()
        inRound = true
        inShop = false
    end))
end

function love.update(dt)
    -- Add this line near the top
    camera:update(dt)

    -- update text modifier hit texts
    modifierHitTexts:update(dt)


    -- Update keys
    for _, key in ipairs(keys) do
        key:update()
    end

    -- Update ui keys
    if inShop then
        for _, key in ipairs(uikeys) do
            key:update()
        end
    end

    -- update cursor if anyone is in a hover state
    
    local hover = false
    if not isGameOver then
        for _, key in ipairs(keys) do
            if key.hover then
                love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                hover = true
                break
            end
        end
        for _, items in ipairs(shopManager.items) do
            if items.button.hover then
                love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                hover = true
                break
            end
        end
        for _, key in ipairs(uikeys) do
            if key.hover then
                love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                hover = true
                break
            end
        end
    end
    
    
    if not hover then
        love.mouse.setCursor()
    end

    -- update modifier timeline manager
    modifierTimelineManager:update(dt)

    -- Handle money sound sequence
    if soundManager.moneySoundCount > 0 then
        soundManager.moneySoundTimer = soundManager.moneySoundTimer + dt
        if soundManager.moneySoundTimer >= soundManager.moneySoundInterval then  -- 0.1 seconds between sounds
            local s = sounds.money:clone()
            s:setPitch(math.random(9, 11) / 10)
            s:setVolume(0.35)
            s:play()
            game.money = game.money + 1
            soundManager.moneySoundCount = soundManager.moneySoundCount - 1

            table.insert(modifierHitTexts.texts, {time = 0, count=1, color=Utils.color("#d1b70f"), text = "$", x = love.graphics.getWidth()/2 - 550 +  math.random(80), y = 80})
            soundManager.moneySoundTimer = 0
        end
    end

    -- handle shop animation
    if inShop and shopManager.animation then
        shopManager.animation:update(dt)
    end

    -- Handle scene transition
    if not inRound and not inShop then
        shopManager.timeElapsed = shopManager.timeElapsed + dt
        if shopManager.timeElapsed >= shopManager.sceneTransitionTime then
            shopManager.timeElapsed = 0
            shopManager.animation = Animation:new("sprites/shop.png", 4, love.graphics.getWidth() / 2 -( 256 * 3 / 2) , 100, 256, 64, 3, 3, .2)
            
            game.goal = math.floor(game.goal * 2)
            game.clicks = game.startingClicks
            game.points = 0
            inShop = true
        end
    end

    -- handle animation buttons
    if inShop and shopManager.animation then
        for _, item in ipairs(shopManager.items) do
            item:update(dt)
        end
    end
end

function addCommasToNumber(number)
    -- Convert number to string
    local numStr = tostring(number)
    
    -- Split into integer and decimal parts (if any)
    local integerPart, decimalPart = numStr:match("^([^%.]*)(%.?.*)$")
    
    -- Add commas to integer part
    local formatted = ""
    local len = #integerPart
    for i = 1, len do
        local char = integerPart:sub(i, i)
        formatted = formatted .. char
        -- Add comma if we're not at the end and it's 3 digits from the right
        if (len - i) % 3 == 0 and i < len then
            formatted = formatted .. ","
        end
    end

    return formatted
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- temp game over screen
    if isGameOver then
        love.graphics.setFont(fonts.p2pmedium)
        local font = love.graphics.getFont()
        local text = "Game Over"
        local textWidth = font:getWidth(text)
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(text, love.graphics.getWidth() / 2 - textWidth / 2, love.graphics.getHeight() / 2 - 100)
        -- End camera transform
        love.graphics.pop()
        return
    end

    -- draw keypad sprite
    love.graphics.setColor(1, 1, 1, 1)
    local sprite = love.graphics.newImage("sprites/keypad.png")
    sprite:setFilter("nearest", "nearest")
    love.graphics.draw(sprite, love.graphics.getWidth()/2 - 141 , love.graphics.getHeight()/2 + 108, 0, 3, 3)


    -- Draw keys
    for _, key in ipairs(keys) do
        key:draw()
    end

    -- draw modifier hit texts
    modifierHitTexts:draw()

    -- draw money on the left
    local font = love.graphics.getFont()
    local screenWidth = love.graphics.getWidth()
    local x = screenWidth / 2
    local y = 100
    local textShadowOffset = 4

    local moneyText = tostring(game.money)
    local moneyTextWidth = font:getWidth(moneyText)
    love.graphics.setColor(0,0,0,.8)
    love.graphics.print("$" .. moneyText, x - 500 - moneyTextWidth - textShadowOffset, y - textShadowOffset)
    love.graphics.setColor(Utils.color("#d1b70f"))
    love.graphics.print("$" .. moneyText, x - 500 - moneyTextWidth, y)
    love.graphics.setColor(1,1,1)

    -- draw ui keys if in shop
    if inShop then
        for _, key in ipairs(uikeys) do
            key:draw()
        end
    end


    -- draw animation
    if inShop and shopManager.animation then
        shopManager.animation:draw()
        for _, item in ipairs(shopManager.items) do
            item:draw()
        end
        -- End camera transform
        love.graphics.pop()
        return
    end

    -- Draw points
    
    love.graphics.setFont(fonts.p2plarge)
    local font = love.graphics.getFont()
    local text = tostring(addCommasToNumber(game.points))
    local textWidth = font:getWidth(text)
    love.graphics.setColor(0,0,0,.8)
    love.graphics.print(text, screenWidth / 2 - textWidth / 2, 300)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(text, screenWidth / 2 - textWidth / 2 + textShadowOffset, 300 + textShadowOffset)

    -- Draw round points
    if game.roundPoints > 0 then
        love.graphics.push()
        love.graphics.translate(-camera.x*0.5, -camera.y*0.5)
        local screenWidth = love.graphics.getWidth()
        love.graphics.setFont(fonts.p2pmedium)
        local font = love.graphics.getFont()
        local text = tostring("+" .. addCommasToNumber(game.roundPoints))
        local textWidth = font:getWidth(text)
        love.graphics.setColor(0,0,0,.8)
        love.graphics.print(text, screenWidth / 2 - textWidth / 2, 380)
        love.graphics.setColor(Utils.color("#ff6a3d"))
        love.graphics.print(text, screenWidth / 2 - textWidth / 2 + textShadowOffset, 390 + textShadowOffset)
        love.graphics.pop()
    end

    -- Draw goal text
    
    -- Get to: portion
    love.graphics.setFont(fonts.p2pmediumsmall)
    local font = love.graphics.getFont()
    local goalBaseText = "Get to:"
    local baseTextWidth = font:getWidth(goalBaseText)
    love.graphics.setColor(0, 0, 0, .5)
    love.graphics.print(goalBaseText, x - baseTextWidth / 2, y)

    -- Target
    love.graphics.setFont(fonts.p2pmedium)
    font = love.graphics.getFont()
    local goalText = tostring(game.goal)
    local goalTextWidth = font:getWidth(goalText)
    love.graphics.setColor(0,0,0,.8)
    love.graphics.print(goalText, x - goalTextWidth / 2, y + 50)
    love.graphics.setColor(Utils.color("#5162ad"))
    love.graphics.print(goalText, x - goalTextWidth / 2 + textShadowOffset, y + 50 + textShadowOffset)
    
    -- Draw remaining clicks
    love.graphics.setFont(fonts.p2p)
    font = love.graphics.getFont()
    local clicksText = tostring(game.clicks)
    local clicksTextWidth = font:getWidth(clicksText)
    love.graphics.setColor(1, 1, 1, .5)
    love.graphics.print(clicksText, x  + 500 - clicksTextWidth - textShadowOffset, y - textShadowOffset)
    love.graphics.setColor(Utils.color("#eb3e38"))
    love.graphics.print(clicksText, x  + 500 - clicksTextWidth, y)

    love.graphics.setFont(fonts.p2pmedium)
    love.graphics.setColor(1, 1, 1, .5)
    love.graphics.print("/" .. game.startingClicks, x  + 500 - textShadowOffset, y + 30 - textShadowOffset)
    love.graphics.setColor(Utils.color("#eb3e38"))
    love.graphics.print("/" .. game.startingClicks, x  + 500, y + 30)

    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white

    love.graphics.setFont(fonts.p2p)

    
    -- End camera transform
    love.graphics.pop()
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check if any key is clicked
        -- combine keys and animation buttons in one table
        if inRound and not modifierTimelineManager.active then
            for _, key in ipairs(keys) do
                if key.hover then
                    key.hot = true
                    if key.triggerOnClick then
                        key.callback()
                    end
                end
            end
        end

        if inShop and not modifierTimelineManager.active then
            for _, key in ipairs(uikeys) do
                if key.hover then
                    key.hot = true
                    if key.triggerOnClick then
                        key.callback()
                    end
                end
            end
        end

        -- same for anim buttons
        if inShop and shopManager.animation then
            for _, item in ipairs(shopManager.items) do
                if item.button.hover then
                    item.button.hot = true
                    if item.button.triggerOnClick then
                        item.button.callback()
                    end
                end
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        -- Reset clicked state
        if inRound then
            for _, key in ipairs(keys) do
                if not key.triggerOnClick and key.hot and key.hover then
                    key.callback()
                end
                key.hot = false
            end
        end

        if inShop then
            for _, key in ipairs(uikeys) do
                if not key.triggerOnClick and key.hot and key.hover then
                    key.callback()
                end
                key.hot = false
            end
        end
        
        -- same for animation buttons
        if inShop and shopManager.animation then
            for _, item in ipairs(shopManager.items) do
                if item.button.hot and item.button.hover then
                    item.button.callback()
                end
                item.button.hot = false
            end
        end
    end
end