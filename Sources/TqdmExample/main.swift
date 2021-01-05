import Foundation
import Tqdm


// Simple argument check
if CommandLine.arguments.contains("-h") || CommandLine.arguments.contains("--help") {
    print("""
          Usage : TqdmExample [iter_count description ascii_or_utf smoothing_value]
          Argument        | Default    | Possible Values
          ----------------|------------|----------------
          iter_count      | 1000       | Any integer
          description     | swift-tqdm | Any string
          ascii_or_utf    | utf        | utf or ascii
          smoothing_value | 0.3        | Float in [0, 1]
          color           | green      | red, green, blue, magenta, cyan, yellow, white 
          """)
    exit(0)
}
let N = CommandLine.argc > 1 ? (Int(CommandLine.arguments[1]) ?? 1000) : 1000
let description = CommandLine.argc > 2 ? CommandLine.arguments[2] : "swift-tqdm"
let ascii = CommandLine.argc > 3 ? CommandLine.arguments[3] == "ascii" : false
let smoothing = CommandLine.argc > 4 ? Float(CommandLine.arguments[4]) ?? 0.3 : 0.3
let color = CommandLine.argc > 5 ? Tqdm.Color(name: CommandLine.arguments[5]) : Tqdm.Color.green


// Create a progress bar and manually update
let tqdm = Tqdm(description: description,
        total: N,
        ascii: ascii,
        smoothing: smoothing,
        color: color)
for _ in 0..<N {
    Thread.sleep(forTimeInterval: 0.005)
    tqdm.update()
}
tqdm.close()

// Wrap sequence and iterate
var sum = 0
for i in TqdmSequence(sequence: 0..<N, description: description, ascii: ascii, smoothing: smoothing, color: color) {
    sum += i
}
print("Sum of the sequence : \(sum)")
