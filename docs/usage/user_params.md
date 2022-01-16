User Parameters
===============

## Input Filepaths
Note that these paths are relative to the Docker container, so should not need to be changed. If you want to change where the inputs and outputs are on your filesystem, change the volume mount options in `docker-compose.yml`. 

`PARAM_TEST_ENCOUNTERS_PATH`
* Default: `"/acasx/code/test_encounters/"`
* Directory containing the DO-385 test encouter JSON files

`PARAM_TRAJECTORY_FILEPATH` 
* Default: `"/input_data/frankfurt-clean"`
* Directory containing trajectory JSON files, e.g. those exported by the [pipeline](input_data.md) included in this project.


## Output Filepaths
As with the input filepaths, these are relative to the Docker container __however__ because this is volume mounted, you will need to change `PARAM_OUTPUT_FILEPATH` to whatever output path you wish to save to, in whichever directory you have volume mounted for output in `docker-compose.yml`.

`PARAM_OUTPUT_FILEPATH`
* Default: "/output_data/static_strat/test_run/"
* Output directory - change anything after `output_data/` to set the output subdirectory.

`PARAM_LOGS_FILEPATH`
* Default: "$(PARAM_OUTPUT_FILEPATH)logs/"
* Simulator internal state log output path

`PARAM_COSTS_FILEPATH`
* Default: "$(PARAM_OUTPUT_FILEPATH)costs/"
* Logging location for cost function calculations per-strategy

`PARAM_STRATS_FILEPATH`
* Default: "$(PARAM_OUTPUT_FILEPATH)strats/"
* Logging location for strategies used at each simulator step

`PARAM_GRID_FILEPATH`
* Default: "$(PARAM_OUTPUT_FILEPATH)grid/"
* Logging location for the output grid of costs, when grid mode is used

`PARAM_COSTS_MAP_FILEPATH`
* Default: "$(PARAM_OUTPUT_FILEPATH)cost_map/"
* Logging location for the cost map, when the cost map mode is used

## Optimiser Parameters

These parameters set how the optimiser works. Feel free to tinker!

`PARAM_START_LEARNING_RATE`
* Default: 0.5
* Starting factor to adjust the strategy by on each optimisation loop

`PARAM_LEARNING_RATE_LOOP_DECAY`
* Default: 0.1
* Percentage to reduce the learning rate by on each loop

`PARAM_MAX_ITER`
* Default: 20
* Maximum number of optimisation loops per trajectory

`PARAM_ALT_MAX`
* Default: 5000
* Maximum allowed altitude for the attacker

`PARAM_CROSS_POINT_MAX`
* Default: 1
* Maximum value of the 'cross point', i.e. the point in the trajectory the attacker and target are at the same altitude, as a proportion of the trajectory - here 1 means the end of the trajectory.

`PARAM_CROSS_POINT_MIN`
* Default: 0
* As above, here 0 means the start of the trajectory

`PARAM_RATE_MAX`
* Default: 84 
* The maximum vertical rate (positive or negative) of an attacker.  Based on analysis of commercial aircraft.

`PARAM_RANDOM_START`
* Default: true
* Whether to start each optimisation run with a randomly initialised strategy. If false, the static strategy is used (see below).

`PARAM_FULL_LOG_DUMP`
* Default: true
* Whether to dump all logs at each step of every trajectory run. Will output a lot of data if you are using this with the optimisation loop!

`PARAM_BEST_STRAT_DUMP`
* Default: false
* Whether to dump the best strategy at the end of each optimisation, or before a random restart.

`PARAM_RANDOM_RESTART`
* Default: true
* Whether to restart with a random strategy if the optimiser gets stuck at a potentially local optima.

`PARAM_RIDGE_COUNT_THRESHOLD`
* Default: 4 
* How long to continue trying to optimise strategies when the cost remains the same.

`PARAM_RUN_SELECTION_SEED`
* Default: 5431
* Random number generator seed for trajectory selection.

`PARAM_STRATEGY_SELECTION_SEED`
* Default: 554466
* Random number generator seed for strategy selection (used when generating random strategies).

`PARAM_TIEBREAKER_SEED`
* Default: 112244
* Random number generator seed for breaking ties when two strategies have the same cost.

`PARAM_NUMBER_OF_TRAJECTORIES`
* Default: 3
* Number of trajectories to randomly select.

