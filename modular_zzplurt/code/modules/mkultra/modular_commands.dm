//SPLURT ADDITION START
// Modular MKUltra command extensions live here to avoid patching upstream command tables.

// Active follow states keyed by enthralled mob -> state data.
var/global/list/mkultra_follow_states = list()
// Self-call states keyed by enthralled mob -> allowed/self name list.
var/global/list/mkultra_selfcall_states = list()
// Signal sink used for global mkultra helpers.
var/global/datum/mkultra_signal_handler/mkultra_signal_handler = new
// Toggleable debug logging.
var/global/mkultra_debug_enabled = TRUE
// Toggle to disable command cooldowns during testing.
var/global/mkultra_disable_cooldowns = TRUE
// Slot keyword lookup for targeted stripping.
/proc/mkultra_add_cooldown(datum/status_effect/chem/enthrall/enthrall_chem, amount)
	if(!enthrall_chem)
		return
	if(mkultra_disable_cooldowns)
		return
	enthrall_chem.cooldown += amount

// TEMP: debug phase setter for quick testing. Remove after QA.
/proc/process_mkultra_command_debug_phase(message, mob/living/user, list/listeners, power_multiplier)
	if(!mkultra_debug_enabled)
		return FALSE
	var/lowered = lowertext(message)
	var/idx = findtext(lowered, "mkdebug phase")
	if(!idx)
		idx = findtext(lowered, "mkultra phase")
	if(!idx)
		return FALSE
	var/digits = trim(replacetext(copytext(lowered, idx + length("mkdebug phase") + 1), ".", ""))
	var/desired = text2num(digits)
	if(!isnum(desired))
		mkultra_debug("phase debug skip: invalid number")
		return FALSE
	var/target_phase = desired
	// Clamp to known phase bounds (1 = in progress, 4 = overdose enthralled).
	if(target_phase < 1)
		target_phase = 1
	if(target_phase > 4)
		target_phase = 4

	var/handled = FALSE
	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem)
			continue
		if(enthrall_chem.enthrall_mob != user)
			continue

		enthrall_chem.phase = target_phase
		enthrall_chem.cooldown = 0
		mkultra_debug("phase debug: set [humanoid] to phase [target_phase]")
		to_chat(humanoid, "<span class='notice'>A debug pulse forces your enthrallment to phase [target_phase].</span>")
		to_chat(user, "<span class='notice'><i>You set [humanoid]'s phase to [target_phase].</i></span>")
		handled = TRUE

	return handled
var/global/list/mkultra_strip_slot_lookup = list(
	"head" = ITEM_SLOT_HEAD,
	"hat" = ITEM_SLOT_HEAD,
	"helmet" = ITEM_SLOT_HEAD,
	"mask" = ITEM_SLOT_MASK,
	"mouth" = ITEM_SLOT_MASK,
	"face" = ITEM_SLOT_MASK,
	"eyes" = ITEM_SLOT_EYES,
	"glasses" = ITEM_SLOT_EYES,
	"goggles" = ITEM_SLOT_EYES,
	"ears" = ITEM_SLOT_EARS,
	"ear" = ITEM_SLOT_EARS,
	"earpiece" = ITEM_SLOT_EARS,
	"neck" = ITEM_SLOT_NECK,
	"tie" = ITEM_SLOT_NECK,
	"collar" = ITEM_SLOT_NECK,
	"suit" = ITEM_SLOT_OCLOTHING,
	"coat" = ITEM_SLOT_OCLOTHING,
	"jacket" = ITEM_SLOT_OCLOTHING,
	"armor" = ITEM_SLOT_OCLOTHING,
	"uniform" = ITEM_SLOT_ICLOTHING,
	"jumpsuit" = ITEM_SLOT_ICLOTHING,
	"clothes" = ITEM_SLOT_ICLOTHING,
	"under" = ITEM_SLOT_ICLOTHING,
	"gloves" = ITEM_SLOT_GLOVES,
	"hands" = ITEM_SLOT_GLOVES,
	"shoes" = ITEM_SLOT_FEET,
	"boots" = ITEM_SLOT_FEET,
	"feet" = ITEM_SLOT_FEET,
	"belt" = ITEM_SLOT_BELT,
	"back" = ITEM_SLOT_BACK,
	"backpack" = ITEM_SLOT_BACK,
	"bag" = ITEM_SLOT_BACK,
	"id" = ITEM_SLOT_ID,
	"pda" = ITEM_SLOT_ID,
	"pocket" = ITEM_SLOT_POCKETS,
	"pockets" = ITEM_SLOT_POCKETS,
	"left pocket" = ITEM_SLOT_LPOCKET,
	"right pocket" = ITEM_SLOT_RPOCKET,
	"storage" = ITEM_SLOT_SUITSTORE,
	"suit storage" = ITEM_SLOT_SUITSTORE,
)

