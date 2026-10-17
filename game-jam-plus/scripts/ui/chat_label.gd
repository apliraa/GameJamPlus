class_name ChatLabel
extends RichTextLabel

func setup(user: String, message: String, name_color: Color) -> void:
	clear()
	push_color(name_color)   # only the username is tinted
	add_text(user)
	pop()
	add_text(": " + message) # uses the label's own default color/font
