local db = {}

function db.open(filename)
    local database = {}
    if fs.exists(filename) then
        local h = fs.open(filename, "r")
        database = textutils.unserialize(h.readAll()) or {}
        h.close()
    end

    local function save()
        local h = fs.open(filename, "w")
        h.write(textutils.serialize(database))
        h.close()
    end

    local tbl = {}

    function tbl.insert(entry)
        table.insert(database, entry)
        save()
    end

    function tbl.find(key, value)
        for _, row in ipairs(database) do
            if row[key] == value then
                return row
            end
        end
        return nil
    end

    return tbl
end

return db
