
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


class Stack {
    private var items = [Chip]()
    private let queue = DispatchQueue(label: "Queue", attributes: .concurrent)
    
    public lazy var hasValues = {
        return self.items.count > 0
    }
    
    func pop() -> Chip {
        var removedItem = Chip(chipType: .small)
        queue.sync{
            removedItem = self.items.removeFirst()
        }
        return removedItem
    }
    
    func push(_ element: Chip) {
        queue.async(flags: .barrier) {
            self.items.insert(element, at: 0)
        }
    }
}


var stack = Stack()
var isGeneratorActive = false

class Generator: Thread {

    override func main() {
        isGeneratorActive = true
        for _ in 1...10 {
            stack.push(Chip.make())
            Generator.sleep(forTimeInterval: 2)
        }
        isGeneratorActive = false
    }
}

class Executor: Thread {
    override func main() {
        while isGeneratorActive || stack.hasValues() {
            if stack.hasValues() {
                var chip = stack.pop()
                chip.sodering()
            }
        }
    }
}

final class StackManager {
    private let queue = DispatchQueue(label: "AppenderQueue", attributes: .concurrent)
    let semaphore = DispatchSemaphore(value: 2)
    var exe = Executor()
    var gen = Generator()
    
    func workWithStack() {
        queue.async { [self] in
            semaphore.wait()
            gen.main()
            semaphore.signal()
        }
        
        queue.async { [self] in
            semaphore.wait()
            exe.main()
            semaphore.signal()
        }
    }
}

var manager = StackManager()
manager.workWithStack()
