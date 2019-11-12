require "neat"

function love.load()
  love.physics.setMeter(64)
  world = love.physics.newWorld(0, 0, true)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  persisting = 0
  
  --All the physics objects
  objects = {}
  objects.sliders = {}
  objects.food = {}
  objects.eggs = {}
  deadboys = {}
  deadpellets = {}
  deadeggs = {}
  
  --initial graphics setup
  love.graphics.setBackgroundColor(0.21, 0.33, 0.57) --set the background color to a nice blue
  love.window.setMode(650, 650, {resizable=true, vsync=false, minwidth=400, minheight=300}) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing
  love.keyboard.setKeyRepeat(true)
  love.graphics.setDefaultFilter( "nearest", "nearest", 1 )
  
  -- coordinates for world origin
  originx = 0
  originy = 0
  tick = 0
  tickrate = 0.5
  totalfood = 0
  math.randomseed(os.time())
  
  sliderimg = love.graphics.newImage("slider.png")
  eggimg = love.graphics.newImage("egg.png")
  pellet = love.graphics.newImage("universalpellet.png")
  
  --Global Slider stats
  slidersEver = 0
  foodEver = 0
  eggsEver = 0
  
  
  seedSliders()
end

function love.update(dt)
  world:update(dt) --this puts the world into motion
	clearDead()
	
  tick = tick + dt
  if tick >= tickrate then
	tick = tick - tickrate
	sliderNeeds()
	sliderOutputs()
	placeFood()
  end
  
  
end

function love.draw()
	love.graphics.setColor(1,1,1,1)
	if #objects.eggs > 0 then
		for i = 1, #objects.eggs do
			love.graphics.draw(eggimg,objects.eggs[i].body:getX(),objects.eggs[i].body:getY(),0,0.2+((100-objects.eggs[i].timeleft)/100),0.2+((100-objects.eggs[i].timeleft)/100),8,8)
		end
	end
	if #objects.sliders > 0 then
		for i = 1, #objects.sliders do
			love.graphics.draw(sliderimg,objects.sliders[i].body:getX(),objects.sliders[i].body:getY(),objects.sliders[i].body:getAngle(),objects.sliders[i].physicalGenetics.size*1,objects.sliders[i].physicalGenetics.size*1,16,16)
			--love.graphics.circle("line",objects.sliders[i].body:getX(),objects.sliders[i].body:getY(),7)
		end
	end
	if #objects.food > 0 then
		for i = 1, #objects.food do
			love.graphics.setColor(0.5,1,0.5,1)
			love.graphics.draw(pellet,objects.food[i].body:getX(),objects.food[i].body:getY(),objects.food[i].body:getAngle(),1,1,4,4)
		end
	end
	
end

function love.keypressed(key)
	
	if key == "down" then
		world:translateOrigin(0,5)
		originy = originy -5
	elseif key == "up" then
		world:translateOrigin(0,-5)
		originy = originy +5
	elseif key == "left" then
		world:translateOrigin(-5,0)
		originx = originx -5
	elseif key == "right" then
		world:translateOrigin(5,0)
		originx = originx +5
	end

end

function newSlider(number, x, y)
	local slider = {}
	
	--Physical Genetic Traits
	slider.physicalGenetics = {}
	slider.physicalGenetics.mutationChance = 0.1
	slider.physicalGenetics.mutationMagnitude = 0.01
	slider.physicalGenetics.size = 1
	slider.physicalGenetics.viewAngle = 90
	slider.physicalGenetics.viewDistance = 150
	slider.physicalGenetics.speed = 1
	slider.physicalGenetics.colorRed = 1
	slider.physicalGenetics.colorGreen = 1
	slider.physicalGenetics.colorBlue = 1
	
	--slider Physics
	slider.body = love.physics.newBody(world, x, y, "dynamic") --place the body and make it dynamic, so it can move around
	slider.shape = love.physics.newCircleShape(7*slider.physicalGenetics.size) --the slider's shape has a radius of 16
	slider.fixture = love.physics.newFixture(slider.body, slider.shape, 1) -- Attach fixture to body and give it a density of 1.
	slider.fixture:setUserData("Slider")
	slider.fixture:setRestitution(0.9) --let the slider bounce
	slider.mouthshape = love.physics.newEdgeShape((7*slider.physicalGenetics.size)+0.1,-3*slider.physicalGenetics.size,(7*slider.physicalGenetics.size)+0.1,3*slider.physicalGenetics.size)
	slider.mouthfix = love.physics.newFixture(slider.body, slider.mouthshape, 0.1)
	slider.mouthfix:setUserData("Mouth")
	slider.mouthfix:setRestitution(0)
	slider.body:setLinearDamping(1)
	slider.body:setAngularDamping(1)
	
	--Don't ask me why, but facing right is the default position.
	slider.body:setAngle(math.rad(math.random(0,360)))
	
	--slider Stats
	slider.ID = number
	slider.energy = 100
	slider.stomach = 100
	slider.lifespan = 100
	slider.turning = 0
	slider.thrust = 0
	slider.body:setUserData(slider.ID)
	
	slidersEver = slidersEver + 1
	return slider
