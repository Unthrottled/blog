---
layout: post
title:  "Boosted Hazelcast"
categories: java
headerImage: cereal/rail.jpg
---

Do not be deceived, as distributed caches go, vanilla Hazelcast has really quick response times. 
However, there are some nob, buttons, and levers that can be pushed, pulled, and pulled to make responses even quicker!

Hazelcast, being a distributed in-memory data-grid, has to be able to store and send objects over networks. 
Meaning that all items put into a hazelcast instance must be stored in a byte array.
The coressponding byte array is is able to be sent across networks and shared with other nodes in the cluster.
This allows all  nodes in a given cluster to share information. 

The process of converting of a Java object int a byte array (or anything really such as XML) is called _Serialization_.
In Java, to make a java object serializable, all it has to do is implement serializable.

{% highlight java %}

package io.acari;

import java.io.Serializable;

public class BestClass implements Serializable {
    private static final long serialVersionUID = 9001L;
}

{% endhighlight %}

That is all that has to be done to have any plain old Java object (pojo) stored in any of Hazelcast's distributed data structures.
Following this branch of object serialization, reflection is used to both serialize (encode to binary) and deserialize (decode from binary) pojos.
This means, for serialization, that all fields of the pojo are written in to byte arrays via iterating over them via reflection. 
Deserializaion requires the pojo to have an empty constructor so that the class may be created and all of non-transient fields filled via reflection.

Lets take a look at an example.

Suppose we have the two following pojos.


{% highlight java %}
package io.acari.pojo;

import java.io.Serializable;
import java.util.List;

public class Programmer implements Serializable {
    private static final long serialVersionUID = 7026171646349890369L;
    private final String name;
    private final int age;
    private final Computer computer;
    private final List<String> languages;
    
    //ACCESSOR METHODS OMITTED
}


{% endhighlight %}


{% highlight java %}
package io.acari.pojo;

import java.io.Serializable;

public class Computer implements Serializable {
    private static final long serialVersionUID = -2198928914280590576L;
    private final String model;
    private final String subModel;
    private final int ram;
    private final String make;

    //ACCESSOR METHODS OMITTED
}


{% endhighlight %}

>All of the metrics where gathered on a Razer Blade Stealth Ultrabook, 7th Generation Intel Core i7, running Ubuntu 16.04. As a forewarning, I learned about benchmarking frameworks, such as [JMH](http://openjdk.java.net/projects/code-tools/jmh/) after writing the example code base for this post.

Given these classes, writing 40000 Programmers ten times took an average of ~243 milliseconds. 
While reading 40000 Programmers ten times took an average of ~433 milliseconds.
This shows that, out of the box, read heavy use-cases of Hazelcast will a bit slower than write heavy applications.

There is a non-Hazelcast dependent optimization for the object serialization process.
This means that work done to code will remain portable to other cache implementations.
Implementing the `Externalizable` interface will allow java to use overridden methods in each pojo to serialize and deserialize objects.
Preventing the need for classes to be created from reflection, but adds the need for extra work.

Here are the new Externalizable pojos:

{% highlight java %}
package io.acari.pojo;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;
import java.util.ArrayList;
import java.util.List;

public class ExternalizableProgrammer implements Externalizable {
    private static final long serialVersionUID = 6757860161913660513L;
    public static final int NULL_LIST = -1;
    private String name;
    private int age;
    private ExternalizableComputer computer;
    private List<String> languages;

    /**
     * No Arguments constructor is needed only if
     * the class does not have one and a constructor
     * with one or more arguments is present.
     * <p>
     * If no constructors are provided the java compiler
     * will automagically put the no args constructor in.
     */
    public ExternalizableProgrammer() {
    }

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeUTF(name);
        out.writeInt(age);
        int size = languages == null ? NULL_LIST : languages.size();
        out.writeInt(size);

        for (int i = 0; i < size; ++i) {
            out.writeUTF(languages.get(i));
        }
        computer.writeExternal(out);
    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        name = in.readUTF();
        age = in.readInt();
        int size = in.readInt();
        if (size > NULL_LIST) {
            languages = new ArrayList<>(size);
            for (int i = 0; i < size; ++i) {
                languages.add(i, in.readUTF());
            }
        }
        computer = new ExternalizableComputer();
        computer.readExternal(in);
    }
    
    //ACCESSOR METHODS OMITTED

}
{% endhighlight %}

The first thing that catches the eye, is the fact that the list is iterated through, in favor of calling the slower `writeObject` and `readObject` of th ObjectOutput's and ObjectInput's API respectively.
In the `readExternal` method, it can be seen that the convenient reflective creation of the Computer field was overridden by manual creation.
This saves time, but is a few extra lines of code.

{% highlight java %}
package io.acari.pojo;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

