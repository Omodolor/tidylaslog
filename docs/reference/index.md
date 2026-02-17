# Package index

## Core workflow

- [`tidylaslog()`](https://omodolor.github.io/tidylaslog/reference/tidylaslog.md)
  : Universal entry point for reading, indexing, and exporting LAS well
  logs
- [`index_laslogs()`](https://omodolor.github.io/tidylaslog/reference/index_laslogs.md)
  : Build a FAIR index for a folder of LAS files
- [`available_curves()`](https://omodolor.github.io/tidylaslog/reference/available_curves.md)
  : List available curve mnemonics in an index
- [`select_laslogs()`](https://omodolor.github.io/tidylaslog/reference/select_laslogs.md)
  : Select wells from an index by metadata and curve availability
- [`pull_laslogs()`](https://omodolor.github.io/tidylaslog/reference/pull_laslogs.md)
  : Pull log data for selected wells (optionally selected curves)
- [`batch_export_laslogs()`](https://omodolor.github.io/tidylaslog/reference/batch_export_laslogs.md)
  : Index, filter, pull, and export LAS logs in one call
- [`read_laslog()`](https://omodolor.github.io/tidylaslog/reference/read_laslog.md)
  : Read a LAS well log file (Log ASCII Standard) into a structured
  object
- [`read_laslog_header()`](https://omodolor.github.io/tidylaslog/reference/read_laslog_header.md)
  : Read LAS header only (no ~A data)
- [`write_laslogs()`](https://omodolor.github.io/tidylaslog/reference/write_laslogs.md)
  : Write LAS logs to CSV and/or Parquet
