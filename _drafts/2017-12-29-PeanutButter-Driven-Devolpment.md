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

1. Design and define interfaces to solve problem.
1. Add a test
1. Run all tests and see if the new test fails.
1. Write the code.
1. Run tests.
1. Refactor code.
1. Repeat until all tests pass and code looks great!
    
This way any developer should have a great place to start. 
Once a interface is defined, they can then write test to validate the designed behaviour.

It is the process of if defining your object API's and how the interact is what make your code great. 
Having to think about the abstractions that are needed leads to a more focused and loosely coupled architecture.
The need to give each interface what it needs to do the job makes testing each class easier as well.

