local M = {}

function M.normal_mode()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, true, true), "nx", false)
end

function M.write_string(str)
	local lines = vim.split(str, "\n")
	vim.api.nvim_put(lines, "c", true, true)
end

function M.current_path()
	local bufnr = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(bufnr)
	local cwd = vim.fn.getcwd()
	return vim.fn.fnamemodify(name, ":." .. cwd .. ":")
end

function M.selection()
	local start_mark, end_mark
	start_mark = "v"
	end_mark = "."
	local _, srow, scol = unpack(vim.fn.getpos(start_mark))
	local _, erow, ecol = unpack(vim.fn.getpos(end_mark))

	-- visual line mode
	if vim.fn.mode() == "V" then
		if srow > erow then
			return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
		else
			return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
		end
	end

	-- regular visual mode
	if vim.fn.mode() == "v" then
		if srow < erow or (srow == erow and scol <= ecol) then
			return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
		else
			return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
		end
	end

	-- visual block mode
	if vim.fn.mode() == "\22" then
		local lines = {}
		if srow > erow then
			srow, erow = erow, srow
		end
		if scol > ecol then
			scol, ecol = ecol, scol
		end
		for i = srow, erow do
			table.insert(
				lines,
				vim.api.nvim_buf_get_text(0, i - 1, math.min(scol - 1, ecol), i - 1, math.max(scol - 1, ecol), {})[1]
			)
		end
		return lines
	end
end

function M.lines(opts)
	local current_buffer = vim.api.nvim_get_current_buf()
	local current_window = vim.api.nvim_get_current_win()
	local cursor_position = vim.api.nvim_win_get_cursor(current_window)
	local row
	if opts.all then
		row = -1
	else
		row = cursor_position[1]
	end

	local all_lines = vim.api.nvim_buf_get_lines(current_buffer, 0, row, true)
	local lines = {}
	local file_contents = ""

	for _, line in ipairs(all_lines) do
		local file_path = line:match("^@(.+)$")
		if file_path then
			file_contents = file_contents .. M.file_contents(file_path)
		else
			table.insert(lines, line)
		end
	end

	local relative_path = M.current_path()
	local header = string.format('<File path="%s">\n', relative_path)
	table.insert(lines, 1, header)

	return file_contents .. table.concat(lines, "\n") .. "\n</File>"
end

function M.file_contents(file_path)
	local cwd = vim.fn.getcwd()
	local contents = ""

	if file_path then
		local full_path
		if file_path:sub(1, 1) == "/" then
			full_path = file_path
		elseif file_path:sub(1, 2) == "~/" then
			full_path = os.getenv("HOME") .. file_path:sub(2)
		elseif file_path:sub(1, 2) == "./" then
			full_path = cwd .. file_path:sub(2)
		else
			full_path = cwd .. "/" .. file_path
		end
		local file = io.open(full_path, "r")
		if file then
			local content = file:read("*all")
			file:close()

			local relative_path = vim.fn.fnamemodify(full_path, ":." .. cwd .. ":")
			contents = string.format('\n\n<File path="%s">\n%s\n</File>', relative_path, content)
		else
			vim.notify("Cannot open file: " .. full_path, vim.log.levels.WARN, { title = "Alpha4" })
		end
	end

	return contents
end

return M
