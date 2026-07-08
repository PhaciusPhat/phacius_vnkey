/// Returns true if `syllable` (lowercased, NFC) is a legal Vietnamese syllable.
///
/// Checks onset → nucleus → coda compatibility according to standard
/// Vietnamese phonotactics. Tone marks are stripped before analysis.
pub fn is_valid_syllable(syllable: &str) -> bool {
    if syllable.is_empty() {
        return false;
    }
    // Strip tone marks to get bare consonants+vowels.
    let bare = strip_tone_marks(syllable);
    let s = bare.to_lowercase();

    // Try to split into (onset, nucleus, coda).
    if let Some((onset, nucleus, coda)) = parse_syllable(&s) {
        validate_combination(onset, nucleus, coda)
    } else {
        false
    }
}

/// Returns true if `s` could be a valid prefix of a Vietnamese syllable
/// (i.e., we should keep buffering rather than auto-restore).
pub fn is_valid_prefix(s: &str) -> bool {
    if s.is_empty() {
        return true;
    }
    let bare = strip_tone_marks(s);
    let s = bare.to_lowercase();

    // A valid prefix is either a known onset, or onset+partial-nucleus, etc.
    // We use a permissive check: any string that starts with a valid onset
    // and whose remaining characters are vowels (possibly partial nucleus).
    let (onset, rest) = consume_onset(&s);
    if onset.is_none() && !rest.is_empty() {
        // No onset consumed — only valid if first char is a vowel (zero onset)
        let first = rest.chars().next().unwrap();
        if !is_vowel_char(first) {
            return false;
        }
    }
    // Rest must be all vowel-ish characters (nucleus/coda partial).
    let after_onset: &str = onset.map(|_o| rest).unwrap_or(rest);
    for ch in after_onset.chars() {
        if !is_vowel_char(ch) && !is_coda_char(ch) {
            return false;
        }
    }
    true
}

// ── Tone stripping ──────────────────────────────────────────────────────────

pub fn strip_tone_marks(s: &str) -> String {
    s.chars().map(|c| base_vowel(c).unwrap_or(c)).collect()
}

/// Map a toned/diacritical vowel to its base form.
pub fn base_vowel(c: char) -> Option<char> {
    match c {
        'à'|'á'|'ả'|'ã'|'ạ' => Some('a'),
        'ầ'|'ấ'|'ẩ'|'ẫ'|'ậ'|'â' => Some('â'),
        'ằ'|'ắ'|'ẳ'|'ẵ'|'ặ'|'ă' => Some('ă'),
        'è'|'é'|'ẻ'|'ẽ'|'ẹ' => Some('e'),
        'ề'|'ế'|'ể'|'ễ'|'ệ'|'ê' => Some('ê'),
        'ì'|'í'|'ỉ'|'ĩ'|'ị' => Some('i'),
        'ò'|'ó'|'ỏ'|'õ'|'ọ' => Some('o'),
        'ồ'|'ố'|'ổ'|'ỗ'|'ộ'|'ô' => Some('ô'),
        'ờ'|'ớ'|'ở'|'ỡ'|'ợ'|'ơ' => Some('ơ'),
        'ù'|'ú'|'ủ'|'ũ'|'ụ' => Some('u'),
        'ừ'|'ứ'|'ử'|'ữ'|'ự'|'ư' => Some('ư'),
        'ỳ'|'ý'|'ỷ'|'ỹ'|'ỵ' => Some('y'),
        _ => None,
    }
}

// ── Onset parsing ───────────────────────────────────────────────────────────

/// Known onsets, longest first (greedy match).
const ONSETS: &[&str] = &[
    "ngh", "gh", "gi", "ng", "nh", "ph", "th", "tr", "ch",
    "kh", "qu", "b", "c", "d", "đ", "g", "h", "k", "l",
    "m", "n", "p", "r", "s", "t", "v", "x",
];

/// Try to consume the onset from the front of `s`.
/// Returns (Some(onset_str), remainder) or (None, s) for zero onset.
fn consume_onset(s: &str) -> (Option<&'static str>, &str) {
    for &onset in ONSETS {
        if let Some(rest) = s.strip_prefix(onset) {
            // Make sure what follows isn't another consonant that would be part of onset.
            return (Some(onset), rest);
        }
    }
    (None, s)
}

// ── Nucleus / coda parsing ──────────────────────────────────────────────────

/// Multi-char nuclei, longest first.
const NUCLEI: &[&str] = &[
    "uôi", "ươi", "iêu", "ươu",
    "iê", "yê", "uô", "ươ", "ua", "ia",
    "oa", "oe", "uy", "oo",
    "ao", "ai", "au", "oi", "ôi", "ơi", "ui", "ưi",
    "eo", "êu", "iu", "ay", "ây",
    "â", "ă", "ê", "ô", "ơ", "ư",
    "a", "e", "i", "o", "u", "y",
];

