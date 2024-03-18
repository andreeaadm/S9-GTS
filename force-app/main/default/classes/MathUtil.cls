public class MathUtil {
    /**
     * Return a random number between the minimum and maximum parameters.
     *
     * @param  Integer  min
     * @param  Integer  max
     * @return Integer
     */
    public static Integer random(Integer min, Integer max) {
        return (Integer)Math.floor(Math.random() * (max - min + 1) + min);
    }
}