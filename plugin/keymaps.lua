vim.api.nvim_create_user_command("P4Checkout", function()
    require("p4file_commands").CheckoutAddFile("edit")
end, {})

vim.api.nvim_create_user_command("P4Add", function()
    require("p4file_commands").CheckoutAddFile("add")
end, {})

vim.api.nvim_create_user_command("P4Revert", function()
    require("p4file_commands").RevertFile()
end, {})

vim.api.nvim_create_user_command("P4MoveRename", function()
    require("p4file_commands").MoveRenameFile()
end, {})

vim.api.nvim_create_user_command("P4GetFileCL", function()
    require("p4file_commands").GetFileChangelist()
end, {})

vim.api.nvim_create_user_command("P4ShowFileHistory", function()
    require("p4file_commands").ShowFileHistory()
end, {})

vim.api.nvim_create_user_command("P4MoveToChangelist", function()
    require("p4file_commands").MoveToAnotherChangelist()
end, {})

vim.api.nvim_create_user_command("P4DeleteChangelist", function()
    require("p4file_commands").DeleteChangelist()
end, {})

vim.api.nvim_create_user_command("P4ShowCheckedOut", function()
    require("p4file_commands").ShowCheckedOut()
end, {})

vim.api.nvim_create_user_command("P4CheckedInTelescope", function()
    require("p4file_commands").ShowCheckedOutInTelescope()
end, {})

-- vim.keymap.set("n", "<leader>pa", function() require("p4").P4add() end, { noremap = true, silent = true, desc = "'p4 add' current buffer" })
-- vim.keymap.set("n", "<leader>pe", function() require("p4nvim").P4Checkout() end, { noremap = true, silent = true, desc = "'p4 edit' current buffer" })
-- vim.keymap.set("n", "<leader>pR", ":!p4 revert -a %<CR>", { noremap = true, silent = true, desc = "Revert if unchanged" })
-- vim.keymap.set("n", "<leader>pn", function() require("perfnvim").P4next() end, { noremap = true, silent = true, desc = "Jump to next changed line" })
-- vim.keymap.set("n", "<leader>pp", function() require("perfnvim").P4prev() end, { noremap = true, silent = true, desc = "Jump to previous changed line" })
-- vim.keymap.set("n", "<leader>po", function() require("perfnvim").P4opened() end, { noremap = true, silent = true, desc = "'p4 opened' (telescope)" })
