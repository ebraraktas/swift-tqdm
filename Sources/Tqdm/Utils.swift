import Foundation

///Exponential moving average: smoothing to give progressively lower
/// weights to older values.
///
/// - Parameters:
///   - x: New value to include in EMA.
///   - mu: Previous EMA value.
///   - alpha: Smoothing factor in range [0, 1], (default: 0.3).
//            Increase to give more weight to recent values.
//            Ranges from 0 (yields `mu`) to 1 (yields `x`).
/// - Returns: Exponential moving average
func ema(x: Float, mu: Float? = nil, alpha: Float = 0.3) -> Float {
    if let mu = mu {
        return (alpha * x) + (1 - alpha) * mu
    } else {
        return x
    }
}

/// Formats a number (greater than unity) with SI Order of Magnitude
/// prefixes.
/// - Parameters:
///   - number: Number ( >= 1) to format.
///   - suffix: Post-postfix
///   - divisor: Divisor between prefixes
/// - Returns: Number with Order of Magnitude SI unit postfix.
func formatSizeof(number: Float, suffix: String = "", divisor: Float = 1000) -> String {
    var num = number
    for unit in ["", "k", "M", "G", "T", "P", "E", "Z"] {
        if abs(num) < 999.5 {
            if abs(num) < 99.95 {
                if abs(num) < 9.995 {
                    return "\(num, minLength: 1, fractionLength: 2)\(unit)\(suffix)"
                }
                return "\(num, minLength: 2, fractionLength: 1)\(unit)\(suffix)"
            }
            return "\(num, minLength: 3, fractionLength: 0)\(unit)\(suffix)"
        }
        num /= divisor
    }
    return "\(num, minLength: 3, fractionLength: 1)Y\(suffix)"
}


/// Formats a number of seconds as a clock time, [H:]MM:SS
///
/// - Parameter t: Time interval to format
/// - Returns: Formatted time string
func formatInterval(t: TimeInterval) -> String {
    let (minutes, s) = Int(t).quotientAndRemainder(dividingBy: 60)
    let (h, m) = minutes.quotientAndRemainder(dividingBy: 60)
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    } else {
        return String(format: "%02d:%02d", m, s)
    }
}
