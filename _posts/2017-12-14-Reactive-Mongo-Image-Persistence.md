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

One of the things that will be needed is a REST API that will allow our frontend to persist images.
The following REST controller is a WebFlux API that exposes a simple CRUD interface using `Mono` and `Flux`.

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/LandingRestController.java)
{% highlight java %}
    //...
    @RestController
    @RequestMapping("/api")
    public class LandingRestController {
        private static final Logger LOGGER = 
        LoggerFactory.getLogger(LandingRestController.class);
    
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
    
        @RequestMapping(value = "image/get/{id}", 
            produces = {MediaType.IMAGE_PNG_VALUE,
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

As a side note, there is apparently a way to get the `saveImage` function to have a method signature of `saveImage(@RequestPart Flux<Part> projectFile)` but I did not spend too much time trying to make that work.
Which should allow the controller to consume the form data as a Reactive Stream of part data. Maybe this will be upgraded later.

### GridFS Component

Now that we know how to consume and produce images using a REST API powered by Spring, here is how we satisfy the implementation.
GridFS has a reactive client so that means that it will need to read and write bytes in asynchronous streams.

The first hurdle that needs to be crossed is, "how to create the respective asynchronous streams?"
Thankfully, the `MultipartFile` exposes a regular InputStream which can in turn be wrapped into a AsyncInputStream by the `AysncStreamHelper` class.
This works fine and dandy when an image file needs to be saved, however, returning an image is a bit different.

The initial design for the REST API was for the fetchImageBinary to stream the bytes, so that the server would not have to keep everything in memory.
However fast and easy solution was to create a `ByteArrayOutputStream` and just side effect all of the reads and convert it into a observable byte array all in memory.
When dealing with larger files, it may be more useful to stream information off to the client, to prevent the need for a whole lot of working memory.


[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/ImageHandler.java)
{% highlight java %}

    //...
    
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

### Spring Configurations

All of the proper framework is set to start persisting images. 
The next step is to wire up all of the correct configuration.

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

[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/MongoConfig.java)
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

#### WebFlux Configuration

This configuration component is not necessary to use WebFlux. It may be transitively enable by something else on the classpath if I had to guess.
However, it is nice to know that this exists

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/WebConfig.java) 

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

It is hard to save an image that has not been choosen by the user.
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

### Model Translation Component

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

### REST Image File Model

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

### REST Image Factory

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