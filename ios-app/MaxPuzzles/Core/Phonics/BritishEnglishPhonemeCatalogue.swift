import Foundation

enum PhonemeCategory: String, CaseIterable, Codable, Sendable {
    case consonant
    case vowel
}

/// Pure consonants must be recorded differently from sounds that can be sustained naturally.
/// This metadata is an authoring constraint; it is never used to manufacture a spoken spelling.
enum PhonemeDelivery: String, Codable, Sendable {
    case short
    case continuous
}

struct BritishEnglishPhoneme: Identifiable, Hashable, Codable, Sendable {
    /// Stable, non-phonetic identifiers. IPA is deliberately metadata because accents evolve and
    /// phonics programmes may choose different child-facing notation for the same sound slot.
    enum ID: String, CaseIterable, Codable, Sendable {
        case consonantP = "c_p"
        case consonantB = "c_b"
        case consonantT = "c_t"
        case consonantD = "c_d"
        case consonantK = "c_k"
        case consonantG = "c_g"
        case consonantF = "c_f"
        case consonantV = "c_v"
        case consonantTHUnvoiced = "c_th_vl"
        case consonantTHVoiced = "c_th_vd"
        case consonantS = "c_s"
        case consonantZ = "c_z"
        case consonantSH = "c_sh"
        case consonantZH = "c_zh"
        case consonantH = "c_h"
        case consonantCH = "c_tsh"
        case consonantJ = "c_dzh"
        case consonantM = "c_m"
        case consonantN = "c_n"
        case consonantNG = "c_ng"
        case consonantL = "c_l"
        case consonantR = "c_r"
        case consonantY = "c_yod"
        case consonantW = "c_w"

        case vowelFleece = "v_fleece"
        case vowelKit = "v_kit"
        case vowelDress = "v_dress"
        case vowelTrap = "v_trap"
        case vowelStrut = "v_strut"
        case vowelLot = "v_lot"
        case vowelFoot = "v_foot"
        case vowelGoose = "v_goose"
        case vowelFace = "v_face"
        case vowelPrice = "v_price"
        case vowelMouth = "v_mouth"
        case vowelGoat = "v_goat"
        case vowelChoice = "v_choice"
        case vowelThought = "v_thought"
        case vowelNurse = "v_nurse"
        case vowelPalm = "v_palm"
        case vowelSquare = "v_square"
        case vowelNear = "v_near"
        case vowelSchwa = "v_schwa"
        case vowelCure = "v_cure"
    }

    let id: ID
    let category: PhonemeCategory
    /// The broad symbol used by the DfE's English spelling appendix.
    let curriculumIPA: String
    /// IPA passed to Apple's preview synthesizer. This may be narrower than the teaching symbol.
    let synthesisIPA: String
    let teachingGrapheme: String
    let exampleWord: String
    let commonGraphemes: [String]
    let delivery: PhonemeDelivery
    let isDialectDependent: Bool
}

struct GraphemePhonemeSequence: Identifiable, Hashable, Sendable {
    var id: String { grapheme }

    let grapheme: String
    let phonemeIDs: [BritishEnglishPhoneme.ID]
    let exampleWord: String
    let pronunciationLabel: String?
    let isContextDependent: Bool

    init(
        grapheme: String,
        phonemeIDs: [BritishEnglishPhoneme.ID],
        exampleWord: String,
        pronunciationLabel: String? = nil,
        isContextDependent: Bool = false
    ) {
        self.grapheme = grapheme
        self.phonemeIDs = phonemeIDs
        self.exampleWord = exampleWord
        self.pronunciationLabel = pronunciationLabel
        self.isContextDependent = isContextDependent
    }
}

enum BritishEnglishPhonemeCatalogue {
    static let datasetID = "en_gb_primary_phonemes_v1"

