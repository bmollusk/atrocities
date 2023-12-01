extends Control

signal link(str)

func on_label_clicked(meta):
	link.emit(meta)



