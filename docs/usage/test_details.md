Testing the Simulator
=====================

## Core Simulation Code

The DO-385 standard provides a range of tests which test whether the standardised code works correctly. This is implemented and can be run as mode 1:
```
docker-compose run simulator 1
```
This will run each of the seven test groups, __skipping__ any non-prescriptive (i.e. optional) tests. This is because the non-prescriptive tests are for Mode C, and we do not implement this. If you are interested on why we don't implement Mode C, see [here](../techdetail/simulator.md).

## Experiment Code

I have also provided some output tests for each of the experiment modes. Baseline outputs are provided in `baseline_output.tgz` and should be extracted to your `output_data/` directory. You can then run all tests with `test_all.sh`. Parameter files are included to test each of the four experimental modes, in the `code/test_params` directory, specifically:
* `code/test_params/static_strat_test_params.jl` for static strategy mode.
* `code/test_params/optimise_test_params.jl` for optimisation mode.
* `code/test_params/gridder_test_params.jl` for grid optimisation mode.
* `code/test_params/cost_map_test_params.jl` for cost map mode.

They are almost entirely the same bar a few changes such as the number of trajectories/the list of trajectories. 

__Note__: Test parameter file names are relative to the `code` directory, since they are loaded inside the Docker container. They are __not__ relative to the project root.

These test parameter files will be used automatically if you run `test_all.sh`. Alternatively, if you want to test a single component, you can do so with:
```
docker-compose run simulator [MODE] --params_file [TEST_PARAMS_FILE] --test_mode
```
Note the `--test_mode` flag - this bypasses normal trajectory selection, instead using a fixed list of trajectories for test. These are included in the repository (whereas other input trajectories are not, due to size).

Once this has finished, you can check whether the output matches the baseline using the Pytest files in `tests/`. These can be run from the `tests/` directory using:
`pytest -q TEST_NAME.py`. You will need to have Pytest installed for this to work.