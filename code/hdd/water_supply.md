---
layout: post
---

`WaterSupply` Design and Tests
---

>Here is the designed, un-implemented class that implements the `WaterSupply` interface.


{% highlight java %}
//....
public class WaterFaucet implements WaterSupply {
    @Override
    public Water fetchWater(long desiredAmount) {
        return null;
    }
}
{% endhighlight %}

> Here is the simple test to verify correctness!

{% highlight java %}
//....
public class WaterFaucetTest {

    @Test
    public void fetchWaterShouldReturnDesiredAmount() {
        Water expected =  new Water(42L);//if getting real water would be so easy!
        WaterFaucet waterFaucet = new WaterFaucet();
        Water result = waterFaucet.fetchWater(42L);
        Assertions.assertThat(result).isEqualTo(expected);
    }
    
    @Test
        public void fetchWaterShouldReturnDesiredAmountWhenGivenZero() {
            Water expected =  new Water(0L);
            WaterFaucet waterFaucet = new WaterFaucet();
            Water result = waterFaucet.fetchWater(0L);
            Assertions.assertThat(result).isEqualTo(expected);
        }
    
        @Test
        public void fetchWaterShouldThrowIllegalArgumentExceptionWhenGivenNumberLessThanZero() {
            try {
                new WaterFaucet().fetchWater(-1L);
                fail();
            } catch (IllegalArgumentException ignore){}
        }
}
{% endhighlight %}