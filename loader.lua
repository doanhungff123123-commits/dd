local url = "https://raw.githubusercontent.com/doanhungf123123/commits/main/script.lua"
pcall(function()
    local scriptFunc = loadstring(game:HttpGet(url))()
    scriptFunc()  -- Gọi function được return
end)
