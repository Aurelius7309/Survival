local Survival = SMODS.current_mod
Survival.config_tab = function()
    return {n = G.UIT.ROOT, config = {r = 0.1, minw = 4, align = "tm", padding = 0.2, colour = G.C.BLACK}, nodes = {
        create_option_cycle({
            label = localize('k_survival_mode'),
            scale = 0.8,
            w = 4,
            options = localize('ml_survival_opt'),
            info = {localize('k_survival_info')},
            opt_callback = 'survival_change_mode',
            current_option = Survival.config.mode or 2,
        })
}}
end
G.FUNCS.survival_change_mode = function(e)
    Survival.config.mode = e.to_key
end

local Game_init_game_object_ref = Game.init_game_object
function Game:init_game_object()
    local ret = Game_init_game_object_ref(self)
    ret.survival = Survival.config.mode
    if ret.survival >= 2 then
        ret.win_ante = 16
        ret.showdown_ante = 4
    end
    if ret.survival >= 3 then
        ret.starting_params.joker_slots = ret.starting_params.joker_slots - 2
    end
    return ret
end

local get_new_boss_ref = get_new_boss
function get_new_boss()
    local win_ante = G.GAME.win_ante
    G.GAME.win_ante = G.GAME.showdown_ante or win_ante
    local boss = get_new_boss_ref()
    G.GAME.win_ante = win_ante
    return boss
end

local to_big = to_big or function(x) return x end
local gba = get_blind_amount
function get_blind_amount(ante)
    if G.GAME.survival < 2 or (G.GAME.modifiers.scaling or 1) > 3 then return gba(ante) end
    local k = 0.75
    local amounts = {}
    if not G.GAME.modifiers.scaling or G.GAME.modifiers.scaling == 1 then
        amounts = {
            to_big(300), to_big(800), to_big(2800), to_big(6000), to_big(11000), to_big(20000), to_big(35000), to_big(50000),
            to_big(9e4), to_big(1.5e5), to_big(2.6e5), to_big(4.5e5), to_big(8e5), to_big(1.4e6), to_big(2.4e6), to_big(4.3e6)
        }
    elseif G.GAME.modifiers.scaling == 2 then
        amounts = {
            to_big(300), to_big(1000), to_big(3200), to_big(9000), to_big(18000), to_big(32000), to_big(56000), to_big(90000),
            to_big(1.8e5), to_big(4e5), to_big(1e6), to_big(2.4e6), to_big(6e6), to_big(1.6e7), to_big(4.5e7), to_big(1.4e8)
        }
    elseif G.GAME.modifiers.scaling == 3 then
        amounts = {
            to_big(300), to_big(1200), to_big(3600), to_big(10000), to_big(25000), to_big(50000), to_big(90000), to_big(1.8e5),
            to_big(4.8e5), to_big(1.6e6), to_big(6e6), to_big(2.2e7), to_big(9e7), to_big(4e8), to_big(2e9), to_big(1.2e10)
        }
    end
    if ante < 1 then return 100 end
    if ante <= 16 then return amounts[ante] end
    local a, b, c, d = amounts[16], 1.6, ante - 16, 1 + 0.2 * (ante - 16)
    local amount = math.floor(a * (b + (k * c) ^ d) ^ c)
    amount = amount - amount % (10 ^ math.floor(math.log10(amount) - 1))
    return amount
end

local set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, silent)
    set_blind_ref(self, blind, reset, silent)
    G.GAME.last_blind.showdown = blind and blind.boss and blind.boss.showdown or nil
end

local evaluate_round_ref = G.FUNCS.evaluate_round
function G.FUNCS.evaluate_round()
    evaluate_round_ref()
    if G.GAME.survival >= 3 and G.GAME.last_blind and G.GAME.last_blind.boss and G.GAME.last_blind.showdown then
        G.E_MANAGER:add_event(Event({
            func = function()
                if G.jokers then
                    G.jokers.config.card_limit = G.jokers.config.card_limit + 1
                    card_eval_status_text(G.deck.cards[1], 'extra', nil, nil, nil, {
                        message = localize { type = 'variable', key = 'ml_negative_desc', vars = {1}}[2],
                        colour = G.C.MONEY,
                        instant = true
                    })
                end
                return true
            end
        }))
    end
end
