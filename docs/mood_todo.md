- implementing mood
  - existing actions (eat, move) should affect mood
    - two axes here: preference for target & drive delta

      - implement preference
        - keys: either entity uuids (specific entities, eg another monster), or entity ids (entity types, eg apples)
        - values: -1 to 1, like attributes, default at 0 (ie, when a monster encounters an entity for the first time, add a key for that entity to its preferences with value 0)
          - exclude uuids for items since those are interchangeable/disposable
        - feedback mechanism: after an action with some target entity affects a monster's mood, update the monster's preference for that entity (id & uuid, unless item)
        - first pass: leave out feedback, instead of defaulting at 0, default at a random value so we can see the effects of preference in action

      - implement some mechanic to translate improved drives to improvements in mood
        - use for action utility estimations and actual mood gains
        - maybe we can adapt the drive delta utility calculation logic to generate a mood delta
      
  - patience checks
    - at a threshold of drive delta (difference between current drive value & desired value) dependent on monster's patience attribute, proc a composure roll
    - composure roll:
      1. emote a struggling face
      2. wait some amount of time (dependent on loyalty attribute?) to give player a chance to encourage
         - TODO: implement monster interaction ***
         - encouraging should
           1. make the monster more likely to succeed the composure check
           2. increase its loyalty
      3. depending on the monster's composure attr and whether it was encouraged by player, succeed or fail composure roll
         - if success: no mood decrease, positive emote, possible mood increase
         - if failure: mood decreases in a large chunk (mood hit), sad emote

  - implement mood attrition, maybe (we don't necessarily need this with drive attrition and patience procs, so possibly optional (but easy))

  - implement happiness attribute
    - once per day, sample the monster's mood and average it into the happiness trait
    - implement updating attributes (we should do vigor too)


*** prerequisite for patience checks: monster interaction

- implement cursor modes
  - free, selecting, commanding, placing
  - different behavior for different input modes (mouse+key, touch, joypad)
    - implement input mode controls (settings menu)
  - modular radial menu with actions (should support arbitrary number of actions < some threshold, render them in a circle, handle inputs)
  