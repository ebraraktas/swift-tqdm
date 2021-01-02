import XCTest

import tqdmTests

var tests = [XCTestCaseEntry]()
tests += tqdmTests.allTests()
XCTMain(tests)
