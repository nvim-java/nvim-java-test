local class = require('java-core.utils.class')
local MessageId = require('java-test.results.message-id')
local TestStatus = require('java-test.results.test-status')

---@class java_test.TestParser
local TestParser = class()

function TestParser:_init()
	self.test_details = {}
end

function TestParser:parse(text)
	local lines = vim.split(text, '\n', {
		plain = true,
		trimempty = true,
	})

	for _, line in ipairs(lines) do
		self:parse_line(line)
	end
end

function TestParser:parse_line(line)
	local message_id = line:sub(1, 8):gsub('%s+', '')
	local content = line:sub(9)

	local node_parser = TestParser.node_parsers[message_id]

	if node_parser then
		local data = vim.split(content, ',', { plain = true, trimempty = true })
		if self[TestParser.node_parsers[message_id]] then
			self[TestParser.node_parsers[message_id]](self, data)
		end
	end
end

function TestParser:parse_test_tree(data)
	local node = {
		test_id = tonumber(data[1]),
		test_name = data[2],
		is_suite = data[3],
		test_count = tonumber(data[4]),
		is_dynamic_test = data[5],
		parent_id = tonumber(data[6]),
		display_name = data[7],
		parameter_types = data[8],
		unique_id = data[9],
	}

	local parent = self:find_result_node(node.parent_id)

	if not parent then
		table.insert(self.test_details, node)
	else
		parent.children = parent.children or {}
		table.insert(parent.children, node)
	end
end

function TestParser:find_result_node(id)
	local function find_node(nodes)
		if not nodes or #nodes == 0 then
			return
		end

		for _, node in ipairs(nodes) do
			if node.test_id == id then
				return node
			end

			local _node = find_node(node.children)

			if _node then
				return _node
			end
		end
	end

	return find_node(self.test_details)
end

function TestParser:parse_test_start(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.status = TestStatus.Started
end

function TestParser:parse_test_end(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.status = TestStatus.Ended
end

TestParser.node_parsers = {
	[MessageId.TestTree] = 'parse_test_tree',
	[MessageId.TestStart] = 'parse_test_start',
	[MessageId.TestEnd] = 'parse_test_end',
}

return TestParser
