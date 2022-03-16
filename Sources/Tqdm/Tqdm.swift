import Foundation

private let clearEntireLine = "\u{1B}[2K"
private let clearLine = "\u{1B}[K"
private let lineStart = "\u{1B}[G"
private let upperLine = "\u{1B}[1A"
private let colorReset = "\u{1B}[0m"
private let colorRgb = "\u{1b}[38;2;%d;%d;%dm"

/// Sequence wrapper to display `Tqdm` progress bar while iterating
public class TqdmSequence<S: Sequence>: Sequence, IteratorProtocol {
    private let tqdm: Tqdm
    // Skip update for the first iteration, see next()
    private var first: Bool
    private var iterator: S.Iterator

    /// TqdmSequence Wrapper to display `Tqdm` progress bar while iterating
    ///
    /// - Parameters:
    ///   - sequence: `Sequence` to be wrapped and iterated over
    ///   - description: Progress bar description before actual bar
    ///   - columnCount: Total column count of the output
    ///   - minInterval: Minimum progress display update interval (default: `0.1`) seconds.
    ///   - minIterations: Minimum progress display update interval, in iterations.
    ///   - ascii: If unspecified or False, use unicode (smooth blocks)
    ///     to fill the meter. The fallback is to use ASCII characters `" 123456789#"`
    ///   - unit: String that will be used to define the unit of each iteration (default: `"it"`)
    ///   - unitScale: If True, the number of iterations will be reduced/scaled
    ///            automatically and a metric prefix following the
    ///            International System of Units standard will be added
    ///            (kilo, mega, etc.) (default: `false`)
    ///   - smoothing: Exponential moving average smoothing factor for speed.
    ///   Ranges from 0 (average speed) to 1 (current/instantaneous speed) (default: `0.3`).
    ///   - initial: The initial counter value. Useful when restarting a progress bar (default: `0`)
    ///   - unitDivisor: (default: `1000`), ignored unless `unitScale` is `true`
    ///   - color: Output color. It colorizes whole output, not just the bar like the Python equivalent does.
    public init(sequence: S,
                description: String? = nil,
                columnCount: Int = 80,
                minInterval: Float = 0.1,
                minIterations: Int = 1,
                ascii: Bool = false,
                unit: String = "it",
                unitScale: Bool = false,
                smoothing: Float = 0.3,
                initial: Int = 0,
                unitDivisor: Float = 1000,
                color: Tqdm.Color? = nil) {
        tqdm = Tqdm(description: description,
                total: sequence.underestimatedCount,
                columnCount: columnCount,
                minInterval: minInterval,
                minIterations: minIterations,
                ascii: ascii,
                unit: unit,
                unitScale: unitScale,
                smoothing: smoothing,
                initial: initial,
                unitDivisor: unitDivisor,
                color: color)
        iterator = sequence.makeIterator()
        first = true
    }

    public func next() -> S.Element? {
        if let e = iterator.next() {
            if !first {
                // To calculate ETA accurately, we postpone progress bar update until next iteration call
                tqdm.update()
            }
            first = false
            return e
        } else {
            // After the last element iterated, update once the bar once
            tqdm.update()
            // Iteration is completed
            tqdm.close()
            return nil
        }
    }

    /// Set or update `description` of the `Tqdm` progress bar
    ///
    /// - Parameter description: New description text
    public func setDescription(description: String) {
        tqdm.setDescription(description: description)
    }
}

public class Tqdm {
    // TODO: Support nested bars (ebraraktas)
    public enum Color {
        case hex(String), red, green, blue, yellow, magenta, cyan, white

        public init?(name: String) {
            switch name {
            case "red": self = .red
            case "green": self = .green
            case "blue": self = .blue
            case "yellow": self = .yellow
            case "magenta": self = .magenta
            case "cyan": self = .cyan
            case "white": self = .white
            default : return nil
            }
        }

