use crate::types::Tone;
use super::{InputMethodProcessor, MethodResult};

pub struct VniMethod;

impl InputMethodProcessor for VniMethod {
    fn process(&self, raw: &str) -> Option<MethodResult> {
        if raw.is_empty() {
            return None;
        }
        Some(process_vni(raw))
    }
}

/// Process a raw VNI keystroke sequence.
///
/// VNI rules:
///   1 → sắc, 2 → huyền, 3 → hỏi, 4 → ngã, 5 → nặng, 0 → remove tone
///   6 → circumflex on preceding vowel (a→â, e→ê, o→ô)
///   7 → horn on preceding vowel (o→ơ, u→ư)
///   8 → breve on preceding vowel (a→ă)
///   9 → đ (only replaces 'd' at onset)
pub fn process_vni(raw: &str) -> MethodResult {
    let mut syllable = String::new();
    let mut tone = Tone::Flat;

    for ch in raw.chars() {
        match ch {
            '1' => { if has_vowel(&syllable) { tone = Tone::Sharp; } else { syllable.push(ch); } }
            '2' => { if has_vowel(&syllable) { tone = Tone::Grave; } else { syllable.push(ch); } }
            '3' => { if has_vowel(&syllable) { tone = Tone::Hook;  } else { syllable.push(ch); } }
            '4' => { if has_vowel(&syllable) { tone = Tone::Tilde; } else { syllable.push(ch); } }
            '5' => { if has_vowel(&syllable) { tone = Tone::Dot;   } else { syllable.push(ch); } }
            '0' => { if has_vowel(&syllable) { tone = Tone::Flat;  } else { syllable.push(ch); } }
            '6' => {
                if apply_circumflex(&mut syllable) { /* applied */ } else { syllable.push(ch); }
            }
            '7' => {
                if apply_horn(&mut syllable) { /* applied */ } else { syllable.push(ch); }
            }
            '8' => {
                if apply_breve(&mut syllable) { /* applied */ } else { syllable.push(ch); }
            }
            '9' => {
                if apply_stroke_d(&mut syllable) { /* applied */ } else { syllable.push(ch); }
            }
            _ => {
                syllable.push(ch.to_lowercase().next().unwrap_or(ch));
            }
        }
    }

    MethodResult { bare: syllable, tone, is_foreign: false }
}

fn has_vowel(s: &str) -> bool {
    s.chars().any(|c| matches!(c,
        'a'|'â'|'ă'|'e'|'ê'|'i'|'o'|'ô'|'ơ'|'u'|'ư'|'y'
    ))
}

/// Apply circumflex to the last eligible vowel (a→â, e→ê, o→ô). Returns true if applied.
fn apply_circumflex(s: &mut String) -> bool {
    replace_last_vowel(s, |c| match c {
        'a' => Some('â'),
        'e' => Some('ê'),
        'o' => Some('ô'),
        _ => None,
    })
}

/// Apply horn (o→ơ, u→ư). Returns true if applied.
/// The compound "uo" cluster → "ươ" both chars together.
fn apply_horn(s: &mut String) -> bool {
    // Handle "uo" compound: both u and o get horn together.
    if let Some(pos) = s.find("uo") {
        let mut new = s[..pos].to_string();
        new.push('ư');
        new.push('ơ');
        new.push_str(&s[pos + 2..]);
        *s = new;
        return true;
    }
    // Single vowel: try 'u' first, then 'o'.
    if replace_last_vowel(s, |c| if c == 'u' { Some('ư') } else { None }) {
        return true;
    }
    replace_last_vowel(s, |c| if c == 'o' { Some('ơ') } else { None })
}

/// Apply breve (a→ă). Returns true if applied.
fn apply_breve(s: &mut String) -> bool {
    replace_last_vowel(s, |c| match c {
        'a' => Some('ă'),
        _ => None,
    })
}

/// Replace 'd' at the start of the syllable with 'đ'. Returns true if applied.
fn apply_stroke_d(s: &mut String) -> bool {
    if s.starts_with('d') {
        s.replace_range(..1, "đ");
        true
    } else {
        false
    }
}

/// Replace the last vowel in `s` using `f`. Returns true if a replacement was made.
fn replace_last_vowel(s: &mut String, f: impl Fn(char) -> Option<char>) -> bool {
    let chars: Vec<char> = s.chars().collect();
    // Find rightmost vowel.
    for i in (0..chars.len()).rev() {
        if let Some(replacement) = f(chars[i]) {
            // Rebuild the string.
            let mut new = String::new();
            for (j, &c) in chars.iter().enumerate() {
                if j == i { new.push(replacement); } else { new.push(c); }
            }
            *s = new;
            return true;
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::Tone;

    fn vni(s: &str) -> (String, Tone) {
        let r = process_vni(s);
        (r.bare, r.tone)
    }

    #[test]
    fn basic_tones() {
        assert_eq!(vni("ha1"), ("ha".into(), Tone::Sharp));
        assert_eq!(vni("ha2"), ("ha".into(), Tone::Grave));
        assert_eq!(vni("ha3"), ("ha".into(), Tone::Hook));
        assert_eq!(vni("ha4"), ("ha".into(), Tone::Tilde));
        assert_eq!(vni("ha5"), ("ha".into(), Tone::Dot));
        assert_eq!(vni("ha0"), ("ha".into(), Tone::Flat));
    }

    #[test]
    fn circumflex() {
        assert_eq!(vni("a6").0, "â");
        assert_eq!(vni("e6").0, "ê");
        assert_eq!(vni("o6").0, "ô");
    }

    #[test]
    fn horn() {
        assert_eq!(vni("o7").0, "ơ");
        assert_eq!(vni("u7").0, "ư");
    }

    #[test]
    fn breve() {
        assert_eq!(vni("a8").0, "ă");
    }

    #[test]
    fn stroke_d() {
        assert_eq!(vni("d9").0, "đ");
    }

    #[test]
    fn combined() {
        // "duong7" → ư applied to 'u' → "dương" bare
        let (bare, tone) = vni("duong7");
        assert_eq!(bare, "dương");
        assert_eq!(tone, Tone::Flat);

        // "duong71" → ư + sắc
        let (bare, tone) = vni("duong71");
        assert_eq!(bare, "dương");
        assert_eq!(tone, Tone::Sharp);
    }
}
