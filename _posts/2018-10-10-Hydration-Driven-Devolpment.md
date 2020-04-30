---
layout: post
title:  "Hydration Driven Development"
date:   2018-10-10
categories: java
tags: [Software Development, TDD, BDD, Software Craftsmanship, Java]
---

Test Driven Development (TDD) is a highly powerful tool to: construct well written, maintainable, and correct code.
However, there seems to be a missing step that makes TDD appear to be less approachable. 
Hopefully, this post will be able to make TDD more appealing and explain the real value behind the methodology.
In addition, we will learn how to make a refreshing glass of water!

A quick Google search for TDD will most likely lead to article prescribing the following bland steps:

1. Add a test
1. Run all tests and see if the new test fails.
1. Write the code to make test pass.
1. Run all tests.
1. Refactor code in an attempt to make the tests pass.
1. Repeat until all tests pass and code looks great!

The question that should come to mind before even writing a test should be, "What class am I writing test for in the first place?"

Any person following the steps above will most likely not know where to start writing tests.
Which is why the following omitted step(s) should be included.

> Design and define interface(s) to solve a single/well-defined responsibility to satisfy a requirement.
    
This way any developer should have a great place or any place really to start.
Starting is the difficult part. Once the vision is in place, a lot the other APIs start to become more clear. 

Once a interface is defined, they can then write test to validate the designed behaviour.

It is the process of defining your APIs and how they interact, before writing your implementation is what sets things up for greatness. 
Having to think about the abstractions that are needed leads to a more focused and loosely coupled architecture.
The need to give each interface what it needs to do the job makes testing each class easier as well.

> TDD should bring the concept of: "If the tests are easy, then the code should be straight forward, concise, readable, and maintainable"

Since the APIs were designed to satisfy a specific behaviour, the tests that are built should verify that that behaviour happens as expected.
Tests should be written in such a way that the implementation of the method should not cause any test to fail, provided the expected behaviour remains the same.

---

Take this layman's example of a requirement:

    Given a half filled or less cup, I expect the cup to be return filled half way with water.
    
There are _many_ ways to satisfy this requirement.

Here's what might have come to mind as a solution.

1. Grab Cup.
1. Move to water faucet.
1. Turn on faucet.
1. Place cup under faucet.
1. Move from under faucet when cup is half full.
1. Return cup.

Resist the urge to just start building solutions though!
The perfectly normal solution above, is really hard to test.

You need to first stub out the water faucet, so that it always produces the same stream of water.
Also, we need to make sure that the faucet can be turned on the same way.
Would also need to make sure that your right grabbing apparatus is stubbed out so that it remain the same throughout.

Once we have built our code and then tested it, everything is happy.
However, what happens when the faucet type changes? 
What happens if the left grabbing apparatus is chosen over the right?
Suppose we are forced to use a water bottle to fill our cup.

The tests that where written will fail, even though the behaviour remained the same.
Empty cup goes in, half filled cup comes out.
How that happened changed though, and the tests that were built reflect that issue.
Our mocked out dependencies no longer satisfy our implementation.
Decoupling the test from the implementation of the class allows for the class to change and the test to remain the same.
Effectively saving time maintaining the codebase. 

It is unnecessary to fix tests when code behaviour remains the same. 
The method is tightly coupled to the implementation, it's a low-level solution.

So then, how do we fix this? Well, we do this by applying Test Driven Development of course!
To help us, we need to think of the high-level abstractions that we need to really satisfy our requirements.
This way the underlying implementations can be changed but, the higher order functionality remains the same!

There is a balance that exists from being too tightly coupled to so loosely coupled that every line of code is just a layer of indirection.
Finding that balance is key here, having the code give just enough context to understand the picture, without having to know everything.
This is the art of creating software, and my interpretation of it.

Breaking this problem into pieces, we first need to define the API that solves this task.

---

### Step One: Design and define interface(s) to solve a single responsibility.

- [Here are first pass designed interfaces.](/code/hdd/first_pass.html)

Here are the classes for your context refreshment:

- **LiquidContainer** - An interface for containing, well, liquid...
- **WaterSupply** - An interface for supplying amounts of water.
- **WaterRepository** - A class that has the dependencies of the above interfaces, and also fills containers with water.

The hard part about TDD, or development in general, is finding a place to start!
What is needed is a class that can satisfy the current requirement.

However, there was no definition of what a cup is or how we are supposed to get water!

A cup is really just a water container if you think hard enough. 
You can put water inside a tub, bucket, or anything that can hold/not hold water!

> Finding the right level of abstraction is an art in of itself. 
Too high and the classes will start to appear as just layers of indirection. 
Making it hard to get any context when debugging. Plus there is a ton more boilerplate to sift through.
Too low and the classes will begin to become tightly coupled to the implementation.
Making any change of the class very difficult, tedious, and slow.

A sink is really just a way to get water. Water can come from a hose, water bottle,
or anything that holds and dispenses water.

So our class that satisfies the requirement only needs a container and a source of water.

Now that water repository has a dependency that has an API that dispenses water and a parameter that has an API to accept water.

---

### Step Two: Add a test

Knowing which class to start writing tests for is tricky sometimes. 
At the moment there are two interfaces and one concrete class that needs to be implemented.
The difficult bit comes to deciding how the unit test is written.

