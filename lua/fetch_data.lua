local M = {}
local utility = require("utility")
M.user = ""
M.clientname = ""
M.clientroot = ""
M.clientstream = ""

function M.GetCLs()
    if not M.clientname then
        print("clientname is not provided")
        return
    end
    local cmd = string.format("p4 changelists -s pending -c %s", M.clientname)
    local handle = io.popen(cmd)
    local changelists = {}

    if not handle then
        print("Failed to get CLs")
        return
    end
    local output = handle:read("*a")
    handle:close()

    -- process shell output to get CL numbers
    for line in output:gmatch("[^\r\n]+") do
        local cl, desc = line:match("^Change (%d+) .- '%s*(.-)%s*'$")
        if cl and desc then
            local full_info = "CL "..cl.." , Description: "..desc
            table.insert(changelists, full_info)
        end
    end
    return changelists
end

function M.ShowFileHistory()
    local filepath = utility.get_file()

    local result = utility.process_cmd("p4 filelog " .. filepath)

    local history = {}
    -- This regex pattern extracts the changelist number, date, username, and description from the Perforce filelog output.
    -- Pattern breakdown:
    -- "... #.- change (%d+) .- on (%d+/%d+/%d+) by ([^@]+)@.- %b() '(.-)'"
    -- 1. "... #.- change (%d+)":
    --    - `...`: Matches any three characters.
    --    - `#.-`: Matches a `#` followed by any number of characters (non-greedy).
    --    - `change (%d+)`: Matches the word "change" followed by a space and captures one or more digits (the changelist number).
    -- 2. `.- on (%d+/%d+/%d+)`:
    --    - `.-`: Matches any number of characters (non-greedy).
    --    - `on (%d+/%d+/%d+)`: Matches the word "on" followed by a space and captures a date in the format `MM/DD/YYYY`.
    -- 3. `by ([^@]+)@.- %b()`:
    --    - `by ([^@]+)@`: Matches the word "by" followed by a space and captures one or more characters that are not `@` (the username), followed by `@`.
    --    - `.- %b()`: Matches any number of characters (non-greedy) followed by a space and balanced parentheses (e.g., `(text)`).
    -- 4. `'(.-)'`:
    --    - `'(.-)'`: Matches and captures any characters (non-greedy) enclosed in single quotes (the description).
    for cl, date, user, desc in result:gmatch("... #.- change (%d+) .- on (%d+/%d+/%d+) by ([^@]+)@.- %b() '(.-)'") do
        table.insert(history, string.format("CL %s | %s | %s | %s", cl, date, user, desc))
    end

    if #history == 0 then
        print("No history found for the file.")
        return
    end

    utility.create_window(70, math.min(10, #history), history)
end

return M
