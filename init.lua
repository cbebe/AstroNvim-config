-- vim:set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab:

-- Fully embracing AstroNvim
vim.g.user_init_lua = "~/.config/nvim/lua/user/init.lua"
vim.g.user_terminal_cmd = "<cmd>terminal<cr>i"
if vim.loop.os_uname().sysname == "Windows_NT" then
	vim.g.user_init_lua = "~/AppData/Local/nvim/lua/user/init.lua"
	vim.g.user_terminal_cmd = "<cmd>terminal<cr>inu<cr>"
end

local hover_ok, hover = pcall(require, "hover")
local _, toggle_checkbox = pcall(require, "toggle-checkbox")
local ok, install = pcall(require, "nvim-treesitter.install")
if ok then install.compilers = { "gcc" } end

local function printDate()
	local pos = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	local date = os.date()
	local nline = line:sub(0, pos) .. date .. line:sub(pos + 1)
	vim.api.nvim_set_current_line(nline)
end

local function CreateTrailingCmd(auto, group, cb)
	local function callback()
		local bt = vim.bo.buftype
		local ft = vim.bo.filetype
		if bt ~= "nofile" and ft ~= "" and ft ~= "neo-tree" then cb() end
	end

	local desc = "Match extra whitespace on " .. auto
	vim.api.nvim_create_autocmd(auto, { desc = desc, group = group, pattern = "*", callback = callback })
end

