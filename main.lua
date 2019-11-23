require "neat"

function love.load()
  love.physics.setMeter(20)
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
  love.filesystem.write("neatlog.txt", "==================Log Begins=================")
  
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
  constant = 1
end

function love.update(dt)
  world:update(dt) --this puts the world into motion
	clearDead()
	sliderBrainTick()
	
	
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
			love.graphics.setColor(1,1,1,1)
			love.graphics.draw(eggimg,objects.eggs[i].body:getX(),objects.eggs[i].body:getY(),0,0.2+((100-objects.eggs[i].timeleft)/100),0.2+((100-objects.eggs[i].timeleft)/100),8,8)
		end
	end
	if #objects.sliders > 0 then
		for i = 1, #objects.sliders do
			love.graphics.setColor(objects.sliders[i].physicalGenetics.colorRed,objects.sliders[i].physicalGenetics.colorGreen,objects.sliders[i].physicalGenetics.colorBlue,1)
			love.graphics.draw(sliderimg,objects.sliders[i].body:getX(),objects.sliders[i].body:getY(),objects.sliders[i].body:getAngle(),objects.sliders[i].physicalGenetics.size*1,objects.sliders[i].physicalGenetics.size*1,16,16)
			--love.graphics.circle("line",objects.sliders[i].body:getX(),objects.sliders[i].body:getY(),7)
		end
	end
	if #objects.food > 0 then
		for i = 1, #objects.food do
			love.graphics.setColor(0.5,1,0.5,1)
			love.graphics.draw(pellet,objects.food[i].body:getX(),objects.food[i].body:getY(),objects.food[i].body:getAngle(),objects.food[i].total/100,objects.food[i].total/100,4,4)
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
	-- 0.1-1.0 mutation chance
	slider.physicalGenetics.mutationChance = 0.5
	-- 0.01-0.1 mutation change
	slider.physicalGenetics.mutationMagnitude = 0.05
	slider.physicalGenetics.size = 1
	--view angle is 0.1-1.0 * 180
	slider.physicalGenetics.viewAngle = 0.5
	--view distance is 0.1-1 *200
	slider.physicalGenetics.viewDistance = 0.75
	slider.physicalGenetics.speed = 1
	slider.physicalGenetics.colorRed = 1
	slider.physicalGenetics.colorGreen = 1
	slider.physicalGenetics.colorBlue = 1
	
	mutatePhysical(slider.physicalGenetics)
	
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
	
	--FoV
	local fovOffX = 0
	local fovOffY = 0
	local fovOffAngle = (math.abs(math.deg(slider.physicalGenetics.viewAngle*180))-180)/2
	fovOffX = math.sin(fovOffAngle)*(slider.physicalGenetics.viewDistance*200)
	fovOffY = math.sqrt(((slider.physicalGenetics.viewDistance*200)^2)-(fovOffX^2))
	
	slider.fovshape = love.physics.newPolygonShape(0,0,fovOffX,-fovOffY,(slider.physicalGenetics.viewDistance*200),0,fovOffX,fovOffY)
	slider.fov = love.physics.newFixture(slider.body, slider.fovshape, 0)
	slider.fov:setUserData("Sensor")
	slider.fov:setSensor(true)
	
	slider.body:setLinearDamping(1)
	slider.body:setAngularDamping(1)
	slider.body:setMass(slider.physicalGenetics.size)
	
	--Don't ask me why, but facing right is the default position.
	slider.body:setAngle(math.rad(math.random(0,360)))
	
	--slider Stats
	slider.ID = number
	slider.energy = 50
	slider.stomach = 50
	slider.lifespan = 50
	slider.body:setUserData(slider.ID)
	slider.foodseen = {}
	slider.sliderseen = {}
	slider.closestSliderDist = 0
	slider.closestSliderAngle = 0
	slider.closestFoodDist = 0
	slider.closestFoodAngle = 0
	
	--slider Brain
	slider.brain = newBrain()
	--INPUTS
	slider.brain.inputs[1] = slider.energy
	slider.brain.inputs[2] = slider.stomach
	slider.brain.inputs[3] = slider.lifespan
	slider.brain.inputs[4] = constant
	slider.brain.inputs[5] = slider.body:getAngle()
	-- fov brain stuff
	slider.brain.inputs[6] = slider.closestSliderDist
	slider.brain.inputs[7] = slider.closestSliderAngle
	slider.brain.inputs[8] = slider.closestFoodDist
	slider.brain.inputs[9] = slider.closestFoodAngle
	slider.brain.inputs[10] = #slider.foodseen
	slider.brain.inputs[11] = #slider.sliderseen
	
	slider.brain.outputNodes[1] = {}
	slider.brain.outputNodes[1].synapses = {}
	slider.brain.outputNodes[1].value = 0
	slider.brain.outputNodes[1].nodetype = "output"
	
	slider.brain.outputNodes[2] = {}
	slider.brain.outputNodes[2].synapses = {}
	slider.brain.outputNodes[2].value = 0
	slider.brain.outputNodes[2].nodetype = "output"
	
	
	mutateBrain(slider.brain)
	
	slidersEver = slidersEver + 1
	return slider
