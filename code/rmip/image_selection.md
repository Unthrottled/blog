---
layout: post
---

Image selection component
---

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