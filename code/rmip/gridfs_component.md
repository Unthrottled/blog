---
layout: post
---

Reactive GridFS Component

[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/handler/ImageHandler.java)

{% highlight java %}

    //...
    @Component
    public class ImageHandler {
      private static final Logger LOGGER = LoggerFactory.getLogger(ImageHandler.class);
      private final GridFSBucket gridFSBucket;
      private final DownloadStreamToFluxFactory downloadStreamToFluxFactory = new DownloadStreamToFluxFactory();
    
      @Autowired
      public ImageHandler(GridFSBucket gridFSBucket) {
        this.gridFSBucket = gridFSBucket;
      }
    
      public Flux<String> saveImage(Flux<Part> multipartFile) {
        return multipartFile
            .flatMap(part -> Mono.from(gridFSBucket.uploadFromStream(part.name(),
                FluxAsyncStreamConverter.convert(part.content()))))
            .map(ObjectId::toHexString);
      }
    
      public Flux<byte[]> fetchImage(String imageId) {
        return downloadStreamToFluxFactory
            .convert(gridFSBucket.openDownloadStream(getId(imageId)));
      }
    
      public Mono<Boolean> removeImage(String imageId) {
        return Mono.from(gridFSBucket.delete(getId(imageId)))
            .map(Objects::nonNull)
            .onErrorReturn(false);
      }
    
      public Flux<Identifier> findAllNames() {
        return Flux.from(gridFSBucket.find())
            .map(GridFSFile::getId)
            .map(BsonValue::asObjectId)
            .map(BsonObjectId::getValue)
            .map(ObjectId::toHexString)
            .map(Identifier::new);
    
      }
    
      private ObjectId getId(String imageId) {
        return new ObjectId(imageId);
      }
    }

{% endhighlight %}