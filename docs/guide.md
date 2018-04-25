### Getting Started

Mods in *Menagerie* consist of `.json` (JSON data), `.png` (image), `.tres` (Godot resource) and/or `.tscn` (Godot scene) files. These are the same types of files the actual game is built from, and for a mod to work, they must be organized in roughly the same way. When *Menagerie* launches, it looks in a few special directories for mod files, and then supplements or replaces the base game files accordingly.

*Menagerie* loads mods from the `user://mods/` and `res://mods/` directories, and prioritizes them in that order. In other words, if any files in `user://mods/` conflict with files in `res://mods/`, the former will take precedence, just as mod files take precedence over any conflicting files in the main game.

In Godot, `user://` is an alias for the "user directory," which `res://` is an alias for the "resource directory." The actual location of `user://` will depend on your operating system; in Linux, for example, it is:
```
/home/{yourname}/.local/share/godot/app_userdata/Menagerie/
``` 
The actual location of `res://` is simply the base directory where the game is installed. This will depend on your game distribution platform; for Steam on Linux, for example, the game is located at:
```
home/{yourname}/.steam/steamapps/common/Menagerie/
``` 
More info on data paths in Godot is available [in the Godot docs](https://godot.readthedocs.io/en/3.0/tutorials/io/data_paths.html).

### File Structure

Mods for *Menagerie* must mimic the file structure of the game, which is as follows:

```
game
|-- assets
|   |-- garden
|   |   |-- object
|   |   `-- item
|   |-- monster
|   |-- town
|   |-- npc
|   `-- ui
|-- bgm
|-- data
|   |-- garden
|   |   |-- object
|   |   `-- item
|   |-- monster
|   |-- npc
|   |-- town
|   `-- ui
|-- garden
|-- monster
|-- npc
|-- system
|-- town
`-- ui
```

(To view the full file structure, check out the game's source code [here]().)

The `garden`, `monster`, `npc`, `system`, `town`, and `ui` folders contain game logic in the form of Godot scenes (`.tscn`) and scripts (`.gd`). In Godot, scenes and scripts are generally paired, though they can function independently as well.

The `assets` and `data` folders are special: they contain sprites and data files, respectively. All of the data files relied upon by scenes in the `monster` folder can be found within `data/monster`, and so on.

Resources for specific monsters, objects, items, or characters is organized into subfolders, one for each entity. For example, Pufig's data is inside `data/monster/pufig`, while its sprites are inside `assets/monster/pufig`.

Putting this all together, a mod to add a monster called Pikablu would include the following files and folders:

```
my_mod
|-- assets
|   `-- monster
|       `-- pikablu
`-- data
    `-- monster
        `-- pikablu
```

That's it!


# Conditions

DRILL DOWN SYNTAX 2
-------------------

`$garden.monsters`:

```
[ Monster#12345, Monster#5437, ... ]
```

`$garden.monsters:preferences`:

```
[
  {
    "monsters": {
      "3789": 5,
      "6732": 12,
      ...
    },
    "items": { ... },
    ...
  },
  {
    "monsters": { ... },
    "items": { ... },
    ...
  },
  ...
]
```

`$garden.monsters:preferences:monsters`:

```
[
  {
    "3789": 5,
    "6732": 12,
    ...
  },
  { 
    "4773": -2 
  },
  ...
]
```


`$garden.monsters:preferences:monsters:@id.max`

```
[ 5, 10, -8, 22, 16 ]
```


`{">=": [{"max": "$garden.monsters:preferences:@id" }, 30]}`


----------------------

`@preferences`

```
{
  "monsters": {
    "3789": 5,
    "6732": 12,
    ...
  },
  "items": { ... },
  ...
}
```


`@preferences.monsters`

```
{
  "3789": 5,
  "6732": 12,
  ...
}
```

-------------

`$garden.monsters`

```
{ "1234": Monster#1234, "5678": Monster#5678 }
```

`$garden.monsters:*`

```
[ Monster#1234, Monster#5678 ]
```

```
{ "filter": 
    [ 
        "$garden.monsters",
        { "==": ["^.*.id", "@favorite_monster.id"] }
    ]
}
```

*: 1234, 5678



.iq

```
{ "get":
    [
        "$garden.monsters",
        "@preferences.monsters"
    ]
}
```
       
        
`$garden.monsters.@preferences.monsters`





```
"map": [
	"$garden.monsters", { 
		"map": [
			"*",
			{ 
				"map": [
					"preferences", 
					"monsters.@id"
				]
			}
		]
	}
]



{"map": [
	{"map": [
		{"map": [
			"$garden.monsters",
			"*"
		]},
		"preferences"
	]},
	"monsters.@id"
]}


{"get":[
	{"get":[
		"$garden",
		{"map":[
			{"map":[
				{"map":[
					"monsters",
					"*"
				]},
				"preferences"
			]},
			"monsters"
		]}
	]},
	"@id"
]}


{"map":[
	{"map":[
		{"map":[
			{"get":[
				"$garden",
				"monsters"
			]},
			"*"
		]},
		"preferences"
	]},
	{"get":[
		"monsters",
		"@id"
	]}
]}
```

```
{"get":[{"map":[{"map":[{"map":[{"get":["$garden","monsters"]},"*"]},"preferences"]},"monsters"]},"@id"]}
```






