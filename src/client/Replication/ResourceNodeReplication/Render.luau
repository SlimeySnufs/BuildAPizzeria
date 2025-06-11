local TweenService = game:GetService("TweenService")
--[=[
    @class ResourceNodeReplication Render
    @client
    @tag ResourceNodeReplication
]=]
local self = {}

--[=[
    @function Init
    @within ResourceNodeReplication Render
]=]
function self.Init()
    return self
end

--[=[
    @function lerp
    @param current
    @param goal
    @param alpha
    @within ResourceNodeReplication Render
]=]
function self.lerp(a,b,c)
    return a + (b - a) * c
end

--[=[
    @function UpdateWheatHeight
    @param Node Instance
    @param ratio number
    @within ResourceNodeReplication Render
]=]
function self.UpdateWheatHeight(Node : Instance, ratio : number)

    local TotalHeight = 5.87
    local WheatPart = Node.Wheat

    local OldHeight : number = WheatPart.Size.Y
    local NewHeight : number = TotalHeight * ratio

    local CraftedSize : Vector3 = Vector3.new(WheatPart.Size.X, NewHeight, WheatPart.Size.Z)
    local NewPositon : Vector3? = nil

    local BottomY = WheatPart.Position.Y - (OldHeight / 2)
    local NewPosition = Vector3.new(
        WheatPart.Position.X,
        BottomY + (NewHeight / 2),
        WheatPart.Position.Z
    )

    TweenService:Create(WheatPart, TweenInfo.new(1), {Position = NewPosition,Size = CraftedSize}):Play()

end

--[=[
    @function UpdateGrowthState
    @param Node Instance
    @param NewValue Number
    @param OldValue Number?
    @param NodeType ("Wheat")
]=]
function self.UpdateGrowthState(Node : Instance, newValue : number, oldValue : number?, NodeType : string)

    if (NodeType == "Wheat" or NodeType == "Tomato") then
        self.UpdateWheatHeight(Node, newValue/4)
    end
    
end

return self
