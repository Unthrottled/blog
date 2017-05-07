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

Anyways, I need to get back to the topic at hand.

For starters, if it was not picked up already, a Java Runtime Environment (JRE) needs to be set up.
In fact just continue on to the next section and take it from there!

Automatic Install
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
      JVM:          1.8.0_131 (Oracle Corporation 25.131-b11)
      OS:           Linux 4.8.0-49-generic amd64


#### Boom, Gradle, Done!

If you happen to be a MacOS or Windows enthusiast I can point you to the [gradle install page](https://gradle.org/install). 
Come back though, I miss you already!

Manual Install
---
Now that you are back, or never left, you probably still do not have Gradle, because you do not want or cannot put neat installer tools on your machine.
Fear not brave Programmer, there are still many ways to install gradle!

What will need to be accomplished for manual installation are the following steps, _regardless of operating system_.

1. Download the compressed Gradle binaries.
1. Uncompress the Gradle binaries somewhere on the target machine
1. Add the binary sub-directory of newly created Gradle directory to the PATH environment variable.
1. ????
1. *Gradle!*

##### Ubuntu Manual Install

The manual install steps can be done many ways, the following will be done using the command line.
According to the steps provided above, the Gradle binaries need to get on our machine.
To accomplish the following step, we need wget.
If wget is not installed on your machine just run the install command, provided sudoer permissions.

    sudo apt-get install wget
    
**Make sure that the the current working directory is where you want gradle to be installed**.

Next use wget to download the gradle 3.5 zip file from the Gradle site.
(Note: at the time of this post 3.5 is the most current version, feel free to use the a more current version if available)

    wget https://services.gradle.org/distributions/gradle-3.5-bin.zip
    
After compressed file exists on the target machine, it now needs to be uncompressed.

    unzip gradle-3.5-bin.zip -d gradle-3.5

The `-d` argument tells unzip to move all of the files contained in the gradle-3.5-bin.zip file into the new gradle-3.5 directory, provided gradle-3.5 in the current working directory.

Lastly, we need to tell everyone where gradle can be found so that it can be used!
This is done by appending the gradle-3.5/bin to the path variable.
Accomplishing this can be done by the following steps

1. The file ~/.profile. (Where ~ is your home directory).
1. Add the following line to the end of the file "PATH=$PATH:/home/alex/gradle-3.5/bin" (Replacing /home/alex with absolute path of the directory containg the  gradle-3.5 directory).
1. Save the file.

Provided you have not closed the current command line that was used to get and unzip gradle, the new path variable has available to the terminal instance, _yet_.
Either close and reopen a new terminal or just run the following command

    bash
    
Now you should be able to do a `gradle  -v` and be successful!
 
**Note:** To upgrade a manual installation you need to follow all of the same steps previously mentioned, but the path should ONLY contain the newest gradle binary directory.

#### Alternate Ubuntu Gradle install

If manual install and upgrade sound like too much work, then the `apt` package management system.

First, the repository provided by cwchien needs to be added:

    sudo add-apt-repository ppa:cwchien/gradle

Second, Then an package management system needs to be updated to register the new repo.

    sudo apt-get update
    
Third, to install the current gradle version the following command is sufficient.

    sudo apt-get install gradle-ppa
    
That's it! If when a new gradle is posted and you want it, just start at the Second step and enjoy your new gradle!

Go forth and conquer!

#### -Alex

### Resources:

- [https://gradle.org/install](https://gradle.org/install)
- [https://wtanaka.com/node/8079](https://wtanaka.com/node/8079)