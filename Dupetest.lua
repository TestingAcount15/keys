local allKeys = loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/refs/heads/main/allkeys.lua"))()
local blacklistedUsers = loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/refs/heads/main/blacklistedusers.lua"))()

local function checkKey(whitelist_key)
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
        if data.key == whitelist_key then
            print("Greetings, " .. data.username)
            isValidKey = true
            break
        end
    end

    if isValidKey then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/refs/heads/main/test.lua"))()
    else
        print("The key you entered is invalid. Please visit our Discord server to obtain a new key, contact support for assistance, or wait a little bit due to rate limiting (max of 5 minutes).")
    end

    return isValidKey
end

local whitelist_key = ""
checkKey(whitelist_key)
