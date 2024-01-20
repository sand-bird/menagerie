# Notes on digestive biology

trying to figure out how to simulate food & nutrition

### References

- [Cats and carbohydrates](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5753635/)
- [A Guide to the Principles of Animal Nutrition (Oregon State University)](https://open.oregonstate.education/animalnutrition)
- [Allometry: Body Size Constraints in Animal Design](https://www.ncbi.nlm.nih.gov/books/NBK218080/)
- [What determines the basal rate of metabolism?](https://journals.biologists.com/jeb/article/222/15/jeb205591/3856/What-determines-the-basal-rate-of-metabolism)
- [Calculating the metabolizable energy of macronutrients](https://academic.oup.com/nutritionreviews/article/75/1/37/2684502)
- [The Role of Fiber in Ruminant Ration Formation](https://cdn.canr.udel.edu/wp-content/uploads/2014/02/The-Role-of-Fiber-in-Ruminant-Ration-Formulation.pdf)
- [Measuring food digestion rates](https://ifst.onlinelibrary.wiley.com/doi/epdf/10.1002/fsat.3004_14.x)

## Food facts

- Energy in food comes primarily from carbohydrates, fats, proteins, and alcohol (ethanol); organisms metabolize these into energy (catabolism) for powering muscles or building new compounds (anabolism).
- Food also contains vitamins, water (contributes to volume but not energy, lowering energy density), and cellulose/fiber (normally inert but can be metabolized into carbs by herbivores).
- Basal metabolic rate (rate of energy decay) is measured in unit energy per unit time per unit mass (kcal / hour / kg), and increases when it's cold or when the animal is stressed.
- The amount of energy an animal can extract from a food source depends on its metabolism - eg, herbivores have long, slow digestive systems that decompose cellulose into carbohydrates so they can metabolize it.
- Carnivory vs herbivory also depends on the presence of specific nutrients:
  - "Cats have high protein requirements and their metabolisms appear unable to synthesize essential nutrients such as retinol, arginine, taurine, and arachidonic acid; thus, in nature, they must consume flesh to supply these nutrients."
  - "it appears that nectar-feeding birds such as sunbirds rely on the ants and other insects that they find in flowers, not for a richer supply of protein, but for essential nutrients such as cobalt/vitamin b12 that are absent from nectar. Similarly, monkeys of many species eat maggoty fruit, sometimes in clear preference to sound fruit."
- Protein & carbs provide 4 kcal/gram; fats provide 9 kcal/gram; soluble fibers apparently provide 2 kcal/gram
- Recommended daily allowance of protein for a human is 0.8 grams (3.2 kcal) protein per kilogram body weight

Some food stats via fatsecret.com:


| food (100g)    | calories | fat    | carbs  | protein |
| -------------- | -------- | ------ | ------ | ------- |
| apples         | 52       | 0.17g  | 13.81g | 0.26g   |
| strawberries   | 32       | 0.3g   | 7.68g  | 0.67g   |
| spinach        | 23       | 0.39g  | 3.63g  | 2.86g   |
| macadamia nuts | 716      | 76.08g | 12.83g | 7.79g   |
| almonds        | 578      | 50.64g | 19.74g | 21.26g  |
| abalone        | 149      | 3.74g  | 7.42g  | 19.97g  |
| "meat"         | 287      | 19.29g | 0g     | 26.41g  |


## Simulation interpretation

The goal here is to support meaningful variety in both content (allowing for a large variety of foods with meaningful differences) and gameplay (encouraging interesting choices about which foods to cultivate).

The main vector for meaningful variety in food is its impact on monsters. As much as possible, different foods should be optimal for different monsters in different contexts - in other words, the food system should support a large variety of _diets_ (without being overly complex, like nutrition in real life).

There are two components to a diet: what an animal _can_ eat (determined by its metabolism) and what an animal _will_ eat (determined by its ecological niche). For modelling food we mostly care about the former, since the latter can be handled using preferences.

To summarize the facts above:

- There are generally two reasons for an animal to _require_ a specific diet:
  1. Its metabolism is specialized to process some energy sources better than others, or to require them in greater proportion (carnivores with protein, herbivores with cellulose/carbs, polar bears with fat)
  2. It requires nutrients from certain kinds of foods (cats cannot produce their own taurine or vitamin A, so must derive it from meat)
- As energy sources, foods are mostly interchangeable - the energy they provide comes from their protein, fat, and carbohydrate content.
  - Protein is protein no matter what food group it comes from (basically; there are different kinds of protein/fat/carbs, but the differences are moot for our purposes)
  - Two foods in the same group may have very different protein/fat/carb content
- Nutrients do not supply energy but are necessary for general health, and are so complex and varied that it's not worth modeling them individually (wtf even is taurine, and who needs it besides cats?) - instead, we can generalize by food group, eg "meat nutrients", "fruit nutrients", "fungus nutrients" etc.


### Food preference

Animals do not always choose nutritionally optimal food sources; eg pandas, which subsist on bamboo even though they are biological carnivores with high protein requirements. 

An individual monster's preferences evolve over time, but just like attributes, monster data definitions can specify innate preferences. These can be used to bias a species toward a certain kind of food; eg, a monster based on a panda would have an innately high preference for a "bamboo" entity, causing it to choose to eat bamboo even when there are more nutritious foods available.


### Belly

- The belly represents undigested food. Each tick, it empties by some amount (based on the monster's metabolic rate), and the energy content of that food (based on the belly's current energy density) is added to the pet's energy meter.
- Different monsters should have dfferent belly sizes! Units mass (kg), should be some fraction of the monster's mass
- When new food is consumed, we calculate its energy density (based on the food's energy content versus the pet's digestive coefficients, and the food's mass), and combine it with the energy density of the existing stomach contents.


### Energy and nutrients

"Food value" occurs along two separate axes: energy and nutrients.

We already have a concept of energy as a drive, and a nebulous idea of a "health" attribute that contributes to VIT. This dovetails nicely with the idea of splitting consumables into energy value and nutrient value.

#### Energy

Recap: in real life, energy comes as protein, carbs, or fats, and different kinds of animals have varying needs of each.

Using the real-life names is kind of mundane (this is a fantasy setting after all). Tentative analogies are **porps** (protein; red-purple), **scoses** (carbs; yellow-orange), and **fobbles** (fats; blue-green).

To these three basic natural energy sources, we can add some more:

* Fiber -- generally inert, but some herbivores can digest this with the help of gut microfauna (actually they process it into carbs/fats and then digest it, but for our purposes fiber -> energy)
* Mana -- it'd be cool to have mons that can eat magic, but this should _not_ be a property of the `edible` trait
* Sunlight -- some monsters may be able to photosynthesize to meet some or all of their energy requirements. (should also not be a property of `edible`)


##### Monsters

Different animals/monsters can metabolize different energy sources more or less efficiently. In nature, this is most relevant with fiber, which is normally inert but can be metabolized by ruminants after their specially adapted digestive systems decompose it into fatty acid and carbs. In the game, monsters may also derive energy from sunlight and magic (though by default they cannot).

```json
// default energy source efficiency
"protein": 1.0,
"carbs": 1.0,
"fats": 1.0,
"fiber": 0.05,
"light": 0.0,
"mana": 0.0
```

Energy sources are _also_ nutrients, and different animals require different proportions of them in their diet -- eg, a cat that only eats fatty meats should be less healthy than a cat that eats lean meats with a higher protein-to-fat ratio.  We can model this with an `ideal_energy_source_ratio` property on monster data definitions. Energy sources not present are assumed to be 0 (totally unnecessary). 

```json
// cat.json
// source: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5753635/
{
  "energy_source_efficiency": {
    "carbs": 0.7, // splitting the difference between 40% and 100%
  },
  "ideal_energy_source_balance": {
    "protein": 0.52,
    "fats": 0.46,
    "carbs": 0.02,
  }
}
```

##### Edibles

On edible entities, we specify the amount of each energy source the entity contains. In this example the amounts are in grams total (so ~double the apple stats from fatsecret, since those apply to 100g of apples and this apple is 200g). It may be more consistent to define them in grams per 100g, though.

Note that these should always add up to less than the entity's mass. In the apple's case it is _significantly_ less because apples are mostly water, but e.g. nuts are much more energy-dense (macadamia nuts are 96% protein/fat/carbs, see above).

```json
apple.json
{
  "mass": 0.2, // kg
  "traits": {
    "edible": {
      "carbs": 28, // grams
      "protein": 0.5,
      "fats": 0.4,
      "fiber": 5
    }
  },
  "tags": [ "fruit" ]
}
```


#### Nutrients

Nutrients can be distilled into food groups. If foods are mostly interchangeable as energy sources (assuming similar protein/carb/fat content), the opposite should be true for nutrients -- they determine which foods a monster requires in order to be healthy, and which foods are toxic to it.

##### Food groups

Food groups can be as granular as we want, see https://en.wikipedia.org/wiki/List_of_feeding_behaviours for a decent list:

These aren't properties of the `edible` trait, but rather tags on the entity.

- meat
  - egg
  - blood
  - various types of animals
- fruit
- vegetable
- flower
- nut
- leaf
- grass
- seeds
- nectar
- pollen
- wood
- earth
- fungus
- rotten


```json
// cat.json
{
  "nutrients": {
    "meat": 1,
    "vegetable": 0.1,
    "fruit": 0.1,
    "allium": -1,
    "chocolate": -1
  }
}
```

##### Toxicity

The following foods are toxic to cats:
- allium (sulphoxides)
- chocolate (theobromine)
- caffeine (methylxanthine)
- grape (also raisins and currants, unknown why)

Most of these are pretty specific so we wouldn't necessarily expect them to be real tags - maybe allium and chocolate would be the most likely. It is okay if our virtual cats are not allergic to grapes.



<svg width="100%" viewBox="0 0 700 700" xmlns="http://www.w3.org/2000/svg" version="1.1"><g transform="translate(350, 350)"><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M43.551630582721955,-63.09542971851365C21.775815291360978,-31.547714859256825 -7.162728056394519,37.65819660093382 0,0"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-21.330005566928,73.63972189173856C-10.665002783464,36.81986094586928 -7.162728056394519,37.65819660093382 0,0"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-24.277879524779532,-72.72112721594785C-12.138939762389766,-36.36056360797392 -7.162728056394519,37.65819660093382 0,0"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M48.55575904955911,-145.44225443189566C36.41681928716933,-109.08169082392175 65.32744587408293,-94.64314457777047 43.551630582721955,-63.09542971851365"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M118.77276081357371,-96.97495759129119C89.07957061018028,-72.7312181934684 65.32744587408293,-94.64314457777047 43.551630582721955,-63.09542971851365"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M150.23456664648106,30.670606378993465C112.67592498486079,23.002954784245098 -31.995008350392002,110.45958283760784 -21.330005566928,73.63972189173856"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M122.92714000939431,194.39371967507276C81.95142667292954,129.5958131167152 -42.660011133856,147.27944378347712 -21.330005566928,73.63972189173856"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-110.58437525938494,106.21773420480521C-82.9382814445387,79.6633006536039 -31.995008350392002,110.45958283760784 -21.330005566928,73.63972189173856"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-118.77276081357377,-96.97495759129112C-89.07957061018031,-72.73121819346834 -31.995008350392002,110.45958283760784 -21.330005566928,73.63972189173856"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-48.555759049559065,-145.4422544318957C-36.4168192871693,-109.08169082392176 -36.4168192871693,-109.08169082392176 -24.277879524779532,-72.72112721594785"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M36.89459459728486,-227.02156040671994C30.745495497737384,-189.18463367226664 60.69469881194889,-181.80281803986958 48.55575904955911,-145.44225443189566"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M72.83363857433866,-218.1633816478435C60.69469881194889,-181.80281803986958 60.69469881194889,-181.80281803986958 48.55575904955911,-145.44225443189566"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M106.88632957006678,-203.65488590023827C89.071941308389,-169.71240491686524 60.69469881194889,-181.80281803986958 48.55575904955911,-145.44225443189566"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M165.87656288907732,-159.32660130720788C138.2304690742311,-132.77216775600658 148.46595101696715,-121.218696989114 118.77276081357371,-96.97495759129119"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M189.286289155541,-130.65489174816582C157.73857429628418,-108.87907645680485 148.46595101696715,-121.218696989114 118.77276081357371,-96.97495759129119"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M220.91916567521562,-63.99001670078413C184.09930472934636,-53.32501391732011 187.79320830810133,38.33825797374183 150.23456664648106,30.670606378993465"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M228.3230410425524,-27.723436458724287C190.2692008687937,-23.102863715603576 187.79320830810133,38.33825797374183 150.23456664648106,30.670606378993465"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M229.81346957946104,9.261166225165422C191.51122464955088,7.717638520971186 187.79320830810133,38.33825797374183 150.23456664648106,30.670606378993465"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M225.35184996972157,46.005909568490196C187.79320830810133,38.33825797374183 187.79320830810133,38.33825797374183 150.23456664648106,30.670606378993465"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M215.05373581764542,81.55912401978321C179.21144651470453,67.96593668315268 187.79320830810133,38.33825797374183 150.23456664648106,30.670606378993465"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M199.1858428704209,114.99999999999999C165.98820239201743,95.83333333333333 187.79320830810133,38.33825797374183 150.23456664648106,30.670606378993465"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M178.1591412203606,145.46243638693676C148.46595101696715,121.21869698911397 187.79320830810133,38.33825797374183 150.23456664648106,30.670606378993465"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M55.042602786138254,223.31661800799196C45.86883565511522,186.09718167332665 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M18.50731080484693,229.2541808708683C15.422759004039111,191.0451507257236 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-18.507310804846803,229.2541808708683C-15.422759004039005,191.0451507257236 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-55.042602786138225,223.316618007992C-45.86883565511519,186.09718167332667 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-90.15232026781725,211.59527204152957C-75.12693355651437,176.32939336794132 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-122.92714000939426,194.3937196750728C-102.4392833411619,161.994766395894 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-152.5182113953829,172.15747207935323C-127.09850949615245,143.4645600661277 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-178.15914122036065,145.46243638693662C-148.46595101696724,121.21869698911387 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-199.1858428704209,114.99999999999999C-165.98820239201743,95.83333333333333 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-215.0537358176454,81.55912401978324C-179.2114465147045,67.9659366831527 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-225.35184996972157,46.00590956849024C-187.79320830810133,38.33825797374187 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-229.813469579461,9.26116622516557C-191.51122464955085,7.71763852097131 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-228.32304104255238,-27.723436458724454C-190.2692008687937,-23.102863715603714 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-220.91916567521568,-63.99001670078399C-184.09930472934641,-53.32501391732 -138.23046907423117,132.77216775600652 -110.58437525938494,106.21773420480521"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-189.2862891555411,-130.65489174816562C-157.73857429628427,-108.87907645680471 -148.4659510169672,-121.21869698911391 -118.77276081357377,-96.97495759129112"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-165.87656288907735,-159.32660130720785C-138.23046907423114,-132.77216775600655 -148.4659510169672,-121.21869698911391 -118.77276081357377,-96.97495759129112"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-106.88632957006672,-203.6548859002383C-89.07194130838894,-169.71240491686527 -60.69469881194883,-181.8028180398696 -48.555759049559065,-145.4422544318957"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-72.8336385743386,-218.16338164784352C-60.69469881194883,-181.8028180398696 -60.69469881194883,-181.8028180398696 -48.555759049559065,-145.4422544318957"></path><path class="link" style="fill: none; stroke: rgb(60, 60, 60); stroke-width: 1px;" d="M-36.89459459728493,-227.02156040671994C-30.745495497737448,-189.18463367226664 -60.69469881194883,-181.8028180398696 -48.555759049559065,-145.4422544318957"></path><g class="node" transform="rotate(100.76923076923077)translate(0)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;"></text></g><g class="node" transform="rotate(-55.38461538461538)translate(76.66666666666667)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Acellular matter</text></g><g class="node" transform="rotate(106.15384615384613)translate(76.66666666666667)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Live matter</text></g><g class="node" transform="rotate(251.53846153846155)translate(76.66666666666667)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Dead matter</text></g><g class="node" transform="rotate(-71.53846153846155)translate(153.33333333333334)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Hard matter</text></g><g class="node" transform="rotate(-39.23076923076923)translate(153.33333333333334)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Exudativory</text></g><g class="node" transform="rotate(11.538461538461533)translate(153.33333333333334)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Herbivory</text></g><g class="node" transform="rotate(57.69230769230768)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Fungivory</text></g><g class="node" transform="rotate(136.15384615384616)translate(153.33333333333334)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Carnivory</text></g><g class="node" transform="rotate(219.23076923076923)translate(153.33333333333334)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Zoophagy</text></g><g class="node" transform="rotate(251.53846153846155)translate(153.33333333333334)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Saprophagy</text></g><g class="node" transform="rotate(-80.76923076923077)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Keratophagy</text></g><g class="node" transform="rotate(-71.53846153846155)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Lepidophagy</text></g><g class="node" transform="rotate(-62.30769230769231)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Osteophagy</text></g><g class="node" transform="rotate(-43.846153846153854)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Nectarivore</text></g><g class="node" transform="rotate(-34.61538461538461)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Mucophagy</text></g><g class="node" transform="rotate(-16.15384615384616)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Algivory</text></g><g class="node" transform="rotate(-6.92307692307692)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Florivory</text></g><g class="node" transform="rotate(2.3076923076922924)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Folivory</text></g><g class="node" transform="rotate(11.538461538461533)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Fructivory</text></g><g class="node" transform="rotate(20.769230769230774)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Granivory</text></g><g class="node" transform="rotate(30)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Palynivory</text></g><g class="node" transform="rotate(39.230769230769226)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Xylophagy</text></g><g class="node" transform="rotate(76.15384615384616)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Bacterivory</text></g><g class="node" transform="rotate(85.38461538461539)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="start" transform="translate(8)" style="font-size: 11px; font-family: Arial, Helvetica;">Anurophagy</text></g><g class="node" transform="rotate(94.61538461538458)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Avivory</text></g><g class="node" transform="rotate(103.84615384615384)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Durophagy</text></g><g class="node" transform="rotate(113.07692307692307)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Haematophagy</text></g><g class="node" transform="rotate(122.30769230769232)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Invertivory</text></g><g class="node" transform="rotate(131.53846153846155)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Molluscivory</text></g><g class="node" transform="rotate(140.7692307692308)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Ophiophagy</text></g><g class="node" transform="rotate(150)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Ovivory</text></g><g class="node" transform="rotate(159.23076923076923)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Piscivory</text></g><g class="node" transform="rotate(168.46153846153845)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Spongivory</text></g><g class="node" transform="rotate(177.69230769230768)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Teuthophagy</text></g><g class="node" transform="rotate(186.92307692307696)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Vermivory</text></g><g class="node" transform="rotate(196.15384615384613)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Zooplanktonivory</text></g><g class="node" transform="rotate(214.61538461538458)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Parasiting</text></g><g class="node" transform="rotate(223.84615384615387)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Necrophagy</text></g><g class="node" transform="rotate(242.30769230769232)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Coprophagy</text></g><g class="node" transform="rotate(251.53846153846155)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Detritivory</text></g><g class="node" transform="rotate(260.7692307692308)translate(230)"><circle r="4.5" style="fill: rgb(238, 238, 238); stroke: rgb(153, 153, 153); stroke-width: 1px;"></circle><text dy=".31em" text-anchor="end" transform="rotate(180)translate(-8)" style="font-size: 11px; font-family: Arial, Helvetica;">Geophagy</text></g></g></svg>
