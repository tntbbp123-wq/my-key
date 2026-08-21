local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SERVER_URL = "http://127.0.0.1:5000/get-script"
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

if not httpRequest then
    warn("❌ 사용 중인 실행기가 HTTP Request 요청을 지원하지 않습니다.")
    return
end

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

    local success, response = pcall(function()
        return httpRequest({
            Url = SERVER_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({ key = userKey })
        })
    end)

    if not success or not response then
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusLabel.Text = "❌ 서버 요청 실패 (서버가 열려있는지 확인하세요)"
        warn("HTTP Request Error:", response)
        return
    end

    print("Response Status Code:", response.StatusCode)
    print("Response Body:", response.Body)

    if response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)

        if decodeSuccess and data and data.status == "success" and data.code then
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            statusLabel.Text = "✅ 인증 성공! 스크립트를 불러옵니다..."
            task.wait(0.5)

            local runScript, err = loadstring(data.code)
            if runScript then
                screenGui:Destroy()
                runScript()
            else
                statusLabel.Text = "❌ 구문 오류 발생"
                warn("Script Load Error:", err)
            end
        else
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            statusLabel.Text = "❌ 서버 응답 파싱 실패"
        end
    else
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusLabel.Text = "❌ 잘못된 키이거나 서버 오류 (" .. tostring(response.StatusCode) .. ")"
    end
end

submitBtn.MouseButton1Click:Connect(verifyKey)
