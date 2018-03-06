---
layout: post
---

HTTP Client Implementation
---

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
