local user_data = require("fetch_data")
local utility = require("utility")

local telescope = require('telescope')
local pickers = require("telescope.pickers")
local finders = require('telescope.finders')
local sorters = require('telescope.config').values.generic_sorter
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

function M.CheckoutAddFile(command)
    local cl_unpacked = user_data.GetCLs()
    local filepath = utility.get_file()
    local cl_buffer, cl_window = utility.create_window(70, 3*#cl_unpacked, cl_unpacked)

    -- Map <Enter> to select a changelist
    vim.api.nvim_buf_set_keymap(
        cl_buffer, "n", "<CR>", ":lua require('p4file_commands').select_changelist_entry()<CR>",
        { noremap = true, silent = true }
    )

    -- Function to handle selection
    M.select_changelist_entry = function()

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
end

function M.RevertFile()
    local filepath = utility.get_file()

    utility.execute_command("revert", filepath)
end

function M.CreateNewChangelist(filepath, command)
    local new_cl_buffer, new_cl_window = utility.create_window(70, 3,
        {"Write changelist description. Press enter in normal mode when done."})

    -- Map <Enter> to finalize the changelist creation
    vim.api.nvim_buf_set_keymap(
        new_cl_buffer, "n", "<CR>", ":lua require('p4file_commands').finalize_new_changelist()<CR>",
        { noremap = true, silent = true }
    )

    M.finalize_new_changelist = function()
        -- Get the description entered by the user
        local description = table.concat(vim.api.nvim_buf_get_lines(new_cl_buffer, 0, -1, false), "\n")

        if description and description ~= "" then
            -- Create a temporary file to hold the changelist form
            local tmpfile = os.tmpname()

            local p4ChangeHandle = io.popen("p4 change -o")
            if not p4ChangeHandle then
                print("Failed to run p4 change -o command")
                return
            end
            local changelist_form = p4ChangeHandle:read("*a")
            p4ChangeHandle:close()

            -- Modify the changelist form with the desired description
            changelist_form = changelist_form:gsub("(<enter description here.-)\n", description .. "\n")

            -- Write the modified form to the temporary file
            local file = io.open(tmpfile, "w")
            if not file then
                print("Error creating new changelist")
                return
            end
            file:write(changelist_form)
            file:close()

            -- Submit the changelist using the modified form
            local submit_handle = io.popen("p4 change -i < " .. tmpfile)
            if not submit_handle then
                print("Error executing p4 change -i")
                return
            end
            local p4ChangeIResult = submit_handle:read("*a")
            submit_handle:close()

            -- Clean up the temporary file
            os.remove(tmpfile)

            -- Close the window
            vim.api.nvim_win_close(new_cl_window, true)

            -- Add/edit the file to the created changelist
            local changelist = p4ChangeIResult:match("Change (%d+) created.")
            if changelist then
                utility.execute_command(command, filepath, changelist)
            else
                print("Failed to create changelist")
            end
        else
            print("No description entered. Aborting creation of new changelist.")
        end
    end
end

function M.ShowFileHistory()
    local filepath = utility.get_file()

    -- Execute the Perforce filelog command
    local command = "p4 filelog " .. filepath
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    -- Parse the filelog output to extract relevant information
    local history = {}
    for cl, date, user, desc in result:gmatch("... #.- change (%d+) .- on (%d+/%d+/%d+) by ([^@]+)@.- %b() '(.-)'") do
        table.insert(history, string.format("CL %s | %s | %s | %s", cl, date, user, desc))
    end

    if #history == 0 then
        print("No history found for the file.")
        return
    end

    utility.create_window(70, math.min(10, #history), history)
end

function M.MoveRenameFile()
    local filepath = utility.get_file()

    local new_filepath = vim.fn.input("Provide new path..", filepath)
    if new_filepath == "" then
        print("No path provided. Aborting action.")
    end

    -- Doing with popen to get a callback to re-open the file in a new place.
    local cmd = "p4 move "..filepath.." "..new_filepath
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()

    if result:match("moved") then
        print("File moved successfully!")
        vim.api.nvim_command("edit "..new_filepath)
    else
        print("Failed to move the file. First you need to check out!")
    end

end

function M.GetFileChangelist()
    local filepath = utility.get_file()
    utility.execute_command("opened", filepath)
end

function M.MoveToAnotherChangelist()
    local filepath = utility.get_file()
    local cl_unpacked = user_data.GetCLs()

    local cl_buffer, cl_window = utility.create_window(70, 3*#cl_unpacked, cl_unpacked)

    -- Map <Enter> to select a changelist
    vim.api.nvim_buf_set_keymap(
        cl_buffer, "n", "<CR>", ":lua require('p4file_commands').select_changelist_for_move()<CR>",
        { noremap = true, silent = true }
    )

    -- Function to handle selection
    M.select_changelist_for_move = function()
        local line = vim.api.nvim_get_current_line()
        local changelist = line:match("CL (%d+)")
        vim.api.nvim_win_close(cl_window, true)

        if changelist then
            -- Execute the Perforce reopen command to move the file to the target changelist
            local command = "p4 reopen -c " .. changelist .. " " .. filepath
            local handle = io.popen(command)
            local result = handle:read("*a")
            handle:close()

            if result:match("reopened") then
                print("File moved to changelist " .. changelist .. " successfully.")
            else
                print("Failed to move file to changelist " .. changelist .. ".")
            end
        else
            print("Error: you did not select a valid line.")
        end
    end
end

function M.ShowCheckedOut()
    -- Execute the Perforce opened command
    local command = "p4 opened"
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

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

function M.DeleteChangelist()
    local cl_unpacked = user_data.GetCLs()

    -- Create a new buffer and window for displaying changelists
    local cl_buffer, cl_window = utility.create_window(100, 3 * #cl_unpacked, cl_unpacked)

    vim.api.nvim_buf_set_keymap(
        cl_buffer, "n", "<CR>", ":lua require('p4file_commands').select_changelist_for_deletion()<CR>",
        { noremap = true, silent = true }
    )

    M.select_changelist_for_deletion = function()
        local line = vim.api.nvim_get_current_line()
        local changelist = line:match("CL (%d+)")
        vim.api.nvim_win_close(cl_window, true)

        if changelist then
            -- Check if there are files in the changelist
            local command = "p4 opened -c " .. changelist
            local handle = io.popen(command)
            local result = handle:read("*a")
            handle:close()

            if result ~= "" then
                -- Prompt the user to revert files
                local revert_files = vim.fn.input("Changelist has files. Revert files before deletion? (y/n): ")
                if revert_files:lower() == "y" then
                    -- Revert files in the changelist
                    local revert_command = "p4 revert -c " .. changelist .. " //..."
                    local revert_handle = io.popen(revert_command)
                    revert_handle:close()
                    print("Files reverted.")
                else
                    print("Files not reverted. Aborting deletion.")
                    return
                end
            end

            -- Delete the changelist
            local delete_command = "p4 change -d " .. changelist
            local delete_handle = io.popen(delete_command)
            local delete_result = delete_handle:read("*a")
            delete_handle:close()

            if delete_result:match("deleted") then
                print("Changelist " .. changelist .. " deleted successfully.")
            else
                print("Failed to delete changelist " .. changelist .. ".")
            end
        else
            print("Error: you did not select a valid line.")
        end
    end
end

function M.ShowCheckedOutInTelescope()
        -- Execute the Perforce opened command
    local command = "p4 opened"
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    -- Parse the opened files output
    local opened_files = {}
    for line in result:gmatch("[^\r\n]+") do
        local depot_path = line:match("^(//.-)#%d+")
        if depot_path then
            table.insert(opened_files, depot_path)
        end
    end

    if #opened_files == 0 then
        print("No files currently opened.")
        return
    end

    -- Convert depot paths to local paths
    local local_files = {}
    for _, depot_path in ipairs(opened_files) do
        local where_command = "p4 where " .. depot_path
        local where_handle = io.popen(where_command)
        local where_result = where_handle:read("*a")
        where_handle:close()

        -- Debugging: Print the output of the p4 where command
        print("p4 where output for " .. depot_path .. ":")
        print(where_result)

        -- Extract the local path from the p4 where output
        local local_path = where_result:match("[^\r\n]+%s+[^\r\n]+%s+([^\r\n]+)")
        if local_path then
            table.insert(local_files, local_path)
        else
            print("Failed to convert depot path to local path: " .. depot_path)
        end
    end

    -- Use Telescope to display the local files
    pickers.new({}, {
        prompt_title = 'Opened Files',
        finder = finders.new_table {
            results = local_files,
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

return M
