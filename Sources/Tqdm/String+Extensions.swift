import Foundation

extension String {
    func trim() -> String {
        trimmingCharacters(in: .whitespaces)
    }

    func substring(start: Int?=nil, end: Int?=nil) -> String{
        let start = (start ?? 0) % count
        let end = (end ?? 0) >= count ? count : (end ?? 0) % count
        let startIndex = self.index(self.startIndex, offsetBy: start)
        let endIndex = self.index(self.startIndex, offsetBy: end)
        return String(self[startIndex..<endIndex])
    }

    /// Returns a new string formed from the String by prepending as many
    /// occurrences as necessary of a given pad string. If the string is
    /// long enough already, returns itself.
    ///
    /// - Parameters:
    ///   - toLength: The new length for the receiver.
    ///   - withPad: The string with which to extend the receiver.
    ///   - startIndex: The index in padString from which to start padding.
    /// - Returns: Padded String
    func leftPadding(toLength: Int, withPad: String = " ", startIndex: Int = 0) -> String {
        let padCount = toLength - self.count
        if padCount <= 0 {
            return self
        }
        let (repeatCount, subpaddingCount) = padCount.quotientAndRemainder(dividingBy: withPad.count)
        let subpadding: String
        if subpaddingCount > 0 {
            let dummyCycle = withPad + withPad
            let start = dummyCycle.index(dummyCycle.startIndex, offsetBy: startIndex)
            let end = dummyCycle.index(start, offsetBy: subpaddingCount)
            subpadding = String(dummyCycle[start..<end])
        } else {
            subpadding = ""
        }
        let padding = "\(String(repeating: withPad, count: repeatCount))\(subpadding)"
        return "\(padding)\(self)"
    }
}

extension String.StringInterpolation {
    /// Interpolate String with Float by specifying formatting in detail.
    ///
    /// - Example:
    /// Example behavior is like below:
    /// ```
    /// print("\(1.234, minLength: 6, fractionLength: 2, padding: "_")")
    /// // prints "__1.23"
    /// ```
    ///
    /// If you are familiar with Python fstrings, this is equivalent to
    /// snippet below:
    /// ```python
    /// f'{value:{padding}>{minLength}.{fractionLength}f}'
    /// ```
    ///
    ///
    /// - Parameters:
    ///   - value: `Float` value
    ///   - minLength: Minimum length of the formatted value
    ///   - fractionLength: Number of digits in fraction
    ///   - padding: Padding `Character`
    mutating func appendInterpolation(_ value: Float,
                                      minLength: Int = 0,
                                      fractionLength: Int = Int.max,
                                      padding: Character = " ") {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        let formatValue: NSNumber = value as NSNumber
        formatter.minimumFractionDigits = fractionLength
        formatter.maximumFractionDigits = fractionLength
        if let result = formatter.string(from: formatValue) {
            appendLiteral(result.leftPadding(toLength: minLength, withPad: String(padding)))
        }
    }
}
