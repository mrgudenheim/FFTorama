extends Button

@export	var import_dialog: ConfirmationDialog

func _on_pressed():
	import_dialog.visible = true
	import_dialog.initialize()