    /// The traditional 44-sound Southern British teaching inventory: 24 consonants and 20
    /// vowels. CURE is retained for scheme compatibility and marked as dialect-dependent because
    /// many present-day speakers merge it with THOUGHT or realise it as two sounds.
    static let all: [BritishEnglishPhoneme] = [
        consonant(.consonantP, "p", "p", "pin", ["p", "pp"], .short),
        consonant(.consonantB, "b", "b", "boy", ["b", "bb"], .short),
        consonant(.consonantT, "t", "t", "top", ["t", "tt", "ed"], .short),
        consonant(.consonantD, "d", "d", "dog", ["d", "dd", "ed"], .short),
        consonant(.consonantK, "k", "c", "cat", ["c", "k", "ck", "ch"], .short),
        consonant(.consonantG, "ɡ", "g", "go", ["g", "gg", "gu", "gh"], .short),
        consonant(.consonantF, "f", "f", "fish", ["f", "ff", "ph", "gh"], .continuous),
        consonant(.consonantV, "v", "v", "van", ["v", "ve", "f"], .continuous),
        consonant(.consonantTHUnvoiced, "θ", "th", "thin", ["th"], .continuous),
        consonant(.consonantTHVoiced, "ð", "th", "this", ["th"], .continuous),
        consonant(.consonantS, "s", "s", "sun", ["s", "ss", "c", "ce", "sc", "se"], .continuous),
        consonant(.consonantZ, "z", "z", "zip", ["z", "zz", "s", "se"], .continuous),
        consonant(.consonantSH, "ʃ", "sh", "ship", ["sh", "ch", "ti", "ci", "s"], .continuous),
        consonant(.consonantZH, "ʒ", "s", "treasure", ["s", "si", "ge"], .continuous),
        consonant(.consonantH, "h", "h", "hat", ["h", "wh"], .continuous),
        consonant(.consonantCH, "tʃ", "ch", "chip", ["ch", "tch"], .short),
        consonant(.consonantJ, "dʒ", "j", "jam", ["j", "g", "ge", "dge"], .short),
        consonant(.consonantM, "m", "m", "man", ["m", "mm", "mb"], .continuous),
        consonant(.consonantN, "n", "n", "nut", ["n", "nn", "kn", "gn"], .continuous),
        consonant(.consonantNG, "ŋ", "ng", "ring", ["ng", "n"], .continuous),
        consonant(.consonantL, "l", "l", "lip", ["l", "ll"], .continuous),
        consonant(.consonantR, "r", "ɹ", "r", "run", ["r", "rr", "wr", "rh"], .continuous),
        consonant(.consonantY, "j", "y", "yes", ["y", "i"], .short),
        consonant(.consonantW, "w", "w", "wet", ["w", "wh", "u"], .short),

        vowel(.vowelFleece, "iː", "ee", "feet", ["ee", "ea", "e", "y", "ie", "ei", "i"]),
        vowel(.vowelKit, "ɪ", "i", "dig", ["i", "y", "ui", "e", "o"]),
        vowel(.vowelDress, "ɛ", "e", "egg", ["e", "ea", "ai", "a"]),
        vowel(.vowelTrap, "æ", "a", "cat", ["a"]),
        vowel(.vowelStrut, "ʌ", "u", "up", ["u", "o", "ou", "oo"]),
        vowel(.vowelLot, "ɒ", "o", "on", ["o", "a", "ou"]),
        vowel(.vowelFoot, "ʊ", "oo", "book", ["oo", "u", "ou"]),
        vowel(.vowelGoose, "uː", "oo", "moon", ["oo", "u-e", "ue", "ew", "u", "ou", "ui", "o", "ough"]),
        vowel(.vowelFace, "eɪ", "ai", "rain", ["ai", "ay", "a-e", "a", "eigh", "ey", "ea"]),
        vowel(.vowelPrice, "aɪ", "igh", "night", ["i-e", "igh", "y", "i", "ie", "eye", "uy"]),
        vowel(.vowelMouth, "aʊ", "ou", "out", ["ou", "ow", "ough"]),
        vowel(.vowelGoat, "əʊ", "oa", "boat", ["oa", "ow", "o-e", "o", "oe", "ough"]),
        vowel(.vowelChoice, "ɔɪ", "oi", "coin", ["oi", "oy"]),
        vowel(.vowelThought, "ɔː", "aw", "saw", ["aw", "au", "al", "or", "oor", "ore", "oar", "our", "ough"]),
        vowel(.vowelNurse, "ɜː", "ur", "turn", ["ir", "ur", "er", "ear", "or"]),
        vowel(.vowelPalm, "ɑː", "ar", "car", ["ar", "a", "al", "ear"]),
        vowel(.vowelSquare, "ɛə", "air", "hair", ["air", "are", "ear", "ere"]),
        vowel(.vowelNear, "ɪə", "ear", "ear", ["ear", "eer", "ere"]),
        vowel(.vowelSchwa, "ə", "a", "about", ["a", "e", "i", "o", "u", "er", "or", "ar", "our", "re"]),
        vowel(.vowelCure, "ʊə", "ure", "pure", ["ure", "our", "oor"], isDialectDependent: true)
    ]

    /// Single letters can encode sound sequences. Keeping these outside `commonGraphemes`
    /// prevents callers from teaching x or qu as invented extra phonemes.
    static let commonSequences: [GraphemePhonemeSequence] = [
        GraphemePhonemeSequence(
            grapheme: "x",
            phonemeIDs: [.consonantK, .consonantS],
            exampleWord: "box"
        ),
        GraphemePhonemeSequence(
            grapheme: "qu",
            phonemeIDs: [.consonantK, .consonantW],
            exampleWord: "queen"
        ),
        GraphemePhonemeSequence(
            grapheme: "u",
            phonemeIDs: [.consonantY, .vowelGoose],
            exampleWord: "music",
            pronunciationLabel: "yoo",
            isContextDependent: true
        ),
        GraphemePhonemeSequence(
            grapheme: "ew",
            phonemeIDs: [.consonantY, .vowelGoose],
            exampleWord: "few",
            pronunciationLabel: "yoo",
            isContextDependent: true
        )
    ]

