---
layout: post
title: Java Objects to and from a File
headerImage: beans/beans-to-file.png
---

There will come a time when the need arises to have Java objects persist without the use of a relational or NoSQL database.
Simply put, reading and writing an object to a local file.
Let us explore how this can be accomplished and find some reason this is helpful in the first place.

#### What can expected from this post:
1. How to read and write Serializable objects to a file.
1. How to read and write Non-Serializable objects to a file.
1. Why would we want to read and write objects to a file.

**Writing Serializable objects to a file.**

The first thing that is needed is an object to write to a file. 
It will need to implement the `java.io.Serializable` or `java.io.Externalizable` interface.
For more information about serializable objects, checkout [this post on java serialization performance!]({% post_url 2017-05-01-Hazelcast-Performance-Serialization %})

Here is the how.

{% highlight java %}
package io.acari;

import io.acari.pojo.ExternalizableProgrammer;
import io.acari.pojo.Programmer;
import io.acari.repositories.ProgrammerRepository;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.LinkedList;
import java.util.List;
import java.util.stream.Stream;

public class Main {

    public static void main(String[] args) throws IOException {
        ProgrammerRepository programmerRepository = ProgrammerRepository.newProgrammerRepository();
        readWriteObject(programmerRepository.getProgrammers(), Programmer.class);
        readWriteObject(programmerRepository.getProgrammers().map(ExternalizableProgrammer::new), ExternalizableProgrammer.class);
    }

    /**
     * Takes a stream of objects and writes and reads from a file
     * created in the directory the main method is executed in.
     * <p>
     * Creates a file named after the class provided's simple name
     * post-fixed by .data
     *
     * @param objectStream a open stream of objects to be serialized.
     * @param tClass       Class of the object of the to be serialized
     * @param <T>          Any class that extends Serializable
     * @throws IOException if user has unsufficent privledges to write in
     *                     current working directory.
     */
    private static <T extends Serializable> void readWriteObject(Stream<T> objectStream, Class<T> tClass) throws IOException {
        String simpleName = tClass.getSimpleName();
        Path fileToWrite = Paths.get(simpleName + ".data");
        //Create File (if needed) to write to.
        if (Files.notExists(fileToWrite)) {
            Files.createFile(fileToWrite);
        }

        //Write stream of objects to file.
        try (ObjectOutputStream out = new ObjectOutputStream(
                Files.newOutputStream(fileToWrite, StandardOpenOption.TRUNCATE_EXISTING))) {
            objectStream.forEach(object -> {
                try {
                    out.writeObject(object);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
        }

        //Read objects from file.
        try (ObjectInputStream in = new ObjectInputStream(Files.newInputStream(fileToWrite, StandardOpenOption.READ))) {
            List<T> programmers = new LinkedList<>();
            try {
                while (true) {
                    programmers.add((T) in.readObject());
                }
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            } catch (EOFException ignored) {
                /**
                 * Reached the end of the file.
                 * No more objects to read
                 */
            }
            System.out.format("%d %s read from file!\n", programmers.size(), simpleName);
        }
    }
}
{% endhighlight %}

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

Before delving into the why of writing objects to a file, it would be nice to mention some more concrete persistence APIs.

As relation databases go there are many to choose from, here is a small sample:

- [MySQL](https://www.mysql.com/)
- [PostgreSQL](https://www.postgresql.org/about/)
- [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-2016)

On the other hand, there are also quite a few NoSQL databases to choose from as well.
The primary difference between SQL and NoSQL databases is that there is no relational setup between objects stored in NoSQL databases.
Items in a NoSQL database are stored as Key-Value pairs. 
Here is a small subset of NoSQL databases:

- [MongoDB](https://www.mongodb.com/what-is-mongodb)
- [Redis](https://redis.io/topics/introduction)
- [Cassandra](http://cassandra.apache.org/)
