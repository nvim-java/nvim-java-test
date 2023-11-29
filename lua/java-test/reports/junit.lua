local class = require('java-core.utils.class')
local log = require('java-core.utils.log')

local ReportViewer = require('java-test.ui.floating-report-viewer')

---@class java_test.JUnitTestReport
---@field private conn uv_tcp_t
---@field private test_parser java_test.TestParser
---@field private test_parser_fac java_test.TestParserFactory
---@overload fun(test_parser_factory: java_test.TestParserFactory)
local JUnitReport = class()

---Init
---@param test_parser_factory java_test.TestParserFactory
function JUnitReport:_init(test_parser_factory)
	self.conn = nil
	self.test_parser_fac = test_parser_factory
end

---Returns a stream reader function
---@param conn uv_tcp_t
---@return fun(err: string, buffer: string) # callback function
function JUnitReport:get_stream_reader(conn)
	self.conn = conn
	self.test_parser = self.test_parser_fac:get_parser()

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
function JUnitReport:on_update(text)
	self.test_parser:parse(text)
end

---Runs on connection close
---@private
function JUnitReport:on_close()
	local results = self.test_parser:get_test_details()
	local rv = ReportViewer()
	rv:show(results)
end

---Runs on connection error
---@private
---@param err string error
function JUnitReport:on_error(err)
	log.error('Error while running test', err)
end

return JUnitReport
