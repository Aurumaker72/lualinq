local path_root = debug.getinfo(1).source:sub(2):gsub("\\[^\\]+\\[^\\]+$", "\\")

---@module 'linq'
linq = dofile(path_root .. 'linq.lua')

-- https://stackoverflow.com/a/25976660
local function table_eq(table1, table2)
    local avoid_loops = {}
    local function recurse(t1, t2)
        -- compare value types
        if type(t1) ~= type(t2) then return false end
        -- Base case: compare simple values
        if type(t1) ~= "table" then return t1 == t2 end
        -- Now, on to tables.
        -- First, let's avoid looping forever.
        if avoid_loops[t1] then return avoid_loops[t1] == t2 end
        avoid_loops[t1] = t2
        -- Copy keys from t2
        local t2keys = {}
        local t2tablekeys = {}
        for k, _ in pairs(t2) do
            if type(k) == "table" then table.insert(t2tablekeys, k) end
            t2keys[k] = true
        end
        -- Let's iterate keys from t1
        for k1, v1 in pairs(t1) do
            local v2 = t2[k1]
            if type(k1) == "table" then
                -- if key is a table, we need to find an equivalent one.
                local ok = false
                for i, tk in ipairs(t2tablekeys) do
                    if table_eq(k1, tk) and recurse(v1, t2[tk]) then
                        table.remove(t2tablekeys, i)
                        t2keys[tk] = nil
                        ok = true
                        break
                    end
                end
                if not ok then return false end
            else
                -- t1 has a key which t2 doesn't have, fail.
                if v2 == nil then return false end
                t2keys[k1] = nil
                if not recurse(v1, v2) then return false end
            end
        end
        -- if t2 has a key which t1 doesn't have, fail.
        if next(t2keys) then return false end
        return true
    end
    return recurse(table1, table2)
end

function test_select_works()
    local params = {
        {
            ["in"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            },
            predicate = function(o)
                return { name = o.name, age = o.age }
            end,
            ["out"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            }
        },
        {
            ["in"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            },
            predicate = function(o)
                return { name = o.name, age = o.age + 1 }
            end,
            ["out"] = {
                { name = 'Alice',   age = 26 },
                { name = 'Bob',     age = 31 },
                { name = 'Charlie', age = 36 }
            }
        },
    }

    for _, param in ipairs(params) do
        local result = linq.select(param["in"], param.predicate)
        assert(#result == #param["out"])
        for i, v in ipairs(result) do
            assert(table_eq(v, param["out"][i]))
        end
    end
end

function test_where_works()
    local params = {
        {
            ["in"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            },
            predicate = function(o)
                return o.name == "Charlie"
            end,
            ["out"] = {
                { name = 'Charlie', age = 35 }
            }
        },
        {
            ["in"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            },
            predicate = function(o)
                return o.age >= 30
            end,
            ["out"] = {
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            }
        },
        {
            ["in"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            },
            predicate = function(o)
                return o.age >= 100
            end,
            ["out"] = {}
        },
        {
            ["in"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            },
            predicate = function(o)
                return true
            end,
            ["out"] = {
                { name = 'Alice',   age = 25 },
                { name = 'Bob',     age = 30 },
                { name = 'Charlie', age = 35 }
            }
        },
    }

    for _, param in ipairs(params) do
        local result = linq.where(param["in"], param.predicate)
        assert(#result == #param["out"])
        for i, v in ipairs(result) do
            assert(table_eq(v, param["out"][i]))
        end
    end
end

test_select_works()
test_where_works()
