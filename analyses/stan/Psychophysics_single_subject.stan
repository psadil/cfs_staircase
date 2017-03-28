functions {
  real psycho_lpmf( int y, real x, int N, vector prm ) {
	  // Purpose:
	  // Calculates the log-likelihood for a piecewise logistic function.
	  // Arguments:
	  // y     - The number of successes
	  // x     - The log of the target contrast
	  // N     - The total number of trials
	  // prm   - A vector of 3 values
	  //         [1] alpha, the slope parameter
	  //         [2] beta, the criterion (value of x for 50% performance)
	  //         [3] kappa, the upper asymptote
	  // Returns:
	  // The probability of a correct response.
	  
	  // Variable declaration
	  real z; real theta; real out;
	  real alpha; real beta; real kappa;
	  
	  alpha = prm[1]; beta = prm[2]; kappa = prm[3];
	  
	  z = alpha*(x + beta);
	  theta = kappa/(1.0 + exp(-z) );
	  if ( theta < 0.5 ) theta = 0.5;
	
	  out = binomial_lpmf( y | N, theta );
	
	  return( out );
  }
}
data {
  int L; // Number of target contrast levels
  int N[L]; // Total number of trials per level
  int y[L]; // Total number of successes per level
  real x[L]; // Log of the target contrasts
}
parameters {
  real<lower=0.0> alpha;
  real<lower=0.0> beta;
  real<lower=0.5,upper=1.0> kappa;
}
model {
  // Variable declaration
  vector[L] summands;
  vector[3] prm;
  
  // Priors
  alpha ~ normal(8.0,2.0);
  beta ~ normal(2.0,1.0);
  kappa ~ normal(.75,0.15);
  
  // Likelihood
  for (l in 1:L) {
    prm[1] = alpha; prm[2] = beta; prm[3] = kappa;
    summands[l] = psycho_lpmf( y[l] | x[l], N[l], prm );
  }
  
  // Call to the sampler
  target += sum( summands );
}