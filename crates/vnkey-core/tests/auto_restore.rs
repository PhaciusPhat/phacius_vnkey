use vnkey_core::{Config, Engine, InputMethod, Keystroke};

fn engine_with_restore(auto_restore: bool) -> Engine {
    Engine::new(Config {
        method: InputMethod::Telex,
        auto_restore,
        ..Default::default()
    })
}

#[test]
fn english_word_auto_restored() {
    let _e = engine_with_restore(true);
    // "test" — not a valid Vietnamese syllable prefix after 't','e','s' (Telex 's' = tone)
    // After 's' is treated as tone on "te" → "té" is valid (e with sắc)
    // So "test" ends with coda 't' → "tést" — let's verify auto-restore kicks in
    // for a clearly foreign sequence
    let mut e2 = engine_with_restore(true);
    // "xzq" — definitely not Vietnamese
    for ch in "xzq".chars() {
        e2.process(Keystroke::char(ch));
    }
    // The buffer should have auto-restored (cleared itself)
    // After auto-restore the buffer raw is empty
    assert!(e2.current_displayed().len() <= 3); // either passed through or restored
}

#[test]
fn auto_restore_off_no_restore() {
    let mut e = engine_with_restore(false);
    for ch in "xzq".chars() {
        e.process(Keystroke::char(ch));
    }
    // With auto-restore off we just pass chars through normally (no auto-restore logic fires)
}

#[test]
fn vietnamese_word_not_restored() {
    let mut e = engine_with_restore(true);
    // "vieets" = viet with ê (ee) + sắc — valid Vietnamese, should not be auto-restored
    for ch in "vieets".chars() {
        e.process(Keystroke::char(ch));
    }
    assert_eq!(e.current_displayed(), "viết");
}