    private static let phonemesByID: [BritishEnglishPhoneme.ID: BritishEnglishPhoneme] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func phoneme(for id: BritishEnglishPhoneme.ID) -> BritishEnglishPhoneme? {
        phonemesByID[id]
    }

    /// Returns every possible single-phoneme correspondence. Ambiguity is intentional: for
    /// example `c`, `g`, `th`, `oo` and `ear` each have more than one valid result.
    static func phonemes(forGrapheme grapheme: String) -> [BritishEnglishPhoneme] {
        let normalized = normalize(grapheme)
        guard !normalized.isEmpty else { return [] }
        return all.filter { phoneme in
            phoneme.commonGraphemes.contains { normalize($0) == normalized }
        }
    }

    static func sequence(forGrapheme grapheme: String) -> GraphemePhonemeSequence? {
        let normalized = normalize(grapheme)
        return commonSequences.first { normalize($0.grapheme) == normalized }
    }

    static var validationIssues: [String] {
        var issues: [String] = []
        let ids = all.map(\.id)

        if all.count != 44 { issues.append("Expected 44 phonemes; found \(all.count)") }
        if Set(ids).count != ids.count { issues.append("Duplicate stable phoneme IDs") }
        if Set(ids) != Set(BritishEnglishPhoneme.ID.allCases) {
            issues.append("Catalogue and stable ID enum do not match")
        }
        if all.filter({ $0.category == .consonant }).count != 24 {
            issues.append("Expected 24 consonants")
        }
        if all.filter({ $0.category == .vowel }).count != 20 {
            issues.append("Expected 20 vowels")
        }

        for phoneme in all {
            if phoneme.curriculumIPA.isEmpty
                || phoneme.synthesisIPA.isEmpty
                || phoneme.teachingGrapheme.isEmpty
                || phoneme.exampleWord.isEmpty
                || phoneme.commonGraphemes.isEmpty {
                issues.append("Incomplete metadata for \(phoneme.id.rawValue)")
            }
            if !phoneme.commonGraphemes.contains(where: {
                normalize($0) == normalize(phoneme.teachingGrapheme)
            }) {
                issues.append("Teaching grapheme missing for \(phoneme.id.rawValue)")
            }
        }

        for sequence in commonSequences {
            if sequence.phonemeIDs.count < 2 {
                issues.append("Compound \(sequence.grapheme) must contain at least two sounds")
            }
            if sequence.phonemeIDs.contains(where: { phonemesByID[$0] == nil }) {
                issues.append("Compound \(sequence.grapheme) references an unknown sound")
            }
        }
        return issues
    }

    private static func consonant(
        _ id: BritishEnglishPhoneme.ID,
        _ ipa: String,
        _ grapheme: String,
        _ example: String,
        _ commonGraphemes: [String],
        _ delivery: PhonemeDelivery
    ) -> BritishEnglishPhoneme {
        consonant(id, ipa, ipa, grapheme, example, commonGraphemes, delivery)
    }

    private static func consonant(
        _ id: BritishEnglishPhoneme.ID,
        _ curriculumIPA: String,
        _ synthesisIPA: String,
        _ grapheme: String,
        _ example: String,
        _ commonGraphemes: [String],
        _ delivery: PhonemeDelivery
    ) -> BritishEnglishPhoneme {
        BritishEnglishPhoneme(
            id: id,
            category: .consonant,
            curriculumIPA: curriculumIPA,
            synthesisIPA: synthesisIPA,
            teachingGrapheme: grapheme,
            exampleWord: example,
            commonGraphemes: commonGraphemes,
            delivery: delivery,
            isDialectDependent: false
        )
    }

    private static func vowel(
        _ id: BritishEnglishPhoneme.ID,
        _ ipa: String,
        _ grapheme: String,
        _ example: String,
        _ commonGraphemes: [String],
        isDialectDependent: Bool = false
    ) -> BritishEnglishPhoneme {
        BritishEnglishPhoneme(
            id: id,
            category: .vowel,
            curriculumIPA: ipa,
            synthesisIPA: ipa,
            teachingGrapheme: grapheme,
            exampleWord: example,
            commonGraphemes: commonGraphemes,
            delivery: .continuous,
            isDialectDependent: isDialectDependent
        )
    }

    private static func normalize(_ grapheme: String) -> String {
        grapheme
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
    }
}
