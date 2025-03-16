--============  Global Setup  ============--
local enet = require("enet")
local host = enet.host_create()
local server = host:connect("73.70.160.188:6789")

-- Custom objects
local Utils = require("scripts.Utils")
local SpriteAnimation = require("scripts.SpriteAnimation")
local UIButton = require("scripts.UIButton")
local Enemy = require("scripts.Enemy")

-- Global states
local players = {} -- Track all players
local enemies = {} -- Track all enemies
local bullets = {} -- Track all bullets
local uiobjects = {} -- Track all UI objects
local playerID = nil -- This client's ID


--============  Manager helper functions that should be moved to management classes  ============--

-- Enemy manager functions

function spawnEnemy(x, y, player)
    local enemy = Enemy:new(x, y, player)
    table.insert(enemies, enemy)
end

function updateEnemies(dt)
    for _, enemy in ipairs(enemies) do
        enemy:update(dt)
    end
end

function drawEnemies()
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end
end

-- Camera management helpers

function shakeCamera(magnitude, shakeDecay)
    camera.shakeMag = math.min(camera.shakeMag + magnitude, camera.maxShake)
    if shakeDecay then
        camera.shakeDecay = shakeDecay
    else
        camera.shakeDecay = 20
    end
end

function updateCameraShake(dt)
    if camera.shakeMag > 0 then
        camera.x = (math.random() * 2 - 1) * camera.shakeMag
        camera.y = (math.random() * 2 - 1) * camera.shakeMag
        camera.shakeMag = math.max(camera.shakeMag - camera.shakeDecay * dt, 0)
    else
        camera.x, camera.y = 0, 0
    end
end


--============  On-Load Initializers  ============--

function initializeUIButtons()
    table.insert(uiobjects, UIButton:new({
        x = love.graphics.getWidth() / 2 - 100,
        y = love.graphics.getHeight() / 2 - 50,
        width = 200,
        height = 45,
        text = "Start",
        callback = function()
            changeScene("game")
        end
    }))
end


--============  LOVE Hooks - Main Loop  ============--

