# Swift Concurrency Playground

This repository contains Swift playgrounds to explore and understand the new concurrency concepts introduced in Swift. It includes examples of Async/Await, AsyncLet, TaskGroups, and Actors. 

## AsyncLet + TaskGroups Playground

### Example 1

Execute 2 asynchronous pieces of work using the Async/Await pattern to showcase the advantages compared to traditional GCD/Operations.

### Example 2

Work that can be done in parallel can use the async let pattern. It is important to note that even though the work is done in parallel, the individual child tasks are awaited in sequence.

### Example 3

Cooperative cancellation. When the 1st child task ends with an error, the parent task will cancel all other child tasks and then throw the error.

### Example 4

Cooperative cancellation. When the 2nd child task ends with an error, the parent task will not cancel the other tasks because it is still awaiting the 1st child task to complete.

### Example 5

Use TaskGroups to avoid the drawback of the async let pattern where parent tasks await child tasks in the order that they appear in code. An error from one of the tasks can set all other tasks to the cancel state and throw the error.

## Actors Playground

### Example 1

Actors are reference types like classes but do not support inheritance.

### Example 2

Actors prevent data races by creating synchronized access to their isolated data.

### Example 3

Actor race conditions can still occur if used incorrectly, e.g., having 2 points of suspension in common code is not good.

### Example 4

Use of the `nonisolated` keyword to tell the compiler that a method is not accessing mutable state.

### Example 5

Main Actor. A Task created from a function having `@MainActor` will also inherit the main actor context. A detached task will not.

Feel free to explore the playgrounds in this repository to better understand Swift's concurrency features.

[![Open in Swift Playgrounds](https://img.shields.io/badge/Open%20in-Swift%20Playgrounds-blue?style=for-the-badge&logo=swift)](swift://https://example.com)

---

**Note:** Make sure to open these playgrounds in a Swift-compatible environment to run and explore the code effectively.
