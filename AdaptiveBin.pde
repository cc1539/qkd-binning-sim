
public static class AdaptiveBin extends SimpleBin {
  
  private final BitBuffer memory = new BitBuffer(true);
  
  public void write(boolean bit) {
    if(refractoryTimeout>0) {
      refractoryTimeout--;
      bit = false;
    }
    if(bit) {
      refractoryTimeout = refractoryPeriod;
    }
    //memory.remember = true;
    memory.write(bit);
    if(++bitIndex>=frameSize) {
      bitIndex = 0;
      
      // just try values of k starting from 1
      // until we don't discard the frame
      // or k exceeds n (in which case we
      // ultimately discard the frame)
      binSize = 1;
      while(true) {
        while(memory.ready()) {
          super.write(memory.read());
        }
        if(discarded) {
          binSize *= 2;
          if(binSize>=frameSize) {
            break;
          }
          memory.seek(0);
        } else {
          break;
        }
      }
      
      memory.clear();
    }
  }
  
  public float getTheoreticalRawKeyRate(float p) {
    int n = frameSize;
    float rate = 0;
    
    for(int l=1;l<=n/2;l++) {
      for(int i=log2ceil(l);i<=log2ceil(n/2);i++) {
        int pow2i = (int)pow(2,i);
        rate += choose(pow2i,l).intValue()*pow(p,l)*pow(1-p,n-l)/pow2i;
      }
    }
    
    for(int i=0;i<=log2ceil(n/4);i++) {
      int pow2i = (int)pow(2,i);
      float pi2i = 1-pow(1-p,pow2i);
      rate += pow(pi2i,n/pow2i-1)*(1-pi2i)*(log2ceil(n)-i)/pow2i;
    }
    return rate;
  }
  
  public String getAbbreviation() {
    return "AB";
  }
  
}