-- LOAD
function love.load()
    love.window.setMode(1200, 800, {resizable = false})
    love.window.setTitle("Mazatro")
    initializeUIButtons()

    
    -- Global variables
    colors = {
        blue = Utils.color("#819796", 1)
    }

    fonts = {
        poppins = love.graphics.newFont("fonts/Poppins-Medium.ttf", 32)
    }

    scenes = {
        menu = drawMenuScene,
        game = drawGameScene,
    }

    game = {
        scene = "menu",
        sound_enabled = true,
        music_enabled = false
    }

    sounds = {
        menu = love.audio.newSource("sounds/music3.ogg", "stream"),
        game = love.audio.newSource("sounds/music2.ogg", "stream"),
        shot = love.audio.newSource("custom-sounds/pistol-shot.ogg", "static"),
        slimeHit = love.audio.newSource("custom-sounds/slime-hit.ogg", "static"),
        multHit = love.audio.newSource("sounds/multhit2.ogg", "static"),
        click = love.audio.newSource("sounds/generic1.ogg", "static"),
    }

    sprites = {
        player = love.graphics.newImage("sprites/player.png"),
        gun = love.graphics.newImage("sprites/gun.png"),
    }

    camera = {
        x = 0,
        y = 0,
        shakeMag = 0,
        shakeDecay = 20,
        maxShake = 5
    }
    
    player = {
        x = love.graphics.getWidth() / 2 - 10, -- x position of player
        y = love.graphics.getHeight() / 2 - 10, -- y position of player
        radians = 0, -- angle of player
        width = 64, -- width of player
        height = 64, -- height of player
        speed = 400, -- movement speed
        fireRate = .1, -- time between shots
        firePushback = 5, -- how much the player is pushed back when firing
        fx = 0, -- force x
        fy = 0, -- force y
        muzzleFlash = { -- muzzle flash effect properties
            active = false,
            size = 0,
            rotation = 0,
            duration = 0
        },
        debugMode = false, -- draw hitbox for debugging
        damage = 10, -- damage dealt by player
        gunShake = {
            x = 0,
            y = 0,
            duration = 0
        },
        gunTipX = 0, -- x position of gun tip
        gunTipY = 0, -- y position of gun tip

        -- properties used by object
        isMoving = false, -- is the player moving?
        particleSystem = nil,  -- particle system for muzzle shot
        fireTime = 0, -- time since last fire
        autoaim = true, -- autoaim towards nearest enemy
        fire = function(self)
            -- Play sound
            local s = sounds.shot:clone()
            -- s:seek(0.1) -- heavy pistol / medium smg
            s:seek(0.15) -- light smg / medium pistol
            s:play()

            -- Camera shake
            shakeCamera(2)

            -- Character recoil
            -- local dx = math.cos(self.radians) * self.firePushback
            -- local dy = math.sin(self.radians) * self.firePushback
            -- self.fx = -dx*20
            -- self.fy = -dy*20

            -- gun shake
            self.gunShake.duration = .1

            -- Generate muzzle flash (random size and rotation)
            self.muzzleFlash.active = true
            self.muzzleFlash.size = love.math.random(10, 15)
            self.muzzleFlash.rotation = love.math.random(0, math.pi * 2)
            self.muzzleFlash.duration = 0.05

            -- Trigger particle system (emits particles at the muzzle position)
            if self.particleSystem then
                self.particleSystem:setPosition(self.gunTipX, self.gunTipY)
                self.particleSystem:setDirection(self.radians)
                self.particleSystem:emit(5)  -- Emit 30 particles per shot
            end

            -- fire instant-hit projectile using a step-based collision detection
            -- TODO: Add bullet sprite and create echo trajectory that appears & disappears very quickly

            local step = 1
            local distance = 2
            local maxDistance = 1000
            local hit = false
            while not hit and step*distance < maxDistance do
                local x = self.x + distance*step*math.cos(self.radians)
                local y = self.y + distance*step*math.sin(self.radians)

                -- Check if the shot hits any enemies
                for i, enemy in ipairs(enemies) do
                    if x > enemy.x and x < enemy.x + enemy.width and y > enemy.y and y < enemy.y + enemy.height then
                        hit = true
                        enemy.health = enemy.health - self.damage
                        if enemy.hitCooldown == 0 then
                            -- random from 150 to 200
                            enemy:applyForce(self.radians, love.math.random(150, 200)) -- Apply force to the enemy
                            enemy.hitCooldown = 0.1
                            enemy.hit = true
                        end

                        if enemy.health <= 0 then
                            table.remove(enemies, i)

                            -- particles
                            if self.particleSystem then
                                self.particleSystem:setPosition(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2)
                                self.particleSystem:emit(30)  -- Emit 30 particles on hit
                            end

                            -- play sounds
                            local s = sounds.slimeHit:clone()
                            s:seek(0.1)
                            s:play()  
                            local ss = sounds.multHit:clone()
                            ss:play()

                            -- shake camera
                            shakeCamera(5, 100)

                            break
                        else
                            -- play sounds
                            local s = sounds.slimeHit:clone()
                            s:seek(0.1)
                            s:play() 
                            
                            -- particles
                            if self.particleSystem then
                                self.particleSystem:setPosition(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2)
                                self.particleSystem:emit(30)  -- Emit 30 particles on hit
                            end

                            break
                        end
                    end
                end

                step = step + 1
            end
        end,
        draw = function(self)
            -- -- calculate walking shuffle
            local wobbleAmount = 1.5  -- Reduced for subtlety (adjustable)
            local wobbleSpeed = 25   -- Slower for a natural pace (adjustable)
            local wobbleX, wobbleY = 0, 0
            if isMoving then
                wobbleX = math.sin(love.timer.getTime() * wobbleSpeed) * wobbleAmount
                wobbleY = math.sin(love.timer.getTime() * wobbleSpeed) * wobbleAmount
            end

            -- -- Draw player
            -- love.graphics.setColor(1, 1, 1)
            -- sprites.player:setFilter("nearest", "nearest")
            -- love.graphics.draw(sprites.player, self.x + self.width / 2 + wobbleX, self.y + self.height / 2 + wobbleY, self.radians - math.pi / 2, 2, 2, sprites.player:getWidth() / 2, sprites.player:getHeight() / 2)


            -- draw gun
            love.graphics.setColor(1, 1, 1)
            sprites.gun:setFilter("nearest", "nearest")
            local flipX = 1
            if self.radians > math.pi / 2 or self.radians < -math.pi / 2 then
                flipX = -1
            end
            love.graphics.draw(sprites.gun, self.x + self.width / 2 + self.gunShake.x + wobbleX, self.y + self.height / 2 + self.gunShake.y + wobbleY, self.radians, 3, 3 * flipX, sprites.gun:getWidth() / 2, sprites.gun:getHeight() / 2)



            -- Draw particle system
            if self.particleSystem then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(self.particleSystem)
            end

            -- Draw muzzle flash if active
            if self.muzzleFlash.active then
                love.graphics.setColor(1, 1, 1, .7)
                love.graphics.push()
                love.graphics.translate(self.gunTipX, self.gunTipY)
                love.graphics.rotate(self.muzzleFlash.rotation)
                love.graphics.rectangle("fill", -self.muzzleFlash.size / 2, -self.muzzleFlash.size / 2, self.muzzleFlash.size, self.muzzleFlash.size)
                love.graphics.pop()

                -- Reduce the duration of the flash
                self.muzzleFlash.duration = self.muzzleFlash.duration - love.timer.getDelta()
                if self.muzzleFlash.duration <= 0 then
                    self.muzzleFlash.active = false
                end
            end
              
            if self.debugMode then
                -- draw gun tip
                love.graphics.setColor(1, 0, 0, 0.5)
                love.graphics.circle("fill", self.gunTipX, self.gunTipY, 5)

                -- draw player hitbox
                love.graphics.setColor(1, 0, 0, 0.5)
                love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
            end
        end,
        update = function(self, dt)
            local dx, dy = 0, 0
            if love.keyboard.isDown("w") then dy = -1 end
            if love.keyboard.isDown("s") then dy = 1 end
            if love.keyboard.isDown("a") then dx = -1 end
            if love.keyboard.isDown("d") then dx = 1 end
            if dy ~= 0 or dx ~= 0 then
                isMoving = true
            else
                isMoving = false
            end

            -- Normalize movement vector to ensure constant speed in all directions
            local length = math.sqrt(dx^2 + dy^2)
            if length > 0 then
                dx = dx / length
                dy = dy / length
            end

            -- Apply speed and delta time
            self.x = self.x + dx * self.speed * dt
            self.y = self.y + dy * self.speed * dt


            

            -- Update rotation based on mouse position or autoaim
            local centerX = self.x + self.width / 2 -- center x position of player
            local centerY = self.y + self.height / 2 -- center y position of player

            if self.autoaim then
                local nearestEnemy = nil
                local nearestDistance = math.huge
                for _, enemy in ipairs(enemies) do
                    local distance = math.sqrt((enemy.x - self.x)^2 + (enemy.y - self.y)^2)
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestEnemy = enemy
                    end
                end
                if nearestEnemy then
                    local dx = (nearestEnemy.x + nearestEnemy.width) - centerX
                    local dy = (nearestEnemy.y + nearestEnemy.height) - centerY
                    self.radians = math.atan2(dy, dx)
                end
            else
                local mx, my = love.mouse.getPosition()
                self.radians = math.atan2(my - centerY, mx - centerX)
            end

            -- update gun tip position
            self.gunTipX = centerX + math.cos(self.radians) * 52
            self.gunTipY = centerY + math.sin(self.radians) * 52

            -- movement from force
            if self.fx ~= 0 or self.fy ~= 0 then
                -- apply force
                self.x = self.x + self.fx * dt
                self.y = self.y + self.fy * dt
                -- apply friction
                if math.abs(self.fx) < 0.1 then self.fx = 0 else self.fx = self.fx * 0.9 end
                if math.abs(self.fy) < 0.1 then self.fy = 0 else self.fy = self.fy * 0.9 end
            end

            -- update gun shake quickly WITHOUT USING DECAY
            if self.gunShake.duration > 0 then
                self.gunShake.x = math.random(-1, 1) * 3
                self.gunShake.y = math.random(-1, 1) * 3
                self.gunShake.duration = self.gunShake.duration - love.timer.getDelta()
            else
                self.gunShake.x = 0
                self.gunShake.y = 0
            end

            -- if mouse is down then fire but make sure to limit it by a firerate
            if love.mouse.isDown(1) then
                if self.fireTime > self.fireRate then
                    self.fire(self);
                    self.fireTime = 0
                end
            end
            if self.fireTime < self.fireRate then
                self.fireTime = self.fireTime + dt
            end

            if self.particleSystem then
                self.particleSystem:update(dt)  -- Update particles
            end
        end,
        -- Initialize the particle system
        initializeParticles = function(self)
            local image = love.graphics.newImage("sprites/particle.png")  -- Use a small spark image for the particles
            self.particleSystem = love.graphics.newParticleSystem(image, 100)

            self.particleSystem:setEmissionRate(0)  -- Start with no emission
            self.particleSystem:setParticleLifetime(0.05, 0.07)  -- Lifetime of each particle
            self.particleSystem:setSpeed(300, 500)  -- Speed range of the particles
            self.particleSystem:setSizeVariation(1)  -- Particles can vary in size
            self.particleSystem:setSizes(0.5, 1)  -- Initial size range of the particles
            self.particleSystem:setSpin(0, math.pi)  -- Particles can rotate
            self.particleSystem:setColors(1, 0.7, 0.2, 1, 1, 1, 1, 1)  -- Particle color (orange/yellow)
            self.particleSystem:setDirection(self.radians)  -- Particles are emitted in all directions
            self.particleSystem:setSpread(math.pi/2)
            self.particleSystem:setRadialAcceleration(5000)  -- Particles have an outward push
        end,
    }

    if game.sound_enabled then
        love.audio.setVolume(0.2)
    else
        love.audio.setVolume(0)
    end


    love.graphics.setBackgroundColor(colors.blue)
    love.graphics.setFont(fonts.poppins)

    player:initializeParticles()

    if game.music_enabled then
        sounds.menu:setLooping(true)
        sounds.menu:play()
    end
