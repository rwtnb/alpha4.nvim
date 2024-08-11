# Alpha4

Alpha4 is an AI-powered programming assistant for Neovim. It enhances your coding experience with intelligent suggestions, explanations, and interactive assistance.

## Features

- Code analysis and improvement suggestions
- Interactive problem-solving
- Code generation and completion
- Dedicated chat interface for extended discussions

https://github.com/user-attachments/assets/d602c512-1de1-426e-b6aa-86e0c214245c

## Installation

### Using LazyVim

1. Ensure you have Neovim (0.8 or later) and [LazyVim](https://www.lazyvim.org/) installed.

2. Add the following to your LazyVim configuration file (usually `~/.config/nvim/lua/plugins/alpha4.lua`):

   ```lua
   return {
     {
       "rwtnb/alpha4.nvim",
       dependencies = {
         "nvim-lua/plenary.nvim",
       },
     },
   }
   ```

3. Restart Neovim or run `:Lazy sync` to install Alpha4.

4. If you're using Ollama (the default provider), make sure it's installed and running. Visit [Ollama's website](https://ollama.ai/) for installation instructions.

## Usage

Alpha4 provides several commands for easy access:

1. Open the chat interface:
   - Press `<leader>lc` in normal mode
   - Or run the command `:Alpha4ToggleChat`

2. Explain selected code:
   - Select code in visual mode, then press `<leader>le`
   - Or run the command `:Alpha4Explain`

3. Replace selected code with improvements:
   - Select code in visual mode, then press `<leader>lr`
   - Or run the command `:Alpha4Replace`

4. Get code suggestions:
   - Select code in visual mode, then press `<leader>ls`
   - Or run the command `:Alpha4Suggest`

### Chat Interface

1. When the chat interface opens, type your message at the bottom of the window.
2. Press `<leader><CR>` to send your message (default key binding).
3. Alpha4 will respond in the chat window.
4. Continue the conversation as needed.
5. To close the chat, press `<leader>lc` again or use your normal Neovim window closing command (e.g., `:q`).

## Configuration

You can customize Alpha4 by passing options to the `setup` function. Here's a detailed explanation of each configuration option:

```lua
require('alpha4').setup({
  -- The default AI provider to use
  default_provider = "ollama",

  -- Configuration for different AI providers
  providers = {
    ollama = {
      url = "http://localhost:11434/api/chat",
      model = "llama3.1",
    },
    groq = {
      url = "https://api.groq.com/openai/v1/chat/completions",
      model = "llama-3.1-70b-versatile",
      api_key_name = "GROQ_API_KEY",
    },
    togetherai = {
      url = "https://api.together.xyz/v1/chat/completions",
      model = "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo",
      api_key_name = "TOGETHERAI_API_KEY",
    },
    openrouter = {
      url = "https://api.openrouter.io/v1/chat/completions",
      model = "openai/gpt-4o-2024-08-06",
      api_key_name = "OPENROUTER_API_KEY",
    },
    anthropic = {
      url = "https://api.anthropic.com/v1/messages",
      model = "claude-3-5-sonnet-20240620",
      api_key_name = "ANTHROPIC_API_KEY",
    },
    openai = {
      url = "https://api.openai.com/v1/chat/completions",
      model = "gpt-4o",
      api_key_name = "OPENAI_API_KEY",
    },
  },

  -- Keybindings for Alpha4 commands
  keys = {
    { "<leader>lc", "<CMD>Alpha4ToggleChat<CR>", desc = "Toggle chat" },
    { "<leader>le", "<CMD>Alpha4Explain<CR>", desc = "Explain" },
    { "<leader>lr", "<CMD>Alpha4Replace<CR>", desc = "Replace" },
    { "<leader>ls", "<CMD>Alpha4Suggest<CR>", desc = "Suggest" },
  },

  -- Configuration for the chat interface
  chat = {
    keys = {
      submit = "<leader><CR>",  -- Key to submit a message in chat
    },
  },

  -- Parameters for different AI tasks
  params = {
    chat = {
      temperature = 0.9,
      top_p = 0.95,
      top_k = 50,
      repetition_penalty = 1.2,
      frequency_penalty = 0.2,
      presence_penalty = 0.2,
      max_tokens = 4096,
    },
    replace = {
      temperature = 0.3,
      top_p = 0.8,
      top_k = 20,
      repetition_penalty = 1.05,
      frequency_penalty = 0.1,
      presence_penalty = 0.1,
      max_tokens = 4096,
    },
    suggest = {
      temperature = 0.2,
      top_p = 0.7,
      top_k = 10,
      repetition_penalty = 1.0,
      frequency_penalty = 0.05,
      presence_penalty = 0.05,
      max_tokens = 4096,
    },
    explain = {
      temperature = 0.5,
      top_p = 0.9,
      top_k = 35,
      repetition_penalty = 1.1,
      frequency_penalty = 0.2,
      presence_penalty = 0.2,
      max_tokens = 4096,
    },
  },

  -- Customizable prompts for different tasks
  -- @see: lua/alpha4/prompts.lua
  prompts = {
    explain = {
      system = "Your custom system prompt for explanations",
      user = "Your custom user prompt for explanations",
    },
    replace = {
      system = "Your custom system prompt for code replacement",
      user = "Your custom user prompt for code replacement",
    },
    suggest = {
      system = "Your custom system prompt for code suggestions",
      user = "Your custom user prompt for code suggestions",
    },
    chat = {
      system = "Your custom system prompt for chat interactions",
      user = "Your custom user prompt for chat interactions",
    },
  },
})
```

## Supported Providers

Alpha4 supports multiple AI providers. To use a provider other than Ollama, you'll need to set up API keys:

1. Ollama (default, local)
2. Groq: Set the `GROQ_API_KEY` environment variable
3. TogetherAI: Set the `TOGETHERAI_API_KEY` environment variable
4. OpenRouter: Set the `OPENROUTER_API_KEY` environment variable
5. Anthropic: Set the `ANTHROPIC_API_KEY` environment variable
6. OpenAI: Set the `OPENAI_API_KEY` environment variable

To change providers, update the `default_provider` option in the setup function.

## Troubleshooting

1. If Alpha4 doesn't respond:
   - Ensure your chosen AI provider is properly configured
   - Check that you have an active internet connection (except for Ollama)
   - Verify that your API key is correct (for non-Ollama providers)

2. If keybindings don't work:
   - Make sure Alpha4 is properly installed and loaded
   - Check for conflicting keybindings in your Neovim configuration

3. For Ollama-specific issues:
   - Ensure Ollama is running (`ollama serve` in your terminal)
   - Verify that the Ollama URL in the configuration matches your Ollama setup

For more help, please open an issue on the GitHub repository.

## Roadmap

- [x] LSP diagnostics for code analysis
- [ ] Local RAG (Retrieval-Augmented Generation)
- [ ] Advanced Prompting Techniques (ReAct, Tree of Thoughts, etc.)
