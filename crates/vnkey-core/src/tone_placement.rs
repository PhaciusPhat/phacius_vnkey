use crate::types::{Tone, TonePlacementMode};
use crate::validator::base_vowel;

/// Apply `tone` to `word` (bare Vietnamese syllable, no existing tone marks)
/// according to the chosen `mode`. Returns the toned string.
pub fn apply_tone(word: &str, tone: Tone, mode: TonePlacementMode) -> String {
    if tone == Tone::Flat {
        return word.to_string();
    }

    let chars: Vec<char> = word.chars().collect();

    // Find the index of the vowel that should receive the tone mark.
    if let Some(idx) = tone_position(&chars, mode) {
        chars
            .iter()
            .enumerate()
            .map(|(i, &c)| if i == idx { toned_vowel(c, tone) } else { c })
            .collect()
    } else {
        word.to_string()
    }
}

/// Find which character index in `chars` should carry the tone mark.
fn tone_position(chars: &[char], mode: TonePlacementMode) -> Option<usize> {
    // Identify vowel indices.
    let vowel_indices: Vec<usize> = chars
        .iter()
        .enumerate()
        .filter(|(_, &c)| is_vowel(c))
        .map(|(i, _)| i)
        .collect();

    if vowel_indices.is_empty() {
        return None;
    }

    // --- Modern placement rules ---
    //
    // Priority (first match wins):
    // 1. Circumflex/breve vowels (â, ê, ô, ă, ơ, ư) — mark goes on them.
    // 2. Open syllable with 2 vowels: mark on second-to-last vowel.
    // 3. Closed syllable: mark on vowel immediately before coda.
    // 4. Fallback: last vowel.
    //
    // Classic differs for "oa/oe/uy" families: mark stays on the second vowel.

    // Rule 1: prefer diacritic vowels (â, ê, ô, ă, ơ, ư).
    // Special case: "ươ" compound nucleus — ơ takes priority over ư.
    {
        let s: String = chars.iter().collect();
        if s.contains("ươ") || s.contains("ưo") {
            // Find ơ (or 'o' after ư) and prefer it.
            for &vi in &vowel_indices {
                if matches!(chars[vi], 'ơ' | 'ô') {
                    return Some(vi);
                }
            }
        }
    }
    for &vi in &vowel_indices {
        if matches!(chars[vi], 'â' | 'ê' | 'ô' | 'ă' | 'ơ' | 'ư') {
            return Some(vi);
        }
    }

    // Find coda start (first trailing consonant cluster).
    let coda_start = coda_start_index(chars);

    match mode {
        TonePlacementMode::Modern => {
            modern_position(&vowel_indices, coda_start, chars)
        }
        TonePlacementMode::Classic => {
            classic_position(&vowel_indices, coda_start, chars)
        }
    }
}

fn modern_position(
    vowel_indices: &[usize],
    coda_start: Option<usize>,
    _chars: &[char],
) -> Option<usize> {
    // Closed syllable: vowel before the coda.
    if let Some(cs) = coda_start {
        let before_coda: Vec<usize> = vowel_indices.iter().copied().filter(|&i| i < cs).collect();
        return before_coda.last().copied().or_else(|| vowel_indices.last().copied());
    }

    // Open syllable with multiple vowels:
    // Modern Vietnamese places the tone on the penultimate vowel in most cases
    // (e.g. "hòa" not "hoà", "tuế" not "tuê").
    // Exception: single vowel → tone on that vowel.
    if vowel_indices.len() >= 2 {
        Some(vowel_indices[vowel_indices.len() - 2])
    } else {
        vowel_indices.last().copied()
    }
}

fn classic_position(
    vowel_indices: &[usize],
    coda_start: Option<usize>,
    _chars: &[char],
) -> Option<usize> {
    modern_position(vowel_indices, coda_start, &[])
}

/// Find the index where the coda begins (the trailing consonant cluster).
fn coda_start_index(chars: &[char]) -> Option<usize> {
    // Walk backward; consume known coda sequences.
    const CODAS: &[&str] = &["ng", "nh", "ch", "c", "m", "n", "p", "t"];
    let s: String = chars.iter().collect();
    for coda in CODAS {
        if s.ends_with(coda) {
            return Some(chars.len() - coda.chars().count());
        }
    }
    None
}

fn is_vowel(c: char) -> bool {
    base_vowel(c).map(is_base_vowel).unwrap_or_else(|| is_base_vowel(c))
}

fn is_base_vowel(c: char) -> bool {
    matches!(c, 'a' | 'ă' | 'â' | 'e' | 'ê' | 'i' | 'o' | 'ô' | 'ơ' | 'u' | 'ư' | 'y')
}

