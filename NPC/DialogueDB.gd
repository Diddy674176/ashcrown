extends RefCounted
class_name DialogueDB
## Branched dialogue trees for Len + key NPCs (Phase 3).

## Each tree: id -> { start, nodes: { id: { text, options: [{label, next, effect}] } } }
## effect keys: accept_quest | advance_quest | set_consequence | set_flag | give_item | toast | recruit_hint | end

const TREES := {
	"len_intro": {
		"title": "Magistrate Len",
		"start": "hello",
		"nodes": {
			"hello": {
				"text": "Magistrate Len: The scar alarm woke half the Gate. Concord needs eyes in the Wilds.",
				"options": [
					{"label": "I'll scout the Wilds.", "next": "accept"},
					{"label": "What exactly is the scar?", "next": "scar_lore"},
					{"label": "Not my problem.", "next": "refuse_soft"},
				],
			},
			"scar_lore": {
				"text": "Len: A Wake tear north of Ember Camp. Vein-mites and worse pour out when it sings.",
				"options": [
					{"label": "Fine — I'll scout it.", "next": "accept"},
					{"label": "Sounds like Choirbound business.", "next": "refuse_soft"},
				],
			},
			"accept": {
				"text": "Len: Kill three hostiles — or bring Ember Fiber as proof. Report back here.",
				"options": [
					{"label": "Understood.", "next": "", "effect": "accept_quest"},
				],
			},
			"refuse_soft": {
				"text": "Len: Then step aside. The Gate still burns either way.",
				"options": [
					{"label": "Leave.", "next": "", "effect": "end"},
				],
			},
		},
	},
	"len_waiting": {
		"title": "Magistrate Len",
		"start": "wait",
		"nodes": {
			"wait": {
				"text": "Len: Still waiting on that Wilds report. Three kills or Ember Fiber.",
				"options": [
					{"label": "I'm on it.", "next": "", "effect": "end"},
					{"label": "Remind me where.", "next": "hint"},
				],
			},
			"hint": {
				"text": "Len: East toward Singing Root and Ember Camp. Watch for skirmishers.",
				"options": [
					{"label": "Got it.", "next": "", "effect": "end"},
				],
			},
		},
	},
	"len_report": {
		"title": "Magistrate Len — Report",
		"start": "report",
		"nodes": {
			"report": {
				"text": "Len: You return. Speak — did the scar hold, or do we raise the Concord levy?",
				"options": [
					{"label": "Help Concord — seal the alarm.", "next": "help"},
					{"label": "Ignore it — not worth the levy.", "next": "ignore"},
					{"label": "Ask about Rook first.", "next": "rook"},
				],
			},
			"rook": {
				"text": "Len: Rook at the Inn answers to Concord favor. Help us and he'll walk with you.",
				"options": [
					{"label": "Then I'll help Concord.", "next": "help"},
					{"label": "I'll leave the scar alone.", "next": "ignore"},
				],
			},
			"help": {
				"text": "Len: Concord favor noted. Rook awaits at the Inn. Take this mail — earned.",
				"options": [
					{"label": "Accept favor.", "next": "", "effect": "consequence_helped"},
				],
			},
			"ignore": {
				"text": "Len: …So be it. The scar keeps singing. No favor. No Rook on Concord coin.",
				"options": [
					{"label": "Walk away.", "next": "", "effect": "consequence_ignored"},
				],
			},
		},
	},
	"len_done_helped": {
		"title": "Magistrate Len",
		"start": "done",
		"nodes": {
			"done": {
				"text": "Len: The Concord remembers your work. Coilcrypt still waits north if you dare.",
				"options": [
					{"label": "Understood.", "next": "", "effect": "end"},
					{"label": "Any further tasks?", "next": "more"},
				],
			},
			"more": {
				"text": "Len: Speak with Sister Cald about the Singing Root — she keeps Choirbound watch.",
				"options": [
					{"label": "I will.", "next": "", "effect": "flag_cald_hint"},
				],
			},
		},
	},
	"len_done_ignored": {
		"title": "Magistrate Len",
		"start": "cold",
		"nodes": {
			"cold": {
				"text": "Len: You chose silence on the scar. Concord doors stay half-shut.",
				"options": [
					{"label": "Leave.", "next": "", "effect": "end"},
				],
			},
		},
	},
	"sera_archive": {
		"title": "Archivist Sera",
		"start": "open",
		"nodes": {
			"open": {
				"text": "Sera: Archives open. Maps, Watch profiles, and scar notes — what do you need?",
				"options": [
					{"label": "Tell me about Ember Camp AFK.", "next": "afk"},
					{"label": "What is the scar alarm?", "next": "scar"},
					{"label": "Nothing — just browsing.", "next": "", "effect": "end"},
				],
			},
			"afk": {
				"text": "Sera: Rest the Agent at Ember Camp east of town. Profiles: EXP, Gold, Explore, Balanced. Boss stays waking-only.",
				"options": [
					{"label": "Thanks.", "next": "", "effect": "flag_sera_afk"},
					{"label": "About the scar?", "next": "scar"},
				],
			},
			"scar": {
				"text": "Sera: Len's scar alarm is a Wake tear. Helping Concord opens Rook; ignoring it cools Gate prices later.",
				"options": [
					{"label": "Noted.", "next": "", "effect": "end"},
				],
			},
		},
	},
	"cald_shrine": {
		"title": "Sister Cald",
		"start": "greet",
		"nodes": {
			"greet": {
				"text": "Sister Cald: Choirbound shrine. The Singing Root hums when the scar breathes. Leave the Core alone.",
				"options": [
					{"label": "I met Len about the scar.", "next": "len"},
					{"label": "Blessing for the road?", "next": "bless"},
					{"label": "I'll move on.", "next": "", "effect": "end"},
				],
			},
			"len": {
				"text": "Cald: Concord and Choirbound disagree on sealing. Your choice with Len echoes here.",
				"options": [
					{"label": "I helped Concord.", "next": "helped_react"},
					{"label": "I ignored the alarm.", "next": "ignored_react"},
					{"label": "Still deciding.", "next": "", "effect": "flag_met_cald"},
				],
			},
			"helped_react": {
				"text": "Cald: Then walk carefully in Coilcrypt — favor is not absolution.",
				"options": [
					{"label": "Understood.", "next": "", "effect": "flag_met_cald"},
				],
			},
			"ignored_react": {
				"text": "Cald: Silence has a cost. The Root still sings for those who listen.",
				"options": [
					{"label": "…", "next": "", "effect": "flag_met_cald"},
				],
			},
			"bless": {
				"text": "Cald: Take a Singing Root Charm — Binding leans toward those who ask gently.",
				"options": [
					{"label": "Accept charm.", "next": "", "effect": "give_root_charm"},
				],
			},
		},
	},
}

static func tree(id: String) -> Dictionary:
	if TREES.has(id):
		return TREES[id]
	return {}

static func len_tree_for_stage(stage: int, consequence: String) -> String:
	if stage <= 0:
		return "len_intro"
	if stage == 1:
		return "len_waiting"
	if stage == 2:
		return "len_report"
	if consequence == "ignored_scar":
		return "len_done_ignored"
	return "len_done_helped"
