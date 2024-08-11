local M = {}

local api = vim.api
local diagnostic = vim.diagnostic

function M.get_diagnostics()
	local items = diagnostic.get(api.nvim_get_current_buf())
	local messages = {}
	for _, d in ipairs(items) do
		table.insert(messages, string.format("Line %d: %s", d.lnum + 1, d.message))
	end

	return messages
end

return M
