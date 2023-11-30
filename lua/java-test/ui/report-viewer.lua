local class = require('java-core.utils.class')

---@class java_test.ReportViewer
local ReportViewer = class()

---Shows the test results in a floating window
---@param _ java_test.TestResults[]
function ReportViewer:show(_)
	error('not implemented')
end

return ReportViewer
