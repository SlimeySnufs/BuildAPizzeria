local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local TweenService = game:GetService("TweenService")

local StoreUI = require(StarterPlayer.StarterPlayerScripts.Client.Scenes.ComputerStore.StoreUI)
--[=[
    @class ComputerStore Main
    @client
    @tag UserInterface
]=]
local self = {}

--[=[
    @function Init
    @within ComputerStore Main
]=]
function self.Init()
    self.Active = false
    self.ListenForSceneStart()
    return self
end

--[=[
    @function ListenForSceneStart
    @within ComputerStore Main
]=]
function self.ListenForSceneStart()
    
    local Laptop = workspace.Laptop
    local Prompt : ProximityPrompt = Laptop:WaitForChild("Hitbox"):WaitForChild("StoreOpenPrompt")

    Prompt.Triggered:Connect(function(plr: Player)
        if plr ~= Players.LocalPlayer then return end
        self.StartScene()
        self.Active = true
        Prompt.Enabled = false
        self.HandleTapToViewButton(workspace:WaitForChild("Laptop"):WaitForChild("ScreenPart").TapToView)
    end)

end

--[=[
    @function TurnOnPreShopUI
    @within ComputerStore Main
]=]
function self.TurnOnPreShopUI()
    
    local ScreenPart = workspace:WaitForChild("Laptop").ScreenPart

    ScreenPart.Beam.Enabled = true
    ScreenPart.SurfaceGui.Enabled = true
    ScreenPart.TapToView.SurfaceGui.Enabled = true

end

--[=[
    @function TurnOffPreShopUI
    @within ComputerStore Main
]=]
function self.TurnOffPreShopUI()
    
    local ScreenPart = workspace:WaitForChild("Laptop").ScreenPart

    ScreenPart.Beam.Enabled = false
    ScreenPart.SurfaceGui.Enabled = false
    ScreenPart.TapToView.SurfaceGui.Enabled = false

end

--[=[
    @function HandleTapToViewButton
    @param TapToViewPart BasePart
    @within ComputerStore Main
]=]
function self.HandleTapToViewButton(TapToViewPart : BasePart)
    
    local DefaultSize = TapToViewPart.Size
    local UI : SurfaceGui = TapToViewPart.SurfaceGui
    local Button : TextButton = UI.TextButton

    local function shrink()
        TweenService:Create(TapToViewPart, TweenInfo.new(0.15), {
            Size = DefaultSize * 0.8
        }):Play()
    end

    local function normal()
        TweenService:Create(TapToViewPart, TweenInfo.new(0.15), {
            Size = DefaultSize
        }):Play()
    end

    local function grow()
        TweenService:Create(TapToViewPart, TweenInfo.new(0.15), {
            Size = DefaultSize * 1.2
        }):Play()
    end

    Button.MouseButton1Down:Connect(function()
        shrink()
    end)

    Button.MouseButton1Up:Connect(function()
        normal()
    end)

    Button.MouseEnter:Connect(function()
        grow()
    end)

    Button.MouseLeave:Connect(function()
        normal()
    end)

    Button.Activated:Connect(function()
        print(`opening main store ui`)
        StoreUI.OpenMainUI()
    end)

end

--[=[
    @function ChangeCamera
    @param CamPart BasePart
    @within ComputerStore Main
]=]
function self.ChangeCamera(CamPart : BasePart)

    if (self.MovementConn) then
        self.MovementConn:Disconnect()
        self.MovementConn = nil
    end

    local CurrentCamera = workspace.CurrentCamera
    CurrentCamera.CameraType = Enum.CameraType.Scriptable
    CurrentCamera.CFrame = CamPart.CFrame
    CurrentCamera.FieldOfView = 80

    local LocalPlayer = Players.LocalPlayer

    local cam = CurrentCamera
    local mouse = LocalPlayer:GetMouse()

    local Scale = 4000

    self.MovementConn = RunService.RenderStepped:Connect(function()
	    local center: Vector2 = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
	    local x: number = mouse.X - center.X / 2
	    local y: number = mouse.Y - center.Y / 2
	    local xOffset : number = x/Scale 
	    local yOffset : number = y/Scale
	
	    local lookAtPoint : Vector3 = CamPart.Position+ CamPart.CFrame.LookVector*5
	    local vector: Vector3 = Vector3.new(
		    lookAtPoint.X - xOffset,
		    lookAtPoint.Y - yOffset,
		    lookAtPoint.Z - xOffset
        )  
	
	    local result : CFrame = CFrame.lookAt(CamPart.CFrame.Position,vector)
	
	    CurrentCamera.CFrame = result
    end)

end

--[=[
    @function PlayStoreLoadAnim
    @within ComputerStore Main
]=]
function self.PlayStoreLoadAnim()

    local LocalPlayer: Player = Players.LocalPlayer
    local character: Model = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local Humanoid: Humanoid? = character:FindFirstChildWhichIsA("Humanoid")

    if not(Humanoid) then
        warn(`Humanoid was not found for local player.`)
        return
    end

    local Animator: Animator? = Humanoid:FindFirstChildWhichIsA("Animator")
    
    if not(Animator) then
        warn(`Animator was not found for local player`)
        return
    end

    local Anim = Instance.new("Animation")
    Anim.AnimationId = "rbxassetid://90318402102594"
    local LoadedAnim = Animator:LoadAnimation(Anim)
    LoadedAnim:Play()

end

--[=[
    @function PlacePlayer
    @within ComputerStore Main
]=]
function self.PlacePlayer()
    
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local HRP : BasePart = Character:FindFirstChild("HumanoidRootPart")

    local Laptop = workspace.Laptop
    local PlacementPart = Laptop:WaitForChild("PlacementPart")

    local targetpos = Vector3.new(PlacementPart.Position.X,HRP.Position.Y,PlacementPart.Position.Z)
    local lookpos = Vector3.new(Laptop.PrimaryPart.Position.X,HRP.Position.Y,Laptop.PrimaryPart.Position.Z)
    local target_cframe = CFrame.new(targetpos,lookpos)

    HRP.Anchored = true
    HRP.CFrame = target_cframe

end

--[=[
    @function StartScene 
    @within ComputerStore Main
]=]
function self.StartScene()

    self.TurnOffPreShopUI()

    local Laptop = workspace.Laptop
    self.ChangeCamera(Laptop.Camera)

    self.PlacePlayer()
    self.PlayStoreLoadAnim()

    task.wait(2.5)

    self.TurnOnPreShopUI()

end

return self