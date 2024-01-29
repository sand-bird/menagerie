# biology 3

more takeaways:

- running out of energy sources is poorly telegraphed and punishing because it happens so suddenly - we go from breaking even to seeing the full impact of attrition, which is greater for larger monsters.
  - at the very least, we should cap the amount of energy sources we consume - eg, no more than 10% of remaining, so running out of energy will happen more gradually (done)

- death loop scenario, illustrated by milotic:
  1. the pet runs out of stored energy, attrition takes over and the pet's energy quckly falls to 0
  2. the pet cannot regain any energy until it eats something else, but moving to food costs energy
  3. if the energy cost of moving to the food is greater than the energy recovery offered by the food, the pet will sleep or idle instead, potentially indefinitely

- pets always immediately go to sleep after eating
  - this seems normal/expected for now since the only drives we use are belly and energy - adding actions that operate on social/mood should mitigate this

- stored energy sources scale boundlessly & without balance - eg pufig & bunny eat more than they catabolize so their stored `scoses`` will continually increase

ways to deal with death loops:

1. implement literal death, and have pets die of starvation
   - this _is_ worth considering, but not at this point in development - we should revisit the idea of pet death after pet lifecycles are more developed.
   - pet death needs to be extremely telegraphed & have lots of opportunities to prevent
2. allow pets to perform energy-consuming actions (moving to food) even when they have no energy
   - this goes against the spirit of energy as "capacity for action", though i think we could make it work (the pet would be taking massive mood hits from having no energy)
3. change energy regeneration so that consuming energy sources is no longer a hard requirement

the case for softening food energy requirements:

it's tempting to require food for energy regeneration because (a) that's how it works in real life and (b) food is a new mechanic and we want it to feel impactful. however, in gameplay terms it makes more sense for each primary drive to have its own recovery mechanic (belly: eat, social: interact, energy: rest). this will make systems clearer to the player and easier to tune - eg, we can adjust belly attrition rates to require more/less food without having to worry much about the effect this will have on energy.

_however_, i still think that energy value is a useful differentiator for food. so, rather than a hard requirement for energy recovery, we can have food energy apply a buff to natural energy recovery. to keep things balanced (and solve the problem of infinitely scaling energy sources), maybe something like this:

- consuming food still absorbs energy sources
- a portion of stored energy decays each tick - scaled by BMR, calibrated according to real-life digestion rates (eg scoses in ~4 hours)
- energy recovery for that tick is modified based on the amount of energy sources consumed (or the amount remaining)
  - what's the threshold? ie, what's the maximum multiplier (2x?) and how do we determine the quantity of energy sources consumed/remaining required to yield that multiplier?
  - define a "max digestible" threshold based on monster mass/bmr, any energy source above that threshold is wasted:
     ```gdscript
     scale = clampf(source / max_digestible, 0, 1)
     multiplier lerpf(1, 2, scale)
     ```

this plus exponential decay should help address the issue that energy sources scale independently from mass - eg, it's possible to define a food with little mass but thousands of grams of energy sources.  for energy purposes, this food will simply buff energy recovery rates for longer.  later, once we tackle the nutrition attribute, we can set standards for how much of each energy source is healthy for a pet at any given time.

note: regardless of initial value, exponential decay means that once an energy source hits `max_digestible` value it will decay at the same rate every time. a higher `max_digestible` will reach this point earlier and decay more slowly after, while a lower value will reach it more slowly and decay more quickly (given the same energy source intake).