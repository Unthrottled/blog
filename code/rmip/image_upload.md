---
layout: post
---

Uploading an Image
---


[Link To File](https://github.com/Unthrottled/mongo-images/blob/master/web-content/src/app/projectFiles/service/ImageUpload.service.ts)

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
