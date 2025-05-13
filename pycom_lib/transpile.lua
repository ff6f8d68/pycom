local transpile = {}

function transpile.toLua(code)
    local lines = {}
    local indentStack = {}

    for line in code:gmatch("[^\r\n]+") do
        local indent = line:match("^(%s*)")
        local trimmed = line:match("^%s*(.-)%s*$")
        local luaLine = trimmed

        -- Import handling
        luaLine = luaLine:gsub("^import ([%w_]+)", "local %1 = require('plib.%1')")

        -- Function
        luaLine = luaLine:gsub("^def ([%w_]+)%((.-)%)%s*:", "function %1(%2)")

        -- If / Else
        luaLine = luaLine:gsub("^if (.-):", "if %1 then")
        luaLine = luaLine:gsub("^elif (.-):", "elseif %1 then")
        luaLine = luaLine:gsub("^else:", "else")

        -- For loops with range
        luaLine = luaLine:gsub("^for ([%w_]+) in range%((.-),(.-)%)%s*:", "for %1 = %2, %3 do")
        luaLine = luaLine:gsub("^for ([%w_]+) in range%((.-)%)%s*:", "for %1 = 1, %2 do")

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
