
local module = {}
local dialogSet = {
	Initial = {
		"bro.. everybody knows &fusion& is way cooler than &fusion2&!",
	},
}
local fusions = {
	"Gogeta",
	"Vegito"
}
function module:GetDialog(speaker, player, relationship, modifier)
	local fusion = fusions[math.random(1, 2)]
	dialogSet.Initial[1] = dialogSet.Initial[1]:gsub("&fusion&", string.lower(fusion))
	dialogSet.Initial[1] = dialogSet.Initial[1]:gsub("&fusion2&", fusion == "Gogeta" and "vegito" or "gogeta")
	return dialogSet.Initial, false
end

return module