local api = vim.api

---@class Scratch
---@field winid number
---@field bufnr number
---@field ft string
---@field lines table
local Scratch = {}

--- Create a new scratch buffer
--- @param name string|nil
--- @return Scratch
function Scratch:new(name)
	local instance = {
		winid = nil,
		bufnr = api.nvim_create_buf(false, true),
		lines = {},
	}

	if name then
		api.nvim_buf_set_name(instance.bufnr, name)
	end

	setmetatable(instance, self)
	self.__index = self
	return instance
end

---Open the scratch buffer
---@param ft string
---@return number
function Scratch:show(ft)
	if not self.winid then
		self.winid = api.nvim_open_win(self.bufnr, true, { split = "right", win = -1 })
	end

	local is_buf_valid = self.bufnr ~= nil and api.nvim_buf_is_valid(self.bufnr)
	local is_win_valid = self.winid ~= nil and api.nvim_win_is_valid(self.winid)
	local is_valid = is_buf_valid and is_win_valid

	local is_win_current = self.winid == api.nvim_get_current_win()
	local is_buf_current = self.bufnr == api.nvim_get_current_buf()

	-- focus the buffer if it's already open
	if is_valid and not is_win_current then
		api.nvim_set_current_win(self.winid)
	elseif is_valid and not is_buf_current then
		api.nvim_set_current_buf(self.bufnr)
	elseif not is_valid then
		-- create the buffer if it's doesn't exist
		self.bufnr = api.nvim_create_buf(false, true)
		self.winid = api.nvim_get_current_win()
		api.nvim_win_set_buf(self.winid, self.bufnr)
	end

	api.nvim_set_option_value("filetype", ft or self.ft, { buf = self.bufnr })
	return self.bufnr
end

function Scratch:write(str)
	local cl = self:get_lines()
	local last = cl[#cl] .. str

	if last:match("\n") then
		local lines = vim.split(last, "\n")
		api.nvim_buf_set_lines(self.bufnr, #cl - 1, -1, false, lines)
		self:update_cursor()
		return
	end

	api.nvim_buf_set_lines(self.bufnr, #cl - 1, -1, false, { last })
	self:update_cursor()
end

function Scratch:append(lines)
	local cl = self:get_lines()
	api.nvim_buf_set_lines(self.bufnr, #cl, -1, false, vim.split(lines, "\n"))
	self:update_cursor()
end

function Scratch:update_cursor()
	local lines = self:get_lines()
	local count = #lines
	api.nvim_win_set_cursor(self.winid, { #lines, lines[count]:len() })
end

function Scratch:clear()
	api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})
end

function Scratch:get_lines()
	return api.nvim_buf_get_lines(0, 0, -1, false)
end

function Scratch:last_line()
	return api.nvim_buf_get_lines(self.bufnr, -2, -1, false)[1]
end

function Scratch:is_focused()
	return self.bufnr == api.nvim_get_current_buf()
end

function Scratch:get_text()
	return table.concat(self:get_lines(), "\n")
end

function Scratch:hide()
	api.nvim_win_hide(self.winid)
	self.winid = nil
end

return Scratch
