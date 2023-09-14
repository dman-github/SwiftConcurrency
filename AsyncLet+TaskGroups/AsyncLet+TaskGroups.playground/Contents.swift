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
 
 Note: Some async tasks under Foundation like Task.Sleep automatically complete when its Task is cancelled.
 
 (4) The order that async let variables are awaited by the parent is important.
 In the example (computationWithAsyncLet_errors2) the Computations from G are cancelled after it throws an error. But the parent task will only throw the error after computation H has finished. This is due to the order that the variables are awaited.
 
 output of computationWithAsyncLet_errors1
 Thread:<NSThread: 0x6000034830c0>{number = 2, name = (null)}    tag:begin Async Let Error    isMain:false    0.6540 ms
 Thread:<NSThread: 0x6000034830c0>{number = 2, name = (null)}    tag:Computation started for E    isMain:false    0.9470 ms
 Thread:<NSThread: 0x6000034830c0>{number = 2, name = (null)}    tag:Computation started for F    isMain:false    1.1641 ms
 Thread:<NSThread: 0x6000034a5800>{number = 4, name = (null)}    tag:Computation 1 done for F    isMain:false    274.5820 ms
 Thread:<NSThread: 0x6000034a5800>{number = 4, name = (null)}    tag:Computation throwing Error for F     isMain:false    274.7511 ms
 Thread:<NSThread: 0x6000034830c0>{number = 2, name = (null)}    tag:Computation 1 done for E    isMain:false    274.8450 ms
 Thread:<NSThread: 0x6000034a5800>{number = 4, name = (null)}    tag:runComputationWithAsyncLet_errors has error: halfComputationsError    isMain:false    275.4480 ms
 
 output of computationWithAsyncLet_errors2
 Thread:<NSThread: 0x6000005e8640>{number = 6, name = (null)}    tag:begin Async Let Errors 2    isMain:false    0.2090 ms
 Thread:<NSThread: 0x6000005e8640>{number = 6, name = (null)}    tag:Computation started for G    isMain:false    0.5790 ms
 Thread:<NSThread: 0x6000005e8640>{number = 6, name = (null)}    tag:Computation started for H    isMain:false    0.9090 ms
 Thread:<NSThread: 0x6000005e8640>{number = 6, name = (null)}    tag:Computation 1 done for G cancelfalse    isMain:false    254.6550 ms
 Thread:<NSThread: 0x6000005e8980>{number = 4, name = (null)}    tag:Computation 1 done for H    isMain:false    254.8840 ms
 Thread:<NSThread: 0x6000005e8980>{number = 4, name = (null)}    tag:Computation throwing Error for H     isMain:false    254.9690 ms
 Thread:<NSThread: 0x6000005e8980>{number = 4, name = (null)}    tag:Computation 2 done for G cancelfalse    isMain:false    511.8580 ms
 Thread:<NSThread: 0x6000005efc80>{number = 2, name = (null)}    tag:Computation 3 done for G cancelfalse    isMain:false    781.9480 ms
 Thread:<NSThread: 0x6000005e8980>{number = 4, name = (null)}    tag:Computation 4 done for G cancelfalse    isMain:false    1055.5700 ms
 Thread:<NSThread: 0x6000005e8980>{number = 4, name = (null)}    tag:Computation ended for G    isMain:false    1055.7990 ms
 Thread:<NSThread: 0x6000005e8980>{number = 4, name = (null)}    tag:computationWithAsyncLet_errors2 has error: halfComputationsError    isMain:false    1055.9260 ms
 
 
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
 See await (firstComputation,secondComputation), in this case when the secondComputation throws the error. The parent task does not
 receive it because it is awaiting the completion of task (firstComputation) which carries on for 4 computations. Only after this is done does the parent await the task (secondComputation) and receive the error.
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

/* 5
 To avoid the drawback relating to the parent task awaiting child tasks in the order that they appear in the code,
 we need to use TaskGroup. Where an error from one of the Tasks will cancel all the others.
 
 Output below where there is no error
 
 Thread:<NSThread: 0x600003b42ac0>{number = 4, name = (null)}    tag:begin Async Group     isMain:false    0.2340 ms
 Thread:<NSThread: 0x600003b41080>{number = 5, name = (null)}    tag:Computation started for I    isMain:false    1.5100 ms
 Thread:<NSThread: 0x600003b41080>{number = 5, name = (null)}    tag:Computation started for J    isMain:false    2.5860 ms
 Thread:<NSThread: 0x600003b770c0>{number = 2, name = (null)}    tag:Computation 1 done for J cancelfalse    isMain:false    268.5840 ms
 Thread:<NSThread: 0x600003b41080>{number = 5, name = (null)}    tag:Computation 1 done for I cancelfalse    isMain:false    268.5760 ms
 Thread:<NSThread: 0x600003b41080>{number = 5, name = (null)}    tag:Computation ended for I    isMain:false    268.8470 ms
 Thread:<NSThread: 0x600003b41080>{number = 5, name = (null)}    tag:Task complete, appending result: 52    isMain:false    269.1201 ms
 Thread:<NSThread: 0x600003b48200>{number = 6, name = (null)}    tag:Computation 2 done for J cancelfalse    isMain:false    528.0170 ms
 Thread:<NSThread: 0x600003b41080>{number = 5, name = (null)}    tag:Computation 3 done for J cancelfalse    isMain:false    780.1400 ms
 Thread:<NSThread: 0x600003b48200>{number = 6, name = (null)}    tag:Computation 4 done for J cancelfalse    isMain:false    1055.1060 ms
 Thread:<NSThread: 0x600003b48200>{number = 6, name = (null)}    tag:Computation ended for J    isMain:false    1055.3100 ms
 Thread:<NSThread: 0x600003b48200>{number = 6, name = (null)}    tag:Task complete, appending result: 21    isMain:false    1055.8461 ms
 Thread:<NSThread: 0x600003b48200>{number = 6, name = (null)}    tag:end Async Group, result: 52 + 21    isMain:false    1057.9160 ms
 Thread:<_NSMainThread: 0x600003b68400>{number = 1, name = main}    tag:all computations ended    isMain:true    1058.1211 ms

 (1) The 2nd task completes first and the result is stored in the array, no need for all the tasks to complete
 (2) All tasks in the TaskGroup run concurrently.
 
 */
