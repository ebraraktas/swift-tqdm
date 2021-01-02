import Foundation

let asciiCharset = Charset(type: .ascii)
let utfCharset = Charset(type: .utf)

enum CharsetType {
    case utf, ascii
}

class Charset {
    private let type: CharsetType
    public let symbols:String
    public let symbolCount: Int
    init(type: CharsetType) {
        self.type = type
        switch self.type {
        case .ascii:
            symbols = " 123456789#"
        case .utf:
            symbols = " " + stride(from: UInt32(0x258F), to: UInt32(0x2587), by: -1).map {
                String(Unicode.Scalar($0)!)
            }.joined(separator: "")
        }
        symbolCount = symbols.count
    }
}