--Slider Neural Net
--[[
nodes have a synapse-in list, and a value
synapses have an input value(from a node) and synapse value(their multiplier)

Input nodes always have updating values.
Hidden nodes are solved first (iterating through their synapse list)
Output nodes are solved last (iterating through their synapse list)

--]]
nodesEver = 0
synapsesEver = 0

function newNode(nodetype)
	local node = {}
	node.synapses = {}
	node.value = 0
	node.type = nodetype
	node.ID = nodesEver+1
	nodesEver = nodesEver+1
	return node
end

function newBrain()
	local sampleBrain = {}
	sampleBrain.inputs = {}
	sampleBrain.hiddenNodes = {}
	sampleBrain.outputNodes = {}
	return sampleBrain
end

function newSynapse(input,value)
	local sampleSynapse = {}
	sampleSynapse.input = 0
	sampleSynapse.value = 0
	sampleSynapse.ID = synapsesEver +1
	synapsesEver = synapsesEver + 1
	return samplesynapse
end