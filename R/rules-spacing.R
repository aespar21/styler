#' @include token-define.R
add_space_around_op <- function(pd_flat) {
  op_after <- pd_flat$token %in% op_token
  op_before <- lead(op_after, default = FALSE)
  idx_before <- op_before & (pd_flat$newlines == 0L)
  pd_flat$spaces[idx_before] <- pmax(pd_flat$spaces[idx_before], 1L)
  idx_after <- op_after & (pd_flat$newlines == 0L)
  pd_flat$spaces[idx_after] <- pmax(pd_flat$spaces[idx_after], 1L)
  pd_flat
}

#' @include token-define.R
set_space_around_op <- function(pd_flat) {
  op_after <- pd_flat$token %in% op_token
  if (!any(op_after)) return(pd_flat)
  op_before <- lead(op_after, default = FALSE)
  pd_flat$spaces[op_before & (pd_flat$newlines == 0L)] <- 1L
  pd_flat$spaces[op_after & (pd_flat$newlines == 0L)] <- 1L
  pd_flat
}

#' Style spacing around math tokens
#' @inheritParams style_space_around_math_token_one
#' @param one Character vector with tokens that should be surrounded by at
#'   least one space (depending on `strict = TRUE` in the styling functions
#'   [style_text()] and friends). See 'Examples'.
#' @param zero Character vector of tokens that should be surrounded with zero
#'   spaces.
style_space_around_math_token <- function(strict, zero, one, pd_flat) {
  pd_flat %>%
    style_space_around_math_token_one(strict, zero, 0L) %>%
    style_space_around_math_token_one(strict, one, 1L)
}

#' Set spacing of token to a certain level
#'
#' Set the spacing of all `tokens` in `pd_flat` to `level` if `strict = TRUE` or
#' to at least to `level` if `strict = FALSE`.
#' @param pd_flat A nest or a flat parse table.
#' @param strict Whether the rules should be applied strictly or not.
#' @param tokens Character vector with tokens that should be styled.
#' @param level Scalar indicating the amount of spaces that should be inserted
#'   around the `tokens`.
style_space_around_math_token_one <- function(pd_flat, strict, tokens, level) {
  op_after <- pd_flat$token %in% tokens
  op_before <- lead(op_after, default = FALSE)
  idx_before <- op_before & (pd_flat$newlines == 0L)
  idx_after <- op_after & (pd_flat$newlines == 0L)
  if (strict) {
    pd_flat$spaces[idx_before | idx_after] <- level
  } else {
    pd_flat$spaces[idx_before | idx_after] <-
      pmax(pd_flat$spaces[idx_before | idx_after], level)
  }
  pd_flat
}

# depreciated!
#' @include token-define.R
remove_space_after_unary_pm <- function(pd_flat) {
  op_pm <- c("'+'", "'-'")
  op_pm_unary_after <- c(op_pm, op_token, "'('", "','")

  pm_after <- pd_flat$token %in% op_pm
  pd_flat$spaces[pm_after & (pd_flat$newlines == 0L) &
    (lag(pd_flat$token) %in% op_pm_unary_after)] <- 0L
  pd_flat
}


remove_space_after_unary_pm_nested <- function(pd) {
  if (any(pd$token[1] %in% c("'+'", "'-'"))) {
    pd$spaces[1] <- 0L
  }

  pd
}


fix_quotes <- function(pd_flat) {
  str_const <- pd_flat$token == "STR_CONST"
  str_const_change <- grepl("^'([^\"]*)'$", pd_flat$text[str_const])
  pd_flat$text[str_const][str_const_change] <-
    vapply(
      lapply(pd_flat$text[str_const][str_const_change], parse_text),
      deparse,
      character(1L)
    )
  pd_flat
}

remove_space_before_opening_paren <- function(pd_flat) {
  paren_after <- pd_flat$token == "'('"
  if (!any(paren_after)) return(pd_flat)
  paren_before <- lead(paren_after, default = FALSE)
  pd_flat$spaces[paren_before & (pd_flat$newlines == 0L)] <- 0L
  pd_flat
}

remove_space_after_opening_paren <- function(pd_flat) {
  paren_after <- pd_flat$token == "'('"
  if (!any(paren_after)) return(pd_flat)
  pd_flat$spaces[paren_after & (pd_flat$newlines == 0L)] <- 0L
  pd_flat
}

remove_space_before_closing_paren <- function(pd_flat) {
  paren_after <- pd_flat$token == "')'"
  if (!any(paren_after)) return(pd_flat)
  paren_before <- lead(paren_after, default = FALSE)
  pd_flat$spaces[paren_before & (pd_flat$newlines == 0L)] <- 0L
  pd_flat
}

add_space_after_for_if_while <- function(pd_flat) {
  comma_after <- pd_flat$token %in% c("FOR", "IF", "WHILE")
  if (!any(comma_after)) return(pd_flat)
  idx <- comma_after & (pd_flat$newlines == 0L)
  pd_flat$spaces[idx] <- pmax(pd_flat$spaces[idx], 1L)
  pd_flat
}

add_space_before_brace <- function(pd_flat) {
  op_after <- pd_flat$token %in% "'{'"
  if (!any(op_after)) return(pd_flat)
  op_before <- lead(op_after, default = FALSE)
  idx_before <- op_before & (pd_flat$newlines == 0L) & pd_flat$token != "'('"
  pd_flat$spaces[idx_before] <- pmax(pd_flat$spaces[idx_before], 1L)
  pd_flat
}

