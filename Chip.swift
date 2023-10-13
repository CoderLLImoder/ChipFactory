
import Foundation

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        
        return Chip(chipType: chipType)
    }
    
    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
    }
}


struct Stack {
    private var items: [Chip] = []
    
    mutating func pop() -> Chip {
        return items.removeFirst()
    }
    
    mutating func push(_ element: Chip) {
        items.insert(element, at: 0)
    }
}

var nsCondition = NSCondition()
var isStackAvaliable = false
var stack = Stack()

class Generator: Thread {
    override func main() {
        nsCondition.lock()
        for _ in 0...10 {
            stack.push(Chip.make())
            wait(w_status: 2)
        }
        isStackAvaliable = true
        nsCondition.signal()
        nsCondition.unlock()
    }
}

class Executor: Thread {
    override func main() {
        for _ in 0...10 {
            nsCondition.lock()
            while !isStackAvaliable {
                nsCondition.wait()
            }
            var chip = stack.pop()
            chip.sodering()
            isStackAvaliable = true
            nsCondition.unlock()
        }
    }
}

var gen = Generator()
var exe = Executor()

gen.main()
exe.main()