const CODAS: &[&str] = &["ng", "nh", "ch", "c", "m", "n", "p", "t"];

fn is_vowel_char(c: char) -> bool {
    matches!(c, 'a'|'ă'|'â'|'e'|'ê'|'i'|'o'|'ô'|'ơ'|'u'|'ư'|'y')
}

fn is_coda_char(c: char) -> bool {
    matches!(c, 'c'|'h'|'m'|'n'|'g'|'p'|'t')
}

fn consume_nucleus(s: &str) -> Option<(&'static str, &str)> {
    for &nuc in NUCLEI {
        if let Some(rest) = s.strip_prefix(nuc) {
            return Some((nuc, rest));
        }
    }
    None
}

fn consume_coda(s: &str) -> Option<(&'static str, &str)> {
    for &coda in CODAS {
        if s == coda {
            return Some((coda, ""));
        }
    }
    None
}

fn parse_syllable(s: &str) -> Option<(&'static str, &'static str, &'static str)> {
    let (onset, after_onset) = consume_onset(s);
    let onset = onset.unwrap_or("");

    let (nucleus, after_nucleus) = consume_nucleus(after_onset)?;

    // Coda is optional.
    let coda = if after_nucleus.is_empty() {
        ""
    } else {
        match consume_coda(after_nucleus) {
            Some((c, "")) => c,
            _ => return None, // leftover characters — invalid
        }
    };

    Some((onset, nucleus, coda))
}

// ── Compatibility rules ─────────────────────────────────────────────────────

fn validate_combination(onset: &str, nucleus: &str, coda: &str) -> bool {
    // gh / ngh only with front vowels e, ê, i
    if matches!(onset, "gh" | "ngh")
        && !matches!(nucleus, "e" | "ê" | "i" | "iê" | "ia") {
            return false;
        }

    // gi onset: nucleus must NOT start with 'i' (would be redundant "gii")
    if onset == "gi" && (nucleus == "i" || nucleus == "ia" || nucleus == "iê") {
        return false;
    }

    // qu onset requires nucleus starting with u-sound
    if onset == "qu"
        && !matches!(nucleus, "a" | "â" | "e" | "ê" | "i" | "o" | "ô" | "oa" | "oe" | "uy" | "u") {
            return false;
        }

    // c / k spelling constraint: 'k' only before e, ê, i; 'c' elsewhere
    // (We don't enforce spelling here — just phonotactics)

    // Coda constraints
    match coda {
        "c" | "p" => {
            // Only short-closing codas with compatible nuclei
            if matches!(nucleus, "uôi" | "ươi" | "iêu" | "ươu") {
                return false;
            }
        }
        "ch" => {
            // Only with front vowels
            if !matches!(nucleus, "a" | "ă" | "â" | "e" | "ê" | "i" | "ia" | "iê" | "oa" | "u") {
                return false;
            }
        }
        "nh" => {
            if !matches!(nucleus, "a" | "ă" | "â" | "e" | "ê" | "i" | "ia" | "iê" | "oa" | "u" | "uy") {
                return false;
            }
        }
        "ng"
            // Broad compatibility — disallow only clearly invalid combos
            if matches!(nucleus, "iê" | "iêu") && coda == "ng" => {
                // "iêng" is not standard
                return false;
            }
        _ => {}
    }

    // Triphthong nuclei must be open (no coda) except some exceptions
    if matches!(nucleus, "uôi" | "ươi" | "iêu" | "ươu") && !coda.is_empty() {
        return false;
    }

    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_valid() {
        for word in &["ba", "me", "bà", "mẹ", "việt", "nam", "hoa", "hoà", "hòa",
                      "chào", "nghĩ", "quê", "đường", "thương", "trường"] {
            assert!(is_valid_syllable(word), "expected valid: {word}");
        }
    }

    #[test]
    fn basic_invalid() {
        for word in &["test", "hello", "abc", "xzq", "bbb"] {
            assert!(!is_valid_syllable(word), "expected invalid: {word}");
        }
    }

    #[test]
    fn gh_ngh_only_front_vowels() {
        assert!(is_valid_syllable("ghi"));
        assert!(is_valid_syllable("nghe"));
        assert!(!is_valid_syllable("gha"));
        assert!(!is_valid_syllable("ngha"));
    }

    #[test]
    fn qu_onset() {
        assert!(is_valid_syllable("qua"));
        assert!(is_valid_syllable("quê"));
    }
}
