local M = {}

function M.countKeys(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function M.execute_command(command, file, cl)
    local cmd = "p4 "..command
    if cl then
        cmd = "p4 "..command.." -c "..cl.." "..file
    elseif file then
        cmd = "p4 "..command.." "..file
    end
    vim.cmd("!" .. cmd)
end

function M.process_cmd(command)
    -- Execute shell command and capture the output
    local handle = io.popen(command)
    if not handle then
        print("Failed to run "..command)
        return
    end
    local result = handle:read("*a")
    handle:close()

    return result
end

function M.get_file()
    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath == "" then
        print("Failed to get file path from current buffer.")
        return
    end
    return filepath
end

function M.create_window(width, height, lines)
    -- Create a new buffer and window
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

    -- Define window options
    local opts = {
        relative = "editor",
        width = width,
        height = math.min(height, 10),
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = "minimal",
        border = "single",
    }

    local window = vim.api.nvim_open_win(buffer, true, opts)
    return buffer, window
end

function M.depot_path_to_local(cmd_data)
    -- Parse the opened files output
    local files = {}
    for line in cmd_data:gmatch("[^\r\n]+") do
        local depot_path = line:match("^(//.-)#%d+")
        if depot_path then
            table.insert(files, depot_path)
        end
    end

    if #files == 0 then
        print("No files currently opened.")
        return
    end

    -- Convert depot paths to local paths
    local local_files = {}
    for _, depot_path in ipairs(files) do
        local where_result = M.process_cmd("p4 where " .. depot_path)

        local local_path = where_result:match("[^\r\n]+%s+[^\r\n]+%s+([^\r\n]+)")
        if local_path then
            table.insert(local_files, local_path)
        else
            print("Failed to convert depot path to local path: " .. depot_path)
        end
    end
    return local_files
end

return M
