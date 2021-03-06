#' Data from "A Dynamic Analysis of The Role of War Chests in Campaign Strategy" by
#' Janet M. Box-Steffensmeier
#'
#' The data cover 397 races for the United States House of Representatives in which an
#' incumbent ran for reelection in 1990.
#' @format A data frame with 1376 observations and 8 variables:
#' \tabular{ll}{
#' \code{caseid} \tab ID number \cr
#' \code{start} \tab  Beginning of the measured time interval, in weeks\cr
#' \code{te} \tab Time to challenger entry (end of the time interval), in weeks \cr
#' \code{ec} \tab The amount of money (in millions of USD) the incumbent has in reserve \cr
#' \code{dem} \tab 1 if the incumbent is a Democrat, 0 if the incumbent is a Republican \cr
#' \code{south} \tab 1 if the district is in the south, 0 else \cr
#' \code{iv} \tab Prior vote percent \cr
#' \code{cut_hi} \tab Indicates whether or not a high quality challenger enters the race (censoring variable)\cr
#' }
#' @source Box-Steffensmeier, J. M. (1996)
#' A Dynamic Analysis of The Role of War Chests in Campaign Strategy.
#' \emph{American Journal of Political Science} \strong{40} 352-371
"boxsteffensmeier"


