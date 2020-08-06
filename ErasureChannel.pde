
/*
 * simulates loss of photons with some probability
 * not used anywhere yet
 */ 
public static class ErasureChannel extends BitBuffer {
  
  private float p;
  
  public void setEraseProbability(float value) {
    p = value;
  }
  
  public float getEraseProbability() {
    return p;
  }
  
  public boolean read() {
    boolean bit = super.read();
    return bit?(Math.random()<p):false;
  }
  
}
