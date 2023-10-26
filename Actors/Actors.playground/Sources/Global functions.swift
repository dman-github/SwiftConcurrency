
import Foundation


enum ComputationError: Error {
    
    case halfComputationsError
    case TaskCancelled
}


extension Task where Success == Never, Failure == Never  {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1000000000)
        try await Task.sleep(nanoseconds: duration)
    }
}

/**
    Thread information is output with a tag and the time in ms from a start date
 */
public func printWithThreadInfo(tag: String) {
    print("Thread:\(Thread.current)","tag:\(tag)",
          "isMain:\(Thread.isMainThread)",
          separator: "\t")
}