end

function mutateBrain(brain)
	love.filesystem.append("neatlog.txt",'\n----------Mutating Brain--------------')
	--first we choose to make a new node, a new synapse, delete a node, delete a synapse, or change a synapse
	--{"newnode","newsynapse","delnode","delsynapse","mutsynapse"}
	local optionlist = {"newnode","newsynapse"}
	if brain.synapseNum > 0 then
		love.filesystem.append("neatlog.txt",'\nSynapses: ' ..brain.synapseNum)
		table.insert(optionlist,"delsynapse")
		table.insert(optionlist,"mutsynapse")
	end
	if #brain.hiddenNodes > 0 then
		love.filesystem.append("neatlog.txt",'\nHiddenNodes: ' ..#brain.hiddenNodes)
		table.insert(optionlist,"delnode")
	end
	local choice = optionlist[math.random(1,#optionlist)]
	love.filesystem.append("neatlog.txt",'\n--' ..choice ..'--')
	if choice == "newnode" then
		local nodetypes = {"sig","lin","sqr","sin","abs","rel","gau","lat"}
		local chosenNode = math.random(1,#nodetypes)
		love.filesystem.append("neatlog.txt",'\n' ..chosenNode)
		brain.hiddenNodes[#brain.hiddenNodes+1] = newNode(brain,nodetypes[chosenNode])
	elseif choice == "newsynapse" then
		local inputhiddenNodeID = 0
		local inputnumber = 0
		local hiddenNodeTableNum = 0
		--figuring out the input or hidden node to attach to
		local hiddenNum = 0
		if #brain.hiddenNodes > 0 then
			hiddenNum = #brain.hiddenNodes
		end
		-- if true we'll be using a hiddenNode
		if math.random(1,(hiddenNum+#brain.inputs)) > #brain.inputs then
			local hiddenNodeTableNum = math.random(1,#brain.hiddenNodes)
			inputhiddenNodeID = brain.hiddenNodes[hiddenNodeTableNum].ID
		else
			inputnumber = math.random(1,#brain.inputs)
		end
		-- Now we figure out the output node (or hidden Node) we'll use.
		local outputnumber = 0
		local outputHiddenNodeID = 0
		-- if our input is a hidden node
		if inputhiddenNodeID > 0 then
			outputnumber = math.random(1,2)
		else
			-- if there are hidden nodes
			if hiddenNum > 0 then
				-- if true our output will be a hidden node
				if math.random(1,(hiddenNum+#brain.outputNodes)) > #brain.outputNodes then
					hiddenNodeTableNum = math.random(1,#brain.hiddenNodes)
					outputhiddenNodeID = brain.hiddenNodes[hiddenNodeTableNum].ID
				else
					outputnumber = math.random(1,2)
				end
			else
				outputnumber = math.random(1,2)
			end
		end
		-- finally we add the new synapse to the output node
		-- if it's an output node
		if outputnumber > 0 then
			if inputhiddenNodeID > 0 then
				--nodes are numbered after the first 11 input nodes. So input can be the ID
				brain.outputNodes[outputnumber].synapses[#brain.outputNodes[outputnumber].synapses+1] = newSynapse(inputhiddenNodeID,math.random(-10,10)/10)
				brain.synapseNum = brain.synapseNum + 1
			else
				--nodes are numbered after the first 11 input nodes. So input can be the ID
				brain.outputNodes[outputnumber].synapses[#brain.outputNodes[outputnumber].synapses+1] = newSynapse(inputnumber,math.random(-10,10)/10)
				brain.synapseNum = brain.synapseNum + 1
			end
		else
			--if the hidden node is the output we don't have to worry about checking for a hidden node as an input.
			brain.hiddenNodes[hiddenNodeTableNum].synapses[#brain.hiddenNodes[hiddenNodeTableNum].synapses+1] = newSynapse(inputnumber,math.random(-10,10)/10)
			brain.synapseNum = brain.synapseNum + 1
		end
	elseif choice == "delnode" then
		--since delnode is only available if there are hidden nodes, we don't need to check for them
		local num = math.random(1,#brain.hiddenNodes)
		if #brain.hiddenNodes[num].synapses > 0 then
			for i = 1,#brain.hiddenNodes[num].synapses do
				table.remove(brain.hiddenNodes[num].synapses,i)
				brain.synapseNum = brain.synapseNum - 1
			end
		end
		-- clean up any synapses that had it as an input
		if brain.synapseNum > #brain.inputs then
			for i = 1,#brain.outputNodes do
				if #brain.outputNodes[i].synapses > 0 then
					for j = 1,#brain.outputNodes[i].synapses do
						if brain.outputNodes[i].synapses[j].input == brain.hiddenNodes[num].ID then
							table.remove(brain.outputNodes[i].synapses,j)
							brain.synapseNum = brain.synapseNum - 1
						end
					end
				end
			end
		end
		-- finally remove the node
		table.remove(brain.hiddenNodes,num)
	elseif choice == "delsynapse" then
		local hiddenNodeTableNums = {}
		local outputNodeTableNums = {}
		-- first we get all the nodes that have synapses
		if #brain.hiddenNodes > 0 then
			for i = 1,#brain.hiddenNodes do
				if #brain.hiddenNodes[i].synapses > 0 then
					table.insert(hiddenNodeTableNums,i)
					love.filesystem.append("neatlog.txt",'\nHiddenNodeWith Synapse Table Number: ' ..i)
				end
			end
		end
		for i = 1,#brain.outputNodes do
			if #brain.outputNodes[i].synapses > 0 then
				table.insert(outputNodeTableNums,i)
				love.filesystem.append("neatlog.txt",'\nOutputNodeWith Synapse Table Number: ' ..i)
			end
		end
		-- now we count each set and pick one at random
		if #hiddenNodeTableNums + #outputNodeTableNums > 0 then
			if #hiddenNodeTableNums == 0 then
				--just worry about output nodes
				local num = math.random(1,#outputNodeTableNums)
				love.filesystem.append("neatlog.txt",'\nOutputNodeTableNum num: ' ..num)
				local outputnodetablenumber = 0
				love.filesystem.append("neatlog.txt",'\nOutputNodeTableNum: ')
				love.filesystem.append("neatlog.txt",outputNodeTableNums[1])
				outputnodetablenumber = outputNodeTableNums[num]
				love.filesystem.append("neatlog.txt",'\nOutputNodeTableNum: ' ..outputnodetablenumber)
				table.remove(brain.outputNodes[outputnodetablenumber].synapses,1)
				brain.synapseNum = brain.synapseNum - 1
			else
				if #outputNodeTableNums == 0 then
					--just worry about hidden nodes
					local num = math.random(1,#hiddenNodeTableNums)
					table.remove(brain.hiddenNodes[hiddenNodeTableNums[num]].synapses,math.random(1,#brain.hiddenNodes[hiddenNodeTableNums[num]].synapses))
					brain.synapseNum = brain.synapseNum - 1
				else
					--both
					if math.random(1,(#hiddenNodeTableNums+#outputNodeTableNums)) > #hiddenNodeTableNums then
						local num = math.random(1,#outputNodeTableNums)
						table.remove(brain.outputNodes[outputNodeTableNums[num]].synapses,math.random(1,#brain.outputNodes[outputNodeTableNums[num]].synapses))
						brain.synapseNum = brain.synapseNum - 1
					else
						local num = math.random(1,#hiddenNodeTableNums)
						table.remove(brain.hiddenNodes[hiddenNodeTableNums[num]].synapses,math.random(1,#brain.hiddenNodes[hiddenNodeTableNums[num]].synapses))
						brain.synapseNum = brain.synapseNum - 1
					end
				end
			end
		end
	elseif choice == "mutsynapse" then
		local hiddenNodeTableNums = {}
		local outputNodeTableNums = {}
		-- first we get all the nodes that have synapses
		if #brain.hiddenNodes > 0 then
			for i = 1,#brain.hiddenNodes do
				if #brain.hiddenNodes[i].synapses > 0 then
					table.insert(hiddenNodeTableNums,i)
				end
			end
		end
		for i = 1,#brain.outputNodes do
			if #brain.outputNodes[i].synapses > 0 then
				table.insert(outputNodeTableNums,i)
			end
		end
		if #hiddenNodeTableNums + #outputNodeTableNums > 0 then
			-- now we count each set and pick one at random
			if numberOfHiddenNodes == 0 then
				--just worry about output nodes
				local num = math.random(1,#outputNodeTableNums)
				local synapsenum = math.random(1,#brain.outputNodes[outputNodeTableNums[num]].synapses)
				brain.outputNodes[outputNodeTableNums[num]].synapses[synapsenum].value = brain.outputNodes[outputNodeTableNums[num]].synapses[synapsenum].value + math.random(-10,10)/1000
			else
				if numberOfOutputNodes == 0 then
					--just worry about hidden nodes
					local num = math.random(1,#hiddenNodeTableNums)
					local synapsenum = math.random(1,#brain.hiddenNodes[hiddenNodeTableNums[num]].synapses)
					brain.hiddenNodes[hiddenNodeTableNums[num]].synapses[synapsenum].value = brain.hiddenNodes[hiddenNodeTableNums[num]].synapses[synapsenum].value + math.random(-10,10)/1000
				else
					--both
					if math.random(1,(#hiddenNodeTableNums+#outputNodeTableNums)) > #hiddenNodeTableNums then
						local num = math.random(1,#outputNodeTableNums)
						local synapsenum = math.random(1,#brain.outputNodes[outputNodeTableNums[num]].synapses)
						brain.outputNodes[outputNodeTableNums[num]].synapses[synapsenum].value = brain.outputNodes[outputNodeTableNums[num]].synapses[synapsenum].value + math.random(-10,10)/1000
					else
						local num = math.random(1,#hiddenNodeTableNums)
						local synapsenum = math.random(1,#brain.hiddenNodes[hiddenNodeTableNums[num]].synapses)
						mutateSynapse(brain.hiddenNodes[hiddenNodeTableNums[num]].synapses[synapsenum])
					end
				end
			end
		end
	end
end

function mutatePhysical(genes)
	for i = 1, #genes do
		if math.random(100) <= (genes.mutationChance*100) then
			genes[i] = genes[i] + (math.random(-(genes.mutationMagnitude*100),genes.mutationMagnitude*100)/100)
		end
	end
	if genes.mutationChance < 0.1 then
		genes.mutationChance = 0.1
	elseif genes.mutationChance > 1 then
		genes.mutationChance = 1
	end
	if genes.mutationMagnitude < 0.01 then
		genes.mutationMagnitude = 0.01
	elseif genes.mutationMagnitude > 0.1 then
		genes.mutationMagnitude = 0.1
	end
	if genes.size < 0.1 then
		genes.size = 0.1
	end
	if genes.viewAngle < 0.1 then
		genes.viewAngle = 0.1
	elseif genes.viewAngle > 0.99 then
		genes.viewAngle = 0.99
	end
	if genes.viewDistance < 0.1 then
		genes.viewDistance = 0.1
	elseif genes.viewDistance > 1 then
		genes.viewDistance = 1
	end
	if genes.speed < 0.1 then
		genes.speed = 0.1
	end
	if genes.colorRed < 0 then
		genes.colorRed = 0
	elseif genes.colorRed > 1 then
		genes.colorRed = 1
	end
	if genes.colorGreen < 0 then
		genes.colorGreen = 0
	elseif genes.colorGreen > 1 then
		genes.colorGreen = 1
	end
	if genes.colorBlue < 0 then
		genes.colorBlue = 0
	elseif genes.colorBlue > 1 then
		genes.colorBlue = 1
	end
end
	

function mutateSynapse(syn)
	syn.value = syn.value + math.random(-10,10)/1000
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

function hatchEgg(egg)
	local slid = deepCopy(egg.parent)
	local baby = {}
	
	--Physical Genetic Traits
	baby.physicalGenetics = slid.physicalGenetics
	mutatePhysical(baby.physicalGenetics)
	
	
	baby.ID = slidersEver + 1
	baby.energy = 20
	baby.lifespan = 100
	baby.stomach = 20
	baby.foodseen = {}
	baby.sliderseen = {}
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
	baby.body:setMass(baby.physicalGenetics.size)
	
	--FoV
	local fovOffX = 0
	local fovOffY = 0
	local fovOffAngle = (math.abs(math.deg(baby.physicalGenetics.viewAngle*90))-180)/2
	fovOffX = math.sin(fovOffAngle)*(baby.physicalGenetics.viewDistance*200)
	fovOffY = math.sqrt(((baby.physicalGenetics.viewDistance*200)^2)-(fovOffX^2))
	
	baby.fovshape = love.physics.newPolygonShape(0,0,fovOffX,-fovOffY,(baby.physicalGenetics.viewDistance*200),0,fovOffX,fovOffY)
	baby.fov = love.physics.newFixture(baby.body, baby.fovshape, 0)
	baby.fov:setUserData("Sensor")
	baby.fov:setSensor(true)
	
	baby.closestSliderDist = 0
	baby.closestSliderAngle = 0
	baby.closestFoodDist = 0
	baby.closestFoodAngle = 0
	
	
	--slider Brain
	baby.brain = newBrain()
	
	baby.brain.inputs[1] = baby.energy
	baby.brain.inputs[2] = baby.stomach
	baby.brain.inputs[3] = baby.lifespan
	baby.brain.inputs[4] = constant
	baby.brain.inputs[5] = baby.body:getAngle()
	-- fov brain stuff
	baby.brain.inputs[6] = baby.closestSliderDist
	baby.brain.inputs[7] = baby.closestSliderAngle
	baby.brain.inputs[8] = baby.closestFoodDist
	baby.brain.inputs[9] = baby.closestFoodAngle
	baby.brain.inputs[10] = #baby.foodseen
	baby.brain.inputs[11] = #baby.sliderseen
	
	baby.brain.outputNodes = deepCopy(slid.brain.outputNodes)
	baby.brain.hiddenNodes = slid.brain.hiddenNodes
	baby.brain.synapseNum = slid.brain.synapseNum
	baby.brain.nodesEver = slid.brain.nodesEver
	
	mutateBrain(baby.brain)
	
	baby.body:setUserData(baby.ID)
	slidersEver = slidersEver + 1
	table.insert(objects.sliders,baby)
	table.insert(deadeggs,egg.ID)
end

function newFood(x, y)
	food = {}
	--pellet Physics
	food.total = 100
	food.body = love.physics.newBody(world, x, y, "dynamic") --place the body and make it dynamic, so it can move around
	food.shape = love.physics.newCircleShape(4*(food.total/100)) --the slider's shape has a radius of 4
	food.fixture = love.physics.newFixture(food.body, food.shape, 0) -- Attach fixture to body and give it a density of 1.
	food.fixture:setUserData("Pellet")
	food.fixture:setRestitution(0) --let the slider bounce
	food.body:setLinearDamping(1)
	food.body:setAngularDamping(1)
	food.body:setMass(0.01)
	totalfood = totalfood + 1
	foodEver = foodEver + 1
	food.body:setUserData(foodEver)
	food.ID = foodEver
	
	return food
end

function placeFood()
	while totalfood < 300 do
		objects.food[#objects.food+1] = newFood(math.random(-100,1700),math.random(-100,1000))
	end
end

function sliderOutputs()
	--control forces
	if #objects.sliders > 0 then
		for i = 1, #objects.sliders do
			objects.sliders[i].body:applyAngularImpulse(objects.sliders[i].brain.outputNodes[2].value)
			local angle = objects.sliders[i].body:getAngle()
			local vector = angle2vector(angle)
			objects.sliders[i].body:applyLinearImpulse(vector.x*(objects.sliders[i].brain.outputNodes[1].value*objects.sliders[i].physicalGenetics.speed),vector.y*(objects.sliders[i].brain.outputNodes[1].value*objects.sliders[i].physicalGenetics.speed))
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
			if objects.sliders[i].stomach >= 5 and objects.sliders[i].energy <= 90 then
				objects.sliders[i].stomach = objects.sliders[i].stomach - 5
				objects.sliders[i].energy = objects.sliders[i].energy + 10
			end
			if math.abs(objects.sliders[i].brain.outputNodes[1].value) > 0 then
				objects.sliders[i].energy = objects.sliders[i].energy - 1
			end
			if math.abs(objects.sliders[i].brain.outputNodes[2].value) > 0 then
				objects.sliders[i].energy = objects.sliders[i].energy - 1
			end
			objects.sliders[i].lifespan = objects.sliders[i].lifespan - 1
			objects.sliders[i].energy = objects.sliders[i].energy - 1
			if objects.sliders[i].energy <= 0 or objects.sliders[i].lifespan <= 0 then
				table.insert(deadboys,objects.sliders[i].ID)
			end
			--lay eggs
			if #objects.sliders + #objects.eggs < 100 then
				if objects.sliders[i].stomach > 50 and objects.sliders[i].energy >= 50 then
					objects.eggs[#objects.eggs+1] = newEgg(objects.sliders[i],objects.sliders[i].body:getX(),objects.sliders[i].body:getY())
					objects.sliders[i].stomach = objects.sliders[i].stomach - 20
					objects.sliders[i].energy = objects.sliders[i].energy - 20
				end
			end
			--update closests
			if #objects.sliders[i].sliderseen > 0 then
				local nearest = getNearestSlider(objects.sliders[i])
				objects.sliders[i].closestSliderDist = distBetweenSliders(objects.sliders[i],nearest)
				objects.sliders[i].closestSliderAngle = angleBetweenSliders(objects.sliders[i],nearest)
			end
			if #objects.sliders[i].foodseen > 0 then
				local nearest = getNearestPellet(objects.sliders[i])
				objects.sliders[i].closestFoodDist = distBetweenSliders(objects.sliders[i],nearest)
				objects.sliders[i].closestFoodAngle = angleBetweenSliders(objects.sliders[i],nearest)
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
				hatchEgg(objects.eggs[i])
			end	
		end
	end
end

function sliderBrainTick()
	if #objects.sliders > 0 then
		for i = 1, #objects.sliders do
			if #objects.sliders[i].brain.hiddenNodes > 0 then
				for j = 1,#objects.sliders[i].brain.hiddenNodes do
					if #objects.sliders[i].brain.hiddenNodes[j].synapses > 0 then
						local synapsevalue = 0
						for k = 1,#objects.sliders[i].brain.hiddenNodes[j].synapses do
							local nodekind, inputNode = getNode(objects.sliders[i].brain,objects.sliders[i].brain.hiddenNodes[j].synapses[k].input)
							synapsevalue = synapsevalue + (inputNode*objects.sliders[i].brain.hiddenNodes[j].synapses[k].value)
						end
						--{"sig","lin","sqr","sin","abs","rel","gau","lat"}
						if objects.sliders[i].brain.hiddenNodes[j].nodetype == "lin" then
							objects.sliders[i].brain.hiddenNodes[j].value = synapsevalue
						elseif objects.sliders[i].brain.hiddenNodes[j].nodetype == "sig" then
							objects.sliders[i].brain.hiddenNodes[j].value = synapsevalue/math.sqrt((1+(synapsevalue)^2))
						elseif objects.sliders[i].brain.hiddenNodes[j].nodetype == "sqr" then
							objects.sliders[i].brain.hiddenNodes[j].value = synapsevalue^2
						elseif objects.sliders[i].brain.hiddenNodes[j].nodetype == "sin" then
							objects.sliders[i].brain.hiddenNodes[j].value = math.sin(synapsevalue)
						elseif objects.sliders[i].brain.hiddenNodes[j].nodetype == "abs" then
							objects.sliders[i].brain.hiddenNodes[j].value = math.abs(synapsevalue)
						elseif objects.sliders[i].brain.hiddenNodes[j].nodetype == "rel" then
							if synapsevalue < 0 then
								synapsevaluse = 0
							end
							objects.sliders[i].brain.hiddenNodes[j].value = synapsevalue
						elseif objects.sliders[i].brain.hiddenNodes[j].nodetype == "gau" then
							objects.sliders[i].brain.hiddenNodes[j].value = gaussian(synapsevalue, 1)
						elseif objects.sliders[i].brain.hiddenNodes[j].nodetype == "lat" then
							if math.abs(synapsevalue) > 0 then
								synapsevalue = 0
							elseif synapsevalue == 0 then
								objects.sliders[i].brain.hiddenNodes[j].value = synapsevalue
							end
						end
					end
				end
			end
			for j = 1,#objects.sliders[i].brain.outputNodes do
				if #objects.sliders[i].brain.outputNodes[j].synapses > 0 then
					local synapsevalue = 0
					for k = 1,#objects.sliders[i].brain.outputNodes[j].synapses do
						local nodekind, inputNode = getNode(objects.sliders[i].brain,objects.sliders[i].brain.outputNodes[j].synapses[k].input)
						if nodekind == "input" then
							synapsevalue = synapsevalue + (inputNode * objects.sliders[i].brain.outputNodes[j].synapses[k].value)
						else
							synapsevalue = synapsevalue + (inputNode.value * objects.sliders[i].brain.outputNodes[j].synapses[k].value)
						end
					end
					objects.sliders[i].brain.outputNodes[j].value = synapsevalue
				end
			end
		end
	end
end

function seedSliders()
  local num = #objects.sliders + 1
  objects.sliders[num] = newSlider(slidersEver+1, math.random(100,1000), math.random(100,800))
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
				for j = 1,#objects.sliders do
					if objects.sliders[j].ID == slidnum then
						local needed = 100 - objects.sliders[j].stomach
						local bite = 0
						if needed > objects.food[i].total then
							bite = objects.food[i].total
							totalfood = totalfood - 1
							table.insert(deadpellets,objects.food[i].ID)
						else
							bite = needed
						end
						objects.sliders[j].stomach = objects.sliders[j].stomach + bite
						objects.food[i].total = objects.food[i].total - bite
						break
					end
				end
				break
			end
		end
	end
	if a:isSensor() then
		local slidbod = a:getBody()
		local thingbod = b:getBody()
		local thing = {}
		local slid = {}
		for i=1,#objects.sliders do
			if slidbod:getUserData() == objects.sliders[i].ID then
				slid = objects.sliders[i]
				break
			end
		end
		if b:getUserData() ~= "Sensor" then
			if b:getUserData() == "Pellet" then
				for i=1,#objects.food do
					if thingbod:getUserData() == objects.food[i].ID then
						thing = objects.food[i]
						local have = 0
						if #slid.foodseen > 0 then
							for i=1,#slid.foodseen do
								if i == thing then
									have = 1
								end
							end
							if have == 0 then
								table.insert(slid.foodseen,thing)
							end
						else
							table.insert(slid.foodseen,thing)
						end
						break
					end
				end
			elseif b:getUserData() == "Slider" then
				for i=1,#objects.sliders do
					if (thingbod:getUserData() == objects.sliders[i].ID) and (thingbod:getUserData() ~= slid.ID) then
						thing = objects.sliders[i]
						local have = 0
						if #slid.sliderseen > 0 then
							for i=1,#slid.sliderseen do
								if i == thing then
									have = 1
								end
							end
							if have == 0 then
								table.insert(slid.sliderseen,thing)
							end
						else
							table.insert(slid.sliderseen,thing)
						end
						break
					end
				end
			end
		end
	end
end
 
function endContact(a, b, coll)
	if a:isSensor() then
		local slidbod = a:getBody()
		local thingbod = b:getBody()
		local thing = nil
		local slid = nil
		for i=1,#objects.sliders do
			if slidbod:getUserData() == objects.sliders[i].ID then
				slid = objects.sliders[i]
				break
			end
		end
		if b:getUserData() ~= "Sensor" then
			if b:getUserData() == "Pellet" then
				for i=1,#objects.food do
					if thingbod:getUserData() == objects.food[i].ID then
						thing = objects.food[i]
						for i = 1,#slid.foodseen do
							if slid.foodseen[i] == thing then
								table.remove(slid.foodseen,i)
							end
						end
						break
					end
				end
			elseif b:getUserData() == "Slider" then
				for i=1,#objects.sliders do
					if thingbod:getUserData() == objects.sliders[i].ID then
						thing = objects.sliders[i]
						for i = 1,#slid.sliderseen do
							if slid.sliderseen[i] == thing then
								table.remove(slid.sliderseen,i)
							end
						end
						break
					end
				end
			end
		end
	end
end
 
function preSolve(a, b, coll)
 
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
 
end

--Table Copying
function deepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function getNearestSlider(slider)
	local closest = 0
	local closestResult = {}
	for i = 1, #slider.sliderseen do
		local otherslidX = slider.sliderseen[i].body:getX()
		local otherslidY = slider.sliderseen[i].body:getY()
		local slidX = slider.body:getX()
		local slidY = slider.body:getY()
		if closest == 0 then
			closest = coordDistance(slidX,slidY,otherslidX,otherslidY)
			closestResult = slider.sliderseen[i]
		else
			if coordDistance(slidX,slidY,otherslidX,otherslidY) < closest then
				closest = coordDistance(slidX,slidY,otherslidX,otherslidY)
				closestResult = slider.sliderseen[i]
			end
		end
	end
	return closestResult
end

function getNearestPellet(slider)
	local closest = 0
	local closestResult = {}
	for i = 1, #slider.foodseen do
		local otherslidX = slider.foodseen[i].body:getX()
		local otherslidY = slider.foodseen[i].body:getY()
		local slidX = slider.body:getX()
		local slidY = slider.body:getY()
		if closest == 0 then
			closest = coordDistance(slidX,slidY,otherslidX,otherslidY)
			closestResult = slider.foodseen[i]
		else
			if coordDistance(slidX,slidY,otherslidX,otherslidY) < closest then
				closest = coordDistance(slidX,slidY,otherslidX,otherslidY)
				closestResult = slider.foodseen[i]
			end
		end
	end
	return closestResult
end

--returns the type of node and the node itself
function getNode(brain,nodeID)
	--hidden nodes are always numbered higher than the number of inputs
	if nodeID <= #brain.inputs then
		-- solve for regular input
		return "input", brain.inputs[nodeID]
	else
		-- solve for hidden node
		for i = 1,#brain.hiddenNodes do
			if brain.hiddenNodes[i].ID == nodeID then
				return "hidden", brain.hiddenNodes[i]
			end
		end
	end
end

function addTables(t1,t2)
	local t3 = {}
    for i=1,#t1 do
        t3[i] = t1[i]
    end
	for i=1,#t2 do
        t3[#t3+1] = t2[i]
    end
    return t3
end


function distBetweenSliders(slidMain,slidTarget)
	local otherslidX = slidTarget.body:getX()
	local otherslidY = slidTarget.body:getY()
	local slidX = slidMain.body:getX()
	local slidY = slidMain.body:getY()
	return coordDistance(slidX,slidY,otherslidX,otherslidY)
end

function angleBetweenSliders(slidMain,slidTarget)
	local otherslidX = slidTarget.body:getX()
	local otherslidY = slidTarget.body:getY()
	local slidX = slidMain.body:getX()
	local slidY = slidMain.body:getY()
	return coordAngle(slidX,slidY,otherslidX,otherslidY)
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

--distance between two points
function coordDistance(ax,ay,bx,by)
	local distance = math.sqrt(((bx - ax)^2)-((by - ay)^2))
	return distance
end

function coordAngle(ax,ay,bx,by)
	local angle = math.atan2((ay - by),(ax - bx))
	return angle
end

function gaussian(mean, variance)
    return  math.sqrt(-2 * variance * math.log(math.random()))*math.cos(2 * math.pi * math.random()) + mean
end