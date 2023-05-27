# Data requirements

This is a reference for what properties we'll need on each of our data definitions.  This document is a planning aid: prescription, not description.  See the [data/system/](/game/data/system/) folder for the actual schemas.


## Types

These are defined in [definitions.schema](/game/data/system/definitions.schema), and can be referenced within a schema with `{ "$ref": "definitions/key" }` (eg `definitions/condition`).

- `condition`: a recursive structure representing a predicate definition (see [the conditions doc](./conditions.md))
- **text**: an object whose keys are language codes (eg `en`) and values are the text in that language.  Curently we have a bunch of these for different max string lengths, eg `text32`, but this probably isn't necessary.
- **file**: a string value representing a filepath relative to the schema definition.  We will want to validate that these are actual files. (Not in the JSON schema spec)
- **spritesheet**: an object with a file reference to a spritesheet image, number of frames, and fps.
- duration/frequency/interval: a span of time. 


## Common properties

All data definitions should have:
- an `id` key whose value is a string that does not include spaces.  This is how the data is referenced in-game.
- a `type` key that contains the entity type (`monster`, `item`, etc).  This determines which schema we use to validate the data, and how it's referenced in-game.

I believe all entity types should also have `name` and `description` (translatable) text fields.


# Monsters

Monster definitions should have:

