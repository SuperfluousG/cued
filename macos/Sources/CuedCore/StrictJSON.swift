import Foundation

enum JSONValue {
    case object([String: JSONValue]), array([JSONValue]), string(String)
    case number(Double), bool(Bool), null
}

/// A small RFC 8259 parser. Foundation's permissive JSON options cannot enforce
/// duplicate-key rejection, which is part of Cued's portable input boundary.
struct StrictJSON {
    private let bytes: [UInt8]
    private var offset = 0

    init(data: Data) throws {
        guard String(data: data, encoding: .utf8) != nil else {
            throw DeckError("The deck must use UTF-8 encoding.")
        }
        bytes = Array(data)
    }

    mutating func parse() throws -> JSONValue {
        let value = try parseValue(depth: 0)
        skipSpace()
        guard offset == bytes.count else { throw error("Unexpected content after the JSON value") }
        return value
    }

    private func error(_ message: String) -> DeckError {
        DeckError("Invalid JSON at byte \(offset + 1): \(message).")
    }

    private mutating func skipSpace() {
        while offset < bytes.count && [9, 10, 13, 32].contains(bytes[offset]) { offset += 1 }
    }

    private mutating func take(_ byte: UInt8) -> Bool {
        if offset < bytes.count && bytes[offset] == byte { offset += 1; return true }
        return false
    }

    private mutating func parseValue(depth: Int) throws -> JSONValue {
        guard depth < 128 else { throw error("JSON nesting is too deep") }
        skipSpace()
        guard offset < bytes.count else { throw error("Expected a value") }
        switch bytes[offset] {
        case 123:
            offset += 1; skipSpace()
            var object: [String: JSONValue] = [:]
            if take(125) { return .object(object) }
            while true {
                skipSpace()
                guard offset < bytes.count && bytes[offset] == 34 else { throw error("Expected an object key") }
                let key = try parseString()
                guard object[key] == nil else { throw error("Duplicate object key: \(key)") }
                skipSpace()
                guard take(58) else { throw error("Expected ':'") }
                object[key] = try parseValue(depth: depth + 1)
                skipSpace()
                if take(125) { return .object(object) }
                guard take(44) else { throw error("Expected ',' or '}'") }
            }
        case 91:
            offset += 1; skipSpace()
            var array: [JSONValue] = []
            if take(93) { return .array(array) }
            while true {
                array.append(try parseValue(depth: depth + 1))
                skipSpace()
                if take(93) { return .array(array) }
                guard take(44) else { throw error("Expected ',' or ']'") }
            }
        case 34: return .string(try parseString())
        case 116: try literal("true"); return .bool(true)
        case 102: try literal("false"); return .bool(false)
        case 110: try literal("null"); return .null
        case 45, 48...57: return .number(try parseNumber())
        default: throw error("Expected a JSON value")
        }
    }

    private mutating func literal(_ text: String) throws {
        for byte in text.utf8 { guard take(byte) else { throw error("Invalid literal") } }
    }

    private mutating func parseString() throws -> String {
        offset += 1
        var output: [UInt8] = []
        while offset < bytes.count {
            let byte = bytes[offset]; offset += 1
            if byte == 34 {
                guard let result = String(bytes: output, encoding: .utf8) else { throw error("Invalid Unicode string") }
                return result
            }
            guard byte >= 32 else { throw error("Unescaped control character") }
            if byte != 92 { output.append(byte); continue }
            guard offset < bytes.count else { throw error("Incomplete escape") }
            let escaped = bytes[offset]; offset += 1
            switch escaped {
            case 34, 47, 92: output.append(escaped)
            case 98: output.append(8)
            case 102: output.append(12)
            case 110: output.append(10)
            case 114: output.append(13)
            case 116: output.append(9)
            case 117:
                var scalar = try hex4()
                if (0xD800...0xDBFF).contains(scalar) {
                    guard take(92) && take(117) else { throw error("Unpaired high surrogate") }
                    let low = try hex4()
                    guard (0xDC00...0xDFFF).contains(low) else { throw error("Unpaired high surrogate") }
                    scalar = 0x10000 + (scalar - 0xD800) * 0x400 + low - 0xDC00
                } else if (0xDC00...0xDFFF).contains(scalar) { throw error("Unpaired low surrogate") }
                guard let unicode = UnicodeScalar(scalar) else { throw error("Invalid Unicode scalar") }
                output.append(contentsOf: String(unicode).utf8)
            default: throw error("Unknown string escape")
            }
        }
        throw error("Unterminated string")
    }

    private mutating func hex4() throws -> UInt32 {
        var result: UInt32 = 0
        for _ in 0..<4 {
            guard offset < bytes.count else { throw error("Incomplete Unicode escape") }
            let byte = bytes[offset]; offset += 1
            let digit: UInt32
            switch byte {
            case 48...57: digit = UInt32(byte - 48)
            case 65...70: digit = UInt32(byte - 55)
            case 97...102: digit = UInt32(byte - 87)
            default: throw error("Invalid Unicode escape")
            }
            result = result * 16 + digit
        }
        return result
    }

    private mutating func parseNumber() throws -> Double {
        let start = offset
        _ = take(45)
        guard offset < bytes.count else { throw error("Incomplete number") }
        if take(48) { /* a leading zero cannot be followed by another digit */ }
        else {
            guard (49...57).contains(bytes[offset]) else { throw error("Invalid number") }
            consumeDigits()
        }
        if take(46) {
            guard offset < bytes.count && (48...57).contains(bytes[offset]) else { throw error("Expected fraction digits") }
            consumeDigits()
        }
        if take(101) || take(69) {
            if !take(43) { _ = take(45) }
            guard offset < bytes.count && (48...57).contains(bytes[offset]) else { throw error("Expected exponent digits") }
            consumeDigits()
        }
        let text = String(bytes: bytes[start..<offset], encoding: .utf8)!
        guard let number = Double(text), number.isFinite else { throw error("Number is not finite") }
        return number
    }

    private mutating func consumeDigits() {
        while offset < bytes.count && (48...57).contains(bytes[offset]) { offset += 1 }
    }
}
