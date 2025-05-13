local runtime = {}

-- Python-style range()
function runtime.range(start_val, end_val)
    local range_table = {}
    for i = tonumber(start_val), tonumber(end_val) do
        table.insert(range_table, i)
    end
    return range_table
end

-- Python-style len()
function runtime.len(obj)
    if type(obj) == "table" then
        local count = 0
        for _ in pairs(obj) do count = count + 1 end
        return count
    elseif type(obj) == "string" then
        return #obj
    else
        return 0
    end
end

-- Optional: Python-style print (adds newline if not present)
function runtime.print(...)
    local args = {...}
    for i, v in ipairs(args) do
        io.write(tostring(v))
        if i < #args then io.write(" ") end
    end
    io.write("\n")
end

return runtime
