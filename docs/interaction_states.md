# Interaction States

## Summary
The interaction system consists of four states (FREE, SELECTING, PLACING, COMMANDING) that manage how the player interacts with the garden. Each state has specific input handling requirements and visual feedback. The system supports multiple input modes (mouse, keyboard, joystick, touch) and automatically switches between them based on the last used input type.

## States

### FREE State
- Default state for cursor movement and basic interaction
- Cursor follows mouse position
- Directional input moves cursor (keys/joystick)
- Touch mode has special entity interaction handling
- Entity highlighting and basic selection available
- Note: Highlighting is a property of FREE state, not a distinct state. It provides visual feedback when the cursor is over an entity but doesn't change how the cursor or input behaves.

### SELECTING State
- Cursor disabled
- Directional input repurposed for UI menu navigation
- Entity remains selected until explicitly deselected
- Camera follows selected entity
- Popup menu shows available actions for selected entity type

### PLACING State
- Cursor enabled but entity interaction disabled
- Shows ghost preview of item/sessile to be placed
- Grid snapping for sessiles
- Invalid placement visualization (red tint)
- Placement validation

### COMMANDING State
- Similar to FREE state
- Distinct cursor sprite
- Nested "selecting" state for target selection
- Command menu navigation

## State Transitions

### Transition Diagram
```
FREE ──────────────┐
  │                │
  │ select entity  │
  │                │
  ▼                │
SELECTING          │
  │                │
  │ deselect       │
  │                │
  └────────────────┘
  │
  │ command monster
  │
  ▼
COMMANDING
  │
  │ COMMAND_FREE
  │   │
  │   │ select target
  │   │
  │   ▼
  │ COMMAND_SELECTING
  │   │
  │   │ cancel
  │   │
  │   └─────────────┐
  │                 │
  └─────────────────┘
```

### Transition Rules

#### FREE → SELECTING
- Trigger: Confirm action, click, or touch on highlighted entity

#### SELECTING → FREE
- Trigger: Cancel action, right click, or click/touch away from popup menu

#### SELECTING → COMMANDING
- Trigger: Choose command option from popup menu
- Conditions: Selected entity must be a monster

#### COMMANDING → SELECTING
- Trigger: Cancel action, right click, or click/touch cancel button in UI

### COMMANDING Substates

#### COMMAND_FREE
- Similar to FREE state
- Can select arbitrary map points in addition to entities
- Used to choose target for monster command

#### COMMAND_SELECTING
- Similar to SELECTING state
- Popup menu shows actions available to commanded monster
- Canceling returns to COMMAND_FREE state

## Input Handling

### Input Modes
- Mouse: Direct cursor following
- Keyboard: Discrete directional movement via `cursor_{direction}` actions
- Joystick: Analog movement with speed based on input strength
- Touch: No cursor sprite, special entity interaction

### Mode Switching
- System tracks last used input type
- Automatically switches mode based on last input
- All input types monitored simultaneously
- Only one input mode active at a time
- Note: Input mode switching is immediate, with no minimum threshold

### State-Specific Behavior

#### FREE State
- Cursor follows input (mouse position, directional keys, or joystick)
- Touch mode: First touch highlights entity, second touch selects
- Cursor speed for key/joystick input is configurable in options menu

#### SELECTING State
- Cursor disabled
- Directional input for UI menu navigation
- Menu navigation supports all input types

#### PLACING State
- Cursor enabled but entity interaction disabled
- Ghost preview with grid snapping for sessiles
- Invalid placement visualization (red tint)

#### COMMANDING State
- Similar to FREE state
- Distinct cursor sprite
- Nested "selecting" state for target selection
- Command menu navigation

## Visual Feedback

### Cursor
- Normal cursor sprite in FREE and PLACING states
- Disabled in SELECTING state
- Distinct sprite in COMMANDING state
- Hidden in touch mode

### Entity Highlighting
- Outline shader for highlighted entities
- Additional visual feedback for selected entities
- Ghost preview for placement
- Invalid placement visualization (red tint)
- Note: When the cursor "sticks" to an entity, this is called highlighting. The entity receives an outline shader and the UI displays information about it.

### UI Elements
- Entity HUD in top left when highlighted
- Command menu for selected entities
- Placement validation feedback
- Input mode indicators

