-- vim:set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab:

local header = {
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
	"      ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
}

-- Fully embracing AstroNvim
vim.g.user_init_lua = "~/.config/nvim/lua/user/init.lua"
vim.g.user_terminal_cmd = "<cmd>terminal<cr>i"
if vim.loop.os_uname().sysname == "Windows_NT" then
	vim.g.user_init_lua = "~/AppData/Local/nvim/lua/user/init.lua"
	vim.g.user_terminal_cmd = "<cmd>terminal<cr>inu<cr>"
end

local hover_ok, hover = pcall(require, "hover")
local _, toggle_checkbox = pcall(require, "toggle-checkbox")

local function printDate()
	local pos = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	local date = os.date()
	local nline = line:sub(0, pos) .. date .. line:sub(pos + 1)
	vim.api.nvim_set_current_line(nline)
end

local ok, install = pcall(require, "nvim-treesitter.install")
if ok then install.compilers = { "gcc" } end

local mappings = {
	n = {
		-- hover
		["gh"] = { hover.hover, desc = "hover.nvim" },
		["gH"] = { hover.hover_select, desc = "hover.nvim (select)" },
		["<leader>gB"] = { "<cmd>BlamerToggle<cr>", desc = "Toggle Git blame" },

		["<leader>E"] = {
			"<cmd>e " .. vim.g.user_init_lua .. "<cr>",
			desc = "Edit user configuration"
		},
		["<leader>D"] = { printDate, desc = "Print date" },
		["<leader>F"] = {
			"<cmd>Neoformat<cr><cr>",
			desc = "Run Neoformat on current buffer"
		},
		["<leader>ss"] = { '<cmd>let @/ = ""<cr>', desc = "Clear search" },
		["<C-d>"] = { "<C-d>zz" },
		["<C-u>"] = { "<C-u>zz" },

		["<leader>fl"] = {
			"<cmd>cd %:p:h<cr>",
			desc = "Change current directory to the file in the buffer"
		},
		["<leader>tt"] = { vim.g.user_terminal_cmd, desc = "Open terminal" },
		["<leader>rs"] = {
			[[<cmd>let _s=@/ | %s/\s\+$//e | let @/=_s | nohl | unlet _s<cr>]],
			desc = "Remove all trailing whitespace"
		}
	},
	v = {
		["<leader>jj"] = {
			"<cmd>% !jq .<cr>",
			desc = "Pretty-print highlighted JSON"
		},
		["<leader>jc"] = {
			"<cmd>% !jq -c .<cr><cr>",
			desc = "Minify highlighted JSON"
		}
	},
	t = { ["<esc><esc>"] = { "<C-\\><C-n>" } }
}

local function polish()
	-- Set autocommands
	vim.api.nvim_create_user_command('OrganizeImports', function()
		vim.lsp.buf.execute_command({
			command = "_typescript.organizeImports",
			arguments = { vim.fn.expand("%:p") },
		})
	end, { nargs = 0 })
	vim.api.nvim_create_augroup("ShowDiagnostics", {})
	vim.api.nvim_create_autocmd("CursorHold,CursorHoldI", {
		desc = "Show line diagnostics automatically in hover window",
		group = "ShowDiagnostics",
		pattern = "*",
		callback = function()
			vim.diagnostic.open_float(nil, { focus = false })
		end
	})

	require("notify").setup { background_colour = "#000000" }

	vim.o.updatetime = 250

	-- Make background transparent
	-- vim.cmd [[
	--           highlight Normal ctermbg=none
	--           highlight NonText ctermbg=none
	--           highlight Normal guibg=none
	--           highlight NonText guibg=none
	--       ]]

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
			callback = callback
		})
	end

	local match_group = vim.api.nvim_create_augroup("MatchTrailing",
		{ clear = true })
	CreateTrailingCmd("BufWinEnter", match_group, function()
		vim.cmd [[ match ExtraWhitespace /\s\+$/ ]]
	end)
	CreateTrailingCmd("InsertEnter", match_group, function()
		vim.cmd [[ match ExtraWhitespace /\s\+\%#\@<!$/ ]]
	end)
	CreateTrailingCmd("InsertLeave", match_group, function()
		vim.cmd [[ match ExtraWhitespace /\s\+$/ ]]
	end)
	CreateTrailingCmd("BufWinLeave", match_group,
		function() vim.cmd [[ call clearmatches() ]] end)

	-- TODO: Add these in ftplugin
	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Toggle checkbox",
		pattern = "*.md",
		callback = function()
			vim.keymap.set("n", "<leader><leader>", toggle_checkbox.toggle)
		end
	})

	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Do nvim-nu setup",
		pattern = "*.nu",
		callback = function() require("nu").setup {} end
	})

	-- Run go
	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Run go file",
		pattern = "*.go",
		callback = function()
			vim.keymap.set("n", "<leader>G", "<cmd>!go run %<cr>")
		end
	})

	vim.api.nvim_create_autocmd("BufWinEnter", {
		desc = "Foldmethod",
		callback = function()
			vim.opt.foldmethod = "marker"
		end
	})

	local leap_ok, leap = pcall(require, "leap")
	if leap_ok then leap.add_default_mappings() end
	vim.g.suda_smart_edit = 1

	if hover_ok then
		hover.setup {
			init = function()
				local lsp_ok, _ = pcall(require, "hover.providers.lsp")
				if not lsp_ok then
					print "hover failed to provide lsp"
				end
			end,
			preview_opts = { border = nil },
			preview_window = false,
			title = true
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
end

local textobjects = {
	select = {
		enable = true,
		-- Automatically jump forward to textobj, similar to targets.vim
		lookahead = true,
		keymaps = {
			-- You can use the capture groups defined in textobjects.scm
			["aa"] = "@parameter.outer",
			["ia"] = "@parameter.inner",
			["af"] = "@function.outer",
			["if"] = "@function.inner",
			["ac"] = "@class.outer",
			["ic"] = "@class.inner"
		}
	},
	move = {
		set_jumps = true,
		enable = true, -- whether to set jumps in the jumplist
		goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
		goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
		goto_previous_start = {
			["[m"] = "@function.outer",
			["[["] = "@class.outer"
		},
		goto_previous_end = {
			["[M"] = "@function.outer",
			["[]"] = "@class.outer"
		}
	},
	swap = {
		enable = true,
		swap_next = { ["<leader>a"] = "@parameter.inner" },
		swap_previous = { ["<leader>A"] = "@parameter.inner" }
	}
}

local playground = {
	enable = true,
	disable = {},
	updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
	persist_queries = false, -- Whether the query persists across vim sessions
	keybindings = {
		toggle_query_editor = "o",
		toggle_hl_groups = "i",
		toggle_injected_languages = "t",
		toggle_anonymous_nodes = "a",
		toggle_language_display = "I",
		focus_language = "f",
		unfocus_language = "F",
		update = "R",
		goto_node = "<cr>",
		show_help = "?"
	}
}

local treesitter = {
	-- Add languages to be installed here that you want installed for treesitter
	ensure_installed = {
		"c", "cpp", "go", "lua", "python", "rust", "typescript", "help"
	},
	matchup = { enable = true },

	highlight = { enable = true },
	indent = { enable = true, disable = { "python" } },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<cr>",
			scope_incremental = "<tab>",
			node_incremental = "<cr>",
			node_decremental = "<s-tab>"
		}
	},
	textobjects = textobjects,
	playground = playground
}

