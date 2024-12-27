return function(whitelist_key)
    local function printTable(t, indent)
        indent = indent or ""
        for k, v in pairs(t) do
            if type(v) == "table" then
                print(indent .. tostring(k) .. ": {")
                printTable(v, indent .. "  ")
                print(indent .. "}")
            else
                print(indent .. tostring(k) .. ": " .. tostring(v))
            end
        end
    end

    local allKeys = loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/main/allkeys.lua"))()
    local blacklistedUsers = loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/main/blacklistedusers.lua"))()

    local function checkKey(key)
        if not key or key == "" then
            print("No key entered. Please provide a valid key to continue.")
            return false
        end

        for _, data in pairs(blacklistedUsers) do
            if data.key == key then
                print(data.username .. " is blacklisted. Contact support if you think this is a mistake.")
                return false
            end
        end

        for _, data in pairs(allKeys) do
            if data.key == key then
                print("Greetings, " .. data.username)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/main/test.lua"))()
                return true
            end
        end

        print("The key you entered is invalid. Please obtain a new key.")
        return false
    end

    print("Checking whitelist key...")
    return checkKey(whitelist_key)
end
print("v1.0")
