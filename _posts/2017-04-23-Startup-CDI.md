---
layout: post
title:  "Startup JavaBeans"
date:   2017-4-23
categories: java
---
Are you in charge of developing or maintaining a stateful web application with the Java EE API? Do you want some set of events to be triggered on your appliactions startup and shutdown? 
If you answered yes to any of these questions, then this post should help!

There are a lot of cool things that we can do with the Java EE api in our manage web containers. Of those things, is creating a Singleton Enterprise Java Bean. An Enterprise Java Bean is an object that is persitited within the web appliciation container for the duration of its context. Think of them as objects that we want in our classes to do meaning full work and how we get the instance of the class is provided by the underlying framework. A Singleton is the only instance of a class that will exist within the application lifecycle. 

Singletons are a great pattern to help solve the use case of bootstrapping our stateful application. Only one object is really needed, because you application only starts up and shuts down once. The Startup Singleton's job will bet to do meaningful work after it has been instanatied. Its instatiation should also happen on or after a successful deployment and not when a user first interacts with the application. By default EJBs are lazly instatiated, meaning that they are created only when needed. There ar a couple of ways to trigger the Startup Singleton's instantiation so it can set up the applications state.

Before starting off with code examples make sure that your application has the following dependency.

Maven

{% highlight xml  %}
<!-- Java EE 7 dependency -->
<dependency>
  <groupId>javax</groupId>
  <artifactId>javaee-api</artifactId>
  <version>7.0</version><!-- Can be version 6 or 7 -->
</dependency>
{% endhighlight %}

Gradle

{% highlight java  %}
compile "javax:javaee-api:7.0" //can be version 6 or 7
{% endhighlight %}

Note: On a personal note. If you are using RedHat's Jboss EAP 6.4 application server, you only have support for all of the items the Java EE 6 api provides. You can have the Java EE 7 on your Jboss EAP 6.4 server, but you cannot use the new feature. Hope that saves somebody some trouble.

If we want to use the EJB singleton provided by the Java EE api then all we have to do is the following:

{% highlight java  %}
package io.acari;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.ejb.Lock;
import javax.ejb.LockType;
import javax.ejb.Singleton;
import javax.ejb.Startup;

@Startup
@Lock(LockType.READ)
@Singleton
public class EJBStartupSingletonBean {
    @PostConstruct
    void initialize(){
        System.err.println("EJB Singleton Bean Doing Startup Work!");
    }

    @PreDestroy
    void shutdown(){
        System.err.println("EJB Singleton Bean Doing Cleanup Work before shutdown!");
    }
}
{% endhighlight %}

I have defined a class called EJBStartupSingletonBean and annotated it with the `@Singelton` annotation. Which means that this java bean will be created by the web application container and only one will ever be in existance. I also added the `@Lock` annotation. This is more of a best practice that I wantede to demonstrate. The annotation provides the functionally of have only one thread to have access to any of the singleton's public methods, to which the above example has none.
The `@Startup` is the money annotation. This tells the framework that at the start of the application the Singleton will be instantiated. When the instance is instantiated the method annotated with `@PostConstruct` will be invoked. 
This is where you can put your code to set up the state of the application. When the application is shutdown the method annotated with `@PreDestroy` will be invoked allowing for any clean up.

As a forewarning, annotating an _Application Scoped_ bean with the `@Startup` anotation will **NOT** cause an instance of that class to be created at startup.

I have provided an functional sample for those who are so inclined.
To run the sample you will need:
 - Internet Connection (At least the first time it is run)
 - Java 8 runtime
 - Maven 3.x.x

It can be reached at : 
https://github.com/cyclic-reference/startup-cdi

I chose to run it on Wildly Swarm, which is like a full fledged JBoss server, but only contains the libraries necessary to run an application server and deploy artifacts. All of this is nicely packed int a a jar. It a bit like Pivotal's Spring Boot.

All you have to do is open a command line, make current working directory the root of the startup-cdi repository. 
Run the command:
`mvn wildfly-swarm:run`

