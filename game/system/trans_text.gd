extends Object
class_name T
"""
this is an index of all translatable text in the game's code (datafiles define
per-language translatable text strings internally).  its purpose is to make sure
that any text we define in the game's code which is supposed to be translatable
will be accounted for when it comes time to create a translations csv.

all strings meant for display should reference a constant in this namespace (eg,
T.MONDAY).  since these are all constants they can be accessed from anywhere.

for now, values are simply the text in english.  when we add a translations csv,
we can either use that english text as the translation key, or create proper
translation keys and update all these values to match.
"""

const RECORDS = &"records"

#                                b u t t o n s                                #
# --------------------------------------------------------------------------- #
const NEW_GAME = &"new game"
const LOAD_GAME = &"load game"
const QUIT_GAME = &"quit game"
const QUIT_TO_TITLE = &"quit to title"

#                              m a i n   m e n u                              #
# --------------------------------------------------------------------------- #

# main menu section titles
const MONSTER_LIST = &"monster list"
const MONSTER_INFO = &"monster info"
const MONSTERS = &"monsters"
const ITEMS = &"items"
const OBJECTS = &"objects"
const ENCYCLOPEDIA = &"encyclopedia"
const OPTIONS = &"options"

# section titles on the monster info ui
const ATTRIBUTES = &"attributes"
const SPECIES = &"species"
const AGE = &"age"
const TRAITS = &"traits"
const BIRTHDAY = &"birthday"

#                                  c l o c k                                  #
# --------------------------------------------------------------------------- #
const YEAR = &"year"

const MONDAY = &"monday"
const TUESDAY = &"tuesday"
const WEDNESDAY = &"wednesday"
const THURSDAY = &"thursday"
const FRIDAY = &"friday"
const SATURDAY = &"saturday"
const SUNDAY = &"sunday"

const VERNE = &"verne"
const TEMPEST = &"tempest"
const ZENITH = &"zenith"
const SOL = &"sol"
const HEARTH = &"hearth"
const HALLOW = &"hallow"
const AURORA = &"aurora"
const RIME = &"rime"

#                                f l a v o r s                                #
# --------------------------------------------------------------------------- #

const SWEET = &"sweet"
const SOUR = &"sour"
const SALTY = &"salty"
const BITTER = &"bitter"
const SPICY = &"spicy"
const SAVORY = &"savory"
const TART = &"tart"


# =========================================================================== #
#                                   T A G S                                   #
# --------------------------------------------------------------------------- #

const FRUIT = &"fruit"
const VEGETABLE = &"vegetable"
const MEAT = &"meat"
const MINERAL = &"mineral"
const FUNGUS = &"fungus"
