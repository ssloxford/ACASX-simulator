Input Data
==========

To help prepare JSON files as input to the simulator, a Python pipeline is provided in `tools/`. This takes a HDF of OpenSky position reports or a directory containing HDF files and splits them into individual flights, cleaning them on the way. A `requirements.txt` file is included for dependencies.

```
python3.7 opensky_extraction_pipeline.py -h
usage: opensky_extraction_pipeline.py [-h]
                                      [--impute_tolerance IMPUTE_TOLERANCE]
                                      [--invalid_max_threshold INVALID_MAX_THRESHOLD]
                                      [--invalid_min_threshold INVALID_MIN_THRESHOLD]
                                      [--invalid_tolerance INVALID_TOLERANCE]
                                      [--altitude_min ALTITUDE_MIN]
                                      [--altitude_max ALTITUDE_MAX]
                                      input_path output_path

Data processing pipeline to convert HDFs containing OpenSky position reports
into a series of JSON files, each containing one flight

positional arguments:
  input_path            Directory or HDF file to process.
  output_path           Directory to save exported JSON files to.

optional arguments:
  -h, --help            show this help message and exit
  --impute_tolerance IMPUTE_TOLERANCE
                        Percentage threshold for flight altitude imputation -
                        if a flight has a lower percentage of present values
                        than this, it is dropped. (default: 0.8)
  --invalid_max_threshold INVALID_MAX_THRESHOLD
                        Threshold for maximum altitude climb between two
                        points (in metres/sec). (default: 25.398760540485622)
  --invalid_min_threshold INVALID_MIN_THRESHOLD
                        Threshold for maximum altitude descent between two
                        points (in metres/sec). (default: -22.85888448643706)
  --invalid_tolerance INVALID_TOLERANCE
                        Tolerance value to allow jitters past the invalid min
                        and max thresholds. (default: 5)
  --altitude_min ALTITUDE_MIN
                        Lower bound of acceptable altitudes (in metres).
                        (default: 1250)
  --altitude_max ALTITUDE_MAX
                        Upper bound of acceptable altitudes (in metres).
                        (default: 10000)
```