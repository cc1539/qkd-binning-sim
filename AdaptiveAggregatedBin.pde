
public static class AdaptiveAggregatedBin extends SimpleBin {
  
  private final BitBuffer memory = new BitBuffer(true);
  
  private int l; // photon count in frame
  private final BitBuffer publicChannel = new BitBuffer();
  
  public BitBuffer getPublicChannel() {
    return publicChannel;
  }
  
  public void write(boolean bit) {
    //memory.remember = true;
    memory.write(bit);
    if(bit) {
      l++;
    }
    if(++bitIndex>=frameSize) {
      bitIndex = 0;
      
      if(l>frameSize/2) {
        l = frameSize-l;
      }
      if(l>0) {
        
        binSize = 1;
        while(binSize<l) {
          binSize *= 2;
        }
        
        // log(frameSize/binSize) bits of completely random information
        int randomBin = 0;
        for(int i=0,n=frameSize/binSize;n>1;i++) {
          boolean randomBit = Math.random()>.5;
          out.write(randomBit);
          if(randomBit) {
            randomBin += 1<<i;
          }
          n /= 2;
        }
        publicChannel.writeInt(randomBin);
        
        l = 0;
      }
      
      memory.clear();
    }
  }
  
}
