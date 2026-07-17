# Dot-to-Dot Picture Review

Review date: 17 July 2026
Target player: children aged 4–5 learning to recognise numerals to 20
Reviewer: implementation QA pass using the in-app proportional review scene

## Acceptance criteria

Every picture was rendered with its real trail numerals and generated tricky dots in one of ten
DEBUG-only review sheets. A picture passes only when:

1. its silhouette, title, and completion emoji form a coherent child-recognisable subject;
2. the trail stays inside the board and contains exactly 10, 15, or 20 numerals for its tier;
3. the ordered dots remain usable at the actual iPhone/iPad game-board scale;
4. generated tricky dots are visually separate and never display the currently requested numeral;
5. the subject adds worthwhile variety for a young child.

The automated catalogue test separately verifies unique stable IDs, 100 total records, the
34/33/33 tier distribution, point counts, bounds, distractor counts, and distractor behaviour.

## Individual sign-off

| # | Picture | Range | Result | Review note |
|---:|---|:---:|:---:|---|
| 1 | Rocket | 1–10 | Pass | Strong pointed nose, body, fins, and flame make an immediate space-themed reward. |
| 2 | Star | 1–10 | Pass | Classic five-point outline is clear before and after connection. |
| 3 | Fish | 1–10 | Pass | Broad body and separate tail read cleanly with generous dot spacing. |
| 4 | House | 1–10 | Pass | Roof, walls, door, and doorway break give a familiar first-picture shape. |
| 5 | Sailboat | 1–10 | Pass | Hull, mast, and triangular sail are distinct and engaging. |
| 6 | Flower | 1–10 | Revised → pass | Replaced star-like bloom with a tulip-style flower, stem, and two leaves; passed second render. |
| 7 | Kite | 1–10 | Pass | Symmetrical diamond and lower point form a simple, readable kite. |
| 8 | Heart | 1–10 | Pass | Twin lobes and lower point remain recognisable even under the numerals. |
| 9 | Moon | 1–10 | Pass | Crescent is visibly different from the circular subjects elsewhere in the set. |
| 10 | Ice Cream | 1–10 | Revised → pass | Added a broad scalloped scoop and a single pointed cone; passed second render. |
| 11 | Cat | 1–15 | Pass | Upright ears and whisker-like cheek corners create a friendly cat face. |
| 12 | Puppy | 1–15 | Pass | Drooping outer ears and muzzle/chin shape distinguish it from the cat. |
| 13 | Butterfly | 1–15 | Pass | Mirrored wings, narrow body, and antenna point make a lively reveal. |
| 14 | Turtle | 1–15 | Pass | Rounded shell with head, feet, and tail protrusions reads as a turtle. |
| 15 | Rabbit | 1–15 | Pass | Tall paired ears, curved back, and rear foot are unmistakably rabbit-like. |
| 16 | Duck | 1–15 | Pass | Rounded body, raised head, and pointed beak give a clear side profile. |
| 17 | Snail | 1–15 | Pass | Large domed shell and small antenna-bearing head make the subject readable. |
| 18 | Crown | 1–15 | Pass | Three peaks and wide base deliver a strong celebratory reveal. |
| 19 | Dolphin | 1–15 | Pass | Arched back, beak, fin, and lifted tail create motion without crowding. |
| 20 | Penguin | 1–15 | Pass | Upright body, side flippers, and two feet form a distinctive character. |
| 21 | Dinosaur | 1–20 | Pass | Long neck, back, tail, and two feet produce an engaging dinosaur silhouette. |
| 22 | Whale | 1–20 | Pass | Broad swimming body and lifted forked tail are clear at game scale. |
| 23 | Elephant | 1–20 | Revised → pass | Replaced generic head shape with a side-on body, four leg edges, head, and curled trunk. |
| 24 | Giraffe | 1–20 | Pass | Long neck, small horned head, torso, and feet give a unique tall subject. |
| 25 | Lion | 1–20 | Pass | Jagged rounded mane and central lion reward create a bold animal reveal. |
| 26 | Crab | 1–20 | Pass | Twin claws, wide shell, and multiple pointed legs are clearly crustacean. |
| 27 | Airplane | 1–20 | Pass | Nose, swept wings, tailplane, and fuselage remain legible with 20 dots. |
| 28 | Octopus | 1–20 | Pass | Domed head and repeated lower tentacles create a playful sea creature. |
| 29 | Shark | 1–20 | Pass | Dorsal fin, pointed nose, lower fin, and forked tail distinguish it from Fish. |
| 30 | Robot | 1–20 | Pass | Antenna, block head/body, arms, and separated feet form a crisp mechanical figure. |
| 31 | Sun | 1–10 | Pass | Alternating rays make a large, joyful shape with evenly spread numerals. |
| 32 | Cloud | 1–10 | Pass | Multi-lobed top and flatter base give a calm, familiar weather picture. |
| 33 | Fir Tree | 1–10 | Revised → pass | Renamed and re-iconed to match the clearly tiered evergreen silhouette. |
| 34 | Apple | 1–10 | Pass | Rounded fruit, top dip, stem, and leaf make the apple immediately clear. |
| 35 | Pear | 1–10 | Pass | Narrow neck and broad lower fruit provide a distinctive outline. |
| 36 | Strawberry | 1–10 | Pass | Leafy crown and tapered berry shape read well and differ from Apple. |
| 37 | Watermelon | 1–10 | Revised → pass | Replaced oval fruit with a domed half-slice and flat rind edge. |
| 38 | Cupcake | 1–10 | Pass | Wavy icing top and tapered wrapper form a recognisable treat. |
| 39 | Pizza | 1–10 | Pass | Triangular slice, crust bumps, and pointed tip give a familiar food shape. |
| 40 | Umbrella | 1–10 | Pass | Wide canopy, scalloped lower edge, shaft, and hooked handle are clear. |
| 41 | Balloon | 1–10 | Pass | Rounded balloon, tied neck, and short curling tail create an upbeat picture. |
| 42 | Present | 1–10 | Pass | Bow loops, ribbon knot, lid, and box make a rewarding gift reveal. |
| 43 | Bell | 1–10 | Pass | Domed top, flared rim, and clapper give a classic bell silhouette. |
| 44 | Key | 1–10 | Pass | Large ring, diagonal shaft, and stepped teeth are distinct from every other object. |
| 45 | Snowman | 1–10 | Pass | Smaller head over a larger round body makes a simple winter character. |
| 46 | Mountain | 1–10 | Pass | Layered peaks and strong ground line provide an easy landscape subject. |
| 47 | Rainbow | 1–10 | Pass | Outer arch and inner cut-out create a clear rainbow band. |
| 48 | Castle | 1–10 | Pass | Battlements, twin towers, and central arched doorway are highly recognisable. |
| 49 | Lighthouse | 1–10 | Revised → pass | Tower and lamp room already passed; completion icon changed from alarm light to a beacon bulb. |
| 50 | Anchor | 1–10 | Pass | Top ring, straight shank, cross arms, and hooked base make a strong nautical shape. |
| 51 | Seashell | 1–10 | Revised → pass | Reworked into a symmetrical fan shell with scalloped upper lobes and a narrow base. |
| 52 | Music Note | 1–10 | Pass | Connected stems, beam, and two note heads produce an especially clear reveal. |
| 53 | Book | 1–10 | Pass | Twin upper/lower page dips and central spine read as an open book. |
| 54 | Pencil | 1–10 | Pass | Long diagonal body, eraser end, and sharpened point are cleanly separated. |
| 55 | Fox | 1–15 | Pass | Tall ears, pointed cheeks, and narrow chin create a fox-like face. |
| 56 | Bear | 1–15 | Pass | Round ears and broad round face provide a friendly bear portrait. |
| 57 | Panda | 1–15 | Revised → pass | Changed from a near-copy of Bear to a full-body pose with ears, arms, and two feet. |
| 58 | Koala | 1–15 | Pass | Oversized side ears and tapered lower face distinguish the koala. |
| 59 | Monkey | 1–15 | Pass | Wide side ears and a peaked crown produce a playful monkey face. |
| 60 | Frog | 1–15 | Pass | Two raised eye bumps and a broad lower face make the frog distinct. |
| 61 | Owl | 1–15 | Pass | Horn-like brows, winged sides, and small lower points give an owl silhouette. |
| 62 | Chicken | 1–15 | Pass | Comb, beak, rounded body, and tail contour create a clear bird profile. |
| 63 | Pig | 1–15 | Pass | Two ears and a wide rounded head work coherently with the pig reward. |
| 64 | Cow | 1–15 | Pass | Side horns, ears, and long lower face distinguish it from Pig and Bear. |
| 65 | Sheep | 1–15 | Pass | Irregular woolly perimeter and small head projection provide texture and variety. |
| 66 | Horse | 1–15 | Pass | Long muzzle, ear, mane edge, and neck make a readable horse-head profile. |
| 67 | Zebra | 1–15 | Revised → pass | Replaced duplicate horse head with a side-on body, mane, four leg edges, and tail. |
| 68 | Camel | 1–15 | Pass | Two humps, raised head, tail, and legs make the animal immediately distinctive. |
| 69 | Crocodile | 1–15 | Pass | Long low body, jagged back, snout, and tail form a strong horizontal trail. |
| 70 | Seahorse | 1–15 | Revised → pass | Curled tail and arched head passed; misleading unicorn completion icon changed to a sea symbol. |
| 71 | Jellyfish | 1–15 | Revised → pass | Domed bell and five trailing tentacle points passed; reward icon made compatible with all supported iOS 16 versions. |
| 72 | Bumblebee | 1–15 | Pass | Twin upper wings, tapered striped-body shape, and lower point create a cheerful insect. |
| 73 | Ladybird | 1–15 | Pass | Antennae and rounded wing case give a compact, friendly bug outline. |
| 74 | Spider | 1–15 | Pass | Eight angular leg projections make this one of the most distinctive animal silhouettes. |
| 75 | Mouse | 1–15 | Pass | Large round ears and pointed lower muzzle clearly read as a mouse. |
| 76 | Squirrel | 1–15 | Pass | Small head and oversized curling tail make the side profile engaging. |
| 77 | Hedgehog | 1–15 | Pass | Repeated back spikes, small snout, and rounded belly form a clear hedgehog. |
| 78 | Car | 1–20 | Pass | Roofline, bonnet/boot, two wheel cut-outs, and chassis remain legible with 20 dots. |
| 79 | Bus | 1–20 | Pass | Tall rectangular body and two wheel shapes distinguish it from Car and Train. |
| 80 | Train | 1–20 | Pass | Cab roof, boiler/front, chassis, and twin wheels create a clear locomotive. |
| 81 | Bicycle | 1–20 | Pass | Two wheel loops, frame triangle, saddle, and handlebar reward careful following. |
| 82 | Tractor | 1–20 | Pass | High cab, sloping bonnet, and unequal wheel sizes form a recognisable farm vehicle. |
| 83 | Fire Engine | 1–20 | Pass | Long emergency-vehicle body, raised equipment line, and wheels provide strong variety. |
| 84 | Submarine | 1–20 | Revised → pass | Conning tower and rounded hull passed; ship reward icon changed to a neutral nautical anchor. |
| 85 | Helicopter | 1–20 | Pass | Tail boom, cabin, skid-like base, and rotor-area contour read as a helicopter. |
| 86 | Hot-air Balloon | 1–20 | Pass | Large envelope, narrow neck, and small basket make a satisfying tall reveal. |
| 87 | Flying Saucer | 1–20 | Pass | Symmetrical dome and wide saucer rim create a playful space picture. |
| 88 | Guitar | 1–20 | Pass | Curved body, narrow neck, headstock, and diagonal stance are unmistakably musical. |
| 89 | Drum | 1–20 | Pass | Curved top/bottom rims and tapered sides produce a simple percussion shape. |
| 90 | Camera | 1–20 | Pass | Rectangular body, raised viewfinder housing, and lower lens bulge read clearly. |
| 91 | Teddy Bear | 1–20 | Pass | Two ears, outstretched arms, separated legs, and full body create a friendly reward. |
| 92 | Football | 1–20 | Pass | Even circular trail deliberately contrasts with the angular vehicle and fantasy subjects. |
| 93 | Skateboard | 1–20 | Pass | Long curved deck and two distinct wheel bumps create a strong horizontal challenge. |
| 94 | Mermaid | 1–20 | Pass | Head, arms, narrow waist, curved tail, and split fin form an imaginative character. |
| 95 | Dragon | 1–20 | Pass | Horns, jagged wings/back, tail, and feet create an energetic fantasy outline. |
| 96 | Unicorn | 1–20 | Pass | Prominent horn, ear, long face, mane edge, and neck make the subject recognisable. |
| 97 | Pirate Ship | 1–20 | Pass | Hull, mast, raised flag tip, sail, and stern make a rich final-tier picture. |
| 98 | Treasure Chest | 1–20 | Revised → pass | Domed lid, box, and central lock passed; completion reward changed from toolbox to treasure. |
| 99 | Digger | 1–20 | Revised → pass | Cab, tracked base, articulated arm, and bucket passed; duplicate tractor icon changed to roadworks. |
| 100 | Volcano | 1–20 | Pass | Wide mountain base, crater, and multi-point eruption make a dramatic final picture. |

## Outcome

All 100 pictures pass after the revisions recorded above. The proportional coordinate fix is shared
by the review scene, gallery thumbnails, completed artwork, tap hit targets, and trace endpoints, so
the reviewed silhouettes are the silhouettes children receive on both iPhone and iPad.
