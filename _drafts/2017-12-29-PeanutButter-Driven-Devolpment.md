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
    
There are many ways to satisfy this requirement.