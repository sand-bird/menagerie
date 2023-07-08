# Localization

Localized text in datafiles is defined as an object whose keys are language codes (`en` is required).

Localized text in game source code should use Godot's localization utilities. For now, this file will keep track of all the stuff we need to localize this way.

- Composite attribute names, long and short ("Intelligence"/"INT", "Vitality"/"VIT", etc)
- Attribute titles ("sickly"/"hearty", "neurotic"/"composed", etc) - these are declared in comments in `attributes.gd`
- Entity trait names ("edible", "perishable" etc)
- Entity tags - "fruit", "soft", "gothic", etc
- Titles for all the blocks on the monster info menu - "species", "age", "attributes", etc