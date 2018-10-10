---
layout: post
---

Writing Code!
---

### Water Repository! 

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
        long goalAmount = liquidContainer.fetchTotalCapacity() / 2;
        Liquid currentVolume = liquidContainer.fetchCurrentVolume().isPresent() ?
                liquidContainer.fetchCurrentVolume()
                        .filter(liquid -> liquid.getAmount() <= goalAmount)
                        .orElseThrow(() -> new IllegalStateException("Container is too full!")) :
                waterSupply.fetchWater(0);

        liquidContainer.storeLiquid(waterSupply.fetchWater(goalAmount - currentVolume.getAmount()));
        return liquidContainer;
    }
}
{% endhighlight %}

### Liquid Object Implementation! 

{% highlight java %}
//....
public class Liquid {
    private long amount;
    Function<Long, ? extends Liquid> instanceFactory = Liquid::new;

    /**
     * @param amount any number above -1
     * @throws IllegalArgumentException if given any number below zero
     */
    Liquid(long amount) {
        this.amount = sanitizeVolume(amount)
                .orElseThrow(() -> new IllegalArgumentException("Cannot create liquid instance with value " + amount));
    }

    private Optional<Long> sanitizeVolume(long amount) {
        return Optional.of(amount)
                .filter(aLong -> aLong > -1);
    }

    public long getAmount() {
        return amount;
    }

    /**
     * Moves the amount of liquid provided to this instance.
     *
     * @param liquid liquid to be drained and added to this instance.
     * @return this liquid instance with the added amount from the liquid provided.
     */
    public Liquid addLiquid(Liquid liquid) {
        this.amount = liquid.reduceVolumeBy(liquid.getAmount())
                .map(Liquid::getAmount)
                .orElse(0L) + getAmount();
        return this;
    }

    /**
     * Reduces the amount of liquid stored in this instance.
     * <p>
     * Will not return any liquid if asked more than the current amount
     * stored in instance.
     *
     * @param volumeToReduceBy the amount of liquid to remove from this instance
     * @return The amount of liquid ranging from 0 to current volume.
     */
    public Optional<? extends Liquid> reduceVolumeBy(long volumeToReduceBy) {
        return sanitizeVolume(volumeToReduceBy)
                .flatMap(this::reduceAmount);
    }

    private Optional<? extends Liquid> reduceAmount(long volume) {
        return sanitizeVolume(volume)
                .filter(goodVolume -> goodVolume <= getAmount())
                .map(reducingVolume -> {
                    this.amount = getAmount() - reducingVolume;
                    return reducingVolume;
                })
                .map(instanceFactory);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Liquid)) return false;
        Liquid liquid = (Liquid) o;
        return amount == liquid.amount;
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount);
    }
}


{% endhighlight %}


### Liquid Container Implementation!

{% highlight java %}
//....
public class SimpleLiquidContainer implements LiquidContainer {
    private final long maxCapacity;
    private Liquid liquidStored;

    public SimpleLiquidContainer(long maxCapacity) {
        this.maxCapacity = Optional.of(maxCapacity)
                .filter(c -> c > -1)
                .orElseThrow(() -> new IllegalArgumentException("Cannot store liquid amounts less than zero!"));
    }

    @Override
    public long fetchTotalCapacity() {
        return maxCapacity;
    }

    @Override
    public Liquid storeLiquid(Liquid liquid) {
        Optional<Liquid> optionalLiquid = fetchCurrentVolume();
        if (optionalLiquid.isPresent()) {
            Liquid currentLiquid = optionalLiquid.get();
            this.liquidStored = currentLiquid.addLiquid(pourCorrectAmount(liquid));
        } else if (liquid.getAmount() > maxCapacity) {
            this.liquidStored = liquid.reduceVolumeBy(maxCapacity).orElseThrow(()->new IllegalStateException("Should have been able to remove max capacity amount of liquid!"));
        } else {
            this.liquidStored = liquid.reduceVolumeBy(liquid.getAmount()).orElseThrow(() -> new IllegalStateException("Should have been able to reduce by current amount!"));
        }
        return liquidStored;
    }

    private Liquid pourCorrectAmount(Liquid liquid) {
        long capacityLeft = maxCapacity - fetchCurrentVolume()
                .map(Liquid::getAmount)
                .orElse(0L);
        boolean willStillBeEmpty = capacityLeft > liquid.getAmount();
        return willStillBeEmpty ?
                liquid :
                liquid.reduceVolumeBy(capacityLeft).orElseThrow(() -> new IllegalStateException("Should have gotten liquid!!"));
    }

    @Override
    public Optional<Liquid> fetchCurrentVolume() {
        return Optional.ofNullable(liquidStored);
    }
}

{% endhighlight %}


### Water Supply Implementation!

{% highlight java %}
//....
public class WaterFaucet implements WaterSupply {
    @Override
    public Water fetchWater(long desiredAmount) {
        return new Water(desiredAmount);
    }
}

{% endhighlight %}
