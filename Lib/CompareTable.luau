--[=[
    @class CompareTable
    This is just a util for comparing tables to see if they are equal or not
    @tag Lib
]=]

local module = {}

--[=[
    @function IsTableSame
    A comparing function to see if two lists have the same elements
    @within CompareTable
    @return Boolean
]=]
function module.IsTableSame(tableOne : {any},tableTwo : {any}) : boolean
    
    for i , value in pairs(tableOne) do
        if tableTwo[i] ~= value then
            return false
        end
    end

    return true

end

return module