-- AUTO COLLECT - SỬA LỖI HOÀN CHỈNH
-- Tuân thủ 9 giai đoạn chính xác

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local AUTO_COLLECT = true
local FLY_SPEED = 300
local SAFETY_BUFFER = 3

-- VECTOR AB
local A = Vector3.new(153, 4.15, -140)
local B = Vector3.new(4027, -1, -135)
local AB = B - A
local AB_LENGTH = AB.Magnitude

local MIN_Y = -5
local MAX_Y = 7

local TSUNAMI_SPEEDS = {
    ["BeastWave"] = 374.36,
    ["BeastWave_Visual"] = 377.64,
    ["SnakeWave"] = 91.34,
    ["SnakeWave_Visual"] = 93.04,
    ["WackyWave"] = 72.00,
    ["WackyWave_Visual"] = 74.54,
    ["Wave1"] = 113.69,
    ["Wave1_Visual"] = 115.93,
    ["Wave2"] = 123.20,
    ["Wave2_Visual"] = 124.20,
    ["Wave3"] = 151.00,
    ["Wave3_Visual"] = 157.04,
    ["Wave4"] = 179.91,
    ["Wave4_Visual"] = 185.90,
    ["Wave5"] = 213.50,
    ["Wave5_Visual"] = 220.31,
    ["WonkyWave"] = 85.58,
    ["WonkyWave_Visual"] = 87.51,
}

print("🎮 AUTO COLLECT - FIXED VERSION")

-- ============================================
-- XÓA TƯỜNG
-- ============================================
local function nuke(v)
    pcall(function() v:Destroy() end)
end

for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("TouchTransmitter") or v:IsA("ProximityPrompt") or v:IsA("ClickDetector") then
        nuke(v)
    end
    if v:IsA("Part") or v:IsA("MeshPart") then
        local n = v.Name:lower()
        if n:find("vip") or n:find("premium") or n:find("cao") then
            nuke(v)
        end
    end
end

workspace.DescendantAdded:Connect(function(v)
    if v:IsA("TouchTransmitter") or v:IsA("ProximityPrompt") or v:IsA("ClickDetector") then
        nuke(v)
    end
    if v:IsA("Part") or v:IsA("MeshPart") then
        local n = v.Name:lower()
        if n:find("vip") or n:find("premium") or n:find("cao") then
            nuke(v)
        end
    end
end)

-- ============================================
-- TOÁN HỌC
-- ============================================

-- Chiếu P xuống dây AB
local function projectOntoLine(P)
    local AP = P - A
    local t = math.clamp(AP:Dot(AB) / AB:Dot(AB), 0, 1)
    return A + AB * t
end

-- Tính khoảng cách từ điểm trên dây đến A (dùng để so sánh)
local function distanceFromA(point)
    return (point - A).Magnitude
end

-- ============================================
-- TÌM ITEMS - SỬA LỖI
-- ============================================

local function findAllItems()
    local tickets = {}
    local consoles = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if not obj:IsA("BasePart") and not obj:IsA("MeshPart") then
            continue
        end
        
        local y = obj.Position.Y
        if y < MIN_Y or y > MAX_Y then
            continue
        end
        
        -- Bỏ qua item đang rơi/bay
        if obj.AssemblyLinearVelocity.Magnitude > 5 then
            continue
        end
        
        local name = obj.Name
        
        -- TÌM TICKET (ưu tiên cao nhất)
        if name == "Rayshield" or 
           name == "Ticket" or 
           name == "GoldenTicket" or
           (obj.Parent and (obj.Parent.Name == "Rayshield" or 
                           obj.Parent.Name == "Ticket" or
                           obj.Parent.Name:find("Ticket"))) then
            table.insert(tickets, obj)
            
        -- GAME CONSOLE (ưu tiên thấp hơn)
        elseif name == "Game Console" then
            table.insert(consoles, obj)
        end
    end
    
    return tickets, consoles
end

-- ============================================
-- TÌM ITEM GÁN NHẤT TỪ VỊ TRÍ HIỆN TẠI
-- ============================================

local function findNearestItem(currentPosOnLine)
    local tickets, consoles = findAllItems()
    
    -- Ưu tiên TICKET trước
    if #tickets > 0 then
        local nearestTicket = nil
        local minDist = math.huge
        
        for _, ticket in ipairs(tickets) do
            local projection = projectOntoLine(ticket.Position)
            local dist = (projection - currentPosOnLine).Magnitude
            
            if dist < minDist then
                minDist = dist
                nearestTicket = ticket
            end
        end
        
        if nearestTicket then
            return nearestTicket, "TICKET"
        end
    end
    
    -- Nếu không có ticket, lấy console gần nhất
    if #consoles > 0 then
        local nearestConsole = nil
        local minDist = math.huge
        
        for _, console in ipairs(consoles) do
            local projection = projectOntoLine(console.Position)
            local dist = (projection - currentPosOnLine).Magnitude
            
            if dist < minDist then
                minDist = dist
                nearestConsole = console
            end
        end
        
        if nearestConsole then
            return nearestConsole, "CONSOLE"
        end
    end
    
    return nil, nil
end

-- ============================================
-- KIỂM TRA AN TOÀN - SỬA LỖI
-- ============================================

