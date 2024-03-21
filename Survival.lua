--- STEAMODDED HEADER
--- MOD_NAME: Survival Mode
--- MOD_ID: Survival
--- MOD_AUTHOR: [Aure]
--- MOD_DESCRIPTION: This mod adds two new game modes: Survival and Survival+. In both modes, the game is extended to last for 16 Antes, with final Boss Blinds every 4 Antes. Ante scaling from Ante 9 to Ante 16 have been adjusted by varying amounts depending on stake. On Survival+ mode, you start with 2 less joker slots, but gain an additional joker slot after defeating a final Boss Blind.

----------------------------------------------
------------MOD CODE -------------------------

function SMODS.INIT.Survival()
    local Game_init_game_object_ref = Game.init_game_object
    function Game:init_game_object()
        local GAME = Game_init_game_object_ref(self)
        if G.survival or G.survival_plus then
            GAME.win_ante = 16
            GAME.showdown_ante = 4
        end
        if G.survival_plus then
            GAME.survival_plus = true
            GAME.starting_params.joker_slots = 3
        end
        return GAME
    end

    local get_new_boss_ref = get_new_boss
    function get_new_boss()
        local win_ante = G.GAME.win_ante
        G.GAME.win_ante = G.GAME.showdown_ante or win_ante
        local boss = get_new_boss_ref()
        G.GAME.win_ante = win_ante
        return boss
    end

    function get_blind_amount(ante)
        local k = 0.75
        local amounts = {}
        if not G.GAME.modifiers.scaling or G.GAME.modifiers.scaling == 1 then
            amounts = {
                300, 800, 2800, 6000, 11000, 20000, 35000, 50000,
                90000, 150000, 260000, 450000, 800000, 1400000, 2400000, 4300000
            }
        elseif G.GAME.modifiers.scaling == 2 then
            amounts = {
                300, 1000, 3200, 9000, 18000, 32000, 56000, 90000,
                180000, 400000, 1000000, 2400000, 6000000, 16000000, 45000000, 135000000
            }
        elseif G.GAME.modifiers.scaling == 3 then
            amounts = {
                300, 1200, 3600, 10000, 25000, 50000, 90000, 180000,
                480000, 1600000, 6000000, 22000000, 90000000, 400000000, 2000000000, 12000000000
            }
        end
        if ante < 1 then return 100 end
        if ante <= 16 then return amounts[ante] end
        local a, b, c, d = amounts[16], 1.6, ante - 16, 1 + 0.2 * (ante - 16)
        local amount = math.floor(a * (b + (k * c) ^ d) ^ c)
        amount = amount - amount % (10 ^ math.floor(math.log10(amount) - 1))
        return amount
    end
end


	function G.FUNCS.change_survival(args)
		G.survival = args.to_key == 2
		G.survival_plus = args.to_key == 3
	end

local run_setup_option_ref = G.UIDEF.run_setup_option
function G.UIDEF.run_setup_option(type)
	local t = run_setup_option_ref(type)
	if type == 'New Run' then
		--t.nodes[5] = t.nodes[4]
		t.nodes[5] = create_option_cycle({
			options = {
				'Off',
				'Survival',
				'Survival+'
            },
			label = 'Survival Mode',
			cycle_shoulders = true,
			opt_callback = 'change_survival',
            current_option = G.survival_plus and 3 or G.survival and 2 or 1,
            scale = 0.8,
			w = 4
		})
	end
	return t
end

local set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, silent)
	set_blind_ref(self, blind, reset, silent)
    G.GAME.last_blind.showdown = blind and blind.boss and blind.boss.showdown or nil
end

local evaluate_round_ref = G.FUNCS.evaluate_round
function G.FUNCS.evaluate_round()
	evaluate_round_ref()
	if G.GAME.survival_plus and G.GAME.last_blind and G.GAME.last_blind.boss and G.GAME.last_blind.showdown then
		G.E_MANAGER:add_event(Event({
			func = function()
                if G.jokers then
                    G.jokers.config.card_limit = G.jokers.config.card_limit + 1
                end
				return true
			end
		}))
	end
end

----------------------------------------------
------------MOD CODE END----------------------