add_space_after_comma <- function(pd_flat) {
  comma_after <- (pd_flat$token == "','") & (pd_flat$newlines == 0L)
  pd_flat$spaces[comma_after] <- pmax(pd_flat$spaces[comma_after], 1L)
  pd_flat
}

set_space_after_comma <- function(pd_flat) {
  comma_after <- (pd_flat$token == "','") & (pd_flat$newlines == 0L)
  pd_flat$spaces[comma_after] <- 1L
  pd_flat
}

remove_space_before_comma <- function(pd_flat) {
  comma_after <- pd_flat$token == "','"
  if (!any(comma_after)) return(pd_flat)
  comma_before <- lead(comma_after, default = FALSE)
  idx <- comma_before & (pd_flat$newlines == 0L)
  pd_flat$spaces[idx] <- 0L
  pd_flat
}


#' Set space between levels of nesting
#'
#' With the nested approach, certain rules do not have an effect anymore because
#'   of the nature of the nested structure. Setting spacing before curly
#'   brackets in for / if / while statements and function declarations will be
#'   such a case since a curly bracket is always at the first position in a
#'   parse table, so spacing cannot be set after the previous token.
#' @param pd_flat A flat parse table.
set_space_between_levels <- function(pd_flat) {
  if (pd_flat$token[1] %in% c("FUNCTION", "IF", "WHILE")) {
    index <- pd_flat$token == "')'" & pd_flat$newlines == 0L
    pd_flat$spaces[index] <- 1L
  } else if (pd_flat$token[1] == "FOR") {
    index <- 2
    pd_flat$spaces[index] <- 1L
  }
  pd_flat
}

#' Start comments with a space
#'
#' Forces comments to start with a space, that is, after the regular expression
#'   "^#+'*", at least one space must follow if the comment is *non-empty*, i.e
#'   there is not just spaces within the comment. Multiple spaces may be legit
#'   for indention in some situations.
#' @param pd A parse table.
#' @param force_one Whether or not to force one space or allow multiple spaces
#'   after the regex "^#+'*".
#' @importFrom purrr map_chr
start_comments_with_space <- function(pd, force_one = FALSE) {
  comment_pos <- pd$token == "COMMENT"
  if (!any(comment_pos)) return(pd)

  comments <- rematch2::re_match(
    pd$text[comment_pos],
    "^(?<prefix>#+['\\*]*)(?<space_after_prefix> *)(?<text>.*)$"
  )

  comments$space_after_prefix <- nchar(
    comments$space_after_prefix, type = "width"
  )
  comments$space_after_prefix <- set_spaces(
    spaces_after_prefix = comments$space_after_prefix,
    force_one
  )

  pd$text[comment_pos] <-
    paste0(
      comments$prefix,
      map_chr(comments$space_after_prefix, rep_char, char = " "),
      comments$text
    ) %>%
    trimws("right")
  pd$short[comment_pos] <- substr(pd$text[comment_pos], 1, 5)
  pd
}


set_space_before_comments <- function(pd_flat) {
  comment_after <- (pd_flat$token == "COMMENT") & (pd_flat$lag_newlines == 0L)
  if (!any(comment_after)) return(pd_flat)
  comment_before <- lead(comment_after, default = FALSE)
  pd_flat$spaces[comment_before & (pd_flat$newlines == 0L)] <- 1L
  pd_flat
}

add_space_before_comments <- function(pd_flat) {
  comment_after <- (pd_flat$token == "COMMENT") & (pd_flat$lag_newlines == 0L)
  if (!any(comment_after)) return(pd_flat)
  comment_before <- lead(comment_after, default = FALSE)
  pd_flat$spaces[comment_before & (pd_flat$newlines == 0L)] <-
    pmax(pd_flat$spaces[comment_before], 1L)
  pd_flat
}


remove_space_after_excl <- function(pd_flat) {
  excl <- (pd_flat$token == "'!'") &
    (pd_flat$token_after != "'!'") &
    (pd_flat$newlines == 0L)
  pd_flat$spaces[excl] <- 0L
  pd_flat
}

set_space_after_bang_bang <- function(pd_flat) {
  last_bang <- (pd_flat$token == "'!'") &
    (pd_flat$token_after != "'!'") &
    (pd_flat$newlines == 0L) &
    (pd_flat$token_before == "'!'")

  pd_flat$spaces[last_bang] <- 1L
  pd_flat
}

remove_space_before_dollar <- function(pd_flat) {
  dollar_after <- (pd_flat$token == "'$'") & (pd_flat$lag_newlines == 0L)
  dollar_before <- lead(dollar_after, default = FALSE)
  pd_flat$spaces[dollar_before] <- 0L
  pd_flat
}

remove_space_after_fun_dec <- function(pd_flat) {
  fun_after <- (pd_flat$token == "FUNCTION") & (pd_flat$lag_newlines == 0L)
  pd_flat$spaces[fun_after] <- 0L
  pd_flat
}

remove_space_around_colons <- function(pd_flat) {
  one_two_or_three_col_after <-
    pd_flat$token %in% c("':'", "NS_GET_INT", "NS_GET")

  one_two_or_three_col_before <-
    lead(one_two_or_three_col_after, default = FALSE)

  col_around <-
    one_two_or_three_col_before | one_two_or_three_col_after

  pd_flat$spaces[col_around & (pd_flat$newlines == 0L)] <- 0L
  pd_flat
}

#' Set space between EQ_SUB and "','"
#' @param pd A parse table.
set_space_between_eq_sub_and_comma <- function(pd) {
  op_before <- which(pd$token == "EQ_SUB" & lead(pd$token == "','"))
  pd$spaces[op_before] <- 1L
  pd
}
