local c_prompts = {}

local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game.ReplicatedStorage
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer

local prompt_ui = ReplicatedStorage.GUI:WaitForChild("proximity_ui")
local player_gui = Player.PlayerGui

local default_aspects = {(200/1332), (50/802)}
local dynamic_size = UDim2.new(
	0, player_gui.ProximityPrompts.AbsoluteSize.X * default_aspects[1],
	0, player_gui.ProximityPrompts.AbsoluteSize.Y * default_aspects[2]
)

c_prompts.prompt_list = {}

function create_highlight()
	local highlight = Instance.new("Highlight", game.ReplicatedStorage)
	highlight.FillTransparency = 1
	return highlight
end

local highlight = create_highlight()

function prompt_functions(prompt: ProximityPrompt)
	table.insert(c_prompts.prompt_list, prompt)

	prompt.Style = Enum.ProximityPromptStyle.Custom
	local spec_ui : BillboardGui = prompt_ui:Clone()
	spec_ui.Parent = player_gui.ProximityPrompts
	spec_ui.Enabled = false
	spec_ui.Adornee = prompt.Parent

	spec_ui.interact_key.key_text.Text = tostring(prompt.KeyboardKeyCode.Name)
	spec_ui.information_text.Text = prompt.ActionText
	
	local tweeninfo = TweenInfo.new(.1, Enum.EasingStyle.Quad)
	
	local model_parent = prompt:FindFirstAncestorOfClass("Model")
	local hl_check = (model_parent and (not model_parent:GetAttribute("HighlightOnInteraction"))) and model_parent or false	
	
	prompt.PromptShown:Connect(function()
		spec_ui.Enabled = true
		spec_ui.information_text.TextSize = 0
		spec_ui.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(spec_ui, tweeninfo, {Size = dynamic_size}):Play()
		TweenService:Create(spec_ui.information_text, tweeninfo, {TextSize = 25}):Play()
		
		if hl_check then highlight.Parent = model_parent end
	end)

	prompt.PromptHidden:Connect(function()
		local tween = TweenService:Create(spec_ui, tweeninfo, {Size = UDim2.new(0, 0, 0, 0)})
		TweenService:Create(spec_ui.information_text, tweeninfo, {TextSize = 0}):Play()
		tween:Play()
		tween.Completed:Wait()
		spec_ui.Enabled = false
		
		highlight.Parent = game.ReplicatedStorage
	end)

	prompt.PromptButtonHoldBegan:Connect(function()
		local t_info = TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear)
		local gradient = spec_ui.interact_key.bg.duration_gradient
		local dur_val = gradient.duration
		dur_val.Value = 0
		gradient.Transparency = NumberSequence.new(0)
		gradient.Enabled = true
		
		local gradient_tween = TweenService:Create(dur_val, t_info, {Value = 1})
		gradient_tween:Play()
		TweenService:Create(spec_ui, tweeninfo, {Size = UDim2.new(0, dynamic_size.X.Offset - 5, 0, dynamic_size.Y.Offset - 5)}):Play()
		
		local num_seqConnection: RBXScriptConnection?
		num_seqConnection = RunService.Heartbeat:Connect(function(dT)
			local num_Seq = {
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(dur_val.Value - .01 or 0, 0),
				NumberSequenceKeypoint.new(dur_val.Value, .4),
				NumberSequenceKeypoint.new(1, .4)
			}
			
			gradient.Transparency = NumberSequence.new(num_Seq)
		end)
	end)

	prompt.PromptButtonHoldEnded:Connect(function()
		local gradient = spec_ui.interact_key.bg.duration_gradient
		gradient.Enabled = false
		TweenService:Create(spec_ui, tweeninfo, {Size = dynamic_size}):Play()
	end)

	prompt.Triggered:Connect(function()
		local t_info = TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
		TweenService:Create(spec_ui, t_info, {Size = UDim2.new(0, dynamic_size.X.Offset - 5, 0, dynamic_size.Y.Offset - 5)}):Play()
	end)
	
	local button : TextButton = spec_ui.interact_key
	button.MouseButton1Down:Connect(function()
		prompt:InputHoldBegin()
	end)

	button.MouseButton1Up:Connect(function()
		prompt:InputHoldEnd()
	end)

end

function initial_setup()
	for _, child : ProximityPrompt in workspace:GetDescendants() do
		if not child:IsA("ProximityPrompt") then continue end
		prompt_functions(child)
	end
end

function listener()
	workspace.DescendantAdded:Connect(function(child: ProximityPrompt)
		if not child:IsA("ProximityPrompt") then return end
		prompt_functions(child)
	end)
end

function c_prompts.Init()
	print("proximity setup")
	task.spawn(initial_setup)
	listener()
end

return c_prompts
