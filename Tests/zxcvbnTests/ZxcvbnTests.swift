import XCTest
@testable import zxcvbn

final class zxcvbnTests: XCTestCase {
    func testWithCTestCases() {
        let cases: [(String, Double)] = rawTestCases.split(separator: "\n")
            .filter { !$0.isEmpty && !$0.starts(with: "#") }
            .compactMap { line in
                let parts = line.split(separator: " ", omittingEmptySubsequences: true)

                guard parts.count == 2 else {
                    return nil
                }

                guard let entropy = Double(parts[1]) else {
                    return nil
                }

                return (String(parts[0]), entropy)
        }

        print("Testing \(cases.count) passwords...")

        cases.forEach {
            let result = Zxcvbn.estimate($0.0)
            let entropy = result.entropy
            let expected = $0.1
            let error = errorPercent(entropy, expected)
            XCTAssertLessThanOrEqual(error, 1, "Entropy of '\($0.0)' was \(entropy) instead of \(expected) | Error: \(error)%")
        }
    }

    func testBadWordReducesEntropy() {
        let original = "correcthorsebatterystaple"
        let password = "c0rr3cth0rs3b4tt3ryst4pl3"

        let result = Zxcvbn.estimate(password, userInfo: [original])

        XCTAssertEqual(result.matches.count, 1)
        XCTAssertEqual(result.matches.first?.type, .userLeetMatch)
        XCTAssertEqual(result.matches.first?.begin, 0)
        XCTAssertEqual(result.matches.first?.length, original.count)
        XCTAssertLessThanOrEqual(result.entropy, 2)

    }

    static var allTests = [
        ("testWithCTestCases", testWithCTestCases),
        ("testBadWordReducesEntropy", testBadWordReducesEntropy),
    ]
}

private func errorPercent<D: FloatingPoint>(_ calculated: D, _ expected: D) -> D {
    let safeExpected = expected == 0 ? D.leastNonzeroMagnitude : expected
    return abs((calculated - expected) / safeExpected) * 100
}

private let rawTestCases = """
zxcvbn                   5.83
qwER43@!                26.44
Tr0ub4dour&3            30.87
archi                   13.61

D0g..................   19.02
abcdefghijk987654321     8.53
neverforget13/3/1997    34.86
1qaz2wsx3edc             9.98
barbarbara              12.43
abarbarbara             16.18

temppass22              17.20
briansmith               5.32
htimsnairb               6.07
briansmith4mayor        21.63
password1                4.0
viking                   7.93
thx1138                  7.70
ScoRpi0ns               19.54
do you know             25.51

ryanhunter2000          20.8
rianhunter2000          28.25

asdfghju7654rewq        29.57
AOEUIDHG&*()LS_         33.33

12345678                 1.59
defghi6789              13.61
02468                    3.32
adgjmpsvy                4.17

rosebud                  8.09
Rosebud                  9.09
ROSEBUD                  9.09
rosebuD                  9.09
R0$38uD                 12.09
ros3bud99               14.41
r0s3bud99               14.41
R0$38uD99               17.41

verlineVANDERMARK       27.24

eheuczkqyq              41.24
rWibMFACxAUGZmxhVncy    111.0

illness                 11.26
1llness                 12.26
i1lness                 12.84
11lness                 22.44
ssenl1i                 12.84
Ba9ZyWABu99[BK#6MBgbH88Tofv)vs$w        171.63
correcthorsebatterystaple               47.98
elpatsyrettabesrohtcerroc               48.98
coRrecth0rseba++ery9.23.2007staple$     71.95

pass.word.pass.word.pass.word.          60.41
passpasswordword         17.28
quvpzquvpz               24.50

#-- with UK KBD  (US-KBD=17.08)
jkl;'#                   11.12

magicfavoriteunclepromisedpublicbotherislandjimseriouslycellleadknowingbrokenadvicesomehowpaidblairlosingpushhelpedkillingusuallyearlierbosslaurabeginninglikedinnocentdocruleselizabethsabrinasummerexcoplearnedthirtyrisklettingphillipspeakingofficerridiculoussupportafternoonericwithsobutallwellareheohaboutrightyou're   545.9
"""
