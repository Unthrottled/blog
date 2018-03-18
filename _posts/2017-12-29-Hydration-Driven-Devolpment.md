---
layout: post
title:  "Hydration Driven Development"
date:   2017-12-29
categories: java
headerImage: hdd/mr_volcano.png
tags: [Software Development, TDD, BDD, Software Craftsmanship, Java]
---

Test Driven Development (TDD) is a highly powerful tool to: construct well written, maintainable, and correct code.
However, there seems to be a missing step that makes TDD appear to be less approachable. 
Hopefully, this post will be able to make TDD more appealing and explain the real value behind the methodology.
In addition to learning how to make a refreshing glass of water!

A quick Google search for TDD will most likely lead to article prescribing the following bland steps:

1. Add a test
1. Run all tests and see if the new test fails.
1. Write the code.
1. Run tests.
1. Refactor code.
1. Repeat until all tests pass and code looks great!

The question that should come to mind before even writing a test should be, "What class am I writing test for in the first place?"

Any person following the steps above will most likely not know where to start writing tests.
Which is why the following omitted step(s) should be included.

> Design and define interface(s) to solve a single/well-defined responsibility.
    
This way any developer should have a great place or any place really to start.
Starting is the difficult part. Once the vision is in place, a lot the other APIs start to become more clear. 

Once a interface is defined, they can then write test to validate the designed behaviour.

It is the process of defining your APIs and how they interact, before writing your is what leads to greatness. 
Having to think about the abstractions that are needed leads to a more focused and loosely coupled architecture.
The need to give each interface what it needs to do the job makes testing each class easier as well.

> TDD should bring the concept of: "If the tests are easy, then the code should be straight forward, concise, readable, and maintainable"

Since the API were designed to satisfy a specific behaviour, the tests that are built should verify that that behaviour happens as expected.
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

It is unnecessary to fix tests when code behaviour remains the same. 
The method is tightly coupled to the implementation, it's a low-level solution.

So then, how do we fix this? Well, we do this by applying Test Driven Development of course!
To help us, we need to think of the high-level abstractions that we need to really satisfy our requirements.
This way the underlying implementations can be changed but the higher order functionality remains the same!

There is a balance that exists from being too tightly coupled to so loosely coupled that every line of code is just a layer of indirection.
Finding that balance is key here, having the code just just enough context to understand the picture, without having to know everything.
This is the art of creating software, and my interpretation of it.

Breaking this problem into pieces, we first need to define the API that solves this task.

---

### Step One: Design and define interface(s) to solve a single responsibility.

### [Here are first pass designed interfaces.]({{site.url}}/code/hdd/first_pass.html)

The hard part about TDD, or development in general, is finding a place to start!
What is needed is a class that can satisfy the current requirement.

However, there was no definition of what a cup is or how we are supposed to get water!

A cup is really just a water container if you think hard enough. 
You can put water inside a tub, bucket, or anything that can hold/not hold water!

A sink is really just a way to get water. Water can come from a hose, water bottle,
or anything that holds and dispenses water.

So our class that satisfies the requirement only needs a container and a source of water.

Now that water repository has a dependency that has an API that dispenses water and a parameter that has an API to accept water.

---

### Step Two: Add a test

Knowing where to start writing test is tricky sometimes. 
At the moment there are two interfaces and one concrete class that needs to be implemented.
The difficult bit comes to deciding how the unit test is written.

One way is to write the test stubbing or mocking out all of the interfaces that the class that is being tested uses.
This means that any constructor dependencies are now stubbed out and any inputs are stubbed out.
The downside of this is that now the test author is responsible for stubbing out the exact behaviour of any dependency or input class.
Which can be time consuming and why designing simple objects is key. 
As an example, stateful inputs or dependencies are a pain to mock out.
This means that the mock needs to exhibit state and it takes more time to create a smart mock over just creating the actual class.

The purpose of TDD is to promote simplicity because testing complex classes is hard.
So it is in the designer's best interest to develop API's that behave simply.

