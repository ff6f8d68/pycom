local args = {...}
if #args == 0 then
    print("Usage:")
    print(" pycom <file.py>")
    print(" pycom comp <input.py> <output.lua>")
    return
end

local transpile = require("pycom_lib.transpile")

local function readFile(path)
    local f = fs.open(path, "r")
    if not f then return nil end
    local c = f.readAll()
    f.close()
    return c
end

local function writeFile(path, content)
    local f = fs.open(path, "w")
    f.write(content)
    f.close()
end

local function ensureCache()
    if not fs.exists(".cache") then fs.makeDir(".cache") end
    if not fs.exists(".cache/pycom") then fs.makeDir(".cache/pycom") end
end

if args[1] == "comp" then
    local input = args[2]
    local output = args[3]
    if not input or not output then
        print("Usage: pycom comp <input.py> <output.lua>")
        return
    end

    local py = readFile(input)
    if not py then
        print("Failed to read: " .. input)
        return
    end

    local lua = transpile.toLua(py)
    writeFile(output, lua)
    print("Compiled: " .. output)

else
    local input = args[1]
    local py = readFile(input)
    if not py then
        print("File not found: " .. input)
        return
    end

    ensureCache()
    local name = fs.getName(input):gsub("%.py$", "")
    local cacheFile = ".cache/pycom/" .. name .. ".lua"

    local lua = transpile.toLua(py)
    writeFile(cacheFile, lua)

    local ok, err = pcall(function()
        shell.run(cacheFile)
    end)

    fs.delete(cacheFile)

    if not ok then
        print("Runtime error:")
        print(err)
    end
end
