-- HungDao9999 | Bay Thẳng + Xuyên Tường + Instant Pickup (2 NÚT: ĐI/VỀ)
-- ĐÃ SỬA: Tắt hoàn toàn, không bay lơ lửng, tự động đóng prompt Robux

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ====== CONFIG ======
local SPEED = 500
local POINTS_GO = {
	Vector3.new(147, 3.38, -138),
	Vector3.new(2588, -0.43, -138.4),
	Vector3.new(2588.35, -0.43, -100.66)
}
local POINTS_BACK = {
	Vector3.new(2588.35, -0.43, -100.66),
	Vector3.new(2588, -0.43, -138.4),
	Vector3.new(147, 3.38, -138)
}
local arrivalThreshold = 5

-- ====== STATE ======
local ENABLED = false
local flyConn, noclipConn, promptConn, robuxPromptConn

-- ====== CHARACTER ======
local function getChar()
	local c = player.Character or player.CharacterAdded:Wait()
	return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

-- ====== TẮT CÁC PROMPT ROBUX TỰ ĐỘNG ======
local function blockRobuxPrompts()
	if robuxPromptConn then robuxPromptConn:Disconnect() end
	
	robuxPromptConn = ProximityPromptService.PromptShown:Connect(function(prompt)
		-- Kiểm tra nếu prompt yêu cầu Robux
		pcall(function()
			if prompt.RequiresLineOfSight == false or 
			   prompt.Name:lower():find("buy") or 
			   prompt.Name:lower():find("purchase") or
			   prompt.Name:lower():find("robux") or
			   prompt.ActionText:lower():find("buy") or
			   prompt.ActionText:lower():find("purchase") then
				-- Ẩn prompt ngay lập tức
				prompt.Enabled = false
				task.wait(0.1)
				prompt.Enabled = true -- Reset để không bị lỗi
				prompt.MaxActivationDistance = 0 -- Vô hiệu hóa
			end
		end)
	end)
	
	-- Đóng tất cả GUI Robux hiện có
	task.spawn(function()
		while ENABLED or robuxPromptConn do
			pcall(function()
				for _, gui in pairs(PlayerGui:GetChildren()) do
					if gui:IsA("ScreenGui") then
						-- Tìm các frame mua bằng Robux
						for _, obj in pairs(gui:GetDescendants()) do
							if obj:IsA("TextLabel") or obj:IsA("TextButton") then
								local text = obj.Text:lower()
								if text:find("robux") or text:find("purchase") or text:find("buy") then
									-- Ẩn frame cha
									local parent = obj.Parent
									while parent and parent ~= gui do
										if parent:IsA("Frame") then
											parent.Visible = false
										end
										parent = parent.Parent
									end
								end
							end
						end
					end
				end
			end)
			task.wait(0.5)
		end
	end)
end

local function unblockRobuxPrompts()
	if robuxPromptConn then 
		robuxPromptConn:Disconnect() 
		robuxPromptConn = nil
	end
end

-- ====== NOCLIP LIÊN TỤC ======
local function enableNoclip(char)
	if noclipConn then noclipConn:Disconnect() end
	noclipConn = RunService.Stepped:Connect(function()
		if not ENABLED then return end
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Massless = true
			end
		end
	end)
end

local function disableNoclip(char)
	if noclipConn then 
		noclipConn:Disconnect() 
		noclipConn = nil
	end
	
	-- Khôi phục collision đầy đủ
	task.wait(0.1) -- Đợi 1 frame
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Name == "HumanoidRootPart" then
				v.CanCollide = false
			else
				v.CanCollide = true
			end
			v.Massless = false
		end
	end
end