// Handlers are registered via the global list in modular_zubbers/mkultra/vocal_cords.dm.

/proc/mkultra_debug(message)
	if(!mkultra_debug_enabled)
		return
	world.log << "["MKULTRA"] [message]"



/proc/process_mkultra_command_cum(message, mob/living/user, list/listeners, power_multiplier)
	// Returns TRUE if this handler consumed the command, FALSE otherwise.
	var/static/regex/cum_words = regex("cum|orgasm|finish for me|climax")
	if(!findtext(message, cum_words))
		return FALSE
	mkultra_debug("cum command matched by [user] -> [listeners.len] listeners")

	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("cum skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || enthrall_chem.phase < 2)
			mkultra_debug("cum skip [humanoid]: missing/low enthrall (phase=[enthrall_chem?.phase])")
			continue
		if(!enthrall_chem.lewd)
			addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='warning'>You feel the command, but it fizzles—this isn't the kind of obedience you're opted in for.</span>"), 5)
			mkultra_debug("cum skip [humanoid]: not lewd opt-in")
			continue

		var/success = humanoid.climax(FALSE, user)
		if(success)
			mkultra_add_cooldown(enthrall_chem, 12)
			mkultra_debug("cum success on [humanoid] by [user]")
			addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='love'>Your lower body tightens as you are compelled to climax for [(enthrall_chem.lewd? enthrall_chem.enthrall_gender : enthrall_chem.enthrall_mob)].</span>"), 5)
			to_chat(user, "<span class='notice'><i>You command [humanoid] to finish, and they obey.</i></span>")
		else
			mkultra_debug("cum failed on [humanoid] by [user]")
			addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='warning'>You try to obey, but your body refuses to climax.</span>"), 5)

	return TRUE


/proc/process_mkultra_command_selfcall(message, mob/living/user, list/listeners, power_multiplier)
	// Lewd-only speech self-name enforcement: "selfcall pet" (single name; commas allowed but optional).
	var/lowered = lowertext(message)
	var/prefix = "selfcall "
	var/static/regex/selfcall_off_words = regex("selfcall off|selfcall stop|clear selfcall")
	if(findtext(lowered, selfcall_off_words))
		// Let the off handler consume it instead of binding "off" as a name.
		return FALSE
	if(!findtext(lowered, prefix))
		return FALSE
	var/raw_names = trim(copytext(message, length(prefix) + 1))
	if(!raw_names)
		mkultra_debug("selfcall skip: empty name list")
		return FALSE
	var/list/name_list = list()
	for(var/part in splittext(raw_names, ","))
		var/clean = trim(part)
		// Drop trailing punctuation like "." so we don't store literal punctuation.
		while(length(clean))
			var/last_char = copytext(clean, -1)
			if(last_char == "." || last_char == "," || last_char == "!" || last_char == "?")
				clean = copytext(clean, 1, length(clean))
				continue
			break
		if(length(clean))
			name_list += clean
	if(!name_list.len)
		mkultra_debug("selfcall skip: no parsed names from '[raw_names]'")
		return FALSE

	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("selfcall skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || !enthrall_chem.lewd || enthrall_chem.phase < 2)
			mkultra_debug("selfcall skip [humanoid]: invalid enthrall (lewd=[enthrall_chem?.lewd] phase=[enthrall_chem?.phase])")
			continue
		if(enthrall_chem.enthrall_mob != user)
			mkultra_debug("selfcall skip [humanoid]: enthraller mismatch (has=[enthrall_chem.enthrall_mob] wanted=[user])")
			continue

		mkultra_apply_selfcall(humanoid, name_list)
		mkultra_add_cooldown(enthrall_chem, 3)
		var/listing = name_list.Join(", ")
		addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='notice'>Your self-reference is confined to: [listing].</span>"), 5)
		to_chat(user, "<span class='notice'><i>You bind [humanoid]'s self-name to: [listing].</i></span>")

	return TRUE


/proc/process_mkultra_command_emote(message, mob/living/user, list/listeners, power_multiplier)
	// Lewd-only emote command: "<emote> for me". Uses the standard emote datum list.
	var/lowered = lowertext(message)
	var/marker = " for me"
	var/idx = findtext(lowered, marker)
	if(!idx)
		return FALSE
	var/emote_text = trim(copytext(message, 1, idx))
	if(!length(emote_text))
		return FALSE
	mkultra_debug("emote command '[message]' matched as [emote_text] by [user]")

	var/emote_key = LOWER_TEXT(emote_text)
	if(!(emote_key in GLOB.emote_list))
		return FALSE

	var/handled = FALSE
	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("emote skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || !enthrall_chem.lewd || enthrall_chem.phase < 2)
			mkultra_debug("emote skip [humanoid]: invalid enthrall (lewd=[enthrall_chem?.lewd] phase=[enthrall_chem?.phase])")
			continue

		humanoid.emote(emote_key, null, null, FALSE, TRUE, FALSE)
		mkultra_add_cooldown(enthrall_chem, 6)
		mkultra_debug("emote [emote_key] applied to [humanoid] by [user]")
		addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='love'>You are compelled to *[emote_key] for [enthrall_chem.enthrall_gender].</span>"), 5)
		to_chat(user, "<span class='notice'><i>[humanoid] performs *[emote_key] on command.</i></span>")
		handled = TRUE

	return handled


/proc/process_mkultra_command_strip_slot(message, mob/living/user, list/listeners, power_multiplier)
	// Targeted strip: "strip <slot>". Always consume once matched to prevent base strip double fire.
	var/lowered = lowertext(message)
	var/prefix = "strip "
	if(!findtext(lowered, prefix))
		return FALSE
	var/slot_text = trim(copytext(message, length(prefix) + 1))
	if(!slot_text)
		return TRUE
	mkultra_debug("strip command '[message]' raw slot '[slot_text]' from [user]")
	// Drop simple articles.
	for(var/article in list("your ", "my ", "the "))
		slot_text = replacetext(slot_text, article, "")
	slot_text = trim(slot_text)

	var/slot_id = mkultra_resolve_strip_slot(slot_text)
	if(!slot_id)
		mkultra_debug("strip slot resolution failed for '[slot_text]'")
		return TRUE

	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("strip skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || !enthrall_chem.lewd || enthrall_chem.phase < 2)
			mkultra_debug("strip skip [humanoid]: invalid enthrall (lewd=[enthrall_chem?.lewd] phase=[enthrall_chem?.phase])")
			continue
		if(enthrall_chem.enthrall_mob != user)
			mkultra_debug("strip skip [humanoid]: enthraller mismatch (has=[enthrall_chem.enthrall_mob] wanted=[user])")
			continue

		var/obj/item/to_drop = mkultra_strip_item_for_slot(humanoid, slot_id)
		if(!to_drop)
			mkultra_debug("strip found nothing in [mkultra_slot_name(slot_id)] on [humanoid]")
			continue
		mkultra_debug("strip dropping [to_drop] from [humanoid] slot [mkultra_slot_name(slot_id)]")
		mkultra_add_cooldown(enthrall_chem, 4)
		to_chat(user, "<span class='notice'><i>You command [humanoid] to strip [mkultra_slot_name(slot_id)], and they comply.</i></span>")
		addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='love'>You obediently remove your [mkultra_slot_name(slot_id)].</span>"), 5)

	// Always consume so base handler doesn't also strip.
	return TRUE

/proc/process_mkultra_command_lust_up(message, mob/living/user, list/listeners, power_multiplier)
	// Lewd-only arousal increase.
	var/static/regex/lust_up_words = regex("get horny|feel horny|get wetter|get harder|feel hotter|aroused")
	if(!findtext(message, lust_up_words))
		return FALSE
	mkultra_debug("lust up command from [user]")

	var/handled = FALSE
	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("lust up skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || !enthrall_chem.lewd || enthrall_chem.phase < 2)
			mkultra_debug("lust up skip [humanoid]: invalid enthrall (lewd=[enthrall_chem?.lewd] phase=[enthrall_chem?.phase])")
			continue
		if(enthrall_chem.enthrall_mob != user)
			mkultra_debug("lust up skip [humanoid]: enthraller mismatch (has=[enthrall_chem.enthrall_mob] wanted=[user])")
			continue

		humanoid.adjust_arousal(8)
		mkultra_add_cooldown(enthrall_chem, 3)
		mkultra_debug("lust up applied to [humanoid] (+8)")
		addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='love'>Heat floods your body at [enthrall_chem.enthrall_gender]'s command.</span>"), 5)
		to_chat(user, "<span class='notice'><i>[humanoid] flushes as you stoke their lust.</i></span>")
		handled = TRUE

	return handled

/proc/process_mkultra_command_lust_down(message, mob/living/user, list/listeners, power_multiplier)
	// Lewd-only arousal decrease.
	var/static/regex/lust_down_words = regex("calm down|cool off|less horny|settle down|compose yourself")
	if(!findtext(message, lust_down_words))
		return FALSE
	mkultra_debug("lust down command from [user]")

	var/handled = FALSE
	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("lust down skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || !enthrall_chem.lewd || enthrall_chem.phase < 2)
			mkultra_debug("lust down skip [humanoid]: invalid enthrall (lewd=[enthrall_chem?.lewd] phase=[enthrall_chem?.phase])")
			continue
		if(enthrall_chem.enthrall_mob != user)
			mkultra_debug("lust down skip [humanoid]: enthraller mismatch (has=[enthrall_chem.enthrall_mob] wanted=[user])")
			continue

		humanoid.adjust_arousal(-8)
		mkultra_add_cooldown(enthrall_chem, 3)
		mkultra_debug("lust down applied to [humanoid] (-8)")
		addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='notice'>You force yourself to cool down at [enthrall_chem.enthrall_gender]'s order.</span>"), 5)
		to_chat(user, "<span class='notice'><i>[humanoid] reins their arousal back under your command.</i></span>")
		handled = TRUE

	return handled

/proc/process_mkultra_command_selfcall_off(message, mob/living/user, list/listeners, power_multiplier)
	// Disable selfcall enforcement: "selfcall off".
	var/static/regex/selfcall_off_words = regex("selfcall off|selfcall stop|clear selfcall")
	if(!findtext(message, selfcall_off_words))
		return FALSE

	var/handled = FALSE
	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("selfcall off skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || !enthrall_chem.lewd || enthrall_chem.phase < 2)
			mkultra_debug("selfcall off skip [humanoid]: invalid enthrall (lewd=[enthrall_chem?.lewd] phase=[enthrall_chem?.phase])")
			continue
		if(enthrall_chem.enthrall_mob != user)
			mkultra_debug("selfcall off skip [humanoid]: enthraller mismatch (has=[enthrall_chem.enthrall_mob] wanted=[user])")
			continue

		if(humanoid in mkultra_selfcall_states)
			mkultra_clear_selfcall(humanoid)
			mkultra_add_cooldown(enthrall_chem, 2)
			addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, "<span class='notice'>Your self-reference restrictions dissolve.</span>"), 5)
			to_chat(user, "<span class='notice'><i>You release [humanoid]'s self-name binding.</i></span>")
			handled = TRUE

	return handled

/proc/process_mkultra_command_follow(message, mob/living/user, list/listeners, power_multiplier)
	// Lewd-only follow/stop-follow handler. "follow me" starts, "stop following" ends.
	var/static/regex/follow_words = regex("follow( me)?")
	var/static/regex/stop_words = regex("stop follow(ing)?|heel")

	var/handled = FALSE
	if(findtext(message, stop_words))
		mkultra_debug("follow stop command from [user]")
		for(var/enthrall_victim in listeners)
			if(!ishuman(enthrall_victim))
				mkultra_debug("follow stop skip [enthrall_victim]: not human")
				continue
			var/mob/living/carbon/human/humanoid = enthrall_victim
			if(mkultra_stop_follow(humanoid, "<span class='notice'>You are ordered to stop following.</span>", user))
				mkultra_debug("follow stop success on [humanoid]")
				handled = TRUE
		return handled

	if(!findtext(message, follow_words))
		return FALSE
	mkultra_debug("follow start command from [user]")

	for(var/enthrall_victim in listeners)
		if(!ishuman(enthrall_victim))
			mkultra_debug("follow start skip [enthrall_victim]: not human")
			continue
		var/mob/living/carbon/human/humanoid = enthrall_victim
		var/datum/status_effect/chem/enthrall/enthrall_chem = humanoid.has_status_effect(/datum/status_effect/chem/enthrall)
		if(!enthrall_chem || !enthrall_chem.lewd || enthrall_chem.phase < 2)
			mkultra_debug("follow start skip [humanoid]: invalid enthrall (lewd=[enthrall_chem?.lewd] phase=[enthrall_chem?.phase])")
			continue
		if(enthrall_chem.enthrall_mob != user)
			mkultra_debug("follow start skip [humanoid]: enthraller mismatch (has=[enthrall_chem.enthrall_mob] wanted=[user])")
			continue

		mkultra_start_follow(humanoid, user, enthrall_chem)
		enthrall_chem.cooldown += 4
		to_chat(user, "<span class='notice'><i>[humanoid] begins to heel at your command.</i></span>")
		handled = TRUE

	return handled

/proc/mkultra_start_follow(mob/living/carbon/human/humanoid, mob/living/master, datum/status_effect/chem/enthrall/enthrall_chem)
	if(QDELETED(humanoid) || QDELETED(master))
		return

	mkultra_stop_follow(humanoid)
	mkultra_follow_states[humanoid] = list(
		"master" = WEAKREF(master),
		"enthrall_chem" = WEAKREF(enthrall_chem),
	)
	mkultra_debug("follow start: [humanoid] now following [master]")
	mkultra_signal_handler.RegisterSignal(humanoid, COMSIG_LIVING_RESIST, TYPE_PROC_REF(/datum/mkultra_signal_handler, follow_on_resist))
	mkultra_signal_handler.RegisterSignal(humanoid, COMSIG_QDELETING, TYPE_PROC_REF(/datum/mkultra_signal_handler, follow_on_delete))
	addtimer(CALLBACK(GLOBAL_PROC, .proc/mkultra_follow_tick, humanoid), 1 SECONDS)

/proc/mkultra_stop_follow(mob/living/carbon/human/humanoid, reason = null, mob/living/master)
	var/list/state = mkultra_follow_states[humanoid]
	if(!state)
		return FALSE

	mkultra_signal_handler.UnregisterSignal(humanoid, list(COMSIG_LIVING_RESIST, COMSIG_QDELETING))
	GLOB.move_manager.stop_looping(humanoid)
	mkultra_follow_states -= humanoid
	if(reason)
		mkultra_debug("follow stop: [humanoid] reason='[reason]' master=[master]")
		addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, humanoid, reason), 2)
	if(master)
		addtimer(CALLBACK(GLOBAL_PROC, .proc/to_chat, master, "<span class='notice'><i>[humanoid] stops following.</i></span>"), 2)
	return TRUE

/datum/mkultra_signal_handler/proc/follow_on_resist(datum/source, mob/living/resister)
	SIGNAL_HANDLER
	mkultra_stop_follow(resister, "<span class='warning'>You shake off the urge to heel.</span>")

/datum/mkultra_signal_handler/proc/follow_on_delete(datum/source)
	SIGNAL_HANDLER
	mkultra_stop_follow(source)

/proc/mkultra_follow_tick(mob/living/carbon/human/humanoid)
	var/list/state = mkultra_follow_states[humanoid]
	if(!state)
		return

	var/datum/weakref/master_ref = state["master"]
	var/mob/living/master = master_ref?.resolve()
	var/datum/weakref/enthrall_ref = state["enthrall_chem"]
	var/datum/status_effect/chem/enthrall/enthrall_chem = enthrall_ref?.resolve()
	if(QDELETED(humanoid) || QDELETED(master) || !enthrall_chem)
		mkultra_stop_follow(humanoid)
		return
	if(enthrall_chem.enthrall_mob != master || !enthrall_chem.lewd || enthrall_chem.phase < 2)
		mkultra_stop_follow(humanoid, "<span class='warning'>Your connection to your handler slips.</span>")
		return
	if(humanoid.incapacitated || humanoid.buckled || humanoid.anchored)
		mkultra_stop_follow(humanoid, "<span class='warning'>You cannot follow right now.</span>", master)
		return
	if(!(master in view(8, humanoid)))
		mkultra_stop_follow(humanoid, "<span class='warning'>You lose sight of your [enthrall_chem.enthrall_gender].</span>", master)
		return

	var/dist = get_dist(humanoid, master)
	if(dist > 1)
		if(!GLOB.move_manager.move_to(humanoid, master, 1, 1))
			step_towards(humanoid, master)

	mkultra_add_cooldown(enthrall_chem, 4)
	addtimer(CALLBACK(GLOBAL_PROC, .proc/mkultra_follow_tick, humanoid), 1 SECONDS)

/proc/mkultra_apply_selfcall(mob/living/carbon/human/humanoid, list/name_list)
	// Clear existing bindings first.
	mkultra_clear_selfcall(humanoid)
	mkultra_selfcall_states[humanoid] = list(
		"names" = name_list.Copy(),
		"idx" = 1,
	)
	mkultra_debug("selfcall set on [humanoid]: [name_list.Join(", ")]")
	mkultra_signal_handler.RegisterSignal(humanoid, COMSIG_MOB_SAY, TYPE_PROC_REF(/datum/mkultra_signal_handler, selfcall_on_say))
	mkultra_signal_handler.RegisterSignal(humanoid, COMSIG_QDELETING, TYPE_PROC_REF(/datum/mkultra_signal_handler, selfcall_on_delete))

/proc/mkultra_clear_selfcall(mob/living/carbon/human/humanoid)
	if(!(humanoid in mkultra_selfcall_states))
		return
	mkultra_signal_handler.UnregisterSignal(humanoid, list(COMSIG_MOB_SAY, COMSIG_QDELETING))
	mkultra_selfcall_states -= humanoid
	mkultra_debug("selfcall cleared on [humanoid]")

/datum/mkultra_signal_handler/proc/selfcall_on_delete(datum/source)
	SIGNAL_HANDLER
	mkultra_clear_selfcall(source)

/datum/mkultra_signal_handler/proc/selfcall_on_say(datum/source, list/speech_args)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/humanoid = source
	var/list/state = mkultra_selfcall_states[humanoid]
	if(!state)
		return
	var/list/name_list = state["names"]
	var/idx = state["idx"] || 1
	if(!name_list || !name_list.len)
		return

	var/message = speech_args[SPEECH_MESSAGE]
	if(!istext(message))
		return

	var/main_name = name_list[idx]
	// Rotate to the next name for variety.
	idx = (idx % name_list.len) + 1
	state["idx"] = idx

	var/clean = message
	var/matched = FALSE

	// Pronoun replacements.
	var/regex/pronouns = regex("\\b(I|I'm|Im|I am|me|my|mine|myself)\\b", "gi")
	if(pronouns.Find(clean))
		clean = replacetext(clean, regex("\\b(I|I'm|Im|I am)\\b", "gi"), "[main_name] is")
		clean = replacetext(clean, regex("\\bmyself\\b", "gi"), main_name)
		clean = replacetext(clean, regex("\\bme\\b", "gi"), main_name)
		clean = replacetext(clean, regex("\\bmy\\b", "gi"), "[main_name]'s")
		clean = replacetext(clean, regex("\\bmine\\b", "gi"), "[main_name]'s")
		matched = TRUE

	// Name replacements: full, first, last.
	var/full_name = humanoid.real_name
	var/first = first_name(full_name)
	var/last = (length(full_name) ? last_name(full_name) : null)
	if(length(full_name) && findtext(clean, full_name, 1, 0))
		clean = replacetext(clean, regex("\\b[full_name]\\b", "gi"), main_name)
		matched = TRUE
	if(length(first) && findtext(clean, first, 1, 0))
		clean = replacetext(clean, regex("\\b[first]\\b", "gi"), main_name)
		matched = TRUE
	if(length(last) && findtext(clean, last, 1, 0))
		clean = replacetext(clean, regex("\\b[last]\\b", "gi"), main_name)
		matched = TRUE

	if(!matched)
		return

	speech_args[SPEECH_MESSAGE] = clean
	mkultra_debug("selfcall rewrite on [humanoid]: '[message]' -> '[clean]'")

/proc/mkultra_resolve_strip_slot(slot_text)
	var/lowered = LOWER_TEXT(slot_text)
	if(lowered in mkultra_strip_slot_lookup)
		return mkultra_strip_slot_lookup[lowered]

	// Fallback: search for a keyword contained in the phrase.
	for(var/key in mkultra_strip_slot_lookup)
		if(findtext(lowered, key))
			return mkultra_strip_slot_lookup[key]
	return null

/proc/mkultra_slot_name(slot_id)
	switch(slot_id)
		if(ITEM_SLOT_HEAD)
			return "headgear"
		if(ITEM_SLOT_MASK)
			return "mask"
		if(ITEM_SLOT_EYES)
			return "eyewear"
		if(ITEM_SLOT_EARS, ITEM_SLOT_EARS_LEFT, ITEM_SLOT_EARS_RIGHT)
			return "ear slot"
		if(ITEM_SLOT_NECK)
			return "neckwear"
		if(ITEM_SLOT_OCLOTHING)
			return "outer suit"
		if(ITEM_SLOT_ICLOTHING)
			return "uniform"
		if(ITEM_SLOT_GLOVES)
			return "gloves"
		if(ITEM_SLOT_FEET)
			return "shoes"
		if(ITEM_SLOT_BELT)
			return "belt"
		if(ITEM_SLOT_BACK)
			return "back item"
		if(ITEM_SLOT_ID)
			return "ID"
		if(ITEM_SLOT_SUITSTORE)
			return "suit storage"
		if(ITEM_SLOT_LPOCKET)
			return "left pocket"
		if(ITEM_SLOT_RPOCKET)
			return "right pocket"
		if(ITEM_SLOT_POCKETS)
			return "pockets"
	return "gear"

/proc/mkultra_strip_item_for_slot(mob/living/carbon/human/humanoid, slot_id)
	var/obj/item/slot_item
	// Handle combined pockets specially so both pockets are tried.
	if(slot_id == ITEM_SLOT_POCKETS)
		for(var/slot_option in list(ITEM_SLOT_LPOCKET, ITEM_SLOT_RPOCKET))
			slot_item = humanoid.get_item_by_slot(slot_option)
			if(slot_item)
				break
	else
		slot_item = humanoid.get_item_by_slot(slot_id)

	if(!slot_item)
		return null
	if(!humanoid.canUnEquip(slot_item, FALSE))
		return null
	if(!humanoid.dropItemToGround(slot_item))
		return null
	return slot_item
//SPLURT ADDITION END
