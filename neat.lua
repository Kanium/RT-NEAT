--Slider Neural Net
--[[
nodes have a synapse-in list, and a value
synapses have an input value(from a node) and synapse value(their multiplier)

Input nodes always have updating values.
Hidden nodes are solved first (iterating through their synapse list)
Output nodes are solved last (iterating through their synapse list)

--]]

synapsesEver = 0

function newNode(brain,nodetype)
	local node = {}
	node.synapses = {}
	node.value = 0
	node.nodetype = nodetype
	node.ID = brain.nodesEver+1
	brain.nodesEver = brain.nodesEver+1
	return node
end

function newBrain()
	local sampleBrain = {}
	sampleBrain.inputs = {}
	sampleBrain.hiddenNodes = {}
	sampleBrain.outputNodes = {}
	sampleBrain.synapseNum = 0
	sampleBrain.nodesEver = 11
	return sampleBrain
end

function newSynapse(input,value)
	local sampleSynapse = {}
	sampleSynapse.input = input
	sampleSynapse.value = value
	sampleSynapse.ID = synapsesEver +1
	synapsesEver = synapsesEver + 1
	return sampleSynapse
end