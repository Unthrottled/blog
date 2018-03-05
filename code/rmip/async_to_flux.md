---
layout: post
--- 

Converting `AysncInputStream` into `Flux<DataBuffer>`
---


[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/flux/DownloadStreamToFluxFactory.java)

{% highlight java %}
    //...
    public class DownloadStreamToFluxFactory {
      private static final Logger LOGGER = LoggerFactory.getLogger(ImageHandler.class);
      
      public Flux<byte[]> convert(GridFSDownloadStream gridFSDownloadStream) {
            return Flux.create(synchronousSink -> readStream(gridFSDownloadStream, synchronousSink), FluxSink.OverflowStrategy.BUFFER);
      }
    
      private void readStream(GridFSDownloadStream gridFSDownloadStream, FluxSink<byte[]> synchronousSink) {
        ByteBuffer allocate = ByteBuffer.allocate(512000);
        Mono.from(gridFSDownloadStream.read(allocate))
            .subscribe(bytesRead -> {
              if (finishedReading(bytesRead)) {
                Mono.from(gridFSDownloadStream.close())
                    .subscribe(a -> {}, throwable -> {}, synchronousSink::complete);
              } else {
                synchronousSink.next(allocate.array());//Send Data to subscribers.
                readStream(gridFSDownloadStream, synchronousSink);
              }
            }, throwable -> {
              LOGGER.warn("Ohhh snap!", throwable);
              synchronousSink.complete();
            });
      }
    
      private boolean finishedReading(Integer read) {
        return read < 0;
      }
    }
    
{% endhighlight %}