end

function newEgg(slider, x, y)
	local egg = {}
	--slider Physics
	egg.body = love.physics.newBody(world, x, y, "dynamic") --place the body and make it dynamic, so it can move around
	
	egg.timeleft = 100
	egg.parent = slider
	egg.ID = eggsEver + 1
	eggsEver = eggsEver + 1
	return egg
end

function hatchEgg(egg,tablenum)
	local slid = egg.parent
	local baby = {}
	
	--Physical Genetic Traits
	baby.physicalGenetics = slid.physicalGenetics
	
	baby.ID = slidersEver + 1
	baby.energy = 20
	baby.lifespan = 100
	baby.stomach = 20
	baby.body = love.physics.newBody(world, egg.body:getX(), egg.body:getY(), "dynamic") --place the body and make it dynamic, so it can move around
	baby.shape = love.physics.newCircleShape(7*baby.physicalGenetics.size) --the slider's shape has a radius of 16
	baby.fixture = love.physics.newFixture(baby.body, baby.shape, 1) -- Attach fixture to body and give it a density of 1.
	baby.fixture:setUserData("Slider")
	baby.fixture:setRestitution(0.9) --let the slider bounce
	baby.mouthshape = love.physics.newEdgeShape((7*baby.physicalGenetics.size)+0.1,-3*baby.physicalGenetics.size,(7*baby.physicalGenetics.size)+0.1,3*baby.physicalGenetics.size)
	baby.mouthfix = love.physics.newFixture(baby.body, baby.mouthshape, 0.1)
	baby.mouthfix:setUserData("Mouth")
	baby.mouthfix:setRestitution(0.9)
	baby.body:setLinearDamping(1)
	baby.body:setAngularDamping(1)
	--Don't ask me why, but facing right is the default position.
	baby.body:setAngle(math.rad(math.random(0,360)))
	
	
	
	baby.turning = slid.turning + math.random(-0.05,0.05)
	baby.thrust = slid.thrust + math.random(-0.05,0.05)
	baby.body:setUserData(baby.ID)
	slidersEver = slidersEver + 1
	table.insert(objects.sliders,baby)
	table.insert(deadeggs,egg.ID)
end

function newFood(x, y)
	food = {}
	--pellet Physics
	food.body = love.physics.newBody(world, x, y, "dynamic") --place the body and make it dynamic, so it can move around
	food.shape = love.physics.newCircleShape(4) --the slider's shape has a radius of 4
	food.fixture = love.physics.newFixture(food.body, food.shape, 0.1) -- Attach fixture to body and give it a density of 1.
	food.fixture:setUserData("Pellet")
	food.fixture:setRestitution(0) --let the slider bounce
	food.body:setLinearDamping(1)
	food.body:setAngularDamping(1)
	
	totalfood = totalfood + 1
	foodEver = foodEver + 1
	food.body:setUserData(foodEver)
	food.ID = foodEver
	return food
end