local config = {
	colorscheme = "catppuccin",
	updater = {
		-- get nightly updates
		channel = "nightly",
		-- disable automatically reloading AstroNvim after an update
		auto_reload = false,
		-- disable automatically quitting AstroNvim after an update
		auto_quit = false,
	},
	diagnostics = { virtual_text = true, underline = true },
	header = {
		"████████╗██╗  ██╗██╗   ██╗ ██████╗██╗  ██╗",
		"╚══██╔══╝██║  ██║╚██╗ ██╔╝██╔════╝██║ ██╔╝",
		"   ██║   ███████║ ╚████╔╝ ██║     █████╔╝",
		"   ██║   ██╔══██║  ╚██╔╝  ██║     ██╔═██╗",
		"   ██║   ██║  ██║   ██║   ╚██████╗██║  ██╗",
		"   ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝",
		"      ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
		"      ████╗  ██║██║   ██║██║████╗ ████║",
		"      ██╔██╗ ██║██║   ██║██║██╔████╔██║",
		"      ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
		"      ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
		"      ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
	},
	plugins = {
		init = {
			"catppuccin/nvim",
			"lambdalisue/suda.vim",
			"sbdchd/neoformat",
			"ThePrimeagen/vim-be-good",
			"nkrkv/nvim-treesitter-rescript",
			"nvim-treesitter/nvim-treesitter-angular",
			"LhKipp/nvim-nu",
			"APZelos/blamer.nvim",
			"ggandor/leap.nvim",
			"dstein64/vim-startuptime",
			"opdavies/toggle-checkbox.nvim",
			"lewis6991/hover.nvim"
		},
	},
	mappings = {
		n = {
			-- hover
			["gh"] = { hover.hover, desc = "hover.nvim" },
			["gH"] = { hover.hover_select, desc = "hover.nvim (select)" },
			["<leader>gB"] = { "<cmd>BlamerToggle<cr>", desc = "Toggle Git blame" },

			["<leader>E"] = { "<cmd>e " .. vim.g.user_init_lua .. "<cr>", desc = "Edit user configuration" },
			["<leader>D"] = { printDate, desc = "Print date" },
			["<leader>F"] = { "<cmd>Neoformat<cr><cr>", desc = "Run Neoformat on current buffer" },
			["<leader>ss"] = { '<cmd>let @/ = ""<cr>', desc = "Clear search" },
			["<leader><leader>"] = { toggle_checkbox.toggle, desc = "Toggle checkbox" },
			["<C-d>"] = { "<C-d>zz" },
			["<C-u>"] = { "<C-u>zz" },

			["<leader>fl"] = { "<cmd>cd %:p:h<cr>", desc = "Change current directory to the file in the buffer" },
			["<leader>tt"] = { vim.g.user_terminal_cmd, desc = "Open terminal" },
			["<leader>rs"] = {
				function()
					vim.cmd [[
                        let _s=@/
                        %s/\s\+$//e
                        let @/=_s
                        nohl
                        unlet _s
                    ]]
				end,
				desc = "Remove all trailing whitespace",
			},
		},
		v = {
			["<leader>jj"] = { "<cmd>% !jq .<cr>", desc = "Pretty-print highlighted JSON" },
			["<leader>jc"] = { "<cmd>% !jq -c .<cr><cr>", desc = "Minify highlighted JSON" },
		},
		t = {
			["<esc><esc>"] = { "<C-\\><C-n>" },
		},
	},
	["which-key"] = {
		register = {
			v = { ["<leader>"] = { j = { name = "JSON" } } },
		},
	},
	polish = function()
		-- Set autocommands
		vim.api.nvim_create_augroup("ShowDiagnostics", {})
		vim.api.nvim_create_autocmd("CursorHold,CursorHoldI", {
			desc = "Show line diagnostics automatically in hover window",
			group = "ShowDiagnostics",
			pattern = "*",
			callback = function() vim.diagnostic.open_float(nil, { focus = false }) end,
		})

		require("notify").setup {
			background_colour = "#000000",
		}

		vim.o.updatetime = 250

		-- Make background transparent
		-- vim.cmd [[
		--           highlight Normal ctermbg=none
		--           highlight NonText ctermbg=none
		--           highlight Normal guibg=none
		--           highlight NonText guibg=none
		--       ]]

		vim.cmd [[ highlight ExtraWhitespace ctermbg=red guibg=red ]]
		local match_group = vim.api.nvim_create_augroup("MatchTrailing", { clear = true })
		CreateTrailingCmd("BufWinEnter", match_group, function() vim.cmd [[ match ExtraWhitespace /\s\+$/ ]] end)
		CreateTrailingCmd("InsertEnter", match_group, function() vim.cmd [[ match ExtraWhitespace /\s\+\%#\@<!$/ ]] end)
		CreateTrailingCmd("InsertLeave", match_group, function() vim.cmd [[ match ExtraWhitespace /\s\+$/ ]] end)
		CreateTrailingCmd("BufWinLeave", match_group, function() vim.cmd [[ call clearmatches() ]] end)

		vim.api.nvim_create_autocmd("BufWinEnter", {
			desc = "Do nvim-nu setup",
			pattern = "*.nu",
			callback = function() require("nu").setup {} end,
		})

		-- Run go
		vim.api.nvim_create_autocmd("BufWinEnter", {
			desc = "Run go file",
			pattern = "*.go",
			callback = function() vim.keymap.set("n", "<leader>G", "<cmd>!go run %<cr>") end,
		})

		if vim.loop.os_uname().sysname == "Windows_NT" then
			-- nushell
			vim.keymap.set("n", "<leader>tt", "<cmd>terminal<cr>inu<cr>")
		else
			vim.keymap.set("n", "<leader>tt", "<cmd>terminal<cr>i")
		end

		local leap_ok, leap = pcall(require, "leap")
		if leap_ok then leap.add_default_mappings() end
		vim.g.suda_smart_edit = 1

		if hover_ok then
			hover.setup {
				init = function()
					local lsp_ok, _ = pcall(require, "hover.providers.lsp")
					if not lsp_ok then print "hover failed to provide lsp" end
				end,
				preview_opts = { border = nil },
				preview_window = false,
				title = true,
			}
		end
		vim.g.blamer_delay = 500

		-- Use deno for formatting
		vim.g.neoformat_enabled_typescript = { "denofmt" }
		vim.g.neoformat_enabled_typescriptreact = { "denofmt" }
		vim.g.neoformat_enabled_javascript = { "denofmt" }
		vim.g.neoformat_enabled_javascriptreact = { "denofmt" }
		vim.g.neoformat_enabled_markdown = { "denofmt" }
		vim.g.neoformat_enabled_json = { "denofmt" }
	end,
}

return config
