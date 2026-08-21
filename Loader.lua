local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [수정됨] Termux 내부 IP 주소 반영
local SERVER_URL = "http://172.16.1.191:5000/get-script"
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

if PlayerGui:FindFirstChild("KeySystemLoaderGui") then
    PlayerGui.KeySystemLoaderGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KeySystemLoaderGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 210)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -105)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 35)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔑 AI Macro Key Verification"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -20, 0, 40)
keyInput.Position = UDim2.new(0, 10, 0, 70)
keyInput.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
keyInput.PlaceholderText = "여기에 키를 입력하세요..."
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.TextSize = 14
keyInput.Font = Enum.Font.SourceSans
keyInput.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 115)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = mainFrame

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, -20, 0, 40)
submitBtn.Position = UDim2.new(0, 10, 0, 145)
submitBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 240)
submitBtn.Text = "인증 및 스크립트 실행"
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 15
submitBtn.Font = Enum.Font.SourceSansBold
submitBtn.Parent = mainFrame

local function verifyKey()
    local userKey = keyInput.Text
    if userKey == "" or userKey == nil then
        statusLabel.Text = "⚠️ 키를 입력해주세요."
        return
    end

    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
    statusLabel.Text = "서버에서 키를 확인하는 중입니다..."

    local response = httpRequest({
        Url = SERVER_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({ key = userKey })
    })

    if response and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        if data.status == "success" and data.code then
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            statusLabel.Text = "✅ 인증 성공! 스크립트를 불러옵니다..."
            task.wait(0.5)

            local runScript, err = loadstring(data.code)
            if runScript then
                screenGui:Destroy()
                runScript()
            else
                statusLabel.Text = "❌ 구문 오류: " .. tostring(err)
            end
        end
    else
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusLabel.Text = "❌ 올바르지 않은 키이거나 서버 연결에 실패했습니다."
    end
end

submitBtn.MouseButton1Click:Connect(verifyKey)
