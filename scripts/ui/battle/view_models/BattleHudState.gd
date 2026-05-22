extends RefCounted
class_name BattleHudState


const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const SlotViewData = preload("res://scripts/ui/battle/view_models/SlotViewData.gd")


var target_score: int = 0
var current_score: int = 0
var reward_level: String = "$$$$"
var core_combo_name: String = str(TranslationServer.translate(&"AUTO.TEXT.53E2DB70167F"))
var core_combo_level: int = 0
var combo_display_visible: bool = false
var final_score_display_visible: bool = false
var base_chips: int = 0
var base_mult: int = 0
var xmult: float = 1.0
var formula_score: int = 0
var money: int = 0
var rerolls_left: int = 0
var rerolls_total: int = 0
var current_hand: int = 0
var max_hands: int = 0
var battle_number: int = 1
var max_battles: int = 1
var circle_base_score: int = 0
var danger_bonus_percent: int = 0
var circle_action_count: int = 0
var relic_capacity: int = 6
var item_capacity: int = 3
var max_selected_dice: int = 0
var relics: Array[SlotViewData] = []
var items: Array[SlotViewData] = []
var dice_results: Array[DieViewData] = []
var selected_dice_indices: Array[int] = []
var score_log: Array[String] = []
var preview_text: String = ""
var status_text: String = ""
var phase_text: String = ""
var controls_locked: bool = false
var info_button_locked: bool = false
var options_button_locked: bool = false
var can_reroll: bool = false
var can_score: bool = false