One way is to write the test stubbing or mocking out all of the interfaces that the class that is being tested uses.
This means that any constructor dependencies are now stubbed out and any inputs are stubbed out.
The downside of this is that now the test author is responsible for stubbing out the exact behaviour of any dependency or input class.
Which can be time consuming and why designing simple objects is key. 
As an example, stateful inputs or dependencies are a pain to mock out.
This means that the mock needs to exhibit state and it takes more time to create a smart mock over just creating the actual class.

The purpose of TDD is to promote simplicity because testing complex classes is hard.
Complex classes are often left un-tested due to this fact.
So it is in the designer's best interest to develop API's that behave simply.

It would be tempting to just implement the stateless dependent classes first. 
So that they may be used to support the classes' test.
Even when creating a stateful class, it is important to step back and think:

- Does the API that has been created make sense? 
- Is it unnecessarily complicated even though the API's surface area is small?
- Can things be made simpler so that testing is easier?

These are some questions that should be asked about the initial design as tests are being written.
Testing the class should be easy, so stubbing out behaviour should be simple. 
It is better to find problems in the design early part of construction. 
Meaning time has not been spent implementing any code and only the bare-bones design exists.
This leave the code in a malleable state. 
Which is another benefit of test-driven development.

Another issue to look out for is: having issues verifying correctness. 
Based off of the current design choices, it is very difficult to verify that the implementation actually fetches water and puts it into the container.
All the test would care about is that the number in the container is the expected number regardless of how the number got there.   

Let us go back and revisit the first step of the process, which is _Design and Define Interfaces_.

- [Here are the redesigned interfaces.](/code/hdd/second_pass.html)

Here are the classes for your context refreshment:

- **LiquidContainer** - An interface for containing, well, liquid..
- **WaterSupply** - An interface for supplying amounts of water.
- **WaterRepository** - A class that has the dependencies of the above interfaces, and also fills containers with water.
- **Liquid** - A state of matter, but also the amount of matter. It can add and reduce it volume all by itself!
- **Water** - Water can be a liquid, right? 


#### Actually writing tests!

Now that the APIs have been re-designed, it's time to write some tests against the defined APIs!

Choosing a starting point to write tests, as mentioned before, is tricky sometimes.
Starting to test the main class `WaterRepository` that solves the given use case is a good starting point.
However, the method takes a stateful object and returns a stateful object.
Stateful classes, while un-avoidable, are a pain to stub/mock out. 

A good starting point is to first _design_ the stateful class, then write tests for it.
Once the tests are written, then implement the methods to make the all of the tests written pass.  
Then the implementation class can be used to support the tests whose classes depend on its implementation.

- [LiquidContainer class definition and tests.](/code/hdd/container_impl.html)

Special note, the class implementation has been defined for the liquid container, but the implementation remains the simplest possible.

- [Liquid interface definition and tests.](/code/hdd/liquid_tests.html)

Now dependent interfaces exist and writing tests for the `WaterRepository` can commence.

All of the work that was previously done has now led up to being able to test the class that was first chosen to be tested!

- [The tests for WaterRepository can be found here.](/code/hdd/WaterRepository_Test.html)

The last chunk of code that needs to be designed is a class that implements the `WaterSupply` interface.
This class will be fairly simple because there is not much to test.
It could be argued that this code is boilerplate and this is over-engineered given the current level of abstraction.
Due to the fact that the process of creating a `Water` object is not complex.
It can be boilerplate because of the fact that providing a value to the constructor is sufficient and having a class do that is unnecessary.
It also can be described as over-engineered due to the fact that the level of abstraction is high enough to supply more implementations than the requirement needs.
Meaning that the code is built in such a way that other requirements to fetch anything liquid (ie: Kool-Aid, Orange Juice, etc) could be easily implemented.

However, in the end what is left is code that is modular, loosely-coupled, maintainable, readable, correct, and fully tested! 
The amount of initial work put upfront pays off because, less time is spent in the future maintaining this code.

- [Here is the last tests that need to be written\!](/code/hdd/water_supply.html)

---

### Step Three: Write code to make the tests pass.

Granted, there are some tests that currently pass, given the state of our code right now.
However, now is the time to make all of the tests that are written to pass!

- [Actual class implementations\!](/code/hdd/class_implementations.html)

It was really fun implementing these classes. 
There came a time when I was glad I had a safety net of tests.

Which leads me to my closing point. In my opinion TDD should **not** be "only write tests and then write code".
As I was developing this demo, there came times where my API's had to evolve, and I had to change things to reflect new behaviours I had not accounted in the past.
I do not know about you, but I cannot think of every bit, piece, nook, and cranny that is required to satisfy the original requirement. 

Test are not meant to weigh and slow us down. Granted, they do take up bandwidth at the initial phase of adding to a project.
However, they pay dividends (if done correctly) in times of maintenance. 
Writing tests is ensuring that future maintainers (which may be you!) have to spend less time trying to adjust code to satisfy changing requirements.

With TDD, there should never be an excuse as to not writing unit test because it was too hard.
That class that needs tests should have been designed with the test in mind, whether it was written before or after!

If there is a take away from this article it should be:

## TL;DR: We should write classes to easily be tested, so we do not hate ourselves later when making changes.     


### [Git Repo for the extra motivated](https://github.com/Unthrottled/hdd.git)
