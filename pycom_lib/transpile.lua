local transpile = {}

function transpile.toLua(code)
    local lines = {}
    local indentStack = {}

    for line in code:gmatch("[^\r\n]+") do
        local rawIndent = line:match("^(%s*)") or ""
        local trimmed = line:match("^%s*(.-)%s*$")
        local luaLine = trimmed

        local indentLevel = #rawIndent

        -- Normalize indentation to levels (every 4 spaces = 1 level)
        local level = math.floor(indentLevel / 4)

        -- Handle Python comments
        -- 1. Replace Python booleans (True -> true)
        luaLine = luaLine:gsub("True", "true")

        -- 2. Replace enumerate() with ipairs() for iteration
        luaLine = luaLine:gsub("for%s+(.-)%s+in%s+enumerate%((.-)%)", "for %1, %2 in ipairs(%2)")

        -- 3. Handle global keyword (remove it)
        luaLine = luaLine:gsub("^%s*global%s+([%w_]+)", "")

        -- 4. Replace lists (Python: name = [] -> Lua: name = {})
        luaLine = luaLine:gsub("^(%s*[%w_]+)%s*=%s*%[%-?%s*%]$", "%1 = {}")

        -- 5. Replace Python len() with Lua # (length operator)
        luaLine = luaLine:gsub("len%(([%w_]+)%)", "#%1")

        -- 6. Replace Python lambda with Lua function
        luaLine = luaLine:gsub("lambda%s*(.-)%s*:%s*(.-)", "function(%1) %2 end")

        -- 7. Handle function definitions (Python: def func(): -> Lua: function func())
        luaLine = luaLine:gsub("^def%s+([%w_]+)%((.-)%)%s*:", "function %1(%2)")

        -- 8. Handle if, elif, else statements (Python -> Lua)
        luaLine = luaLine:gsub("^if%s+(.-):", "if %1 then")
        luaLine = luaLine:gsub("^elif%s+(.-):", "elseif %1 then")
        luaLine = luaLine:gsub("^else%s*:", "else")

        -- 9. Handle for loops (Python: for x in range() -> Lua: for x = start, end do)
        luaLine = luaLine:gsub("^for%s+([%w_]+)%s+in%s+range%((.-),(.-)%)%s*:", "for %1 = %2, %3 do")
        luaLine = luaLine:gsub("^for%s+([%w_]+)%s+in%s+range%((.-)%)%s*:", "for %1 = 1, %2 do")

        -- 10. Handle for-each loop (Python: for x in list -> Lua: for i, x in ipairs(list))
        luaLine = luaLine:gsub("^for%s+([%w_]+)%s+in%s+(.-)%s*:", "for %1, %2 in ipairs(%2) do")

        -- 11. Handle return statements (Python: return x -> Lua: return x)
        luaLine = luaLine:gsub("^return%s+(.*)", "return %1")

        -- 12. Handle function calls (e.g., print statements)
        luaLine = luaLine:gsub("^print%s*%(.-%)$", "print(%1)")

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
