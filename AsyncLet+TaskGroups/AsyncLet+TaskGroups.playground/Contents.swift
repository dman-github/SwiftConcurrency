import Foundation
public var pgStartD = Date()

func resetParams() {
    print("\n")
    pgStartD = Date()
}

/** 1
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
/** 2
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

/** 3
 Cooperative Cancellation
 
The concept of parent and child task relationship is important in modern swift concurrency.

(1) Many properties of the Parent Task like task priorities are propagated to the child.
(2) A parent task can only finish if all its child tasks are finished/fail
(3) If one of the child task errors, then the error gets propagated to the parent which is awaiting on it.
    But before the parent can throw the error  it must wait for the other tasks to complete. The parent sets
    the cacellation flag of all its child tasks and waits for them to complete. Therefore it is important to check
    this cancellation flag on all child tasks and finish gracefully.
(4) The order that async let variables are awaited by the parent is important as shown in the next
    2 examples.
 
 Note: Some async tasks under Foundation like Task.Sleep automatically complete when its Task is cancelled.
 
 */
func computationWithAsyncLet_errors1(executionStart: Date) async throws -> (Int,Int) {
    async let firstComputation = multipleComputationsAsync(computations: 4,
                                                               startDate: executionStart, tag: "E")
    async let secondComputation = multipleComputationsAsync_errors(computations: 4,
                                                                startDate: executionStart, tag: "F")
    /*
     Here await (secondComputation,firstComputation) means the parent task awaits its child task in that order.
     we can also write this as
     
      try await secondComputation
      try await firstComputation
     
    The order is important here because when the task (secondComputation) throws the error, the parent task receives the error and cancels all the other tasks.
    As cooperative cancellation is in place the task (firstComputation) will finish. An finally the parent task will throw the error.
    In this example the parent task will throw the error as soon as the task(secondComputation) throws the error.
     
     The opposite scenario is seen in the next example.
     */
    return try await (secondComputation,firstComputation)
}
func runComputationWithAsyncLet_errors1() async {
        do {
            printWithThreadInfo(tag: "begin Async Let Error", executionStart: pgStartD)
            let result = try await computationWithAsyncLet_errors1(executionStart: pgStartD)
            printWithThreadInfo(tag: "end Async Let Errors, result: \(result.0) + \(result.1)",
                                executionStart: pgStartD)
        } catch {
            printWithThreadInfo(tag: "runComputationWithAsyncLet_errors has error: \(error)",
                                executionStart: pgStartD)
        }
}

/* 4
 Now await (firstComputation,secondComputation) in this case when the secondComputation throws the error. The parent task does not
 receive it because it is awaiting the completion of task (firstComputation) which carries on for 4 computations. Only after this does the parent await the task (secondComputation) and receive the error.
 In this example the parent task will throw the error only after the task (firstComputation) completes.
 */
func computationWithAsyncLet_errors2(executionStart: Date) async throws -> (Int,Int) {
    async let firstComputation = multipleComputationsAsync_checks_task_cancellation(computations: 4,
                                                               startDate: executionStart, tag: "G")
    async let secondComputation = multipleComputationsAsync_errors(computations: 4,
                                                                startDate: executionStart, tag: "H")
    return try await (firstComputation,secondComputation)
}
func runComputationWithAsyncLet_errors2() async {
    do {
        printWithThreadInfo(tag: "begin Async Let Errors 2", executionStart: pgStartD)
        let result = try await computationWithAsyncLet_errors2(executionStart: pgStartD)
        printWithThreadInfo(tag: "end Async Let Errors 2, result: \(result.0) + \(result.1)",
                            executionStart: pgStartD)
    } catch {
        printWithThreadInfo(tag: "computationWithAsyncLet_errors2 has error: \(error)",
                            executionStart: pgStartD)
    }
}


Task { @MainActor in
    printWithThreadInfo(tag: "all computations started", executionStart: pgStartD)
    await runComputationWithoutAsyncLet()
    resetParams()
    await runComputationWithAsyncLet()
    resetParams()
    await runComputationWithAsyncLet_errors1()
    resetParams()
    await runComputationWithAsyncLet_errors2()
    printWithThreadInfo(tag: "all computations ended", executionStart: pgStartD)
}



