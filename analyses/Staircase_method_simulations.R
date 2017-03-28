#-------------------------------------------#
# Development of a stair-case algorithm for #
# the gabor priming task                    #
# Kevin Potter                              #
#-------------------------------------------#

runCode = c( F, T, F )

### Generative model ###

# A mixture model combining a piece-wise logistic function that 
# truncates at 50% accuracy with a 10% chance of a pure guessing 
# response

alpha = 7; beta = 2.9; lambda = .1

f_theta = function(x,alpha,beta) {
	
	z = alpha*(x + beta)
	theta = 1/( 1 + exp( -z ) )
	theta[ theta < .5 ] = .5
	
	return( theta )
}

g_theta = function( theta, alpha, beta ) {
	
	if ( theta == .5 ) {
		x = -beta
	} else {
		x = log( theta/(1-theta) )/alpha - beta
	}
	
	return( x )
}

### Visual example of model ###

if ( runCode[1] ) {
	
	N = 36
	x = seq( -3, -2, length = 100 )
	p_correct = f_theta( x, alpha, beta )
	
	like = p_correct*(1-lambda) + .5*lambda
	
	x11();
	plot( x, like, type = 'l', ylim = c(0,1), bty = 'l', 
				xlab = 'Log contrast', ylab = 'P(Correct)' )
	abline( h = c(.5,.9), lty = 2 )
	
}

### An example of the stair-case method ###

# Define parameters
crit = .75 # Desired level of accuracy
N_width = 10 # Width of interval for moving average
N_int = 8 # Number of intervals to assess
N_total = N_int * N_width # Total number of trials

# Define window within which no changes should occur
stable_win = qbinom( c(.25,.75), N_width, crit )/N_width

# Initial starting value for log of target contrast
x_cur = -2
# Size of change to log of target contrast during each interval
x_change = seq( .5, .1, length = N_int)

# Define the stair-case algorithm
staircase_algorithm = function( y, x_cur, x_change, 
																interval, stable_win, N_width ) {
	
	# Set window for moving average
	interval[1:(N_width-1)] = interval[2:N_width]
	interval[N_width] = y
	
	est_ac = NULL
	if ( cnt == N_width ) {
		
		est_ac = mean( interval )
		
		if (est_ac < stable_win[1] ) {
			x_cur = x_cur + x_change
		}
		if (est_ac > stable_win[2]) {
			x_cur = x_cur - x_change
		}
		cnt = 1;
	} else {
		cnt = cnt + 1;
	}
	
	return( list( 
		est_ac = est_ac,
		x_cur = x_cur,
		cnt = cnt,
		interval = interval ) )
}


if ( runCode[2] ) {
	
	theta = rep( NA, N_total )
	interval = rep( NA, N_width )
	mv_avg = rep( NA, N_int )
	all_x = rep( NA, N_total )
	cnt = 1;
	inc = 1;
	y = rep( NA, N_total )
	
	# Loop through trials
	for (n in 1:N_total) {
		
		# Save current log contrast value
		all_x[n] = x_cur
		
		# True probability
		theta[n] = f_theta( x_cur, alpha, beta )
		if ( runif(1) < lambda ) theta[n] = .5
		
		# Simulate data
		y[n] = rbinom( 1, 1, theta[n] )
		
		# Apply stair-case algorithm
		tmp = staircase_algorithm( y[n], x_cur, x_change[inc], interval, 
												 stable_win, N_width )
		x_cur = tmp$x_cur
		interval = tmp$interval
		cnt = tmp$cnt
		if (cnt == 1) {
			mv_avg[inc] = tmp$est_ac
			inc = inc + 1;
		}
		rm( tmp )
		
	}
	
	sel = min( which( mv_avg < crit ) )
	rng = seq( N_width,N_total,N_width)
	final_x = mean( all_x[ rng[sel:N_int] ] )
		
	x11()
	layout( cbind(1,2) )
	
	plot( 1:(N_total/N_width), mv_avg, type = 'l', 
				ylim = c(0,1), xlab = 'Trials', ylab = 'Moving average', 
				bty = 'l' )
	abline( h = crit, lty = 2 )
	est_p = (1-lambda)*f_theta( final_x, alpha, beta ) + lambda*.5
	abline( h = est_p, col = 'blue' )
	
	plot( 1:N_total, all_x, type = 'l', bty = 'l', xlab = 'Trials', 
				ylab = 'Log contrast' )
	abline( h = g_theta(crit,alpha,beta), lty = 2 )
	abline( h = final_x, col = 'blue' )
	
}

### Simulation study ###

if ( runCode[3] ) {
	
	nRep = 100
	final_x = rep( NA, nRep )
	
	for (nr in 1:nRep) {
		
		interval = rep( NA, N_width )
		mv_avg = rep( NA, N_int )
		all_x = rep( NA, N_int )
		cnt = 1;
		inc = 1;
		
		# Loop through trials
		for (n in 1:N_total) {
			
			# Save current log contrast value
			all_x[inc] = x_cur
			
			# True probability
			theta = f_theta( x_cur, alpha, beta )
			if ( runif(1) < lambda ) theta[n] = .5
			
			# Simulate data
			y = rbinom( 1, 1, theta )
			
			# Apply stair-case algorithm
			tmp = staircase_algorithm( y, x_cur, x_change[inc], interval, 
																 stable_win, N_width )
			x_cur = tmp$x_cur
			interval = tmp$interval
			cnt = tmp$cnt
			if (cnt == 1) {
				mv_avg[inc] = tmp$est_ac
				inc = inc + 1;
			}
			rm( tmp )
			
		}
		
		sel = min( which( mv_avg < crit ) )
		final_x[nr] = mean( all_x[ sel:N_int ] )
		
	}
	
	x11()
	truth = g_theta( crit, alpha, beta )
	plot( 1:nRep, truth - final_x, pch = 19 )
	abline( h = 0, lty = 2 )
	abline( h = mean( truth - final_x ), col = 'red' )
	
}
