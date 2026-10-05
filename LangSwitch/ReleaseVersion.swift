/// A release version with numeric components and optional SemVer identifiers.
/// One or two core components are padded with zeroes. Build metadata is ignored
/// for equality and ordering, as it does not change release precedence.
struct ReleaseVersion: Comparable, Sendable {
    private enum PrereleaseIdentifier: Equatable, Sendable {
        case numeric(String)
        case text(String)
    }

    private let components: [String]
    private let prerelease: [PrereleaseIdentifier]?

    init?(_ rawValue: String) {
        var value = rawValue[...]
        if value.first == "v" || value.first == "V" {
            value = value.dropFirst()
        }

        let metadataParts = value.split(separator: "+", omittingEmptySubsequences: false)
        guard metadataParts.count <= 2 else { return nil }
        if metadataParts.count == 2 {
            guard Self.identifiersAreValid(metadataParts[1]) else { return nil }
        }

        let versionParts = metadataParts[0].split(
            separator: "-", maxSplits: 1, omittingEmptySubsequences: false
        )
        let core = versionParts[0].split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(core.count), core.allSatisfy(Self.isCanonicalNumber) else {
            return nil
        }

        var components = core.map(String.init)
        while components.count < 3 {
            components.append("0")
        }
        self.components = components

        if versionParts.count == 2 {
            guard Self.identifiersAreValid(versionParts[1]) else { return nil }
            var identifiers: [PrereleaseIdentifier] = []
            for identifier in versionParts[1].split(separator: ".") {
                if Self.isNumber(identifier) {
                    guard Self.isCanonicalNumber(identifier) else { return nil }
                    identifiers.append(.numeric(String(identifier)))
                } else {
                    identifiers.append(.text(String(identifier)))
                }
            }
            prerelease = identifiers
        } else {
            prerelease = nil
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.components == rhs.components && lhs.prerelease == rhs.prerelease
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        for (left, right) in zip(lhs.components, rhs.components) where left != right {
            return numberIsLess(left, than: right)
        }

        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil):
            return false
        case (nil, .some):
            return false
        case (.some, nil):
            return true
        case let (.some(left), .some(right)):
            for (leftIdentifier, rightIdentifier) in zip(left, right) {
                guard leftIdentifier != rightIdentifier else { continue }
                switch (leftIdentifier, rightIdentifier) {
                case let (.numeric(leftNumber), .numeric(rightNumber)):
                    return numberIsLess(leftNumber, than: rightNumber)
                case (.numeric, .text):
                    return true
                case (.text, .numeric):
                    return false
                case let (.text(leftText), .text(rightText)):
                    return leftText < rightText
                }
            }
            return left.count < right.count
        }
    }

    private static func numberIsLess(_ lhs: String, than rhs: String) -> Bool {
        if lhs.utf8.count != rhs.utf8.count {
            return lhs.utf8.count < rhs.utf8.count
        }
        return lhs < rhs
    }

    private static func isNumber(_ value: Substring) -> Bool {
        !value.isEmpty && value.utf8.allSatisfy { (48...57).contains($0) }
    }

    private static func isCanonicalNumber(_ value: Substring) -> Bool {
        isNumber(value) && (value.count == 1 || value.first != "0")
    }

    private static func identifiersAreValid(_ value: Substring) -> Bool {
        value.split(separator: ".", omittingEmptySubsequences: false).allSatisfy { identifier in
            !identifier.isEmpty && identifier.utf8.allSatisfy {
                (48...57).contains($0) || (65...90).contains($0)
                    || (97...122).contains($0) || $0 == 45
            }
        }
    }
}
