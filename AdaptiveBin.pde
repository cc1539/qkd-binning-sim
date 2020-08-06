
public static class AdaptiveBin extends SimpleBin {
  
  private final BitBuffer memory = new BitBuffer(true);
  
  public void write(boolean bit) {
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
  
}
