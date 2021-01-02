import Foundation

class Bar {
    // Length of the bar
    private let length: Int

    // Charset to be used
    private let charset: Charset

    // Completion fraction in [0, 1]
    private let frac: Float

    init(frac: Float, length: Int = 10, charsetType: CharsetType = .utf) {
        self.frac = frac
        self.length = length
        self.charset = charsetType == .utf ? utfCharset : asciiCharset
    }

    func format() -> String {
        let symbols = self.charset.symbols
        let (barLength, fracBarLength) = Int(frac * Float(length * charset.symbolCount)).quotientAndRemainder(dividingBy: charset.symbolCount)

        let res = String(repeating: symbols[symbols.index(before: symbols.endIndex)], count: barLength)
        if barLength < self.length {
            let fracBar = String(symbols[symbols.index(symbols.startIndex, offsetBy: fracBarLength)])
            let offset = String(repeating: String(symbols[symbols.startIndex]), count: self.length - 1 - barLength)
            return res + fracBar + offset
        } else {
            return res
        }
    }
}