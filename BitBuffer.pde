
/*
 * space-efficient bit buffer
 * could've just used booleans but apparently booleans are
 * internally stored as whole a*s integers on the stack
 * and as whole a*s bytes on the heap, and that didn't feel
 * right
 *
 * so here i basically reduce space usage by 7/8 since i use
 * each byte to hold 8 boolean values
 *
 * this is essentially a bit queue and didn't have to be so
 * complicated but this is just how it is
 */
public static class BitBuffer implements BitStream {
  
  // the "bins" here don't have anything to do with the bins in the
  // framing algorithms
  public static final int BIN_SIZE = 32;
  public static final int BIN_BITS = BIN_SIZE*8;
  
  private final ArrayList<byte[]> bins = new ArrayList<byte[]>();
  private int readIndex = 0;
  private int writeIndex = 0;
  
  // whether we should delete bins that are behind the read index
  // if we're going to "seek" to the beginning we should remember
  private boolean remember;
  
  public BitBuffer() {}
  
  public BitBuffer(boolean remember) {
    this.remember = remember;
  }
  
  public boolean ready() {
    return readIndex<writeIndex;
  }
  
  public boolean read() {
    
    if(!ready()) {
      return false;
    }
    
    // if we've gone far enough with the read index then
    // delete the bin we just went past if we know we won't
    // be going back with "seek"
    if(!remember && readIndex>BIN_BITS) {
      readIndex -= BIN_BITS;
      writeIndex -= BIN_BITS;
      bins.remove(0);
    }
    
    int binIndex = readIndex/BIN_BITS;
    int byteIndex = (readIndex%BIN_BITS)/8;
    int bitIndex = readIndex%8;
    readIndex++;
    
    return (bins.get(binIndex)[byteIndex]&(1<<bitIndex))!=0;
  }
  
  public void write(boolean bit) {
    //println("{"+(bit?'1':'0')+"}");
    
    // add "bins" until the amount of bits reaches the writeIndex
    int binIndex = writeIndex/BIN_BITS;
    while(binIndex>=bins.size()) {
      bins.add(new byte[BIN_SIZE]);
    }
    
    // then actually write in the bit
    if(bit) {
      int byteIndex = (writeIndex%BIN_BITS)/8;
      int bitIndex = writeIndex%8;
      bins.get(binIndex)[byteIndex] += 1<<bitIndex;
    }
    
    writeIndex++;
  }
  
  public byte readByte() {
    byte num = 0;
    for(int i=0;i<8;i++) {
      if(read()) { num += 1<<i; }
    }
    return num;
  }
  
  public int readInt() {
    int num = 0;
    for(int i=0;i<32;i++) {
      if(read()) { num += 1<<i; }
    }
    return num;
  }
  
  public void writeByte(byte num) {
    for(int i=0;i<8;i++) {
      write((num&(1<<i))!=0);
    }
  }
  
  public void writeInt(int num) {
    for(int i=0;i<32;i++) {
      write((num&(1<<i))!=0);
    }
  }
  
  public void clear() {
    readIndex = 0;
    writeIndex = 0;
    bins.clear();
  }
  
  public void seek(int index) {
    readIndex = index;
  }
  
}
