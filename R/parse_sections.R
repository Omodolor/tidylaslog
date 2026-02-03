#' Split LAS text into sections
#' @keywords internal
split_las_sections <- function(lines) {
  lines <- gsub("\r$", "", lines)
  hdr_idx <- grep("^\\s*~", lines)

  if (length(hdr_idx) == 0) {
    stop("No LAS sections found (no lines starting with '~').")
  }

  # section name is first token after "~"
  sec_names <- toupper(sub("^\\s*~\\s*([^ \\t]+).*$", "\\1", lines[hdr_idx]))
  sec_names <- sub("^OTHER$", "O", sec_names)

  ends <- c(hdr_idx[-1] - 1, length(lines))
  out <- list()

  for (i in seq_along(hdr_idx)) {
    sec <- sec_names[i]

    # lines after the section header
    block <- lines[(hdr_idx[i] + 1):ends[i]]

    # IMPORTANT:
    # If the section header line contains extra tokens (e.g. "~A DEPTH GR RHOB"),
    # keep them as the first line of the block.
    header_line <- lines[hdr_idx[i]]
    remainder <- sub("^\\s*~\\s*[^ \\t]+\\s*", "", header_line)
    remainder <- trimws(remainder)

    if (nzchar(remainder)) {
      block <- c(remainder, block)
    }

    out[[sec]] <- block
  }

  out
}
