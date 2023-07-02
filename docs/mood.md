# Mood

## Sympathy

Social actions should impact the actor's mood based on their impact on the target's mood; we can call this mood feedback "sympathy".  The formula should depend on the following:

- **preference**: actor's preference for the target is a direct multiplier: the actor's mood changes by a portion of the target's mood determined by the preference value
  - a negative preference for the target means the monster gains mood for actions that _lower_ the target's mood, and vice versa
  - the further the preference is from neutral (0), the greater the multiplier
  - if the actor's preference for the target is perfectly neutral (0), the resulting mood change (from preference) is also 0
- **kindness**:
  - convert from a (0, 1) attribute to a (-1, 1) multiplier: `kindness * 2 - 1`
    - can shrink/grow this with an additional multiplier on the result
  - direct multiplier on result of mood action, such that low kindness means the monster gains mood for actions that lower the target's mood
  - additive with preference result: on an action that raises the target's mood, a negative mood result from low preference should offset a positive result from high kindness
- **empathy**:
  - convert from (0, 1) attribute to (0, 2) multiplier: `empathy * 2`.
  - multiplies the impact to the target's mood for the purpose of the calculation. eg, if the target's mood changes by 0.2 and the actor's empathy is 0.4 (converted to a multiplier of 0.8), the sympathy formula will use a value of 0.16 for the target's mood change.

### Mood-based utility modifiers

Monsters in a bad mood should be more inclined to select actions with negative consequences to other pets' moods, even if the utility of those actions (the actual change to the actor's mood, per the sympathy calculation) is not any higher than normal.

Actions have two levers for this: `estimate_result` can be purposefully made inaccurate, or `mod_utility` can be used to directly apply a modifier to the utility calculated from the estimated result.


## Unmet drives & patience

If one of a monster's drives falls below a threshold, there is a chance to proc a patience check. The probability increases the further the drive is below the threshold.

In a patience check:
1. the monster emotes/announces the drive it needs ("X is hungry")
2. we roll to see whether or not the monster takes damage to its mood. The probability is determined by:
   * the monster's **patience** attribute
   * its current patience counter
3. if the roll succeeds (no mood hit), we increment the monster's patience check counter.  If the roll fails, reset the counter

(Note: patience is increased by meeting the monster's needs when its patience counter is above 0)

QUESTION: how to determine the magnitude of the mood hit? could this be modified by an attribute (willpower, poise)?

## Composure

When a monster suffers a mood hit (mood damage outside of attrition - maybe above a certain threshold), it has a chance to perform a composure check. (QUESTION: does anything modify this probability? composure? some other attribute (willpower/fortitude)?)

In a composure check:
1. the monster emotes a stress / "about to cry" face
2. wait for X ticks. the player can "encourage" the monster during this interval to substantially increase the odds of the composure roll
3. roll against the monster's **composure** attribute, modified by encouragement
4. if the roll succeeds, the monster emotes a triumphant face and does not take a mood hit (maybe even gets a small mood bonus).  If the roll fails, the monster emotes a dejected face and takes a mood hit
