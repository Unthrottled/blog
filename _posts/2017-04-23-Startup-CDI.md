---
layout: post
title:  "Startup JavaBeans"
date:   2017-4-23
categories: java
---
Are you in charge of developing or maintaining a stateful web application with the Java EE API? Do you want some set of events to be triggered on your applications startup and shutdown? 
If you answered yes to any of these questions, then this post should help!
There are a lot of cool things that we can do with the Java EE API in our manage web containers. Of those things, is creating a Singleton Enterprise Java Bean. An Enterprise Java Bean is an object that is persisted within the web application container for the duration of its context. Think of them as objects that we want in our classes to do meaning full work and how we get the instance of the class is provided by the underlying framework. A Singleton is the only instance of a class that will exist within the application life cycle. 
Singletons are a great pattern to help solve the use case of bootstrapping our stateful application. Only one object is really needed, because you application only starts up and shuts down once. The Startup Singleton's job will bet to do meaningful work after it has been instantiated. Its instantiation should also happen on or after a successful deployment and not when a user first interacts with the application. By default EJBs are lazily instantiated, meaning that they are created only when needed. There ar a couple of ways to trigger the Startup Singleton's instantiation so it can set up the applications state.
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
If we want to use the EJB singleton provided by the Java EE API then all we have to do is the following:
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
I have defined a class called EJBStartupSingletonBean and annotated it with the `@Singelton` annotation. Which means that this java bean will be created by the web application container and only one will ever be in existance. I also added the `@Lock` annotation. This is more of a best practice that I wanted to demonstrate. The annotation provides the functionally of have only one thread to have access to any of the singleton's public methods, to which the above example has none.
The `@Startup` is the money annotation. This tells the framework that at the start of the application the Singleton will be instantiated. When the instance is instantiated the method annotated with `@PostConstruct` will be invoked. 
This is where you can put your code to set up the state of the application. When the application is shutdown the method annotated with `@PreDestroy` will be invoked allowing for any clean up.
As a forewarning, annotating an _Application Scoped_ bean with the `@Startup` annotation will **NOT** cause an instance of that class to be created at startup.
I have provided an functional sample for those who are so inclined.
To run the sample you will need:
 - Internet Connection (At least the first time it is run)
 - Java 8 runtime
 - Maven 3.x.x
