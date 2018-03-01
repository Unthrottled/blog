---
layout: post
---
{% highlight java %}
//....
public class SimpleLiquidContainer implements LiquidContainer {
    private final long maxCapacity;
    private Liquid currentCapacity;

    public SimpleLiquidContainer(long maxCapacity) {
        this.maxCapacity = maxCapacity;
    }

    @Override
    public long fetchTotalCapacity() {
        return maxCapacity;
    }

    @Override
    public Liquid storeLiquid(Liquid liquid) {
        return null;
    }

    @Override
    public Optional<Liquid> fetchCurrentVolume() {
        return Optional.ofNullable(currentCapacity);
    }
}
{% endhighlight %}

{% highlight java %}
//....
import org.junit.Test;

import java.util.Optional;

import static org.junit.Assert.*;

public class SimpleLiquidContainerTest {


    @Test
    public void constructorShouldThrowIllegalArgumentExceptionWhenGivenNegativeValue() {
        try {
            new SimpleLiquidContainer(-1);
            fail();
        } catch (IllegalArgumentException ignored) {
        }
    }

    @Test
    public void fetchTotalCapacityShouldReturnValueConstructedWith() {
        long input = 500L;
        long expectedResult = 500L;
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        long result = testSubject.fetchTotalCapacity();
        assertEquals(expectedResult, result);
    }

    @Test
    public void storeLiquidShouldStoreReturnMaxCapacityWhenGivenValueEqualToTotalCapacity() {
        long input = 500L;
        Liquid expectedResult = new Water(500L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        Liquid result = testSubject.storeLiquid(new Water(input));
        assertEquals(expectedResult, result);
    }

    @Test
    public void storeLiquidShouldStoreReturnMaxCapacityWhenGivenValueGreaterThanTotalCapacity() {
        long input = 500L;
        Liquid expectedResult = new Water(500L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        Liquid result = testSubject.storeLiquid(new Water(input + 1L));
        assertEquals(expectedResult, result);
    }

    @Test
    public void storeLiquidShouldStoreReturnDesiredAmountWhenGivenValueLessThanTotalCapacity() {
        long input = 500L;
        Liquid expectedResult = new Water(499L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        Liquid result = testSubject.storeLiquid(new Water(input - 1L));
        assertEquals(expectedResult, result);
    }

    @Test
    public void storeLiquidShouldStoreReturnMaxCapacityWhenGivenValueOneLessThanTotalCapacityTwice() {
        long input = 500L;
        Liquid expectedResult = new Water(500L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        Liquid testInput = new Water(input - 1L);
        testSubject.storeLiquid(testInput);
        Liquid result = testSubject.storeLiquid(testInput);
        assertEquals(expectedResult, result);
    }

    @Test
    public void fetchCurrentVolumeReturnMaxCapacityWhenGivenValueEqualToTotalCapacity() {
        long input = 500L;
        Liquid expectedResult = new Water(500L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        testSubject.storeLiquid(new Water(input));
        Optional<Liquid> result = testSubject.fetchCurrentVolume();
        assertTrue(result
                .map(expectedResult::equals)
                .orElse(false));
    }

    @Test
    public void fetchCurrentVolumeReturnMaxCapacityWhenGivenValueGreaterThanTotalCapacity() {
        long input = 500L;
        Liquid expectedResult = new Water(500L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        testSubject.storeLiquid(new Water(input + 1));
        Optional<Liquid> result = testSubject.fetchCurrentVolume();
        assertTrue(result
                .map(expectedResult::equals)
                .orElse(false));
    }

    @Test
    public void fetchCurrentVolumeReturnDesiredAmountWhenGivenValueLessThanTotalCapacity() {
        long input = 500L;
        Liquid expectedResult = new Water(499L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        testSubject.storeLiquid(new Water(input - 1));
        Optional<Liquid> result = testSubject.fetchCurrentVolume();
        assertTrue(result
                .map(expectedResult::equals)
                .orElse(false));
    }

    @Test
    public void fetchCurrentVolumeReturnMaxCapacityWhenGivenValueOneLessThanTotalCapacityTwice() {
        long input = 500L;
        Liquid expectedResult = new Water(500L);
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        testSubject.storeLiquid(new Water(input - 1));
        testSubject.storeLiquid(new Water(input - 1));
        Optional<Liquid> result = testSubject.fetchCurrentVolume();
        assertTrue(result
                .map(expectedResult::equals)
                .orElse(false));
    }

    @Test
    public void fetchCurrentVolumeShouldReturnZeroWhenNoWaterHasBeenStored() {
        long input = 500L;
        SimpleLiquidContainer testSubject = new SimpleLiquidContainer(input);
        Optional<Liquid> result = testSubject.fetchCurrentVolume();
        assertTrue(!result.isPresent());
    }
}
{% endhighlight %}
