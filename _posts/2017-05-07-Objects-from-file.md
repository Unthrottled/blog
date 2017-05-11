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

The first thing that will be needed is an object to write to a file. 
It will need to implement the `java.io.Serializable` or `java.io.Externalizable` interface.
For more information about serializable objects, checkout [this post on java serialization performance!]({% post_url 2017-05-01-Hazelcast-Performance-Serialization %})

This is one way of reading and writing objects to and from a file.

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
        ProgrammerRepository programmerRepository = 
                                    ProgrammerRepository.newProgrammerRepository();
        readWriteObject(programmerRepository.getProgrammers(), 
                        Programmer.class);
        readWriteObject(programmerRepository.getProgrammers().map(ExternalizableProgrammer::new), 
                        ExternalizableProgrammer.class);
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
    private static <T extends Serializable> void readWriteObject(Stream<T> objectStream, 
                                                                 Class<T> tClass) throws IOException {
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
        try (ObjectInputStream in = new ObjectInputStream(Files.newInputStream(fileToWrite, 
                                                                  StandardOpenOption.READ))) {
            List<T> programmers = new LinkedList<>();
            try {
                while (true) {
                    programmers.add((T) in.readObject());
                }
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            } catch (EOFException ignored) {
                /*
                 * Reached the end of the file.
                 * No more objects to read
                 */
            }
            System.out.format("%d %s read from file!\n", programmers.size(), simpleName);
        }
    }
}
{% endhighlight %}

One of the most important parts to know is that any object written to a file _must_ implement the `Serializable` interface.
Otherwise a pretty little `NotSerializableException` gets throw when writing to the `ObjectOutputStream`.

Another handy fact is that the `ObjectInputStream` will throw an `EOFException` (End-of-File) when the data stream has no more bytes to read.
Which will allows the infinite loop, created in the method, to break.

A complete functioning project using this code can be found at the following repository listed below.
The repository contains a README file that will help get the project up and running!

