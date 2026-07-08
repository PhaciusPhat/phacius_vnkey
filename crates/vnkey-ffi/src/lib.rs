use std::panic::catch_unwind;
use vnkey_core::{Config, EditAction, Engine, InputMethod, Keystroke, TonePlacementMode};

// ── C-facing types ────────────────────────────────────────────────────────────

/// Input method selector.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub enum VnkeyInputMethod {
    Telex = 0,
    Vni = 1,
}

/// Tone-placement mode.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub enum VnkeyTonePlacement {
    Modern = 0,
    Classic = 1,
}

/// Configuration passed when creating or reconfiguring an engine.
#[repr(C)]
pub struct VnkeyConfig {
    pub method: VnkeyInputMethod,
    pub placement: VnkeyTonePlacement,
    pub enabled: bool,
    pub auto_restore: bool,
}

/// A single edit action returned to the shell.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub enum VnkeyActionKind {
    /// No action — used as a null sentinel in arrays.
    None = 0,
    /// Delete `count` characters to the left.
    Backspace = 1,
    /// Insert UTF-8 text (pointer into action's `text` buffer).
    Insert = 2,
}

/// Maximum length of an inserted string in one action.
pub const VNKEY_INSERT_MAX: usize = 64;

/// One edit action.
#[repr(C)]
pub struct VnkeyAction {
    pub kind: VnkeyActionKind,
    /// For Backspace: number of characters to delete.
    pub count: u8,
    /// For Insert: null-terminated UTF-8 string.
    pub text: [u8; VNKEY_INSERT_MAX],
}

impl VnkeyAction {
    fn none() -> Self {
        Self { kind: VnkeyActionKind::None, count: 0, text: [0; VNKEY_INSERT_MAX] }
    }

    fn backspace(n: u8) -> Self {
        Self { kind: VnkeyActionKind::Backspace, count: n, text: [0; VNKEY_INSERT_MAX] }
    }

    fn insert(s: &str) -> Self {
        let mut text = [0u8; VNKEY_INSERT_MAX];
        let bytes = s.as_bytes();
        let len = bytes.len().min(VNKEY_INSERT_MAX - 1);
        text[..len].copy_from_slice(&bytes[..len]);
        Self { kind: VnkeyActionKind::Insert, count: 0, text }
    }
}

/// Result of processing one keystroke.
#[repr(C)]
pub struct VnkeyResult {
    /// Number of valid actions in `actions`.
    pub action_count: u8,
    pub actions: [VnkeyAction; 4],
}

impl VnkeyResult {
    fn passthrough() -> Self {
        Self {
            action_count: 0,
            actions: [
                VnkeyAction::none(),
                VnkeyAction::none(),
                VnkeyAction::none(),
                VnkeyAction::none(),
            ],
        }
    }

    fn from_actions(edit_actions: Vec<EditAction>) -> Self {
        let mut result = Self::passthrough();
        let count = edit_actions.len().min(4);
        result.action_count = count as u8;
        for (i, ea) in edit_actions.into_iter().take(4).enumerate() {
            result.actions[i] = match ea {
                EditAction::Backspace(n) => VnkeyAction::backspace(n),
                EditAction::Insert(s) => VnkeyAction::insert(&s),
            };
        }
        result
    }
}

// ── Engine handle ─────────────────────────────────────────────────────────────

/// Opaque engine handle.
pub struct VnkeyEngine(Engine);

// ── Public C API ──────────────────────────────────────────────────────────────

/// Create a new engine. The caller owns the returned pointer and must free it
/// with `vnkey_engine_free`.
#[no_mangle]
pub extern "C" fn vnkey_engine_new(config: VnkeyConfig) -> *mut VnkeyEngine {
    let result = catch_unwind(|| {
        let cfg = to_core_config(config);
        Box::into_raw(Box::new(VnkeyEngine(Engine::new(cfg))))
    });
    result.unwrap_or(std::ptr::null_mut())
}

/// Free an engine previously created with `vnkey_engine_new`.
///
/// # Safety
/// `engine` must be a valid non-null pointer returned by `vnkey_engine_new`
/// that has not already been freed.
#[no_mangle]
pub unsafe extern "C" fn vnkey_engine_free(engine: *mut VnkeyEngine) {
    if !engine.is_null() {
        let _ = catch_unwind(|| {
            drop(Box::from_raw(engine));
        });
    }
}

