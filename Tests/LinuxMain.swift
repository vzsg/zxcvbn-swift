import XCTest

import zxcvbnTests

var tests = [XCTestCaseEntry]()
tests += zxcvbnTests.allTests()
XCTMain(tests)