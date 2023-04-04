-- vim:set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab:

local extras = require("user.extras")

-- Fully embracing AstroNvim
vim.g.user_init_lua = "~/.config/nvim/lua/user/init.lua"
vim.g.user_terminal_cmd = "<cmd>terminal<cr>i"
if vim.loop.os_uname().sysname == "Windows_NT" then
	vim.g.user_init_lua = "~/AppData/Local/nvim/lua/user/init.lua"
	vim.g.user_terminal_cmd = "<cmd>terminal<cr>inu<cr>"
end

local hover_ok, hover = pcall(require, "hover")

local function printDate()
	local pos = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	local date = os.date()
	local nline = line:sub(0, pos) .. date .. line:sub(pos + 1)
	vim.api.nvim_set_current_line(nline)
end

local function setupNeorg()
	local neorg_ok, neorg = pcall(require, "neorg")
	if neorg_ok then
		neorg.setup {
			load = {
				["core.defaults"] = {}, -- Loads default behaviour
				["core.norg.concealer"] = {}, -- Adds pretty icons to your documents
				["core.norg.dirman"] = {
					config = {
						workspaces = { notes = "~/notes" },
						default_workspace = "notes",
					},
				}, -- Manages Neorg workspaces
			},
		}
	else
		print('error loading neorg')
	end
end

local mappings = {
	n = {
		-- neorg
		["<leader>no"] = { "<cmd>edit ~/notes/index.norg<cr>", desc = "Open Neorg index" },
		["<leader>nr"] = { "<cmd>Neorg return<cr>", desc = "Close all neorg buffers" },
		["<leader>nl"] = { setupNeorg, desc = "Setup Neorg" },

		-- hover
		["gh"] = { hover.hover, desc = "hover.nvim" },
		["gH"] = { hover.hover_select, desc = "hover.nvim (select)" },
		["<leader>gB"] = { "<cmd>BlamerToggle<cr>", desc = "Toggle Git blame" },

		["<leader>E"] = {
			"<cmd>e " .. vim.g.user_init_lua .. "<cr>",
			desc = "Edit user configuration",
		},
		["<leader>D"] = { printDate, desc = "Print date" },
		["<leader>F"] = {
			"<cmd>Neoformat<cr><cr>",
			desc = "Run Neoformat on current buffer",
		},
		["<leader>ss"] = { '<cmd>let @/ = ""<cr>', desc = "Clear search" },
		["<C-d>"] = { "<C-d>zz" },
		["<C-u>"] = { "<C-u>zz" },

		["<leader>fl"] = {
			"<cmd>cd %:p:h<cr>",
			desc = "Change current directory to the file in the buffer",
		},
		["<leader>tt"] = { vim.g.user_terminal_cmd, desc = "Open terminal" },
		["<leader>R"] = {
			[[<cmd>let _s=@/ | %s/\s\+$//e | let @/=_s | nohl | unlet _s<cr>]],
			desc = "Remove all trailing whitespace",
		},
	},
	v = {
		["<leader>jj"] = {
			"<cmd>% !jq .<cr>",
			desc = "Pretty-print highlighted JSON",
		},
		["<leader>jc"] = {
			"<cmd>% !jq -c .<cr><cr>",
			desc = "Minify highlighted JSON",
		},
	},
	t = { ["<esc><esc>"] = { "<C-\\><C-n>" } },
}


local function polish()
	local ts_install, install = pcall(require, "nvim-treesitter.install")
	if ts_install then
		if vim.loop.os_uname().sysname == "Windows_NT" then
			install.prefer_git = false
			-- this is the only compiler that works for me on windows. embrace modernity
			install.compilers = { "zig" }
		end
	else
		print("could not load treesitter install")
	end


	-- Set autocommands
	vim.api.nvim_create_user_command(
		"OrganizeImports",
		function()
			vim.lsp.buf.execute_command {
				command = "_typescript.organizeImports",
				arguments = { vim.fn.expand "%:p" },
			}
		end,
		{ nargs = 0 }
	)
	vim.api.nvim_create_augroup("ShowDiagnostics", {})
	vim.api.nvim_create_autocmd("CursorHold,CursorHoldI", {
		desc = "Show line diagnostics automatically in hover window",
		group = "ShowDiagnostics",
		pattern = "*",
		callback = function() vim.diagnostic.open_float(nil, { focus = false }) end,
	})

	local notify_ok, notify = pcall(require, "notify")
	if notify_ok then pcall(notify.setup, { background_colour = "#000000" }) end

	vim.o.updatetime = 250

	-- Make background transparent
	vim.cmd [[
		highlight Normal ctermbg=none
		highlight NonText ctermbg=none
		highlight Normal guibg=none
		highlight NonText guibg=none
	]]

	vim.cmd [[ highlight ExtraWhitespace ctermbg=red guibg=red ]]

	local function CreateTrailingCmd(auto, group, cb)
		local function callback()
			local bt = vim.bo.buftype
			local ft = vim.bo.filetype
			if bt ~= "nofile" and ft ~= "" and ft ~= "neo-tree" then cb() end
		end

		local desc = "Match extra whitespace on " .. auto
		vim.api.nvim_create_autocmd(auto, {
			desc = desc,
			group = group,
			pattern = "*",
			callback = callback,
		})
	end

	local match_group = vim.api.nvim_create_augroup("MatchTrailing", { clear = true })
	CreateTrailingCmd("BufWinEnter", match_group, function() vim.cmd [[ match ExtraWhitespace /\s\+$/ ]] end)
	CreateTrailingCmd("InsertEnter", match_group, function() vim.cmd [[ match ExtraWhitespace /\s\+\%#\@<!$/ ]] end)
	CreateTrailingCmd("InsertLeave", match_group, function() vim.cmd [[ match ExtraWhitespace /\s\+$/ ]] end)
	CreateTrailingCmd("BufWinLeave", match_group, function() vim.cmd [[ call clearmatches() ]] end)

	-- TODO: Add these in ftplugin
	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Toggle checkbox",
		pattern = "*.md",
		callback = function()
			local toggle_checkbox_ok, toggle_checkbox = pcall(require, "toggle-checkbox")
			if toggle_checkbox_ok then vim.keymap.set("n", "<leader><leader>", toggle_checkbox.toggle) end
		end,
	})

	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Do nvim-nu setup",
		pattern = "*.nu",
		callback = function()
			local nu_ok, nu = pcall(require, "nu")
			if nu_ok then nu.setup {} end
		end,
	})

	-- Run Neorg
	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Setup Neorg",
		pattern = "*.norg",
		callback = setupNeorg,
	})

	-- Run go
	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Run go file",
		pattern = "*.go",
		callback = function()
			vim.opt.foldmethod = "marker"
			vim.keymap.set("n", "<leader>G", "<cmd>!go run %<cr>")
		end,
	})

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

	local telescope_ok, telescope = pcall(require, "telescope")
	if telescope_ok then pcall(telescope.load_extension, "emoji") end

	local harpoon_ok, harpoon = pcall(require, 'harpoon')
	if harpoon_ok then
		harpoon.setup {}
		local ui = require('harpoon.ui')
		local mark = require('harpoon.mark')
		vim.keymap.set('n', "<leader>ha", mark.add_file, { desc = '[h]arpoon [a]dd file' })
		vim.keymap.set('n', "<leader>ht", mark.toggle_file, { desc = '[h]arpoon [t]oggle file' })
		vim.keymap.set('n', "<leader>hm", ui.toggle_quick_menu, { desc = '[h]arpoon [m]enu' })
		vim.keymap.set('n', "<leader>hn", ui.nav_next, { desc = '[h]arpoon [n]ext' })
		vim.keymap.set('n', "<leader>hp", ui.nav_prev, { desc = '[h]arpoon [p]revious' })
		vim.keymap.set('n', "<leader>h1", function() ui.nav_file(1) end, { desc = '[h]arpoon [1]st file' })
		vim.keymap.set('n', "<leader>h2", function() ui.nav_file(2) end, { desc = '[h]arpoon [2]nd file' })
		vim.keymap.set('n', "<leader>h3", function() ui.nav_file(3) end, { desc = '[h]arpoon [3]rd file' })
		vim.keymap.set('n', "<leader>h4", function() ui.nav_file(4) end, { desc = '[h]arpoon [4]th file' })
	else
		print('could not load harpoon')
	end
