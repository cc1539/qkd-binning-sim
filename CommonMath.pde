
public static class CommonMath {
  
  public static double entropy(double p) {
    return (p>0&&p<1)?(-(p*Math.log(p)+(1-p)*Math.log(1-p))/Math.log(2)):0;
  }
  
  // math functions for calculation of theoretical raw key rates
  public static int log2ceil(float l) {
    int log2 = 0;
    for(int i=1;i<l;i*=2) {
      log2++;
    }
    return log2;
  }
  
  public static int log2floor(float l) {
    int log2 = 0;
    for(int i=1;i<l;i*=2) {
      log2++;
    }
    return log2-(pow(2,log2)==l?0:1);
    //return floor(log(l)/log(2));
  }
  
  public static BigInteger perm(int n, int k) {
    BigInteger a = BigInteger.ONE;
    for(long i=k+1;i<=n;i++) {
      a = a.multiply(new BigInteger(i+""));
    }
    return a;
  }
  
  public static BigInteger choose(int n, int k) {
    BigInteger a = perm(n,k);
    BigInteger b = perm(n,n-k);
    return (a.multiply(b).divide(perm(n,1)));
  }

}
