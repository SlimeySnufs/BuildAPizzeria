--[=[
    @class CooldownService
    @server
    @tag Service
]=]
local registry = {}
registry.__index = registry

--[=[
    @type Registry {CooldownMap: {string: number}, new: (cooldown_time: number) -> CooldownService.Registry}
    @within CooldownService
]=]
export type Registry = {
    CooldownMap: {string: number},
    CooldownTime: number,
    new: (cooldown_time: number) -> Registry,
    IsOnCooldown: (self: Registry, key: string) -> boolean,
    GetCooldownTime: (self: Registry, key: string) -> number | nil,
    StartCooldown: (self: Registry, key: string) -> boolean
}

--[=[
    @function new
    @param cooldown_time number
    @within CooldownService
    @return Registry
]=]
function registry.new(cooldown_time : number) : Registry
    local self = setmetatable({}, registry) :: Registry

    --[=[
        @prop CooldownMap {string: number}
        @within CooldownService
    ]=]
    self.CooldownMap = {}

    --[=[
        @prop CooldownTime number
        @within CooldownService
    ]=]
    self.CooldownTime = cooldown_time

    return self
end

--[=[
    @function IsOnCooldown
    @param key string
    @return boolean
    @within CooldownService
]=]
function registry:IsOnCooldown(key: string): boolean
    local cooldownEnd = self.CooldownMap[key]
    if not cooldownEnd then
        return false -- Not on cooldown
    end

    return os.time() < cooldownEnd
end

--[=[
    @function GetCooldownTime
    @param key string
    @return number | nil
    @within CooldownService
]=]
function registry:GetCooldownTime(key: string): number | nil
    return self.CooldownMap[key]
end

--[=[
    @function StartCooldown
    @param key string
    @return boolean
    @within CooldownService
]=]
function registry:StartCooldown(key: string): boolean
    if self:IsOnCooldown(key) then
        return false -- Already on cooldown
    end

    self.CooldownMap[key] = os.time() + self.CooldownTime
    return true
end

return registry