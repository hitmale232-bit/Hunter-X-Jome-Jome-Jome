
return {
	-- Vitality
	["Endurance"] = {Description = "Your tough exterior has blessed you with a body that can withstand more damage, increasing your maximum health.", 
		Cost = 1, Category = "Vitality", Requirements = {}},
	["Thick Skin"] = {Description = "In addition to increased endurance, you're able to maintain more of your movement while affected by stun.", 
		Cost = 1, Category = "Vitality", Requirements = {"Remarkable Prowess", "Endurance"}},
	["Stoicism"] = {Description = "An unwavering reaction to insignificant attacks. Weak attacks are completely shrugged off; incapable of stunning you.", 
		Cost = 1, Category = "Vitality", Requirements = {"Superhuman Prowess", "Thick Skin"}, Type = "Enhancement"},
	["Plot Armor"] = {Description = "Until you're on your last legs, you refuse to fall. You cannot be knocked down by simple M1's.", 
		Cost = 2, Category = "Physical", Requirements = {"Remarkable Prowess", "Thick Skin"}},
	["Inflated Ego"] = {Description = "Your ego knows no bounds. Damage taken is significantly dampened while your health is reasonable full.", 
		Cost = 2, Category = "Physical", Requirements = {"Superhuman Prowess", "Thick Skin"}},
	["Otherworldly Vitality"] = {Description = "Your lifeforce overflows.", 
		Cost = 4, Fee = 4000, Category = "Vitality", Requirements = {"Immense Prowess", "Thick Skin"}},
	
	-- Defense
	["Steady Footing"] = {Description = "Your footwork is far less hindered while guarding incoming attacks.", 
		Cost = 1, Category = "Physical", Requirements = {}},
	["Steadfast"] = {Description = "Underneath the shell of your defenses exists a focused mind. Attacks dealt to your guard recover your lost energy.", 
		Cost = 1, Category = "Physical", Requirements = {"Considerable Prowess", "Steady Footing"}},
	["Ironclad Defense"] = {Description = "Your ability to block attacks has become far more efficient. Incoming damage dealt through your guard is further decreased.", 
		Cost = 2, Category = "Protection", Requirements = {"Remarkable Prowess", "Steady Footing"}},
	["Exoskeleton"] = {Description = "Your fortified defenses prevent any attack from dealing more than a portion of your total health.", 
		Cost = 3, Category = "Physical", Requirements = {"Superhuman Prowess", "Ironclad Defense"}},
	["Parry"] = {Description = "Blocking right before receiving an attack will allow you to block all of it's incoming damage.", 
		Cost = 3, Category = "Special", Requirements = {"Superhuman Prowess", "Ironclad Defense"}},
	["Adamas Shell"] = {Description = "There are no blind-spots in your defense. Your block now guards from all angles.", 
		Cost = 3, Category = "Protection", Requirements = {"Superhuman Prowess", "Steady Footing"}},
	["Iron Maiden"] = {Description = "Your defense is one of a porcupine's. Attackers suffer minor damage with every attack they inflict on your guard.", 
		Cost = 4, Category = "Special", Requirements = {"Exceptional Prowess", "Adamas Shell"}},
	
	["Primate"] = {Description = "Your primal survival instinct activates near death, greatly increasing your defense and making it harder to knock you out when at low health.",
		Cost = 5, Fee = 7500, Category = "Special", Requirements = {"Immense Prowess"}},
	
	-- Stamina/Recovery
	["Lung Capacity"] = {Description = "Your lung capacity is expanded. Running out of breath will be the last of your worries in a fight.", 
		Cost = 1, Category = "Vitality", Requirements = {}},
	["Masochist"] = {Description = "Taking damage only serves to restore your energy, allowing you to spin back and deliver devastating revenge.", 
		Cost = 1, Category = "Physical", Requirements = {"Considerable Prowess", "Lung Capacity"}},
	["Aggressor"] = {Description = "Your dormant power truly surfaces under the threat of danger. Taking massive damage results in a huge temporary damage boost.", 
		Cost = 2, Category = "Carnage", Requirements = {"Remarkable Prowess", "Masochist"}},
	["Iron Soul"] = {Description = "You seem to be at your best during a pinch. Mortality causes your blood to flow, allowing you to tap into Awakened Force.", 
		Cost = 2, Category = "Carnage", Requirements = {"Superhuman Prowess", "Aggressor"}},
	["Blessed by the Heart"] = {Description = "The stars shine down on you. Near-death encounters net additional experience.",
		Cost = 4, Fee = 1500, Category = "Special", Requirements = {"Exceptional Prowess", "Iron Soul"}},
	["Fast Metabolism"] = {Description = "Your hunger drain is decreased.", 
		Cost = 1, Fee = 1, Requirements = {}}, -- troll fee lolololxd
	
	-- Concentrated Breaths
	["Concentrated Breathing"] = {Description = "No breath will be wasted. Simply by standing still and utilizing a specific breathing pattern, energy regeneration will increase far faster than normal.", 
		Cost = 2, Category = "Vitality", Requirements = {"Lung Capacity"}},
	["Concentrated Breathing: Recovery"] = {Description = "Building on the fundamentals of Concentrated Breathing, standing still now doubles your health regeneration.", 
		Cost = 2, Category = "Technical", Requirements = {"Considerable Prowess", "Concentrated Breathing"}},
	["Breathing Technique"] = {Description = "Your breathing exercises have reached the next level. Enhancement technique energy costs are cut in half.", 
		Cost = 3, Category = "Technical", Requirements = {"Considerable Prowess", "Concentrated Breathing"}},
	
	-- Strength
	["Brute Force"] = {Description = "Slightly increased physical attack damage.", 
		Cost = 1, Category = "Physical", Requirements = {"Considerable Prowess"}},
	["Iron Muscles"] = {Description = "Let loose heavy attacks with real power behind them. Deal significantly more heavy damage.", 
		Cost = 2, Category = "Physical", Requirements = {"Superhuman Prowess", "Brute Force"}},
	["Slumber"] = {Description = "Knocked foes remain down for longer.",
		Cost = 1},
	["Underdog"] = {Description = "Deal slightly more damage to those stronger than you.",
		Cost = 1, Category = "Physical", Requirements = {"Considerable Prowess"}},
	["Otherworldly Strength"] = {Description = "You wield limitless power.", 
		Cost = 4, Fee = 4000, Category = "Special", Requirements = {"Immense Prowess", "Iron Muscles"}},
	
	-- Brawler
	["Devastating Attack"] = {Description = "More of your outgoing damage penetrates through your opponents guard.", 
		Cost = 1, Category = "Physical", Requirements = {"Considerable Prowess"}},
	["Violent Rush"] = {Description = "Breaking an opponents guard restores all lost energy.", 
		Cost = 2, Category = "Physical", Requirements = {"Remarkable Prowess", "Devastating Attack"}},
	["Constant Flux"] = {Description = "Chaining light attacks makes you stronger.", 
		Cost = 3, Category = "Special", Requirements = {"Remarkable Prowess", "Violent Rush"}, Type = "Active"},
	["Devourer"] = {Description = "Your strikes carry the essence of a predator. Each blow has a chance to siphon the life of your enemy, restoring your strength through their suffering.", 
		Cost = 5, Fee = 5000, Category = "Special", Requirements = {"Immense Prowess", "Otherworldly Strength"}, Type = "Active"},
	
	-- Tactician
	["Tactical Scan"] = {Description = "A detailed analysis into your opponent allows you to peer into their weaknesses, granting a temporary damage boost against others.", 
		Cost = 2, Category = "Technical", Requirements = {}, Type = "Active"},
	["Gladiator"] = {Description = "Fighting multiple opponents at once enables a temporary boost in power, evening the playing-field.", 
		Cost = 2, Category = "Technical", Requirements = {"Considerable Prowess", "Tactical Scan"}, Type = "Active"},
	["Total Concentration"] = {Description = "Removing all unnecessary thoughts (including defense) from your mind, you proceed with a quick, yet devastating attack that deals massive damage.", 
		Cost = 3, Category = "Special", Requirements = {"Remarkable Prowess", "Tactical Scan"}, Type = "Active"},
	
	-- Speed
	["Athleticism"] = {Description = "Your new running style maximizes speed and efficiency, allowing you to go farther, faster.", 
		Cost = 1, Category = "Physical", Requirements = {}},
	["Evasive Maneuver"] = {Description = "Perform a backflip when back-dashing, increasing distance and escaping incoming attacks.", 
		Cost = 2, Category = "Physical", Requirements = {"Considerable Prowess", "Athleticism"}},
	["Olympian Trackstar"] = {Description = "You've pushed your speed beyond all limits.", 
		Cost = 2, Category = "Physical", Requirements = {"Remarkable Prowess", "Athleticism"}},
	["Otherworldly Speed"] = {Description = "Your speed knows no bounds.", 
		Cost = 4, Fee = 4000, Category = "Special", Requirements = {"Immense Prowess", "Olympian Trackstar"}},
	["Light Feet"] = {Description = "You move on your toes. Strafing speed is significantly increased.", 
		Cost = 2, Category = "Physical", Requirements = {"Considerable Prowess", "Athleticism"}},
	["Conditioned Legs"] = {Description = "Shrug off the pain that would otherwise hinder your movements. Health has much less of an impact on your speed.", 
		Cost = 2, Category = "Physical", Requirements = {"Remarkable Prowess", "Athleticism"}},
	["Marathoner's Heart"] = {Description = "There is nothing stopping you. Extended periods of running increase your sprinting speed considerably.", 
		Cost = 3, Category = "Physical", Requirements = {"Conditioned Legs"}},
	
	-- Evasion
	["Swift Comeback"] = {Description = "The effects of failing a dodge are significantly dampened.", 
		Cost = 1, Category = "Physical", Requirements = {"Considerable Prowess"}},
	["Twinkle Toes"] = {Description = "Gain a short burst of speed after successfully dodging an attack.", 
		Cost = 2, Category = "Physical", Requirements = {"Considerable Prowess", "Swift Comeback"}},
	["Whirlwind"] = {Description = "Successfully dodging an attack completely removes it's cooldown, allowing you to get back into the fight.", 
		Cost = 2, Category = "Physical", Requirements = {"Remarkable Prowess", "Swift Comeback"}},
	["Unreal Reflexes"] = {Description = "While active, your dodge window is increased.", 
		Cost = 3, Category = "Special", Requirements = {"Exceptional Prowess", "Twinkle Toes"}, Type = "Enhancement"},
	["Momentum Buildup"] = {Description = "Dodging attacks builds up momentum, granting a temporary boost in your own physical attack power.", 
		Cost = 3, Category = "Technical", Requirements = {"Superhuman Prowess", "Swift Comeback"}},
	["Spinning Counter"] = {Description = "A counter that takes the opportunity after dodging an attack to leave one of your own.", 
		Cost = 3, Category = "Attack", Requirements = {"Superhuman Prowess", "Momentum Buildup"}, Type = "Active"},
	["Weave Master"] = {Description = "Recover half of the energy used from dodging an attack back after successfully pulling off a dodge.", 
		Cost = 2, Category = "Technical", Requirements = {"Momentum Buildup"}},
	["Way of the Weave"] = {Description = "Recover a small portion of your health back after successfully dodging an attack.", 
		Cost = 3, Category = "Special", Requirements = {"Exceptional Prowess", "Weave Master"}},
	["Ultra Instinct"] = {Description = "The ultimate technique that severs the consciousness from the body in order to allow the body to subconsciously move it to even attack and evade, you can automatically dodge up to 3 attacks consecutively.",
		Cost = 4, Category = "Special", Requirements = {"Immense Prowess", "Way of the Weave"}, Type = "Enhancement"}, 
	
	-- Medicine
	["Medical Analysis"] = {Description = "With just a glance, you can determine the current condition of others — indicated by a health gauge.", 
		Cost = 1, Fee = 50, Category = "Scientific", Requirements = {}},
	["Trained Doctor"] = {Description = "You've become very diligent and responsible for keeping your supplies stocked. Medical Kits no longer run out.", 
		Cost = 3, Category = "Scientific", Requirements = {"Considerable Prowess", "Medical Analysis"}},
	["Doctor's Analysis"] = {Description = "With the use of Medical Notes, the specifics of an individual's physical attributes can be read in an easily digestible form.", 
		Cost = 3, Category = "Scientific", Requirements = {"Remarkable Prowess", "Trained Doctor"}},
	["Field Medic"] = {Description = "Unconscious allies can now be woken up using a Medical Kit.", 
		Cost = 2, Category = "Scientific", Requirements = {"Considerable Prowess", "Trained Doctor"}},
	["Self-Aid"] = {Description = "Your mastery of first-aid now allows you to use medicine on yourself (Right-click).", 
		Cost = 2, Category = "Scientific", Requirements = {"Remarkable Prowess", "Medical Analysis"}},
	["Master Doctor"] = {Description = "Your medkit healing speed has greatly increased.", 
		Cost = 3, Category = "Scientific", Requirements = {"Exceptional Prowess", "Self-Aid", "Soothing Presence"}},
	["Convalescent"] = {Description = "Natural health regeneration is vastly increased.", 
		Cost = 3, Category = "Special", Requirements = {"Exceptional Prowess", "Self-Aid"}},
	
	-- Therapy
	["Therapeutic"] = {Description = "Talking to others very slowly mends insanity and rebuilds a bit of their livelihood.", 
		Cost = 1, Category = "Miscellaneous", Requirements = {}},
	["Soothing Presence"] = {Description = "Friends in your presence slowly recover some of their livelihood.", 
		Cost = 2, Category = "Miscellaneous", Requirements = {"Therapeutic"}},
	["Blessed by the Stars"] = {Description = "There is an air around you that draws people in. It's almost as if the universe itself is assisting you.", 
		Cost = 4, Fee = 1750, Category = "Special", Requirements = {"Exceptional Prowess", "Soothing Presence"}},
	
	-- Personality
	["Lethal Blow"] = {Description = "An attack launched with murderous intent behind it, capable of ending another person's life.", 
		Cost = 3, Category = "Attack", Requirements = {"Considerable Prowess"}, Type = "Active"},
	["Bloodlust"] = {Description = "Killing another person restores all of your health.", 
		Cost = 2, Category = "Carnage", Requirements = {"Remarkable Prowess", "Lethal Blow"}},
	["Carnage"] = {Description = "Taking another individual's life inflicts massive insanity to surrounding individuals.", 
		Cost = 2, Category = "Carnage", Requirements = {"Remarkable Prowess", "Bloodlust"}},
	
	-- Leadership
	["Enemy Spotted"] = {Description = 'Shouting the phrase "there" will briefly highlight all visible players.',
		Cost = 2, Requirements = {"Remarkable Prowess"}},
	
	--[[ Utility skills
	["Leap"] = {Description = "A simple strengthened jump. Sending you high into the air.", 
		Cost = 1, Requirements = {"Considerable Prowess"}, State = "Active"},
	["Stone Toss"] = {Description = "Thrown stones will automatically aim at anyone close to wherever you're aiming.", 
		Cost = 1, State = "Active"},
	["Pitcher's Arm"] = {Description = "Throw 3 stones rather than 1.", 
		Cost = 21, Requirements = {"Stone Toss"}},]]
	
	-- Misc.
	["Backup Plan"] = {Description = "Never let opponents get the jump on you. Equip an extra active skill and completely overwhelm them.",
		Cost = 1, Category = "Technical", Requirements = {}},
	["Well Rested"] = {Description = "Regain consciousness with more health.",
		Cost = 1, Category = "Miscellaneous", Requirements = {}},
	["Conqueror"] = {Description = "Knocking an opponent restores considerably more health.", 
		Cost = 1, Category = "Carnage", Requirements = {"Remarkable Prowess"}},
	["Weak Coward"] = {Description = "Health affects movement speed significantly less.",
		Cost = 2, Requirements = {"Considerable Prowess"}},
	["Shonen Stomach"] = {Description = "Increased maximum stomach.",
		Cost = 1, Requirements = {"Considerable Prowess"}},
	["Full Counter"] = {Description = "Blocking someone's light attack allows you to punish them if fast enough.",
		Cost = 4, Requirements = {"Immense Prowess"}},
	["Unbreakable Will"] = {Description = "After being block broken, the next attack to hit you deals reduced damage.",
		Cost = 2, Requirements = {"Remarkable Prowess"}},
	
	-- Races
	["Exorcism"] = {Description = "Deal additional damage to yokais.",
		Cost = 1, Category = "Miscellaneous", Requirements = {"Awakened Inner Hue"}},
	["Malevolent Personality"] = {Description = "You deal more damage to humans.",
		Cost = 1, Category = "Miscellaneous", Requirements = {"Awakened Inner Hue"}},
	
	-- Roblox Chat/Msgs
	["Human Speech"] = {Description = "You can now understand the languages used by Humans.",
		Cost = 1, Category = "Special", Requirements = {}},
	["Cursed Speech"] = {Description = "You can now understand the languages used by Yokais.",
		Cost = 1, Category = "Special", Requirements = {}},
	
	-- Hue Support
	["Solipsis"] = {Description = "Reality is a construct before your mind. By deliberately tricking our own minds, we can actualize the undoing of physical injuries.",
		Cost = 1, Category = "Special", Requirements = {"Exceptional Proficiency", "Refined Aura"}, Type = "Active"},
	["Reverse Curse Technique"] = {Description = "You can now regenerate mortal injuries and absurd wounds.",
		Cost = 2, Category = "Special", Requirements = {"Incredible Proficiency", "Refined Aura", "Solipsis"}, Type = "Active"},
	["Deepsight"] = {Description = "This technique allows one to gauge their opponent's general output, highlighting their flow and making them visible from a distance.",
		Cost = 2, Category = "Energy", Requirements = {"Remarkable Proficiency"}, Type = "Active"},
	["See Through World"] = {Description = "The mastered version of Deepsight, See Through World.",
		Cost = 2, Category = "Energy", Requirements = {"Incredible Proficiency", "Deepsight"}, Type = "Active"},
	--[[["Hue: Transfer"] = {Description = "A technique granting the user the ability to transfer their Hue energy to another.", 
		Cost = 2, Requirements = {"Refined Aura", "Mental Tranquility"}, State = "Active"},]]
	["World Pulse"] = {Description = "The Eye that sees all.", 
		Cost = 3, Category = "Energy", Requirements = {"See Through World", "Deepsight"}, Type = "Active"},
	
	-- Hue Manipulation
	["Mental Tranquility"] = {Description = "Naturally regain Hue at a faster rate.",
		Cost = 2, Category = "Energy", Requirements = {"Considerable Proficiency"}},
	["Flow State"] = {Description = "Hue output ramps up when below half health.", 
		Cost = 2, Requirements = {"Mental Tranquility"}},
	["Barrier Layer"] = {Description = "Employ an additional layer of power on top of your already enhanced fortitude.",
		Cost = 2, Category = "Energy", Requirements = {"Remarkable Proficiency", "Full Release"}},
	["Refined Aura"] = {Description = "Refined Aura increases the upper limit of your aura output — allowing the fruits of your training to bloom.",
		Cost = 3, Category = "Energy", Requirements = {"Remarkable Proficiency", "Barrier Layer"}},
	["Cloaking"] = {Description = "Dissopates the flow of surrounding aura — keeping you hidden while simultaneously providing a faster recovery rate.",
		Cost = 1, Category = "Energy", Requirements = {"Considerable Prowess"}, Type = "Active"},
	["Hotspring"] = {Description = "By freeing your mind and entering something of a trance, you allow your aura to recollect at a rapid pace.",
		Cost = 3, Category = "Energy", Requirements = {"Polished Proficiency", "Cloaking"}, Type = "Active"},
	["Infusion"] = {Description = "Infuses physical attacks with additional Hue energy at the moment right before impact.",
		Cost = 2, Category = "Attack", Requirements = {"Remarkable Proficiency"}, Type = "Enhancement"},
	["Disrupting Fang"] = {Description = "A technique designed by Toni of the Zeven clan to counter the Hue of her enemies. By simply landing an attack enhanced with Infusion, your enemies aura will be incrementally sapped away.",
		Cost = 3, Category = "Energy", Requirements = {"Polished Proficiency", "Infusion"},
		Clan = "Zeven"},
	["Blessed by the Sparks"] = {Description = "Your Hue is painted with an odd, distorted tint. Unleashing a Critical Flash is far more common than it is for others.",
		Cost = 4, Fee = 2000, Category = "Special", Requirements = {"Exceptional Proficiency", "Infusion"}},
	["Glowing Lantern"] = {Description = "A suspended capsule of aura that cuts a portion of the your power off and stores the energy for later use.",
		Cost = 3, Category = "Attack", Requirements = {"Remarkable Proficiency"}, Type = "Active",
		Clan = "Springfield"},
	["Channeled Colors"] = {Description = "By condensing aura to it's limit and firing it in a single direction, you're able to create a powerful blast of concentrated energy.",
		Cost = 4, Category = "Special", Requirements = {"Incredible Proficiency"}, Type = "Active",
		Clan = "Springfield"},
	["Spiritual Pressure"] = {Description = "Releasing your aura sends a dominating pressure down the spines of those around you.", 
		Cost = 3, Category = "Attack", Requirements = {"Full Release", "Immense Prowess"}, Type = "Active"},
	
	-- Release Forms
	["Perfect Release: Hatsu"] = {Description = "Hatsu reflects a person’s natural aura type and determines how they can express their power — like creating or manipulating energy in unique ways.",
		Cost = 4, Fee = 3000, Category = "Attack", Requirements = {"Immense Prowess"}, Type = "Enhancement"},
	["Perfect Release"] = {Description = "The final form of full release. Perfect Release is the technique of using and controlling one’s life energy at it's limits, it's full potential.",
		Cost = 3, Fee = 2000, Category = "Attack", Requirements = {"Superhuman Proficiency"}, Type = "Active"},
	["Full Release"] = {Description = "A more aggressive form of Release. At the cost of greater energy consumption, you can expand more of your total power at once, further boosting your combat capabilities.",
		Cost = 2, Category = "Attack", Requirements = {"Remarkable Proficiency"}, Type = "Active"},
	
	-- Ninjutsu 
	["Shinobi Gait"] = {Description = "Your footsteps are hushed and your passive movement speed is increased.", 
		Cost = 2},
	
	-- Blending skills
	["Leg Breaker"] = {Description = "Leg Breaker deals damage directly to your opponents legs with each use; lowering their mobility.",
		Cost = 2, Fee = 850, Category = "Attack", Requirements = {"Considerable Prowess"},  Type = "Active"},	
	
	-- Fist skills
	["Triple Kick"] = {Description = "A technique to close the gap swiftly and deliver three powerful kicks in rapid succession to overwhelm your opponent.",
		Cost = 2, Requirements = {"Remarkable Prowess"}, Type = "Active",},
	["Headbutt Package"] = {Description = "A dizzying assault of headbutts, aimed at catching even the strongest of foes off-guard.", 
		Cost = 2, Fee = 1500, Category = "Attack", Requirements = {"Remarkable Prowess"}, Type = "Active"},
	["Dragon Rush"] = {Description = "An assault of melee attacks that allow you to pressure and push back opponents.",
		Cost = 3, Fee = 900, Category = "Attack", Requirements = {"Superhuman Prowess"},  Type = "Active"},
	["Knee Release"] = {Description = "Release your knees and utilize the momentum into a powerful kick; dodging incoming blows while attacking.", 
		Cost = 2, Fee = 759, Category = "Attack", Requirements = {"Remarkable Prowess"},  Type = "Active"},
	["Double Impact"] = {Description = "An reverse punch focused on catching an opponent off-guard and dealing two blows at once.", 
		Cost = 3, Fee = 1000, Category = "Attack", Requirements = {"Superhuman Prowess"}, Type = "Active"},
	["Air Strike"] = {Description = "An attack taking advantage of your opponents blindspot by striking from above.",
		Cost = 2, Fee = 450, Category = "Attack", Requirements = {"Superhuman Prowess"},  Type = "Active"},
	["Dragon Claw"] = {Description = "By focusing all of your strength to build up in one punch, you deliver a strategic punch into your opponent.",
		Cost = 2, Fee = 650, Category = "Attack", Requirements = {"Remarkable Prowess"},  Type = "Active"},
	["Feather Fists"] = {Description = "Enhances your m1 and m2 attack speed.",
		Cost = 2, Fee = 500, Category = "Attack", Requirements = {"Considerable Prowess"},  Type = "Active"},
	
	["Negation"] = {Description = "Your strikes reject the essence of Hue itself, bypassing its defensive properties and rendering its protection ineffective.", --why are we making stoicism v2
		Cost = 4, Fee = 1500, Category = "Attack", Requirements = {"Superhuman Prowess"},  Type = "Active"}, -- touch = demote (ant spec)
	
	-- Sword skills
	["Backstabber"] = {Description = "Damage inflicted on an opponents blind-spot is increased.", 
		Cost = 1, Category = "Technical", Requirements = {"Considerable Prowess"}},
	["Swordsman's Resolve"] = {Description = "Truly a remarkable feat, you are a master of the sword, a Pilgrim Knight.", -- An attacked executed with swiftness and precision. The damage dealt corrolates with your target's current condition.", 
		Cost = 2, Category = "Technical", Requirements = {"Remarkable Prowess"}},
	["The King's Royal Knight"] = {Description = "You've once been the Knight of Fittoa's King, a most trustworthy swordsman.", -- this Increases Sword Speed :P oh shii
		Cost = 2, Category = "Technical", Requirements = {"Remarkable Prowess", "Swordsman's Resolve"}},
	["Viper Slash"] = {Description = "A draw-style technique focused on catching your opponent off guard with it's delayed slashes.", 
		Cost = 2, Fee = 1000, Category = "Attack", Requirements = {"Remarkable Prowess"}, Type = "Active"},
	["Finishing Slay"] = {Description = "A powerful an instant display of strength, dealing gradually more and more damage to weakened enemies and serving as a finishing blow.", 
		Cost = 3, Fee = 1350, Category = "Attack", Requirements = {"Superhuman Prowess"}, Type = "Active"},
	["Bird's Slash"] = {Description = "You've learned how to carve the air with your blade, allowing your slashes travel short distances.", 
		Cost = 3, Fee = 1500, Category = "Attack", Requirements = {"Superhuman Prowess"}, Type = "Active"},
	["Wicker Basket"] = {Description = "Utilizing the force generated from your slashes, you can unleash an attack that deals rapid damage to those within the area of effect.", 
		Cost = 2, Fee = 1000, Category = "Attack", Requirements = {"Exceptional Prowess"}, Type = "Active"},
	["Hollowpoint Strike"] = {Description = "A precise technique that takes advantage of defensive opponents, dealing considerably more damage to those with their guards actively raised.", 
		Cost = 2, Category = "Attack", Requirements = {"Superhuman Prowess"}, Type = "Active"},
	
	-- Spear skills
	["Prince's Chosen"] = {Description = "The Prince is truly thankful of your quick reflexes and great services, he choses you as his strongest spearman.", -- spear m1 speed buff
		Cost = 2, Category = "Attack", Requirements = {"Considerable Prowess"}},
	["Skewer"] = {Description = "Execution of a precise spear thrust; utilizing the entire weapon for extended reach and brutally pulling the enemy closer into range.",
		Cost = 2, Fee = 1000, Category = "Attack", Requirements = {"Remarkable Prowess"}, Type = "Active"},
	["Plunge"] = {Description = "By propelling yourself into the air, you crash down from above with tremendous force, striking the ground with great strength.",
		Cost = 2, Fee = 1350, Category = "Attack", Requirements = {"Exceptional Prowess"}, Type = "Active"},
	
	-- Shadow Step
	["Shadow Step"] = {Description = "By momentarily pushing the muscles in your legs to their absolute limit, you can burst forward in a blur, seemingly vanishing from sight.",
		Cost = 2, Category = "Physical", Requirements = {"Remarkable Prowess"}},
	["Shadow Step: Improved Agility"] = {Description = "The pinnacle of Shadow Step. You now move significantly faster while using it and gain brief invulnerability to most attacks immediately after activation.",  
		Cost = 3, Category = "Physical", Requirements = {"Superhuman Prowess", "Shadow Step"}},
	["Shadow Step: Raven Bane"] = {Description = "An offensive use of Shadow Step that allows the user to step into incoming attacks, helping to close distance with the target.",
		Cost = 3, Fee = 800, Category = "Physical", Requirements = {"Superhuman Prowess", "Shadow Step"}, Type = "Enhancement"},
	["Shadow Step: Crow Genjutsu"] = {Description = "Automatically execute Shadow Step after successfully evading an opponent’s attack.",
		Cost = 3, Fee = 800, Category = "Special", Requirements = {"Exceptional Prowess", "Shadow Step"}, Type = "Enhancement"},
	
	
	-- Clans Only Stuff n Buffs
	["Mental Limit Break"] = {Description = "The ability to go beyond your limits whenever the conditions are met.",
		Cost = 999, Category = "Special", Requirements = {}, Type = "Active", 
		Clan = "Vandal", Locked = true},
	["Eight Gates"] = {Description = "Applies rotational force to one's Lion Bear Fist techniques, increasing their attack damage, knockback, and strafing speed.",
		Cost = 4, Fee = 2500, Category = "Special", Requirements = {}, Type = "Active",
		Clan = "Lee", Locked = true},
	["Total Concentration: Constant"] = {Description = "Your stamina regen is grealy increased.", 
		Cost = 999, Category = "Special", Requirements = {}},
	["Psychological Limit Break"] = {Description = "Your full potential has been obtained. You can now surpass your limits at will.",
		Cost = 999, Category = "Special", Requirements = {"The Honored One", "The Chosen One"}, Type = "Active", Locked = true},
	
	-- Black Flashes
	["Black Flash"] = {Description = "The true essence of a Black Flash Merchant, disgusting.",
		Cost = 25, Fee = 100000, Category = "Special", Requirements = {}, Type = "Active", Locked = true},
	
	-- SPECS OR UNOBS DONT TOUCH
	["Six Eyes"] = {Description = "The Six Eyes allow for the extremely precise manipulation of hue, down to an atomic level. This not only allows the bearer to operate the Limit Break through complex control of hue but enables them to process it with extraordinary efficiency as well. The amount of hue loss when a bearer uses hue manipulation skills is small, making it impossible for them to run out of hue reserve.",
		Cost = 999, Fee = 1000000, Category = "Energy", Requirements = {"The Honored One", "The Chosen One"}, Locked = true}, -- dont touch or demote delxue only
	["Yokai Lord's Fear"] = {Description = "Humans get passive insanity when being near you for a certain period of time.",
		Cost = 999, Fee = 100000, Category = "Special", Requirements = {"Devil", "True Yokai"}, Type = "Enhancement"},
	["Yokai Lord's Influence"] = {Description = "Humans get much more insanity when killing near you.",
		Cost = 999, Fee = 100000, Category = "Special", Requirements = {"Devil", "True Yokai"}, Type = "Enhancement"},
	
	-- DONT TOUCH SPECS
	["Special Grade : Inventory Curse"] = {Description = "A special yokai spirit sealed inside you, further improving your limits of knowledge. God's Plan.. Wasn't it?",
		Cost = 999, Fee = 1000000, Category = "Technical", Requirements = {}, Locked = true},
	
	["Emulate"] = {Description = "Getting hit by a player will give you their last used active ability.",
		Cost = 999, Category = "Special", Requirements = {}, Type = "Active", Locked = true},
	
	-- PORTALS
	["Garganta"] = {Description = "The portal to the other world, connecting Limbo to the Asura city", -- YOKAIS WILL SPAWN WITH THAT
		Cost = 999, Category = "Special", Requirements = {}, Type = "Active", Locked = true},
}