local function isSafeToCollect(itemPos, touchPoint)
    local distToItem = (itemPos - touchPoint).Magnitude
    
    -- Thời gian bay ra + bay về
    local totalTime = (distToItem * 2) / FLY_SPEED
    
    -- Tìm tsunami gần nhất
    local nearestTsunamiTime = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("UnionOperation") and obj.Name:find("Wave") then
            if obj.Parent then
                local tsunamiType = obj.Parent.Name
                local speed = TSUNAMI_SPEEDS[tsunamiType] or 100
                
                -- Tính khoảng cách từ sóng đến điểm chạm
                local tsunamiDist = (obj.Position - touchPoint).Magnitude
                local tsunamiTime = tsunamiDist / speed
                
                if tsunamiTime < nearestTsunamiTime then
                    nearestTsunamiTime = tsunamiTime
                end
            end
        end
    end
    
    -- Phải có đủ buffer
    local isSafe = totalTime + SAFETY_BUFFER < nearestTsunamiTime
    
    if not isSafe then
        print(string.format("⚠️ Không an toàn | Bay: %.1fs | Sóng: %.1fs", totalTime, nearestTsunamiTime))
    end
    
    return isSafe
end

-- ============================================
-- BAY - SỬA LỖI
-- ============================================

local activeConnection = nil

local function stopFlying()
    if activeConnection then
        activeConnection:Disconnect()
        activeConnection = nil
    end
end

local function flyTo(targetPos)
    stopFlying()
    
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Tắt va chạm
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    local startPos = hrp.Position
    local distance = (targetPos - startPos).Magnitude
    
    if distance < 2 then
        hrp.CFrame = CFrame.new(targetPos)
        return
    end
    
    local duration = distance / FLY_SPEED
    local startTime = tick()
    
    activeConnection = RunService.Heartbeat:Connect(function()
        if not character or not character.Parent then
            stopFlying()
            return
        end
        
        hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            stopFlying()
            return
        end
        
        local elapsed = tick() - startTime
        local alpha = math.min(elapsed / duration, 1)
        
        hrp.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
        hrp.AssemblyLinearVelocity = Vector3.zero
        
        if alpha >= 1 then
            stopFlying()
        end
    end)
    
    task.wait(duration + 0.05)
    stopFlying()
end

-- ============================================
-- MAIN LOOP - LOGIC ĐÚNG
-- ============================================

local function startAutoCollect()
    local character = player.Character
    if not character then return end
    
    print("\n📍 GIAI ĐOẠN 1: Kéo về A")
    flyTo(A)
    
    -- Vị trí hiện tại trên dây
    local currentPosOnLine = A
    
    while AUTO_COLLECT do
        character = player.Character
        if not character then
            task.wait(1)
            continue
        end
        
        print("\n📍 GIAI ĐOẠN 2: Tìm item")
        
        -- Tìm item gần nhất từ vị trí hiện tại
        local item, itemType = findNearestItem(currentPosOnLine)
        
        if not item then
            print("❌ Không còn item, chờ...")
            task.wait(2)
            continue
        end
        
        print(string.format("✅ Tìm thấy: %s", itemType))
        
        -- GIAI ĐOẠN 4: Tính điểm chạm
        local touchPoint = projectOntoLine(item.Position)
        
        print(string.format("📍 GIAI ĐOẠN 4: Điểm chạm (%.1f, %.1f, %.1f)", 
            touchPoint.X, touchPoint.Y, touchPoint.Z))
        
        -- GIAI ĐOẠN 5: Trượt dọc dây đến điểm chạm
        print("📍 GIAI ĐOẠN 5: Trượt dọc dây")
        flyTo(touchPoint)
        
        -- Cập nhật vị trí hiện tại
        currentPosOnLine = touchPoint
        
        -- GIAI ĐOẠN 6: Phân tích tsunami
        print("📍 GIAI ĐOẠN 6: Kiểm tra tsunami")
        
        local safe = isSafeToCollect(item.Position, touchPoint)
        
        if safe then
            -- GIAI ĐOẠN 7A: Nhặt
            print("✅ GIAI ĐOẠN 7A: An toàn, nhặt item")
            
            flyTo(item.Position)
            task.wait(0.2) -- Đợi nhặt
            
            -- Quay về điểm chạm
            flyTo(touchPoint)
            
            print("✅ Nhặt xong, tiếp tục từ điểm chạm")
            
        else
            -- GIAI ĐOẠN 7B: Bỏ qua
            print("⚠️ GIAI ĐOẠN 7B: Không an toàn, bỏ qua")
        end
        
        task.wait(0.3)
    end
end

-- ============================================
-- AUTO RESPAWN
-- ============================================

if player.Character then
    task.spawn(startAutoCollect)
end

player.CharacterAdded:Connect(function(character)
    print("\n📍 GIAI ĐOẠN 9: Respawn, reset về A")
    stopFlying()
    character:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    task.spawn(startAutoCollect)
end)

print("\n✅ Script sẵn sàng!")
print(string.format("📍 A: (%.1f, %.1f, %.1f)", A.X, A.Y, A.Z))
print(string.format("📍 B: (%.1f, %.1f, %.1f)", B.X, B.Y, B.Z))
print("🎟️ Ưu tiên: Ticket > Console")
