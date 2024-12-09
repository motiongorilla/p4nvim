local user_data = require("fetch_data")
local utility = require("utility")
local pickers = require("telescope.pickers")
local finders = require('telescope.finders')
local sorters = require('telescope.config').values.generic_sorter
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

function M.ShowCheckedOutInTelescope()
    -- Execute the Perforce opened command
    local result = utility.process_cmd("p4 opened")
    local file_paths = utility.depot_path_to_local(result)

    -- Use Telescope to display the local files
    pickers.new({}, {
        prompt_title = 'Opened Files',
        finder = finders.new_table {
            results = file_paths,
        },
        sorter = sorters({}),
        attach_mappings = function(prompt_bufnr, map)
            map('i', '<CR>', function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.api.nvim_command('edit ' .. selection[1])
            end)
            return true
        end,
    }):find()
end

-- Function to handle changelist selection for deletion
local function _delete_cl(changelist, cl_window)
    vim.api.nvim_win_close(cl_window, true)

    if changelist then
        -- Check if there are files in the changelist
        local result = utility.process_cmd("p4 opened -c " .. changelist)

        if result ~= "" then
            -- Prompt the user to revert files
            local revert_files = vim.fn.input("Changelist has files. Revert files before deletion? (y/n): ")
            if revert_files:lower() == "y" then
                -- Revert files in the changelist
                utility.execute_command("revert", "//...", changelist)
                print("Files reverted.")
            else
                print("Files not reverted. Aborting deletion.")
                return
            end
        end

        -- Delete the changelist
        local delete_result = utility.process_cmd("p4 change -d "..changelist)

        if delete_result:match("deleted") then
            print("Changelist " .. changelist .. " deleted successfully.")
        else
            print("Failed to delete changelist " .. changelist .. ".")
        end
    else
        print("Error: you did not select a valid line.")
    end
end


function M.DeleteChangelist()
    local cl_unpacked = user_data.GetCLs()

    -- Create a new buffer and window for displaying changelists
    local cl_buffer, cl_window = utility.create_window(100, 3 * #cl_unpacked, cl_unpacked)

    -- Map <Enter> to select a changelist using a closure
    vim.api.nvim_buf_set_keymap(
        cl_buffer, "n", "<CR>", "", {
            noremap = true,
            silent = true,
            callback = function()
                local line = vim.api.nvim_get_current_line()
                local changelist = line:match("CL (%d+)")
                _delete_cl(changelist, cl_window)
            end
        }
    )
end


function M.ShowCheckedOut()
    -- Execute the Perforce opened command
    local result = utility.process_cmd("p4 opened")

    -- Parse the opened files output
    local checked_out_files = {}
    for line in result:gmatch("[^\r\n]+") do
        table.insert(checked_out_files, line)
    end

    if #checked_out_files == 0 then
        print("No files currently checked out.")
        return
    end

    -- Create a new buffer and window for displaying the checked out files
    utility.create_window(100, #checked_out_files, checked_out_files)
end

local function _show_files_in_cl(cl_num)
    -- Execute the Perforce opened command for the specified changelist
    local result = utility.process_cmd("p4 opened -c " .. cl_num)
    local file_paths = utility.depot_path_to_local(result)

    local file_buffer, file_window = utility.create_window(70, 2*#file_paths, file_paths)

    -- Map <Enter> to open the selected file
    vim.api.nvim_buf_set_keymap(
        file_buffer, "n", "<CR>", "", {
            noremap = true,
            silent = true,
            callback = function()
                local line = vim.api.nvim_get_current_line()
                vim.api.nvim_win_close(file_window, true)
                vim.api.nvim_command('edit ' .. line)
            end
        }
    )
end

function M.Make_new_cl(new_cl_buffer, new_cl_window, filepath, command)
    -- Get the description entered by the user
    local description = table.concat(vim.api.nvim_buf_get_lines(new_cl_buffer, 0, -1, false), "\n")

    if description and description ~= "" then
        -- Create a temporary file to hold the changelist form
        local tmpfile = os.tmpname()
        local cl_form = utility.process_cmd("p4 change -o")

        -- modify the changelist form with the desired description
        cl_form = cl_form:gsub("(<enter description here.-)\n", description .. "\n")

        -- Write the modified form to the temporary file
        local file = io.open(tmpfile, "w")
        if not file then
            print("Error creating new changelist")
            return
        end
        file:write(cl_form)
        file:close()

        -- Submit the changelist using the modified form
        local p4cl_result = utility.process_cmd("p4 change -i < " .. tmpfile)

        -- Clean up the temporary file
        os.remove(tmpfile)

        -- Close the window
        vim.api.nvim_win_close(new_cl_window, true)

        if filepath then
            -- Add/edit the file to the created changelist
            local changelist = p4cl_result:match("Change (%d+) created.")
            if changelist then
                utility.execute_command(command, filepath, changelist)
            else
                print("Failed to create changelist")
            end
        end
    else
        print("No description entered. Aborting creation of new changelist.")
    end
end


function M.ShowCLList()
    local changelists = user_data.GetCLs()
    local buffer, window = utility.create_window(70, 2*#changelists, changelists)

    vim.api.nvim_buf_set_keymap(
        buffer, "n", "<CR>", "", {
            noremap = true,
            silent = true,
            callback = function()
                local line = vim.api.nvim_get_current_line()
                if line:match("CL (%d+)") then
                    local cl_number = line:match("CL (%d+)")
                    vim.api.nvim_win_close(window, true)
                    _show_files_in_cl(cl_number)
                elseif line:match("Create new CL") then
                    M.Make_new_cl(buffer, window)
                end
            end
        }
    )
end

return M