func computationWithTaskgroup(executionStart: Date) async throws -> (Int,Int) {
    let result: [Int] = try await withThrowingTaskGroup(of: Int.self, body: { group in
        group.addTask { try await multipleComputationsAsync_checks_task_cancellation(computations: 4,
                                                                                     startDate: executionStart, tag: "I")}
        group.addTask { try await multipleComputationsAsync_checks_task_cancellation(computations: 1,
                                                                                     startDate: executionStart, tag: "J")}
        
        /* The Taskgroup is awaited, as it conforms to AsyncSequence we can reduce the results into an array */
        return try await group.reduce(into: [], { results, taskResult in
            printWithThreadInfo(tag: "Task complete, appending result: \(taskResult)", executionStart: pgStartD)
            results.append(taskResult)
        })
    })
    return (result[0], result[1])
}
func runComputationWithTaskGroup() async {
    do {
        printWithThreadInfo(tag: "begin Async Group ", executionStart: pgStartD)
        let result = try await computationWithTaskgroup(executionStart: pgStartD)
        printWithThreadInfo(tag: "end Async Group, result: \(result.0) + \(result.1)",
                            executionStart: pgStartD)
    } catch {
        printWithThreadInfo(tag: "runComputationWithTaskGroup has error: \(error)",
                            executionStart: pgStartD)
    }
}


/**
 When any task errors the taskGroup will cancel all the other tasks and throw the error
 
 Thread:<NSThread: 0x6000028a50c0>{number = 5, name = (null)}    tag:begin Async Group     isMain:false    0.2811 ms
 Thread:<NSThread: 0x600002889640>{number = 4, name = (null)}    tag:Computation started for I    isMain:false    1.1201 ms
 Thread:<NSThread: 0x6000028a50c0>{number = 5, name = (null)}    tag:Computation started for J    isMain:false    1.2381 ms
 Thread:<NSThread: 0x6000028874c0>{number = 2, name = (null)}    tag:Computation 1 done for I    isMain:false    276.2361 ms
 Thread:<NSThread: 0x6000028893c0>{number = 6, name = (null)}    tag:Computation 1 done for J    isMain:false    276.2361 ms
 Thread:<NSThread: 0x6000028893c0>{number = 6, name = (null)}    tag:Computation throwing Error for J     isMain:false    276.4990 ms
 Thread:<NSThread: 0x6000028874c0>{number = 2, name = (null)}    tag:runComputationWithTaskGroup has error: halfComputationsError    isMain:false    276.7920 ms
 Thread:<_NSMainThread: 0x6000028a0040>{number = 1, name = main}    tag:all computations ended    isMain:true    276.9721 ms
 
 */

func computationWithTaskgroup_errors(executionStart: Date) async throws -> (Int,Int) {
    let result: [Int] = try await withThrowingTaskGroup(of: Int.self, body: { group in
        group.addTask { try await multipleComputationsAsync_checks_task_cancellation(computations: 4,
                                                                                     startDate: executionStart, tag: "I")}
        group.addTask { try await multipleComputationsAsync_errors(computations: 4,
                                                                                     startDate: executionStart, tag: "J")}
        
        /* The Taskgroup is awaited, as it conforms to AsyncSequence we can reduce the results into an array */
        return try await group.reduce(into: [], { results, taskResult in
            printWithThreadInfo(tag: "Task complete, appending result: \(taskResult)", executionStart: pgStartD)
            results.append(taskResult)
        })
    })
    return (result[0], result[1])
}
func runComputationWithTaskGroup_errors() async {
    do {
        printWithThreadInfo(tag: "begin Async Group errors ", executionStart: pgStartD)
        let result = try await computationWithTaskgroup_errors(executionStart: pgStartD)
        printWithThreadInfo(tag: "end Async Group errors, result: \(result.0) + \(result.1)",
                            executionStart: pgStartD)
    } catch {
        printWithThreadInfo(tag: "runComputationWithTaskGroup has error: \(error)",
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
    resetParams()
    await runComputationWithTaskGroup()
    resetParams()
    await runComputationWithTaskGroup_errors()
    printWithThreadInfo(tag: "all computations ended", executionStart: pgStartD)
}



