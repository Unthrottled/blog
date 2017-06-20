---
layout: post
title: "Circuit Breakers"
tags: [Java, Hystrix, Hystrix Dashboard, Spring Boot, Spring MVC, Angular, Webpack, ReactiveX, Node.js, Netflix OSS, Circuit Breaker]
headerImage: circuit/hystrix-logo.png
---

Aside from being hard to spell sometimes, the circuit breaker design pattern is most helpful for protecting your application code from everybody else.
Not only does it protect your application, it also prevents directing more traffic to a service, that is already having trouble responding, with more requests.

For starters, I have created an example project that utilizes and tries to demonstrate the circuit breaker pattern that is implemented by Hystrix.
The repository can be found here:

### [https://github.com/cyclic-reference/circuit-breaker](https://github.com/cyclic-reference/circuit-breaker)

Let's start of with an example.
Image that we are tasked with consuming service Zeta, a third party webservice, because their API satisfies part of our projects requirements.
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
It should be able to recover faster if we are not constantly filling up its queues with requests its just going to reject.

The same applies when it takes forever to respond.
It makes no sense loading up the service with more work than it can handle.
What we are looking for is a "hands off" period for the struggling Zeta.
Also, having a finger to point at the trouble maker would be nice as well.

This is what I see as Hystrix's main use cases. The following bullet points are taken from the Hystrix wiki, explaining its design in their words:

- Give protection from and control over latency and failure from dependencies accessed (typically over the network) via third-party client libraries.
- Stop cascading failures in a complex distributed system.
- Fail fast and rapidly recover.
- Fallback and gracefully degrade when possible.
- Enable near real-time monitoring, alerting, and operational control.

The rest of the post will run of the example project demonstrating some of Hystrix's functionality.

So let us say that we have our Zeta client wrapping in a Hystrix command now.
When the application starts, the circuit is in the closed state, our feign Zeta has been behaving well so far.
However, without changing the number of synchronized requests to Zeta, just turning the power switch off.

This will result in the volume circle to go from jolly green to sickly yellow and then soon to be dead red.
You will notice that before the circle goes to red, the circuit still remains closed, we have not met the triggering threshold.
However, once the circuit opens, the monitor circle becomes a nice shade of red.
The circuit is now open, and using the fall back method.
Effectively protecting us and the currently dead feign Zeta.

Triggering the power switch back to the on position, you should notice something interesting.
The requests still keep failing, what the heck?
Do I not know how to write functioning code?

That last statement is up for debate, however, this is part of the circuit breaker design pattern.
When the circuit breaker opens, it will eventually need to close, redirecting traffic back to newly functioning feign Zeta.
So after a period of time remaining open, circuit will eventually slide into a "half open" state.

Meaning that the next call will be routed to feign Zeta, if the call is a success, then all traffic is re-routed back to the service, effectively closing the circuit again.
However, if the request fails again, the circuit will go back into the open state.
This being different than when a call fails while circuit is closed.
When the circuit is closed, there has to be a certain threshold of failed requests before the circuit opens.
This period between being fully open and half open will explain the gap of failed messages in the stream, even though feign Zeta is still working.

The Hystrix will exhibit almost the same behaviour when requests begin to reach the timeout threshold.
Instead of the red failure request count going up in the Hystrix monitor, the yellow time-out request will begin to go up.

For more information about Hystrix, be sure to visit the github wiki.
Also be sure to checkout this Software Engineering radio podcast for more information about the tools Netflix uses!

#### [http://www.se-radio.net/2014/12/episode-216-adrian-cockcroft-on-the-modern-cloud-based-platform/](http://www.se-radio.net/2014/12/episode-216-adrian-cockcroft-on-the-modern-cloud-based-platform/)


#### Resources:

- [https://github.com/Netflix/Hystrix](https://github.com/Netflix/Hystrix)
- [http://reactivex.io/](http://reactivex.io/)
- [https://angular.io/guide/quickstart](https://angular.io/guide/quickstart)
- [https://angular.io/tutorial](https://angular.io/tutorial)
- [https://angular.io/guide/webpack](https://angular.io/guide/webpack)
- [https://juristr.com/blog/2016/09/ng2-get-window-ref/](https://juristr.com/blog/2016/09/ng2-get-window-ref/)
- [https://hub.docker.com/\_/node/](https://hub.docker.com/\_/node/)
- [https://martinfowler.com/bliki/CircuitBreaker.html](https://martinfowler.com/bliki/CircuitBreaker.html)