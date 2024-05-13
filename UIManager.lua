--!native

--[=[

    filenmame: Manager.lua
    runcontext: module/client
    description: Handles the opening/closing of UI elements and loading of all UI Scripts.

]=]

local Manager = {}
Manager.CurrentlyOpen = nil;

-- [=[ SERVICES ]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- [=[ PACKAGES ]=]

local Hierarchy = require(script.Parent.Hierarchy);
local Effects = require(script.Parent.Effects);

-- [=[ ASSETS ]=]

local Player = Players.LocalPlayer;
local GUI : PlayerGui = Player.PlayerGui;
local Root : Hierarchy.Root = GUI.Root;

local HUD : Frame = Root.HUD;
local Buttons : Folder = Root.Buttons;
local Frames : Folder = Root.Frames;

-- [=[ FUNCTIONS ]=]

--[=[

    function Initialize:

    description: Called by the main client script, when the player has loaded.

]=]

function Manager.Initialize()
    for _, v : ImageButton in ipairs(Buttons:GetChildren()) do
        if v:IsA("ImageButton") then
            local BaseSize : UDim2 = v.Size;

            v.MouseEnter:Connect(function(x, y)
                Effects.ScaledBasedOnPercentage(v, 0.15, 1.15)
            end)
        
            v.MouseLeave:Connect(function(x, y)
                Effects.Scale(v, 0.15, BaseSize)
            end)
        
            v.Activated:Connect(function(inputObject, clickCount)
                Manager.OpenFrame(v.Name)
            end)
        end
    end
end

--[=[

    function OpenFrame:

        @param           clicked             string             Name of the tab the player wants to open.

    description: Called when the player clicks on a UI Button.

]=]

function Manager.OpenFrame(clicked : string)
    
    local Frame = Frames:FindFirstChild(clicked)

    -- Case 1: No other frame is currently opened.

    if Manager.CurrentlyOpen == nil then

        Manager.CurrentlyOpen = Frame
        Frame.Visible = true

    -- Case 2: Frame opened is the same, so close it.

    elseif Manager.CurrentlyOpen == Frame then

        Frame.Visible = false
        Manager.CurrentlyOpen = nil

    -- Case 3: Frame opened is different, so close the old one and open the new one.

    elseif Manager.CurrentlyOpen ~= nil and Manager.CurrentlyOpen ~= Frame then

        Manager.CurrentlyOpen.Visible = false
        Manager.CurrentlyOpen = Frame
        Frame.Visible = true

    end
end

return Manager