        func value() -> (r: UInt8, g: UInt8, b: UInt8)? {
            switch self {
            case .red: return (r: 0xff, g: 0x00, b: 0x00)
            case .green: return (r: 0x00, g: 0xff, b: 0x00)
            case .blue: return (r: 0x00, g: 0x00, b: 0xff)
            case .yellow: return (r: 0xff, g: 0xff, b: 0x00)
            case .magenta: return (r: 0xff, g: 0x00, b: 0xff)
            case .cyan: return (r: 0x00, g: 0xff, b: 0xff)
            case .white: return (r: 0xff, g: 0xff, b: 0xff)
            case .hex(let hexString):
                if hexString[hexString.startIndex] == "#" && hexString.count == 7 {
                    return (r: UInt8(hexString.substring(start: 1, end: 3), radix: 16) ?? 0xff,
                            g: UInt8(hexString.substring(start: 3, end: 5), radix: 16) ?? 0xff,
                            b: UInt8(hexString.substring(start: 5, end: 7), radix: 16) ?? 0xff)
                } else {
                    return nil
                }
            }
        }
    }

    private let startTime: Date
    private let total: Float?
    private let minInterval: Float
    private let minIterations: Float
    private let ascii: Bool
    private let unit: String
    private let unitScale: Bool
    private let smoothing: Float
    private let initial: Float
    private let unitDivisor: Float
    private let color: Color?

    private(set) var description: String = ""
    private var n: Float = 0
    private var lastPrintN: Float = 0
    private var lastPrintTime: Date
    private var avgTime: Float? = nil
    private let columnCount: Int
    private var closed: Bool = false

    /// Useful progress bar to print on terminal
    ///
    /// - Parameters:
    ///   - description: Progress bar description before actual bar
    ///   - total: The number of expected iterations. If unspecified only basic progress
    ///    statistics are displayed (no ETA, no progressbar).
    ///   - columnCount: Total column count of the output
    ///   - minInterval: Minimum progress display update interval (default: `0.1`) seconds.
    ///   - minIterations: Minimum progress display update interval, in iterations.
    ///   - ascii: If unspecified or False, use unicode (smooth blocks)
    ///     to fill the meter. The fallback is to use ASCII characters `" 123456789#"`
    ///   - unit: String that will be used to define the unit of each iteration (default: `"it"`)
    ///   - unitScale: If True, the number of iterations will be reduced/scaled
    ///            automatically and a metric prefix following the
    ///            International System of Units standard will be added
    ///            (kilo, mega, etc.) (default: `false`)
    ///   - smoothing: Exponential moving average smoothing factor for speed.
    ///   Ranges from 0 (average speed) to 1 (current/instantaneous speed) (default: `0.3`).
    ///   - initial: The initial counter value. Useful when restarting a progress bar (default: `0`)
    ///   - unitDivisor: (default: `1000`), ignored unless `unitScale` is `true`
    ///   - color: Output color. It colorizes whole output, not just the bar like the Python equivalent does.
    public init(description: String? = nil,
                total: Int? = nil,
                columnCount: Int = 80,
                minInterval: Float = 0.1,
                minIterations: Int = 1,
                ascii: Bool = false,
                unit: String = "it",
                unitScale: Bool = false,
                smoothing: Float = 0.3,
                initial: Int = 0,
                unitDivisor: Float = 1000,
                color: Color? = nil) {
        startTime = Date()
        lastPrintTime = startTime

        self.total = total == nil ? nil : Float(total!)
        self.columnCount = columnCount
        self.minInterval = minInterval
        self.minIterations = Float(minIterations)
        self.ascii = ascii
        self.unit = unit
        self.unitScale = unitScale
        self.smoothing = max(min(smoothing, 1.0), 0.0)
        self.initial = Float(initial)
        self.unitDivisor = unitDivisor
        self.color = color
        setDescription(description: description)
    }

    /// Set or update `description` of the `Tqdm` progress bar
    ///
    /// - Parameter description: New description text
    public func setDescription(description: String?) {
        // Sanitize description by trimming whitespace and trailing colon
        if let description = description?.trim() {
            self.description = description.replacingOccurrences(of: "\\s*:*\\s*$", with: "", options: .regularExpression)
        } else {
            self.description = ""
        }
    }

    /// Print a message without overlap with the bar.
    ///
    /// - Parameter message: Message string
    public func write(message: String) {
        // TODO : make this static (ebraraktas)
        if let colorValue = color?.value() {
            let colorString = String(format: colorRgb, colorValue.r, colorValue.g, colorValue.b)
            print("\(upperLine)\(clearLine)\(colorString)\(message)\(colorReset)\n")
        } else {
            print("\(upperLine)\(clearLine)\(message)\n")
        }
    }

