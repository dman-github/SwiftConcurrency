import Foundation

/*
 Protect mutable state with Swift actors.
 Data race occur when multiple threads read the same location of memory without synchronisation and at least one of them is a write.
 Actors protect their state from data races by synchronising thread access to it data.
 Not only this but by using actors we can get feedback from the compiler in order to write thread-safe code and to avoid the actor limitations.
 
 Below are the important features and limitations
*/

/* 1
 Actors are reference types like classes but do not support inheritance
 */

actor Vehicle {
    var maxSpeed: Int = 100
    var color: String = "Black"
}

/*class Car: Vehicle {
 /* Error actor types do not support inheritance*/
}*/

/* 2
 Actors prevent data races by creating synchronized access to its isolated data.
 */

actor Kitchen {
    @TaskLocal static var id = ""  // Used to track which task is the parent as they are all running concurrently
    var numberOrdersBeingPrepared: Int = 0 {
        didSet{
            printWithThreadInfo(tag: "Actor method read numberOrdersBeingPrepared old:\(oldValue) new:\(numberOrdersBeingPrepared) ")
        }
    }
    let type = "Asian"
    
    func aMealStartsPreparing() {
        numberOrdersBeingPrepared += 1
        printWithThreadInfo(tag: "Actor method aMealStartsPreparing for Task :\(Kitchen.id)")
        
    }
    
    func aMealStopsPreparing() {
        numberOrdersBeingPrepared += 1
        printWithThreadInfo(tag: "Actor method aMealStopsPreparing for Task :\(Kitchen.id)")
    }
    
    func aMealStartsPreparingSafe() {
        numberOrdersBeingPrepared += 1
        printWithThreadInfo(tag: "Actor method aMealStartsPreparingSafe for Task :\(Kitchen.id)")
        howManyMealsAreBeingPreparing()
        
    }
    
    func aMealStopsPreparingSafe() {
        numberOrdersBeingPrepared += 1
        printWithThreadInfo(tag: "Actor method aMealStopsPreparingSafe for Task :\(Kitchen.id)")
        howManyMealsAreBeingPreparing()
    }
    
    func howManyMealsAreBeingPreparing() {
        print(numberOrdersBeingPrepared)
    }
    
    func printWhatTypeOfCuisine() {
        print("This kitchen makes \(type) for Task :\(Kitchen.id)")
    }
    
    nonisolated func printWhatTypeOfCuisineNonIsolated() {
        print("This kitchen makes \(type) for Task :\(Kitchen.id)")
    }
}

func actorExample() async {
    let myKitchen = Kitchen()
    /* myKitchen.aMealStartsPreparing() */           // Cannot call mutable properties directly, compiler will help us with an error message.
    /* print(myKitchen.numberOrdersBeingPrepared) */ // Cannot read a mutable variable as it is unsafe in a concurrent space, compiler again helps us with an error message
    print(myKitchen.type)                            // Can read the const type as this is immutable and safe
    
    /* We must have syncronised access */
    await myKitchen.aMealStartsPreparing()
    print(await myKitchen.numberOrdersBeingPrepared)
}

/* 3
 Actor race conditions can still occur if used incorrectly
 
 Result :
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method read numberOrdersBeingPrepared old:0 new:1     isMain:false
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method aMealStartsPreparing for Task :1st    isMain:false
 Task 1st reading 1
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method read numberOrdersBeingPrepared old:1 new:2     isMain:false
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method aMealStartsPreparing for Task :2nd    isMain:false
 Task 2nd reading 2
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method read numberOrdersBeingPrepared old:2 new:3     isMain:false
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method aMealStartsPreparing for Task :3rd    isMain:false
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method read numberOrdersBeingPrepared old:3 new:4     isMain:false
 Thread:<NSThread: 0x600002922000>{number = 3, name = (null)}    tag:Actor method aMealStartsPreparing for Task :4th    isMain:false
 Task 3rd reading 4
 Task 4th reading 4
 
 Here there are 4 tasks concurrently trying to call aMealStartsPreparing. They can do this safely without exceptions because the actor allows sync access.
 However during the first await myKitchen.aMealStartsPreparing() the task suspends, and by the time the task resumes and reads
 await myKitchen.numberOrdersBeingPrepared,  aMealStartsPreparing has been called 4 times
 
 Conclusion: Having 2 points of suspension among COMMON code is not good.
 Better approach: Move the reading to inside the actor method, gets rid of 1 await suspension point
 Note: This result is not reproducible all the time it depends on what threads the OS uses

 */