/// Process one keystroke. Returns the edit actions the shell must execute.
/// Returns a passthrough result (action_count=0) on any internal error.
///
/// # Safety
/// `engine` must be a valid non-null pointer returned by `vnkey_engine_new`.
#[no_mangle]
pub unsafe extern "C" fn vnkey_engine_process(
    engine: *mut VnkeyEngine,
    codepoint: u32,
    is_boundary: bool,
) -> VnkeyResult {
    if engine.is_null() {
        return VnkeyResult::passthrough();
    }
    catch_unwind(|| {
        let eng = &mut (*engine).0;
        let ch = match char::from_u32(codepoint) {
            Some(c) => c,
            None => return VnkeyResult::passthrough(), // invalid Unicode scalar → pass through
        };
        let key = if is_boundary {
            Keystroke { ch, is_boundary: true }
        } else {
            Keystroke::char(ch)
        };
        let actions = eng.process(key);
        VnkeyResult::from_actions(actions)
    })
    .unwrap_or_else(|_| VnkeyResult::passthrough())
}

/// Reset the engine composition buffer (e.g. on focus change / mouse click).
///
/// # Safety
/// `engine` must be a valid non-null pointer returned by `vnkey_engine_new`.
#[no_mangle]
pub unsafe extern "C" fn vnkey_engine_reset(engine: *mut VnkeyEngine) {
    if engine.is_null() {
        return;
    }
    let _ = catch_unwind(|| {
        (*engine).0.reset();
    });
}

/// Update the engine configuration without recreating it.
///
/// # Safety
/// `engine` must be a valid non-null pointer returned by `vnkey_engine_new`.
#[no_mangle]
pub unsafe extern "C" fn vnkey_engine_set_config(
    engine: *mut VnkeyEngine,
    config: VnkeyConfig,
) {
    if engine.is_null() {
        return;
    }
    let _ = catch_unwind(|| {
        (*engine).0.set_config(to_core_config(config));
    });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn to_core_config(c: VnkeyConfig) -> Config {
    Config {
        method: match c.method {
            VnkeyInputMethod::Telex => InputMethod::Telex,
            VnkeyInputMethod::Vni => InputMethod::Vni,
        },
        placement: match c.placement {
            VnkeyTonePlacement::Modern => TonePlacementMode::Modern,
            VnkeyTonePlacement::Classic => TonePlacementMode::Classic,
        },
        enabled: c.enabled,
        auto_restore: c.auto_restore,
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    fn default_config() -> VnkeyConfig {
        VnkeyConfig {
            method: VnkeyInputMethod::Telex,
            placement: VnkeyTonePlacement::Modern,
            enabled: true,
            auto_restore: true,
        }
    }

    #[test]
    fn roundtrip_create_free() {
        let ptr = vnkey_engine_new(default_config());
        assert!(!ptr.is_null());
        unsafe { vnkey_engine_free(ptr) };
    }

    #[test]
    fn roundtrip_process() {
        let ptr = vnkey_engine_new(default_config());
        assert!(!ptr.is_null());

        // Type 'h', 'a', 's' → expect an Insert("há") at some point.
        let mut saw_insert = false;
        for ch in "has".chars() {
            let result = unsafe { vnkey_engine_process(ptr, ch as u32, false) };
            for i in 0..result.action_count as usize {
                if let VnkeyActionKind::Insert = result.actions[i].kind {
                    saw_insert = true;
                }
            }
        }
        assert!(saw_insert, "expected at least one Insert action");
        unsafe { vnkey_engine_free(ptr) };
    }

    #[test]
    fn null_pointer_safety() {
        // None of these should panic or crash.
        let result = unsafe { vnkey_engine_process(std::ptr::null_mut(), 'a' as u32, false) };
        assert_eq!(result.action_count, 0);
        unsafe { vnkey_engine_reset(std::ptr::null_mut()) };
        unsafe { vnkey_engine_free(std::ptr::null_mut()) };
    }

    #[test]
    fn invalid_codepoint_safety() {
        let ptr = vnkey_engine_new(default_config());
        // 0xD800 is a surrogate — not a valid Unicode scalar.
        let result = unsafe { vnkey_engine_process(ptr, 0xD800, false) };
        // Should return passthrough, not crash.
        assert_eq!(result.action_count, 0);
        unsafe { vnkey_engine_free(ptr) };
    }

    #[test]
    fn reset_clears_state() {
        let ptr = vnkey_engine_new(default_config());
        unsafe {
            vnkey_engine_process(ptr, 'h' as u32, false);
            vnkey_engine_process(ptr, 'a' as u32, false);
            vnkey_engine_reset(ptr);
            // After reset, processing 'h' again should not produce a backspace for old state.
            let result = vnkey_engine_process(ptr, 'h' as u32, false);
            // First char 'h' alone should not produce a backspace > 1.
            for i in 0..result.action_count as usize {
                if let VnkeyActionKind::Backspace = result.actions[i].kind {
                    assert!(result.actions[i].count <= 1);
                }
            }
            vnkey_engine_free(ptr);
        }
    }
}
