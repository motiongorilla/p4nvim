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
    require("fetch_data").ShowFileHistory()
end, {})

vim.api.nvim_create_user_command("P4MoveToChangelist", function()
    require("p4file_commands").MoveToAnotherChangelist()
end, {})

vim.api.nvim_create_user_command("P4DeleteChangelist", function()
    require("p4general_commands").DeleteChangelist()
end, {})

vim.api.nvim_create_user_command("P4ShowCheckedOut", function()
    require("p4general_commands").ShowCheckedOut()
end, {})

vim.api.nvim_create_user_command("P4CheckedInTelescope", function()
    require("p4general_commands").ShowCheckedOutInTelescope()
end, {})

vim.api.nvim_create_user_command("P4CLList", function()
    require("p4general_commands").ShowCLList()
end, {})

