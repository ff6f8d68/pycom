local transpile = {}

function transpile.toLua(code)
    local lines = {}
    local indentStack = {}

    for line in code:gmatch("[^\r\n]+") do
        local indent = line:match("^(%s*)")
        local trimmed = line:match("^%s*(.-)%s*$")
        local luaLine = trimmed

        -- Handle Python comments
        luaLine = luaLine:gsub("^%s*#(.*)", "-- %1")

        -- Handle list initialization (Python: name = [] -> Lua: name = {})
        luaLine = luaLine:gsub("^(%s*[%w_]+)%s*=%s*%[%-?%s*%]$", "%1 = {}")

        -- Handle lists with content (Python: [1, 2, 3] -> Lua: {1, 2, 3})
        luaLine = luaLine:gsub("^%s*%[(.-)%]$", function(list)
            return "{" .. list:gsub(",", ", ") .. "}"
        end)


        -- Handle lists (Python arrays) -> Lua tables
        luaLine = luaLine:gsub("^%s*%[(.*)%]$", function(list)
            return "{" .. list:gsub(",", ", ") .. "}"
        end)

        -- Import handling
        luaLine = luaLine:gsub("^import%s+([%w_]+)", "local %1 = require('plib.%1')")
        luaLine = luaLine:gsub("^from%s+([%w_]+)%s+import%s+([%w_]+)", "local %2 = require('plib.%1').%2")

        -- Function definitions
        luaLine = luaLine:gsub("^def ([%w_]+)%((.-)%)%s*:", "function %1(%2)")

         -- Fixing the "if" statement and ensuring the entire condition is correctly parsed
        luaLine = luaLine:gsub("^if (.-):", "if %1 then")

        -- Handle elif as elseif in Lua
        luaLine = luaLine:gsub("^elif (.-):", "elseif %1 then")

        -- Handle else in Lua
        luaLine = luaLine:gsub("^else:", "else")

        -- For loops with range
        luaLine = luaLine:gsub("^for ([%w_]+) in range%((.-),(.-)%)%s*:", "for %1 = %2, %3 do")
        luaLine = luaLine:gsub("^for ([%w_]+) in range%((.-)%)%s*:", "for %1 = 1, %2 do")

        -- For loop (simple iteration) -> Lua for loop
        luaLine = luaLine:gsub("^for ([%w_]+) in (.*)%s*:", "for %1 in pairs(%2) do")

        -- Handle assignment
        luaLine = luaLine:gsub("^([%w_]+)%s*=%s*(.-)$", "%1 = %2")

        -- Handle return statements
        luaLine = luaLine:gsub("^return%s+(.*)", "return %1")

        table.insert(lines, luaLine)

        local level = #indent
        while #indentStack > 0 and level < indentStack[#indentStack] do
            table.insert(lines, "end")
            table.remove(indentStack)
        end

        if trimmed:match(":$") then
            table.insert(indentStack, level)
        end
    end

    while #indentStack > 0 do
        table.insert(lines, "end")
        table.remove(indentStack)
    end

    return table.concat(lines, "\n")
end

return transpile