    /// Manually update the progress bar
    ///
    /// - Parameter n: Increment to add to the internal counter of iterations (default: `1`)
    public func update(n: Int = 1) {
        if closed {
            return
        }
        if n < 0 {
            lastPrintN += Float(n) // for auto-display logic to work
        }
        self.n += Float(n)
        if (self.n - lastPrintN) >= minIterations {
            let deltaT = Date().timeIntervalSince(lastPrintTime)
            if deltaT >= Double(minInterval) {
                let deltaIt = self.n - lastPrintN
                let currentTime = Date()
                if smoothing > 0 && deltaT > 0 && deltaIt > 0 {
                    let rate = Float(deltaT) / deltaIt
                    avgTime = ema(x: rate, mu: avgTime, alpha: smoothing)
                }
                display()
                lastPrintN = self.n
                lastPrintTime = currentTime
            }
        }
    }


    /// Close progress bar
    public func close() {
        if !closed {
            display()
            closed = true
        }
    }

    /// Manually complete and close  the progress bar
    public func complete() {
        if self.total != nil {
            self.n = self.total!
        }
            close()
    }
    
    func display() {
        let meter = formatMeter()
        if let colorValue = color?.value() {
            let colorString = String(format: colorRgb, colorValue.r, colorValue.g, colorValue.b)
            print("\(lastPrintN > 0 ? upperLine : "")\(clearLine)\(colorString)\(meter)\(colorReset)")
        } else {
            print("\(lastPrintN > 0 ? upperLine : "")\(clearLine)\(meter)")
        }
    }

    func formatMeter() -> String {
        let total = self.total != nil && n >= (self.total! + 0.5) ? nil : self.total
        let elapsed = Float(Date().timeIntervalSince(startTime))
        let elapsedString = formatInterval(t: TimeInterval(elapsed))

        let rate: Float?
        let invRate: Float?
        if let avgTime = avgTime {
            rate = 1 / avgTime
            invRate = avgTime
        } else if elapsed > 0 {
            rate = (n - initial) / elapsed
            invRate = 1 / rate!
        } else {
            rate = nil
            invRate = nil
        }

        let rateString: String
        if let rate = rate {
            rateString = "\(unitScale ? formatSizeof(number: rate, divisor: unitDivisor) : "\(rate, minLength: 5, fractionLength: 2)")\(unit)/s"
        } else {
            rateString = "?\(unit)/s"
        }

        let invRateString: String
        if let invRate = invRate {
            invRateString = "\(unitScale ? formatSizeof(number: invRate, divisor: unitDivisor) : "\(invRate, minLength: 5, fractionLength: 2)")s/\(unit)"
        } else {
            invRateString = "?s/\(unit)"
        }

        let nString = unitScale ? formatSizeof(number: n, divisor: unitDivisor) : "\(n, fractionLength: 0)"

        let totalString: String
        if total != nil {
            totalString = unitScale ? formatSizeof(number: total!, divisor: unitDivisor) : "\(total!, fractionLength: 0)"
        } else {
            totalString = "?"
        }

        let remainingString: String
        if let rate = rate, let total = total {
            let remaining = TimeInterval((total - n) / rate)
            remainingString = formatInterval(t: remaining)
        } else {
            remainingString = "?"
        }

        var leftBar = description.count > 0 ? "\(description): " : ""
        let rightBar = "| \(nString)/\(totalString) [\(elapsedString)<\(remainingString), \((rate ?? 0) > 1 ? rateString : invRateString)]"

        let meter: String
        if let total = total {
            let frac = n / total
            let percentage = frac * 100
            let noBarCount = rightBar.count + leftBar.count
            let bar = Bar(frac: frac,
                    length: Swift.max(1, columnCount - noBarCount),
                    charsetType: ascii ? .ascii : .utf).format()
            leftBar += "\(percentage, minLength: 3, fractionLength: 0)%|"
            meter = "\(leftBar)\(bar)\(rightBar)"
        } else {
            meter = "\(leftBar)\(rightBar)"
        }
        return meter
    }
}