public class ExternalizableComputer implements Externalizable {
    private static final long serialVersionUID = -6235153548793669030L;
    private String model;
    private String subModel;
    private int ram;
    private String make;

    /**
     * No Arguments constructor is needed only if
     * the class does not have one and a constructor
     * with one or more arguments is present.
     * <p>
     * If no constructors are provided the java compiler
     * will automagically put the no args constructor in.
     */
    public ExternalizableComputer() {
    }

    @Override
    public void writeExternal(ObjectOutput objectOutput) throws IOException {
        objectOutput.writeUTF(model);
        objectOutput.writeUTF(subModel);
        objectOutput.writeInt(ram);
        objectOutput.writeUTF(make);
    }

    @Override
    public void readExternal(ObjectInput objectInput) throws IOException, ClassNotFoundException {
        model = objectInput.readUTF();
        subModel = objectInput.readUTF();
        ram = objectInput.readInt();
        make = objectInput.readUTF();
    }
    
    //ACCESSOR METHODS OMMITTED
}

{% endhighlight %}

All the extra work payed off in the end.
Writing 40000 externalizable programmers ten times yielded an average of ~164 milliseconds.
While reading 40000 externalizable programmers ten iterations gave an average of ~126 milliseconds.
That is a savings of ~80 ms writing object into memory and a ~300ms drop in wait time while reading!

While this work could possibly be transferred to other applications, which require object serialization, there are even _faster_ Hazelcast specific options!

The first example is the DataSerializable interface, which is looks a whole lot like the Externalizable interface.

Here are the new pojos:

{% highlight java %}
package io.acari.pojo;

import com.hazelcast.nio.ObjectDataInput;
import com.hazelcast.nio.ObjectDataOutput;
import com.hazelcast.nio.serialization.DataSerializable;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class DataSerializableProgrammer implements DataSerializable {
    public static final int NULL_LIST = -1;
    private String name;
    private int age;
    private DataSerializableComputer computer;
    private List<String> languages;

    /**
     * No Arguments constructor is needed only if
     * the class does not have one and a constructor
     * with one or more arguments is present.
     * <p>
     * If no constructors are provided the java compiler
     * will automagically put the no args constructor in.
     */
    public DataSerializableProgrammer() {
    }

    @Override
    public void writeData(ObjectDataOutput out) throws IOException {
        out.writeUTF(name);
        out.writeInt(age);
        int size = languages == null ? NULL_LIST : languages.size();
        out.writeInt(size);
        for (int i = 0; i < size; ++i) {
            out.writeUTF(languages.get(i));
        }
        computer.writeData(out);
    }

    @Override
    public void readData(ObjectDataInput in) throws IOException {
        name = in.readUTF();
        age = in.readInt();
        int size = in.readInt();
        if (size > NULL_LIST) {
            languages = new ArrayList<>(size);
            for (int i = 0; i < size; ++i) {
                languages.add(i, in.readUTF());
            }
        }
        computer = new DataSerializableComputer();
        computer.readData(in);
    }
    //ACCESSOR METHODS OMITTED
  }
    
}
{% endhighlight %}

There is only one big difference from the externalizable class is the switch from `java.io.ObjectInput` and `java.io.ObjectOutput` to `com.hazelcast.nio.ObjectDataInput` and `com.hazelcast.nio.ObjectDataOutput` respectively.

Hazelcast already has an optimized convience method for reading and writing the `ArrayList` class called `com.hazelcast.internal.serialization.impl.ArrayListStreamSerializer`.
That class does what the `writeData` and `readData` of `DataSerializableProgrammer` does for the `ArrayList`, but encapsulates it into the `out.writeObject(list)` and `in.readObject` does respectively.
However using the readObject _and_  writeObject methods come at a performance cost of ~20ms. 

Just about the same goes for the DataSerializable Computer class as well.

{% highlight java %}
package io.acari.pojo;

import com.hazelcast.nio.ObjectDataInput;
import com.hazelcast.nio.ObjectDataOutput;
import com.hazelcast.nio.serialization.DataSerializable;

import java.io.IOException;

public class DataSerializableComputer implements DataSerializable {
    private String model;
    private String subModel;
    private int ram;
    private String make;

    /**
     * No Arguments constructor is needed only if
     * the class does not have one and a constructor
     * with one or more arguments is present.
     * <p>
     * If no constructors are provided the java compiler
     * will automagically put the no args constructor in.
     */
    public DataSerializableComputer() {
    }

    @Override
    public void writeData(ObjectDataOutput out) throws IOException {
        out.writeUTF(model);
        out.writeUTF(subModel);
        out.writeInt(ram);
        out.writeUTF(make);
    }

    @Override
    public void readData(ObjectDataInput in) throws IOException {
        model = in.readUTF();
        subModel = in.readUTF();
        ram = in.readInt();
        make = in.readUTF();
    }
    //ACCESSOR METHODS OMITTED
}

