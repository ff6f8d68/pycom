local memory = {}
local procs = {}
local pid = 0

function memory.spawn(fn)
    pid = pid + 1
    procs[pid] = {
        id = pid,
        thread = coroutine.create(fn)
    }
    return pid
end

function memory.step()
    for id, proc in pairs(procs) do
        if coroutine.status(proc.thread) ~= "dead" then
            local ok, err = coroutine.resume(proc.thread)
            if not ok then
                print("Proc " .. id .. " error: " .. err)
                procs[id] = nil
            end
        else
            procs[id] = nil
        end
    end
end

function memory.run_all()
    while next(procs) do
        memory.step()
        os.queueEvent("yield")
        os.pullEvent("yield")
    end
end

return memory
