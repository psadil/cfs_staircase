#------------------------#
# Psychophysics analysis #
# Kevin Potter           #
# Updated 10/18/2016     #
#------------------------#

# Clear workspace
rm(list = ls())

# Load in useful packages
# library(devtools)
# install_github("rettopnivek/utilityf")
library(utilityf)
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

orig_dir = getwd() # Save current directory

runCode = c( F, T, T, F, T )
savePlot = T

if (savePlot) pdf('Psychophysics_results.pdf',width=12,height=6)

###
### Collate subject data
###
# Lookup - 01

if ( runCode[1] ) {
	
	setwd('..') # Navigate up one folder
	# Load in example data
	# setwd('Psychophysics_subjects')
	setwd('Psychophysics_subjects_v2')
	
	# Extract subject filenames
	allFiles = dir()
	SubjectFiles = allFiles[ grep( 'Subject_', allFiles ) ]
	SubjectFiles = SubjectFiles[ grep( '.csv', SubjectFiles ) ]
	
	N = length( SubjectFiles )
	
	allData = c()
	
	for (s in 1:N) {
		
		tmp = read.table( file = SubjectFiles[s], 
											sep = ',', header = T )
		allData = rbind( allData, tmp )
		
	}
	
	allData$OldID = allData$Subject
	allData$Subject = createIncrement( allData$Subject )
	
	# Return to original directory
	setwd( orig_dir )
	
	save( allData, N, file = 'Psychophysics_results_v2.RData' )
	
	# Clean up workspace
	rm( allFiles, SubjectFiles, tmp, s )
	
}

###
### Data pre-processing
###
# Lookup - 02

if ( runCode[2] ) {
	
	load( 'Psychophysics_results_v2.RData' )
	
	rawData = allData
	
	# Determine number of missing responses per subject
	# Trim subjects with more than 25% missing responses
	cnt = aggregate( rep(1,nrow(allData)), list( allData$Subject ), sum )
	tmp = aggregate( allData$Choice == 2, list( allData$Subject ), sum )
	missing = tmp$x/cnt$x
		
	# Separate practice/calibration/main trials and remove missing responses
	# sel = allData$BlockType == 0
	# pd = allData[ sel, ] # Practice trials
	sel = allData$BlockType == 1
	sa = allData[ sel, ] # Staircase trials
	sel = allData$Choice != 2 & allData$BlockType == 2
	d = allData[ sel, ] # Main data
	
	# Clean up workspace
	rm( sel, cnt, tmp )
}

###
### Descriptive statistics
###
# Lookup - 03

