local whitelist_key = "2851zUBKS6CWX3CCi=bgJdbc3uHeF26KrWOXlQSYjg1WU9nffn"
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

print("Loaded allKeys:")
printTable(allKeys)

print("Loaded blacklistedUsers:")
printTable(blacklistedUsers)

local function checkKey(whitelist_key)
    print("Key passed to function:", whitelist_key)
    if not whitelist_key or whitelist_key == "" then
        print("No key entered. Please provide a valid key to continue.")
        return false
    end

    for _, data in pairs(blacklistedUsers) do
        if data.key == whitelist_key then
            print(data.username .. " is blacklisted. Contact support if you think this is a mistake.")
            return false
        end
    end

    local isValidKey = false
    for _, data in pairs(allKeys) do
        print("Checking key:", data.key)
        if data.key == whitelist_key then
            print("Greetings, " .. data.username)
            isValidKey = true
            break
        end
    end

    if isValidKey then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/main/test.lua"))()
    else
        print("The key you entered is invalid. Please visit our Discord server to obtain a new key, contact support for assistance, or wait a little bit due to rate limiting (max of 5 minutes).")
    end

    return isValidKey
end

checkKey(whitelist_key)
