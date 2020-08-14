
public static class RandomBitStream {
  
  private long positives;
  private long transitions;
  private long samples;
  
  private boolean lastBit;
  
  public void clear() {
    samples = 0;
    positives = 0;
    transitions = 0;
  }
  
  public void write(boolean bit) {
    if(samples==0) {
      lastBit = bit;
    }
    if(bit) {
      positives++;
    }
    if(lastBit!=(lastBit=bit)) {
      transitions++;
    }
    samples++;
  }
  
  public float getStatisticalRandomness() {
    return (float)entropy((double)positives/samples);
  }
  
  public float getStructuralRandomness() {
    return (float)entropy((double)transitions/samples);
  }
  
  public float getRandomness() {
    return getStatisticalRandomness()*getStructuralRandomness();
  }
  
  public static double entropy(double p) {
    return (p>0&&p<1)?(-(p*Math.log(p)+(1-p)*Math.log(1-p))/Math.log(2)):0;
  }

}