- A `size`.  Assuming this indicates which navmesh we use (if we bake multiple navmeshes based on agent radius), this should be an enum.  It should be a bit smaller than the monster's sprites.
- A list of possible `evolutions` and the `condition`s required for each. (Note: let's NOT associate monster definitions with life stages; evolution should be more flexible than that)
- A list of `morphs`: sprite variants. Each morph should have:
  - The `condition` required for an egg to produce that morph (optional?)
  - The `weight` of rolling that morph, assuming multiple are valid
  - The `name` of the morph in translatable text
  - A set of **`animations`**
- Parameters affecting the monster's intrinsic properties:
  - Gender ratio
  - Base traits: these depend on both heredity (parents' traits) and species, modified by a probability distribution inherent to the trait.  I'm not sure what this should look like - will need to carefully consider to what extent species should affect a monster's traits.
- Dietary restrictions (what sorts of foods the monster can/cannot eat)
  - it would be really cool to have monsters that can eat stuff that's not normally edible - maybe an undocumented "inedible" value here that allows it to consume items without the `edible` trait on them?
- Parameters affecting the monster's preferences: these would probably look like weights associated with aesthetic tags
- Items dropped by the monster, plus frequency and requirements

## Animations

To facilitate creating new monsters, the set of required animations should be as small as possible.  Here are all the ones I think we'll need for a robust set of behaviors:

- `idle` *
- `walk` *
- `sleep` *
- `eat` (can maybe substitute `walk` or `idle`)
- `lie_down` (can skip)
- `run` (can substitute `walk`)
- `attack` (maybe not necessary)
- `dig` (maybe not necessary)

Animations should have front and back sprites at minimum - so, something like `{ front, back }`, where each value is an object with `{ left, right }` (one of the two required; if the other isn't specified, we flip the sprite in code), and each value of those is a spritesheet.



# Objects and Items

(Potentially) stateful entities that exist in the garden and are not monsters.

Most objects and items are actionable: they can advertise certain actions to monsters within perceptual range, typically with themselves as a target: eg, food can advertise `eat`, a bench can advertise `idle` and `sleep` (with a bigger boost to mood than idling or sleeping on the ground), and so on.

The main difference between the two entity types is that objects are bound to the tile grid (hence immovable) while items exist on the pixel grid (like monsters do), so their positions and sizes are defined differently, and they have different capabilities.

Use cases:
- edible objects
  - a bench made of food (can also be sat on)
  - a trough that holds a certain amount of food, can be refilled, and only advertises "eat" when nonempty (maybe it advertises "emote hunger" when it is empty)
- different kinds of food with different effects on drives when eaten
- items that last for only a short while on the ground before they disappear
- monster poop that smells like (holds a reference to) the monster which made it
- a ball which rolls around when a monster collides with it and advertises a "play" action

## States vs separate entities

Plants are complex objects that need state machines: different phases of growth each with their own sprite(s) and potential behavior (eg, only fully-grown trees can drop fruit), and conditions to transition from one state to another.

Items may also have different states with different behavior: eg, eating an apple may transform it into an inedible apple core; fruit left on the ground for long enough may rot.  Unripe fruit may still be edible, but if left to ripen, will have better nutritional properties.

We could define each state of an apple tree as a separate object: `apple_tree_sprout`, `apple_tree_seedling`, `apple_tree_sapling`, `apple_tree_mature`, `apple_tree_fruiting`, `apple_tree_dead`.  Or we could have a single `apple_tree` entity which contains all these different states.  How to decide?

If we use states:
- States could inherit properties from the parent object.  Eg, not every state would need its own description, sprites, size, etc
  - We could get around this for separate entities by defining an inheritance mechanism (either for the whole entity or just for certain properties)
- We'd get a single entry in the encyclopedia for the object by default, and could add subpages for diff states.
  - The subpages would be sorted according to the order the keys are listed in the `states` object, because apparently godot preserves this.  Or, if needed, we could add an "encyclopedia_subpages" array to the object definition, and validate that its values are all found in `states`
- States are more semantic than separate entities in the cases where we'd use them - all the different states of apple tree are part of the same overarching type of entity
- States would be more cumbersome to implement and use - looking up object data would always require checking for the property in the appropriate state, then falling back to the parent.
  - This can be a static method on `Object` - probably not a big deal

If we use separate entities:
- By default they would all show up separately on the encyclopedia
  - We could add a property to all of them like `encyclopedia_group`, but we have no place to put data for the group (translatable name at minimum)
- Looking up object data would be a lot more straightforward
- Not having inheritance may make things simpler at the cost of a little repetition

**Verdict:** states win on semantics and the implications for the encyclopedia.


## Inventory management

Assuming we can put stuff away at will in the inventory, how much of its state should be preserved?  Eg, what happens if you put away a half-eaten apple while other apples (uneaten and partially-eaten) are in the inventory?

Assume that items in the inventory are in a serialized format (we don't want to instantiate everything in the inventory), and so putting something in the inventory serializes it.

Strategies:

1. base inventory is an object of entity IDs to entries.  An entry is:
   1. an object 

## Traits

A term from Rust (how topical).  This is an interface between game logic and data definition that allows us to code parameterized logic for different kinds of things objects/items can do, then reference those traits within data definitions with the required parameters to apply configurable functionality to the entity.  Objects/items with traits will be given state parameters associated with that trait (eg `amount_remaining` for edibles).

(Note: traits might be useful for monsters, too: flying, swimming, herbivorous/carnivorous/omnivorous, etc)

### Shared traits

- `edible` - what are the properties of food?  How much nourishment it contains, how much food there is (celery vs potato), its flavor profile, its type (fruit/vegetable/insect/meat/other, for monsters with different dietary requirements) and maybe how difficult it is to eat.  Also, what happens when the food has been consumed: does the entity disappear (default) or transform into some inedible residue?
- `decays` - for items that disappear over time.  Requires total durability & rate of decay, provides state for current durability.  Optionally accepts an ID of another entity to transition into once durability is exhausted (eg a fruit rots).  This could be used for anything that transforms on a timer, so it might be useful to name it something more generic

### Object traits

- `container` - exposes parameters for capcity and valid kinds of content, and state for current content.  Superclass of specific kinds of containers:
  - `planter` - can be used to grow plants.  For the plant's purposes it functions as a tile, which means it needs an associated type of terrain. For simplicity this should be a trait parameter, hence soil type is inherent to the entity, though, it would be neat if the trait implementation could (also, eventually) expose functionality to add soil before planting
  - `fruiting` - takes the entity ID of the fruit item it produces, frequency and conditions for fruiting, quantity of fruits, the position at which the fruit spawns, and the entity ID to which it reverts when it is no longer fruiting.
    - Consider a fruit tree and a fruiting mushroom log.  The log should never "drop" its mushrooms - monsters must go interact with it to retrieve one.  The tree should drop its fruit at regular intervals, and should advertise a "shake" action for this that requires a certain level of intelligence or knowledge.
  - Containers of monsters:
    - `enterable` - an enclosure into which the monster can enter.  Possibly comes with state for whether a monster is inside (door closed), how many monsters it can hold maybe also coordinates for the entrance.  Maybe breeding happens when multiple monsters are in the same enclosure.
    - `sittable` - stuff like benches and rocks which monsters can sit on.  Needs parameters for where the monster sprite(s?) should be moved while on the object
- `plant` - comes with plant-related state: health as a function of water and soil quality, and growth progress as a function of health and time.  provides special interaction options like `water`

- `spreading` - spreads to adjacent tiles if they are available.  Takes parameters for rate of spread


  - Consider a fruit tree and a fruiting mushroom log.  When the log fruits, monsters can just go over and grab the mushrooms.  When the tree fruits, there is an extra step: the fruits stay on the tree until they fall.  At this point the tree advertises a "shake" action (to intelligent enough monsters) that will force the fruits down.

### Item traits

- `toy` - advertises the `play` action, and takes parameters for 


## Shared properties

- Aesthetic properties - is it beautiful (art) or offensive (poop)? an enum of traits would be really cool here - materials (stone, wood), themes (gothic, rustic)
- Sprites/spritesheets - each should be associated with a condition so we can show different sprite depending on state


## Objects

Sessile entities which are placed on the 16px tile grid in the garden: trees, furniture, etc.

### Sprite tiling

Some objects like hedges and fences should tile: their sprites depend on the sprites of adjacent objects.  (We don't have to worry about this with items since they don't sit on the tile grid.)


## Items

Movable objects like fruits and toys that sit on the garden floor and exist on the pixel grid, not the tile grid.

Examples:
- Food: should have different levels of consumedness
- Toys: items that monsters can interact with aside from eating, eg a ball that can be knocked around
  - toys that move on their own, like little robots/bugs?
- Monster drops: marginally-useful items with which to furnish the in-game economy, eg `fluffy_tuft`

Items do need state.  Food is not eaten all at once; other kinds of items might decay or transform over time.  Therefore two instances of the same item are not interchangeable.

Items can behave differently based on internal states, eg food might have different sprites based on how much of it has been eaten.



# Other data types

## Notes

Little writings that appear in the encyclopedia along with stuff about other entities as they are "discovered" by the player.  These function as achievements.  Unlike other entities, no description is needed.

- `name`: translatable text
- `icon`
- `content`: translatable text
- `condition`: condition for unlock (id is added to player's `discovered` array)
- possibly something for check frequency (to determine if the unlock condition ismet) - or maybe we just check all notes on an hourly/daily cadence (tickly is prob overkill)


## Locations

Outside the garden, you will eventually be able to visit Locations where you can interact with NPCs in a visual novel style interface.  Valid locations should be listed on main menu.

Location definitions should have:

- Background sprite: possibly multiple of these, each associated with a condition and a weight, so that locations can change in response to game state
  - If we're getting really fancy, maybe a lighting sprite the same resolution as the background sprite, with colored pixels to indicate light sources
- A condition for whether the location is accessible
- An icon or thumbnail to show on the menu/map


## NPCs

NPCs show up in Locations if conditions are met, have dialogue, and potentially have stores where they can buy and sell items.

It would be really nice to have events with dialogue between multiple NPCs.  That's getting ahead of ourselves though.  Initially, it might make sense to just have a single NPC for each Location, and not worry about them moving around.

Properties:

- Birthday
- Sprites: an object whose IDs are keys we can use to reference the sprite in dialogue data.  No set template for which sprites an NPC needs, but we should validate that all sprites in dialogue are keys present in this list.


### Dialogue

Using JSON for dialogues is a crapshoot - see [./sample_dialogue.json](./sample_dialogue.json).  Nobody wants to write more of that, including me.  Let's figure out a different format.

<!--
A dialogue is an array of translatable texts, where input is required to move from each element to the next.  Each dialogue should have an ID, a condition, and a weight.

Because data merging appends values to arrays, rather than replacing them, we need to make sure translatable text is NOT nested inside an array.  Ie, something like this will work:

```json
{ "dialogues": {
  "greeting1": {
    // for validation: choice must be offered in each translation
    "choices": ["yes", "question"],
    "en": [
      "What a lovely day!",
      "Are you here to buy some potions?",
      { "yes": "Yes", "question": "Potions?" }
    ],
    "pr": [
      "Bon dia!",
      "Esta aqui para comprar alguns potions?",
      { "yes": "Sim", "question": "Potions?" },
      
    ],
  }
}}
```

Alternately, we can group translations for each line together if as long as we save all the lines in an object instead of an array:

```json
{ "dialogues": {
  "greeting1": {
    "0": {
      "en": "What a lovely day!",
      "pr": "Bon dia!"
    },
    "1": {
      "en": "Are you here to buy some potions?",
      "pr": "Esta aqui para comprar alguns potions?"
    },
  }
}}
```

When the player makes a choice, we save the dialogue path they chose to the NPC instance (saved to `player.save`), so that it can be referenced with `@`.  Then, future dialogs can branch depending on past decisions.

-->


### Stores

Should buy goods by category/tag, and have one or more predefined sell lists associated with conditions (since the condition will likely apply to a lot of different items).

The NPC should have a property for how much money they have available

Items in sell-lists:
- `id` of the item
- `max_quantity` the npc can sell
- any state the item should have (eg, the `state` of an object)
