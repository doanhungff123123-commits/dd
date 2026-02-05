return function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local ProximityPromptService = game:GetService("ProximityPromptService")
	
	local player = Players.LocalPlayer
	local PlayerGui = player:WaitForChild("PlayerGui")
	
	if PlayerGui:FindFirstChild("FlyGUI") then
		PlayerGui.FlyGUI:Destroy()
		task.wait(0.3)
	end
	
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
	
	local ENABLED = false
	local flyConn, noclipConn, pickupConn
	
	local function getChar()
		local c = player.Character or player.CharacterAdded:Wait()
		return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
	end
	
	local function enableNoclip(char)
		if noclipConn then noclipConn:Disconnect() end
		noclipConn = RunService.Stepped:Connect(function()
			if not ENABLED then return end
			for _, v in pairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
		end)
	end
	
	local function disableNoclip(char)
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end
		task.wait(0.1)
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				v.CanCollide = true
			end
		end
	end
	
	local function enableInstantPickup()
		if pickupConn then pickupConn:Disconnect() end
		pickupConn = ProximityPromptService.PromptShown:Connect(function(prompt)
			if not ENABLED then return end
			pcall(function()
				local name = prompt.Name:lower()
				local action = prompt.ActionText:lower()
				if not (name:find("buy") or name:find("purchase") or action:find("buy") or action:find("robux")) then
					prompt.HoldDuration = 0
					task.wait()
					fireproximityprompt(prompt)
				end
			end)
		end)
	end
	
	local function disableInstantPickup()
		if pickupConn then
			pickupConn:Disconnect()
			pickupConn = nil
		end
	end
	
	local function flyTo(hrp, pos)
		if not hrp or not hrp.Parent or not ENABLED then return false end
		
		local startTime = tick()
		local timeout = 120
		local done = false
		
		if flyConn then flyConn:Disconnect() end
		
		flyConn = RunService.Heartbeat:Connect(function(dt)
			if not ENABLED or not hrp or not hrp.Parent then
				done = false
				if flyConn then flyConn:Disconnect() end
				return
			end
			
			local dist = (pos - hrp.Position).Magnitude
			
			if dist <= arrivalThreshold then
				hrp.CFrame = CFrame.new(pos)
				done = true
				if flyConn then flyConn:Disconnect() end
				return
			end
			
			if tick() - startTime > timeout then
				done = false
				if flyConn then flyConn:Disconnect() end
				return
			end
			
			local dir = (pos - hrp.Position).Unit
			local move = math.min(SPEED * dt, dist)
			hrp.CFrame = CFrame.new(hrp.Position + dir * move)
		end)
		
		while not done and ENABLED do
			if tick() - startTime > timeout then
				if flyConn then flyConn:Disconnect() end
				return false
			end
			task.wait()
		end
		
		return done
	end
	
	local function stop()
		ENABLED = false
		
		if flyConn then
			flyConn:Disconnect()
			flyConn = nil
		end
		
		local ok, char, hrp, hum = pcall(getChar)
		if not ok or not char then return end
		
		disableNoclip(char)
		workspace.Gravity = 196.2
		
		if hum then
			hum.PlatformStand = false
			hum.Sit = false
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		
		if hrp then
			hrp.Anchored = false
			hrp.Velocity = Vector3.zero
			hrp.RotVelocity = Vector3.zero
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
		
		task.wait(0.3)
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			task.wait(0.2)
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
		
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = true
				part.Velocity = Vector3.zero
				part.RotVelocity = Vector3.zero
			end
		end
		
		disableInstantPickup()
	end
	
	local function run(points)
		local char, hrp, hum = getChar()
		
		enableNoclip(char)
		enableInstantPickup()
		
		workspace.Gravity = 0
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		
		for i, pos in ipairs(points) do
			if not ENABLED then break end
			
			local ok = flyTo(hrp, pos)
			if not ok then break end
			
			task.wait(0.3)
		end
		
		if ENABLED then
			stop()
		end
	end
	
	local gui = Instance.new("ScreenGui", PlayerGui)
	gui.ResetOnSpawn = false
	gui.Name = "FlyGUI"
	
	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.fromOffset(200, 90)
	frame.Position = UDim2.fromScale(0.4, 0.45)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.Active = true
	frame.Draggable = true
	frame.BorderSizePixel = 0
	
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
	
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	
	local btnGo = Instance.new("TextButton", frame)
	btnGo.Size = UDim2.new(0.4, 0, 0.45, 0)
	btnGo.Position = UDim2.new(0.05, 0, 0.4, 0)
	btnGo.Font = Enum.Font.GothamBold
	btnGo.TextSize = 16
	btnGo.TextColor3 = Color3.new(1, 1, 1)
	btnGo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btnGo.Text = "GO"
	btnGo.BorderSizePixel = 0
	
	Instance.new("UICorner", btnGo).CornerRadius = UDim.new(0, 8)
	
	local btnBack = Instance.new("TextButton", frame)
	btnBack.Size = UDim2.new(0.4, 0, 0.45, 0)
	btnBack.Position = UDim2.new(0.55, 0, 0.4, 0)
	btnBack.Font = Enum.Font.GothamBold
	btnBack.TextSize = 16
	btnBack.TextColor3 = Color3.new(1, 1, 1)
	btnBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btnBack.Text = "BACK"
	btnBack.BorderSizePixel = 0
	
	Instance.new("UICorner", btnBack).CornerRadius = UDim.new(0, 8)
	
	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(0.9, 0, 0.25, 0)
	label.Position = UDim2.new(0.05, 0, 0.05, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Text = "READY"
	
	btnGo.MouseButton1Click:Connect(function()
		if ENABLED then
			stop()
			btnGo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			btnBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			label.Text = "STOPPED"
			task.wait(1)
			label.Text = "READY"
			return
		end
		
		ENABLED = true
		btnGo.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		btnBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		label.Text = "FLYING..."
		
		task.spawn(function()
			run(POINTS_GO)
			btnGo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			label.Text = "DONE"
			task.wait(1)
			label.Text = "READY"
		end)
	end)
	
	btnBack.MouseButton1Click:Connect(function()
		if ENABLED then
			stop()
			btnGo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			btnBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			label.Text = "STOPPED"
			task.wait(1)
			label.Text = "READY"
			return
		end
		
		ENABLED = true
		btnBack.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
		btnGo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		label.Text = "RETURNING..."
		
		task.spawn(function()
			run(POINTS_BACK)
			btnBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			label.Text = "DONE"
			task.wait(1)
			label.Text = "READY"
		end)
	end)
	
	player.CharacterAdded:Connect(function()
		if ENABLED then
			task.wait(1)
			stop()
			btnGo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			btnBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			label.Text = "READY"
		end
	end)
	
	print("Script loaded successfully")
end