The command should output something like the following:


    ...
    ...
    2017-04-24 13:58:04,968 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0006: Undertow HTTP listener default listening on [0:0:0:0:0:0:0:0]:8080
    2017-04-24 13:58:05,082 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Swarm 2017.4.0 (WildFly Core 2.2.1.Final) started in 1328ms - Started 132 of 145 services (27 services are lazy, passive or on-demand)
    2017-04-24 13:58:05,815 INFO  [org.wildfly.swarm.runtime.deployer] (main) deploying startup-cdi.war
    2017-04-24 13:58:05,839 INFO  [org.jboss.as.server.deployment] (MSC service thread 1-2) WFLYSRV0027: Starting deployment of "startup-cdi.war" (runtime-name: "startup-cdi.war")
    2017-04-24 13:58:06,861 WARN  [org.jboss.as.dependency.private] (MSC service thread 1-7) WFLYSRV0018: Deployment "deployment.startup-cdi.war" is using a private module ("org.jboss.jts:main") which may be changed or removed in future versions without notice.
    2017-04-24 13:58:06,884 INFO  [org.jboss.weld.deployer] (MSC service thread 1-3) WFLYWELD0003: Processing weld deployment startup-cdi.war
    2017-04-24 13:58:07,386 INFO  [org.hibernate.validator.internal.util.Version] (MSC service thread 1-3) HV000001: Hibernate Validator 5.2.4.Final
    2017-04-24 13:58:07,441 INFO  [org.jboss.as.ejb3.deployment] (MSC service thread 1-3) WFLYEJB0473: JNDI bindings for session bean named 'EJBStartupSingletonBean' in deployment unit 'deployment "startup-cdi.war"' are as follows:
    
        java:global/startup-cdi/EJBStartupSingletonBean!io.acari.EJBStartupSingletonBean
        java:app/startup-cdi/EJBStartupSingletonBean!io.acari.EJBStartupSingletonBean
        java:module/EJBStartupSingletonBean!io.acari.EJBStartupSingletonBean
        java:global/startup-cdi/EJBStartupSingletonBean
        java:app/startup-cdi/EJBStartupSingletonBean
        java:module/EJBStartupSingletonBean
    
    2017-04-24 13:58:07,556 INFO  [org.jboss.weld.Version] (MSC service thread 1-5) WELD-000900: 2.3.5 (Final)
    2017-04-24 13:58:07,571 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-6) WFLYUT0018: Host default-host starting
    2017-04-24 13:58:07,989 ERROR [stderr] (ServerService Thread Pool -- 11) EJB Singleton Bean Doing Startup Work!
    2017-04-24 13:58:08,079 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 11) WFLYUT0021: Registered web context: /
    2017-04-24 13:58:08,096 INFO  [org.jboss.as.server] (main) WFLYSRV0010: Deployed "startup-cdi.war" (runtime-name : "startup-cdi.war")
    2017-04-24 13:58:08,099 INFO  [org.wildfly.swarm] (main) WFSWARM99999: WildFly Swarm is Ready

Where `2017-04-24 13:58:07,989 ERROR [stderr] (ServerService Thread Pool -- 11) EJB Singleton Bean Doing Startup Work!` was outputted to standard error (to help distinguish it in the command prompt). This tells us that our Singleton Bean was created on application startup and was able to do work!

When you give the proccess SIGKILL `CTRL+C` you should get this:

    ...
    ....
    2017-04-24 13:58:08,096 INFO  [org.jboss.as.server] (main) WFLYSRV0010: Deployed "startup-cdi.war" (runtime-name : "startup-cdi.war")
    2017-04-24 13:58:08,099 INFO  [org.wildfly.swarm] (main) WFSWARM99999: WildFly Swarm is Ready
    ^C2017-04-24 14:02:29,458 INFO  [org.wildfly.swarm] (Thread-3) WFSWARM0027: Shutdown requested
    2017-04-24 14:02:29,461 INFO  [org.jboss.as.server] (Thread-4) WFLYSRV0220: Server shutdown has been requested via an OS signal
    2017-04-24 14:02:29,502 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 26) WFLYUT0022: Unregistered web context: /
    2017-04-24 14:02:29,504 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0008: Undertow HTTP listener default suspending
    2017-04-24 14:02:29,505 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0007: Undertow HTTP listener default stopped, was bound to [0:0:0:0:0:0:0:0]:8080
    2017-04-24 14:02:29,512 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-8) WFLYUT0019: Host default-host stopping
    2017-04-24 14:02:29,512 ERROR [stderr] (ServerService Thread Pool -- 26) EJB Singleton Bean Doing Cleanup Work before shutdown!
    2017-04-24 14:02:29,517 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-5) WFLYUT0004: Undertow 1.4.11.Final stopping
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time: 04:34 min
    [INFO] Finished at: 2017-04-24T14:02:29-05:00

It can be seen that the busy beans `@PreDestroy` method was invoked and it cleaned up after itself from this line: `2017-04-24 14:02:29,512 ERROR [stderr] (ServerService Thread Pool -- 26) EJB Singleton Bean Doing Cleanup Work before shutdown! `
Again was outputted to standard error to help distinguish it in the command prompt.