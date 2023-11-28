local class = require('java-core.utils.class')
local str_util = require('java-test.utils.str')

local MessageId = require('java-test.results.message-id')
local TestStatus = require('java-test.results.test-status')
local TestExecStatus = require('java-test.results.test-execution-status')

---@class java_test.TestParser
---@field private test_details java_test.TestDetails
local TestParser = class()

---Init
---@private
function TestParser:_init()
	self.test_details = {}
end

---@private
TestParser.node_parsers = {
	[MessageId.TestTree] = 'parse_test_tree',
	[MessageId.TestStart] = 'parse_test_start',
	[MessageId.TestEnd] = 'parse_test_end',
	[MessageId.TestFailed] = 'parse_test_failed',
}

---Returns the parsed test details
---@return java_test.TestDetails # parsed test details
function TestParser:get_test_details()
	return self.test_details
end

---Parse a given text into test details
---@param text string test result buffer
function TestParser:parse(text)
	if text:sub(-1) ~= '\n' then
		text = text .. '\n'
	end

	local line_iter = text:gmatch('(.-)\n')

	local line = line_iter()

	while line ~= nil do
		local message_id = line:sub(1, 8):gsub('%s+', '')
		local content = line:sub(9)

		local node_parser = TestParser.node_parsers[message_id]

		if node_parser then
			local data = vim.split(content, ',', { plain = true, trimempty = true })

			if self[TestParser.node_parsers[message_id]] then
				self[TestParser.node_parsers[message_id]](self, data, line_iter)
			end
		end

		line = line_iter()
	end
end

---@private
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

---@private
function TestParser:parse_test_start(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.result = {}
	node.result.execution = TestExecStatus.Started
end

---@private
function TestParser:parse_test_end(data)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)
	node.result.execution = TestExecStatus.Ended
end

---@private
function TestParser:parse_test_failed(data, line_iter)
	local test_id = tonumber(data[1])
	local node = self:find_result_node(test_id)
	assert(node)

	node.result.status = TestStatus.Failed

	while true do
		local line = line_iter()

		if line == nil then
			break
		end

		-- EXPECTED
		if str_util.starts_with(line, MessageId.ExpectStart) then
			node.result.expected =
				self:get_content_until_end_tag(MessageId.ExpectEnd, line_iter)

		-- ACTUAL
		elseif str_util.starts_with(line, MessageId.ActualStart) then
			node.result.actual =
				self:get_content_until_end_tag(MessageId.ActualEnd, line_iter)

		-- TRACE
		elseif str_util.starts_with(line, MessageId.TraceStart) then
			node.result.trace =
				self:get_content_until_end_tag(MessageId.TraceEnd, line_iter)
		end
	end
end

function TestParser:get_content_until_end_tag(end_tag, line_iter)
	local content = {}

	while true do
		local line = line_iter()

		if line == nil or str_util.starts_with(line, end_tag) then
			break
		end

		table.insert(content, line)
	end

	return content
end

---@private
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

return TestParser
