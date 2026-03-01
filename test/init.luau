local create_maid = require("./src")

local function create_connection(expected_result: number)
    return {
        Disconnect = function(self)
            self.Disconnect = expected_result
        end,

        _disconnected = function(self)
            return self.Disconnect == expected_result
        end,
    }
end
local test_stats = {
    ran = 0,
    success = 0
}
local test = function(name: string)
    local test = {}
    test.name = name

    test.run = function(implementation: () -> ())
        local success, err = pcall(implementation)
        test_stats.ran += 1
        if not success then
            warn(`{name} - ❌ - {err}`)
        else
            print(`{name} - ✅`)
            test_stats.success += 1
        end
    end

    return test
end


test("Is callable").run(function()
    create_maid()
end)

test("add and clear methods exist").run(function()
    local add, clear = create_maid()
    assert(typeof(add) == "function", "add method not a function")
    assert(typeof(clear) == "function", "clear method not a function")
end)


test("able to add").run(function()
    local add, _ = create_maid()
    add(create_connection(0))
end)

for i = 0, 10 do
    test(`fully supports {i} connections`).run(function()
        local add, clear = create_maid()
        local cons = {}

        for j = 1, i do
            table.insert(cons, create_connection(math.random(1, 99999)))
        end

        for _, con in cons do
            add(con)
        end


        for _, con in cons do
            assert(con:_disconnected() == false, "con was disconnected simply by adding it, before clear calls")
        end

        clear()

        for _, con in cons do
            assert(con:_disconnected(), "connection wasn't disconnected after clear was called")
        end
    end)
end


test(`re-use works (10x100) connections`).run(function()
    local add, clear = create_maid()

    for i = 1, 10 do
        local cons = {}

        for j = 1, 100 do
            table.insert(cons, create_connection(math.random(1, 99999)))
        end

        for _, con in cons do
            add(con)
        end


        for _, con in cons do
            assert(con:_disconnected() == false, "con was disconnected simply by adding it, before clear calls")
        end

        clear()

        for _, con in cons do
            assert(con:_disconnected(), "connection wasn't disconnected after clear was called")
        end
    end
end)




print(`\nPassing tests: {test_stats.success} / {test_stats.ran}`)