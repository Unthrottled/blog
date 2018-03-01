---
layout: post
---

{% highlight java %}
//....

public interface LiquidContainer {
  /**
   * @return the total volume container, regardless of fill level.
   */
  long fetchTotalCapacity();

  /**
   * Fills the container with the desired amount of water.
   * @param volumeOfWater desired amount of water to place in container, must be greater than zero
   * @return amount of water stored in container
   * @throws IllegalStateException if given number lower than zero.
   */
  long storeWater(long volumeOfWater);

  /**
   * @return The amount of liquid currently stored in the container.
   */
  long fetchCurrentVolume();
}

{% endhighlight %}

{% highlight java %}
//....
public interface WaterSupply {

  /**
   * @param desiredAmount the amount of water to retrieve from
   *                      the water supply
   * @return the maximum amount of water that can be supplied each invocation
   * @throws IllegalArgumentException if given a number less than zero
   */
  long fetchWater(int desiredAmount);

  /**
   * @return the largest amount of water that can be returned from the water supply
   * per invocation.
   */
  long maximumFetchableWater();
}
{% endhighlight %}

{% highlight java %}
//....
public class WaterRepository {
  private final WaterSupply waterSupply;

  public WaterRepository(WaterSupply waterSupply){
    this.waterSupply = waterSupply;
  }

  /**
   * Fills the given container to the floor of the halfway mark.
   *
   * @param liquidContainer a container that is less than half full.
   * @return a container that is half full.
   * @throws IllegalArgumentException when given a more than half filled container
   *                                  (we are half full people here)
   */
  public LiquidContainer fillContainerHalfWay(LiquidContainer liquidContainer){
    return liquidContainer;
  }
}
{% endhighlight %}