It would be tempting to just implement the stateless dependent classes first. 
So that they may be used to support the classes' test.
Even when creating a stateful class, it is important to step back and think.

Does the API that has been created make sense? 
Is it unnecessarily complicated even though the API's surface area is small?
Can things be made simpler so that testing is easier?

These are some questions that should be asked about the initial design as tests are being written.
Testing the class should be easy, so stubbing out behaviour should be simple. 
It is better to find problems in the design early part of construction. 
Meaning time has not been spent implementing any code and only the barebones design exists.
This leave the code in a malleable state. 
Which is another benefit of test-driven development.

Another issue to look out for is: having issues verifying correctness. 
Based off of the current design choices, it is very difficult to verify that the implementation actually fetches water and puts it into the container.
All the test would care about is that the number in the container is the expected number regardless of how the number got there.   

Let us go back and revisit the first step of the process, which is _Design and Define Interfaces_.

### [Here are redesigned interfaces.]({{site.url}}/code/hdd/second_pass.html)

## Writing Tests!

Now that the API's have been re-designed, it's time to write some tests against the defined APIs!

Choosing a starting point to write tests, as mentioned before, is tricky sometimes.
Starting to test the main class `WaterRepository` that solves the given use case is a good starting point.
However, the method takes a stateful object and returns a stateful object.
Stateful classes, while un-avoidable, are a pain to stub/mock out. 

A good starting point is to first _design_ the stateful class, then write tests for it.
Once the tests are written, then implement the methods to make the all of the tests written pass.  
Then the implementation class can be used to support the tests whose classes depend on its implementation.

### [Liquid container tests.]({{site.url}}/code/hdd/container_impl.html)

### [Liquid interface tests.]({{site.url}}/code/hdd/liquid_tests.html)

{% highlight java %}
//....
public class WaterRepositoryTest {


    @Test
    public void fillContainerHalfWayShouldReturnAContainerThatIsHalfFull() {
        WaterSupply waterSupply = Mockito.mock(WaterSupply.class);
        Mockito.when(waterSupply.fetchWater(250L)).thenReturn(new Water(250L));
        WaterRepository testSubject = new WaterRepository(waterSupply);
        LiquidContainer simpleLiquidContainer = new SimpleLiquidContainer(500);
        LiquidContainer result = testSubject.fillContainerHalfWay(simpleLiquidContainer);
        assertTrue(result.fetchCurrentVolume()
                .map(new Water(250)::equals)
                .orElse(false));
    }


    @Test
    public void fillContainerHalfWayShouldReturnAContainerThatIsHalfFull_II() {
        WaterSupply waterSupply = Mockito.mock(WaterSupply.class);
        Mockito.when(waterSupply.fetchWater(500L)).thenReturn(new Water(500L));
        WaterRepository testSubject = new WaterRepository(waterSupply);
        LiquidContainer simpleLiquidContainer = new SimpleLiquidContainer(1000);
        LiquidContainer result = testSubject.fillContainerHalfWay(simpleLiquidContainer);
        assertTrue(result.fetchCurrentVolume()
                .map(new Water(500)::equals)
                .orElse(false));
    }


    @Test
    public void fillContainerHalfWayShouldReturnAContainerThatIsHalfFullAndIsOdd() {
        WaterSupply waterSupply = Mockito.mock(WaterSupply.class);
        Mockito.when(waterSupply.fetchWater(131L)).thenReturn(new Water(131L));
        WaterRepository testSubject = new WaterRepository(waterSupply);
        LiquidContainer simpleLiquidContainer = new SimpleLiquidContainer(263);
        LiquidContainer result = testSubject.fillContainerHalfWay(simpleLiquidContainer);
        assertTrue(result.fetchCurrentVolume()
                .map(new Water(131)::equals)
                .orElse(false));
    }
}
{% endhighlight %}

{% highlight java %}
//....
{% endhighlight %}