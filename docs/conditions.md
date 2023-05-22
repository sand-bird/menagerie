# Conditions

Menagerie can parse special JSON syntax for predicates, so that we can define predicates within datafiles -- ie, the requirements for a monster to grow into other types of monsters, for a tree to produce fruit, for an NPC to be present at a location, etc.

Since they are intended as predicates, conditions ultimately resolve to true or false.  However, the syntax supports expressions that resolve to other data types as well (see [Operators](#operators)).

As a simple example, this will resolve to true if the player has over nine thousand monies:

```json
{ ">": ["$player.money", 9000] }
```

A conditions is a dictionary/object consisting of a single key/value pair.  The key is the **operator** and the value is an array of **arguments**.  The exception to this is `and`, which can also be represented in shorthand as an array of subconditions (ie, an array of conditions is handled as an `and` condition).

In the example above, `>` is the operator, and `$player.money` and `9000` are the arguments. 


# Variables

Condition arguments can contain variables denoted by **sigils**:

| sigil | meaning |
| --- | --- |
| `$` | global class reference |
| `@` | local property |
|	`#` | constant |
| `*` | current element (for collection operators) |


## Global Variables

Global variables are annotated with `$` and resolve to system classes like `Player` and `Clock`.  Generally you will want to fetch a property from one of these with `.`, as in `$player.money`.

See the linked files to find out what properties are available!

### $player

References the [`Player` singleton](/game/system/player.gd).  Most of the properties here are serialized to the `player.save` file when the game is saved.

### $garden

References the [garden](/game/garden/garden.gd), which contains references to all the entities (monsters, objects, items, and terrain) inside.  These are serialized to the `garden.save` file when the game is saved.

The garden is instanced, not a singleton like Player - currently there is only one garden so this doesn't matter, but maybe someday we will support multiple ones.  Each entity also has a reference to the garden in which it lives, accessible with `@garden` in conditions on an entity definition.

### $clock

References the game's clock, which lives in the [`Clock` singleton](/game/system/clock.gd).

A few notes:

* `date` refers to the day of the month, while `day` is the day-of-week.
* Enumerated properties (`month` & `day`) will resolve to their integer value, ie `2` rather than `wednesday`, and `3` rather than `sol`.
* All properties are 0-indexed, meaning the first of the month is `date` 0, and Year 1 is `year` 0.
* Properties reset when the next-highest property rolls over, so `tick` will never be larger than `TICKS_IN_HOUR - 1`.

### $data

References the [`Data` singleton](/game/system/data.gd), which ingests and stores all accessible data definitions (from the game and from loaded mods) in a dictionary indexed by the definition's ID (defined by its `"id"` key).

Since conditions are parsed at runtime, this data will already be populated and available, so a condition can access the contents of any other data definition.  This does technically mean that a condition can reference itself, but that would crash the game, so it's probably not a great idea.


## Local Variables

Local variables are annotated with `@` and resolve to properties on the "caller" -- usually, that means the entity that is being defined.

The entity definition for the monster Pufig specifies that it can evolve into Pufine if its patience is greater than its aggressiveness:

``` json
{ ">": ["@patience", "@aggressiveness"] }
```

At runtime, when an instanced Pufig wants to evolve, it will evaluate this condition against its own `patience` and `aggressiveness` properties to see if it's able to evolve into Pufine.


## Constants

Apparently the `#` sigil references a constant, and this is defined in `conditions.gd`, but I'm not sure if it even works.  I declared a lot of constants in the early days of this project that we don't actually need anyway.

# Operators

## Relational operators

Menagerie supports all the basic comparisons:

| condition | returns true if |
| --- | --- |
| `{ "==": [a, b] }` | `a` equals `b` |
| `{ "!=": [a, b] }` | `a` does not equal `b` |
| `{ ">": [a, b] }` | `a` is greater than `b` |
| `{ "<": [a, b] }` | `a` is less than `b` |
| `{ ">=": [a, b] }` | `a` is greater than or equal to `b` |
| `{ "<=": [a, b] }` | `a` is less than or equal to `b` |
| `{ "in": [a, b] }` | `a` is a member of collection `b` |

## Boolean operators

Menagerie supports `and`, `or`, and `not` operators which take subconditions as arguments.  The `and` and `or` operators accept an arbitrary number of subconditions, and can be nested as deeply as desired:

```json
{ "and": [
  { "or": [
    { "and": [...] },
    { "and": [...] }
  ]},
  { "or": [...] },
  { "or": [...] },
]}
```

### `and`

As a special shorthand syntax: an array of subconditions is treated as an `and` condition.  Thus, the following are equivalent:

```json
{ "and": [{ ">": [a, b] }, {"<": [c, d] }] }
```
```json
[{ ">": [a, b] }, { "<": [c, d] }]
```

### `not`

Needs some testing to see what happens if you pass multiple subconditions into `not`. I think it would treat the argument as an `and` condition, meaning `not` would return true if any of the subconditions are false.


## Data operators

There is a cicada-inspired Pokémon called [Shedinja](https://bulbapedia.bulbagarden.net/wiki/Shedinja_(Pokémon)) with a unique evolutionary requirement: when your Nincada evolves normally into a Ninjask, Shedinja will spontaneously appear in your party as long as you have an empty slot and a spare Pokéball.

Conditions should enable similarly complex behavior -- extensibly and modularly.  To that end, the following operators return data rather than booleans:

| condition | behavior |
| --- | --- |
| `{ "get": [a, b] }` | fetch property `b` of `a` |
| `{ "map": [a, b] }` | fetch property `b` from every element in collection `a` (returns a collection) |
| `{ "filter": [a, b] }` | returns a new collection with the elements from collection `a` that match subcondition `b` |


## Shorthands

Nesting data operators quickly becomes unwieldy, so arguments support a shorthand syntax using "seperators" (separation operators).  The dot syntax (`.`) we've already seen is actually seperator shorthand for `get`, while `map` uses a colon (`:`) in the same way.  Thus the following are equivalent:

```json
{ "map": [
  { "get": ["$garden", "monsters"] },
  "type"
]}
```

```json
"$garden.monsters:type"
```

Shorthand strings can be nested within regular conditions as arguments; they will be resolved before the parent condition (inside-to-outside).


## Working with collections

`map` and `filter` work with both arrays and objects.  If the collection is an object, they will iterate over its values (they don't care about keys).

For these operators, the `*` sigil resolves to the value of the current element in the collection.  For example, this `filter` condition return a collection of all monsters in the garden whose IQ is over 30:

```json
{ "filter": [
  "$garden.monsters",
  { ">": ["*.iq", 30] }
]}
```

`*` is technically usable with `map` also, but it will likely not do anything, as `map`'s second argument needs to resolve to a key, and objects can't fetch themselves from themselves.


# Examples

## Example 1: Favorite monster

Pikablu can evolve into Raiblu only if another monster in the garden considers Pikablu its favorite monster.  For this we can assume the `Monster` class has a `favorite_monster` getter that will fetch the monster for which we have the highest preference.

### Reciprocal favorite

Here we check if Pikablu is its favorite monster's favorite monster.

If `favorite_monster` stores a reference:

```json
{"==": [
  "@id",
  "@favorite_monster.favorite_monster.id"
]}
```

If `favorite_monster` stores an id, we must look up that id in `$garden.monsters`:

```json
{"==": [
  "@id",
  "$garden.monsters.@favorite_monster.favorite_monster"
]}
```

### General favorite

Here we check if any other monster in the garden has Pikablu as its favorite.  For this we need to iterate over all the monsters in the garden with `map`:

```json
{"in": [
  "@id",
  "$garden.monsters:favorite_monster"
]}
```

## Example 2: Inventory filtering

These conditions are actually used in the game (for now) to determine whether the "items" and "objects" main menu pages should be displayed.  The condition resolves to true for each of these pages if the player has an item or object in their inventory, respectively.

Items:

```json
{"filter": [
    "$player.inventory:id",
    {"==": ["$data.*.type", "item"]}
  ]}
}
```

Objects:

```json
{"filter": [
  "$player.inventory",
  {"==": [
    {"get": [{"get": ["$data", "*.id"]}, "type"]},
    "object"
  ]}
]}
```

(I'm not sure why the latter condition isn't just using `$data.*.id.type`.  Sometimes `get` operations need to be defined in longhand because we don't support order of operation overrides with `get` shorthands, but this one looks like it should check out.  Hm!)