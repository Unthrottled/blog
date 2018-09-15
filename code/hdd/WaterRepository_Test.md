---
layout: post
---

`WaterRepository` Tests!
---

>It could be argued that the following test is not a _Unit Test_ per se and that it is more of an _Integration Test_.
Meaning that it does not just test a single class and that it tests the integration of many classes.
The following tests are coupled to the implementations of the dependent classes.
Breaking changes may be introduced and these tests may no longer pass.
So the author not only has to fix the class's tests, but this test as well.
There are arguments for and against this type of test, but this is the highest value test.


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
