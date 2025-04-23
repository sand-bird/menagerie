# input

we want to support four control schemes simultaneously:

- mouse
- touch
- joypad
- keyboard

several of these overlap with each other. eg, joypad and keyboard-only do exactly the same things but with different inputs; thus, each important action should have both a joypad binding and a keyboard binding.

actions:

- interact/accept/confirm (ui_accept*)
  - joypad: x/a
  - key: space/enter

- back/cancel (ui_back*)
  - joypad: o/b
  - key: backspace/esc

- menu (menu) (NOT ui_menu)
  - joy: triangle/y
  - key: m

- ui directions (ui_left, ui_up, etc)*
  - joy: left stick, d-pad
  - key: wasd, arrows?
  - used to navigate menus (shift focus)

- next_tab, prev_tab
  - used to switch tabs on the main menu
  - joy: back triggers
  - key: tab, shift+tab
  - need to unbind tab & shift_tab from ui_focus* events

- next page, prev page
  - used to switch pages on main menu
  - joy: front triggers
  - key: q, e / shift+left, shift+right

- ui scroll
  - used to scroll scrolling panels without fucking with focus
  - joy: right stick
  - key: arrows

- move cursor
  - joy: binding a stick to this directly gives us greater control, since joystick axes support variable action strength. should be able to choose the stick
  - key: wasd

- pan camera
  - joy: right stick
  - key: arrows