function placeFood()
	while totalfood < 500 do
		objects.food[#objects.food+1] = newFood(math.random(-1500,1500),math.random(-1000,1000))
	end
end

function sliderOutputs()
	--control forces
	if #objects.sliders > 0 then
		for i = 1, #objects.sliders do
			objects.sliders[i].body:applyAngularImpulse(objects.sliders[i].turning)
			local angle = objects.sliders[i].body:getAngle()
			local vector = angle2vector(angle)
			objects.sliders[i].body:applyLinearImpulse(vector.x*objects.sliders[i].thrust,vector.y*objects.sliders[i].thrust)
		end
	end
end

function clearDead()
	--Clear out the deadboys
	while #deadboys > 0 do
		for i = 1, #objects.sliders do
			if deadboys[1] == objects.sliders[i].ID then
				objects.sliders[i].body:destroy()
				table.remove(objects.sliders,i)
				table.remove(deadboys,1)
				break
			end
		end
	end
	--Clear Dead Pellets
	while #deadpellets > 0 do
		for i = 1, #objects.food do
			if deadpellets[1] == objects.food[i].ID then
				objects.food[i].body:destroy()
				table.remove(objects.food,i)
				table.remove(deadpellets,1)
				break
			end
		end
	end
	--Clear Dead Eggs
	while #deadeggs > 0 do
		for i = 1, #objects.eggs do
			if deadeggs[1] == objects.eggs[i].ID then
				objects.eggs[i].body:destroy()
				table.remove(objects.eggs,i)
				table.remove(deadeggs,1)
				break
			end
		end
	end
end

function sliderNeeds()
  --Iterate on Needs
	if #objects.sliders > 0 then
		for i = 1, #objects.sliders do
			if objects.sliders[i].stomach >= 3 and objects.sliders[i].energy <= 94 then
				objects.sliders[i].stomach = objects.sliders[i].stomach - 3
				objects.sliders[i].energy = objects.sliders[i].energy + 9
			end
			objects.sliders[i].energy = objects.sliders[i].energy - 3
			objects.sliders[i].lifespan = objects.sliders[i].lifespan - 0.4
			if objects.sliders[i].energy <= 0 or objects.sliders[i].lifespan <= 0 then
				table.insert(deadboys,objects.sliders[i].ID)
			end
			--lay eggs
			if #objects.sliders + #objects.eggs < 100 then
				if objects.sliders[i].stomach > 50 and objects.sliders[i].energy >= 90 then
					objects.eggs[#objects.eggs+1] = newEgg(objects.sliders[i],objects.sliders[i].body:getX(),objects.sliders[i].body:getY())
					objects.sliders[i].stomach = objects.sliders[i].stomach - 20
					objects.sliders[i].energy = objects.sliders[i].energy - 20
				end
			end
		end
	end
	if #objects.sliders < 20 then
		seedSliders()
	end
	if #objects.eggs > 0 then
		for i = 1, #objects.eggs do
			objects.eggs[i].timeleft = objects.eggs[i].timeleft - 5
			if objects.eggs[i].timeleft <= 0 then
				hatchEgg(objects.eggs[i],i)
			end	
		end
	end
end



function seedSliders()
  local num = #objects.sliders + 1
  objects.sliders[num] = newSlider(slidersEver+1, math.random(100,1000), math.random(100,800))
  objects.sliders[num].thrust = math.random(0.1,1)
  objects.sliders[num].turning = math.random(-0.1,0.1)
  objects.sliders[num].physicalGenetics.size = objects.sliders[num].physicalGenetics.size + (math.random(10)/10)
end


--Collision Functions
function beginContact(a, b, coll)
	if a:getUserData() == "Mouth" and b:getUserData() == "Pellet" then
		local bod = b:getBody()
		local slid = a:getBody()
		local num = bod:getUserData()
		local slidnum = slid:getUserData()
		local x, y = coll:getNormal()
		for i = 1,#objects.food do
			if objects.food[i].ID == num then
				totalfood = totalfood - 1
				table.insert(deadpellets,objects.food[i].ID)
				for i = 1,#objects.sliders do
					if objects.sliders[i].ID == slidnum then
						objects.sliders[i].stomach = objects.sliders[i].stomach + 80
						if objects.sliders[i].stomach > 100 then
							objects.sliders[i].stomach = 100
						end
						break
					end
				end
				break
			end
		end
	end
	if b:getUserData() == "Mouth" and a:getUserData() == "Pellet" then
		local bod = a:getBody()
		local num = bod:getUserData()
		local slid = b:getBody()
		local slidnum = slid:getUserData()
		local x, y = coll:getNormal()
		for i = 1,#objects.food do
			if objects.food[i].ID == num then
				totalfood = totalfood - 1
				table.insert(deadpellets,objects.food[i].ID)
				for i = 1,#objects.sliders do
					if objects.sliders[i].ID == slidnum then
						objects.sliders[i].stomach = objects.sliders[i].stomach + 80
						if objects.sliders[i].stomach > 100 then
							objects.sliders[i].stomach = 100
						end
						break
					end
				end
				break
			end
		end
	end
end
 
function endContact(a, b, coll)
 
end
 
function preSolve(a, b, coll)
 
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
 
end



-- angle needs to be in radians
function angle2vector(angle)
	local vector = {}
	vector.x = math.cos(angle)
	vector.y = math.sin(angle)
	return vector
end

-- returns angle in radians
function vector2angle(x,y)
	local angle = math.atan2(y,x)
	return angle
end