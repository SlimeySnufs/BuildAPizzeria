local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Data = script.Parent.Parent.Data
local replica = require(Data.ReplicaClient)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")
local Bottom = MainGui:WaitForChild("Bottom")

--[=[
    @class CurrencyLabelBinder
    Use this module to bind text labels to certain values in the player's data.
    @client
    @tag UserInterface
]=]
local self = {}

--[=[
    Initializes the CurrencyLabelBinder module.

    @function Init
    @within CurrencyLabelBinder
    @return CurrencyLabelBinder
]=]
function self.Init()
    replica.Init()

    local label = Bottom.CashLabel.TextLabel
    if label and label:IsA("TextLabel") then
        self.BindLabelToCurrency("Cash", label, {"Cash"}, true, "$")
    end

    return self
end

--[=[
    Binds a label to a specific currency in the player's data with optional rolling animation.
    This will animate the label in smooth increments, queuing updates if needed.

    @function BindLabelToCurrency
    @within CurrencyLabelBinder

    @param Currency string -- Name of the currency (optional utility/debug use).
    @param Label TextLabel -- The TextLabel to bind and animate.
    @param DataPath {string} -- Replica path to the value.
    @param RollingEffect boolean -- Whether to animate changes with a rolling number effect.
    @param Affix string? -- Optional string to append after the number (e.g., " coins", "$").

    @error INVALID_LABEL -- Label must be a valid TextLabel.
]=]
function self.BindLabelToCurrency(Currency: string, Label: TextLabel, DataPath: {string}, RollingEffect: boolean, Affix: string?)
    assert(Label and Label:IsA("TextLabel"), "INVALID_LABEL")

    local updateQueue = {}
    local animating = false
    Affix = Affix or ""

    local originalSize = Label.Size
    local bumpSize = originalSize + UDim2.new(0.1, 0, 0.1, 0)

    local bumpTween = TweenService:Create(Label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
        Size = bumpSize
    })

    local function bump()
        task.spawn(function()
            bumpTween:Play()
        end)
    end

    local function escapePattern(text: string): string
        return text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    end

    local function formatWithCommas(number: number): string
        local formatted = tostring(math.floor(number + 0.5))
        return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end

    local function updateLabel(value: number)
        local text = formatWithCommas(value) .. Affix
        Label.Text = text
        bump()
    end

    local function runQueue()
        if animating or #updateQueue == 0 then return end
        animating = true

        local targetValue = table.remove(updateQueue, 1)
        local escapedAffix = escapePattern(Affix)

        local rawText = Label.Text
        local numericString = rawText:gsub(",", ""):gsub(escapedAffix, "")
        local currentValue = tonumber(numericString) or 0

        local delta = targetValue - currentValue
        local absDelta = math.abs(delta)
        local steps = math.clamp(math.ceil(absDelta / 10), 3, 15)
        local increment = delta / steps

        for i = 1, steps do
            currentValue += increment
            updateLabel(currentValue)

            if i < steps or #updateQueue == 0 then
                task.wait(0.015)
            end
        end

        updateLabel(targetValue)
        animating = false

        if #updateQueue > 0 then
            runQueue()
        end
    end

    replica.ListenForChange(DataPath, function(newValue: number, oldValue: number)
        if not RollingEffect then
            updateLabel(newValue)
            return
        end

        table.insert(updateQueue, newValue)
        runQueue()
    end)

    task.spawn(function()
        task.wait(3)
        local data = replica.Data
        if data and data[Currency] ~= nil then
            updateLabel(data[Currency])
        end
    end)
end

return self
