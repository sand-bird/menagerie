# Localization

Localized text in datafiles is defined as an object whose keys are language codes (`en` is required).

Localized text in game source code should use Godot's localization utilities.  To ensure we don't miss anything, all translatable text in the source should be defined as a constant in [`system/trans_text.gd`](../game/system/trans_text.gd):

### Game elements

- Composite attribute names, long and short ("Intelligence"/"INT", "Vitality"/"VIT", etc)
- Attribute titles ("sickly"/"hearty", "neurotic"/"composed", etc) - these are declared in comments in `attributes.gd`
- Entity trait names ("edible", "perishable" etc)
- Entity tags - "fruit", "soft", "gothic", etc

### UI elements

- Text on all buttons
- Titles for each of the menu chapters/sections
- Titles for misc ui elements, eg save file list
- Titles for all the blocks on the monster info menu - "species", "age", "attributes", etc