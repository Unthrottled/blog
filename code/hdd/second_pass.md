{% highlight java %}
//....
public interface LiquidContainer {
    /**
     * @return the total volume container, regardless of fill level.
     */
    long fetchTotalCapacity();

    /**
     * Fills the container with the desired amount of water.
     *
     * @param liquid desired amount of water to place in container, must be greater than zero
     * @return amount of liquid stored in container
     */
    Liquid storeLiquid(Liquid liquid);

    /**
     * @return The amount of liquid currently stored in the container.
     */
    Optional<Liquid> fetchCurrentVolume();
}

{% endhighlight %}

> ^ Now there is an a defined type to represent the abstraction of water. 
> There is no need for any API (other than the water API) to always have to check for incorrect values!
> Also it made more sense to make fetching the current amount of liquid to return an optional.
> As a container can not have any liquid in it, almost as if it is _optional_.

{% highlight java %}
//....
public interface WaterSupply {

    /**
     * @param desiredAmount the amount of water to retrieve from
     *                      the water supply
     * @return the requested amount of water that can be supplied each invocation
     * @throws IllegalArgumentException if given a number less than zero
     */
    Water fetchWater(long desiredAmount);

}

{% endhighlight %}

> ^ The maximum fetchable water method was more of an implementation detail of this interface.
> It unnecessarily couples any class using it to the current constraints of its implementation.
> IE, the water supply may provide water via other containers. 
> Those containers have a fixed amount of water and calling to fetch water gives one container of water.
> Like filling the cup with a water bottle.
> That's how it works in the real world (sometimes), however it is a silly design.
> Just make it so that when water is asked for, give the amount that is needed. 
> How it happens is up to the implementation of the class. 

{% highlight java %}
//....
public class WaterRepository {
    private final WaterSupply waterSupply;

    public WaterRepository(WaterSupply waterSupply) {
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
    public LiquidContainer fillContainerHalfWay(LiquidContainer liquidContainer) {
        return liquidContainer;
    }
}
{% endhighlight %}

> ^ The requirement is: given a half filled or less cup, I expect the cup to be return filled half way with water.
> It is expected that the API only accepts half filled or less containers.

{% highlight java %}
//....
public class Liquid {
    private final long amount;

    /**
     * @param amount any number above -1
     * @throws IllegalArgumentException if given any number below zero
     */
    Liquid(long amount) {
        this.amount = amount;
    }

    public long getAmount() {
        return amount;
    }
}

{% endhighlight %}

> ^ The new abstraction of things that can go into containers. 

{% highlight java %}
//....
public class Water extends Liquid {

    public Water(long amount) {
        super(amount);
    }
}
{% endhighlight %}

> ^ The water type definition, hurray polymorphism! Is this over-engineering? I do not know. 
