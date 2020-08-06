
public static interface BitStream {
  public boolean ready(); // whether there are still bits to read at the moment
  public boolean read(); // read in a literal bit
  public void write(boolean bit); // write a literal bit
}
