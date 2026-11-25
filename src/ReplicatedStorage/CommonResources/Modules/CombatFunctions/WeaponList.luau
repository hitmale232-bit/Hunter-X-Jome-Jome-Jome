
return {
	["Fists"] = {
		Type = "Unarmed",
		Effect = "Impact",
		Damage = 1,
		Speed = 1,
		Range = 4,
		Animations = {
			[1] = {Hit = "Stun1", Block = "Block1"},
			[2] = {Hit = "Stun2", Block = "Block2"},
			[3] = {Hit = "Stun1", Block = "Block1"},
			[4] = {Hit = "Knockdown1", Block = "Block2"},
			["Heavy"] = {Hit = "Knockdown1", Block = "Block1"},
			["Aerial"] = {Hit = "Knockdown1", Block = "Block1"},
		},
		Sounds = {
			["Light"] = {
				Initial = "SwingSimple",
				Attack = "ImpactSimple",
				Block = "GuardImpact",
			},
			["Heavy"] = {
				Initial = "SwingHeavy",
				Attack = "ImpactHeavy",
			},
			["Aerial"] = {
				Initial = "SwingHeavy",
				Attack = "ImpactHeavy",
			},
		},
	},	
	
	["Sword"] = {
		Type = "Sword",
		Effect = "Slash",
		Damage = 1.1,
		Speed = 0.85,
		Range = 4.25,
		Equip = {"Unsheath", "Sheathe"},
		Animations = {
			[1] = {Hit = "Stun1", Block = "Block1"},
			[2] = {Hit = "Stun2", Block = "Block2"},
			[3] = {Hit = "Stun1", Block = "Block1"},
			[4] = {Hit = "Knockdown1", Block = "Block2"},
			["Heavy"] = {Hit = "Knockdown1", Block = "Block1"},
			["Aerial"] = {Hit = "Knockdown1", Block = "Block1"},
		},
		Sounds = {
			["Light"] = {
				Initial = "SwingSimple",
				Attack = "SlashSimple",
				Block = "GuardSlash",
			},
			["Heavy"] = {
				Initial = "SwingHeavy",
				Attack = "SlashHeavy",
			},
			["Aerial"] = {
				Initial = "SwingHeavy",
				Attack = "SlashHeavy",
			},
		},
	},
	
	["Spear"] = {
		Type = "Polearm",
		Effect = "Slash",
		Damage = 1.05,
		Speed = 0.75,
		Range = 5,
		Equip = {"Unsheath", "Sheathe"},
		Animations = {
			[1] = {Hit = "Stun1", Block = "Block1"},
			[2] = {Hit = "Stun1", Block = "Block1"},
			[3] = {Hit = "Stun2", Block = "Block2"},
			[4] = {Hit = "Knockdown1", Block = "Block2"},
			["Heavy"] = {Hit = "Knockdown1", Block = "Block1"},
			["Aerial"] = {Hit = "Knockdown1", Block = "Block1"},
		},
		Sounds = {
			["Light"] = {
				Initial = "SwingSimple",
				Attack = "SlashSimple",
				Block = "GuardSlash",
			},
			["Heavy"] = {
				Initial = "SwingHeavy",
				Attack = "SlashHeavy",
			},
			["Aerial"] = {
				Initial = "SwingHeavy",
				Attack = "SlashHeavy",
			},
		},
	},
}