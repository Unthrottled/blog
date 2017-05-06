---
layout: post
title: Get that Gradle
categories: jvm
headerImage: gradle/gradle.png
---

When it comes to Java project build management frameworks, there are a few options.
One could choose Apache ANT or Maven, which are fine XML based build tools.
However, there are other options that are not XML Based. 
Such as Gradle, which is groovy based.
One of the the positives, in my opinion, is that more can be done with less code.
Also the fact that Groovy scripts can be written is a plus, its like a less verbose Java!

So let us explore the many ways we can install/upgrade Gradle, _another_ technology with an elephant based mascot.


![All Them Elephants]({{site.imageDir}}gradle/elephants.png)

I am sure that there are more examples of pachyderms pictures, but these are the ones I know of the top of my head.

Anyways, I need to converge back to the topic at hand.

For starters, if it was not picked up already, a Java Runtime Environment (JRE) needs to be set up.
In fact just continue on to the next section and take it from there!

Automatic Installers
---

For Linux users, if able to, install [SDKMAN](http://sdkman.io/install.html).
_This tool i really, really, nice!_
It makes installing and upgrading any Source Development Kits a breeze.

After you have on you box, and you still need Java, all you have to do is run this command:

     sdk install java 

At the time of this post, this will install and set up a Java Development Kit and Java Runtime Environment 8u131, easy!

**Fun Fact:** If you ever need to know where your JDK is installed just type in the command
    
    whereis java

`whereis` is a handy little command that finds the locations of all the binaries, sources, and manual of any command that exits on your path.
Which on when run on my machine will output the following

    java: /usr/bin/java /etc/java /usr/share/java /home/alex/.sdkman/candidates/java/9ea167/bin/java /usr/share/man/man1/java.1.gz

Since I have Java 9 installed my all of te JDKs live under the `/home/alex/.sdkman/candidates/java/` directory.
It is worth mentioning that there is a symbolic link in the java directory called current, which will be pointing to (you guessed it) the current installed version of java!

Installing Gradle is just as easy, I bet you have already come up with the command!
Here it is anyways:

    sdk install gradle
    
Run the gradle version command to verify that the installation went well:
  
      alex@sandwich:~$ gradle -v
      
      ------------------------------------------------------------
      Gradle 3.5
      ------------------------------------------------------------
      
      Build time:   2017-04-10 13:37:25 UTC
      Revision:     b762622a185d59ce0cfc9cbc6ab5dd22469e18a6
      
      Groovy:       2.4.10
      Ant:          Apache Ant(TM) version 1.9.6 compiled on June 29 2015
      JVM:          9-ea (Oracle Corporation 9-ea+167)
      OS:           Linux 4.8.0-49-generic amd64

#### Boom, Gradle, Done!
    
https://services.gradle.org/distributions/gradle-3.5-bin.zip