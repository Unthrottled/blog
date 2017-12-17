---
layout: post
headerImage: reach.png
tags: []
---

{% highlight java %}
package io.acari.images;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api")
public class LandingRestController {
    private static final Logger LOGGER = LoggerFactory.getLogger(LandingRestController.class);

    private final ImageHandler imageHandler;

    @Autowired
    public LandingRestController(ImageHandler imageHandler) {
        this.imageHandler = imageHandler;
    }

    @PostMapping(value = "image/delete/{id}",
            consumes = MediaType.ALL_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<Boolean> deleteImage(@PathVariable("id") String id) {
        return imageHandler.removeImage(id);
    }

    @PostMapping(value = "image/save", consumes = {
            MediaType.MULTIPART_FORM_DATA_VALUE,
            MediaType.IMAGE_PNG_VALUE,
            MediaType.IMAGE_JPEG_VALUE,
            MediaType.IMAGE_GIF_VALUE,
            MediaType.APPLICATION_FORM_URLENCODED_VALUE,

    })
    public Mono<String> saveImage(@RequestPart MultipartFile projectFile) {
        return imageHandler.saveImage(projectFile);
    }

    @RequestMapping(value = "image/get/{id}", produces = {MediaType.IMAGE_PNG_VALUE,
            MediaType.IMAGE_JPEG_VALUE,
            MediaType.IMAGE_GIF_VALUE})
    public Mono<byte[]> fetchImage(@PathVariable("id") String id) {
        return imageHandler.fetchImageBinary(id);
    }

    @GetMapping(value = "images", produces = MediaType.APPLICATION_JSON_VALUE)
    public Flux<Identifier> allProjects() {
        return imageHandler.findAllNames();
    }
}
{% endhighlight %}



{% highlight java %}
package io.acari.images;

import com.mongodb.client.gridfs.model.GridFSFile;
import com.mongodb.reactivestreams.client.gridfs.GridFSBucket;
import com.mongodb.reactivestreams.client.gridfs.helpers.AsyncStreamHelper;
import org.bson.BsonObjectId;
import org.bson.BsonValue;
import org.bson.types.ObjectId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Objects;

@Component
public class ImageHandler {
  private static final Logger LOGGER = LoggerFactory.getLogger(ImageHandler.class);
  private final GridFSBucket gridFSBucket;

  @Autowired
  public ImageHandler(GridFSBucket gridFSBucket) {
    this.gridFSBucket = gridFSBucket;
  }

  public Mono<String> saveImage(MultipartFile multipartFile) {
    String name = multipartFile.getOriginalFilename();
    try {
      return Mono.from(gridFSBucket.uploadFromStream(name,
          AsyncStreamHelper.toAsyncInputStream(multipartFile.getInputStream())))
          .map(ObjectId::toHexString);
    } catch (IOException e) {
      LOGGER.warn("Error saving image", e);
      return Mono.error(new Throwable("Unable to save image!"));
    }
  }

  public Mono<byte[]> fetchImageBinary(String imageId) {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    return Mono.from(gridFSBucket.downloadToStream(new ObjectId(imageId),
        AsyncStreamHelper.toAsyncOutputStream(outputStream)))
        .map(l -> outputStream.toByteArray());
  }

  public Mono<Boolean> removeImage(String imageId) {
    return Mono.from(gridFSBucket.delete(new ObjectId(imageId)))
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
}
{% endhighlight %}


{% highlight java %}
aoeu
{% endhighlight %}