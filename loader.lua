if getgenv().HungDaoFlyLoaded then 
    warn("⚠️ Script already loaded! Please reset to reload.")
    return 
end

getgenv().HungDaoFlyLoaded = true

local success, err = pcall(function()
    loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/doanhungf123123/commits/main/script.lua",
        true
    ))()
end)

if not success then
    warn("❌ Failed to load script: " .. tostring(err))
    getgenv().HungDaoFlyLoaded = nil -- Reset nếu lỗi
end
