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

    package io.acari.images;
    
    import com.mongodb.ConnectionString;
    import com.mongodb.async.client.MongoClientSettings;
    import com.mongodb.connection.ClusterSettings;
    import com.mongodb.connection.netty.NettyStreamFactoryFactory;
    import com.mongodb.reactivestreams.client.MongoClient;
    import com.mongodb.reactivestreams.client.MongoClients;
    import com.mongodb.reactivestreams.client.gridfs.GridFSBucket;
    import com.mongodb.reactivestreams.client.gridfs.GridFSBuckets;
    import io.netty.channel.nio.NioEventLoopGroup;
    import org.slf4j.Logger;
    import org.slf4j.LoggerFactory;
    import org.springframework.beans.factory.annotation.Autowired;
    import org.springframework.context.annotation.Bean;
    import org.springframework.context.annotation.Configuration;
    import org.springframework.core.env.Environment;
    import org.springframework.data.mongodb.config.AbstractReactiveMongoConfiguration;
    
    import javax.annotation.PreDestroy;
    
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

        acari:
          mongo:
            connectionString: mongodb://mongo
            landingDatabase: images
        
        server:
          port: 80


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
aoeu
{% endhighlight %}