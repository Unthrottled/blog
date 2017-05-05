---
layout: post
title: Processes running on ports.
categories: sysadmin
---
There comes a time during exploratory development.
Where all the new tools and frames works _have_ to be installed and probed.
Inevitably port collisions are bound to happen.
  
Personally, I ran int this problem when I was setting up a [Consul](http://www.consul.io) cluster.
Consul is a neat tool that allows for distributed services to discover one another. 
As an example, lets say we have an application that requires a service to provide silly cat pictures.
A silly cat service can be created deployed to many different servers. 
Now that they are deployed, they will not do the application any good if the client does not know where any of the services are, at any moment.
Consul will act as a router for these cat services. 
Once a service is registered into Consul traffic can be routed to that service.
Which allows for the silly cat service to scale horizontally, in case there is a large influx of users request more silly kitties.
I would highly recommend listing to [this podcast from Software Engineering Radio](http://www.se-radio.net/2016/08/se-radio-episode-264-james-phillips-on-service-discovery/).
They go into more detail about all of the cool things that service discovery can provide!

Anyways, back to the task at hand. 
So I was setting up a Consul cluster via docker images, and I had to expose UDP port 53 on the image and associate it to a port on my docker host.
Upon running the container, I was notified of port collision. 
Having port collisions on 8080 or 80 would have ben expected, but port 53, really?

Ubuntu is my operating system of choice, so I am able to use unix commands.
The following is satisfactory for finding the proccess id (PID) running on a port. Provided you have sudoer permissions:

    sudo lsof -n -i | grep :53