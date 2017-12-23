---
layout: post
headerImage: mongo_images/logo.png
tags: [Java, Spring Boot, Reactor, WebFlux, Mongodb, Reactive Streams, Angular, Gridfs]
---

Have you bought into the whole [Reactive Programming](https://en.wikipedia.org/wiki/Reactive_programming) bit yet? 
Well, I have participated in consuming the "_Reactive Flavor Aid_" and there is one issue at the moment.
Currently, there is a supreme lack of helpful documentation to assist in a seamless development experience.
Fear not fellow reactive enthusiast, this post should help you save images in MongoDB utilizing reactive streams!

Recently, I wanted to create a project that is a full slice reactive application.
Meaning that the code and communication between the Frontend, Backend, and Data Persistance Layers are _reactive_.
When reactive is stated, the following can be assumed:

- All code is no blocking
- Code is processed in an [event loop](http://vertx.io/docs/guide-for-java-devs/#_core_vert_x_concepts).
- Push based programming.
- Publisher/Subscriber or [Observable/Observer](http://reactivex.io/intro.html) pattern. 

With all of this criterion set, here is the following application stack that I came up with:

- [Angular 5](https://angular.io/) paired with [RxJS](http://reactivex.io/rxjs/)
- [Spring 5](https://spring.io/) paired with WebFlux powered by [Reactor](https://projectreactor.io/)
- [MongoDB](https://www.mongodb.com/) which supports reactive streams!

At a high level, the project consists of a Spring Boot server.
Which serves static content to the user, and provides a REST API to save, update, retrieve, and delete persisted images.

The images are stored in a Mongo database. 
The server takes advantage of GridFS which breaks the image binary into chunks which allows for storage of images greater than 16MB. 

This all sounds straight forward, right? As it turns out, there is very little documentation and examples on how to do anything reactive!

The rest of this post will show you how you can choose, upload, and download images! 

![Warning]({{site.imageDir}}mongo_images/trigger warnings.png)  

Attention! The remainder of this post contains a lot of code and corresponding explanations of code.
If the reader feels so inclined, you can find the  *[Source Code to the project described above.](https://github.com/cyclic-reference/mongo-images)*  

## Backend Setup

Spring Boot is an awesome framework, the following will show you how to create a WebFlux capable Tomcat Server.

---

### Rest Controller

One of the things that will be needed is a non-blocking REST API that will allow our frontend to persist images.
The following component provides a WebFlux API that is a simple CRUD (create, update, delete) routing function.

- `/api/images` is a GET endpoint that returns a non-blocking `Flux<String>` of all of the current images that have been saved.
- `/api/image/save` is a POST endpoint that consumes the form multipart data as a   `Flux<Part>` and returns the image identifiers as `Flux<String>`.
- `/api/image/get/{id}` is a GET endpoint that takes a path variable as the Hexidecimal Identifier given by the save or images endpoint.
- `/api/image/delete/{id}` is a DELETE endpoint thate takes a path variable as the Hexidecimal Identifier given by the save or images enpoint.

Side note, the other routing function is to serve the static resources defined in src/main/resources/static.

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/rest/RouterComponent.java)
{% highlight java %}
    //...
    @Component
    public class RouterComponent {
      private static final Logger LOGGER = LoggerFactory.getLogger(RouterComponent.class);
    
      private final ImageHandler imageHandler;
    
      @Autowired
      public RouterComponent(ImageHandler imageHandler) {
        this.imageHandler = imageHandler;
      }
    
      @Bean
      public RouterFunction<?> landingRouterFunction() {
        return RouterFunctions.nest(RequestPredicates.path("/api"),
            RouterFunctions.route(RequestPredicates.GET("/images"),
                request -> ServerResponse.ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(imageHandler.findAllNames(), Identifier.class))
                .andRoute(RequestPredicates.POST("/image/save"),
                    request -> ServerResponse.ok()
                        .body(imageHandler.saveImage(request.bodyToFlux(Part.class)), String.class))
                .andRoute(RequestPredicates.GET("/image/get/{id}"),
                    request -> ServerResponse.ok()
                        .body(imageHandler.fetchImage(request.pathVariable("id")), byte[].class))
                .andRoute(RequestPredicates.DELETE("/image/delete/{id}"),
                    request -> ServerResponse.ok()
                        .body(imageHandler.removeImage(request.pathVariable("id")), Boolean.class))
        ).andOther(RouterFunctions.resources("/**", new ClassPathResource("static/")));
      }
{% endhighlight %}

### GridFS Components

Now that we know how to consume and produce images using a REST API powered by Spring, here is how we satisfy the implementation.
GridFS has a reactive client so that means that it will need to read and write bytes in asynchronous streams.

The first hurdle that needs to be crossed is, "how to create the respective asynchronous streams?"

The `Part` class only exposes a `Flux<DataBuffer` which is basically just a Spring wrapped ByteBuffer.

Unfortunately, there is no direct api support for converting a `Flux<Part>` to a `AsycInputStream`, so I had to make my own.
All in the name of non-blocking asynchronous code! I will address my implementation later. 

This works fine and dandy when an image file needs to be saved; however, returning an image is a bit different.

The REST API is designed to to stream the buffered bytes to the client, so that the server to keep everything in memory as it is reading the image.
So this means that our API for retrieving images has a return signature of `Flux<byte[]>`, which will stream the chunked image data to http clients.

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

### Converting Flux<Part> to AsyncInputStream

This was a very interesting problem that I had to solve.
The primary issue between the two classes is one is purely push based, while the other is pull then push.

The Flux, in my opinion is purely push. It is a direct soure of whatever it is labeled as.
One subscribed to the stream of objects, then they will be pushed to your code as they come.

While the Asynce stream is pull then push. What happens here is that you have to ask for the stream to fill your buffer with bytes.
Then it will push the result of the reading one it is done. Then it is up to you again to ask. Which is the primary differences between these two APIs.

The Flux will give you all of the data one you ask once. While it it up to the user to fetch all of the data.
Which leaves us with a window of time where the Flux is producing data, while the user is doing stuff other than asking to fill another buffer.

So in order to make a successfully conversion, we need to return the data from the `Flux<DataBuffer>` in the same sequence as we received it, to each sequential read call of the Async Input Stream.

There is a blocking way to accomplish this and that would be to turn the Flux into a Iterable, which is natively supported by the Reactor library.
Unfortunately, again, there is no native support for non-blocking Flux iteration. 

Again, I had to make my own implementation. which I will cover a little bit later.

#### Part One

{% highlight java %}
    //...
    /**
     * The Async Input Stream interface represents some asynchronous input stream of bytes.
     *
     */
    public class FluxAsyncInputStream implements AsyncInputStream {
      private static final Logger LOGGER = LoggerFactory.getLogger(FluxAsyncInputStream.class);
    
      private final NonBlockingIterableFlux<DataBuffer> source;
    
      public FluxAsyncInputStream(Flux<DataBuffer> source) {
        this.source = new NonBlockingIterableFlux<>(source);
    
      }
    
      /**
       * Reads a sequence of bytes from this stream into the given buffer.
       *
       * @param dst      the destination buffer
       * @return a publisher with a single element, the total number of bytes read into the buffer, or
       *         {@code -1} if there is no more data because the end of the stream has been reached.
       */
      @Override
      public Publisher<Integer> read(ByteBuffer dst) {
        return this.source.takeNext()
            .map(dataBuffer -> {
              dst.put(dataBuffer.asByteBuffer());
              return dataBuffer.readableByteCount() <= 0 ? -1 : dataBuffer.readableByteCount();
            }).defaultIfEmpty(-1);
      }
    
      /**
       * Closes the input stream
       *
       * @return a publisher with a single element indicating when the stream has been closed
       */
      @Override
      public Publisher<Success> close() {
        this.source.dispose();
        return Mono.just(Success.SUCCESS);
      }
    }
{% endhighlight %}

#### Part Two Iterating a Flux without blocking and returning a Publisher.

Note: this class is _not_ lazely evaluated. When constructed it automatically lets the publisher it is ready to receive data.

{% highlight java %}
    //...
    public class NonBlockingIterableFlux<T> implements Disposable {
      private final Queue<T> itemBuffer = new LinkedList<>();
      private final Queue<MonoSinkHelper<T>> callables = new LinkedList<>();
      private final Disposable subscription;
      private boolean complete = false;
    
      /**
       * Stateful class, which allows for non-blocking
       * sequential access to items in provided flux stream.
       * <p>
       * It is a hot observable that buffers when it has
       * backpressure. It guarantees that all items where delivered
       * to somebody.
       *
       * @param source non-null flux source.
       * @throws NullPointerException when given null source
       */
      public NonBlockingIterableFlux(Flux<T> source) {
        Preconditions.checkNotNull(source);
        Flux<T> messaged = Flux.create(stringFluxSink ->
            source.subscribe(sourceItem -> emitNextItem(stringFluxSink, sourceItem),
                this::accept,
                this::run));
        subscription = messaged.subscribe();
      }
    
      /**
       * Cancel or dispose the underlying task or resource.
       */
      public void dispose() {
        subscription.dispose();
        callables.forEach(MonoSinkHelper::success);
      }
    
      /**
       * Think of this like a "Take a Number" queue.
       * When you {@code takeNext()} you are essentially asking
       * to be served when your number is called.
       * The order at which this is called determines what
       * item you get in the flux, ie the first call get the first element
       * and the second call gets the second item in the flux.
       * <p>
       * Some people ahead of you may leave, that's okay,
       * because you will get their item.
       * <p>
       * If you take a number that cannot fufilled
       * (the flux handed out all of it's items),
       * you will be notified by an empty return.
       *
       * @return An item in the flux based off of the current queue of callbacks.
       * or nothing if the flux has run out of items.
       */
      public Mono<T> takeNext() {
        if (complete && itemBuffer.isEmpty()) {
          return Mono.empty();
        } else if (itemBuffer.isEmpty()) {
          return createCallback();
        } else {
          return Mono.just(itemBuffer.poll());
        }
      }
    
      private Mono<T> createCallback() {
        final Consumer<MonoSink<T>> stringConsumer = tMonoSink -> {
          callables.offer(new MonoSinkHelper<>(tMonoSink));
        };
        return Mono.create(stringConsumer);
      }
    
      private void emitNextItem(FluxSink<T> stringFluxSink, T a) {
        if (callables.isEmpty()) {
          bufferItem(stringFluxSink, a);
        } else {
          emitToNextSubscribedCaller(stringFluxSink, a);
        }
      }
    
      private void bufferItem(FluxSink<T> stringFluxSink, T a) {
        stringFluxSink.next(a);
        itemBuffer.offer(a);
      }
    
      private void emitToNextSubscribedCaller(FluxSink<T> stringFluxSink, T a) {
        MonoSinkHelper<T> nextPersonInLine = callables.poll();
        if (nextPersonInLine.isDisposed()) {
          emitNextItem(stringFluxSink, a);
        } else {
          nextPersonInLine.success(a);
        }
      }
    
    
      private void accept(Throwable b) {
        callables.forEach(callable -> callable.error(b));
      }
    
      private void run() {
        callables.forEach(MonoSinkHelper::success);
        complete = true;
      }
    
    }
{% endhighlight %}

#### Part Three: The helper.

I need a class that let me know if any subscriber had unsubscribed while waiting for the next element to be returned from the Flux.
This way the sequence is still preserved, and the data goes to a subcriber that is actually listening!

{% highlight java %}
    //...
    public class MonoSinkHelper<T>{
    
      private final MonoSink<T> monoSink;
      private boolean disposed = false;
    
      public MonoSinkHelper(MonoSink<T> monoSink) {
        this.monoSink = monoSink;
        monoSink.onDispose(this::disposed);
      }
    
      public void success(){
        this.monoSink.success();
      }
    
      public void success(T t){
        this.monoSink.success(t);
      }
    
      public void error(Throwable t){
        this.monoSink.error(t);
      }
    
      public boolean isDisposed() {
        return disposed;
      }
    
      private void disposed() {
        disposed = true;
      }
    }
{% endhighlight %}

### Spring Configurations

All of the proper framework is set to start persisting images. 
The next step is to wire up all of the correct configuration.

#### Spring Boot Configuration

{% highlight java %}
    
    //...
    @EnableReactiveMongoRepositories
    @SpringBootApplication(exclude = {MongoAutoConfiguration.class, MongoDataAutoConfiguration.class})
    public class LandingApplication {
    
        public static void main(String[] args) {
            SpringApplication.run(LandingApplication.class, args);
        }
    }

{% endhighlight %}

#### Mongo Client Configuration

A mongo client will have to be created so that the application can actually save files!
Setting up the Mongo configuration start of by extending the Abstract ReactiveMongoConfiguration class.
Which will require the implementation of a MongoClient and Database Name factory method.

There are a couple of "gotchas" when creating a reactive Mongo client.
The first being tha the Stream Factory needs to be a NettyStream, otherwise are runtime exception gets thrown when it is omitted!
A required dependency of the stream factory is to specify a NioEventLoopGroup (which is fun to say a loud, Loop Group).
The event loop will need to be shut down when the Spring component is shutdown.

The database connection string and database name can be specified in the application properties file.
Which will be mentioned soon enough!

While the Mongo client is never directly used in the code mentioned above, it is used transitively by the GridFSBucket.
The reactive GridFSBucket is provided as a Spring Bean in this configuration component as well.

[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/configuration/MongoConfig.java)
{% highlight java %}

    //....
    
    @Configuration
    public class MongoConfig extends AbstractReactiveMongoConfiguration {
      private static final Logger LOGGER = LoggerFactory.getLogger(MongoConfig.class);
      private final Environment environment;
    
      @Autowired
      public MongoConfig(Environment environment) {
        this.environment = environment;
      }
    
      private final NioEventLoopGroup eventLoopGroup = new NioEventLoopGroup();
    
      @Bean
      @Override
      public MongoClient reactiveMongoClient() {
        ConnectionString connectionString = new ConnectionString(environment.getProperty("acari.mongo.connectionString", "localhost:27017"));
        return MongoClients.create(MongoClientSettings.builder()
                .streamFactoryFactory(NettyStreamFactoryFactory.builder()
                        .eventLoopGroup(eventLoopGroup)
                        .build())
                .clusterSettings(ClusterSettings.builder()
                        .applyConnectionString(connectionString)
                        .build())
                .build());
      }
    
      @Override
      protected String getDatabaseName() {
        return environment.getProperty("acari.mongo.landingDatabase", "images");
      }
    
      @Bean
      public GridFSBucket gridFsTemplate(MongoClient reactiveMongoClient) throws Exception {
        return GridFSBuckets.create(reactiveMongoClient.getDatabase(getDatabaseName()));
      }
    
      @PreDestroy
      public void shutdown(){
        eventLoopGroup.shutdownGracefully();
      }
    }
{% endhighlight %}

#### Part Four: Converting AsyncInputStream into Flux<DataBuffer>

Fortunately, this process is much easier! Plus there is native library support!! 

{% highlight java %}
    //...
    public class DownloadStreamToFluxFactory {
      private static final Logger LOGGER = LoggerFactory.getLogger(ImageHandler.class);
      
      public Flux<byte[]> convert(GridFSDownloadStream gridFSDownloadStream) {
        return Flux.create(synchronousSink -> readStream(gridFSDownloadStream, synchronousSink));
      }
    
      private void readStream(GridFSDownloadStream gridFSDownloadStream, FluxSink<byte[]> synchronousSink) {
        ByteBuffer allocate = ByteBuffer.allocate(4096);
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

#### WebFlux Configuration

This configuration component is necessary to use WebFlux.

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/configuration/WebConfig.java) 

{% highlight java %}

    //....
    import org.springframework.context.annotation.Configuration;
    import org.springframework.web.reactive.config.EnableWebFlux;
    import org.springframework.web.reactive.config.WebFluxConfigurer;
    
    @Configuration
    @EnableWebFlux
    public class WebConfig implements WebFluxConfigurer {
    
    }


{% endhighlight %}

#### Spring Application Property Configuration

Lastly, this is the applications properties file that will allow for the configuration of both the database and Mongo instance used!

[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/resources/application.yml)

### application.yml

        acari:
          mongo:
            connectionString: mongodb://mongo
            landingDatabase: images
        
        server:
          port: 80
          
          
---
          
## Frontend Setup

There is a ton of Angular 5 code that I had to write to get this project to be minimally viable.
I wanted to avoid the fluff and just get to the things (I think) that matter.

The following will be covered:

- How to let the user to Select an image.
- How to Display a file, represented as binary, in the browser.
- How to Upload a local user file (POST the image to the web-service created).
- How to retrieve an image from a Byte Stream, and covert it into browser accepted binary.

### Image File Selection

It is hard to save an image that has not been chosen by the user.
This Angular 5 component is dedicated to just that, selecting a file!

When the user chooses an image an event is fired. 
This component finds the selected file and emits it as output.

{% highlight javascript %}

    import {Component, EventEmitter, Output} from '@angular/core';
    
    @Component({
        selector: 'project-file-choose',
        template: `
            <label class="btn btn-lg btn-default">
                <input type="file" (change)="selectFile($event)"/>
            </label>
        `
    })
    export class ProjectFileChooseComponent {
    
        @Output()
        private fileSelectedEmitter = new EventEmitter<File>();
    
        constructor() {
        }
    
        private _selectedFile: File;
    
        selectFile(event: any): void {
            this.selectedFile = event.target.files.item(0);
            this.fileSelectedEmitter.emit(this.selectedFile);
        }
    
    
        get selectedFile(): File {
            return this._selectedFile;
        }
    
        set selectedFile(value: File) {
            this._selectedFile = value;
        }
    
    }
{% endhighlight %}

## Image Visualization 

Now that the user can choose a file, and the corresponding component emits selected file, image visualization can happen!

### Model Translation Component

This project has a model called `ProjectFile` that is an abstraction of our Image file.

{% highlight javascript %}
    export interface ProjectFile {
        imageBinary(): Observable<any>;
        getIdentifier(): string;
        setNewFile(file: File): void;
    }
{% endhighlight %}

The `ProjectFileChooseComponent` is a part of this component which subscribes to the "File Selected" event that is emitted by the file choosing component.
When the event is fired, it is this component's job to set the current project file to the newly emitted file.

How the _ProjectFile_ model handles a file being set will be discussed later when the implementations of `ProjectFile` are covered.

{% highlight javascript %}
    
    import {Component, EventEmitter, Input, Output} from "@angular/core";
    import {ProjectFile} from "../model/ProjectFile.model";
    
    @Component(
        {
            selector: 'project-file-manipulation',
            template: `
                <project-file-choose (fileSelectedEmitter)="fileChosen($event)">
                </project-file-choose>
            `
        }
    )
    export class ProjectFileManipulationComponent {
        private _projectFile: ProjectFile;
    
        @Output()
        private projectFileUpdated = new EventEmitter<ProjectFile>();
    
    
        @Input()
        get projectFile(): ProjectFile {
            return this._projectFile;
        }
    
        set projectFile(value: ProjectFile) {
            this._projectFile = value;
        }
    
        fileChosen(file: File): void{
            this._projectFile.setNewFile(file);
            this.projectFileUpdated.emit(this._projectFile);
        }
    }

{% endhighlight %}

### Image Visualization Component

An important concept to understand is that the `ProjectFile` has a method that should provide an image's binary.
Given raw binary, then it is expected that there is some way to display that on the browser.

Great expectation! 

Two important bits in this component are the `get imageBinary()` function and
 
    <img [src]="imageBinary | async" alt="SOME IMAGE"/>

The first function supplies the reference to the Observable image binary property. 
While the HTML uses the supplied image binary property and runs it through the asynchronous angular pipe.
    

{% highlight javascript %}

    import {Component, Input} from '@angular/core';
    import {Observable} from "rxjs/Observable";
    import {ProjectFile} from "../model/ProjectFile.model";
    
    @Component({
        selector: 'project-file-view',
        template: `
            <div *ngIf="editMode">
                <project-file-manipulation [projectFile]="projectFile" (projectFileUpdated)="updateFile($event)">
                </project-file-manipulation>
                <div *ngIf="imageBinary | async">
                    <div class="btn btn-lg btn-success" (click)="uploadFile()">Upload</div>
                    <div class="btn btn-lg btn-danger" (click)="delete()">Delete</div>
                </div>
            </div>
            <div class="image-holder">
                <div class="image-container"
                     *ngIf="imageBinary | async">
                    <img [src]="imageBinary | async" alt="SOME IMAGE"/>
                </div>
            </div>
        `
    })
    export class ProjectFileViewComponent {
    
        constructor() {
        }
    
        private _projectFile: ProjectFile;
    
        @Input()
        get projectFile(): ProjectFile {
            return this._projectFile;
        }
    
        set projectFile(value: ProjectFile) {
            this._projectFile = value;
        }
    
        get imageBinary(): Observable<any> {
            return this._projectFile.imageBinary();
        }
    
    }

{% endhighlight %}

### Image Model

There are currently two implementations of the ProjectFile interface.
The LocalProjectFile, which is a representation of an image that has not be stored in MongoDB yet.
Local meaning that it has not left your machine yet!

When a file is set on a LocalProject file, the file is converted into binary using FileReader.
The results of the FileReader result are put into a `ReplaySubject`.
A replay subject is a special observable that, sort of, has a current value. 
Meaning that whenever any observer subscribes, then at most one image binary is emitted.
This prevents the need to keep converting the file over and over again. 
Just store the binary in memory from then on return that. 

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-content/src/app/projectFiles/model/LocalProjectFile.ts)

{% highlight javascript %}

    //...
    
    export class LocalProjectFile implements ProjectFile {
        private imageBinaryRepeater = new ReplaySubject<MSBaseReader>(1);
        private _identifier: Identifier;
    
        constructor(id: Identifier) {
            this._identifier = id;
        }
    
        private _selectedFile: Observable<File>;
    
        /**
         * This is the expected data structure that will
         * be translated as a rest call to the backend.
         * @returns {Observable<File>}
         */
        get selectedFile(): Observable<File> {
            return this._selectedFile;
        }
    
        set selectedFile(value: Observable<File>) {
            this._selectedFile = value;
            this.readFileIntoBinary();
        }
    
        /**
         * Sets current project file and also
         * reads the file into binary so that it
         * will be displayed.
         * @param {File} file preferably a image file.
         */
        setNewFile(file: File): void {
            this.selectedFile = Observable.of(file);
        }
    
        getIdentifier(): string {
            return this._identifier.id;
        }
    
        /**
         * This is the raw image data binary that
         * will be rendered by the browser.
         * @returns {Observable<MSBaseReader>}
         */
        imageBinary(): Observable<MSBaseReader> {
            return this.imageBinaryRepeater;
        }
    
        private readFileIntoBinary() {
            this._selectedFile
                .subscribe(file => {
                    let fileReader = new FileReader();
                    fileReader.onload = event => {
                        this.imageBinaryRepeater.next(fileReader.result);
                    };
                    fileReader.readAsDataURL(file);
                });
        }
    }

{% endhighlight %}

## Uploading an Image 

### Image Upload Service

Being able to choose and display the chosen image is nice, but what about uploading?
Fear not, our REST server takes a MultiPartFile as input.
Here is how to convert a file into FormData which is a MultiPartFile!

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-content/src/app/projectFiles/service/ImageUpload.service.ts)

{% highlight javascript %}

    //...
    
    @Injectable()
    export class ImageUploadService {
    
    
        constructor(private backendAPIService: BackendAPIService) {
        }
    
        public uploadImage(reachFile: Observable<File>): Observable<string> {
            return reachFile
                .filter(isDefined)
                .map(reachFile => {
                    let formData = new FormData();
                    /**
                     * The name that we append to the form has to correspond
                     * to the name of the parameter in the method signature
                     * in the REST controller.
                     */
                    formData.append('projectFile', reachFile);
                    return formData
                }).flatMap(formData =>
                    this.backendAPIService.postImage(formData))
        }
    }

{% endhighlight %}

### HTTP Client

Most of the work above was done by the `BackendAPIService` which is a wrapper around the HttpClient, which is the class responsible for running HttpRequests.
The `postImage` function takes FormData and uses that as the POST request body. 
The return is an observable of key that can be used to fetch and delete the image in persistence.

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-content/src/app/services/BackendAPI.service.ts)

{% highlight javascript %}

    //....
    
    @Injectable()
    export class BackendAPIService {
        constructor(private httpClient: HttpClient){}
    
    
        postImage(formData: FormData): Observable<string> {
            return this.httpClient.post('./api/image/save', formData, {
                responseType: 'text'
            });
        }
    
        fetchImage(_id: string): Observable<ArrayBuffer> {
            return this.httpClient.get('./api/image/get/' + _id, {
                responseType: 'arraybuffer'
            });
        }
    
        fetchAllImageIds(): Observable<any> {
            return this.httpClient.get('./api/images', {
                responseType: 'json'
            })
        }
    
        deleteImage(_id: string): Observable<boolean> {
            return this.httpClient.post('./api/image/delete/' + _id, {
                responseType: 'json'
            }).map(response => (<Boolean>response === true));
        }
    }

{% endhighlight %}

## Retrieve A Remote Image File

### Remote Image File Model

The second implementation of the `ProjectFile` interface is the RemoteProjectFile.
Which is the abstraction of an image that comes from persistence.
The key difference between the Local and the Remote project is where the binary source is located.

In the case of the local file the binary come directly from your disk, while the binary for the remote file comes from the server (which is probably still your disk :) ).

Much like the LocalFile, the remote file takes advantage of the `ReplaySubject` which prevents the need to make more than one REST call to retrieve the image binary while still using the Observable abstraction.

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-content/src/app/projectFiles/model/RemoteProjectFile.ts)

{% highlight javascript %}

    //....
    
    export class RemoteProjectFile implements ProjectFile {
        private imageBinaryReplay = new ReplaySubject<any>(1);
        private _name: string;
    
        /**
         *
         * @param {Identifier} identifier the unique identifier that will allow use of
         *                      the backend rest api.
         * @param {Observable<any>} remoteProjectFile project file from the backend
         */
        constructor(identifier: Identifier = new Identifier(),
                    remoteProjectFile: Observable<any> = Observable.empty()) {
    
            remoteProjectFile.subscribe(imageBinary => {
                this.imageBinaryReplay.next(imageBinary);
            });
    
            this._identifier = identifier;
            this._name = this.identifier.id;
        }
    
        private _identifier: Identifier;
    
        get identifier(): Identifier {
            return this._identifier;
        }
    
        set identifier(value: Identifier) {
            this._identifier = value;
        }
    
        /**
         * Replaces the current remote project file with the new binary.
         *
         * I am kind of torn at the moment because one you set the binary again
         * it is no longer a remote project file and does not fit int this current
         * abstraction.
         * @param {File} file
         */
        setNewFile(file: File): void {
            //todo: me?
        }
    
        getIdentifier(): string {
            return this._identifier.id;
        }
    
        /**
         * Actual binary received from the backend service.
         * @returns {Observable<any>}
         */
        imageBinary(): Observable<any> {
            return this.imageBinaryReplay
        }
    
    
    }

{% endhighlight %}

### Remote Image Factory

The great thing about the `RemoteProjectFileService` is that when provided a File Key, it creates a ImageBinary Observable (which is an HTTP call waiting to happen), and wraps the key and binary in the RemoteProjectFile model.
As saw above, the model subscribes to the observable, which in turn eventually makes an HTTP POST.

Since the binary coming from the server is raw it needs to be converted into a format the browser should be able to understand.


[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-content/src/app/projectFiles/service/RemoteProjectFile.service.ts)

{% highlight javascript %}

    //....
    
    @Injectable()
    export class RemoteProjectFileService {
    
        constructor(private backendAPISevice: BackendAPIService, private windowRef: WindowRef) {
        }
    
        public fetchRemoteProject(fileId: string): RemoteProjectFile {
            return new RemoteProjectFile(new Identifier(fileId),
                this.backendAPISevice.fetchImage(fileId)
                    .map(arrayBuffer => this.convertToImageBinary(arrayBuffer)));
        }
    
        public fetchAllRemoteProjects(): Observable<RemoteProjectFile> {
            return this.backendAPISevice.fetchAllImageIds()
                .map((response: any[]) => response)
                .flatMap(files => Observable.from(files))
                .map(identifier => identifier._id)
                .map(id => this.fetchRemoteProject(id));
        }
    
        removeProject(projectToRemove: RemoteProjectFile): Observable<boolean> {
            return this.backendAPISevice.deleteImage(projectToRemove.getIdentifier());
        }
    
        private convertToImageBinary(arrayBuffer: any): any {
            let binary = '';
            let bytes = new Uint8Array(arrayBuffer);
            let len = bytes.byteLength;
            for (let i = 0; i < len; ++i) {
                binary += String.fromCharCode(bytes[i]);
            }
            return 'data:image/png;base64,' + this.windowRef.nativeWindow.btoa(binary);
        }
    }

{% endhighlight %}
