local url = "https://raw.githubusercontent.com/doanhungf123123/commits/main/script.lua"
local success, err = pcall(function()
	local code = game:HttpGet(url)
	local func = loadstring(code)
	if func then
		func()()
		print("Loaded")
	else
		warn("Load failed")
	end
end)
if not success then
	warn("Error: " .. tostring(err))
end
