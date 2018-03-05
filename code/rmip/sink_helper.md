---
layout: post
---

Subscriber helper
---

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/mono/MonoSinkHelper.java)

{% highlight java %}
    //...
    public class MonoSinkHelper<T>{
    
      private final MonoSink<T> monoSink;
      private boolean disposed = false;
    
      public MonoSinkHelper(MonoSink<T> monoSink) {
        this.monoSink = monoSink;
        monoSink.onDispose(this::disposed);
      }
    
      public void success(){
        this.monoSink.success();
      }
    
      public void success(T t){
        this.monoSink.success(t);
      }
    
      public void error(Throwable t){
        this.monoSink.error(t);
      }
    
      public boolean isDisposed() {
        return disposed;
      }
    
      private void disposed() {
        disposed = true;
      }
    }
{% endhighlight %}