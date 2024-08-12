local Scratch = require("alpha4.scratch")
local llm = require("alpha4.llm")
local prompt = require("alpha4.prompt")
local buffer = require("alpha4.buffer")
local chat = require("alpha4.chat")

local api = vim.api

---@class Alpha4
local M = {
	scratch = Scratch:new(),

	opts = {
		default_provider = "ollama",
		providers = {},
		prompts = {},
		keys = {
			{ "<leader>lc", "<CMD>Alpha4ToggleChat<CR>", desc = "Toggle chat" },
			{ "<leader>le", "<CMD>Alpha4Explain<CR>", desc = "Explain" },
			{ "<leader>lr", "<CMD>Alpha4Replace<CR>", desc = "Replace" },
			{ "<leader>ls", "<CMD>Alpha4Suggest<CR>", desc = "Suggest" },
		},
		chat = {
			keys = {
				submit = "<CR>",
			},
		},
		params = {
			chat = {
				temperature = 0.9, -- Higher temperature for more creative and diverse responses in problem-solving
				top_p = 0.95, -- High top_p to allow for a wide range of token choices, promoting diversity
				top_k = 50, -- Moderate top_k to balance between diversity and focus in language
				repetition_penalty = 1.2, -- Higher penalty to discourage repetitive language in open-ended chat
				frequency_penalty = 0.2, -- Moderate penalty to encourage varied vocabulary use
				presence_penalty = 0.2, -- Moderate penalty to encourage exploration of different topics
				max_tokens = 4096,
			},
			replace = {
				temperature = 0.3, -- Lower temperature for more focused and deterministic responses in debugging
				top_p = 0.8, -- Slightly lower top_p to narrow down token choices for precision
				top_k = 20, -- Lower top_k to focus on more probable tokens, reducing noise
				repetition_penalty = 1.05, -- Light penalty to allow necessary repetition of technical terms
				frequency_penalty = 0.1, -- Lower penalty to permit use of specific debugging terminology
				presence_penalty = 0.1, -- Lower penalty to allow focus on the debugging topic at hand
				max_tokens = 4096,
			},
			suggest = {
				temperature = 0.2, -- Low temperature for more predictable and consistent code suggestions
				top_p = 0.7, -- Lower top_p to focus on the most probable tokens for code completion
				top_k = 10, -- Low top_k to prioritize the most likely code continuations
				repetition_penalty = 1.0, -- Minimal penalty to allow for necessary code pattern repetition
				frequency_penalty = 0.05, -- Very low penalty to permit common coding patterns and syntax
				presence_penalty = 0.05, -- Very low penalty to maintain focus on the current code context
				max_tokens = 4096,
			},
			explain = {
				temperature = 0.5, -- Moderate temperature to balance clarity with flexibility in explanations
				top_p = 0.9, -- High top_p to allow for varied language in explanations
				top_k = 35, -- Moderate top_k to provide diverse yet relevant explanations
				repetition_penalty = 1.1, -- Moderate penalty to encourage varied language while allowing some repetition for clarity
				frequency_penalty = 0.2, -- Moderate penalty to encourage use of diverse terms in explanations
				presence_penalty = 0.2, -- Moderate penalty to allow exploration of related concepts when explaining
				max_tokens = 4096,
			},
		},
	},
}

function M.setup(opts)
	opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	api.nvim_create_user_command("Alpha4Replace", "lua require('alpha4').replace()", { nargs = 0 })
	api.nvim_create_user_command("Alpha4Explain", "lua require('alpha4').explain()", { nargs = 0 })
	api.nvim_create_user_command("Alpha4Suggest", "lua require('alpha4').suggest()", { nargs = 0 })
	api.nvim_create_user_command("Alpha4ToggleChat", "lua require('alpha4').toggle_chat()", { nargs = 0 })

	for _, key in pairs(opts.keys) do
		key.mode = key.mode or { "n", "v" }
		for _, mode in pairs(key.mode) do
			api.nvim_set_keymap(mode, key[1], key[2], {
				noremap = true,
				silent = true,
				desc = key.desc,
			})
		end
	end

	prompt.setup({ templates = opts.prompts })
	llm.setup({
		default_provider = opts.default_provider,
		providers = opts.providers,
	})
	chat.setup({ keys = opts.chat.keys })
end

function M.replace(opts)
	opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	local task = "Follow the TODO and FIXME comments in the <USER:SELECTION> and provide the suggested replacements."
	local system, user = prompt.format("replace", opts.task or task)

	api.nvim_command("normal! d")
	api.nvim_command("normal! O")

	llm.call({
		provider = llm.get_provider(opts.params.replace, opts.provider),
		system = system,
		messages = {
			{ role = "user", content = user },
		},
		on_delta = function(delta)
			buffer.write_string(delta)
		end,
	})

	buffer.normal_mode()
end

function M.suggest(opts)
	opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	local task = "Complete the code snippet in the <USER:SELECTION> by providing the missing parts."
	local system, user = prompt.format("suggest", opts.task or task)

	api.nvim_command("normal! d")
	api.nvim_command("normal! k")

	llm.call({
		provider = llm.get_provider(opts.params.suggest, opts.provider),
		system = system,
		messages = {
			{ role = "user", content = user },
		},
		max_tokens = opts.max_tokens or M.opts.max_tokens,
		on_delta = function(delta)
			buffer.write_string(delta)
		end,
	})

	buffer.normal_mode()
end

function M.explain(opts)
	opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	local system, user = prompt.format("explain", opts.task or "Explain code")

	M.scratch:show("markdown")
	M.scratch:write(string.format("# Explaining Code - %s", os.date("%Y-%m-%d %H:%M:%S")))

	llm.call({
		provider = llm.get_provider(opts.params.chat, opts.provider),
		max_tokens = opts.max_tokens or M.opts.max_tokens,
		system = system,
		messages = {
			{ role = "user", content = user },
		},
		on_delta = function(delta)
			M.scratch:write(delta)
		end,
	})

	buffer.normal_mode()
end

function M.toggle_chat(opts)
	opts = vim.tbl_deep_extend("force", M.opts, {
		params = M.opts.params.chat,
		provider = {},
	}, opts or {})

	chat.toggle({
		provider = llm.get_provider(opts.params.chat, opts.provider),
		system = opts.system,
	})
end

return M
