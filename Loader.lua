--// 1.2 Update

Script = {
    Table = getgenv()['Spectral.lol'],

    Target = nil,
    CamTarget = nil,

    MainEvent = nil,
    Argument = nil,

    Functions = {},
    Drawings = {}
}

--// Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Variables
local Client = Players.LocalPlayer
local Mouse = Client:GetMouse()
local Camera = Workspace.CurrentCamera
local Arguments = loadstring(game:HttpGet("https://raw.githubusercontent.com/Platmino/Spectral.lua/refs/heads/main/Arguments.lua"))()

task.spawn(function()
	for Index, Value in pairs(Arguments) do 
		if table.find(Value, game.PlaceId) then 
			Script.Argument = Index
		end
	end
	for _, Value in pairs(game.ReplicatedStorage:GetChildren()) do
		if Value.Name == "MainEvent" or Value.Name == "Bullets" or Value.Name == ".gg/untitledhood" or Value.Name == "Remote" or Value.Name == "MAINEVENT" then
			Script.MainEvent = Value
		end
	end
end)

--// Drawing
Script.Functions.Draw = function(Name, Property, Config)
    Script.Drawings[Name] = Drawing.new(Property)

    for Index, Value in pairs(Script.Table.FOV[Config]) do    
        setrenderproperty(Script.Drawings[Name], Index, Value)
    end
end

Script.Functions.Draw("TargetCircle", "Circle", "Target")
Script.Functions.Draw("TargetLine", "Line", "Line")

--// Main Code
Script.Functions.GetClosestPlayer = function(Radius)
    local Closest = math.huge
    local Target = nil

    for Index, Player in pairs(Players:GetPlayers()) do
        if Player ~= Client and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            PartPos, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
            Magnitude = (Vector2.new(PartPos.X, PartPos.Y) - UserInputService:GetMouseLocation()).Magnitude

            if Radius > Magnitude and (Magnitude < Closest and OnScreen) then
                Closest = Magnitude
                Target = Player
            end
        end
    end
    return Target
end

UserInputService.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement then 
        Script.Drawings.TargetCircle.Position = UserInputService:GetMouseLocation()
    end
end)

UserInputService.InputBegan:Connect(function(Input, gameProccessedEvent)
    if gameProccessedEvent then return end

    if Input.KeyCode == Script.Table.Target.Keybind and Script.Table.Target.Enabled then
        if Script.Target == nil then
            Script.Target = Script.Functions.GetClosestPlayer(Script.Drawings.TargetCircle.Radius)
        else
            Script.Target = nil
        end
    end

    if Input.KeyCode == Script.Table.Camera.Keybind and Script.Table.Camera.Enabled then
        if Script.CamTarget == nil then
            Script.CamTarget = Script.Functions.GetClosestPlayer(math.huge)
        else
            Script.CamTarget = nil
        end
    end
end)

Script.Functions.GetPrediction = function()
    if Script.Target and Script.Target.Character and Script.Target.Character.Humanoid then
        local PredictedPos
        if Script.Target.Character.Humanoid.FloorMaterial == Enum.Material.Air then
            PredictedPos = Script.Target.Character[Script.Table.Target.Bone].Position + Vector3.new(0, Script.Table.Target.JumpOffset, 0) + Script.Target.Character[Script.Table.Target.Bone].Velocity * Script.Table.Target.Prediction
        else
            PredictedPos = Script.Target.Character[Script.Table.Target.Bone].Position + Script.Target.Character[Script.Table.Target.Bone].Velocity * Script.Table.Target.Prediction
        end
        return PredictedPos
    end
end

Script.Functions.HookThatShit = function(Character)
    Character.ChildAdded:Connect(function(Child)
        if Child:IsA("Tool") then
            Child.Activated:Connect(function()
                if Script.Target and Script.Target.Character then
                    Script.MainEvent:FireServer(Script.Argument, Script.Functions.GetPrediction(Script.Table.Target))
                end
            end)
        end
    end)
end

Client.CharacterAdded:Connect(Script.Functions.HookThatShit)
Script.Functions.HookThatShit(Client.Character)

RunService.Heartbeat:Connect(function(Delta)
    if Script.Target and Script.Target.Character and Script.Table.FOV.Line.Visible then
        PredictedPos = Script.Functions.GetPrediction(Script.Table.Target)
        Pos, OnScreen = Camera:WorldToViewportPoint(PredictedPos)
        
        if OnScreen then
            Script.Drawings.TargetLine.Visible = true
            Script.Drawings.TargetLine.From = UserInputService:GetMouseLocation()
            Script.Drawings.TargetLine.To = Vector2.new(Pos.X, Pos.Y)
        else
            Script.Drawings.TargetLine.Visible = false
        end
    else
        Script.Drawings.TargetLine.Visible = false
    end
end)

RunService.RenderStepped:Connect(function()
    if Script.Table.Camera.Enabled and Script.CamTarget and Script.CamTarget.Character then
        local PredictedPos
        if Script.CamTarget.Character.Humanoid.FloorMaterial == Enum.Material.Air then
            PredictedPos = Script.CamTarget.Character[Script.Table.Camera.Bone].Position + Vector3.new(0, Script.Table.Camera.JumpOffset, 0) + Script.CamTarget.Character[Script.Table.Camera.Bone].Velocity * Script.Table.Camera.Prediction
        else
            PredictedPos = Script.CamTarget.Character[Script.Table.Camera.Bone].Position + Script.CamTarget.Character[Script.Table.Camera.Bone].Velocity * Script.Table.Camera.Prediction
        end

        Camera.CFrame = CFrame.new(Camera.CFrame.p, PredictedPos)
    end
end)
