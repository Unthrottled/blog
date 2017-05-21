---
layout: post
title: "Distributed Tracing"
---

The term _microservice_ means difference things to many different people.
Some, including myself, might call it freedom from the oppressive monolith and chains that must be bore when working on one.
Allowing developers to spread there wings and fly, without having to worry if the changes they made broke some obscure part of the codebase.
Enabling the release of code early and often, shedding the fear going to production and delivering code that matters.

This does not mean that the monolithic architecture is inherently bad. 
For instance, if one is working on a small project, it is probably not worth the overhead of maintaining many services, through out their lifecycle.
That would be like using a grenade launcher to hunt deer.
Sure it gets the job done, but it is expensive and there is a high probability that it might blow up in your face. 
Plus, as far as I am aware, deer do not shoot back.

One of the things that has a high probably of unintended friendly fire is, _tail-latency_.
Latency can be defined as the time it takes for something to respond to an action or event. 
Such as the time it takes for chemical reactions to take place, the length in time it takes a double-clutch to register a change of gears,or how long it takes for a website to respond when a button is clicked.
Tail-latency is the classification of the reactions that took longest to occur.
The far end of the bell-curve of response times. 

![Bell-Curve]({{site.imageDir}}/tracing/bell-curve.jpg)

Let us say that we are have developed an application that provides users will silly cat pictures.
It normally takes the application 100 milliseconds(ms) to load a single image an amusing kitty photo.
Each page consists of an average aggregation of ten photos.
It is known that the is a 10% chance of having an image take 1000ms or 1 second to load.
Meaning that a complete page has a high probability of taking one second to completely load up.
This one second lag is what we would call our tail-latency. 
Sure it normally takes 100ms to run, but it is the 1 second that really matters.

People are fickle and tend to only see the the bad.
Take for instance, lets say you visit a sandwich shop. The first time you order a chicken sandwich on rye, it was good.
The next next you go, you order the chicken sandwich again, since knowing that it was pretty good.
Turns out this sandwich was good as well. However, the preceding visit, we have the chicken sandwich again, but this time something awful happens.
After consuming the tasty morsel, later that evening you catch the stomach virus going around work. 
You spend the rest of the night with traumatizing stomach pains, leading up to the evacuation of the sandwich had for lunch.
The experience was so awful, that it ruined chicken sandwiches entirely. 
It was not the sandwiches fault that you got sick, but even thinking about eating another is out of the question.
How's the saying go? It only takes one bad apple to ruin the bunch?

Having to wait one whole second to look at funny pictures might not seem up to par with total gastro-evacuation, but it might cause loss of users.
Sure the first time, they might just chalk it up to just Comcast for providing third world internet connection speed. 
However, that blaming a slow ISP, for inhibiting a quality does of funny cat photos, can only go so far .
If the website in continuously slow, people will give up and search for a better alternative. 
It is not worth having to wait internet eons to get what they want, and people will move on.

So what does this have to do with distributed tracing?
Well as it turns out, a whole bunch!
Distributed tracing allows for an in-depth break down of a latency tree in a micro-service architecture.
Essentally, a profiler, such as [yourkit](https://www.yourkit.com/), for the cloud.
It enables a more granular break down a service call.
Showing the interactions between services that are made and how long each one takes after they have received a request and finished with a response.
Painting a more clear picture of a transaction.
Hopefully, leading to a paths where optimizations can be wired in to reduce response times.

Continuing off of the previous example: we have an Alpha Service. 
Alpha Service has a dependencies on both Bravo Service and Charlie Service.
Charlie Service has a dependency Zulu Service.
We know that it takes around 100ms (with the occasional tail latency of 1000ms), but do not know the break down of time spent with dependent interacting with one another.
For instance, it might be the case that Alpha, Bravo, and Charlie all respond in a reasonable amount of time of lets say 10ms.
It might be Zulu that takes an average of 70ms, with a chance of being bogged down and taking 930ms.

This currently is all conjecture at the moment, just a bunch of guesses.
There exits many cool tools and methodologies that allow for this kind of insight in place of, "well it could be this".
**Knowing is way better than guessing!**

One such technology is Twitter's [Zipkin](http://zipkin.io/) which is based off of Google's research, on tracing distributed infrastructure, [Dapper paper](https://research.google.com/pubs/pub36356.html).
Now I have not read the entire paper as of yet. However, I am able to give you a synopsis of what I know, base off of use of Zipkin and presintations on such a subject.

Starting off with the definition of a **Span** in the context of Client-Server.
A Span is really any unit of work that a Client or Service will execute in.
In the case of Zipkin it can be any of the following.

- It first starts at the point of the _client sending_ a message to a server (Client Send:CS). 
- The next event is when the _server eventually receives_ the client's sent message (Server Receive:SR).
- After that, the serve will eventually send a message back to the client which initiated the request (Server Send:SS).
- Ending the span when the _client receives_ (CR) the message from the server it contacted (Client Receive:CR).

A **Trace** is a tree of spans that compose an entry point request into the infrastructure we happen to be debugging.
Given the example stated above and all requests are blocking, a trace would be:

1. Alpha Client sends a message to Alpha Service. CS
1. Alpha Service receives the message from Alpha Client. SR
1. Alpha Service sends a message to Bravo Service. CS
1. Bravo Service receives the message from Alpha Service. SR
1. Bravo Service sends a message back to Alpha Service. SS
1. Alpha Service receives the message from Bravo Service. CR
1. Alpha Service sends a message to Charlie Service. CS
1. Charlie Service a receives the message from Alpha Service. SR
1. Charlie Service sends a message to Zulu service. CS
1. Zulu Service receives the message from Charlie Service. SR
1. Zulu Service sends a message back to Charlie Service. SS
1. Charlie Service receives the message from Zulu Service. CR
1. Charlie Service sends a message back to Alpha Service. SS
1. Alpha Service recievs the message from Charlie Service CR
1. Alpha Service sends a message to Alpha Client. SS
1. Alpha Client receives the message from Alpha Service. CR

That is quite a bit to take in, fortunately with this information, Zipkin has the ability to create a graphical depiction of a dependency tree!
The following dependency tree was created by Zipkin UI from a trace of the example project above.
 
![Service Dependency Tree]({{site.imageDir}}/tracing/dependency-tree.png)

