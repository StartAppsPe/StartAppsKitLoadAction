import XCTest
@testable import StartAppsKitLoadAction

class StartAppsKitLoadActionTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(StartAppsKitLoadAction().text, "Hello, World!")
    }


    static var allTests : [(String, (StartAppsKitLoadActionTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
