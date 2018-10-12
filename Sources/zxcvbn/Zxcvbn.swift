import czxcvbn
import Foundation

public enum Zxcvbn {
    public struct Match {
        public let begin: Int
        public let length: Int
        public let entropy: Double
        public let type: MatchType
    }

    public enum MatchType: UInt32 {
        case nonMatch = 0
        case bruteMatch = 1
        case dictionaryMatch = 2
        case dictLeetMatch = 3
        case userMatch = 4
        case userLeetMatch = 5
        case repeatsMatch = 6
        case sequenceMatch = 7
        case spatialMatch = 8
        case dateMatch = 9
        case yearMatch = 10
        case multipleMatch = 32
    }

    public struct Result {
        let entropy: Double
        let matches: [Match]
    }

    public static func estimate(_ password: String, userInfo: [String] = []) -> Result {
        var info: UnsafeMutablePointer<ZxcMatch_t>?

        defer {
            ZxcvbnFreeInfo(info)
        }

        guard !userInfo.isEmpty else {
            let entropy = ZxcvbnMatch(password, nil, &info)
            return Result(entropy: entropy, matches: convertInfo(info?.pointee))
        }

        return withArrayOfCStrings(userInfo) { userInfo in
            let entropy = ZxcvbnMatch(password, userInfo, &info)
            return Result(entropy: entropy, matches: convertInfo(info?.pointee))
        }
    }
}

private func convertInfo(_ info: ZxcMatch_t?) -> [Zxcvbn.Match] {
    var result = [Zxcvbn.Match]()
    var current = info

    while current != nil {
        let match = Zxcvbn.Match(
            begin: Int(current!.Begin),
            length: Int(current!.Length),
            entropy: current!.Entrpy,
            type: Zxcvbn.MatchType(rawValue: current!.Type.rawValue) ?? .nonMatch)
        result.append(match)

        current = current!.Next?.pointee
    }

    return result
}

private func withArrayOfCStrings<R>(_ args: [String], _ body: (UnsafeMutablePointer<UnsafePointer<CChar>?>) -> R) -> R {
    let argsCounts = Array(args.map { $0.utf8.count + 1 })
    let argsOffsets = [ 0 ] + scan(argsCounts, 0, +)
    let argsBufferSize = argsOffsets.last!

    var argsBuffer: [UInt8] = []
    argsBuffer.reserveCapacity(argsBufferSize)
    for arg in args {
        argsBuffer.append(contentsOf: arg.utf8)
        argsBuffer.append(0)
    }

    return argsBuffer.withUnsafeMutableBufferPointer {
        (argsBuffer) in
        let ptr = UnsafeMutableRawPointer(argsBuffer.baseAddress!).bindMemory(to: CChar.self, capacity: argsBuffer.count)
        var cStrings: [UnsafePointer<CChar>?] = argsOffsets.map { UnsafePointer(ptr + $0) }
        cStrings[cStrings.count - 1] = nil

        return cStrings.withUnsafeMutableBufferPointer { buf in body(buf.baseAddress!) }
    }
}

/// Compute the prefix sum of `seq`.
private func scan<S : Sequence, U>(_ seq: S, _ initial: U, _ combine: (U, S.Iterator.Element) -> U) -> [U] {
    var result: [U] = []
    result.reserveCapacity(seq.underestimatedCount)
    var runningResult = initial
    for element in seq {
        runningResult = combine(runningResult, element)
        result.append(runningResult)
    }
    return result
}
