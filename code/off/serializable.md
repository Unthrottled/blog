---
layout: post
---

Externalizable Serialization
---

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
        try (ObjectInputStream in = new ObjectInputStream(Files.newInputStream(fileToWrite, StandardOpenOption.READ))) {
            List<T> serializableObjects = new LinkedList<>();
            try {
                while (true) {
                    serializableObjects.add((T) in.readObject());
                }
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            } catch (EOFException ignored) {
                /*
                 * Reached the end of the file.
                 * No more objects to read
                 */
            }
            logger.info("{} {} read from {}!\n", serializableObjects.size(), simpleName, fileToWrite.toAbsolutePath());
        }
    }
}
{% endhighlight %}
