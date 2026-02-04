#' Parse LAS ASCII data (~A)
#' @keywords internal
parse_ascii_block <- function(lines, null_value = NA_real_, output = c("long","wide")) {
  output <- match.arg(output)

  lines <- lines[!grepl("^\\s*#", lines)]
  lines <- lines[nzchar(trimws(lines))]

  if (length(lines) == 0) {
    return(tibble::tibble())
  }

  header_line <- lines[1]
  if (grepl("[A-Za-z]", header_line)) {
    header_tokens <- strsplit(trimws(header_line), "\\s+")[[1]]
    header_tokens <- header_tokens[header_tokens != "~A"]
    data_lines <- lines[-1]
  } else {
    stop("~A block has no header line with curve names; cannot parse reliably.")
  }

  con <- textConnection(data_lines)
  on.exit(close(con), add = TRUE)
  dat <- utils::read.table(con, header = FALSE, fill = TRUE, stringsAsFactors = FALSE)

  if (ncol(dat) < length(header_tokens)) {
    for (k in (ncol(dat)+1):length(header_tokens)) dat[[k]] <- NA
  }
  dat <- dat[, seq_len(length(header_tokens)), drop = FALSE]
  names(dat) <- toupper(header_tokens)

  for (nm in names(dat)) {
    suppressWarnings(dat[[nm]] <- as.numeric(dat[[nm]]))
  }

  if (!is.na(null_value)) {
    dat[dat == null_value] <- NA_real_
  }

  dat <- tibble::as_tibble(dat)

  if (output == "wide") {
    depth_col <- if ("DEPT" %in% names(dat)) "DEPT" else if ("DEPTH" %in% names(dat)) "DEPTH" else NULL
    if (is.null(depth_col)) stop("No DEPT/DEPTH column found in ~A header.")

    dat <- dat |>
      dplyr::rename(depth = dplyr::all_of(depth_col)) |>
      dplyr::relocate("depth")

    return(dat)
  }



  depth_col <- if ("DEPT" %in% names(dat)) "DEPT" else if ("DEPTH" %in% names(dat)) "DEPTH" else NULL
  if (is.null(depth_col)) stop("No DEPT/DEPTH column found in ~A header.")

  dat |>
    dplyr::rename(depth = dplyr::all_of(depth_col)) |>
    tidyr::pivot_longer(
      cols = -dplyr::all_of("depth"),
      names_to = "mnemonic",
      values_to = "value"
    )
}

