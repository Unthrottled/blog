---
layout: post
headerImage: reach.png
tags: [Java, Spring Boot, Reactor, WebFlux, Mongodb, Reactive Streams, Angular, Gridfs]
---

This will be the paragraph that contains the excerpt. 


## Backend Setup

---

### Rest Controller

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/LandingRestController.java)
{% highlight java %}
    //...
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

### GridFS Component

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

### Spring Configuration

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

### Spring Application Property Configuration

[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/resources/application.yml)

### application.yml

        acari:
          mongo:
            connectionString: mongodb://mongo
            landingDatabase: images
        
        server:
          port: 80
          
          
---
          
# Frontend Setup


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

{% highlight javascript %}

    import {ProjectFile} from "./ProjectFile.model";
    import {Observable} from "rxjs/Observable";
    import {ReplaySubject} from "rxjs/ReplaySubject";
    import {Identifier} from "./Identifier.model";
    
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

{% highlight javascript %}

    import {Injectable} from "@angular/core";
    import {Observable} from "rxjs/Observable";
    import {BackendAPIService} from "../../services/BackendAPI.service";
    import {isDefined} from "../../util/Object.util";
    
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

{% highlight javascript %}

    import {Injectable} from "@angular/core";
    import {HttpClient} from "@angular/common/http";
    import {Observable} from "rxjs/Observable";
    
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



{% highlight javascript %}

    import {ProjectFile} from "./ProjectFile.model";
    import {Observable} from "rxjs/Observable";
    import {ReplaySubject} from "rxjs/ReplaySubject";
    import {Identifier} from "./Identifier.model";
    
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

{% highlight javascript %}

    import {Injectable} from "@angular/core";
    import {BackendAPIService} from "../../services/BackendAPI.service";
    import {WindowRef} from "../../util/window";
    import {RemoteProjectFile} from "../model/RemoteProjectFile";
    import {Identifier} from "../model/Identifier.model";
    import {Observable} from "rxjs/Observable";
    
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

{% highlight javascript %}
aoeu
{% endhighlight %}

{% highlight javascript %}
aoeu
{% endhighlight %}