extends UICard

func default_ui_play_func(ui: Control):
	var burnnumber = randi_range(1, len(ui.deck))
	Globals.cursor_state = Globals.cursor_states.DEFAULT
	for i in range(burnnumber):
		ui.deck.pop_back()
		await get_tree().create_timer(.005).timeout
		ui.update_deck_ui()
		
	return true