{% endhighlight %}

The numbers are in and they look good!
Writing 40000 DataSerializable Programmers ten iterations took an average of ~128 milliseconds, a savings of ~36ms.
Reading 40000 Data Serializable Programmers ten times took averaged of a total operation time of ~83 milliseconds! 
That is 43ms quicker than the already ~306ms cheaper Externalizable read!

Since the Externalizable class, the `Computer` instance has not been provided by reflection.
There is one last bit of slower reflection that can be dropped, which is the creation of the `Programmer` instance.
The Hazelcast specific `IdentifiedDataSerializable` interface is that such method.

Which looks like the following.

{% highlight java %}
package io.acari.pojo;

import com.hazelcast.nio.serialization.IdentifiedDataSerializable;

public class IdentifiedDataSerializableProgrammer extends DataSerializableProgrammer implements IdentifiedDataSerializable {

    public static final int FACTORY_ID = 9000;
    public static final int OBJECT_ID = 9001;

    /**
     * No Arguments constructor is needed only if
     * the class does not have one and a constructor
     * with one or more arguments is present.
     * <p>
     * If no constructors are provided the java compiler
     * will automagically put the no args constructor in.
     */
    public IdentifiedDataSerializableProgrammer() {
        super();
    }

    public IdentifiedDataSerializableProgrammer(Programmer programmer) {
        super(programmer);
    }

    @Override
    public int getFactoryId() {
        return FACTORY_ID;
    }

    @Override
    public int getId() {
        return OBJECT_ID;
    }
}
{% endhighlight %}

IdentifiedDataSerializable extends DataSerializable adding the getFactoryId and getId, which will be used by the `DataSerializableFactory`.
Whose functional API accepts an ID in the form of an integer and returns an instance whose class is associated with that integer.

`IdentifiedDataSerializableProgrammer` needs to have a factory with an ID of nine-thousand configured in the Hazelcast server. 
 In addition that factory must return an instance of `IdentifiedDataSerializableProgrammer` when given an integer that is over nine-thousand.
 This allows for one factory to create multiple instances of different classes.
 As emphasis,IdentifiedDataSerializableProgrammer inherts from DataSerializableProgrammer which creates its own the _DataSerializableComputer_ at deserialization time.
 Therefore eliminating the need for IdentifiedDataSerializableComputer!
 
 If Spring detects Hazelcast on the classpath, it will try to auto-configure a Hazelcast server instance.
 Given a `com.hazelcast.config.Config` bean, Spring will use that bean for the creation of Hazelcast instance.
 Below is an example of the very thing.
 
{% highlight java%}
package io.acari;

import io.acari.pojo.IdentifiedDataSerializableProgrammer;
import com.hazelcast.config.ClasspathXmlConfig;
import com.hazelcast.config.Config;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class HazelcastConfig {

    @Bean
    public Config config() {
        Config serverConfig = new ClasspathXmlConfig("hazelcast.xml");
        serverConfig.getSerializationConfig().addDataSerializableFactory(IdentifiedDataSerializableProgrammer.FACTORY_ID,
                i -> {
                    switch (i) {
                        case IdentifiedDataSerializableProgrammer.OBJECT_ID:
                            return new IdentifiedDataSerializableProgrammer();
                        default:
                            return null;
                    }
                });
        return serverConfig;
    }
}
{% endhighlight%}

A Hazelcast xml configuration file is loaded from the classpath (can be found in the src/main/resources directory).
Once the configuration file is loaded, a DataSerializeableFactory of id 9000 is added, with a lambda acting as the implementation, which returns a IdentifiedDataSerializableProgrammer when given 9001 and null for all other cases. 
Side skirting the need for a concrete implementation of the interface.

The same thing can also be accomplished if the Hazelcast Server is not running on the same process as the application that consumes it.
A Hazelcast client can be created with a DataSerializableFactory.

The snippet below demonstrates the following requirement (assuming that a hazelcast-client.xml is in the classpath and the server tries to connect to is running):
 
 {% highlight java %}
   //...
   ClientConfig clientConfig = new XmlClientConfigBuilder("hazelcast-client.xml").build();
   clientConfig.getSerializationConfig().addDataSerializableFactory(IdentifiedDataSerializableProgrammer.FACTORY_ID,
         i -> {
             switch (i) {
                 case IdentifiedDataSerializableProgrammer.OBJECT_ID:
                     return new IdentifiedDataSerializableProgrammer();
                 default:
                     return null;
             }
         });
   HazelcastInstance hz = HazelcastClient.newHazelcastClient(clientConfig);
