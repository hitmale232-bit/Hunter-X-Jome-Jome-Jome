
--[[ 

price ranges

200-600 introduction/basic skill (like endurance)
800-1000 general passive skill that grants a cool buff
1000-2500 build defining passive
1000-3000 active skill (depends on rank)

skillpoint ranges

0 for essential skills
1 for generic passive skilsl
2-3 for build defining passive skills
3-4 for active skills
5 for powerful/legendary skills

]]--

-- TODO: give all skills an ID so i can change/add/remove skill names

return {
	-- Physique-based skill
	-- Durable
	["Endurance"] = {Description = "Increased durability and maximum energy.", 
		Cost = 430, CostSP = 1, Requirements = {"Considerable Prowess"}},
	["Stoicism"] = {Description = "You tend to shrug off the effects of weaker attacks. Status elements also don't hinder you as much.", 
		Cost = 575, CostSP = 1, Requirements = {"Endurance", "Remarkable Prowess"}},
	["Otherworldly Vitality"] = {Description = "Wield the vitality of the titans. Greatly increases durability.", 
		Cost = 2025, CostSP = 3, Requirements = {"Endurance", "Immense Prowess"}},
	
	-- Iron Maiden
	["Steadfast"] = {Description = "Blocking attacks now converts pain into adrenaline, restoring lost energy.", 
		Cost = 515, CostSP = 1, Requirements = {"Considerable Prowess"}},
	["Ironclad Defense"] = {Description = "Take significantly less chip-damage while guarding.", 
		Cost = 1225, CostSP = 2, Requirements = {"Steadfast", "Remarkable Prowess"}},
	["Adamas Shell"] = {Description = "Your defense includes no blind-spots.",
		Cost = 2200, CostSP = 3, Requirements = {"Ironclad Defense", "Exceptional Prowess"}},
	["Masochist"] = {Description = "Taking damage restores energy.",
		Cost = 835, CostSP = 1, Requirements = {"Steadfast", "Superhuman Prowess"}},
	["Restless"] = {Description = "Being guardbroken replenshes all energy and provides a brief damage boost.", 
		Cost = 1675, CostSP = 3, Requirements = {"Masochist", "Superhuman Prowess"}},
	
	-- Beastly
	["Devastating Strength"] = {Description = "More of your damage chips through your opponents guard.", 
		Cost = 915, CostSP = 1, Requirements = {"Remarkable Prowess"}},
	["Violent Rush"] = {Description = "Breaking an opponents guard restores all lost energy.", 
		Cost = 1005, CostSP = 2, Requirements = {"Devastating Strength", "Remarkable Prowess"}},
	["Iron Muscles"] = {Description = "Heavy attacks deal significantly more damage.", 
		Cost = 1675, CostSP = 3, Requirements = {"Devastating Strength", "Superhuman Prowess"}},
	["Heavy Hitter"] = {Description = "Increased physical attack damage.", 
		Cost = 1975, CostSP = 3, Requirements = {"Devastating Strength", "Superhuman Prowess"}},
	
	-- Agility-based skills
	-- Quick
	["Athletic Stride"] = {Description = "Grants increased sprinting speed.",
		Cost = 450, CostSP = 1, Requirements = {"Considerable Prowess"}},
	["Quick Feet"] = {Description = "Increased speed boost after successfully dodging an attack.", 
		Cost = 885, CostSP = 2, Requirements = {"Athletic Stride", "Remarkable Prowess"}},
	
	-- Untouchable
	["Level-Headed"] = {Description = "Decreased cooldown after failing a dodge.", 
		Cost = 915, CostSP = 2, Requirements = {"Remarkable Prowess"}},
	["Whirlwind"] = {Description = "Successfully dodging an attack completely removes it's cooldown.", 
		Cost = 1195, CostSP = 3, Requirements = {"Level-Headed", "Remarkable Prowess"}},
	["Way of the Weave"] = {Description = "Recover some health after successfully dodging an attack.", 
		Cost = 2015, CostSP = 4, Requirements = {"Level-Headed", "Superhuman Prowess"}},	
	["Weave Master"] = {Description = "Receive half of the drained energy back after successfully pulling off a dodge.", 
		Cost = 1565, CostSP = 3, Requirements = {"Way of the Weave", "Superhuman Prowess"}},
	-- Psyche-based skills
	-- Medicine
	["Recovery"] = {Description = "Standing still initiates healing.", 
		Cost = 500, CostSP = 1, Requirements = {"Considerable Prowess"}},
	["Medical Analysis"] = {Description = "With just a glance, you can determine the current condition of others — indicated by a health gauge.", 
		Cost = 1120, CostSP = 2, Requirements = {"Recovery", "Remarkable Prowess"}, State = "Active"},
	["First Aid"] = {Description = "You can now apply first aid on yourself (left-click) and others (right-click).", 
		Cost = 1245, CostSP = 2, Requirements = {"Medical Analysis", "Remarkable Prowess"}, State = "Active"},
	["Convalescent"] = {Description = "Natural health regeneration is greatly increased.",
		Cost = 2225, CostSP = 4, Requirements = {"First Aid", "Immense Prowess"}},
	
	-- Charisma
	["Soothing Presence"] = {Description = "Players in your presence slowly recover some of their lost livelihood.",
		Cost = 1040, CostSP = 2, Requirements = {"Considerable Prowess"}},
	["Therapy"] = {Description = "Talking to others slowly mends insanity.",
		Cost = 1105, CostSP = 2, Requirements = {"Remarkable Prowess"}},
	
	-- Leadership
	["Commanding Authority: Spotted"] = {Description = 'Shouting the phrase "there" will briefly highlight all visible players.',
		Cost = 1040, CostSP = 2, Requirements = {"Remarkable Prowess"}},
	
	-- Sadistic
	["Stress Relief"] = {Description = "Knocking opponents restores some Hue.", 
		Cost = 915, CostSP = 1, Requirements = {"Awakened Inner Hue", "Remarkable Prowess"}},
	["Conqueror"] = {Description = "Knocking out opponents restores slightly more health.", 
		Cost = 1505, CostSP = 2, Requirements = {"Stress Relief", "Superhuman Prowess"}},
	
	-- Hue-based skills
	-- Basic Hue Techniques
	["Hue: Cloaking"] = {Description = "Cloaking halts the natural flow of Hue, granting the user stealth and increased recovery, at the cost of defense.", 
		Cost = 485, CostSP = 1, Requirements = {"Awakened Inner Hue"}, State = "Active"},
	["Hue: Deepsight"] = {Description = "Deepsight is a Hue technique that enhances the senses, allowing them to detect and measure Hue far more easily.", 
		Cost = 850, CostSP = 2, Requirements = {"Awakened Inner Hue"}, State = "Active"},
	["Hue: Full Release"] = {Description = "Burns through heavy amounts of Hue to greatly enhance one's physical attributes.", 
		Cost = 505, CostSP = 2, Requirements = {"Basic Hue Proficiency"}, State = "Active"},
	["Intimidating Exterior"] = {Description = "Releasing your aura sends a dominating pressure down the spines of those around you.", 
		Cost = 500, CostSP = 0, Requirements = {"Hue: Full Release", "Adept Hue Proficiency", "Adept Hue Volume"}},
	
	-- Advanced Hue Techniques
	["Hue: Reverse Domain"] = {Description = "Simple Domain is an attack created by Yuzu Zeven to counter domains without establishing one's own.", 
		Cost = 1020, CostSP = 2, Requirements = {"Adept Hue Proficiency"}, State = "Active"},
	["Hue: Solipsis"] = {Description = "", 
		Cost = 2210, CostSP = 4, Requirements = {"Great Hue Proficiency", "Recovery"}},
	
	-- Sparking Hue
	["Hue: Infusion"] = {Description = "Infuses physical attacks with additional Hue energy at the moment right before impact.", 
		Cost = 2100, CostSP = 2, Requirements = {"Adept Hue Proficiency"}, State = "Active"},
	--["Critical-Flash Attack"] = {Description = ""},
	["Blessed by the Sparks"] = {Description = "Grants increased chance to land a critical-flash.", -- and slightly stronger Hue: Infusion
		Cost = 4000, CostSP = 4, Requirements = {"Adept Hue Proficiency", "Hue: Infusion"}},
	
	-- Aura Flow
	["Calm Flow"] = {Description = "Hue regenerates slightly faster.", 
		Cost = 570, CostSP = 1, Requirements = {"Basic Hue Proficiency"}},
	["Flow State"] = {Description = "Hue output ramps up when below half health.", 
		Cost = 815, CostSP = 2, Requirements = {"Calm Flow", "Adept Hue Proficiency"}},
	["Refined Fundamentals"] = {Description = "You took the time to master the fundamentals of Hue, now all basic techniques drain significantly less.", 
		Cost = 1165, CostSP = 2, Requirements = {"Calm Flow", "Great Hue Proficiency"}},
	["Barrier Layer"] = {Description = "Applies an extra coating of Hue around one's body, repelling slightly more damage coming your way.", 
		Cost = 1240, CostSP = 2, Requirements = {"Refined Fundamentals"}},
	["Hue: Transfer"] = {Description = "A technique granting the user the ability to transfer their Hue energy to another.", 
		Cost = 1715, CostSP = 2, Requirements = {"Refined Fundamentals"}, State = "Active"},
	["Hue: Hotspring"] = {Description = "Hue: Hotspring is a Hue replenishment technique, channeling energy into one's Hue pool.", 
		Cost = 2100, CostSP = 2, Requirements = {"Refined Fundamentals"}, State = "Active"},
	
	-- Miscellaneous skills
	["Well-Rested"] = {Description = "Recover from being knocked out with extra health.", 
		Cost = 1005, CostSP = 2},
	["Slumberrr"] = {Description = "Knocked foes remain down for longer.",
		Cost = 800, CostSP = 1},
	["Underdog"] = {Description = "Deal slightly more damage to those stronger than you.",
		Cost = 910, CostSP = 1},
	["Airborne"] = {Description = "Light attacks launched in midair deal increased damage.",
		Cost = 722, CostSP = 1},
	["Shonen Stomach"] = {Description = "Increased maximum stomach.",
		Cost = 655, CostSP = 1},
	["Slow Metabolism"] = {Description = "Hunger drain is decreased.",
		Cost = 725, CostSP = 1},
	["Exorcism"] = {Description = "Damage towards Yokai is increased.",
		Cost = 885, CostSP = 1},
	["Strategic Withdrawl"] = {Description = "Health affects movement speed significantly less.",
		Cost = 1085, CostSP = 2, Requirements = {"Considerable Prowess"}},
	
	["Spinning Counter"] = {Description = "Take the opportunity after dodging an attack to leave one of your own.",
		Cost = 1100, CostSP = 2, Requirements = {"Exceptional Prowess"}},
	["Adrenaline Rush"] = {Description = "Low health causes a surge of adrenaline, granting increased energy regeneration alongside a slight damage boost.", 
		Cost = 800, CostSP = 2, Requirements = {"Remarkable Prowess"}}, -- has a cooldown
	["Malevolent Personality"] = {Description = "Your cold demeanor allows you to coat your attacks in bloodlust, granting extra attack damage.",
		Cost = 905, CostSP = 2},
	["Multi-tasking Proficiency"] = {Description = "Energy regeneration is increased by x1.5 when fighting multiple opponents.",
		Cost = 1025, CostSP = 2, Requirements = {"Considerable Prowess"}},
	["Mythical Presence"] = {Description = "You're surrounded by an unknown presence.", -- Grants various small passives
		Cost = 4000, CostSP = 4},
	
	-- Form techniques (toggle passives, but lower max energy)
	["Constant Flux"] = {Description = "Chaining attacks together gradually (but temporarily) increases their damage potential.",
		Cost = 885, CostSP = 1, Requirements = {"Considerable Prowess"}},
	["Concentrated Breathing"] = {Description = "Attack skills use slightly less energy.", 
		Cost = 1005, CostSP = 2, Requirements = {"Remarkable Prowess"}},
	["Unreal Reflexes"] = {Description = "While active, your dodge window is increased.",
		Cost = 1205, CostSP = 2, Requirements = {"Superhuman Prowess"}, State = "Active"},
	["In-Fighter Step"] = {Description = "While active, melee attacks teleport you to nearby enemies.",
		Cost = 1505, CostSP = 3, Requirements = {"Superhuman Prowess"}, State = "Active"},
	
	-- Shadow Step techniques
	["Shadow Step"] = {Description = "A technique focused on channeling your strength into your leg muscles, allowing the user to move at unreal speeds.", 
		Cost = 1200, CostSP = 2, Requirements = {"Athletic Stride", "Remarkable Prowess"}},
	["Shadow Step: Raven Bane"] = {Description = "An offensive application of Shadow Step, utilizing it's momentum to increase their attack power. Gradually saps the user's leg strength.", 
		Cost = 2000, CostSP = 2, Requirements = {"Shadow Step", "Superhuman Prowess"}, State = "Active"},
	["Shadow Step: Improved Agility"] = {Description = "The pinnicle of the Shadow Step techniques. This technique allows the user to move at their max speed.", 
		Cost = 2085, CostSP = 3, Requirements = {"Shadow Step", "Exceptional Prowess"}},
	["Shadow Step: Crow Genjutsu"] = {Description = "Applies a variation of Shadow Step immediately following a dodge.",
		Cost = 2405, CostSP = 3, Requirements = {"Shadow Step: Improved Agility", "Superhuman Prowess"}},	
	
	-- Utility skills
	["Leap"] = {Description = "A simple strengthened jump. Sending you high into the air.", 
		Cost = 455, CostSP = 0, Requirements = {"Considerable Prowess"}, State = "Active"},
	["Stone Toss"] = {Description = "Thrown stones will automatically aim at anyone close to wherever you're aiming.", 
		Cost = 605, CostSP = 1, State = "Active"},
	["Pitcher's Arm"] = {Description = "Throw 3 stones rather than 1.", 
		Cost = 800, CostSP = 1, Requirements = {"Stone Toss"}},
	
	-- Fist skills
	--["Stallion's Kick"] = {Description = "Landing unarmed aerial attacks restores some health.", -- might change to be some kind of active
	--	Cost = 655, CostSP = 1, Requirements = {"Iron Muscles", "Superhuman Prowess"}},
	["Knee Release"] = {Description = "Release your knees and utilize the momentum into a powerful kick; dodging incoming blows while attacking.",
		CostSP = 2, Requirements = {"Superhuman Prowess"}, Type = "Active"},
	["Devouring Fist"] = {Description = "Landing unarmed light attacks restores a small amount of health.", 
		Cost = 1995, CostSP = 2, Requirements = {"Superhuman Prowess"}},
	["Headbutt Package"] = {Description = "A brutal combination of fierce headbutts. Deals considerable damage to even the strongest enemies.",
		CostSP = 2, Requirements = {"Remarkable Prowess"}, Type = "Active"},	
	
	-- Sword skills
	["Backstab"] = {Description = "Increased damage when attacking an opponents back. How dishonorable...", 
		Cost = 800, CostSP = 1, Requirements = {"Considerable Prowess"}},
	["Royal Swordsmanship"] = {Description = "You've reached a state of swordsmanship many only dream of achieving. All sword skills deal increased damage.", 
		Cost = 1225, CostSP = 2, Requirements = {"Remarkable Prowess"}},
	["Viper Slash"] = {Description = "An swift draw-style technique, that deals delayed damage to whomever is cut by it.", 
		Cost = 1800, CostSP = 2, Requirements = {"Superhuman Prowess"}, State = "Active"},
	["Finishing Slay"] = {Description = "A powerful finishing blow.1`	qq0 Lethal when used on an unconscious opponent", 
		Cost = 2105, CostSP = 3, Requirements = {"Superhuman Prowess"}, State = "Active"},
	["Bird's Slash"] = {Description = "You've learned how to carve the air with your blade, allowing your slashes travel short distances.",
		CostSP = 2, Requirements = {"Remarkable Prowess"}, Type = "Active"},
	["Bird's Slash: Spiral Hawk"] = {Description = "An upgraded version of Bird Soar which slashes opponents to ribbons dealing even greater damage.",
		CostSP = 2, Requirements = {"Bird Soar", "Superhuman Prowess"}, Type = "Active"},
	["Bird's Slash: Spiral Phoenix"] = {Description = "The highest level of the Bird Soar technique, even catching fire due to the friction of the slash.",
		CostSP = 3, Requirements = {"Bird Soar: Spiral Hawk", "Superhuman Prowess"}, Type = "Active"},
	
	["SAMPLE TEXT2"] = {Description = "Air slash.", 
		Cost = 1350, CostSP = 1, Requirements = {"Remarkable Prowess"}},
	["Spiraling Hawk"] = {Description = "An advanced technique utilizing the fundamentals of SAMPLE TEXT2 and furthering them. Drilling through anyone along it's path.", 
		Cost = 1600, CostSP = 2, Requirements = {"Superhuman Prowess"}, State = "Active"},
	["Spiraling Phoenix"] = {Description = "A variation of Spiraling Hawk that set everything in it's path aflame due to the explosive friction of the curve.", 
		Cost = 2850, CostSP = 3, Requirements = {"Spiraling Hawk", "Exceptional Prowess"}},
	
	-- Spear/Polearm skills
	["Prince's Chosen"] = {Description = "Enter a form that employs one's dexterity to increase the speed of the their attacks.",
		Cost = 800, CostSP = 1},
	
	-- Ninjutsu
	["Shinobi Gait"] = {Description = "Your footsteps are hushed and your passive movement speed is increased.", 
		Cost = 600, CostSP = 2},
	["Kunai Throw"] = {Description = "Rather than throwing rocks, you throw kunai knives.", 
		Cost = 850, CostSP = 2, Requirements = {"Stone Toss", "Remarkable Prowess"}},
	["Ninjutsu: Blinding Ash"] = {Description = "A smokescreen attack that blinds all those within the range of the attack.", 
		Cost = 950, CostSP = 2, Requirements = {"Considerable Prowess"}, State = "Active"},
	["Ninjutsu: Dragon's Whistle"] = {Description = "The user claps their hands in such a way that a high-frequency sound is caused, slightly damaging and slowing anyone near them.", 
		Cost = 925, CostSP = 2, Requirements = {"Remarkable Prowess"}, State = "Active"},
	
	-- Lion Bear Fist
	["Raionkuma: Footwork"] = {Description = "The foundation of all Raionkuma techniques. Utilizing this footwork slightly increases offensive and defensive potential.", 
		Cost = 2450, CostSP = 2, Requirements = {"Considerable Prowess"}},
	["Raionkuma: Vortex Fist"] = {Description = "A powerful reverse punch that twists at the location of impact, causing immense pain to the victim over time.", 
		Cost = 1955, CostSP = 2, Requirements = {"Raionkuma: Footwork", "Remarkable Prowess"}, State = "Active"},
	["Raionkuma: Eight Gates"] = {Description = "Applies rotational force to one's Lion Bear Fist techniques, increasing their attack damage, knockback, and strafing speed.", 
		Cost = 2100, CostSP = 3, Requirements = {"Raionkuma: Footwork", "Superhuman Prowess"}, State = "Active"},
	
	-- World King Fist
	["Kaioken: Attack"] = {Desciption = "Rush forward tackling your opponent.",
		Cost = 1950, CostSP = 2, Requirements = {"Remarkable Prowess"}},
	--["Kaioken: Dragon Fist"] = {Desciption = "Rush forward tackling your opponent.",
	--	Cost = 2105, CostSP = 2, Requirements = {"Superhuman Prowess"}},
	
	-- Zeven Clan Techniques
	["Zeven Technique: Disrupting Fang"] = {Description = "Landing attacks drains a small amount of an opponent's Hue.", 
		Cost = 4450, CostSP = 2, Requirements = {"Refined Fundamentals", "Immense Hue Proficiency"}},
	["Zeven Technique: Limit Break"] = {Description = "The passive upper limit of Hue enhancement is increased.", 
		Cost = 4570, CostSP = 3, Requirements = {"Refined Fundamentals", "Immense Hue Proficiency"}, State = "Active"},
}
