import XCTest
@testable import Tqdm

final class swift_tqdmTests: XCTestCase {
    func testFormatInterval() {
        XCTAssertEqual(formatInterval(t: TimeInterval(60)), "01:00")
        XCTAssertEqual(formatInterval(t: TimeInterval(6160)), "1:42:40")
        XCTAssertEqual(formatInterval(t: TimeInterval(238113)), "66:08:33")
    }

    func testFormatSizeof() {
        XCTAssertEqual(formatSizeof(number: 9), "9.00")
        XCTAssertEqual(formatSizeof(number: 99), "99.0")
        XCTAssertEqual(formatSizeof(number: 999), "999")
        XCTAssertEqual(formatSizeof(number: 9994), "9.99k")
        XCTAssertEqual(formatSizeof(number: 9999), "10.0k")
        XCTAssertEqual(formatSizeof(number: 99499), "99.5k")
        XCTAssertEqual(formatSizeof(number: 99999), "100k")
        XCTAssertEqual(formatSizeof(number: 999999), "1.00M")

        // These generate floating point representation warning
        XCTAssertEqual(formatSizeof(number: 999_999_999), "1.00G")
        XCTAssertEqual(formatSizeof(number: 999_999_999_999), "1.00T")
        XCTAssertEqual(formatSizeof(number: 999_999_999_999_999), "1.00P")
        XCTAssertEqual(formatSizeof(number: 999_999_999_999_999_999), "1.00E")
        XCTAssertEqual(formatSizeof(number: 999_999_999_999_999_999_999), "1.00Z")
        XCTAssertEqual(formatSizeof(number: 999_999_999_999_999_999_999_999), "1.0Y")
        XCTAssertEqual(formatSizeof(number: 9_999_999_999_999_999_999_999_999), "10.0Y")
        XCTAssertEqual(formatSizeof(number: 99_999_999_999_999_999_999_999_999), "100.0Y")
        XCTAssertEqual(formatSizeof(number: 999_999_999_999_999_999_999_999_999), "1000.0Y")
    }

    func testBarFormat() {
        XCTAssertEqual(Bar(frac: 0.3, length: 5, charsetType: .ascii).format(), "#5   ")
        XCTAssertEqual(Bar(frac: 0.5, length: 4, charsetType: .ascii).format(), "##  ")
        XCTAssertEqual(Bar(frac: 0.5, charsetType: .ascii).format(), "#####     ")
        XCTAssertEqual(Bar(frac: 0.5, charsetType: .utf).format(), "█████     ")
    }

    func testTqdmWrapper() {
        let N : Int = 100
        let squares = (0..<N).map{ $0 * $0 }
        let wrappedSequence = TqdmSequence(sequence: squares)
        XCTAssertEqual(wrappedSequence.reduce(0, +), (N - 1) * N * (2 * N - 1) / 6)
        let fruits = ["apple", "pear", "banana", "orange"]
        var fruitsString = ""
        for fruit in TqdmSequence(sequence: fruits, color: .green) {
            fruitsString += "\(fruit) "
        }
        XCTAssertEqual(fruitsString, "apple pear banana orange ")
    }

    func testSetDescription() {
        let tqdm = Tqdm()
        XCTAssertEqual(tqdm.description, "")
        tqdm.setDescription(description: "first")
        XCTAssertEqual(tqdm.description, "first")
        tqdm.setDescription(description: "second :")
        XCTAssertEqual(tqdm.description, "second")
        tqdm.setDescription(description: "third : ")
        XCTAssertEqual(tqdm.description, "third")
        tqdm.setDescription(description: "fourth  :: ")
        XCTAssertEqual(tqdm.description, "fourth")
        tqdm.setDescription(description: nil)
        XCTAssertEqual(tqdm.description, "")
    }

    static var allTests = [
        ("testFormatInterval", testFormatInterval),
        ("testFormatSizeof", testFormatSizeof),
        ("testBarFormat", testBarFormat),
        ("testTqdmWrapper", testTqdmWrapper),
        ("testSetDescription", testSetDescription),
    ]
}