[https://github.com/cyclic-reference/object-to-file](https://github.com/cyclic-reference/object-to-file)

**Writing Non-Serializable objects to a file.**

**Disclamer**: This does not mean, SERIALIZE ALL THE THINGS!
Some classes are not serializable for a good reason. 
Such as FutureTask, Thread, and Executor. 
These are very complex and stateful objects that have no use becoming stagnate in a file.

An important question to ask is: why in the world would this ever be a thing in the first place?

Which is a really good question. 
There happens to be some things that are out of our control.
Which really chaffs my chaps sometimes. 
I mean come on, we are programmers! 
We bend computers to our will such that nothing should be impossible,

Lets say that we have to consume a third-party (someone else other than us) library to consume a web-service. 
This library contains a domain object that is vital to the core application logic that we are building.
The object is _very_ large and complex. 
In order to thoroughly unit-test the classes that interface with the third party library, these domain objects need to be created.
Since they are so large and complex that creating different permutations these objects from hand is very time consuming and error prone.
Suppose that is far easier to create this domain object by using dedicated tool outside our codebase.
However, the issue here is that the complex domain object does not implment the Serializable interface. 
It could even be Serializable, but have really complex data types to create.
So we cannot viably persist the object with the methods we know right now.

One way around this issue is mapping the object to a JSON (Javascript Object Notation) string.
This is viable option only if access to a JSON object mapper library is permitted.
Such libraries include but are not limited to:

- [Google GSON](https://github.com/google/gson)
- [Jackson FasterXML](https://www.mkyong.com/java/jackson-2-convert-java-object-to-from-json/)

A full project is provided for the example below.
This repository also contains a README file that will help get the project up and running!

[https://github.com/cyclic-reference/test-objects-from-file](https://github.com/cyclic-reference/test-objects-from-file)

The following example will be done using GSON, Google's POJO to JSON mapping tool.
The goal is to write a JSON object string to a file. 
As each of the objects get serialized into JSON and written, they will be separated a new line character.
Allowing the eventual parsing by the java NIO (Non-blocking input output) `java.nio.file.Files` method `Stream<String> lines(Path path)`.
Which accepts a `Path` as an argument an returns a Stream of lines, or in this case JSON objects.
That in turn can be deserialized back into the POJO it was created from.

Here is how that could be done.

---

{% highlight java %}
package io.acari;

import com.google.gson.Gson;
import io.acari.pojo.NonSerializableProgrammer;
import io.acari.repositories.ProgrammerRepository;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.function.Consumer;

import static io.acari.repositories.ProgrammerRepository.newProgrammerRepository;

public class TestDataCreator {
    private static final Path TEST_JSON_DATA_FILE = 
                                    Paths.get("src", "test", "resources", "programmers.json")
                                         .toAbsolutePath();
    private static final Gson GSON = new Gson();

    public Path fetchJSONFile(){
        if (needToWriteToFile(TEST_JSON_DATA_FILE)) {
            Consumer<Path> jsonWriter = path -> {
                try (BufferedWriter out = Files.newBufferedWriter(path)) {
                    newProgrammerRepository().getProgrammers()
                            .map(NonSerializableProgrammer::new)
                            .forEach(programmer -> {
                                try {
                                    out.write(GSON.toJson(programmer));
                                    out.newLine();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                            });
                } catch (IOException e) {
                    e.printStackTrace();
                }
            };
            createData(TEST_JSON_DATA_FILE, jsonWriter);
        }
        return TEST_JSON_DATA_FILE;
    }

    private void createData(Path testDataFile, Consumer<Path> consumer) {
        try {
            if (Files.size(testDataFile) == 0) {
                consumer.accept(testDataFile);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private boolean needToWriteToFile(Path testDataFile) {
        try {
            if (Files.notExists(testDataFile)) {
                Files.createFile(testDataFile);
            }
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }
}

{% endhighlight %}

For clarity, the `newProgrammerRepository().getProgrammers().map(NonSerializableProgrammer::new)` code snippet is just a chain of methods that: 

1. Randomly creates some programmers
2. Exposes them as a stream.
3. Converts each programmer into a non-serializable version of the object.

Running _fetchJSONFile()_, provided proper permissions to modify contents in the current working directory, will create a file whose relative path is test-objects-from-file/src/test/resources/programmers.json.
The contents of the file could look something like the following:

{% highlight javascript %}
{"name":"14kk1qadp1gtloea6r7iljurpi","age":41,"computer":{"model":"Blade","subModel":"Stealth","ram":16,"make":"Razer"},"languages":["Groovy","Go","Lisp","Ruby","C","C#","Perl","Cobol"]}
{"name":"5rrgdb3j8git645m7p04tah0jo","age":20,"computer":{"model":"Blade","subModel":"Pro","ram":16,"make":"Razer"},"languages":["Groovy","Go","Clojure","Javascript","C#","Cobol","R","Matlab"]}
{"name":"3fmn5dfq32vtt7f9vgif4dc7ql","age":51,"computer":{"model":"Blade","subModel":"Pro","ram":16,"make":"Razer"},"languages":["Lisp","Ruby","Javascript","C","C#","Perl","Cobol","R","Matlab"]}
{"name":"7he5loei1ne71l4o3ltumgs5a5","age":36,"computer":{"model":"Macbook","subModel":"Air","ram":8,"make":"Apple"},"languages":["Java","Ruby","C","Perl","R","Matlab"]}
{"name":"40rr4ta6hf44s6dana116cdj3n","age":0,"computer":{"model":"Blade","subModel":"Pro","ram":16,"make":"Razer"},"languages":["Java","Groovy","Clojure","C","C#","Perl","Cobol","R"]}
{"name":"4rsohi17kqvou7mm26m4bfj5mt","age":32,"computer":{"model":"Blade","subModel":"Pro","ram":16,"make":"Razer"},"languages":["Java","Groovy","Clojure","Lisp","C++","C","C#","R","Matlab"]}
{% endhighlight %}

Having the file in the resources directory will allow the gradle build to put it directly into the classpath, next time a build is run.
Meaning that this class is really just good for one run, after that the file it created will be package into the executable .jar file.
This can change how the test data resource is accessed in the created program.

Here is how to use the resource via absolute path using TestDataCreator, and reading from the classpath resources:

{% highlight java %}
package io.acari;

import com.google.gson.Gson;
import io.acari.pojo.NonSerializableProgrammer;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

public class TestDataProvider {
    private static Map<String, NonSerializableProgrammer> nonSerialProgrammers = new LinkedHashMap<>();
    private static final Gson GSON = new Gson();

    static {
        ClassPathResource resource = new ClassPathResource("programmers.json");
        if(resource.exists()) {
            try {
                //This assumes that there is JSON File created in the resources directory
                //of the project and returns the reference to the file to the following
                //method that in turn creates the objects from the JSON string(s).
                //The resource directory is located in the following file structure
                // src
                // |
                // --test
                //   |  
                //   --resources
                nonSerialProgrammers = createProgrammersFromJSON(Paths.get(resource.getURI()));
            } catch (IOException e) {
                e.printStackTrace();
            }
        } else {
            TestDataCreator testDataCreator = new TestDataCreator();
            //This is the first time running the code
            //So there is no JSON File created, so we will create it in the resources directory
            //of the project and return the reference to the newly created file to the following
            //method that in turn create the objects from the created file.
            nonSerialProgrammers = createProgrammersFromJSON(testDataCreator.fetchJSONFile());
        }
       
    }

    private static Map<String, NonSerializableProgrammer> createProgrammersFromJSON(Path path) {
        if (Files.exists(path)) {
            try {
                return Files.lines(path)
                        .map(programmerJson ->
                                GSON.fromJson(programmerJson, NonSerializableProgrammer.class))
                        .collect(Collectors.toMap(
                                NonSerializableProgrammer::getName,
                                Function.identity()));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return Collections.emptyMap();
    }

    public static Map<String, NonSerializableProgrammer> getNonSerialProgrammers() {
        return nonSerialProgrammers;
    }
}
{% endhighlight %}

Lastly, when the data is created, each object is mapped to a unique identifier.
Meaning that access to a favorite test object or scenario involving an object with a certain state is just a simple key away!
No more having to create a really complex object by hand every time a new scenario needs to be tested.

One of the downsides to this is that this file could get really big, really fast.
Potentially slowing down the test suite. 
When tests start to take for ever, they get run less.
Test that are built and not run is just as bad as not having tests in the first place!

Anyways I could go on and on about this subject.
Which I might do in a future post.

Before leaving, it would be nice to mention some more concrete persistence APIs.
While having files to read and write a small subset of objects, it has really no place for real work.

Feel free to check these handy tools out!

If you want a relational database there are many to choose from, here is a small sample:

- [MySQL](https://www.mysql.com/)
- [PostgreSQL](https://www.postgresql.org/about/)
- [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-2016)

On the other hand, there are also quite a few NoSQL databases to choose from as well.
The primary difference between SQL and NoSQL databases is that there is no relational setup between objects stored in NoSQL databases.
Items in a NoSQL database are usually stored Key-Value pairs. 
Here is a small subset of NoSQL databases:

- [MongoDB](https://www.mongodb.com/what-is-mongodb)
- [Redis](https://redis.io/topics/introduction)
- [Cassandra](http://cassandra.apache.org/)

### Thank you for your attention!

#### -Alex