end

local plugins = {
	init = function(default_plugins)
		local my_plugins = {
			"xiyaowong/telescope-emoji.nvim",
			"catppuccin/nvim",
			"lambdalisue/suda.vim",
			"sbdchd/neoformat",
			"ThePrimeagen/vim-be-good",
			"APZelos/blamer.nvim",
			"ggandor/leap.nvim",
			"dstein64/vim-startuptime",
			["opdavies/toggle-checkbox.nvim"] = { ft = "markdown" },
			"lewis6991/hover.nvim",
			"nvim-treesitter/playground",
			"nkrkv/nvim-treesitter-rescript",
			["ThePrimeagen/harpoon"] = { requires = "nvim-lua/plenary.nvim" },
			["nvim-treesitter/nvim-treesitter-textobjects"] = { after = "nvim-treesitter" },
			["LhKipp/nvim-nu"] = { ft = "nu" },
			["nvim-neorg/neorg"] = { ft = "norg", run = ":Neorg sync-parsers", requires = "nvim-lua/plenary.nvim" },
		}

		-- Disable until it's fixed ig
		default_plugins["Darazaki/indent-o-matic"] = nil

		return vim.tbl_deep_extend("force", default_plugins, my_plugins)
	end,
	treesitter = extras.plugin_treesitter,
	heirline = extras.plugin_heirline,
}

return {
	icons = extras.config_icons,
	heirline = extras.config_heirline,
	colorscheme = "catppuccin",
	mappings = mappings,
	polish = polish,
	plugins = plugins,
	updater = extras.updater,
	header = extras.header,
	diagnostics = { virtual_text = true, underline = true },
	["which-key"] = {
		register = {
			v = { ["<leader>"] = { j = { name = "JSON" } } },
			n = { ["<leader>"] = {
				h = { name = "Harpoon" },
				n = { name = "Neorg" },
			} },
		}
	},
}
