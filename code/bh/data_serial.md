---
layout: post
---

DataSerializable
---


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
