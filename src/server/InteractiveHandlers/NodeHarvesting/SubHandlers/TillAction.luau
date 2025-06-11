--[=[
    @class Till
    @tag InteractiveHandler
]=]
local self = {}

--[=[
    @function FlashStrikeBox
    @param position Vector3
    @param rotation Vector3
    @return {BasePart}?
    @within Till
]=]
function self.FlashStrikeBox(position : Vector3, PlayerPosition : Vector3, size : Vector3) : {BasePart}?
    
    local hitbox = Instance.new("Part")
    hitbox.Parent = workspace
    hitbox.Name = "FlashedHitbox"
    hitbox.Anchored = true
    hitbox.Size = size
    hitbox.CanCollide = false
    hitbox.Transparency = 1

    hitbox.CFrame = CFrame.new(position,PlayerPosition)

    task.delay(1, hitbox.Destroy,hitbox)

    return workspace:GetPartsInPart(hitbox)

end

local VALID_CROPS = {
    "WheatNode",
    "TomatoNode",
}

--[=[
    @function SwingAttempt
    @param player Player
    @return boolean
    @within Till
]=]
function self.SwingAttempt(player : Player) : Instance?
    
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp : BasePart = char.PrimaryPart

    local PlayerPosition: Vector3 = hrp.Position
    local PlayerDirection: Vector3 = hrp.CFrame.LookVector

    local TargetPosition = PlayerPosition + (PlayerDirection * 2)

    local Size: Vector3 = Vector3.new(6,7,6)

    local Parts: {BasePart}? = self.FlashStrikeBox(TargetPosition, PlayerPosition, Size)

    for _ , hit in Parts do
        if table.find(VALID_CROPS,hit.Parent.Name) then
            return hit.Parent
        end
    end

    return nil

end

return self