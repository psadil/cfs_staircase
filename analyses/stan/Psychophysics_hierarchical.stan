functions {
  real f_psycho( real x, vector prm ) {
	  // Purpose:
	  // Calculates P(Correct) for a piecewise logistic function.
	  // Arguments:
	  // x     - The log of the target contrast
	  // prm   - A vector of 3 values
	  //         [1] alpha, the slope parameter
	  //         [2] beta, the criterion (value of x for 50% performance)
	  //         [3] kappa, the upper asymptote
	  // Returns:
	  // The probability of a correct response.
	  
	  // Variable declaration
	  real z; real theta;
	  real alpha; real beta; real kappa;
	  
	  alpha = prm[1]; beta = prm[2]; kappa = prm[3];
	  
	  z = alpha*(x + beta);
	  theta = kappa/(1.0 + exp(-z) );
	  if ( theta < 0.5 ) theta = 0.5;
	
	  return( theta );
  }
}
data {
  int S; // Number of subjects
  int L; // Number of target contrast levels
  int N[S*L]; // Total number of trials per level and subject
  int y[S*L]; // Total number of successes per level and subject
  real x[S*L]; // Log of the target contrasts
  int indS[S*L]; // Subject index
}
parameters {
  real<lower=0.0> alpha[S];
  real<lower=0.0> beta[S];
  real<lower=0.5,upper=1.0> kappa[S];
  real mu_alpha;
  real mu_beta;
  real mu_kappa;
  real<lower=0.0> sig_alpha;
  real<lower=0.0> sig_beta;
  real<lower=0.0> sig_kappa;
}
model {
  // Variable declaration
  real theta[S*L];
  vector[3] prm;
  int Nt;
  
  // Priors
  mu_alpha ~ normal(8.0,2.0);
  mu_beta ~ normal(2.0,1.0);
  mu_kappa ~ normal(.75,0.15);
  sig_alpha ~ normal(0.2,0.5);
  sig_beta ~ normal(0.2,0.5);
  sig_kappa ~ normal(0.2,0.5);
  
  // Hierarchy
  alpha ~ normal( mu_alpha, sig_alpha);
  beta ~ normal( mu_beta, sig_beta);
  kappa ~ normal( mu_kappa, sig_kappa);
  
  // Likelihood
  Nt = S*L;
  for (nt in 1:Nt) {
    prm[1] = alpha[ indS[nt] ];
    prm[2] = beta[ indS[nt] ];
    prm[3] = kappa[ indS[nt] ];
    theta[ nt ] = f_psycho( x[ nt ], prm );
  }
  y ~ binomial( N, theta );
  
}