`PARAM_COST_MAP_RATE_INTERVAL`
* Default: 24
* The step interval across the valid range of vertical rates, when calculating the cost map

`PARAM_COST_MAP_CROSS_POINT_INTERVAL`
* Default: 0.2
* The step interval across the valid range of crossing points, when calculating the cost map

## Default Strategies

### Grid Mode
```
PARAM_ATTACKER_LATLON = {
    "00" => {"lat" => 49.862075, "lon" => 8.2448725},
    "01" => {"lat" => 49.862075, "lon" => 8.4563575},
    "02" => {"lat" => 49.862075, "lon" => 8.6678425},
    "03" => {"lat" => 49.862075, "lon" => 8.8793275},
    "10" => {"lat" => 49.979225, "lon" => 8.2448725},
    "11" => {"lat" => 49.979225, "lon" => 8.4563575},
    "12" => {"lat" => 49.979225, "lon" => 8.6678425},
    "13" => {"lat" => 49.979225, "lon" => 8.8793275},
    "20" => {"lat" => 50.096375, "lon" => 8.2448725},
    "21" => {"lat" => 50.096375, "lon" => 8.4563575},
    "22" => {"lat" => 50.096375, "lon" => 8.6678425},
    "23" => {"lat" => 50.096375, "lon" => 8.8793275},
    "30" => {"lat" => 50.213525, "lon" => 8.2448725},
    "31" => {"lat" => 50.213525, "lon" => 8.4563575},
    "32" => {"lat" => 50.213525, "lon" => 8.6678425},
    "33" => {"lat" => 50.213525, "lon" => 8.8793275}
}
```
Defines a grid of coordinates to position the attacker at. General form is:
```
PARAM_ATTACKER_LATLON = {
    "label_1" => {"lat" => lat_1, "lon" => lon_1
    ...
    "label_n" => {"lat" => lat_n, "lon" => lon_n}
    ...
}
```

### Optimiser Default Start Strategy

If `PARAM_RANDOM_START` is not set to true, this strategy will be used. 

```
PARAM_START_STRATEGY_FIXED = {
    "run_name" => "cost-func-test3",
    "mode" => 3,
    "start_alt_delta" => 0,
    "end_alt_delta" => 0,
    "rate" => 10,    #feet per sec
    "cross_point" => 0.5, #point of the trajectory at which attacker crosses ownship
    "attacker_pos" => 1
}
```

The fields are as follows:
* `run_name` - name of the run, will be used to save output under
* `mode` - mode - typically only 0 or 3 is used - check [here](../techdetail/attacker_strategy)
* `start_alt_delta` - The starting altitude difference to the target aircraft. Here this is zero, so it is level.
* `end_alt_delta` - The ending altitude difference to the target aircraft. Here this is zero, so it is level.
* `rate` - the vertical rate of the attacker in feet/s, only used in modes 1, 2 and 3.
* `cross_point` - the crossover point of the attacker and target, i.e. the point in the trajectory when the attacker and target altitudes are equal, from 0 to 1.
* `attacker_pos` - either 0 for underneath the end of the trajectory, or 1 for in the middle.

### Static Strategies

These are the strategies used to test the static strategy mode, but are also useful to show how a strategy is defined.

```
const PARAM_DEFAULT_STRATEGIES = {
    "cost-func-test1" => {
        "run_name" => "cost-func-test1",
        "mode" => 0,
        "start_alt_delta" => -2000,
        "end_alt_delta" => 2000,
        "rate" => 10,    #feet per sec
        "cross_point" => 0.75, #point of the trajectory at which attacker crosses ownship
        "attacker_pos" => 1
    },
    "cost-func-test2" => {
        "run_name" => "cost-func-test2",
        "mode" => 0,
        "start_alt_delta" => 2000,
        "end_alt_delta" => -2000,
        "rate" => -10,    #feet per sec
        "cross_point" => 0.25, #point of the trajectory at which attacker crosses ownship
        "attacker_pos" => 1
    },
    "cost-func-test3" => {
        "run_name" => "cost-func-test3",
        "mode" => 0,
        "start_alt_delta" => 0,
        "end_alt_delta" => 0,
        "rate" => 0,    #feet per sec
        "cross_point" => 0.25, #point of the trajectory at which attacker crosses ownship
        "attacker_pos" => 1
    }
}
```

