////
// FileDataStore.m
// Incidents
////
// See the file COPYRIGHT for copyright information.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////
#import "utilities.h"
#import "Ranger.h"
#import "Incident.h"
#import "FileDataStore.h"



NSArray *getRangerHandles(void);



@interface FileDataStore ()

@property (strong) NSMutableDictionary *allIncidentsByNumber;
@property (assign) int nextIncidentNumber;
@property (strong) NSFileWrapper *fileStorage;

@end



@implementation FileDataStore


- (id) init
{
    if (self = [super init]) {
//        [self load]; // FIXME
    }
    return self;
}


@synthesize delegate=_delegate;


- (NSURL *) applicationDataDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* supportDirectories = [fileManager URLsForDirectory:NSApplicationSupportDirectory
                                                      inDomains:NSUserDomainMask];

    if (! supportDirectories.count) {
        performAlert(@"No application support directory?!?");
        return nil;
    }

    NSURL *supportDirectory = [supportDirectories objectAtIndex:0];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL *appDirectory = [supportDirectory URLByAppendingPathComponent:bundleID];

    return appDirectory;
}


- (NSURL *) dispatchQueueDataDirectory
{
    NSURL *appDataDirectory = [self applicationDataDirectory];

    if (! appDataDirectory) {
        return nil;
    }

    NSURL *queueDataDirectory =
    [appDataDirectory URLByAppendingPathComponent:@"Dispatch Queue"];

    return queueDataDirectory;
}


- (void) load
{
    NSError *error;

    NSLog(@"Loading incidents...");

    self.allIncidentsByNumber = [NSMutableDictionary dictionary];

    // Create the data directory if it doesn't exist
    NSURL *queueDataDirectory = [self dispatchQueueDataDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager createDirectoryAtURL:queueDataDirectory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error]) {
        performAlert(@"Can't create data directory: %@", error);
        return;
    }

    NSArray *childURLs = [fileManager contentsOfDirectoryAtURL:queueDataDirectory
                                    includingPropertiesForKeys:nil
                                                       options:0
                                                         error:&error];

    if (! childURLs) {
        performAlert(@"Unable to enumerate data directory: %@", error);
        return;
    }

    NSInteger maxNumber = 0;

    for (NSURL *childURL in childURLs) {
        // Skip dot files
        if ([childURL.lastPathComponent hasPrefix:@"."]) {
            continue;
        }

        NSData *data = [NSData dataWithContentsOfURL:childURL options:0 error:&error];

        if (! data) {
            performAlert(@"Unable to read file: %@", error);
            return;
        }

        NSDictionary *incidentJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

        Incident *incident = [Incident incidentInDataStore:self fromJSON:incidentJSON error:&error];
        if (! incident || error) {
            performAlert(@"Unable to deserialize incident: %@", error);
            return;
        }

        if (incident.number.intValue > maxNumber) {
            maxNumber = incident.number.intValue;
        }

        self.allIncidentsByNumber[incident.number] = incident;

        id <DataStoreDelegate> delegate = self.delegate;
        [delegate dataStore:self didUpdateIncident:incident];
        NSLog(@"Loaded: %@", incident);
    }

    self.nextIncidentNumber = (NSUInteger)maxNumber + 1;

    return;
}


- (void) loadIncidentNumber:(NSNumber *)number {
    // FIXME ??
    return;
}


- (NSArray *) incidents
{
    return self.allIncidentsByNumber.allValues;
}


- (Incident *) incidentWithNumber:(NSNumber *)number
{
    return self.allIncidentsByNumber[number];
}


- (Incident *) createNewIncident
{
    NSNumber *temporaryNumber = @-1;

    while (self.allIncidentsByNumber[temporaryNumber]) {
        temporaryNumber = [NSNumber numberWithInteger:temporaryNumber.integerValue-1];
    }

    return [[Incident alloc] initInDataStore:self withNumber:temporaryNumber];
}


