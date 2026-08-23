import XCTest
@testable import LoopCore

final class PresentationMapperTests: XCTestCase {
    func testEmptyStreamIsIdle() {
        let snap = PresentationMapper.mapPresentationState([])
        XCTAssertEqual(snap.state, .idle)
        XCTAssertNil(snap.errorMessage)
    }

    func testHappyPathLoads() {
        let events: [EmbedderEventLike] = [
            .init(eventType: "capability_invoked", sequence: 1, data: [
                "capability_id": "fixture.process",
            ]),
            .init(eventType: "capability_result", sequence: 2, data: [
                "capability_id": "fixture.process",
                "output": ["ok": true],
            ]),
        ]
        let snap = PresentationMapper.mapPresentationState(events)
        XCTAssertEqual(snap.state, .loaded)
        let progress = PresentationMapper.mapCapabilityProgress(events)
        XCTAssertEqual(progress.map(\.capabilityId), ["fixture.process", "fixture.process"])
        XCTAssertEqual(progress.map(\.phase), [.invoked, .result])
        XCTAssertNil(PresentationMapper.activeCapabilityId(events))
    }

    func testBlockedWaitingForHuman() {
        let events: [EmbedderEventLike] = [
            .init(eventType: "capability_invoked", sequence: 1, data: [
                "capability_id": "fixture.approve",
            ]),
            .init(eventType: "state_changed", sequence: 2, data: [
                "state": "waiting_for_human",
            ]),
        ]
        XCTAssertEqual(PresentationMapper.mapPresentationState(events).state, .blocked)
        XCTAssertEqual(PresentationMapper.activeCapabilityId(events), "fixture.approve")
    }

    func testErrorPath() {
        let events: [EmbedderEventLike] = [
            .init(eventType: "error", sequence: 1, data: [
                "error": ["message": "boom"],
            ]),
        ]
        let snap = PresentationMapper.mapPresentationState(events)
        XCTAssertEqual(snap.state, .error)
        XCTAssertEqual(snap.errorMessage, "boom")
    }
}
