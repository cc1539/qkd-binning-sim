
double entropy(double p) {
  return (p>0&&p<1)?(-(p*Math.log(p)+(1-p)*Math.log(1-p))/Math.log(2)):0;
}

double statisticalRandomness(boolean[] in) {
  // only the quantity of '1's and '0's matter
  // we don't care about their distribution throughouet the stream
  int ones = 0;
  for(int i=0;i<in.length;i++) {
    if(in[i]) {
      ones++;
    }
  }
  return (double)ones/in.length;
}

double structuralRandomness(boolean[] in) {
  // when there are lots of "streaks", the value is low
  // when '1's and '0's are maximally "mixed", the value is high
  int changes = 0;
  for(int i=1;i<in.length;i++) {
    if(in[i]!=in[i-1]) {
      changes++;
    }
  }
  return entropy((double)changes/(in.length-1));
}

double maxStructuralRandomness(double p) {
  return 1;
}

double randomness(boolean[] in) {
  double p = statisticalRandomness(in);
  return entropy(p)*structuralRandomness(in)/maxStructuralRandomness(p);//*(1-repetitivity(in));
}
