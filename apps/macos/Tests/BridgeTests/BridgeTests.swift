import XCTest
@testable import Bridge

final class BridgeTests: XCTestCase {
    func testEngineCreation() {
        let engine = VNEngine(method: .telex, placement: .modern, enabled: true, autoRestore: true)
        // Just ensure we can create and use the engine without crashing.
        let actions = engine.process(character: "h")
        XCTAssertNotNil(actions)
    }

    func testTelexHaSharp() {
        let engine = VNEngine(method: .telex)
        _ = engine.process(character: "h")
        _ = engine.process(character: "a")
        let actions = engine.process(character: "s")
        let inserts = actions.compactMap { if case .insert(let s) = $0 { return s } else { return nil } }
        XCTAssertTrue(inserts.contains("á"), "Expected 'á' in inserts, got \(inserts)")
    }

    func testResetClearsState() {
        let engine = VNEngine(method: .telex)
        _ = engine.process(character: "h")
        _ = engine.process(character: "a")
        engine.reset()
        // After reset, first character should not generate excessive backspaces.
        let actions = engine.process(character: "h")
        let backspaces = actions.compactMap { if case .backspace(let n) = $0 { return n } else { return nil } }
        XCTAssertTrue(backspaces.allSatisfy { $0 <= 1 }, "Unexpected backspaces after reset: \(backspaces)")
    }

    func testVniMode() {
        let engine = VNEngine(method: .vni)
        _ = engine.process(character: "h")
        _ = engine.process(character: "a")
        let actions = engine.process(character: "1")
        let inserts = actions.compactMap { if case .insert(let s) = $0 { return s } else { return nil } }
        XCTAssertTrue(inserts.contains("á"), "VNI: Expected 'á', got \(inserts)")
    }

    func testDisabledEnginePassthrough() {
        let engine = VNEngine(method: .telex, enabled: false)
        let actions = engine.process(character: "a")
        XCTAssertTrue(actions.isEmpty, "Disabled engine should produce no actions")
    }

    func testReconfigure() {
        let engine = VNEngine(method: .telex, enabled: true)
        engine.setConfig(method: .vni, placement: .modern, enabled: false, autoRestore: true)
        let actions = engine.process(character: "a")
        XCTAssertTrue(actions.isEmpty, "After disabling, engine should produce no actions")
    }
}
