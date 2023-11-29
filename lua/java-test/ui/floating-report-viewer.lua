local class = require('java-core.utils.class')
local StringBuilder = require('java-test.utils.string-builder')
local TestExecutionStatus = require('java-test.results.test-execution-status')
local TestStatus = require('java-test.results.test-status')

---@class java_test.FloatingReportViewer
---@field window number|nil
---@field buffer number|nil
---@overload fun(): java_test.FloatingReportViewer
local FloatingReportViewer = class()

---Shows the test results in a floating window
---@param test_results java_test.TestResults[]
function FloatingReportViewer:show(test_results)
	---@param results java_test.TestResults[]
	local function build_result(results, indentation, prefix)
		local ts = StringBuilder()

		for _, result in ipairs(results) do
			local tc = StringBuilder()

			tc.append(prefix .. indentation)

			if result.is_suite then
				tc.append('📁 ' .. result.test_name).lbreak()
			else
				if result.result.status == TestStatus.Failed then
					tc.append('❌' .. result.test_name)
						.lbreak()
						.append(indentation)
						.append(result.result.trace, indentation)
				elseif result.result.status == TestStatus.Skipped then
					tc.append('⚠ ' .. result.test_name).lbreak()
				else
					tc.append('✅' .. result.test_name).lbreak()
				end
			end

			if result.children then
				tc.append(build_result(result.children, indentation .. '\t', ''))
			end

			ts.append(tc.build())
		end

		return ts.build()
	end

	local res = build_result(test_results, '', '')

	self:show_in_window(vim.split(res, '\n'))
end

function FloatingReportViewer:show_in_window(content)
	local Popup = require('nui.popup')
	local event = require('nui.utils.autocmd').event

	local popup = Popup({
		enter = true,
		focusable = true,
		border = {
			style = 'rounded',
		},
		position = '50%',
		relative = 'editor',
		size = {
			width = '80%',
			height = '60%',
		},
		buf_options = {
			modifiable = true,
			readonly = true,
		},
		win_options = {
			foldmethod = 'indent',
			foldlevel = 1,
		},
	})

	-- mount/open the component
	popup:mount()

	-- unmount component when cursor leaves buffer
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)

	-- set content
	vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, content)
	vim.api.nvim_buf_set_option(popup.bufnr, 'modifiable', false)
end

return FloatingReportViewer