-- ====== BAY THẲNG BẰNG CFRAME ======
local function flyDirectTo(hrp, targetPos)
	if not hrp or not hrp.Parent or not ENABLED then
		return false
	end
	
	print("🎯 Flying to: " .. tostring(targetPos))
	
	local startTime = tick()
	local timeout = 120
	local completed = false
	
	if flyConn then flyConn:Disconnect() end
	
	flyConn = RunService.Heartbeat:Connect(function(dt)
		if not ENABLED or not hrp or not hrp.Parent then
			completed = false
			if flyConn then flyConn:Disconnect() end
			return
		end
		
		local currentPos = hrp.Position
		local direction = (targetPos - currentPos).Unit
		local distance = (targetPos - currentPos).Magnitude
		
		if distance <= arrivalThreshold then
			hrp.CFrame = CFrame.new(targetPos)
			completed = true
			if flyConn then flyConn:Disconnect() end
			return
		end
		
		if tick() - startTime > timeout then
			completed = false
			if flyConn then flyConn:Disconnect() end
			return
		end
		
		local moveDistance = math.min(SPEED * dt, distance)
		local newPos = currentPos + (direction * moveDistance)
		hrp.CFrame = CFrame.new(newPos)
	end)
	
	while not completed and ENABLED do
		if tick() - startTime > timeout then
			if flyConn then flyConn:Disconnect() end
			return false
		end
		task.wait()
	end
	
	return completed
end

-- ====== INSTANT PICKUP (TỰ ĐỘNG ẤN E) ======
local function enableInstantPickup()
	if promptConn then promptConn:Disconnect() end
	promptConn = ProximityPromptService.PromptShown:Connect(function(p)
		if not ENABLED then return end
		
		-- Chỉ pickup vật phẩm, KHÔNG pickup prompt mua bằng Robux
		pcall(function()
			local isRobuxPrompt = p.Name:lower():find("buy") or 
			                     p.Name:lower():find("purchase") or
			                     p.ActionText:lower():find("buy")
			
			if not isRobuxPrompt then
				p.HoldDuration = 0
				task.wait()
				fireproximityprompt(p)
			end
		end)
	end)
end

local function disableInstantPickup()
	if promptConn then 
		promptConn:Disconnect() 
		promptConn = nil
	end
end

-- ====== STOP & CLEANUP - SỬA KỸ LƯỠNG ======
local function stopAndCleanup()
	print("🛑 BẮT ĐẦU TẮT HOÀN TOÀN...")
	ENABLED = false
	
	-- Tắt tất cả connections
	if flyConn then 
		flyConn:Disconnect() 
		flyConn = nil
	end
	
	local success, char, hrp, hum = pcall(getChar)
	if not success or not char then
		print("⚠️ Không tìm thấy character")
		return
	end
	
	-- 1. TẮT NOCLIP TRƯỚC
	disableNoclip(char)
	print("🔒 Đã tắt noclip")
	
	-- 2. KHÔI PHỤC GRAVITY
	workspace.Gravity = 196.2
	
	-- 3. RESET HOÀN TOÀN HUMANOID
	if hum then
		hum.PlatformStand = false
		hum.Sit = false
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	
	-- 4. RESET PHYSICS HRP
	if hrp then
		hrp.Anchored = false
		hrp.Velocity = Vector3.new(0, 0, 0)
		hrp.RotVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end
	
	-- 5. ĐỢI CHẠM ĐẤT VÀ RESET LẠI
	task.wait(0.3)
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(0.2)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end
	
	-- 6. RESET TẤT CẢ PARTS TRONG CHARACTER
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
			part.Massless = false
			part.Velocity = Vector3.new(0, 0, 0)
			part.RotVelocity = Vector3.new(0, 0, 0)
		end
	end
	
	-- 7. TẮT INSTANT PICKUP VÀ ROBUX BLOCKER
	disableInstantPickup()
	unblockRobuxPrompts()
	
	print("✅ ĐÃ TẮT HOÀN TOÀN - CÓ THỂ DI CHUYỂN BÌNH THƯỜNG")
end

