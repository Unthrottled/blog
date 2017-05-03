---
layout: post
title:  "Boosted Hazelcast"
categories: java
headerImage: rail.jpg
---

Do not be deceived, as distributed caches go, vanilla Hazelcast has really quick response times. 
However, there are some nob, buttons, and levers that can be pushed, pulled, and pulled to make responses even quicker!

Hazelcast, being a distributed in-memory data-grid, has to be able to store and send objects over networks. 
Meaning that all items put into a hazelcast instance must be stored in a byte array.
A byte array is a data structure that is able to be sent across networks.
This allows all the nodes in a given cluster to share information. 