-- NvChad status line config from AstroNvim docs
-- override the heirline setup call
local plugin_heirline = function(config)
	-- the first element of the configuration table is the statusline
	config[1] = {
		-- default highlight for the entire statusline
		hl = { fg = "fg", bg = "bg" },
		-- each element following is a component in astronvim.status module

		-- add the vim mode component
		astronvim.status.component.mode {
			-- enable mode text with padding as well as an icon before it
			mode_text = { icon = { kind = "VimIcon", padding = { right = 1, left = 1 } } },
			-- surround the component with a separators
			surround = {
				-- it's a left element, so use the left separator
				separator = "left",
				-- set the color of the surrounding based on the current mode using astronvim.status module
				color = function() return { main = astronvim.status.hl.mode_bg(), right = "blank_bg" } end,
			},
		},
		-- we want an empty space here so we can use the component builder to make a new section with just an empty string
		astronvim.status.component.builder {
			{ provider = "" },
			-- define the surrounding separator and colors to be used inside of the component
			-- and the color to the right of the separated out section
			surround = { separator = "left", color = { main = "blank_bg", right = "file_info_bg" } },
		},
		-- add a section for the currently opened file information
		astronvim.status.component.file_info {
			-- enable the file_icon and disable the highlighting based on filetype
			file_icon = { padding = { left = 0 } },
			filename = { fallback = "Empty" },
			-- add padding
			padding = { right = 1 },
			-- define the section separator
			surround = { separator = "left", condition = false },
		},
		-- add a component for the current git branch if it exists and use no separator for the sections
		astronvim.status.component.git_branch { surround = { separator = "none" } },
		-- add a component for the current git diff if it exists and use no separator for the sections
		astronvim.status.component.git_diff { padding = { left = 1 }, surround = { separator = "none" } },
		-- fill the rest of the statusline
		-- the elements after this will appear in the middle of the statusline
		astronvim.status.component.fill(),
		-- add a component to display if the LSP is loading, disable showing running client names, and use no separator
		astronvim.status.component.lsp { lsp_client_names = false, surround = { separator = "none", color = "bg" } },
		-- fill the rest of the statusline
		-- the elements after this will appear on the right of the statusline
		astronvim.status.component.fill(),
		-- add a component for the current diagnostics if it exists and use the right separator for the section
		astronvim.status.component.diagnostics { surround = { separator = "right" } },
		-- add a component to display LSP clients, disable showing LSP progress, and use the right separator
		astronvim.status.component.lsp { lsp_progress = false, surround = { separator = "right" } },
		-- NvChad has some nice icons to go along with information, so we can create a parent component to do this
		-- all of the children of this table will be treated together as a single component
		{
			-- define a simple component where the provider is just a folder icon
			astronvim.status.component.builder {
				-- astronvim.get_icon gets the user interface icon for a closed folder with a space after it
				{ provider = astronvim.get_icon "FolderClosed" },
				-- add padding after icon
				padding = { right = 1 },
				-- set the foreground color to be used for the icon
				hl = { fg = "bg" },
				-- use the right separator and define the background color
				surround = { separator = "right", color = "folder_icon_bg" },
			},
			-- add a file information component and only show the current working directory name
			astronvim.status.component.file_info {
				-- we only want filename to be used and we can change the fname
				-- function to get the current working directory name
				filename = { fname = function(nr) return vim.fn.getcwd(nr) end, padding = { left = 1 } },
				-- disable all other elements of the file_info component
				file_icon = false,
				file_modified = false,
				file_read_only = false,
				-- use no separator for this part but define a background color
				surround = { separator = "none", color = "file_info_bg", condition = false },
			},
		},
		-- the final component of the NvChad statusline is the navigation section
		-- this is very similar to the previous current working directory section with the icon
		{ -- make nav section with icon border
			-- define a custom component with just a file icon
			astronvim.status.component.builder {
				{ provider = astronvim.get_icon "ScrollText" },
				-- add padding after icon
				padding = { right = 1 },
				-- set the icon foreground
				hl = { fg = "bg" },
				-- use the right separator and define the background color
				-- as well as the color to the left of the separator
				surround = { separator = "right", color = { main = "nav_icon_bg", left = "file_info_bg" } },
			},
			-- add a navigation component and just display the percentage of progress in the file
			astronvim.status.component.nav {
				-- add some padding for the percentage provider
				percentage = { padding = { left = 1 } },
				-- disable all other providers
				ruler = { padding = { left = 1 } },
				-- use no separator and define the background color
				surround = { separator = "none", color = "file_info_bg" },
			},
		},
	}

	-- a second element in the heirline setup would override the winbar
	-- by only providing a single element we will only override the statusline
	-- and use the default winbar in AstroNvim

	-- return the final confiuration table
	return config