-- ====== MAIN LOGIC ======
local function run(points, direction)
	local char, hrp, hum = getChar()
	
	enableNoclip(char)
	enableInstantPickup()
	blockRobuxPrompts() -- Bật chặn prompt Robux
	
	workspace.Gravity = 0
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	
	print("🚀 Bắt đầu bay " .. direction .. "...")
	
	for i, pos in ipairs(points) do
		if not ENABLED then break end
		
		print("=== Điểm " .. i .. "/" .. #points .. " ===")
		local success = flyDirectTo(hrp, pos)
		
		if not success then
			print("❌ Thất bại tại điểm " .. i)
			break
		end
		
		print("✅ Đã đến điểm " .. i)
		task.wait(0.3)
	end
	
	if ENABLED then
		print("✅ Hoàn thành bay " .. direction .. "!")
		
		-- TẮT HOÀN TOÀN
		stopAndCleanup()
	end
end

-- ====== GUI 2 NÚT ======
local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false
gui.Name = "HungDaoFlyGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(220, 100)
frame.Position = UDim2.fromScale(0.4, 0.45)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2

-- NÚT ĐI
local btnGo = Instance.new("TextButton", frame)
btnGo.Size = UDim2.new(0.42, 0, 0.5, 0)
btnGo.Position = UDim2.new(0.05, 0, 0.35, 0)
btnGo.Font = Enum.Font.GothamBold
btnGo.TextSize = 18
btnGo.TextColor3 = Color3.new(1, 1, 1)
btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnGo.Text = "ĐI"
btnGo.BorderSizePixel = 0

local btnGoCorner = Instance.new("UICorner", btnGo)
btnGoCorner.CornerRadius = UDim.new(0, 8)

local btnGoStroke = Instance.new("UIStroke", btnGo)
btnGoStroke.Color = Color3.fromRGB(255, 255, 255)
btnGoStroke.Thickness = 1

-- NÚT VỀ
local btnBack = Instance.new("TextButton", frame)
btnBack.Size = UDim2.new(0.42, 0, 0.5, 0)
btnBack.Position = UDim2.new(0.53, 0, 0.35, 0)
btnBack.Font = Enum.Font.GothamBold
btnBack.TextSize = 18
btnBack.TextColor3 = Color3.new(1, 1, 1)
btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnBack.Text = "VỀ"
btnBack.BorderSizePixel = 0

local btnBackCorner = Instance.new("UICorner", btnBack)
btnBackCorner.CornerRadius = UDim.new(0, 8)

local btnBackStroke = Instance.new("UIStroke", btnBack)
btnBackStroke.Color = Color3.fromRGB(255, 255, 255)
btnBackStroke.Thickness = 1

-- LABEL TRẠNG THÁI
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(0.9, 0, 0.2, 0)
label.Position = UDim2.new(0.05, 0, 0.05, 0)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1
label.Text = "SẴN SÀNG"

-- LOGIC NÚT ĐI
btnGo.MouseButton1Click:Connect(function()
	if ENABLED then
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "ĐÃ TẮT"
		task.wait(1)
		label.Text = "SẴN SÀNG"
		return
	end
	
	ENABLED = true
	btnGo.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = "ĐANG BAY ĐI..."
	
	task.spawn(function()
		run(POINTS_GO, "ĐI")
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "HOÀN THÀNH"
		task.wait(1)
		label.Text = "SẴN SÀNG"
	end)
end)

-- LOGIC NÚT VỀ
btnBack.MouseButton1Click:Connect(function()
	if ENABLED then
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "ĐÃ TẮT"
		task.wait(1)
		label.Text = "SẴN SÀNG"
		return
	end
	
	ENABLED = true
	btnBack.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = "ĐANG BAY VỀ..."
	
	task.spawn(function()
		run(POINTS_BACK, "VỀ")
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "HOÀN THÀNH"
		task.wait(1)
		label.Text = "SẴN SÀNG"
	end)
end)

-- XỬ LÝ RESPAWN
player.CharacterAdded:Connect(function()
	if ENABLED then
		task.wait(1)
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "SẴN SÀNG"
	end
end)

print("🌟 HungDao9999 Script Loaded! (ĐÃ SỬA: Tắt hoàn toàn + Chặn Robux) 🌟")
