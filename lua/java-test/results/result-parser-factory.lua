local class = require('java-core.utils.class')
local TestParser = require('java-test.results.result-parser')

---@class java_test.TestParserFactory
local TestParserFactory = class()

---Returns a test parser of given type
---@param args any
---@return java_test.TestParser
function TestParserFactory.get_parser(args)
	return TestParser()
end

return TestParserFactory
