#' Parse LAS header-style lines (MNEM.UNIT VALUE : DESC)
#' @keywords internal
parse_header_block <- function(lines) {
  lines <- lines[!grepl("^\\s*#", lines)]
  lines <- lines[nzchar(trimws(lines))]

  if (length(lines) == 0) {
    return(tibble::tibble(
      MNEM = character(), UNIT = character(), VALUE = character(), DESC = character()
    ))
  }

  parts <- strsplit(lines, ":", fixed = TRUE)

  left <- vapply(parts, function(x) x[1], character(1))
  desc <- vapply(parts, function(x) {
    if (length(x) >= 2) trimws(paste(x[-1], collapse=":")) else ""
  }, character(1))

  mnem <- trimws(sub("^\\s*([^\\.\\s]+)\\..*$", "\\1", left))
  unit <- trimws(sub("^\\s*[^\\.\\s]+\\.([^\\s]+)\\s+.*$", "\\1", left))
  unit[grepl("^\\s*[^\\.\\s]+\\s+.*$", left)] <- ""

  value <- trimws(sub("^\\s*[^\\.\\s]+\\.[^\\s]*\\s+(.*)$", "\\1", left))
  value[!grepl("\\.", left)] <- trimws(sub("^\\s*[^\\s]+\\s+(.*)$", "\\1", left[!grepl("\\.", left)]))

  tibble::tibble(
    MNEM = toupper(mnem),
    UNIT = unit,
    VALUE = value,
    DESC = desc
  )
}

#' Parse LAS curve block (~C)
#' @keywords internal
parse_curve_block <- function(lines) {
  # Always return a tibble with these columns
  empty <- tibble::tibble(
    MNEM = character(),
    UNIT = character(),
    API_CODE = character(),
    DESC = character()
  )

  if (length(lines) == 0) return(empty)

  # Drop comments and blanks
  x <- lines[!grepl("^\\s*#", lines)]
  x <- x[nzchar(trimws(x))]

  if (length(x) == 0) return(empty)

  # Drop obvious header lines and "Information Block" junk
  x <- x[!grepl("(?i)MNEM\\.?UNIT|API\\s*CODE|CURVE\\s*DESCRIPTION|INFORMATION\\s*BLOCK", x, perl = TRUE)]
  x <- x[!grepl("^\\s*~", x)]  # safety: any section markers that leaked in

  if (length(x) == 0) return(empty)

  # Parse each curve line
  rows <- lapply(x, function(line) {
    # Split description by ":" (LAS style)
    parts <- strsplit(line, ":", fixed = TRUE)[[1]]
    left  <- trimws(parts[1])
    desc  <- if (length(parts) >= 2) trimws(paste(parts[-1], collapse = ":")) else ""

    # Collapse internal whitespace
    toks <- strsplit(gsub("\\s+", " ", left), " ", fixed = TRUE)[[1]]
    toks <- toks[nzchar(toks)]

    if (length(toks) == 0) return(NULL)

    # First token is like MNEM.UNIT
    mnem_unit <- toks[1]
    mu <- strsplit(mnem_unit, "\\.", fixed = FALSE)[[1]]
    mnem <- toupper(trimws(mu[1]))
    unit <- if (length(mu) >= 2) toupper(trimws(mu[2])) else ""

    # Optional API code = remaining tokens (before ":")
    api_code <- if (length(toks) >= 2) paste(toks[-1], collapse = " ") else ""

    tibble::tibble(
      MNEM = mnem,
      UNIT = unit,
      API_CODE = trimws(api_code),
      DESC = desc
    )
  })

  out <- dplyr::bind_rows(rows)

  # Final cleanup: keep only real curve mnemonics
  out <- out |>
    dplyr::mutate(MNEM = toupper(trimws(.data$MNEM))) |>
    dplyr::filter(
      nzchar(.data$MNEM),
      !grepl("\\s", .data$MNEM),              # removes "INFORMATION BLOCK"
      grepl("^[A-Z0-9_\\-\\.]+$", .data$MNEM) # sane mnemonic characters
    )

  # Ensure columns exist even if empty
  if (nrow(out) == 0) return(empty)
  out
}
