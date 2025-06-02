--[=[
    @class RandomNPC
    @shared
    @tag Lib
]=]

--[[
█░█ █▄░█ █▀█ █▀▀ ▄▄ █▀▀ █▀▀ █▄░█
▀▄▀ █░▀█ █▀▀ █▄▄ ░░ █▄█ ██▄ █░▀█
--Versatile NPC Generator | V1.0_Stable--
--Written by Mingau--

Description: This is a seed-based, easy-to-modify random NPC generator. It is versatile and can be used to create a wide variety of NPCs.

--Documentation--

[ FUNCTIONS ]
--#VNPC_Gen.NewNPC()

--Description
--This function generates a new random NPC with the following parameters.

--Parameters
All parameters are optional but can modify the way NPCs are generated.

1-Gender
	-Description: Specifies the gender of the NPC.
	-Values: "Male", "Female"
	-nil: Randomly chosen between "Male" and "Female".

2-CustomSeed
	-Description: Specifies the seed used to generate the NPC.
	-Values: Any number from 0 to 999999
	-nil: Randomly chosen seed.
	
3-FaceEnabled
	-Description: Specifies if the NPC will be applied a random face.
	-Values: true, false
	-nil: Will stay with the default face.

4-ExcludeRepetitions
	-Description: Specifies if the NPC generator will exclude repetitions of the same seed using the "NPC Registry" (the seed will only be registered for an NPC if this is set to true).
	This won't work if the seed is manually set.
	-Values: true, false
	-nil: Same as false

--Returns
1.Generated NPC model.

[ TUTORIALS ]
--#How to import custom clothing, hairs, accessories and faces?
	-Clothing, hairs, accessories and faces are all stored in the "NPC_Accessories" folder.
	-To import your own clothing, hairs, accessories and faces, follow these steps:
		1-Get the clothing or accessories you want to add (all accessories such as hair or hats MUST follow this structure: Acessory, Handle (model), Attachment)
		2-Go to the corresponding folder in NPC_Accessories (Accessories are in Hats, etc..).
		7-Drag and drop the asset into the folder.

Important note: All clothing, accessories and hats must be named 1 of the following:
"Male" for male only faces, "Female" for female only faces, or "NonSpecific" for faces that can be used for both genders.
]]

--#Settings#--
local WarningsEnabled = false

local  VNPC_Gen = {

	["Names"] = {

		["Male"] = {

			"John",
			"David",
			"Robert",
			"James",
			"Jack",
			"Michael",
			"Joseph",
			"Charles",
			"Stanley",
			"Chris",
			"Jim",
			"Jake",
			"Richard",
			"Thomas",
			"George",
			"Ethan",
			"Daniel",
			"Henry",
			"Benjamin",
			"Jacob",
			"Frederick",
			"Kevin",
			"Alexander",
			"Jason",
			"Stephen",
			"Paul",
			"Tom",
			"Douglas",
			"Nicholas",
			"Adam",
			"Brian",
			"Christopher",
			"Frank",
			"Steve",
			"Justin",
			"Carl",
			"Dan",
			"Peter",
			"Andrew",
			"Joshua",
			"Matthew"

		};

		["Female"] = {

			"Jane",
			"Mary",
			"Emma",
			"Charlotte",
			"Harper",
			"Sophia",
			"Emily",
			"Olivia",
			"Ava",
			"Megan",
			"Lauren",
			"Jennifer",
			"Amanda",
			"Ashley",
			"Sarah",
			"Jessica",
			"Elizabeth",
			"Bella",
			"Hannah",
			"Grace",
			"Evelyn",
			"Tiffany",
			"Eva",
			"Christine",
			"Joane",
			"Jenna",
			"Susan",
			"Juliet",
			"Caroline",
			"Lois",
			"Kate",
			"Catherine",
			"Hailey",
			"Kaylee",
			"Chloe",
			"Isabella",
			"Mia"

		};

	};

	["Surnames"] = {

		"Johnson",
		"Davis",
		"Wilson",
		"Williams",
		"Thompson",
		"Brown",
		"Smith",
		"Harris",
		"Martinez",
		"Taylor",
		"Evans",
		"Lee",
		"Scott",
		"Jones",
		"Gomez",
		"Rodriguez",
		"Lopez",
		"Miller",
		"Laurence",
		"Carlson",
		"Cooper",
		"Aliston",
		"Bennett",
		"Davis",
		"Adams",
		"Howard",
		"Jackson",
		"Anderson"

	};

	["NPC Registry"] = {

		["NPC_Seeds"] = {};

	};

}

local Replicated = game:GetService("ReplicatedStorage")
local Assets = Replicated.Assets
local NPC_Accessories = Assets.NPC_Accessories

