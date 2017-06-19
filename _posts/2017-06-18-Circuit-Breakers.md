---
layout: post
title: "Circuit Breakers"
tags: [Java, Hystrix, Hystrix Dashboard, Spring Boot, Spring MVC, Angular, Webpack, ReactiveX, Node.js, Netflix OSS]
headerImage: circuit/hystrix-logo.png
---

Aside from being hard to spell sometimes, the circuit breaker design pattern is most helpful for protecting your application code from everybody else.
Not only does it protect your application, it also prevents directing more traffic to a service, that is already having trouble responding, with more requests.

For starters, I have created an example project that utilizes and tries to demonstrate the circuit breaker pattern that is implemented by Hystrix.
The repository can be found here:

### [https://github.com/cyclic-reference/circuit-breaker](https://github.com/cyclic-reference/circuit-breaker)

Let's start of with an example.
Image that we are tasked with consuming service Zeta, a third party webservice because their API satisifies part of our projects requirements.
However, Zeta does not have an outstanding track record in terms of performance.
There will be days when it only takes the Zeta around 100ms to respond, which is okay. 
However, it also has the habit to randomly increase the latency to past half a second, a minute, even to socket timeout!
It also seems that there is always some brief window of time that all of the requests sent to Zeta fail fast.
Almost like it just throws its hands up and refuses to do any work!

This is a big issue for our project. 
Whenever we want to demonstrate any functionality we developed at the end of our development iteration, we have to cross our fingers and hope Zeta works.
Our application will be the face of all Zeta's issues, even though it is not our fault, we will still get the repercussions.
So what are we to do? 

We need a way to wrap all of the service calls to Zeta in a protective bubble.
This bubble will need to fail the request if Zeta takes longer than average to respond, so our application does not take forever to respond.
It would also be nice when the call fails, that we could fall back to some canned response that is sufficient to no response at all.
That way we can still display something even when Zeta does not feel like doing it's job.
We also probably want to not pound Zeta into the ground with constant incoming requests during its fail fast period.
It should be able to recover faster if we are not constanty filling up its queues with requests its just going to reject.
The same applies when it takes forever to respond.
It makes no sense loading up the service with more work than it can handle.
What we are looking for is a "hands off" period.

This is what I see as Hystrix's main use case.

#### Resources:

- [https://github.com/Netflix/Hystrix](https://github.com/Netflix/Hystrix)
- [http://reactivex.io/](http://reactivex.io/)
- [https://angular.io/guide/quickstart](https://angular.io/guide/quickstart)
- [https://angular.io/tutorial](https://angular.io/tutorial)
- [https://angular.io/guide/webpack](https://angular.io/guide/webpack)
- [https://juristr.com/blog/2016/09/ng2-get-window-ref/](https://juristr.com/blog/2016/09/ng2-get-window-ref/)
- [https://hub.docker.com/\_/node/](https://hub.docker.com/\_/node/)
- [https://martinfowler.com/bliki/CircuitBreaker.html](https://martinfowler.com/bliki/CircuitBreaker.html)