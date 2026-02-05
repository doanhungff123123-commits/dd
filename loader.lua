if getgenv().HungDaoFlyLoaded then 
    print("Script already running!")
    return 
end

getgenv().HungDaoFlyLoaded = true

local success, err = pcall(function()
    local scriptFunc = loadstring(game:HttpGet("https://raw.githubusercontent.com/doanhungf123123/commits/main/script.lua", true))
    if scriptFunc then
        scriptFunc()
    else
        error("Failed to load script from GitHub")
    end
end)

if not success then
    warn("Error loading script: " .. tostring(err))
    getgenv().HungDaoFlyLoaded = nil
end
