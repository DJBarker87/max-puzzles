# Phoneme Audio Foundation

This subsystem is the app-level audio foundation used by Comet Writer and by Star Speller's
single-letter safety path.
Its catalogue is the traditional 44-sound British-English teaching inventory: 24 consonants
and 20 vowels. The stable dataset identifier is `en_gb_primary_phonemes_v1`.

The catalogue follows the IPA guidance in the Department for Education's English spelling
appendix while keeping stable IDs separate from IPA. That separation matters because accents
and phonics programmes differ. In particular, CURE `/ʊə/` is retained for compatibility but
marked dialect-dependent.

## Deliberate audio boundary

There are two audio paths:

1. **Approved recording** — the only path future games may use. A human-reviewed, locally
   bundled `.m4a` clip is resolved by stable phoneme ID. Missing or corrupt recordings return an
   explicit failure; they never fall back to a letter name.
2. **IPA preview** — available only to the standalone Debug audio lab. It uses Apple's IPA
   pronunciation attribute so all 44 entries can be auditioned before recordings are approved.
   System synthesis is a review aid, not production phonics audio.

Comet Writer has an explicit 26-letter mapping onto this inventory. It repeats each reviewed
recording sequence around a timed pause and never sends a displayed letter to plain-text speech.
Star Speller uses the same safe path only for a non-word, one-letter custom entry; ordinary words
remain whole-word prompts because their sounds depend on context.

## Approved recording layout

Place version-one British-English clips in:

```text
MaxPuzzles/Resources/PhonemeAudio/en-GB/v1/
```

This directory is already a folder resource in the app target, so future clips placed there keep
the required `PhonemeAudio/en-GB/v1` bundle path. Its `recording-contract.json` lists the complete
stable-ID set. The service derives each filename from those IDs. Files must be mono AAC in an
`.m4a` container, recorded by one speaker in one acoustic setup. Keep files short, offline and free
from music or effects.

They are deliberately ignored by git as a conservative distribution boundary: this repository is public
and should not become a raw audio library.  Local and App Store builds include the files when they are present in
the folder resource. Recreate them from the privately retained source pack with:

```sh
python3 ios-app/Tools/import_phoneme_audio.py \
  --source-dir "/path/to/phoneme-source-audio" \
  --source-pdf "/path/to/source-reference.pdf"
```

The importer maps the PDF-linked chart buttons to stable IDs, separates the isolated first
utterance from the later example word, and writes a git-ignored evidence manifest containing the
PDF/source/output hashes and crop boundaries. Do not add the generated `.m4a` files to the public
repository.

Private import evidence is written outside the app resource folder at
`ios-app/LocalAssets/PhonemeAudio/en-GB/v1/import-manifest.local.json`, so hashes and source
records are not accidentally copied into the application bundle.

The app target's **Verify Phoneme Audio** phase fails every Release build unless that
private manifest and the complete 44-file set are present. It verifies exact SHA-256 hashes and
uses `afinfo` to require decodable mono 48 kHz AAC. Debug builds remain possible in a clean public
checkout, but an archive cannot silently ship a prompt that says “Letter” and then plays nothing.

Each clip must:

- contain the isolated phoneme, never the letter name;
- use a pure sound without an added schwa (`/m/`, not “muh”);
- keep stop consonants short rather than turning them into syllables;
- have no spoken label, example word or leading prompt;
- use consistent perceived volume and clean edits;
- have documented provenance and distribution permission.

Do not manufacture recordings by spelling sounds as ordinary text. Strings such as `kuh` add a
vowel that is not part of `/k/`.

## Human approval and release QA

Automated checks can prove that IDs, mappings and files are present; they cannot prove that a
child hears the right sound. The project owner supplied the source pack and explicitly authorised
game integration. A final physical-device audition remains a release QA
step: two adults should listen to all clips in random order, with at least one reviewer familiar
with synthetic phonics.

Review both `th` sounds, both `oo` sounds, `/ʒ/`, schwa, and the dialect-dependent CURE entry
particularly carefully. Test on an iPhone and iPad speaker and on headphones. Reject clipping,
background noise, repeated sounds, letter names and added schwas.

## Scheme integration

The catalogue describes sounds and common grapheme mappings; it does not prescribe teaching
order. A future game or Writer integration must add an explicit progression for the child's
school programme. `x` (`/k/ + /s/`) and `qu` (`/k/ + /w/`) are modelled as sound sequences, not
invented as additional phonemes.

Primary references:

- [National curriculum in England: English programmes of study](https://www.gov.uk/government/publications/national-curriculum-in-england-english-programmes-of-study/national-curriculum-in-england-english-programmes-of-study)
- [English Appendix 1: Spelling](https://assets.publishing.service.gov.uk/media/5a7ccc06ed915d63cc65ce61/English_Appendix_1_-_Spelling.pdf)
- [Choosing a phonics teaching programme](https://www.gov.uk/government/publications/choosing-a-phonics-teaching-programme/list-of-phonics-teaching-programmes)