- (void) updateIncident:(Incident *)incident
{
    if (! incident || ! incident.number) {
        performAlert(@"Cannot commit invalid incident: %@", incident);
        return;
    }
    if (incident.isNew) {
        incident.number = [NSNumber numberWithInt:self.nextIncidentNumber++];
    }
    self.allIncidentsByNumber[incident.number] = incident;
    [self writeIncident:incident];
}


- (BOOL) writeIncident:(Incident *)incident
{
    NSError *error;

    NSLog(@"Writing incident: %@", incident);

    NSURL *queueDataDirectory = [self dispatchQueueDataDirectory];
    NSURL *childURL = [queueDataDirectory URLByAppendingPathComponent:incident.number.stringValue];

    // Option: NSJSONWritingPrettyPrinted
    NSData *data = [NSJSONSerialization dataWithJSONObject:[incident asJSON] options:0 error:&error];
    if (! data) {
        performAlert(@"Unable to serialize to incident %@ to JSON: %@", incident, error);
        return NO;
    }

    if (! [data writeToURL:childURL options:0 error:&error]) {
        performAlert(@"Unable to write file: %@", error);
        return NO;
    }
    
    return YES;
}


- (NSArray *) rangers
{
    NSArray *rangerHandles = getRangerHandles();

    NSMutableArray *rangers = [NSMutableArray arrayWithCapacity:rangerHandles.count];

    for (NSString *rangerHandle in rangerHandles) {
        Ranger *ranger = [[Ranger alloc] initWithHandle:rangerHandle name:nil];

        [rangers addObject:ranger];
    }

    return rangers;
}


- (NSDictionary *) allRangersByHandle
{
    if (! _allRangersByHandle) {
        NSMutableDictionary *rangers = [[NSMutableDictionary alloc] initWithCapacity:self.rangers.count];

        for (Ranger *ranger in self.rangers) {
            rangers[ranger.handle] = ranger;
        }

        _allRangersByHandle = rangers;
    }
    return _allRangersByHandle;
}
@synthesize allRangersByHandle=_allRangersByHandle;


- (NSArray *) allIncidentTypes
{
    return @[
             @"Admin",
             @"Art",
             @"Echelon",
             @"Eviction",
             @"Fire",
             @"Gate",
             @"Green Dot",
             @"HQ",
             @"Law Enforcement",
             @"Medical",
             @"Mental Health",
             @"SITE",
             @"Staff",
             @"Theme Camp",
             @"Vehicle",
             
             @"Junk",
             ];
}


- (NSArray *) allLocationNames
{
    return @[];
}


- (NSArray *) addressesForLocationName:(NSString *)locationName {
    return @[];
}


@end



