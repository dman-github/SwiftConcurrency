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
public func printWithThreadInfo(tag: String, executionStart: Date) {
    let diff = abs(Date().distance(to: executionStart))
    print("Thread:\(Thread.current)","tag:\(tag)",
          "isMain:\(Thread.isMainThread)",
          "\(String(format: "%.4f",diff*1000)) ms",
          separator: "\t")
}


public func multipleComputationsAsync(computations num: Int, startDate: Date, tag: String) async throws -> Int {
    printWithThreadInfo(tag: "Computation started for \(tag)", executionStart: startDate)
    for i in 1...num {
        try await Task.sleep(seconds: 0.25)
        printWithThreadInfo(tag: "Computation \(i) done for \(tag)", executionStart: startDate)
    }
    printWithThreadInfo(tag: "Computation ended for \(tag)", executionStart: startDate)
    return Int.random(in: 0..<100)
}

public func multipleComputationsAsync_checks_task_cancellation(computations num: Int,
                                                              startDate: Date, tag: String) async throws -> Int {
    printWithThreadInfo(tag: "Computation started for \(tag)", executionStart: startDate)
    for i in 1...num {
        try Task.checkCancellation() // Not necessary because Task.sleep will automatically check Task status
        try await Task.sleep(seconds: 0.25)
        try Task.checkCancellation()  // Not necessary because Task.sleep will automatically check Task status
        printWithThreadInfo(tag: "Computation \(i) done for \(tag) cancel\(Task.isCancelled)", executionStart: startDate)
    }
    printWithThreadInfo(tag: "Computation ended for \(tag)", executionStart: startDate)
    return Int.random(in: 0..<100)
}

/* Function errors after half the computations */
public func multipleComputationsAsync_errors(computations num: Int,
                                                      startDate: Date,
                                                      tag: String) async throws -> Int {
    printWithThreadInfo(tag: "Computation started for \(tag)", executionStart: startDate)
    for i in 1...num {
        if i == (num+1)/2 {
            printWithThreadInfo(tag: "Computation throwing Error for \(tag) ", executionStart: startDate)
            throw ComputationError.halfComputationsError
        } else {
            try await Task.sleep(seconds: 0.25)
            printWithThreadInfo(tag: "Computation \(i) done for \(tag)", executionStart: startDate)
        }
    }
    printWithThreadInfo(tag: "Computation ended for \(tag)", executionStart: startDate)
    return Int.random(in: 0..<100)
}
