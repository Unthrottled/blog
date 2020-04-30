---
layout: post
title: Processes running on ports.
categories: sysadmin
tags: [System Adminstration, Consul, Service Discovery, Unix, Windows]
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
The following is satisfactory for finding the proccess id (PID) running on a port. 
Provided you have sudoer permissions (this works for OSX and UNIX machines):

    sudo lsof -n -i | grep :53

`lsof` is a unix command that lists all of the current open files.
Which is handy in this case because everything in unix is a file!
So this includes stream and a network files (Internet socket, NFS file or UNIX  domain  socket.)
These files will be bound to a port, and the sudo permission will give the PID of the open process. 
The `-i` argument tells _lsof_ to select the listing of all internet and network file, greaty reducing the output of the command.
The `-n` argument is a optimization that allows the comand to run faster by doing less work. 
Most of this information is provided in the manual pages, which can be accessed by `man lsof`.
Finally the standard output of the lsof command is piped into `grep` to help us find what really matters.
Without grep the command spits out a bunch of output like this:

    ...
    chrome   6683 alex  205u  IPv6 256428110      0t0  UDP *:mdns 
    chrome   6683 alex  286u  IPv6 256428111      0t0  UDP *:mdns 
    java     8757 alex  123u  IPv4  42679018      0t0  TCP 127.0.0.1:40159 (LISTEN)
    java     8757 alex  215u  IPv4    649987      0t0  TCP 127.0.0.1:6942 (LISTEN)
    java     8757 alex  713u  IPv4    650062      0t0  TCP 127.0.0.1:63342 (LISTEN)
    java     8757 alex  782u  IPv4    654625      0t0  UDP *:54600 
    java     8757 alex  783u  IPv4    654626      0t0  UDP *:8976 
    java     8757 alex  790u  IPv4    654709      0t0  TCP *:32971 (LISTEN)
    spotify 12375 alex   77u  IPv4  92474199      0t0  TCP 127.0.0.1:4381 (LISTEN)
    spotify 12375 alex   78u  IPv4  92474200      0t0  TCP 127.0.0.1:4371 (LISTEN)
    spotify 12375 alex  105u  IPv4  92521189      0t0  UDP *:57621 
    spotify 12375 alex  106u  IPv4  92521610      0t0  TCP *:57621 (LISTEN)
    spotify 12375 alex  118u  IPv4 211120429      0t0  TCP *:44079 (LISTEN)
    spotify 12375 alex  119u  IPv4  92565111      0t0  UDP *:34539 
    spotify 12375 alex  120u  IPv4  92565112      0t0  UDP *:57885 
    ...

Now that all the information is on the table, there can only be one process on the port I want!
The PID is in the second column and for example I want port 4381. 
That means I have to turn my music off.

    kill -9 12375
    
This will send the SIGINT signal to tell the Spotify process that it is time to shut down.

This is great and all, but what if you are on windows?
All hope is not lost, for it has the `netstat` command, which looks a bit like this:

    netstat -a -n -o
    
It is almost the same as the lsof command.The `-a` argument ask for all of the processes associated  with a port.
`-n` option prevents DNS lookup for all addresses found. 
Whie the `-o` argument includes the PID in the output.
Which looks something like this:

    Active Connections
      Proto  Local Address      	Foreign Address    	State       	PID
      TCP	127.0.0.1:1315     	127.0.0.1:1316     	ESTABLISHED 	4780
      TCP	127.0.0.1:1316     	127.0.0.1:1315     	ESTABLISHED 	4780
      TCP	127.0.0.1:1326     	127.0.0.1:1327     	ESTABLISHED 	3364
      TCP	127.0.0.1:1327     	127.0.0.1:1326     	ESTABLISHED 	3364
      ...

Most of the information about the netstat command can be provided by executing
`netstat /?`.

If the Windows process 4780 needs to be terminated the `taskkill` should come in handy.

    taskkill /F /PID 4780
    
If the processes existed befor running the command, it does not now!
The `/F` tells the command to force terminate ande the `/PID` allows for process id inputed.

So now if you should now be armed and dangerous. 
Do not let some obscure process hog the port you want to use, show it whose boss!
