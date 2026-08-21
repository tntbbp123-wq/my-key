local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 모바일 호환을 위해 localhost 및 127.0.0.1 자동 백업 설정
local PRIMARY_URL = "http://localhost:5000/get-script"
local SECONDARY_URL = "http://127.0.0.1:5000/get-script"

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

if PlayerGui:FindFirstChild("KeySystemLoaderGui") then
    PlayerGui.KeySystemLoaderGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KeySystemLoaderGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 220)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
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
keyInput.Position = UDim2.new(0, 10, 0, 55)
keyInput.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
keyInput.PlaceholderText = "여기에 키를 입력하세요..."
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.TextSize = 14
keyInput.Font = Enum.Font.SourceSans
keyInput.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 35)
statusLabel.Position = UDim2.new(0, 10, 0, 100)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, -20, 0, 40)
submitBtn.Position = UDim2.new(0, 10, 0, 160)
submitBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 240)
submitBtn.Text = "인증 및 스크립트 실행"
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 15
submitBtn.Font = Enum.Font.SourceSansBold
submitBtn.Parent = mainFrame

local function sendRequest(url, key)
    return pcall(function()
        return httpRequest({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({ key = key })
        })
    end)
end

local function verifyKey()
    if not httpRequest then
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        statusLabel.Text = "❌ 실행기가 http request를 지원하지 않습니다."
        return
    end

    local userKey = keyInput.Text
    if userKey == "" or userKey == nil then
        statusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
        statusLabel.Text = "⚠️ 키를 입력해주세요."
        return
    end

    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
    statusLabel.Text = "서버 연결 확인 중..."

    -- 1차 접속 시도 (localhost)
    local success, response = sendRequest(PRIMARY_URL, userKey)
    
    -- 실패 시 2차 접속 시도 (127.0.0.1)
    if not success or not response or response.StatusCode ~= 200 then
        success, response = sendRequest(SECONDARY_URL, userKey)
    end

    if not success or not response then
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        statusLabel.Text = "❌ 서버 접속 실패 (Termux 서버가 꺼져있는지 확인)"
        return
    end

    if response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)

        if decodeSuccess and data and data.status == "success" and data.code then
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            statusLabel.Text = "✅ 인증 성공! 스크립트 로딩 중..."
            task.wait(0.5)

            local runScript, err = loadstring(data.code)
            if runScript then
                screenGui:Destroy()
                runScript()
            else
                statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                statusLabel.Text = "❌ 로드 실패: " .. tostring(err)
            end
        else
            statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            statusLabel.Text = "❌ 응답 파싱 실패"
        end
    elseif response.StatusCode == 403 then
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        statusLabel.Text = "❌ 잘못된 키입니다. (유효한 키를 입력하세요)"
    else
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        statusLabel.Text = "❌ 에러 코드: " .. tostring(response.StatusCode)
    end
end

submitBtn.MouseButton1Click:Connect(verifyKey)
