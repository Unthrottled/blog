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
package acari.io.pojo;

import java.io.Serializable;
import java.util.List;

public class Programmer implements Serializable {
    private static final long serialVersionUID = 7026171646349890369L;
    private final String name;
    private final int age;
    private final Computer computer;
    private final List<String> languages;

    public Programmer(String name, int age, Computer computer, List<String> languages) {
        this.name = name;
        this.age = age;
        this.computer = computer;
        this.languages = languages;
    }
    
    //ACCESSOR METHODS OMITTED
}


{% endhighlight %}


{% highlight java %}
package acari.io.pojo;

import java.io.Serializable;

public class Computer implements Serializable {
    private static final long serialVersionUID = -2198928914280590576L;
    private final String model;
    private final String subModel;
    private final int ram;
    private final String make;

    public Computer(int ram, String make, String model, String subModel) {
        this.model = model;
        this.subModel = subModel;
        this.ram = ram;
        this.make = make;
    }

    //ACCESSOR METHODS OMITTED
}


{% endhighlight %}

>All of the metrics where gathered on a Razer Blade Stealth Ultrabook, 7th Generation Intel Core i7, running Ubuntu 16.04. As a forewarning, I learned about benchmarking frameworks, such as [JMH](http://openjdk.java.net/projects/code-tools/jmh/) after writing the example code base for this post.

Given these classes, writing 40000 Programmers ten times took an average of 243.1 milliseconds. 
While reading 40000 Programmers ten times took an average of 432.6 milliseconds.
This shows that, out of the box, read heavy use-cases of Hazelcast will a bit slower than write heavy applications.

There is a non-Hazelcast dependent optimization for the object serialization process.
This means that work done to code will remain portable to other cache implementations.
Implementing the `Externalizable` interface will allow java to use overridden methods in each pojo to serialize and deserialize objects.
Preventing the need for classes to be created from reflection, but adds the need for extra work.

Here are the new Externalizable pojos:

{% highlight java %}
package acari.io.pojo;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;
import java.util.ArrayList;
import java.util.List;

public class ExternalizableProgrammer implements Externalizable {
    private static final long serialVersionUID = 6757860161913660513L;
    private String name;
    private int age;
    private ExternalizableComputer computer;
    private List<String> languages;

    public ExternalizableProgrammer() {
    }

    public ExternalizableProgrammer(Programmer programmer) {
        this.name = programmer.getName();
        this.age = programmer.getAge();
        this.computer = new ExternalizableComputer(programmer.getComputer());
        this.languages = programmer.getLanguages();
    }

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeUTF(name);
        out.writeInt(age);
        int size = languages == null ? -1 : languages.size();
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
        if (size > -1) {
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

{% highlight java %}
package acari.io.pojo;

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

    public ExternalizableComputer() {
    }

    public ExternalizableComputer(Computer computer) {
        this.model = computer.getModel();
        this.subModel = computer.getSubModel();
        this.ram = computer.getRam();
        this.make = computer.getMake();
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