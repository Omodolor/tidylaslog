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
  lines <- lines[!grepl("^\\s*#", lines)]
  lines <- lines[nzchar(trimws(lines))]

  if (length(lines) == 0) {
    return(tibble::tibble(
      MNEM = character(), UNIT = character(), API_CODE = character(), DESC = character()
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

  api_code <- trimws(sub("^\\s*[^\\.\\s]+\\.[^\\s]*\\s*(.*)$", "\\1", left))

  tibble::tibble(
    MNEM = toupper(mnem),
    UNIT = unit,
    API_CODE = api_code,
    DESC = desc
  )
}