if ( runCode[3] ) {
	
	# Forgot to include practice trials in second psychophysics run
	Pract = F
	if (Pract) {
		
		### Practice trials ###
		
		# Proportion correct
		ac = aggregate( pd$Accuracy, list( 
			pd$TargetContrast, pd$FoilContrast, pd$Subject ), 
			mean )
		
		# Label columns
		colnames(ac) = c( 'TC','FC','S','P' )
		
		if (!savePlot) x11()
		tmp = matrix( 1:20, 4, 5, byrow = T )
		tmp[4,3] = N+1; tmp[4,4:5] = N+2
		layout( tmp )
		
		sbj = unique( ac$S )
		
		for (s in sbj) {
			
			par( mar = c(3,3,1,1) )
			plot( c(1,length( ac$P[ ac$S == s ] )), c(0,1), 
						type = 'n', xlab = ' ', ylab = ' ', 
						bty = 'l', xaxt = 'n' )
			abline( h = .5, lty = 2 )
			
			axis( 1, 1:length( ac$P[ ac$S == s ] ), 
						round( rev( log( ac$TC[ ac$S == s ] ) ), 2 ) )
			
			lines( 1:length( ac$P[ ac$S == s ] ), rev( ac$P[ ac$S == s ] ) )
			
			legend('bottomright',paste('Subject',s),bty='n')
			
		}
		blankPlot()
		blankPlot()
		legend('topleft','Practice trials',bty='n',cex=1.5)
		
	}
	
	### Calibration trials ###
	
	# Index for moving average intervals
	trial_int = rep( 1:8, each = 10 )
	trial_int = rep( trial_int, N )
	
	ac = aggregate( sa$Accuracy, list( trial_int, sa$Subject ), mean )
	tc = aggregate( sa$TargetContrast, list( trial_int, sa$Subject ), unique )
	colnames( ac ) = c('TI','S','P')
	colnames( tc ) = c('TI','S','TC')
	
	perf_thresh = numeric( N )
	
	if (!savePlot) x11()
	tmp = matrix( 1:20, 4, 5, byrow = T )
	tmp[4,3] = N+1; tmp[4,4:5] = N+2
	layout( tmp )
	
	sbj = unique( ac$S )
	
	for (s in sbj) {
		
		par( mar = c(3,3,1,2) )
		sel = ac$S == s
		plot( c(1,8), c(0,1), type = 'n', xlab = ' ', ylab = ' ',
					xaxt = 'n', yaxt = 'n' )
		
		polygon( c(1, 8, 8, 1 ), c(.8,.8,.7,.7),
						 col = 'grey', border = NA )
		
		axis(2,c(0,.5,1))
		axis(1,1:8,seq(10,80,10))
		lines( 1:8, ac$P[sel] )
		abline( h = .75, lty = 2 )
		par(new=TRUE)
		
		plot( c(1,8), c(0,.4), type = 'n', xlab = ' ', ylab = ' ',
					xaxt = 'n', yaxt = 'n' )
		axis(4,c(0,.2,.4))
		lines( 1:8, tc$TC[sel], col = 'blue' )
		par(new=FALSE)
		
		st = min( which( ac$P[ sel ] < .75 ) )
		perf_thresh[s] = mean( tc$TC[ sel ][ st:8 ] )
		
		abline( h = perf_thresh[s], col = 'blue', lty = 2 )
		
		legend( 'bottomleft', paste('Subject',s), bty = 'n' )
	}
	
	blankPlot()
	legend('topleft',c('Moving average','Target contrast'),
				 fill=c('black','blue'),
				 bty='n')
	blankPlot()
	legend('topleft','Calibration data',bty='n',cex=1.5)
	
	### Psychophysics trials
	
	# Proportion correct
	ac = aggregate( d$Accuracy, list( 
		d$TargetContrast, d$FoilContrast, d$Subject ), 
		mean )
	acDur = aggregate( d$Accuracy, list( 
		d$TargetContrast, d$FoilContrast, d$Subject, d$PrimeType, d$PrimeDuration ), 
		mean )
	
	# Label columns
	colnames(ac) = c( 'TC','FC','S','P' )
	colnames(acDur) = c( 'TC','FC','S','PT','D','P' )
	
	if (!savePlot) x11()
	tmp = matrix( 1:20, 4, 5, byrow = T )
	tmp[4,3] = N+1; tmp[4,4:5] = N+2
	layout( tmp )
  
	sbj = unique( ac$S )
	
	for (s in sbj) {
		
		par( mar = c(3,3,1,1) )
		plot( c(-3,-2), c(0,1), type = 'n', xlab = ' ', ylab = ' ', 
					bty = 'l' )
		abline( h = .5, lty = 2 )
		
		lines( log( ac$TC[ ac$S == s ] ), ac$P[ ac$S == s ] )
		
		
		inc = 1; clr = c('blue','red')
		for (cnd in c(50,400)) {
			
			sel = acDur$S == s & acDur$D == cnd
			lines( log( acDur$TC[ sel ] ), acDur$P[ sel ], col = clr[inc], lty = 2 )
			inc = inc + 1
			
		}
		
		legend('bottomright',paste('Subject',s),bty='n')
		
	}
	
	blankPlot()
	legend('topleft',c('Collapsed','50 ms','400 ms'),fill=c('black','blue','red'),
				 bty='n')
	blankPlot()
	legend('topleft','Main data',bty='n',cex=1.5)
	
}

###
### Modeling of curve
###
# Lookup - 04

if ( runCode[4] ) {
	
	### Define useful functions ###
	
	f_theta = function( x, alpha, beta, kappa ) {
		# Purpose:
		# Calculates P(Correct) for a piecewise logistic function.
		# Arguments:
		# x     - The log target contrast
		# alpha - The slope parameter
		# beta  - The criterion (value of x for 50% performance)
		# kappa - The upper asymptote
		# Returns:
		# The probability of a correct response.
		
		z = alpha*(x + beta)
		y = kappa/(1+exp(-z))
		y[ y < .5 ] = .5
		
		return( y )
	}
	
	# Proportion correct
	fc = aggregate( d$Accuracy, list( 
		d$TargetContrast, d$FoilContrast, d$Subject ), 
		sum )
	colnames(fc) = c( 'TC','FC','S','Y' )
	fc$N = aggregate( rep(1,nrow(d)), list( 
		d$TargetContrast, d$FoilContrast, d$Subject ), 
		sum )$x
	
	sel = fc$S == 1
	stan_dat = list(
		L = length( fc$TC[sel] ),
		N = fc$N[sel],
		y = fc$Y[sel],
		x = log( fc$TC[sel] )
	)
	
	warmup = 200 # Warm-up period
	niter = 2500 # Number of samples for MC approximation
	
	setwd('Stan_scripts')
	
	startTime = Sys.time() # To assess run-time
	fit = stan( file = 'Psychophysics_single_subject.stan',
							data = stan_dat, 
							warmup = warmup, iter = warmup + niter, 
							chains = 4, seed = 65748
	)
	
	post = extract(fit)
	
	if (!savePlot) x11()
	layout( cbind(1,2,3) )
	hist( as.numeric(post$alpha), freq = F, 
				border='white',col='grey',bty='l', 
				breaks = 40, main = expression(alpha) )
	hist( as.numeric(post$beta), freq = F, 
				border='white',col='grey',bty='l', 
				breaks = 40, main = expression(beta) )
	hist( as.numeric(post$kappa), freq = F, 
				border='white',col='grey',bty='l', 
				breaks = 40, main = expression(kappa) )
	
}

