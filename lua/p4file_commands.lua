local user_data = require("fetch_data")
local utility = require("utility")
local generalops = require("p4general_commands")

local M = {}

function M.CheckoutAddFile(command)
    local cl_unpacked = user_data.GetCLs()
    table.insert(cl_unpacked, "Create new CL")

    local filepath = utility.get_file()
    local cl_buffer, cl_window = utility.create_window(70, 3*#cl_unpacked, cl_unpacked)

    -- Map <Enter> to select a changelist using a closure
    vim.api.nvim_buf_set_keymap(
        cl_buffer, "n", "<CR>", "", {
            noremap = true,
            silent = true,
            callback = function()
                local line = vim.api.nvim_get_current_line()
                local changelist = line:match("CL (%d+)")
                vim.api.nvim_win_close(cl_window, true)
                if changelist then
                    utility.execute_command(command, filepath, changelist)
                elseif line:match("Create new CL") then
                    M.CreateNewChangelist(filepath, command)
                else
                    print("Error: you did not select a valid line.")
                end
            end
        }
    )
end

function M.CreateNewChangelist(filepath, command)
    local new_cl_buffer, new_cl_window = utility.create_window(70, 3,
        {"Write changelist description. Press enter in normal mode when done."})

    -- Map <Enter> to finalize the changelist creation
    vim.api.nvim_buf_set_keymap(
        new_cl_buffer, "n", "<CR>", "",{
            noremap = true,
            silent = true,
            callback = function()
                generalops.Make_new_cl(new_cl_buffer, new_cl_window, filepath, command)
        end
        }
    )

end

function M.MoveRenameFile()
    local filepath = utility.get_file()

    local new_filepath = vim.fn.input("Provide new path..", filepath)
    if new_filepath == "" then
        print("No path provided. Aborting action.")
    end

    local result = utility.process_cmd("p4 move "..filepath.." "..new_filepath)

    -- On success open file for edit with a new path
    if result:match("moved") then
        print("File moved successfully!")
        vim.api.nvim_command("edit "..new_filepath)
    else
        print("Failed to move the file. First you need to check out!")
    end
end

local function _move_operation(changelist, cl_window, filepath)
    vim.api.nvim_win_close(cl_window, true)

    if changelist then
        -- Execute the Perforce reopen command to move the file to the target changelist
        local result = utility.process_cmd("p4 reopen -c " .. changelist .. " " .. filepath)

        if result:match("reopened") then
            print("File moved to changelist " .. changelist .. " successfully.")
        else
            print("Failed to move file to changelist " .. changelist .. ".")
        end
    else
        print("Error: you did not select a valid line.")
    end
end

function M.MoveToAnotherChangelist()
    local filepath = utility.get_file()
    local cl_unpacked = user_data.GetCLs()

    local cl_buffer, cl_window = utility.create_window(70, 3*#cl_unpacked, cl_unpacked)

    -- Map <Enter> to select a changelist using a closure
    vim.api.nvim_buf_set_keymap(
        cl_buffer, "n", "<CR>", "", {
            noremap = true,
            silent = true,
            callback = function()
                local line = vim.api.nvim_get_current_line()
                local changelist = line:match("CL (%d+)")
                _move_operation(changelist, cl_window, filepath)
            end
        }
    )
end

function M.RevertFile()
    local filepath = utility.get_file()

    utility.execute_command("revert", filepath)
end

function M.GetFileChangelist()
    local filepath = utility.get_file()
    utility.execute_command("opened", filepath)
end

return M
