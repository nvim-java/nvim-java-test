local class = require('java-core.utils.class')
local log = require('java-core.utils.log')

local TestParser = require('java-test.results.test-parser')

---@class java_test.DapTestReport
---@field private conn uv_tcp_t
---@field private test_parser java_test.TestParser
local TestReport = class()

function TestReport:_init()
	self.conn = nil
	self.test_parser = TestParser()
end

---Returns a stream reader function
---@param conn uv_tcp_t
---@return fun(err: string, buffer: string) # callback function
function TestReport:get_stream_reader(conn)
	self.conn = conn

	return vim.schedule_wrap(function(err, buffer)
		if err then
			self:on_error(err)
			self:on_close()
			self.conn:close()
			return
		end

		if buffer then
			self:on_update(buffer)
		else
			self:on_close()
			self.conn:close()
		end
	end)
end

---Runs on connection update
---@private
---@param text string
function TestReport:on_update(text)
	self.test_parser:parse(text)
end

---Runs on connection close
---@private
function TestReport:on_close()
	vim.print('closing')
end

---Runs on connection error
---@private
---@param err string error
function TestReport:on_error(err)
	log.error('Error while running test', err)
end

return TestReport