end

-- UPDATE
function love.update(dt)
    -- Game scene
    if game.scene == "game" then
        -- Update player position
        player:update(dt)

        -- Update camera
        updateCameraShake(dt)

        -- Send local player position
        local data = string.format("%f,%f,%.6f", player.x, player.y, player.radians)
        server:send(data)

        --  Update enemies
        updateEnemies(dt)

        -- spawn enemies randomly
        if math.random() < 0.1 then
            local x = love.math.random(0, love.graphics.getWidth())
            local y = love.math.random(0, love.graphics.getHeight())
            spawnEnemy(x, y, player)
        end
    
        -- Process network events
        local event = host:service(100)
        while event do
            if event.type == "receive" then
                local id, x, y, radians = event.data:match("([^,]+),([%-?%d%.]+),([%-?%d%.]+),([%-?%d%.]+)")
                if id and x and y and radians then
                    players[id] = { x = tonumber(x), y = tonumber(y), radians = tonumber(radians) }
                end
            elseif event.type == "connect" then
                print(event.peer, "connected.")
                playerID = tostring(event.peer:connect_id())
            elseif event.type == "disconnect" then
                print(event.peer, "disconnected.")
                players[playerID] = nil
            end
            event = host:service()
        end
    end
end

-- DRAW 
function love.draw()

    -- set default attributes
    love.mouse.setCursor()

    -- Render current scene
    if scenes[game.scene] then
        scenes[game.scene]()
    else
        drawNotFoundScene()
    end
