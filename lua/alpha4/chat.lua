local llm = require("alpha4.llm")
local Scratch = require("alpha4.scratch")
local prompt = require("alpha4.prompt")

local api = vim.api

local M = {
	turn = "User",
	messages = {},
	scratch = nil,
	opts = {
		provider = {},
		system = prompt.templates.chat.system,
		keys = {
			submit = "<leader><CR>",
		},
	},
}

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	M.scratch = Scratch:new(string.format("alpha4-chat-%s.md", os.date("%Y%m%d%H%M%S")))
	api.nvim_buf_set_keymap(
		M.scratch.bufnr,
		"n",
		M.opts.keys.submit,
		":lua require('alpha4.chat').submit()<CR>",
		{ noremap = true, silent = true }
	)
end

-- TODO: load documents to the chat context
function M.load_documents(file_path)
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

function M.write_message(speaker, turn, content)
	local last_line = M.scratch:last_line()
	if last_line and last_line:len() > 0 then
		M.scratch:append("\n")
	end

	M.scratch:write(string.format("[%s] [#%d]:%s", speaker, turn, content))
end

function M.parse_messages()
	M.messages = {}
	local text = M.scratch:get_text()
	local pattern = "%[([%w]+)%]%s%[#(%d+)%]:[%s\n]*(.*)"

	for speaker, turn, content in text:gmatch(pattern) do
		table.insert(M.messages, { speaker, turn, content })
	end

	local last_index = #M.messages
	if last_index > 0 and vim.trim(M.messages[last_index][3]):len() == 0 then
		table.remove(M.messages, last_index)
	end
end

function M.redraw(opts)
	M.scratch:clear()
	M.scratch:show("markdown")
	M.scratch:write("# Chat with Alpha4\n")
	M.scratch:append("Provider:\n")
	for k, v in pairs(opts.provider) do
		if not string.match(k, "api_key") then
			M.scratch:append(string.format("\t%s: %s", k, v))
		end
	end
	M.scratch:append("\n---\n\n")

	for _, m in pairs(M.messages) do
		M.write_message(m[1], m[2], "\n\n" .. m[3])
		if m[2] == "Alpha4" then
			M.scratch:append("\n---\n\n")
		end
	end

	if #M.messages == 0 then
		M.write_message("User", 1, "\n\n")
	end
end

function M.format_messages()
	local messages = {}
	for _, m in pairs(M.messages) do
		table.insert(messages, {
			content = m[3],
			role = m[1] == "Alpha4" and "assistant" or "user",
		})
	end
	return messages
end

function M.toggle(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	if M.scratch:is_focused() then
		M.scratch:hide()
	else
		M.scratch:show("markdown")
		M.redraw(opts)
		M.parse_messages()
	end
end

function M.is_open()
	return M.scratch:is_focused()
end

function M.submit()
	local opts = M.opts
	M.parse_messages()
	M.redraw(opts)

	if #M.messages == 0 then
		vim.notify("No message to send", vim.log.levels.WARN, { title = "Alpha4" })
		return
	end

	local last_message = M.messages[#M.messages]
	if vim.trim(last_message[3]):len() == 0 or last_message[1] == "Alpha4" then
		vim.notify("Please enter a message", vim.log.levels.WARN, { title = "Alpha4" })
		return
	end

	M.write_message("Alpha4", #M.messages + 1, "\n")

	llm.call({
		provider = opts.provider,
		system = opts.system,
		messages = M.format_messages(),
		max_tokens = opts.max_tokens,
		on_delta = function(delta)
			M.scratch:write(delta)
		end,
		on_end = function(code)
			if code ~= 0 then
				M.scratch:write("\n\n❗ERROR❗Something went wrong.")
				return
			end
			M.scratch:write("\n")
			M.parse_messages()
			M.redraw(opts)
			M.write_message("User", #M.messages + 2, "\n\n")
		end,
	})
end

return M
