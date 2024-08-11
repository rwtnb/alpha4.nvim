local Job = require("plenary.job")

local api = vim.api

local M = {
	---@type Job|nil
	job = nil,

	opts = {
		default_provider = "ollama",

		providers = {
			ollama = {
				url = "http://localhost:11434/api/chat",
				model = "llama3.1",
				temperature = 0.3,
				top_p = 0.9,
				top_k = 40,
				max_tokens = 4096,
			},
			groq = {
				url = "https://api.groq.com/openai/v1/chat/completions",
				model = "llama-3.1-70b-versatile",
				api_key_name = "GROQ_API_KEY",
				api_key = nil,
				temperature = 0.3,
				top_p = 0.9,
				top_k = 40,
				max_tokens = 4096,
			},
			togetherai = {
				url = "https://api.togetherai.co/v1/chat/completions",
				model = "gpt-4o",
				api_key_name = "TOGETHERAI_API_KEY",
				api_key = nil,
				temperature = 0.3,
				top_p = 0.9,
				top_k = 40,
				max_tokens = 4096,
			},
			openrouter = {
				url = "https://api.openrouter.io/v1/chat/completions",
				model = "gpt-4o",
				api_key_name = "OPENROUTER_API_KEY",
				api_key = nil,
				temperature = 0.3,
				top_p = 0.9,
				top_k = 40,
				max_tokens = 4096,
			},
			anthropic = {
				url = "https://api.anthropic.com/v1/messages",
				model = "claude-3-5-sonnet-20240620",
				api_key_name = "ANTHROPIC_API_KEY",
				api_key = nil,
				temperature = 0.3,
				top_p = 0.9,
				top_k = 40,
				max_tokens = 4096,
			},
			openai = {
				url = "https://api.openai.com/v1/chat/completions",
				model = "gpt-4o",
				api_key_name = "OPENAI_API_KEY",
				api_key = nil,
				temperature = 0.3,
				top_p = 0.9,
				top_k = 40,
				max_tokens = 4096,
			},
		},
	},
}

local function get_api_key(name)
	local val = vim.fn.getenv(name)

	if not val or val == "" then
		api.nvim_err_writeln("environment variable not found: " .. name)
		return nil
	end

	return val
end

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	for name, po in pairs(M.opts.providers) do
		po.name = name
		if po.api_key_name then
			if M.opts.default_provider == po.name then
				po.api_key = get_api_key(po.api_key_name)
			else
				po.api_key = pcall(get_api_key, po.api_key_name)
			end
		end
	end
end

function M.get_provider(params, provider)
	provider = provider or M.opts.providers[M.opts.default_provider]
	return vim.tbl_deep_extend("force", M.opts.providers[M.opts.default_provider], provider, params or {})
end

local function on_delta(provider, data, callback)
	local json = data:match("^data: (.+)$")
	if not json then
		return
	end
	if json == "[DONE]" then
		return
	end

	local ok, parsed_data = pcall(vim.json.decode, json)
	if not ok then
		api.nvim_err_writeln("Error decoding JSON: " .. parsed_data)
		return
	end

	local delta
	if provider == "anthropic" then
		delta = parsed_data.delta and parsed_data.delta.text
	else
		delta = parsed_data.choices
			and parsed_data.choices[1]
			and parsed_data.choices[1].delta
			and parsed_data.choices[1].delta.content
	end

	if delta and delta ~= vim.NIL then
		callback(delta)
	end
end

local function ollama_request(opts, request)
	local provider = opts.provider
	local system = opts.system

	table.insert(request.body.messages, 1, { role = "system", content = system })
	table.insert(request.body.messages, { role = "assistant", content = "<OUTPUT>" })

	return vim.tbl_deep_extend("force", request, {
		body = {
			options = {
				temperature = opts.temperature or provider.temperature,
				top_p = opts.top_p or provider.top_p,
				top_k = opts.top_k or provider.top_k,
				repeat_penalty = opts.presence_penalty or provider.presence_penalty,
				stop = { "</OUTPUT>" },
			},
		},
	})
end

local function anthropic_request(opts, request)
	table.insert(request.body.messages, { role = "assistant", content = "<OUTPUT>" })

	return vim.tbl_deep_extend("force", request, {
		headers = {
			["x-api-key"] = opts.provider.api_key,
			["anthropic-version"] = "2023-06-01",
		},
		body = {
			system = opts.system,
			temperature = opts.temperature or opts.provider.temperature,
			top_p = opts.top_p or opts.provider.top_p,
			top_k = opts.top_k or opts.provider.top_k,
			stop_sequences = { "</OUTPUT>" },
			max_tokens = opts.max_tokens or opts.provider.max_tokens,
		},
	})
end

local function generic_request(opts, request)
	local provider = opts.provider
	local system = opts.system

	table.insert(request.body.messages, 1, { role = "system", content = system })
	table.insert(request.body.messages, { role = "assistant", content = "<OUTPUT>" })

	return vim.tbl_deep_extend("force", request, {
		headers = {
			["Authorization"] = "Bearer " .. provider.api_key,
			["HTTP-Referer"] = "https://github.com/rwtnb/alpha4.nvim",
			["X-Title"] = "alpha4.nvim",
		},
		body = {
			temperature = opts.temperature or provider.temperature,
			top_p = opts.top_p or provider.top_p,
			presence_penalty = opts.presence_penalty or provider.presence_penalty,
			frequency_penalty = opts.frequency_penalty or provider.frequency_penalty,
			stop = { "</OUTPUT>" },
			max_tokens = opts.max_tokens or provider.max_tokens,
		},
	})
end

function M.call(opts)
	opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	local request = {
		url = opts.provider.url,
		headers = {
			["Content-Type"] = "application/json",
		},
		body = {
			model = opts.provider.model,
			stream = true,
			messages = opts.messages,
		},
	}

	if opts.provider.name == "ollama" then
		request = ollama_request(opts, request)
	elseif opts.provider.name == "anthropic" then
		request = anthropic_request(opts, request)
	else
		request = generic_request(opts, request)
	end

	return M.do_request(opts, request)
end

function M.do_request(opts, request)
	local provider = opts.provider

	local args = {
		"-N",
		"--fail",
		provider.url,
	}

	for key, value in pairs(request.headers) do
		table.insert(args, "-H")
		table.insert(args, key .. ": " .. value)
	end

	table.insert(args, "-d")
	table.insert(args, vim.fn.json_encode(request.body))

	if M.job then
		M.job:shutdown()
		M.job = nil
	end

	M.job = Job:new({
		command = "curl",
		args = args,
		on_stdout = function(_, data)
			on_delta(opts.provider.name, data, vim.schedule_wrap(opts.on_delta))
		end,
		on_stderr = function(_, _) end,
		on_exit = vim.schedule_wrap(function(_, code)
			if code ~= 0 then
				print("Call to " .. opts.provider.name .. " failed with code " .. code)
			end

			if opts.on_end then
				opts.on_end(code)
			end
		end),
	}):start()
end

return M
