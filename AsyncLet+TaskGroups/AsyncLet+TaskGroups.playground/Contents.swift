import Foundation
public var pgStartD = Date()

func resetParams() {
    print("\n")
    pgStartD = Date()
}

/**
 The function below executes 2 async pieces of work. Each computation does some work and
 returns an integer value. It has the following benefits compared to traditionaly GCD/Operations.
 
 (1) No more missing completion handlers
 (2) In build error propagation with try/throws
 (3) top to bottom stuctured flow of the program.
 
 Drawback: The 2 pieces of work are independent of each other and therefore can be done in parallel, but here
 they are called one after the other. The total execution time can be improved.
 */
func computationWithoutAsyncLet(executionStart: Date) async throws -> (Int,Int) {
    let firstComputation = try await multipleComputationsAsync(computations: 4,
                                                               startDate: executionStart, tag: "A")
    let secondComputation = try await multipleComputationsAsync(computations: 4,
                                                                startDate: executionStart, tag: "B")
    return (firstComputation,secondComputation)
}
func runComputationWithoutAsyncLet() async {
        do {
            printWithThreadInfo(tag: "begin No Async Let", executionStart: pgStartD)
            let result = try await computationWithoutAsyncLet(executionStart: pgStartD)
            printWithThreadInfo(tag: "end No Async Let, result: \(result.0) + \(result.1)",
                                executionStart: pgStartD)
        } catch {
            printWithThreadInfo(tag: "computationWithoutAsyncLet has error", executionStart: pgStartD)
        }
}
/**
 Structured concurrency using async-let
 
 Async-let allows us to achieve parallel execution. Here we annotated the firstComputation and secondComputation with the async-let keyword, no await keyword so the program flow will continue to call the 2nd multipleComputationsAsync. At the end where we are waiting for the result from the async tasks, we will pause until results from 1st call and 2nd calls are received or any of them raises an exception as indicated by the try keyword.

 key points:
 (1) The right side of the = in the async let statement is executed in a child task while the parent task continues. Child task runs immediately.
 (2) When the constant on the left side is evaluated (on the child task completion) , its value can be accessed
 by the parent task after the await statement.
 (3) The async-let or concurrent binding has to use Let keyword instead of Var, because a constant cannot
 be over-written later on.

 */
func computationWithAsyncLet(executionStart: Date) async throws -> (Int,Int) {
    async let firstComputation = multipleComputationsAsync(computations: 4,
                                                               startDate: executionStart, tag: "C")
    async let secondComputation = multipleComputationsAsync(computations: 4,
                                                                startDate: executionStart, tag: "D")
    return try await (firstComputation,secondComputation)
}
func runComputationWithAsyncLet() async {
        do {
            printWithThreadInfo(tag: "begin Async Let", executionStart: pgStartD)
            let result = try await computationWithAsyncLet(executionStart: pgStartD)
            printWithThreadInfo(tag: "end Async Let, result: \(result.0) + \(result.1)",
                                executionStart: pgStartD)
        } catch {
            printWithThreadInfo(tag: "computationWithAsyncLet has error", executionStart: pgStartD)
        }
}

/**
 Cooperative Cancellation
 
The concept of parent and child task relationship is important in modern swift concurrency.

(1) Many properties of the Parent Task like task priorities are propagated to the child.
(2) A parent task can only finish if all its child tasks are finished
(3) If one of the child task errors,
 
 
 */
func computationWithAsyncLet_Errors_No_Cancel_Check(executionStart: Date) async throws -> (Int,Int) {
    async let firstComputation = multipleComputationsAsync(computations: 4,
                                                               startDate: executionStart, tag: "E")
    async let secondComputation = multipleComputationsAsync_errors(computations: 4,
                                                                startDate: executionStart, tag: "F")
    return try await (firstComputation,secondComputation)
}
func runComputationWithAsyncLet_Errors_No_Cancel_Check() async {
        do {
            printWithThreadInfo(tag: "begin Async Let", executionStart: pgStartD)
            let result = try await computationWithAsyncLet_Errors_No_Cancel_Check(executionStart: pgStartD)
            printWithThreadInfo(tag: "end Async Let, result: \(result.0) + \(result.1)",
                                executionStart: pgStartD)
        } catch {
            printWithThreadInfo(tag: "runComputationWithAsyncLet_Errors_No_Cancel_Check has error: \(error)",
                                executionStart: pgStartD)
        }
}

func computationWithAsyncLet_errors_cancel_check(executionStart: Date) async throws -> (Int,Int) {
    async let firstComputation = multipleComputationsAsync_checks_task_cancellation(computations: 4,
                                                               startDate: executionStart, tag: "G")
    async let secondComputation = multipleComputationsAsync_errors(computations: 4,
                                                                startDate: executionStart, tag: "H")
    let poo = try await firstComputation + secondComputation
    return (0,0)
}
func runComputationWithAsyncLet_errors_cancel_check() async {
    do {
        printWithThreadInfo(tag: "begin Async Let", executionStart: pgStartD)
        let result = try await computationWithAsyncLet_errors_cancel_check(executionStart: pgStartD)
        printWithThreadInfo(tag: "end Async Let, result: \(result.0) + \(result.1)",
                            executionStart: pgStartD)
    } catch {
        printWithThreadInfo(tag: "runComputationWithAsyncLet_errors_cancel_check has error: \(error)",
                            executionStart: pgStartD)
    }
}


Task { @MainActor in
    printWithThreadInfo(tag: "all computations started", executionStart: pgStartD)
    await runComputationWithoutAsyncLet()
    resetParams()
    await runComputationWithAsyncLet()
    resetParams()
    await runComputationWithAsyncLet_Errors_No_Cancel_Check()
    resetParams()
    await runComputationWithAsyncLet_errors_cancel_check()
    printWithThreadInfo(tag: "all computations ended", executionStart: pgStartD)
}



