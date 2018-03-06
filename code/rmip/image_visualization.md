---
layout: post
---

Image Visualisation Component
---

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