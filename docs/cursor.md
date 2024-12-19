# Cursor states

these should probably actually be managed by the garden because they have implications on other garden nodes, eg entities (put outlines on them if they are selected), ui (show garden hud if something is selected), and camera (snap to an entity or enable/disable edge scroll)

## Free state

- Joypad mode:
  - move the cursor with left stick
  - pan with right stick or edge scroll (allow edge scroll to be disabled)
  - cursor sticks strongly to entities when it gets near them
  - action button while cursor is over an entity selects that entity

- Mouse+key mode:
  - move the cursor with mouse
  - wasd pans the camera, or edge scroll
  - slight cursor stick
  - left click selects entity
  - right click unselects (esc/back/etc should also work)

- Touch mode:
  - drag scroll
  - pressing & releasing on an entity selects it
    - should be a little smart to avoid selecting stuff when we just wanted to scroll. avoid selecting if the camera has moved a lot between press and release
  - bonus: just pressing "highlights" it, shows basic hud as though there were a cursor stuck to it

- while an entity is highlighted, a hud for it shows up in the top left
- we should also experiment with applying a simple shader, like outline


## Selecting state

- when an entity is selected we disable manual camera scrolling and force the camera to keep the entity as close to the center of the screen as possible

- touch mode:
  - tap & release the entity again to pull up menu
  - touch & release away from the entity to deselect

- joypad mode:
  - press action button to pull up menu
  - press cancel button to deselect

- mouse+key mode:
  - click entity again to pull up menu
  - rick click or back button to cancel

- bonus for both keyboard & joypad: moving cursor while entity is selected (but menu is not up) makes it appear (clicking another entity moves the selection)


## Placing state

- when cursor is visble (always in mouse or joypad input), show a ghost of the item/sessile to place under the cursor
- if sessile, ghost should snap to grid while cursor moves smoothly

- Joypad mode:
  - move the cursor with left stick
  - pan with right stick or edge scroll
  - place with action button
  - cancel with back button

- mouse+key mode:
  - move the cursor with mouse
  - place with left click
  - cancel with right click

- touch mode:
  - touch & hold to show ghost cursor
  - release to place item/object
  - render cancel button (big X) center bottom, release on this button to cancel (eg, player can drag to the button and then away from it without cancelling as long as they don't release)
    - button should visually change state when touch is pressed in its activation zone
  - disable drag scroll, use edge scroll instead (ie, while dragging the ghost of the entity, if cursor moves toward the edge then scroll)


# Commanding state

- used to select a target while issuing a command for a monster (entered from select mode)
- unlock the camera from the selected monster
- should continue to show monster select hud or some indication that we're commanding that monster
- when selecting an entity (or the ground), should replace that entity's context menu with a "command" menu containing interactions the selected monster can have with the entity (eg, approach, grab, etc)
  - note: actions should define icons and/or trans text to be used in the command menu

- touch mode:
  - cancel button on the bottom, like with placing state (does this cancel out of selecting the monster, or return to it?)


