---
layout: post
---

Remote Image Factory
---


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