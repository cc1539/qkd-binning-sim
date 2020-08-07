
public static class SimpleBin implements BitStream {
  
  protected int frameSize; // n
  protected int binSize; // k
  
  protected int bitIndex; // which bit in the frame are we currently looking at?
  protected int binIndex; // which bin in the frame are we currently looking at?
  
  protected boolean binOccupied; // whether the bin we're currently looking at has been occupied by a photon
  protected int binFillIndex = -1; // the position of the last occupied bin, or -2 if we saw more than one occupied bin
  protected int binNullIndex = -1; // the position of the last empty bin, or -2 if we saw more than one empty bin
  protected boolean discarded; // whether the frame was just discarded at the last bit write
  
  // literal output of the binning scheme
  protected final BitBuffer out = new BitBuffer();
  
  public void setFrameSize(int frameSize) {
    this.frameSize = frameSize;
  }
  
  public void setBinSize(int binSize) {
    this.binSize = binSize;
  }
  
  public int getFrameSize() {
    return frameSize;
  }
  
  public int getBinSize() {
    return binSize;
  }
  
  public boolean ready() {
    return out.ready();
  }
  
  public boolean read() {
    return out.read();
  }
  
  public void write(boolean bit) {
    discarded = false;
    if(bit) {
      binOccupied = true;
    }
    if(++bitIndex>=binSize) {
      
      bitIndex = 0;
      
      if(binOccupied) {
        if(binFillIndex>=0 || binFillIndex==-2) {
          binFillIndex = -2;
        } else {
          binFillIndex = binIndex;
        }
      } else {
        if(binNullIndex>=0 || binNullIndex==-2) {
          binNullIndex = -2;
        } else {
          binNullIndex = binIndex;
        }
      }
      
      binOccupied = false;
      if(++binIndex*binSize>=frameSize) {
        if(binFillIndex>=0 || binNullIndex>=0) {
          
          // translate the position of the chosen bin in the frame
          // into binary and have that be the literal output
          int outIndex = binFillIndex>=0?binFillIndex:binNullIndex;
          for(int i=0,n=frameSize/binSize;n>1;i++) {
            out.write((outIndex&(1<<i))!=0);
            n /= 2;
          }
          
        } else {
          discarded = true;
        }
        binFillIndex = -1;
        binNullIndex = -1;
        binIndex = 0;
      }
      
    }
  }
  
  public void clear() {
    bitIndex = 0;
    binIndex = 0;
    
    binOccupied = false;
    binFillIndex = -1;
    binNullIndex = -1;
  }
  
  public float getTheoreticalRawKeyRate(float p) {
    float pik = 1-pow(1-p,binSize);
    if(binSize==frameSize) {
      return 0;
    } else if(binSize==frameSize/2) {
      return pik*(1-pik)/binSize;
    } else {
      return (pik*pow((1-pik),frameSize/binSize-1)+
              (1-pik)*pow(pik,frameSize/binSize-1))
              /binSize*log(frameSize/binSize)/log(2);
    }
  }
  
  public String getAbbreviation() {
    return "SB, k="+binSize;
  }
  
}
