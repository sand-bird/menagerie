extends Panel

@onready var saves: PagedList

func _ready():
	saves = $saves
	$title.text = tr(T.RECORDS)
	saves.page_changed.connect(update_page_display)
	saves.page_count_changed.connect(update_page_display)
	update_page_display()

## we don't care about passing through the params from the signals
## because we can just fetch them directly from $saves
func update_page_display(_x = null):
	var current = saves.page
	var total = saves.page_count
	$pages.text = str(current + 1, " / ", total)
	$pages/arrows.update_visibility(current, total)
