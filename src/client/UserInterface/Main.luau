--[=[
    @class UserInterface Main
    @tag UserInterface
    @client
]=]
local self = {}

--[=[
    @function Init
    Starts all of the userinterface modules in parallel for faster loading
    @within UserInterface Main
]=]
function self.Init()
    
    -- Parallelize UI component initialization for faster loading

    local Handlers = {
        script.Parent.CurrencyLabelBinder,
        script.Parent.Hider,
        script.Parent.CustomPrompts,
        script.Parent.ButtonAnimations,
        script.Parent.StateUI.Main,
        script.Parent.ButtonBinder,
    }

    for _, handler in ipairs(Handlers) do
        local success, err = pcall(function()
            if handler and handler:IsA("ModuleScript") then
                task.spawn(function()
                    handler = (require)(handler)
                    if (handler.Init) then
                        handler.Init()
                    else
                        warn(`Module {handler.Name} does not have an Init function`)
                    end
                end)
            else
                warn(`Expected ModuleScript, got {handler.ClassName} for {handler.Name}`)
            end
        end)
        if not success then
            warn(`Failed to initialize {handler.Name}: {err}`)
        else
            print(`Initialized {handler.Name} successfully`)
        end
    end

end

return self