---
layout: post
---

`WaterRepository` Tests!
---

{% highlight java %}
//....
public class WaterRepositoryTest {

    @Test
    public void fillContainerHalfWayShouldReturnAContainerThatIsHalfFull() {
        WaterSupply waterSupply = Mockito.mock(WaterSupply.class);
        Mockito.when(waterSupply.fetchWater(250L)).thenReturn(new Water(250L));
        WaterRepository testSubject = new WaterRepository(waterSupply);
        LiquidContainer simpleLiquidContainer = new SimpleLiquidContainer(500);
        LiquidContainer result = testSubject.fillContainerHalfWay(simpleLiquidContainer);
        assertTrue(result.fetchCurrentVolume()
                .map(new Water(250)::equals)
                .orElse(false));
    }


    @Test
    public void fillContainerHalfWayShouldReturnAContainerThatIsHalfFull_II() {
        WaterSupply waterSupply = Mockito.mock(WaterSupply.class);
        Mockito.when(waterSupply.fetchWater(500L)).thenReturn(new Water(500L));
        WaterRepository testSubject = new WaterRepository(waterSupply);
        LiquidContainer simpleLiquidContainer = new SimpleLiquidContainer(1000);
        LiquidContainer result = testSubject.fillContainerHalfWay(simpleLiquidContainer);
        assertTrue(result.fetchCurrentVolume()
                .map(new Water(500)::equals)
                .orElse(false));
    }


    @Test
    public void fillContainerHalfWayShouldReturnAContainerThatIsHalfFullAndIsOdd() {
        WaterSupply waterSupply = Mockito.mock(WaterSupply.class);
        Mockito.when(waterSupply.fetchWater(131L)).thenReturn(new Water(131L));
        WaterRepository testSubject = new WaterRepository(waterSupply);
        LiquidContainer simpleLiquidContainer = new SimpleLiquidContainer(263);
        LiquidContainer result = testSubject.fillContainerHalfWay(simpleLiquidContainer);
        assertTrue(result.fetchCurrentVolume()
                .map(new Water(131)::equals)
                .orElse(false));
    }
}
{% endhighlight %}