NSArray *getRangerHandles(void)
{
    return @[
             @"2Wilde",
             @"Abakus",
             @"Abe",
             @"ActionJack",
             @"Africa",
             @"Akasha",
             @"Amazon",
             @"Anime",
             @"Answergirl",
             @"Apparatus",
             @"Archer",
             @"Atlantis",
             @"Atlas",
             @"Atomic",
             @"Atticus",
             @"Avatar",
             @"Awesome Sauce",
             @"Axle",
             @"Baby Huey",
             @"Babylon",
             @"Bacchus",
             @"Backbone",
             @"Bass Clef",
             @"Batman",
             @"Bayou",
             @"Beast",
             @"Beauty",
             @"Bedbug",
             @"Belmont",
             @"Bender",
             @"Beow",
             @"Big Bear",
             @"BioBoy",
             @"Bjorn",
             @"BlackSwan",
             @"Blank",
             @"Bluefish",
             @"Bluetop",
             @"Bobalicious",
             @"Bobo",
             @"Boiler",
             @"Boisee",
             @"Boots n Katz",
             @"Bourbon",
             @"Boxes",
             @"BrightHeart",
             @"Brooklyn",
             @"Brother",
             @"Buick",
             @"Bumblebee",
             @"Bungee Girl",
             @"Butterman",
             @"Buzcut",
             @"Bystander",
             @"CCSallie",
             @"Cabana",
             @"Cajun",
             @"Camber",
             @"Capitana",
             @"Capn Ron",
             @"Carbon",
             @"Carousel",
             @"Catnip",
             @"Cattus",
             @"Chameleon",
             @"Chenango",
             @"Cherub",
             @"Chi Chi",
             @"Chilidog",
             @"Chino",
             @"Chyral",
             @"Cilantro",
             @"Citizen",
             @"Climber",
             @"Cobalt",
             @"Coconut",
             @"Cousteau",
             @"Cowboy",
             @"Cracklepop",
             @"Crawdad",
             @"Creech",
             @"Crizzly",
             @"Crow",
             @"Cucumber",
             @"Cursor",
             @"DL",
             @"Daffydell",
             @"Dandelion",
             @"Debris",
             @"Decoy",
             @"Deepwater",
             @"Delco",
             @"Deuce",
             @"Diver Dave",
             @"Dixie",
             @"Doc Rox",
             @"Doodlebug",
             @"Doom Raider",
             @"Dormouse",
             @"Double G",
             @"Double R",
             @"Doumbek",
             @"Ducky",
             @"Duct Tape Diva",
             @"Duney Dan",
             @"DustOff",
             @"East Coast",
             @"Easy E",
             @"Ebbtide",
             @"Edge",
             @"El Cid",
             @"El Weso",
             @"Eldo",
             @"Enigma",
             @"Entheo",
             @"Esoterica",
             @"Estero",
             @"Europa",
             @"Eyepatch",
             @"Fable",
             @"Face Plant",
             @"Fairlead",
             @"Falcore",
             @"Famous",
             @"Farmer",
             @"Fat Chance",
             @"Fearless",
             @"Feline",
             @"Feral Liger",
             @"Fez Monkey",
             @"Filthy",
             @"Firecracker",
             @"Firefly",
             @"Fishfood",
             @"Fixit",
             @"Flat Eric",
             @"Flint",
             @"Focus",
             @"Foofurr",
             @"FoxyRomaine",
             @"Freedom",
             @"Freefall",
             @"Full Gear",
             @"Fuzzy",
             @"G-Ride",
             @"Gambol",
             @"Garnet",
             @"Gecko",
             @"Gemini",
             @"Genius",
             @"Geronimo",
             @"Gibson",
             @"Gizmo",
             @"Godess",
             @"Godfather",
             @"Gonzo",
             @"Goodwood",
             @"Great White",
             @"Grim",
             @"Grofaz",
             @"Grooves",
             @"Grounded",
             @"Guitar Hero",
             @"Haggis",
             @"Haiku",
             @"Halston",
             @"HappyFeet",
             @"Harvest",
             @"Hattrick",
             @"Hawkeye",
             @"Hawthorn",
             @"Hazelnut",
             @"Heart Touch",
             @"Heartbeat",
             @"Heaven",
             @"Hellboy",
             @"Hermione",
             @"Hindsight",
             @"Hitchhiker",
             @"Hogpile",
             @"Hole Card",
             @"Hollister",
             @"Homebrew",
             @"Hookah Mike",
             @"Hooper",
             @"Hoopy Frood",
             @"Horsforth",
             @"Hot Slots",
             @"Hot Yogi",
             @"Howler",
             @"Hughbie",
             @"Hydro",
             @"Ice Cream",
             @"Igor",
             @"Improvise",
             @"Incognito",
             @"India Pale",
             @"Inkwell",
             @"Iron Squirrel",
             @"J School",
             @"J.C.",
             @"JTease",
             @"Jake",
             @"Jellyfish",
             @"Jester",
             @"Joker",
             @"Judas",
             @"Juniper",
             @"Just In Case",
             @"Jynx",
             @"Kamshaft",
             @"Kansas",
             @"Katpaw",
             @"Kaval",
             @"Keeper",
             @"Kendo",
             @"Kermit",
             @"Kettle-Belle",
             @"Kilrog",
             @"Kimistry",
             @"Kingpin",
             @"Kiote",
             @"KitCarson",
             @"Kitsune",
             @"Komack",
             @"Kotekan",
             @"Krusher",
             @"Kshemi",
             @"Kuma",
             @"Kyrka",
             @"LK",
             @"LadyFrog",
             @"Laissez-Faire",
             @"Lake Lover",
             @"Landcruiser",
             @"Larrylicious",
             @"Latte",
             @"Leeway",
             @"Lefty",
             @"Legba",
             @"Legend",
             @"Lens",
             @"Librarian",
             @"Limoncello",
             @"Little John",
             @"LiveWire",
             @"Lodestone",
             @"Loki",
             @"Lola",
             @"Lone Rider",
             @"LongPig",
             @"Lorenzo",
             @"Loris",
             @"Lothos",
             @"Lucky Charm",
             @"Lucky Day",
             @"Lushus",
             @"M-Diggity",
             @"Madtown",
             @"Magic",
             @"Magnum",
             @"Mailman",
             @"Malware",
             @"Mammoth",
             @"Manifest",
             @"Mankind",
             @"Mardi Gras",
             @"Martin Jay",
             @"Massai",
             @"Mauser",
             @"Mavidea",
             @"Maximum",
             @"Maxitude",
             @"Maybe",
             @"Me2",
             @"Mellow",
             @"Mendy",
             @"Mere de Terra",
             @"Mickey",
             @"Milky Wayne",
             @"MisConduct",
             @"Miss Piggy",
             @"Mockingbird",
             @"Mongoose",
             @"Monkey Shoes",
             @"Monochrome",
             @"Moonshine",
             @"Morning Star",
             @"Mouserider",
             @"Moxie",
             @"Mr Po",
             @"Mucho",
             @"Mufasa",
             @"Muppet",
             @"Mushroom",
             @"NaFun",
             @"Nekkid",
             @"Neuron",
             @"Newman",
             @"Night Owl",
             @"Nobooty",
             @"Nosler",
             @"Notorious",
             @"Nuke",
             @"NumberNine",
             @"Oblio",
             @"Oblivious",
             @"Obtuse",
             @"Octane",
             @"Oddboy",
             @"Old Goat",
             @"Oliphant",
             @"One Trip",
             @"Onyx",
             @"Orion",
             @"Osho",
             @"Oswego",
             @"Outlaw",
             @"Owen",
             @"Painless",
             @"Pandora",
             @"Pappa Georgio",
             @"Paragon",
             @"PartTime",
             @"PawPrint",
             @"Pax",
             @"Peaches",
             @"Peanut",
             @"Phantom",
             @"Philamonjaro",
             @"Picante",
             @"Pigmann",
             @"Piney Fresh",
             @"Pinstripes",
             @"Pinto",
             @"Piper",
             @"PitBull",
             @"Po-Boy",
             @"PocketPunk",
             @"Pokie",
             @"Pollux",
             @"Polymath",
             @"PopTart",
             @"Potato",
             @"PottyMouth",
             @"Prana",
             @"Princess",
             @"Prunetucky",
             @"Pucker-Up",
             @"Pudding",
             @"Pumpkin",
             @"Quandary",
             @"Queen SOL",
             @"Quincy",
             @"Raconteur",
             @"Rat Bastard",
             @"Razberry",
             @"Ready",
             @"Recall",
             @"Red Raven",
             @"Red Vixen",
             @"Redeye",
             @"Reject",
             @"RezzAble",
             @"Rhino",
             @"Ric",
             @"Ricky San",
             @"Riffraff",
             @"RoadRash",
             @"Rockhound",
             @"Rocky",
             @"Ronin",
             @"Rooster",
             @"Roslyn",
             @"Sabre",
             @"Safety Phil",
             @"Safeword",
             @"Salsero",
             @"Samba",
             @"Sandy Claws",
             @"Santa Cruz",
             @"Sasquatch",
             @"Saturn",
             @"Scalawag",
             @"Scalpel",
             @"SciFi",
             @"ScoobyDoo",
             @"Scooter",
             @"Scoutmaster",
             @"Scuttlebutt",
             @"Segovia",
             @"Sequoia",
             @"Sharkbite",
             @"Sharpstick",
             @"Shawnee",
             @"Shenanigans",
             @"Shiho",
             @"Shizaru",
             @"Shrek",
             @"Shutterbug",
             @"Silent Wolf",
             @"SilverHair",
             @"Sinamox",
             @"Sintine",
             @"Sir Bill",
             @"Skirblah",
             @"Sledgehammer",
             @"SlipOn",
             @"Smithers",
             @"Smitty",
             @"Smores",
             @"Snappy",
             @"Snowboard",
             @"Snuggles",
             @"SpaceCadet",
             @"Spadoinkle",
             @"Spastic",
             @"Spike Brown",
             @"Splinter",
             @"Sprinkles",
             @"Starfish",
             @"Stella",
             @"Sticky",
             @"Stitch",
             @"Stonebeard",
             @"Strider",
             @"Strobe",
             @"Strong Tom",
             @"Subway",
             @"Sunbeam",
             @"Sundancer",
             @"SuperCraig",
             @"Sweet Tart",
             @"Syncopate",
             @"T Rex",
             @"TSM",
             @"Tabasco",
             @"Tagalong",
             @"Tahoe",
             @"Tango Charlie",
             @"Tanuki",
             @"Tao Skye",
             @"Tapestry",
             @"Teardrop",
             @"Teksage",
             @"Tempest",
             @"Tenderfoot",
             @"The Hamptons",
             @"Thirdson",
             @"Thunder",
             @"Tic Toc",
             @"TikiDaddy",
             @"Tinkerbell",
             @"Toecutter",
             @"TomCat",
             @"Tool",
             @"Toots",
             @"Trailer Hitch",
             @"Tranquilitea",
             @"Treeva",
             @"Triumph",
             @"Tryp",
             @"Tuatha",
             @"Tuff (e.nuff)",
             @"Tulsa",
             @"Tumtetum",
             @"Turnip",
             @"Turtle Dove",
             @"Tuxedo",
             @"Twilight",
             @"Twinkle Toes",
             @"Twisted Cat",
             @"Two-Step",
             @"Uncle Dave",
             @"Uncle John",
             @"Urchin",
             @"Vegas",
             @"Verdi",
             @"Vertigo",
             @"Vichi Lobo",
             @"Victrolla",
             @"Viking",
             @"Vishna",
             @"Vivid",
             @"Voyager",
             @"Wasabi",
             @"Wavelet",
             @"Wee Heavy",
             @"Whipped Cream",
             @"Whoop D",
             @"Wicked",
             @"Wild Fox",
             @"Wild Ginger",
             @"Wingspan",
             @"Wotan",
             @"Wunderpants",
             @"Xplorer",
             @"Xtevan",
             @"Xtract",
             @"Yeti",
             @"Zeitgeist",
             @"Zero Hour",
             @"biteme",
             @"caramel",
             @"daMongolian",
             @"jedi",
             @"k8",
             @"longshot",
             @"mindscrye",
             @"natural",
             @"ultra",
             
             @"Intercept",
             @"Khaki",
             @"Operations Manager",
             @"Officer of the Day",
             @"Logistics Managers",
             @"Personnel Manager",
             @"Captain Hook",
             @"ESD 911 Dispatch",
             @"DPW Dispatch",
             ];
}
