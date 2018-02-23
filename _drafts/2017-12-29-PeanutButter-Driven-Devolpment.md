---
layout: post
title:  "Peanut Butter Driven Development"
date:   2017-12-29
categories: java
headerImage: pbdd/pbj.png
tags: [Software Development, TDD, BDD, Software Craftsmanship, Java]
---

Test Driven Development (TDD) is a highly powerful tool to construct well written, maintainable, and correct code.
However, there seems to be a missing step when a majority of people talk about TDD. 
Hopefully, this post will be able to make TDD more approachable and explain the real value behind the methodology.
In addition to learning how to make a peanut butter and jelly sandwich!

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

1. Design and define interface(s) to solve a single responsibility.
1. Add a test
1. Run all tests and see if the new test fails.
1. Write the code.
1. Run tests.
1. Refactor code.
1. Repeat and start at step 4 until all tests pass and code looks great!
1. Repeat and start at step 1 until the feature is implemented.
    
This way any developer should have a great place or any place really to start.
Starting is the difficult part. Once the vision is in place, a lot the other APIs start to become more clear. 

Once a interface is defined, they can then write test to validate the designed behaviour.

It is the process of defining your APIs and how they interact, before writing your is what leads to greatness. 
Having to think about the abstractions that are needed leads to a more focused and loosely coupled architecture.
The need to give each interface what it needs to do the job makes testing each class easier as well.

TDD should bring the concept of: "If the tests are easy, then the code should be straight forward, concise, readable, and maintainable"

Since the API were designed to satisfy a specific behaviour, the tests that are built should verify that that behaviour happens as expected.
Tests should be written in such a way that the implementation of the method should not cause any test to fail, provided the expected behaviour remains the same.

Take this layman's example of a requirement:

    Given an empty cup, then I expect the cup to be return filled half way with water.
    
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
Finding that balance is key here, having the code have just enough context to understand the picture, without having to know everything.
This is the art of creating software, and my interpretation of it.

Breaking this problem into pieces, we first need to define the API that solves this task.

### Step One: Design and define interface(s) to solve a single responsibility.

{% highlight java %}
//....

public interface LiquidContainer {
  /**
   * @return the total volume container, regardless of fill level.
   */
  long fetchTotalCapacity();

  /**
   * Fills the container with the desired amount of water.
   * @param volumeOfWater desired amount of water to place in container, must be greater than zero
   * @return amount of water stored in container
   * @throws IllegalStateException if given number lower than zero.
   */
  long storeWater(long volumeOfWater);

  /**
   * @return The amount of liquid currently stored in the container.
   */
  long fetchCurrentVolume();
}

{% endhighlight %}

{% highlight java %}
//....
public interface WaterSupply {

  /**
   * @param desiredAmount the amount of water to retrieve from
   *                      the water supply
   * @return the maximum amount of water that can be supplied each invocation
   * @throws IllegalArgumentException if given a number less than zero
   */
  long fetchWater(int desiredAmount);

  /**
   * @return the largest amount of water that can be returned from the water supply
   * per invocation.
   */
  long maximumFetchableWater();
}
{% endhighlight %}

{% highlight java %}
//....
public class WaterRepository {
  private final WaterSupply waterSupply;

  public WaterRepository(WaterSupply waterSupply){
    this.waterSupply = waterSupply;
  }

  /**
   *
   * @param liquidContainer
   * @return
   */
  public LiquidContainer fillContainerHalfWay(LiquidContainer liquidContainer){
    return liquidContainer;
  }
}
{% endhighlight %}

The hard part about TDD, or development in general, is finding a place to start!
What was needed is a class who can satisfy the requirement.

However, there was no definition of what a cup is or how we are supposed to get water!

A cup is really just a water container if you think hard enough. 
You can put water inside a tub, bucket, or anything that can hold/not hold water!

A sink is really just a way to get water. Water can come from a hose, water bottle,
or anything that holds and dispenses water.

So our class that satisfies the requirement only needs a container and a source of water.

Now that water repository has a dependency that has an API that dispenses water and a parameter that has an API to accept water.

### Step Two: Add a test

Knowing where to start writing test is tricky sometimes. 
At the moment there are two interfaces and one concrete class that needs to be implemented.
The difficult bit comes to deciding how the unit test is written.

One way is to write the test stubbing or mocking out all of the interfaces that the class that is being tested uses. \
This means that any constructor dependencies are now stubbed out and any inputs are stubbed out.
The downside of this is that now the test author is responsible for stubbing out the exact behaviour of any dependency or input class.
Which can be time consuming and why designing simple objects is key. 
The purpose of TDD is to promote simplicity because testing complex classes is hard.
So it is in the designer's best interest to develop API's that behave simply.

It would be tempting to just implement the dependent classes first. 
So that they may be used to support the classes' test. 
However, if those thought do occur it is important to step back and think.

Does the API that has been created make sense? 
Is it unnecessarily complicated even though the API's surface area is small?
Can things be made simpler?

These are some questions that should be ask about the initial design as tests are being written.
Testing the class should be easy, so stubbing out behaviour should be simple. 
It is better to find problems in the design early part of construction. 
Meaning time hast not been spent implementing any code and just the design exists.
This leave the code in a malleable state. 
Which is another benefit of test-driven development.

Another issue to look out for is: having issues verifying correctness. 
Based off of the current design choices, it is very difficult to verify that the implementation actually fetches water and puts it into the container.
All the test would care about is that the number in the container is the expected number.   


{% highlight java %}
//....
{% endhighlight %}