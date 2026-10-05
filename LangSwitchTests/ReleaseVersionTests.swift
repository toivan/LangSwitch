import XCTest

final class ReleaseVersionTests: XCTestCase {
    func testNumericComponentsUseNumericPrecedence() throws {
        XCTAssertLessThan(try version("v1.9.0"), try version("v1.10.0"))
        XCTAssertLessThan(try version("2.0.0"), try version("10.0.0"))
        XCTAssertLessThan(try version("1.0.9"), try version("1.0.10"))
        XCTAssertLessThan(try version("1.99.99"), try version("2.0.0"))
    }

    func testPrefixAndMissingComponentsAreNormalized() throws {
        XCTAssertEqual(try version("v1.4.0"), try version("V1.4.0"))
        XCTAssertEqual(try version("1"), try version("1.0.0"))
        XCTAssertEqual(try version("1.10"), try version("1.10.0"))
        XCTAssertLessThan(try version("v1.9"), try version("v1.10"))
    }

    func testSemVerPrereleaseSequence() throws {
        let versions = try [
            "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta",
            "1.0.0-beta", "1.0.0-beta.2", "1.0.0-beta.11",
            "1.0.0-rc.1", "1.0.0"
        ].map(version)

        for (earlier, later) in zip(versions, versions.dropFirst()) {
            XCTAssertLessThan(earlier, later)
            XCTAssertFalse(later < earlier)
        }
    }

    func testNumericPrereleaseSortsBeforeTextAndTextIsCaseSensitive() throws {
        XCTAssertLessThan(try version("1.0.0-9"), try version("1.0.0-A"))
        XCTAssertLessThan(try version("1.0.0-A"), try version("1.0.0-a"))
        XCTAssertLessThan(try version("1.0.0-alpha"), try version("1.0.0-alpha.0"))
    }

    func testBuildMetadataDoesNotChangePrecedenceOrEquality() throws {
        let plain = try version("1.2.3")
        let withBuild = try version("1.2.3+build.001")
        let otherBuild = try version("1.2.3+other")

        XCTAssertEqual(plain, withBuild)
        XCTAssertEqual(withBuild, otherBuild)
        XCTAssertFalse(plain < withBuild)
        XCTAssertFalse(withBuild < plain)
        XCTAssertEqual(try version("1.2.3-rc.1+abc"), try version("1.2.3-rc.1+def"))
        XCTAssertLessThan(try version("1.2.3-rc.1+abc"), plain)
    }

    func testNumbersLargerThanMachineIntegerDoNotOverflow() throws {
        let huge = "99999999999999999999999999999999999999999999999999"
        let larger = "100000000000000000000000000000000000000000000000000"

        XCTAssertLessThan(try version("\(huge).0.0"), try version("\(larger).0.0"))
        XCTAssertLessThan(try version("1.0.0-\(huge)"), try version("1.0.0-\(larger)"))
        XCTAssertEqual(try version("\(huge).0.0"), try version("v\(huge)"))
    }

    func testValidIdentifierCharacters() throws {
        XCTAssertNotNil(ReleaseVersion("1.2.3-alpha-1+build-2.001"))
        XCTAssertNotNil(ReleaseVersion("0.0.0-0+0"))
        XCTAssertNotNil(ReleaseVersion("1.2.3-0alpha"))
    }

    func testInvalidVersionsAreRejected() {
        let invalid = [
            "", "v", "V", "vv1.2.3", "release-1.2.3",
            "1.2.3.4", ".1.2", "1..2", "1.2.", "1.2.3.",
            "01.2.3", "1.02.3", "1.2.03", "00", "-1.2.3",
            "1.2.x", "1.2.3-", "1.2.3+", "1.2.3-alpha..1",
            "1.2.3-01", "1.2.3-alpha.01", "1.2.3+build..1",
            "1.2.3+build+other", "1.2.3-alpha_beta", "1.2.3+build/1",
            " 1.2.3", "1.2.3 ", "1.2.3\n", "1.2.3-β", "１.2.3"
        ]

        for value in invalid {
            XCTAssertNil(ReleaseVersion(value), "Should reject \(value.debugDescription)")
        }
    }

    private func version(_ value: String) throws -> ReleaseVersion {
        try XCTUnwrap(ReleaseVersion(value), "Should accept \(value)")
    }
}