function VNPC_Gen.NewNPC(Gender : ("Male" | "Female")?, CustomSeed : number?, FacesEnabled : boolean?)

	local TargetGender = nil
	local Seed = nil
	local FaceGenerationEnabled = false
	
	if FacesEnabled == true then
		
		FaceGenerationEnabled = true

	end

	if CustomSeed then

		Seed = CustomSeed

	else

		Seed = math.random(0, 999999)

	end

	local RandPseudo = Random.new(Seed)

	if Gender then
		if Gender == "Male" or Gender == "Female" then
			TargetGender = Gender
		else
			if WarningsEnabled == true then
				print("No valid gender was given")
			end
		end
	else

		TargetGender = RandPseudo:NextInteger(0, 10)
		if TargetGender >= 5 then
			TargetGender = "Male"
		else
			TargetGender = "Female"
        end
	end

	local FullName = nil
	local NameFolder = VNPC_Gen.Names[TargetGender]

	local RandomName = RandPseudo:NextInteger(1, #NameFolder)
	local RandomSurname = RandPseudo:NextInteger(1, #VNPC_Gen.Surnames)

	local Name = NameFolder[RandomName]
	local Surname = VNPC_Gen.Surnames[RandomSurname]

	FullName = Name .. " " .. Surname

	local BodyColor = RandPseudo:NextInteger(1, #NPC_Accessories.BodyColors:GetChildren())
	BodyColor = NPC_Accessories.BodyColors:GetChildren()[BodyColor]

	local HairFolder = {}
	for i, Hair in pairs(NPC_Accessories.Hairs:GetChildren()) do
		if Hair.Name == TargetGender or Hair.Name == "NonSpecific" then
			table.insert(HairFolder, Hair)
		end
	end

	local HairSelected = RandPseudo:NextInteger(1, #HairFolder)
	HairSelected = HairFolder[HairSelected]

	local HasAccessory = RandPseudo:NextInteger(0, 15)

	if HasAccessory >= 9 then
		HasAccessory = true
	else
		HasAccessory = false
	end
	
	local FaceSelected = nil
	local FaceFolder = {}
	
	if FaceGenerationEnabled == true then
		
		for i, Face in pairs(NPC_Accessories.Faces:GetChildren()) do
			if Face.Name == TargetGender or Face.Name == "NonSpecific" then
				table.insert(FaceFolder, Face)
			end
		end

		FaceSelected =  RandPseudo:NextInteger(1, #FaceFolder)
		FaceSelected = FaceFolder[FaceSelected]
		
	end
	
	local AccessorySelected = nil
	local AccessoryFolder = {}
	
	if HasAccessory == true then
		
		for i, Accessory in pairs(NPC_Accessories.Hats:GetChildren()) do
			if Accessory.Name == TargetGender or Accessory.Name == "NonSpecific" then
				table.insert(AccessoryFolder, Accessory)
            end
		end
		
		AccessorySelected =  RandPseudo:NextInteger(1, #AccessoryFolder)
		AccessorySelected = AccessoryFolder[AccessorySelected]

	end
	
	local ShirtFolder = {}
	for i, Shirt in pairs(NPC_Accessories.Shirts:GetChildren()) do
		if Shirt.Name == TargetGender or Shirt.Name == "NonSpecific" then
			table.insert(ShirtFolder, Shirt)
        end
	end
	
	local ShirtSelected = RandPseudo:NextInteger(1, #ShirtFolder)
	ShirtSelected = ShirtFolder[ShirtSelected]
	
	local PantsFolder = {}
	for i, Pants in pairs(NPC_Accessories.Pants:GetChildren()) do
		if Pants.Name == TargetGender or Pants.Name == "NonSpecific" then
			table.insert(PantsFolder, Pants)
		end
	end

	local PantsSelected = RandPseudo:NextInteger(1, #PantsFolder)
	PantsSelected = PantsFolder[PantsSelected]
	
	local NewNPC = Assets.NPC:Clone()
	NewNPC.Name = FullName

	local BodyColors = BodyColor:Clone()
	local Hair = HairSelected:Clone()
	local Accessory = nil
	local Shirt = ShirtSelected:Clone()
	local Pants = PantsSelected:Clone()

	if AccessorySelected then

		Accessory = AccessorySelected:Clone()

	end
	
	BodyColors.Parent = NewNPC
	Hair.Parent = NewNPC
	Shirt.Parent = NewNPC
	Pants.Parent = NewNPC

	if Accessory then
		Accessory.Parent = NewNPC		
	end
	
	if FaceSelected then
		local NPCFace = NewNPC:WaitForChild("Head").face
		NPCFace.Texture = FaceSelected.Texture
	end
	
	HairFolder = nil
	ShirtFolder = nil
	PantsFolder = nil
	AccessoryFolder = nil
	FaceFolder = nil

	return NewNPC

end

return VNPC_Gen