//...
 {% endhighlight %}    
 
 The following is a graph showing the performance summaries of all the interfaces disscussed.
 
 ![graph.jpg]({{site.imageDir}}cereal/times.png)
 
 There are a few other options that can be done toward object serialization and Hazelcast.
 However they are not as performant as the last two discussed, so I will provide a [link to my resource for this post.](http://docplayer.net/35092370-Webinar-maximizing-hazelcast-performance-with-serialization.html)
 There all the options are explored by one of the founders of Hazelcast, who knows a lot more on the topic than I do!
 
Finally, I have created a Spring-Boot project consisting of almost all of the examples provided in this post.
It has time trial tests for both a Hazelcast server and a Client connected to a vanilla Hazelcast server.

The link to the respository is as follows [https://github.com/cyclic-reference/hazelcast-serialization](https://github.com/cyclic-reference/hazelcast-serialization)

To run the sample you will need:
 - Internet Connection (At least the first time it is run)
 - [Java 8 runtime](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
 - [Gradle 2.3+ ](https://gradle.org/install)
 
Once the repository is on your machine, in order to boot up the server do the following.

1. Open up a command window and make the current working directory the root of the hazelcast-serialization repository
1. Run the command

        ./gradlew bootRun
        
The application will output a bunch of logs. Somewhere in there you should find the outputs of the time trials.

    ....
    ....
    2017-05-04 13:06:46.694  INFO 10982 --- [           main] io.acari.TimeTrial                       : Time trials ready for Hazelcast server ready to start!
    2017-05-04 13:06:46.730  INFO 10982 --- [onPool-worker-1] c.h.i.p.impl.PartitionStateManager       : [172.20.0.1]:9001 [dev] [3.8.1] Initializing cluster partition table arrangement...
    2017-05-04 13:06:53.897  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Regular Serializable  arguments 10 times took an average of 263.6 milliseconds.
    2017-05-04 13:06:53.898  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Regular Serializable  arguments 10 times took an average of 437.7 milliseconds.
    2017-05-04 13:06:56.691  INFO 10982 --- [ration.thread-0] c.h.i.p.impl.PartitionStateManager       : [127.0.0.1]:9009 [clientExample] [3.8.1] Initializing cluster partition table arrangement...
    2017-05-04 13:06:56.699  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Externalizable  arguments 10 times took an average of 140.1 milliseconds.
    2017-05-04 13:06:56.699  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Externalizable  arguments 10 times took an average of 125.1 milliseconds.
    2017-05-04 13:06:58.950  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Data Serializable  arguments 10 times took an average of 130.2 milliseconds.
    2017-05-04 13:06:58.951  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Data Serializable  arguments 10 times took an average of 82.0 milliseconds.
    2017-05-04 13:07:01.164  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Identified Data Serializable  arguments 10 times took an average of 127.4 milliseconds.
    2017-05-04 13:07:01.164  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Identified Data Serializable  arguments 10 times took an average of 78.7 milliseconds.
    2017-05-04 13:07:01.164  INFO 10982 --- [           main] io.acari.TimeTrial                       : Time trials for Hazelcast server finished!
    2017-05-04 13:07:01.164  INFO 10982 --- [           main] io.acari.TimeTrial                       : Time trials ready for Hazelcast client ready to start!
    2017-05-04 13:07:07.450  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Regular Serializable  arguments 10 times took an average of 218.7 milliseconds.
    2017-05-04 13:07:07.450  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Regular Serializable  arguments 10 times took an average of 397.4 milliseconds.
    2017-05-04 13:07:10.063  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Externalizable  arguments 10 times took an average of 129.5 milliseconds.
    2017-05-04 13:07:10.063  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Externalizable  arguments 10 times took an average of 116.7 milliseconds.
    2017-05-04 13:07:12.214  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Data Serializable  arguments 10 times took an average of 123.1 milliseconds.
    2017-05-04 13:07:12.215  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Data Serializable  arguments 10 times took an average of 80.2 milliseconds.
    2017-05-04 13:07:14.265  INFO 10982 --- [           main] io.acari.TimeTrial                       : Writing 40000 Identified Data Serializable  arguments 10 times took an average of 121.7 milliseconds.
    2017-05-04 13:07:14.265  INFO 10982 --- [           main] io.acari.TimeTrial                       : Reading 40000 Identified Data Serializable  arguments 10 times took an average of 72.2 milliseconds.
    2017-05-04 13:07:14.265  INFO 10982 --- [           main] io.acari.TimeTrial                       : Time trials for Hazelcast client finished!
    .....
    .....
    
Again, I now know that there are frameworks for benchmarking now. 
However that was after I spent time writing the sample project.

Enjoy!

## -Alex

####Resources you should totally checkout:

[http://docplayer.net/35092370-Webinar-maximizing-hazelcast-performance-with-serialization.html](http://docplayer.net/35092370-Webinar-maximizing-hazelcast-performance-with-serialization.html)