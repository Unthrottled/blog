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
compile 'javax:javaee-api:7.0' //can be version 6 or 7
{% endhighlight %}