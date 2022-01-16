Installation and Quickstart
============

The project should be pretty easy to set up. You will need the following:
* Docker (inc. docker-compose)
* Python 3 with Pytest and Requests installed

First, grab the repo using:
```
git clone https://github.com/ssloxford/ACASX
```

Then follow these steps:
1. Drop the standardised code into `code/standardised_code/` (Skip if you have the full repo)
2. Drop the DO-385 data files (from `DO-385_PDIFs_20180808.zip`) in `code/do385_data`.
3. Build the Docker image and run the DO-385 tests with `docker-compose run simulator 1`

This should output that no tests have failed.

Then, to run your own inputs:
4. Put your input files in `input_data/` - check [here](usage/input_data.md) if you are not sure what this should look like.
5. Check out which mode you want to run [here](simmodes/modes_overview.md)
6. Change `code/user_params.jl` to suit your use case and point to your input files - with a guide [here](usage/user_params.md). If you want to run all the trajectories you provided, just set `PARAM_NUMBER_OF_TRAJECTORIES` to be the same number as you provide.
7. Run the simulator with `docker-compose run simulator [MODE]`!

The help output for this command is:
```
usage: main_opt_refactor.jl [--params_file PARAMS_FILE] [--test_mode]
                        [-h] sim_mode

positional arguments:
  sim_mode              Set the simulator mode, either testing, single
                        strategy, optimisation or grid. See docs for
                        details. (type: Int64, default: 1)

optional arguments:
  --params_file PARAMS_FILE
                        Path to parameter file to use. (default:
                        "user_params.jl")
  --test_mode           Enables test mode, which forces the simulator
                        to use a pre-defined list of trajectories as
                        input.
  -h, --help            show this help message and exit
```