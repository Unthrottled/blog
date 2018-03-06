---
layout: post
---

Remote `ProjectFile` Implementation
---

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