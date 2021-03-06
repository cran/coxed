#' Predict expected durations using the GAM method
#'
#' This function is called by \code{\link[coxed]{coxed}} and is not intended to be used by itself.
#' @param cox.model The output from a Cox proportional hazards model estimated
#' with the \code{\link[survival]{coxph}} function in the \code{survival} package
#' or with the \code{\link[rms]{cph}} function in the \code{\link[rms]{rms}}
#' package
#' @param newdata An optional data frame in which to look for variables with
#' which to predict. If omitted, the fitted values are used
#' @param coef A vector of new coefficients to replace the \code{coefficients} attribute
#' of the \code{cox.model}. Used primarily for bootstrapping, to recalculate durations
#' using new coefficients derived from a bootstrapped sample.
#' If \code{NULL}, the original coefficients are employed
#' @param b.ind A vector of observation numbers to pass to the estimation sample to construct
#' the a bootstrapped sample with replacement
#' @return Returns a list containing the following components:
#' \tabular{ll}{
#' \code{exp.dur} \tab A vector of predicted mean durations for the estimation sample
#' if \code{newdata} is omitted, or else for the specified new data. \cr
#' \code{baseline.functions} \tab The estimated cumulative baseline hazard function and survivor function. \cr
#' }
#' @details The non-parametric step function (NPSF) approach to calculating expected durations from the Cox
#' proportional hazards model, described in Kropko and Harden (2018), uses the method proposed by
#' Cox and Oakes (1984, 107-109) for estimating the cumulative baseline hazard function.  This
#' method is nonparametric and results in a step-function representation of the cumulative
#' baseline hazard.
#'
#' Cox and Oakes (1984, 108) show that the cumulative baseline hazard function can be estimated
#' after fitting a Cox model by
#' \deqn{\hat{H}_0(t) = \sum_{\tau_j < t}\frac{d_j}{\sum_{l\in\Re(\tau_j)}\hat{\psi}(l)},}
#' where \eqn{\tau_j} represents time points earlier than \eqn{t}, \eqn{d_j} is a count of the
#' total number of failures at \eqn{\tau_j}, \eqn{\Re(\tau_j)} is the remaining risk set at \eqn{\tau_j},
#' and \eqn{\hat{\psi}(l)} represents the ELP from the Cox model for observations still in the
#' risk set at \eqn{\tau_j}. This equation is used calculate the cumulative baseline hazard at
#' all time points in the range of observed durations. This estimate is a stepwise function
#' because time points with no failures do not contribute to the cumulative hazard, so the function
#' is flat until the next time point with observed failures.
#'
#' We extend this method to obtain expected durations by first calculating the baseline survivor
#' function from the cumulative hazard function, using
#' \deqn{\hat{S}_0(t) = \exp[-\hat{H}_0(t)].}
#' Each observation's survivor function is related to the baseline survivor function by
#' \deqn{\hat{S}_i(t) = \hat{S}_0(t)^{\hat{\psi}(i)},}
#' where \eqn{\hat{\psi}(i)} is the exponentiated linear predictor (ELP) for observation \eqn{i}.
#' These survivor functions can be used directly to calculate expected durations for each
#' observation.  The expected value of a non-negative random variable can be calculated by
#' \deqn{E(X) = \int_0^{\infty} \bigg(1 - F(t)\bigg)dt,}
#' where \eqn{F(.)} is the cumulative distribution function for \eqn{X}.  In the case of a
#' duration variable \eqn{t_i}, the expected duration is
#' \deqn{E(t_i) = \int_0^T S_i(t)\,dt,}
#' where \eqn{T} is the largest possible duration and \eqn{S(t)} is the individual's survivor
#' function.  We approximate this integral with a right Riemann-sum by calculating the survivor
#' functions at every discrete time point from the minimum to the maximum observed durations,
#' and multiplying these values by the length of the interval between time points with observed failures:
#' \deqn{E(t_i) \approx \sum_{t_j \in [0,T]} (t_j - t_{j-1})S_i(t_j).}
#' @seealso \code{\link[coxed]{coxed}}
#' @references Kropko, J. and Harden, J. J. (2018). Beyond the Hazard Ratio: Generating Expected
#' Durations from the Cox Proportional Hazards Model. \emph{British Journal of Political Science}
#' \url{https://doi.org/10.1017/S000712341700045X}
#'
#' Cox, D. R., and Oakes, D. (1984). \emph{Analysis of Survival Data. Monographs on Statistics & Applied Probability}
#' @author Jonathan Kropko <jkropko@@virginia.edu> and Jeffrey J. Harden <jharden2@@nd.edu>
#' @export
#' @examples
#' mv.surv <- Surv(martinvanberg$formdur, event = rep(1, nrow(martinvanberg)))
#' mv.cox <- coxph(mv.surv ~ postel + prevdef + cont + ident + rgovm + pgovno + tpgovno +
#'      minority, method = "breslow", data = martinvanberg)
#'
#' ed <- coxed.npsf(mv.cox)
#' ed$baseline.functions
#' ed$exp.dur
#'
#' #Running coxed.npsf() on a bootstrap sample and with new coefficients
#' bsample <- sample(1:nrow(martinvanberg), nrow(martinvanberg), replace=TRUE)
#' newcoefs <- rnorm(8)
#' ed2 <- coxed.npsf(mv.cox, b.ind=bsample, coef=newcoefs)
coxed.npsf <- function(cox.model, newdata=NULL, coef=NULL, b.ind=NULL) {

     if(!is.null(coef)){
          y.bs <- cox.model$y[b.ind,1]
          failed.bs <- cox.model$y[b.ind,2]
          cox.model$coefficients <- coef
     }
     y <- cox.model$y[,1]
     failed <- cox.model$y[,2]
     exp.xb <- exp(predict(cox.model, type="lp"))
     if(!is.null(coef)) exp.xb <- exp.xb[b.ind]

     # Compile total failures (only non-censored) at each time point
     if(!is.null(coef)) h <- cbind(y.bs, failed.bs, exp.xb)
     if(is.null(coef)) h <- cbind(y, failed, exp.xb)
     h <- h[order(h[,1]),]
     h <- aggregate(h[,-1], by=list(h[,1]), FUN="sum")
     colnames(h) <- c("time", "total.failures", "exp.xb")

     # Construction of the risk set (includes censored and non-censored observations)
     h[,3] <- rev(cumsum(rev(h[,3])))

     #Construct CBH, baseline survivor and failure CDF
     CBH <- cumsum(h[,2]/h[,3])
     S.bl <- exp(-CBH)
     baseline.functions <- data.frame(time = h$time, cbh = CBH, survivor = S.bl)

     if(!is.null(newdata)){
          exp.xb <- exp(predict(cox.model, newdata=newdata, type="lp"))
     } else{
          exp.xb <- exp(predict(cox.model, type="lp"))
     }

     #Generate EDs for all in-sample observations
     survival <- t(sapply(exp.xb, FUN=function(x){S.bl^x}, simplify=TRUE))
     expect.duration <- apply(survival, 1, FUN=function(x){
          sum(diff(h[,1])*x[-1])
     })
     expect.duration.med <- sum(diff(h[,1])*S.bl^(median(exp.xb))[-1])

     return(list(baseline.functions = baseline.functions,
                 exp.dur = expect.duration))
}
