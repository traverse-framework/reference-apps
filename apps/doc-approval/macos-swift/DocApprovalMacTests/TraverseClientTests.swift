import Foundation
import XCTest
@testable import DocApprovalMac

final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

enum TestURLSessionFactory {
    static func make() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

final class TraverseClientTests: XCTestCase {
    func testCheckHealthReturnsTrueOn200() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/healthz")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let client = TraverseClient(session: TestURLSessionFactory.make())
        let ok = try await client.checkHealth(baseURL: URL(string: "http://127.0.0.1:8787")!)
        XCTAssertTrue(ok)
    }

    func testExecuteReturnsExecutionId() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let body = #"{"execution_id":"exec_abc"}"#.data(using: .utf8)!
            return (response, body)
        }
        let client = TraverseClient(session: TestURLSessionFactory.make())
        let id = try await client.execute(
            workspaceId: "local-default",
            capability: "doc-approval.analyze",
            input: ["document": "invoice text"],
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(id, "exec_abc")
    }

    func testParseOutputFromPoll() async throws {
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "http://127.0.0.1:8787")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let body = """
            {"execution_id":"exec_abc","status":"succeeded","output":{"docType":"invoice","parties":["Acme"],"amounts":["$100"],"confidence":0.9,"recommendation":"approve"}}
            """.data(using: .utf8)!
            return (response, body)
        }
        let client = TraverseClient(session: TestURLSessionFactory.make())
        let result = try await client.pollExecution(
            workspaceId: "local-default",
            executionId: "exec_abc",
            baseURL: URL(string: "http://127.0.0.1:8787")!
        )
        XCTAssertEqual(result.status, "succeeded")
        XCTAssertEqual(result.output?.docType, "invoice")
        XCTAssertEqual(result.output?.recommendation, "approve")
    }
}
