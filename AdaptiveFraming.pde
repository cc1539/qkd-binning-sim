
public static class AdaptiveFraming extends SimpleBin {
  
  private final BitBuffer memory = new BitBuffer(true); // we use this to save the entire frame
  
  private int l; // photon count in current frame
  private final BitBuffer publicChannel = new BitBuffer();
  
  private float theoreticalBitOut;
  
  public BitBuffer getPublicChannel() {
    return publicChannel;
  }
  
  // write a random number with number of bits
  // equal to the smallest power of 2 greater 
  // than or equal to frameSize
  private void writeRandom(int frameSize) {
    /*
    int n = 1;
    while(n<frameSize) {
      n *= 2;
    }
    int randomNum = 0;
    for(int i=0;n>0;i++) {
      boolean bit = Math.random()>.5;
      out.write(bit);
      if(bit) {
        randomNum += 1<<i;
      }
      n /= 2;
    }
    publicChannel.writeInt(randomNum);
    */
    theoreticalBitOut += log(frameSize)/log(2);
    while(theoreticalBitOut>=1) {
      boolean bit = Math.random()>.5;
      out.write(bit);
      theoreticalBitOut--;
    }
  }
  
  public void write(boolean bit) {
    //memory.remember = true;
    memory.write(bit);
    if(bit) { l++; } // count photon
    if(++bitIndex>=frameSize) {
      bitIndex = 0;
      
      if(l>frameSize/2) {
        l = frameSize-l;
      }
      if(l>0) {
        
        // split up frame into subframes
        // as evenly as possible, with each
        // subframe containing one photon
        int r = frameSize%l;
        int m = frameSize/l;
        for(int i=0;i<r;i++) {
          writeRandom(m+1);
        }
        for(int i=0;i<l-r;i++) {
          writeRandom(m);
        }
        
        l = 0;
      }
      
      memory.clear();
    }
  }
  
  public float getTheoreticalRawKeyRate(float p) {
    int n = frameSize;
    
    if(n>32) { // above n=32 we start to suffer from underflow AND overflow, and need to use BigDecimal and BigInteger together
      BigDecimal rate = BigDecimal.ZERO;
      for(int l=1;l<=n-1;l++) {
        int r = n%((l<=n/2)?l:(n-l));
        int m = n/((l<=n/2)?l:(n-l));
        double rho = (r*Math.log(m+1)+((l<=n/2)?(l-r):(n-l-r))*Math.log(m))/Math.log(2);
        rate = rate.add(
          new BigDecimal(choose(n,l))
          .multiply(new BigDecimal(rho))
          .multiply(new BigDecimal(p).pow(l))
          .multiply(new BigDecimal(1-p).pow(n-l)));
      }
      rate = rate.divide(new BigDecimal(n));
      return rate.floatValue();
    }
    
    double rate = 0;
    for(int l=1;l<=n-1;l++) {
      int r = n%((l<=n/2)?l:(n-l));
      int m = n/((l<=n/2)?l:(n-l));
      double rho = (r*Math.log(m+1)+((l<=n/2)?(l-r):(n-l-r))*Math.log(m))/Math.log(2);
      rate += choose(n,l).intValue()*rho*Math.pow(p,l)*Math.pow(1-p,n-l);
      /*
      double term = choose(n,l)*rho;
      term = Math.log(term)+(n-l)*Math.log(1-p)+l*Math.log(p)+Math.log(10)*n;
      rate += Double.isNaN(term)?0:(Math.exp(term)/Math.pow(10,n));
      //rate += term;
      */
    }
    return (float)(rate/n);
  }
  
  public String getAbbreviation() {
    return "AF";
  }
  
}