## Menus and Entity Types

### Entity Types
- All entity types can be highlighted and selected
- Entity types include:
  - Monsters
  - Items
  - Sessiles (stationary objects)

### Menu System
- Uses a single menu scene that supports variable number of options
- Each option can have:
  - Custom label
  - Custom icon
  - Custom functionality

### SELECTING Menu Options
- Monsters:
  - Command (transitions to COMMANDING state)
  - Pet
  - Scold
  - Info
- Items and Sessiles:
  - Grab (transitions to PLACING state)
  - Put away
  - Additional options based on entity traits

### COMMAND_SELECTING Menu Options
- Options determined by:
  - Commanded monster's known actions
  - Target entity's traits
- Uses same menu scene as SELECTING state

## Implementation Strategy

### State Machine
- Use a simple state machine with explicit state transitions
- Each state should be a separate class that implements a common interface
- States should be responsible for:
  - Input handling
  - Visual feedback
  - State-specific behavior
- The main state machine should handle:
  - State transitions
  - Entity selection/highlighting

### Integration with Existing Systems

#### Menu System
- Use existing menu manager via `Dispatcher.ui_open` and `Dispatcher.ui_close`
- Menu scenes should be placed in `/game/ui` folder
- Leverage Godot's built-in UI focus and input handling
- Menu scenes should be reusable across states

#### Input Management
- Use existing `cursor.gd` for cursor movement and entity interaction
- In SELECTING state:
  - Disable cursor
  - Use Godot's built-in UI input handling
  - Leverage focus neighbor behavior
  - Use built-in `ui_*` actions
  - Use built-in click/touch handling on buttons

#### Entity Management
- Use existing `garden.gd` for entity management
- Handles:
  - Entity parenting
  - Entity selection/highlighting
  - Entity state
- Entity-specific behavior should be implemented in entity classes
- Entities should implement interfaces for:
  - Selection
  - Highlighting
  - Menu options
- Garden calls these interfaces as appropriate

### Code Structure
- State machine should be implemented in `garden.gd`
- Each state should be a separate script
- States should communicate with existing systems via signals
- Entity-specific behavior should be implemented in entity scripts
- Garden should use entity interfaces rather than implementing behavior

### Entity Interfaces

#### Selection Interface
- `is_selectable() -> bool`: Returns whether the entity can be selected
- `on_selected()`: Called when entity is selected
- `on_deselected()`: Called when entity is deselected
- `get_selection_menu_options() -> Array`: Returns available menu options when selected

#### Highlighting Interface
- `is_highlightable() -> bool`: Returns whether the entity can be highlighted
- `on_highlighted()`: Called when entity is highlighted
- `on_unhighlighted()`: Called when entity is unhighlighted
- `get_highlight_info() -> Dictionary`: Returns information to display in HUD

#### Menu Options Interface
- `get_menu_options(target: Entity = null) -> Array`: Returns available menu options
- `on_menu_option_selected(option: String, target: Entity = null)`: Called when a menu option is selected
- `can_perform_action(action: String, target: Entity = null) -> bool`: Checks if action is valid

### Garden Interactions

#### Entity Management
- Garden maintains lists of entities by type (monsters, items, sessiles)
- Garden handles entity parenting and scene tree organization
- Garden manages entity state transitions (selection, highlighting)
- Garden delegates behavior to entity interfaces

#### State Machine
- Garden implements the state machine
- Garden handles state transitions
- Garden manages input mode switching
- Garden coordinates between states and entities

#### Menu Integration
- Garden opens/closes menus via `Dispatcher`
- Garden passes entity context to menus
- Garden handles menu option callbacks
- Garden manages menu state transitions

### State Usage

#### FREE State
- Uses entity highlighting interface
- Manages cursor movement
- Handles basic entity interaction
- Prepares for state transitions

#### SELECTING State
- Uses entity selection interface
- Manages menu navigation
- Handles menu option selection
- Prepares for state transitions

#### PLACING State
- Uses entity placement interface
- Manages ghost preview
- Handles placement validation
- Manages placement completion

#### COMMANDING State
- Uses entity command interface
- Manages target selection
- Handles command execution
- Manages command completion
