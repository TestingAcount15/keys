local function printTable(t, indent)
    indent = indent or ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            appendToClipboard(indent .. tostring(k) .. ": {")
            printTable(v, indent .. "  ")
            appendToClipboard(indent .. "}")
        else
            appendToClipboard(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

local function appendToClipboard(text)
    outputBuffer = outputBuffer .. text .. "\n"
end

local outputBuffer = ""
local setClipboardEnabled = true

local allKeys = loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/main/allkeys.lua"))()
local blacklistedUsers = loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/main/blacklistedusers.lua"))()

appendToClipboard("Loaded allKeys:")
printTable(allKeys)

appendToClipboard("Loaded blacklistedUsers:")
printTable(blacklistedUsers)

local function checkKey(whitelist_key)
    appendToClipboard("Key passed to function: " .. tostring(whitelist_key))
    if not whitelist_key or whitelist_key == "" then
        appendToClipboard("No key entered. Please provide a valid key to continue.")
        return false
    end

    for _, data in pairs(blacklistedUsers) do
        if data.key == whitelist_key then
            appendToClipboard(data.username .. " is blacklisted. Contact support if you think this is a mistake.")
            return false
        end
    end

    local isValidKey = false
    for _, data in pairs(allKeys) do
        appendToClipboard("Checking key: " .. data.key)
        if data.key == whitelist_key then
            appendToClipboard("Greetings, " .. data.username)
            isValidKey = true
            break
        end
    end

    if isValidKey then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingAcount15/keys/main/test.lua"))()
    else
        appendToClipboard("The key you entered is invalid. Please visit our Discord server to obtain a new key, contact support for assistance, or wait a little bit due to rate limiting (max of 5 minutes).")
    end

    return isValidKey
end

checkKey(whitelist_key)

if setClipboardEnabled then
    setclipboard(outputBuffer)
    print("All data copied to clipboard.")
end