func actorExampleRaceCondition() async  {
    let myKitchen = Kitchen()
    async let t1 = Task {
        await Kitchen.$id.withValue("1st") {
            await myKitchen.aMealStartsPreparing()
            print("Task \(Kitchen.id) reading \(await myKitchen.numberOrdersBeingPrepared)")
        }
    }
    
    async let t2 = Task {
        await Kitchen.$id.withValue("2nd") {
            await myKitchen.aMealStartsPreparing()
            print("Task \(Kitchen.id) reading \(await myKitchen.numberOrdersBeingPrepared)")
        }
    }
    
    async let t3 = Task {
        await Kitchen.$id.withValue("3rd") {
            await myKitchen.aMealStartsPreparing()
            print("Task \(Kitchen.id) reading \(await myKitchen.numberOrdersBeingPrepared)")
        }
    }
    
    async let t4 = Task {
        await Kitchen.$id.withValue("4th") {
            await myKitchen.aMealStartsPreparing()
            print("Task \(Kitchen.id) reading \(await myKitchen.numberOrdersBeingPrepared)")
        }
    }
    // Spawn child tasks concurrently and await them.
    // To ensure serial execuation of the main functions
    await (t1.result,t2.result,t3.result,t4.result)
}


/*
 Result with not more race conditions
Thread:<NSThread: 0x6000005df680>{number = 5, name = (null)}    tag:Actor method read numberOrdersBeingPrepared old:0 new:1     isMain:false
Thread:<NSThread: 0x6000005df680>{number = 5, name = (null)}    tag:Actor method aMealStartsPreparingSafe for Task :5th    isMain:false
1
Thread:<NSThread: 0x6000005df680>{number = 5, name = (null)}    tag:Actor method read numberOrdersBeingPrepared old:1 new:2     isMain:false
Thread:<NSThread: 0x6000005df680>{number = 5, name = (null)}    tag:Actor method aMealStartsPreparingSafe for Task :6th    isMain:false
2*/
func actorExampleNoMoreRaceCondition() async  {
    let myKitchen = Kitchen()
    async let t1 = Task {
        await Kitchen.$id.withValue("5th") {
            await myKitchen.aMealStartsPreparingSafe()
        }
    }
    
    async let t2 = Task {
        await Kitchen.$id.withValue("6th") {
            await myKitchen.aMealStartsPreparingSafe()
        }
    }
    // Spawn child tasks concurrently and await them.
    // To ensure serial execuation of the main functions
    await (t1.result,t2.result)
}

/* 4
 Using nonisolated keyword
 
 Some actor methods that do not access immuable state would not need to be called using the await keyword.
 However the compiler will falg an error. We have to explicitely mark the method as nonisolated to to tell
 the compiler that we have confirmed that the method is not accessing mutable state
 
 */
 func actorReadIsolationError() async  {
    let myKitchen = Kitchen()
    //myKitchen.printWhatTypeOfCuisine() Compiler flags as error because we need to use await to access an actor method
    myKitchen.printWhatTypeOfCuisineNonIsolated() // This is ok because we have marked method as not isolated
}

Task { @MainActor in
    await actorExample()
    resetParams()
    await actorExampleRaceCondition()
    resetParams()
    await actorExampleNoMoreRaceCondition()
    resetParams()
    await actorReadIsolationError()
}



func resetParams() {
    print("\n")
}