###
### Hierarchical model
###
# Lookup - 05

if ( runCode[5] ) {
	
	### Define useful functions ###
	
	f_theta = function( x, alpha, beta, kappa ) {
		# Purpose:
		# Calculates P(Correct) for a piecewise logistic function.
		# Arguments:
		# x     - The log target contrast
		# alpha - The slope parameter
		# beta  - The criterion (value of x for 50% performance)
		# kappa - The upper asymptote
		# Returns:
		# The probability of a correct response.
		
		z = alpha*(x + beta)
		y = kappa/(1+exp(-z))
		y[ y < .5 ] = .5
		
		return( y )
	}
	
	g_theta = function( theta, alpha, beta, kappa ) {
		# Purpose:
		# Calculates the log target contrast for a piecewise logistic function.
		# Arguments:
		# theta - The desired level of performance
		# alpha - The slope parameter
		# beta  - The criterion (value of x for 50% performance)
		# kappa - The upper asymptote
		# Returns:
		# The log of the target contrast to produced the desired level 
		# of performance.
		
		new_theta = sapply( kappa, function(x) min( x, theta ) )
		
		x = -log( kappa/new_theta - 1 )/alpha - beta
		
		return( x )
	}
	
	violinPlot = function( x, pos, crit = NULL, scaleH = .5, 
												 type = 'greater', ... ) {
		# Purpose:
		# Adds a violin plot to an already existing figure.
		# Arguments:
		# x      - The vector of values to plot
		# pos    - The x-axis position at which to draw the violin plot
		# crit   - The critical value to use when shading areas of the plot
		# scaleH - The maximum possible width of the plot
		# type   - Whether the shaded area should be greater or less than the 
		#          critical value
		# ...    - Additional plotting parameters (color,shading,etc...)
		# Returns:
		# The proportion of the distribution greater than or less than 
		# the critical value.
		
		den = density( x )
		
		if ( length(crit) > 0 ) {
			if (type=='greater') {
				sel = den$x > crit
				PostProb = sum( x > crit )/length(x)
			}
			if (type=='less') {
				sel = den$x < crit
				PostProb = sum( x < crit )/length(x)
			}
		} else {
			sel = rep( T, length( den$x ) )
			PostProb = 1
		}
		
		den$y = den$y/max(den$y); den$y = den$y*scaleH;
		xa = c( -den$y[sel], rev(den$y[sel]) ) + pos
		ya = c( den$x[sel], rev(den$x[sel]) )
		polygon( xa, ya, ... )
		
		return( PostProb )
	}
	
	# Proportion correct
	fc = aggregate( d$Accuracy, list( 
		d$TargetContrast, d$FoilContrast, d$Subject ), 
		sum )
	colnames(fc) = c( 'TC','FC','S','Y' )
	fc$N = aggregate( rep(1,nrow(d)), list( 
		d$TargetContrast, d$FoilContrast, d$Subject ), 
		sum )$x
	
	stan_dat = list(
		S = N,
		L = length( unique( fc$TC ) ),
		N = fc$N,
		y = fc$Y,
		x = log( fc$TC ),
		indS = fc$S
	)
	
	warmup = 1000 # Warm-up period
	niter = 5000 # Number of samples for MC approximation
	
	setwd('Stan_scripts')
	
	startTime = Sys.time() # To assess run-time
	fit = stan( file = 'Psychophysics_hierarchical.stan',
							data = stan_dat, 
							warmup = warmup, iter = warmup + niter, 
							chains = 4, seed = 84302,
							thin = 2,
							control = list( adapt_delta = .9 )
	)
	
	post = extract( fit )
	
	if (!savePlot) x11()
	layout( cbind(1,2,3) )
	par( mar = c( 6, 6, 3, 2 ) )
	yl = lowerUpper( 1, as.vector( post$mu_alpha ) )
	plot( c(0,1), yl, type = 'n', bty = 'n', 
				xlab = ' ',
				ylab = ' ', xaxt = 'n' )
	mtext( 'Slope of function', side = 1, line = .5 )
	violinPlot( post$mu_alpha, .5, col = 'grey' )
	yl = lowerUpper( 1, as.vector( post$mu_beta ) )
	plot( c(0,1), yl, type = 'n', bty = 'n', 
				xlab = ' ',
				ylab = ' ', xaxt = 'n' )
	mtext( '50% cut-off', side = 1, line = .5 )
	violinPlot( post$mu_beta, .5, col = 'grey' )
	yl = lowerUpper( 1, as.vector( post$mu_kappa ) )
	plot( c(0,1), yl, type = 'n', bty = 'n', 
				xlab = ' ',
				ylab = ' ', xaxt = 'n' )
	mtext( 'Upper asymptote\nPeak performance', side = 1, line = .5 )
	violinPlot( post$mu_kappa, .5, col = 'grey' )
	mtext('Posteriors for \nhyper-parameters', side = 3, outer = T, 
				line = -3 )
	
	if (!savePlot) x11()
	layout( cbind( 1 ) )
	yl = lowerUpper( .5, as.vector( post$kappa ) )
	plot( c(0,N+1), yl, type = 'n', bty = 'l', 
				main = 'Peak performance posteriors', xlab = 'Subjects',
				ylab = 'Parameter values', xaxt = 'n' )
	axis(1,1:N)
	for (s in 1:N) {
		violinPlot( post$kappa[,s], s, scaleH = .4, col = 'grey' )
	}
	
	if (!savePlot) x11()
	tmp = matrix( 1:20, 4, 5, byrow = T )
	tmp[4,3] = N+1; tmp[4,4:5] = N+2
	layout( tmp )
	
	sbj = unique( fc$S )
	for (s in sbj) {
		
		x = fc$TC[ fc$S == s ]
		n = fc$N[ fc$S == s ]
		p = fc$Y[ fc$S == s ]/n
		l = length(x)
		
		par( mar = c(3,3,1,1) )
		plot( c(-3,-2), c(0,1), 
					type = 'n', xlab = ' ', ylab = ' ', 
					bty = 'l', xaxt = 'n' )
		abline( h = .5, lty = 2 )
		
		axis( 1, seq(-3,-2,.25) )
		
		wdth = matrix(NA,2,l)
		for (i in 1:l) {
			theta = f_theta( log( x[i] ), 
											 post$alpha[,s], post$beta[,s], post$kappa[,s] )
			ppc = rbinom( length( theta ), n[i], theta )
			wdth[,i] = quantile( ppc, c(.025,.975) )/n[i]
		}
		
		polygon( log( c( x, rev(x) ) ), c( wdth[1,], rev( wdth[2,] ) ), 
						 col = rgb( .5, .5, .5, .25 ), border = NA )
		
		pred = f_theta( log( x ), 
						 mean( post$alpha[,s] ),
						 mean( post$beta[,s] ),
						 mean( post$kappa[,s] ) )
		
		lines( log( x ), p )
		lines( log( x ), pred, col = 'blue', lty = 2 )
		
		legend( 'bottomright', paste('Subject',s), bty = 'n' )
		
	}
	
	blankPlot()
	legend( 'topleft', c('Observed','Predicted','95% CI'),
					fill = c('black','blue','grey'), bty = 'n' )
	blankPlot()
	legend('topleft',c('Observed data','vs. model', 'predictions'),
				 bty = 'n', cex = 1.5 )
	
	layout( cbind( 1 ) ) # Reset layout
	if (!savePlot) x11()
	par( mar = c( 4, 5, 3, 1 ) )
	plot( c(.5,N+.5), c(-3,-1), type = 'n', xlab = 'Subjects',
				ylab = 'Log contrast for 75% performance',
				xaxt = 'n', bty = 'l' )
	axis( 1, 1:N )
	for (s in 1:N) {
		
		x_crit = g_theta( .75, post$alpha[,s], post$beta[,s], post$kappa[,s] )
		x_crit = x_crit[ x_crit != Inf ]
		
		violinPlot( x_crit, s, scaleH = .4, col = 'grey' )
		
		points( s, log( perf_thresh[s] ), col = 'blue', pch = 19 )
		
	}
	legend( 'topright', c('Staircase estimate'), pch = 19, col = 'blue',
					bty = 'n' )
	
}

setwd( orig_dir )
if (savePlot) dev.off()