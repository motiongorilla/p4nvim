require("fetch_data")

local M = {}
local file_ops = require("p4file_commands")

function M.setup()
	vim.api.nvim_create_user_command("P4Checkout", function()
		file_ops.CheckoutFile()
	end, {})
end

return M