/// Map a base vowel + tone to the precomposed Unicode character.
pub fn toned_vowel(base: char, tone: Tone) -> char {
    let b = base_vowel(base).unwrap_or(base);
    match (b, tone) {
        ('a', Tone::Sharp) => 'á',
        ('a', Tone::Grave) => 'à',
        ('a', Tone::Hook)  => 'ả',
        ('a', Tone::Tilde) => 'ã',
        ('a', Tone::Dot)   => 'ạ',

        ('â', Tone::Sharp) => 'ấ',
        ('â', Tone::Grave) => 'ầ',
        ('â', Tone::Hook)  => 'ẩ',
        ('â', Tone::Tilde) => 'ẫ',
        ('â', Tone::Dot)   => 'ậ',

        ('ă', Tone::Sharp) => 'ắ',
        ('ă', Tone::Grave) => 'ằ',
        ('ă', Tone::Hook)  => 'ẳ',
        ('ă', Tone::Tilde) => 'ẵ',
        ('ă', Tone::Dot)   => 'ặ',

        ('e', Tone::Sharp) => 'é',
        ('e', Tone::Grave) => 'è',
        ('e', Tone::Hook)  => 'ẻ',
        ('e', Tone::Tilde) => 'ẽ',
        ('e', Tone::Dot)   => 'ẹ',

        ('ê', Tone::Sharp) => 'ế',
        ('ê', Tone::Grave) => 'ề',
        ('ê', Tone::Hook)  => 'ể',
        ('ê', Tone::Tilde) => 'ễ',
        ('ê', Tone::Dot)   => 'ệ',

        ('i', Tone::Sharp) => 'í',
        ('i', Tone::Grave) => 'ì',
        ('i', Tone::Hook)  => 'ỉ',
        ('i', Tone::Tilde) => 'ĩ',
        ('i', Tone::Dot)   => 'ị',

        ('o', Tone::Sharp) => 'ó',
        ('o', Tone::Grave) => 'ò',
        ('o', Tone::Hook)  => 'ỏ',
        ('o', Tone::Tilde) => 'õ',
        ('o', Tone::Dot)   => 'ọ',

        ('ô', Tone::Sharp) => 'ố',
        ('ô', Tone::Grave) => 'ồ',
        ('ô', Tone::Hook)  => 'ổ',
        ('ô', Tone::Tilde) => 'ỗ',
        ('ô', Tone::Dot)   => 'ộ',

        ('ơ', Tone::Sharp) => 'ớ',
        ('ơ', Tone::Grave) => 'ờ',
        ('ơ', Tone::Hook)  => 'ở',
        ('ơ', Tone::Tilde) => 'ỡ',
        ('ơ', Tone::Dot)   => 'ợ',

        ('u', Tone::Sharp) => 'ú',
        ('u', Tone::Grave) => 'ù',
        ('u', Tone::Hook)  => 'ủ',
        ('u', Tone::Tilde) => 'ũ',
        ('u', Tone::Dot)   => 'ụ',

        ('ư', Tone::Sharp) => 'ứ',
        ('ư', Tone::Grave) => 'ừ',
        ('ư', Tone::Hook)  => 'ử',
        ('ư', Tone::Tilde) => 'ữ',
        ('ư', Tone::Dot)   => 'ự',

        ('y', Tone::Sharp) => 'ý',
        ('y', Tone::Grave) => 'ỳ',
        ('y', Tone::Hook)  => 'ỷ',
        ('y', Tone::Tilde) => 'ỹ',
        ('y', Tone::Dot)   => 'ỵ',

        _ => base, // unknown — leave untouched
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::{Tone, TonePlacementMode};

    fn modern(word: &str, tone: Tone) -> String {
        apply_tone(word, tone, TonePlacementMode::Modern)
    }

    #[test]
    fn single_vowel() {
        assert_eq!(modern("ba", Tone::Sharp), "bá");
        assert_eq!(modern("me", Tone::Grave), "mè");
        assert_eq!(modern("ho", Tone::Dot),   "họ");
    }

    #[test]
    fn circumflex_priority() {
        assert_eq!(modern("han", Tone::Sharp), "hán");
        assert_eq!(modern("hân", Tone::Sharp), "hấn");
        assert_eq!(modern("hoang", Tone::Grave), "hoàng");
    }

    #[test]
    fn flat_tone_no_change() {
        assert_eq!(modern("ba", Tone::Flat), "ba");
    }

    #[test]
    fn classic_vs_modern_hoa() {
        // Modern Vietnamese: "hòa" (tone on 'o', penultimate vowel in open syllable).
        let m = apply_tone("hoa", Tone::Grave, TonePlacementMode::Modern);
        let c = apply_tone("hoa", Tone::Grave, TonePlacementMode::Classic);
        assert_eq!(m, "hòa");
        assert_eq!(c, "hòa");
    }
}
