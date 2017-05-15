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
Such as the time it takes for chemical reactions to take place, or how long it takes for a website to respond when a button is clicked.
Tail-latency is the classification of the reactions that took longest to occur.
The far end of the bell-curve of response times. 

Lets say that we are have developed an application that provides users will silly cat pictures.
It normally takes the application 100 milliseconds(ms) to load a single image an amusing kitty photo.
Each page consists of an average aggregation of ten photos.
It is know that the is a 10% chance of having an image take 1000ms or 1 second to load.
Meaning that a complete page has a high probability of taking one second to load up.
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
How's the say go? It only takes one bad apple to ruin the bunch?

Having to wait one whole second to look at funny pictures might not seem up to par with total gastro-evacuation, but it might cause loss of users.
Sure the first time, they might just chalk it up to just cursing Comcast for slow internet. 
However, that can only go so far.
If the website in contiunousy slow, people might not want to use it at all.

So what does this have to do with distributed tracing?
Well as it turns out, a whole bunch!
Distributed tracing allows for break down of the latency tree in a micro-service architecture.
Essentally, a profiler, such as [yourkit](https://www.yourkit.com/), for web-service suite.
It enables a more granular break down of the calls that are made and how long each one takes when an interaction with a service occurs.
Allowing for a more clear picture as to where things can be optimized for every transaction.

Continuing off of the previous example: we have Service Alpha. 
Service Alpha has a dependencies on both Service Bravo and Service Charlie.
Charlie has a dependency Service Zulu.
We know that it takes around 100ms (with the occasional tail latency of 1000ms), but do not know the break down of time spent with dependent interacting with one another.
For instance, it might be the case that Alpha, Bravo, and Charlie all repsond in a reasonable amount of time of lets say 10ms.
It might be Zulu that takes an average of 70ms, with a chance of being bogged down and taking 930ms.
This currently is all conjecture at the moment.
There exits many cool tools and methodologies that allow for this kind of insight.