end

local plugins = {
	init = {
		"catppuccin/nvim",
		"lambdalisue/suda.vim",
		"sbdchd/neoformat",
		"ThePrimeagen/vim-be-good",
		"APZelos/blamer.nvim",
		"ggandor/leap.nvim",
		"dstein64/vim-startuptime",
		"opdavies/toggle-checkbox.nvim",
		"lewis6991/hover.nvim",

		"nvim-treesitter/playground",
		-- "nvim-treesitter/nvim-treesitter-angular",
		"nkrkv/nvim-treesitter-rescript",
		["nvim-treesitter/nvim-treesitter-textobjects"] = { after = "nvim-treesitter" },
		["LhKipp/nvim-nu"] = { ft = "nu" }
	},
	treesitter = treesitter,
	heirline = plugin_heirline
}

local updater = {
	channel = "stable",
	-- disable automatically reloading AstroNvim after an update
	auto_reload = false,
	-- disable automatically quitting AstroNvim after an update
	auto_quit = false
}

-- add new user interface icon
local icons = {
	VimIcon = "",
	ScrollText = "",
	GitBranch = "",
	GitAdd = "",
	GitChange = "",
	GitDelete = "",
}
-- modify variables used by heirline but not defined in the setup call directly
local heirline = {
	-- define the separators between each section
	separators = {
		left = { "", " " }, -- separator for the left side of the statusline
		right = { " ", "" }, -- separator for the right side of the statusline
	},
	-- add new colors that can be used by heirline
	colors = function(hl)
		-- use helper function to get highlight group properties
		local comment_fg = astronvim.get_hlgroup("Comment").fg
		hl.git_branch_fg = comment_fg
		hl.git_added = comment_fg
		hl.git_changed = comment_fg
		hl.git_removed = comment_fg
		hl.blank_bg = astronvim.get_hlgroup("Folded").fg
		hl.file_info_bg = astronvim.get_hlgroup("Visual").bg
		hl.nav_icon_bg = astronvim.get_hlgroup("String").fg
		hl.nav_fg = hl.nav_icon_bg
		hl.folder_icon_bg = astronvim.get_hlgroup("Error").fg
		return hl
	end,
	attributes = { mode = { bold = true } },
	icon_highlights = { file_icon = { statusline = false } },
}

return {
	icons = icons,
	heirline = heirline,
	colorscheme = "catppuccin",
	mappings = mappings,
	polish = polish,
	plugins = plugins,
	updater = updater,
	header = header,
	diagnostics = { virtual_text = true, underline = true },
	["which-key"] = { register = { v = { ["<leader>"] = { j = { name = "JSON" } } } } }
}
