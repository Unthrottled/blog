---
layout: post
---

Weblflux Rest Controller
---

[Link To File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/rest/RouterComponent.java)
{% highlight java %}
    //...
    @Component
    public class RouterComponent {
      private static final Logger LOGGER = LoggerFactory.getLogger(RouterComponent.class);
    
      private final ImageHandler imageHandler;
    
      @Autowired
      public RouterComponent(ImageHandler imageHandler) {
        this.imageHandler = imageHandler;
      }
    
      @Bean
      public RouterFunction<?> landingRouterFunction() {
        return RouterFunctions.nest(RequestPredicates.path("/api"),
            RouterFunctions.route(RequestPredicates.GET("/images"),
                request -> ServerResponse.ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(imageHandler.findAllNames(), Identifier.class))
                .andRoute(RequestPredicates.POST("/image/save"),
                    request -> ServerResponse.ok()
                        .body(imageHandler.saveImage(request.bodyToFlux(Part.class)), String.class))
                .andRoute(RequestPredicates.GET("/image/get/{id}"),
                    request -> ServerResponse.ok()
                        .body(imageHandler.fetchImage(request.pathVariable("id")), byte[].class))
                .andRoute(RequestPredicates.DELETE("/image/delete/{id}"),
                    request -> ServerResponse.ok()
                        .body(imageHandler.removeImage(request.pathVariable("id")), Boolean.class))
        ).andOther(RouterFunctions.resources("/**", new ClassPathResource("static/")));
      }
{% endhighlight %}