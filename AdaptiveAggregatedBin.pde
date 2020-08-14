
public static class AdaptiveAggregatedBin extends SimpleBin {
  
  private final BitBuffer memory = new BitBuffer(true);
  
  private int l; // photon count in frame
  private final BitBuffer publicChannel = new BitBuffer();
  
  public BitBuffer getPublicChannel() {
    return publicChannel;
  }
  
  public void write(boolean bit) {
    if(refractoryTimeout>0) {
      refractoryTimeout--;
      bit = false;
    }
    //memory.remember = true;
    memory.write(bit);
    if(bit) {
      refractoryTimeout = refractoryPeriod;
      l++; // count photon
    }
    if(++bitIndex>=frameSize) {
      bitIndex = 0;
      
      /*
      if(l>frameSize/2) {
        l = frameSize-l;
      }
      */
      if(l>0 && l<frameSize) {
        
        binSize = (int)pow(2,(l<=frameSize/2)?CommonMath.log2ceil(l):CommonMath.log2floor(frameSize-l));
        
        // log(frameSize/binSize) bits of completely random information
        int randomBin = 0;
        for(int i=0,n=CommonMath.log2ceil(frameSize/binSize);i<n;i++) {
          boolean randomBit = Math.random()>.5;
          out.write(randomBit);
          if(randomBit) {
            randomBin += 1<<i;
          }
        }
        publicChannel.writeInt(randomBin);
      }
      l = 0;
      
      memory.clear();
    }
  }
  
  public float getTheoreticalRawKeyRate(float p) {
    int n = frameSize;
    if(n>32) { // above n=32 we start to suffer from underflow AND overflow, and need to use BigDecimal and BigInteger together
      BigDecimal rate = BigDecimal.ZERO;
      for(int l=1;l<=n-1;l++) {
        rate = rate.add(
          new BigDecimal(CommonMath.choose(n,l))
          .multiply(new BigDecimal(p).pow(l))
          .multiply(new BigDecimal(1-p).pow(n-l))
          .multiply(new BigDecimal(CommonMath.log2ceil(n)-((l<=n/2)?CommonMath.log2ceil(l):CommonMath.log2floor(n-l)))));
      }
      return rate.divide(new BigDecimal(n)).floatValue();
    }
    float rate = 0;
    for(int l=1;l<=n-1;l++) {
      rate += CommonMath.choose(n,l).intValue()*pow(p,l)*pow(1-p,n-l)*(CommonMath.log2ceil(n)-((l<=n/2)?CommonMath.log2ceil(l):CommonMath.log2floor(n-l)));
    }
    return rate/n;
  }
  
  public String getAbbreviation() {
    return "AAB";
  }
  
}