end

-- QUIT
function love.quit()
    love.graphics.setShader()  -- reset shader before quitting
end

--============  LOVE HOOKS - Event Handlers  ============--

-- handle mouse events - only register click if mouse is both pressed and released within a button's area

-- MOUSE PRESSED
function love.mousepressed(x, y, button)
    if game.scene == "menu" then
        for _, obj in ipairs(uiobjects) do
            if button == 1 and x > obj.x and x < obj.x + obj.width and
               y > obj.y and y < obj.y + obj.height then
                obj.hot = true
            end
        end
    end
end

-- MOUSE RELEASED
function love.mousereleased(x, y, button)
    if game.scene == "menu" then
        for _, obj in ipairs(uiobjects) do
            if obj.hot and button == 1 and x > obj.x and x < obj.x + obj.width and
            y > obj.y and y < obj.y + obj.height then
                local s = sounds.click:clone()
                s:play()
                obj.callback()
            end
            if obj.hot then
                obj.hot = false
            end
        end
    end
end

--============  Scene Helpers  ============--

-- Change scene
function changeScene(newScene)
    -- set new scene
    game.scene = newScene

    -- play new scene sound
    if game.music_enabled then
        if game.scene == "menu" then
            sounds.menu:stop()
            sounds.game:play()
        elseif game.scene == "game" then
            sounds.game:stop()
            sounds.menu:play()
        end
    end 
end

--============  Scenes  ============--

-- Draw menu scene
function drawMenuScene()
    for _, obj in ipairs(uiobjects) do
        obj:draw()
    end
end

-- Draw game scene
function drawGameScene()
    love.graphics.push()

    -- Translate for camera shake
    love.graphics.translate(camera.x, camera.y)

    -- draw enemies
    drawEnemies()

    -- Draw other players
    love.graphics.setColor(1, 0, 0)
    for id, p in pairs(players) do
        if id ~= playerID then
            love.graphics.setColor(.6, .6, 1) -- blue-shift for other players
            sprites.player:setFilter("nearest", "nearest")
            love.graphics.draw(sprites.player, p.x, p.y, p.radians - math.pi / 2 , 2, 2, sprites.player:getWidth()/2, sprites.player:getHeight()/2)
        end
    end

    

    -- Draw player
    player:draw()

    love.graphics.pop()
end

-- Draw null scene
function drawNotFoundScene()
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("Scene not found", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, 1, 1, 0, 0)
end
