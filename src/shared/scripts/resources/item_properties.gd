extends Resource
class_name ItemProperties


enum ItemType {
	GUN=0,
	MELEE=1,
	BOMB=2,
	GRENADE=3,
	STIM=4,
}

@export var item_type: ItemType = ItemType.GUN
@export var name: String = "Unnamed item"
@export var id: int = 0
