pub mod telex;
pub mod vni;

pub use telex::TelexMethod;
pub use vni::VniMethod;

use crate::types::Tone;

/// Result of processing the raw buffer through an input method.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MethodResult {
    /// The bare syllable (diacritics applied, no tone mark yet).
    pub bare: String,
    /// The tone extracted from the key sequence.
    pub tone: Tone,
    /// True if the sequence is unambiguously non-Vietnamese (auto-restore).
    pub is_foreign: bool,
}

pub trait InputMethodProcessor {
    /// Process the full raw buffer and return a MethodResult.
    /// Returns None if the buffer is empty.
    fn process(&self, raw: &str) -> Option<MethodResult>;
}
