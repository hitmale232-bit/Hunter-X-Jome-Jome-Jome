local ServerResources = game.ServerScriptService.ServerResources

local SkillLibrary = require(ServerResources.Modules.SkillLibrary)

local dialogSet = {
	Initial = {"wanna learn a cool tip for fighting tough opponents?"},

	Elaborate1 = {
		"remember to position yourself carefully when readying attacks",
		"your footwork plays a much larger role in a fight than you might think",
	},
	Elaborate2 = {
		"it's very easy to throw off multiple opponents",
		"just switch targets randomly!",
	},
	Elaborate3 = {
		"sometimes you won't always have the ability to dodge",
		"but don't forget that you also have the option to guard",
	},
	Elaborate4 = {
		"you don't always have to run around while fighting someone",
		"if you opt to slowly pace yourself then you can recover a ton of stamina very quickly",
	},
	
	Finish1 = {"just remember that whenever you're in a pinch"},
	Finish2 = {"give it a try whenever you get the chance"},
	Finish3 = {"take care friend"},
}

local module = {}

function module:GetDialog(speaker, player, relationship, modifier)
	if relationship >= 2 then
		local random = Random.new(modifier):NextInteger(1, 3)
		return dialogSet["Finish"..random], false
	elseif relationship >= 1 then
		local random = Random.new(modifier):NextInteger(1, 4)
		if random == 1 and math.random() <= 0.25 then
			SkillLibrary:Give(player, "Light Feet")
		elseif random == 2 and math.random() <= 0.25 then
			SkillLibrary:Give(player, "Gladiator")
		elseif random == 3 and math.random() <= 0.25 then
			SkillLibrary:Give(player, "Ironclad Defense")
		elseif random == 4 and math.random() <= 0.25 then
			SkillLibrary:Give(player, "Concentrated Breathing")
		end
		return dialogSet["Elaborate"..random], true
	end
	return dialogSet.Initial, true
end

return module