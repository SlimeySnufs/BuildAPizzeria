local Main = {}

--[=[
    @class SceneUI Main
    @tag Scenes
    @client
]=]

--[=[
    @function Init
    Initializes the SceneUI components
    @within SceneUI Main
]=]

function Main.Init()
    -- Initialize the Computer Store Buttons
    require(script.Parent.ComputerStoreButtons).Init()
end

return Main