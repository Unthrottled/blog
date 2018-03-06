---
layout: post
---

Image Visualisation Component
---

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