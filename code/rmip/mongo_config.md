---
layout: page
---

Spring configuration for Reactive Mongo.
---

[Link to File](https://github.com/cyclic-reference/mongo-images/blob/master/web-service/src/main/java/io/acari/images/configuration/MongoConfig.java)
{% highlight java %}

    //....
    
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