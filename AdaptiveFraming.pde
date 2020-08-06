
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
  
}
