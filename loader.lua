if getgenv().HungDaoFlyLoaded then 
    warn("Script already loaded!")
    return 
end

getgenv().HungDaoFlyLoaded = true

loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/doanhungf123123/commits/main/script.lua",
    true
))()
