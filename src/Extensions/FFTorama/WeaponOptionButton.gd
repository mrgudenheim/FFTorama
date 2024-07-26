extends OptionButton

var weapon_options: Array = [
	"Knife",
	"Ninja Sword",
	"Sword",
	"Knight Sword",
	"Katana",
	"Axe",
	"Rod",
	"Stave",
	"Flail",
	"Gun",
	"Crossbow",
	"Bow",
	"Instrument",
	"Book",
	"Polearm",
	"Pole",
	"Bag",
	"Cloth",
	"Shield",
	"Shuriken",
	"Bomb"]

# Called when the node enters the scene tree for the first time.
func _ready():
	for weapon in weapon_options:
		add_item(weapon)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

