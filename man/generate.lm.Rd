% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generate.lm.R
\name{generate.lm}
\alias{generate.lm}
\title{Generate simulated durations using a baseline survivor function and proportional hazards}
\usage{
generate.lm(baseline, X = NULL, N = 1000, type = "none",
  beta = NULL, xvars = 3, mu = 0, sd = 1, censor = 0.1)
}
\arguments{
\item{baseline}{The baseline hazard, cumulative hazard, survival, failure PDF, and failure CDF as output by \code{\link[coxed]{baseline.build}}}

\item{X}{A user-specified data frame containing the covariates that condition duration. If \code{NULL}, covariates are generated from
normal distributions with means given by the \code{mu} argument and standard deviations given by the \code{sd} argument}

\item{N}{Number of observations in each generated data frame}

\item{type}{If "none" (the default) data are generated with no time-varying covariates or coefficients.
If "tvc", data are generated with time-varying covariates, and if "tvbeta" data are generated with time-varying
coefficients (see details)}

\item{beta}{A user-specified vector containing the coefficients that for the linear part of the duration model. If \code{NULL}, coefficients are generated from
normal distributions with means of 0 and standard deviations of 0.1}

\item{xvars}{The number of covariates to generate. Ignored if \code{X} is not \code{NULL}}

\item{mu}{If scalar, all covariates are generated to have means equal to this scalar. If a vector, it specifies the mean of each covariate separately,
and it must be equal in length to \code{xvars}. Ignored if \code{X} is not \code{NULL}}

\item{sd}{If scalar, all covariates are generated to have standard deviations equal to this scalar. If a vector, it specifies the standard deviation
of each covariate separately, and it must be equal in length to \code{xvars}. Ignored if \code{X} is not \code{NULL}}

\item{censor}{The proportion of observations to designate as being right-censored}
}
\value{
Returns a list with the following components:
\tabular{ll}{
\code{data} \tab The simulated data frame, including the simulated durations, the censoring variable, and covariates\cr
\code{beta} \tab The coefficients, varying over time if \code{type} is "tvbeta" \cr
\code{XB} \tab The linear predictor for each observation \cr
\code{exp.XB} \tab The exponentiated linear predictor for each observation \cr
\code{survmat} \tab An (\code{N} x \code{T}) matrix containing the individual survivor function at
time t for the individual represented by row n   \cr
\code{tvc} \tab A logical value indicating whether or not the data includes time-varying covariates \cr
}
}
\description{
This function is called by \code{\link[coxed]{sim.survdata}} and is not intended to be used by itself.
}
\details{
If \code{type="none"} then the function generates idiosyncratic survival functions for each observation via proportional hazards: first the
linear predictor is calculated from the X variables and beta coefficients, then the linear predictor is exponentiated and set as the exponent of the
baseline survivor function.  For each individual observation's survival function, a duration is drawn by drawing a single random number on U[0,1]
and finding the time point at which the survival function first decreases past this value. See Harden and Kropko (2018) for a more detailed description
of this algorithm.

If \code{type="tvc"}, this function cannot accept user-supplied data for the covariates, as a time-varying covariate is expressed over time frames
which themselves convey part of the variation of the durations, and we are generating these durations. If user-supplied X data is provided, the
function passes a warning and generates random data instead as if \code{X=NULL}. Durations are drawn again using proportional hazards, and are passed
to the \code{\link[PermAlgo]{permalgorithm}} function in the \code{PermAlgo} package to generate the time-varying data structure (Sylvestre and Abrahamowicz 2008).

If \code{type="tvbeta"} the first coefficient, whether coefficients are user-supplied or randomly generated, is interacted with the natural log of
the time counter from 1 to \code{T} (the maximum time point for the \code{baseline} functions). Durations are generated via proportional hazards,
and coefficients are saved as a matrix to illustrate their dependence on time.
}
\examples{
baseline <- baseline.build(T=100, knots=8, spline=TRUE)
simdata <- generate.lm(baseline, N=1000, xvars=5, mu=0, sd=1, type="none", censor=.1)
summary(simdata$data)
simdata <- generate.lm(baseline, N=1000, xvars=5, mu=0, sd=1, type="tvc", censor=.1)
summary(simdata$data)
simdata <- generate.lm(baseline, N=1000, xvars=5, mu=0, sd=1, type="tvbeta", censor=.1)
simdata$beta
}
\references{
Harden, J. J. and Kropko, J. (2018). Simulating Duration Data for the Cox Model.
\emph{Political Science Research and Methods} \url{https://doi.org/10.1017/psrm.2018.19}

Sylvestre M.-P., Abrahamowicz M. (2008) Comparison of algorithms to generate event times conditional on time-dependent covariates. \emph{Statistics in Medicine} \strong{27(14)}:2618–34.
}
\seealso{
\code{\link[coxed]{sim.survdata}}, \code{\link[PermAlgo]{permalgorithm}}
}
\author{
Jonathan Kropko <jkropko@virginia.edu> and Jeffrey J. Harden <jharden2@nd.edu>
}
