# biology 2: synthesis

takeaways from simulating "biologically accurate" nutrition:

- calculating "real" work done to move a monster a given distance works well and feels great - we should keep this and just tweak the numbers as necessary.

- modelling edibles as complete energy sources (grams of protein/fat/carbs) is definitely Too Complex.  "digestion efficiency" is right out.  ultimately, **the energy value of food doesn't matter that much, because energy is primarily about activity.**

- I still like the idea of `porps`, `fobbles` and `scoses` as whimsical abstractions of real energy sources.  It's nice to have a nod to the fundamentals of real nutrition, even if our systems don't work the same way.

- while realistic BMR is extremely unbalanced, the basic idea of BMR as a differentiator is valid -- again, a nice nod to real-life biodiversity.

- restoring energy should require _both_ food and rest -- ie, sleeping should have an immediate and noticeable effect on a monster's energy meter, but sleep alone should not be a sufficient source of energy.

## the plan

- edibles are differentiated by food group tags and `porp`/`scose`/`fobble` content (ints, roughly equivalent to grams of protein/carbs/fat)

- monster BMR is a function of mass.  Mass-specific BMR is configurable as a multiplier, or more likely an enum (`very slow` ... `very fast`)


### nutrition

- monsters have `porp`/`scose`/`fobble` requirements (per day?) that influence the nutrition attribute

- monsters have food group tag requirements that influence the nutrition attribute

- (we can figure out the specific implementation details later when we tackle updating attributes more generally)


### belly

- belly capacity is still in kg, still determined by the monster's mass + data def (probably enum, small/medium/large)

- eating still fills the belly based on the mass of the edible

- belly decay rate is a percentage of belly capacity, modified by BMR and appetite (independent from energy decay)


### energy

- `energy` represents "capacity for activity": dependent on "stored chemical energy" (actual kcal), but more abstract/metaphysical

- `energy` should decay _slowly_ based on BMR (attrition)

- `porps`, `scoses` and `fobbles` themselves represent "stored chemical energy", and have some static conversion factor to `energy` (`fobbles` still double `porps`/`scoses`)

- monsters store consumed `porps`/`scoses`/`fobbles` and convert them to `energy` (catabolism) at a BMR-dependent rate

- monsters that can photosynthesize (and maybe plants too!) also generate and store `lumens`, which are catabolized with a static conversion factor just like the three normal energy sources
  - base `lumen` generation rate should probably be standard, not monster dependent (ie, we use a `can_photosynthesize` bool and not a multiplier)
  - actual `lumen` generation rate should depend on available sunlight (less if cloudy, none at night)

- attrition and catabolism should be balanced* so that:

  - standard catabolism rate is slightly higher than standard attrition rate, so that idling appears to recover energy slowly (as long as the monster has `porps`/`scoses`/`fobbles`/`lumens` to catabolize)

  - sleeping appears to restore energy quickly (by increasing catabolism, reducing attrition, or both)

  - the energy cost of moving is always higher than idle recovery rate (catabolism - attrition), but movement cost _relative to idle recovery rate_ is inversely proportional to the monster's mass-specific BMR modifier (ie, high MSBMR monsters burn & catabolize more energy by existing relative to the energy they require to move, so movement has a lower relative cost)


*Balancing this should Just Work so long as we define everything in relative terms, and all the variables that control energy spend and recovery are ultimately relative to the monster's mass:

* movement cost is relative to mass
* BMR is relative to mass (& configurable mass-specific BMR multiplier)
* catabolism rate is relative to BMR
* attrition rate is relative to BMR