It can be reached at : 
[https://github.com/cyclic-reference/startup-cdi](https://github.com/cyclic-reference/startup-cdi)
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
Where `2017-04-24 13:58:07,989 ERROR [stderr] (ServerService Thread Pool -- 11) EJB Singleton Bean Doing Startup Work!` was outputted to standard error (to help distinguish it in the command prompt) when the `@PreDestroy` method was invoked on the Startup Singleton bean. This tells us that our Singleton Bean was created on application startup and was able to do work!
When you give the process SIGINT `CTRL+C` you should get this:
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
That is  the easiest way to get a Startup Singleton bean. However, we also have the `javax.inject.Singleton` which almost works like `java.ejb.Singleton`. Both produce singletons, however `javax.inject.Singleton` does not work with `@javax.ejb.Startup`.
If we really need the `javax.inject.Singleton`, we have to jump through a few more hoops. 
The Singleton Class look just about the same:
{% highlight java  %}
package io.acari;
import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.ejb.Startup;
import javax.inject.Singleton;
@Startup
@Singleton
public class EnterpriseStartupSingletonBean {
    @PostConstruct
    void initialize(){
        System.err.println("Enterprise Singleton Bean Doing Startup Work!");
    }
    @PreDestroy
    void shutdown(){
        System.err.println("Enterprise Singleton Bean Doing Cleanup Work before shutdown!");
    }
    @Override
    public String toString() {
        return "EnterpriseStartupSingletonBean";
    }
}
{% endhighlight %}
Looks almost the same. Except for the `import javax.inject.Singleton;` and overriding the `toString()` method.
The next thing needed is really obscure. An implementation of a Service Provider Interface (SPI) is necessary. This class will listen to the application container's life-cycle events. 
The events that are relevant for this use case is the `processBean` and `AfterDeploymentValidation` events.
The process bean event is fired for every defined JavaBean in the classpath. The AfterDeploymentValidation event is (as you can probably guess) fired after your artifact has been successfully deployed.
The class looks like this:
{% highlight java  %}
package io.acari;
import javax.ejb.Startup;
import javax.enterprise.context.spi.CreationalContext;
import javax.enterprise.event.Observes;
import javax.enterprise.inject.spi.*;
import java.util.LinkedHashSet;
import java.util.Set;
public class StartupServiceProvider implements Extension {
    private final Set<Bean<?>> startupBeans = new LinkedHashSet<>();
    <T> void onBeanProcess(@Observes ProcessBean<T> processBeanEvent, BeanManager beanManager){
        if(processBeanEvent.getAnnotated().isAnnotationPresent(Startup.class)){
            startupBeans.add(processBeanEvent.getBean());
        }
    }
    void onApplicationDeploymentValidation(@Observes AfterDeploymentValidation afterDeploymentValidationEvent,
                                           BeanManager beanManager){
        startupBeans.forEach(bean -> {
            CreationalContext<?> creationalContext = beanManager.createCreationalContext(bean);
            Object startupBeanReference = beanManager.getReference(bean,
                    bean.getBeanClass(), creationalContext);
            System.err.println(startupBeanReference.toString() + " has been jump started!");
        });
    }
}
{% endhighlight %}
The main goal of this class is to collect all of the JavaBeans which have the annotation `@Startup` and invoke them after the application is started up. We invoke them by calling the `toString()` method to force the creation of the bean.
**Note:** the way it is written now, it will create Singleton, Application Scoped, Request Scoped, and any other JavaBeans.
Finally, we need to register SPI with the application server, this can be done by creating a file called `javax.enterprise.inject.spi.Extension` with the fully qualified class name of our SPI. For the case of the example it will just contain `io.acari.StartupServiceProvider`.
The file needs to live in the webapp/META-INF/services/ directory of the archive.
I have created a fully functioning example at: [https://github.com/cyclic-reference/startup-enterprise-cdi](https://github.com/cyclic-reference/startup-enterprise-cdi)
I wanted to use Swarm, but am not willing to spend the time to figure out how to integrate. 
So to prevent you from having to download and install a Wildfly web server on your machine, I am just going to get a put the example in a Docker container hosted on Docker Hub.
Things you will need on your machine:
 - The latest version of [Docker](https://www.docker.com/community-edition)
 - One Internet
Once you have your Docker host installed. Open up a command prompt. Run the command `sudo docker pull alexsimons/startup-cdi`. This pulls in the image I have created for your convenience.
Once the command completes an the docker image is on your host all you have to do is run the container and attach it to see the output of the busy bean.
Which can be accomplished by `sudo docker run --rm --name=cdi -it alexsimons/startup-cdi`. Here we have a named container of "cdi" and we told docker to attach to the running processes to a [TTY](http://www.abouttty.com/) so we can see the output. The `--rm` flag tells docker to remove the Docker container after the Docker container has stoped 
 
Which should look a bit like this:
 
     ....
     ....
     20:12:18,254 INFO  [org.infinispan.configuration.cache.EvictionConfigurationBuilder] (ServerService Thread Pool -- 62) ISPN000152: Passivation configured without an eviction policy being selected. Only manually evicted entities will be passivated.
     20:12:18,257 INFO  [org.infinispan.configuration.cache.EvictionConfigurationBuilder] (ServerService Thread Pool -- 62) ISPN000152: Passivation configured without an eviction policy being selected. Only manually evicted entities will be passivated.
     20:12:18,316 INFO  [org.jboss.ws.common.management] (MSC service thread 1-2) JBWS022052: Starting JBossWS 5.1.5.Final (Apache CXF 3.1.6) 
     20:12:18,642 INFO  [org.jboss.weld.deployer] (MSC service thread 1-5) WFLYWELD0003: Processing weld deployment startup-enterprise-cdi.war
     20:12:18,697 INFO  [org.hibernate.validator.internal.util.Version] (MSC service thread 1-5) HV000001: Hibernate Validator 5.2.4.Final
     20:12:18,884 INFO  [org.jboss.weld.Version] (MSC service thread 1-2) WELD-000900: 2.3.5 (Final)
     20:12:19,524 ERROR [stderr] (MSC service thread 1-1) Enterprise Singleton Bean Doing Startup Work!
     20:12:19,527 ERROR [stderr] (MSC service thread 1-1) EnterpriseStartupSingletonBean has been jump started!
     20:12:19,662 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 62) WFLYUT0021: Registered web context: /startup-enterprise-cdi
     20:12:19,693 INFO  [org.jboss.as.server] (ServerService Thread Pool -- 34) WFLYSRV0010: Deployed "startup-enterprise-cdi.war" (runtime-name : "startup-enterprise-cdi.war")
     20:12:19,796 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0060: Http management interface listening on http://127.0.0.1:9990/management
     20:12:19,797 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0051: Admin console listening on http://127.0.0.1:9990
     20:12:19,797 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Full 10.1.0.Final (WildFly Core 2.2.0.Final) started in 4177ms - Started 425 of 673 services (404 services are lazy, passive or on-demand)
The two line we care about are 
            
    20:12:19,524 ERROR [stderr] (MSC service thread 1-1) Enterprise Singleton Bean Doing Startup Work!
    20:12:19,527 ERROR [stderr] (MSC service thread 1-1) EnterpriseStartupSingletonBean has been jump started!
The first line is the output `@PostConstruct` method of the singleton. 
The second line is the output of the SPI implementation telling us that it gave that bean a kick in the pants and got in up and running.
When you give the process SIGINT `CTRL+C` you should get this:
    ....
    ....
    20:12:19,797 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Full 10.1.0.Final (WildFly Core 2.2.0.Final) started in 4177ms - Started 425 of 673 services (404 services are lazy, passive or on-demand)
    ^C*** JBossAS process (57) received INT signal ***
    20:13:18,704 INFO  [org.jboss.as.server] (Thread-2) WFLYSRV0220: Server shutdown has been requested via an OS signal
    20:13:18,748 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 67) WFLYUT0022: Unregistered web context: /startup-enterprise-cdi
    20:13:18,752 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-3) WFLYUT0019: Host default-host stopping
    20:13:18,757 ERROR [stderr] (MSC service thread 1-7) Enterprise Singleton Bean Doing Cleanup Work before shutdown!
    20:13:18,766 INFO  [org.jboss.as.connector.subsystems.datasources] (MSC service thread 1-2) WFLYJCA0010: Unbound data source [java:jboss/datasources/ExampleDS]
    20:13:18,770 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0008: Undertow HTTP listener default suspending
    20:13:18,771 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0007: Undertow HTTP listener default stopped, was bound to 0.0.0.0:8080
    20:13:18,771 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0008: Undertow HTTPS listener https suspending
    20:13:18,772 INFO  [org.jboss.as.server.deployment] (MSC service thread 1-5) WFLYSRV0028: Stopped deployment startup-enterprise-cdi.war (runtime-name: startup-enterprise-cdi.war) in 60ms
    20:13:18,772 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-2) WFLYUT0007: Undertow HTTPS listener https stopped, was bound to 0.0.0.0:8443
    20:13:18,772 INFO  [org.wildfly.extension.undertow] (MSC service thread 1-5) WFLYUT0004: Undertow 1.4.0.Final stopping
    20:13:18,776 INFO  [org.jboss.as.connector.deployers.jdbc] (MSC service thread 1-2) WFLYJCA0019: Stopped Driver service with driver-name = h2
    20:13:18,781 INFO  [org.jboss.as] (MSC service thread 1-2) WFLYSRV0050: WildFly Full 10.1.0.Final (WildFly Core 2.2.0.Final) stopped in 51ms
    *** JBossAS process (57) received TERM signal ***
Where `20:13:18,757 ERROR [stderr] (MSC service thread 1-7) Enterprise Singleton Bean Doing Cleanup Work before shutdown!` was outputted to standard error (to help distinguish it in the command prompt) when the `@PreDestroy` method was invoked on the Startup Singleton bean. This tells us that our Singleton Bean was created on application startup and was able to do work!
#### Resources:
---
- Gupta, Arun. Java EE 7 Essentials:. Beijing: O'Reilly, 2013. Print. Chapter 9
- [http://wildfly-swarm.io/generator/](http://wildfly-swarm.io/generator/)