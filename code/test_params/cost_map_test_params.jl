PARAM_TEST_ENCOUNTERS_PATH="/acasx/code/test_encounters/"

PARAM_TRAJECTORY_FILEPATH = "/input_data/test_input/"

#PARAM_OUTPUT_FILEPATH = "/output_data/gridtest/test_run_grid2/"
PARAM_OUTPUT_FILEPATH = "/output_data/cost_map/test_run/"
PARAM_LOGS_FILEPATH = "$(PARAM_OUTPUT_FILEPATH)logs/"
PARAM_COSTS_FILEPATH = "$(PARAM_OUTPUT_FILEPATH)costs/"
PARAM_STRATS_FILEPATH = "$(PARAM_OUTPUT_FILEPATH)strats/"
PARAM_GRID_FILEPATH = "$(PARAM_OUTPUT_FILEPATH)grid/"

#NOTE!! Lower trajectory number set for this due to lower number of flights

PARAM_COSTS_MAP_FILEPATH = "$(PARAM_OUTPUT_FILEPATH)cost_map/"

const PARAM_TEST_TRAJECTORY_LIST = [
    "3c6664-20191201-173747.json",
    "405a49-20191116-064802.json",
    "406d26-20191202-164709.json"
]
 
# =============================================
#
# Optimisation Params
#
# =============================================


const PARAM_START_LEARNING_RATE = 0.5
const PARAM_LEARNING_RATE_LOOP_DECAY = 0.1
const PARAM_MAX_ITER = 20
const PARAM_ALT_MAX = 5000
const PARAM_CROSS_POINT_MAX = 1
const PARAM_CROSS_POINT_MIN = 0
const PARAM_RATE_MAX = 84 #Based on analysis in simple-baro-step-detection
const PARAM_RANDOM_START = true
const PARAM_FULL_LOG_DUMP = true
const PARAM_BEST_STRAT_DUMP = false
const PARAM_RANDOM_RESTART = true
const PARAM_RIDGE_COUNT_THRESHOLD = 4 

const PARAM_RUN_SELECTION_SEED = 5431
const PARAM_STRATEGY_SELECTION_SEED = 554466
const PARAM_TIEBREAKER_SEED = 112244
#const PARAM_NUMBER_OF_TRAJECTORIES = 1150
const PARAM_NUMBER_OF_TRAJECTORIES = 3

const PARAM_COST_MAP_RATE_INTERVAL = 24
const PARAM_COST_MAP_CROSS_POINT_INTERVAL = 0.2


const PARAM_ATTACKER_LATLON = {
    "00" => {"lat" => 49.862075, "lon" => 8.2448725},
    "01" => {"lat" => 49.862075, "lon" => 8.4563575},
    "02" => {"lat" => 49.862075, "lon" => 8.6678425},
    "03" => {"lat" => 49.862075, "lon" => 8.8793275},
    "10" => {"lat" => 49.979225, "lon" => 8.2448725},
    # "11" => {"lat" => 49.979225, "lon" => 8.4563575},
    # "12" => {"lat" => 49.979225, "lon" => 8.6678425},
    # "13" => {"lat" => 49.979225, "lon" => 8.8793275},
    # "20" => {"lat" => 50.096375, "lon" => 8.2448725},
    # "21" => {"lat" => 50.096375, "lon" => 8.4563575},
    # "22" => {"lat" => 50.096375, "lon" => 8.6678425},
    # "23" => {"lat" => 50.096375, "lon" => 8.8793275},
    # "30" => {"lat" => 50.213525, "lon" => 8.2448725},
    # "31" => {"lat" => 50.213525, "lon" => 8.4563575},
    # "32" => {"lat" => 50.213525, "lon" => 8.6678425},
    # "33" => {"lat" => 50.213525, "lon" => 8.8793275}
}

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


# const PARAM_ATTACKER_LATLON = {"00"=> {"lat"=> 49.84255, "lon"=> 8.209624},
# "01"=> {"lat"=> 49.84255, "lon"=> 8.350615},
# "02"=> {"lat"=> 49.84255, "lon"=> 8.491605},
# "03"=> {"lat"=> 49.84255, "lon"=> 8.632595},
# "04"=> {"lat"=> 49.84255, "lon"=> 8.773584},
# "05"=> {"lat"=> 49.84255, "lon"=> 8.914575},
# "10"=> {"lat"=> 49.92065, "lon"=> 8.209624},
# "11"=> {"lat"=> 49.92065, "lon"=> 8.350615},
# "12"=> {"lat"=> 49.92065, "lon"=> 8.491605},
# "13"=> {"lat"=> 49.92065, "lon"=> 8.632595},
# "14"=> {"lat"=> 49.92065, "lon"=> 8.773584},
# "15"=> {"lat"=> 49.92065, "lon"=> 8.914575},
# "20"=> {"lat"=> 49.99875, "lon"=> 8.209624},
# "21"=> {"lat"=> 49.99875, "lon"=> 8.350615},
# "22"=> {"lat"=> 49.99875, "lon"=> 8.491605},
# "23"=> {"lat"=> 49.99875, "lon"=> 8.632595},
# "24"=> {"lat"=> 49.99875, "lon"=> 8.773584},
# "25"=> {"lat"=> 49.99875, "lon"=> 8.914575},
# "30"=> {"lat"=> 50.07685, "lon"=> 8.209624},
# "31"=> {"lat"=> 50.07685, "lon"=> 8.350615},
# "32"=> {"lat"=> 50.07685, "lon"=> 8.491605},
# "33"=> {"lat"=> 50.07685, "lon"=> 8.632595},
# "34"=> {"lat"=> 50.07685, "lon"=> 8.773584},
# "35"=> {"lat"=> 50.07685, "lon"=> 8.914575},
# "40"=> {"lat"=> 50.15495, "lon"=> 8.209624},
# "41"=> {"lat"=> 50.15495, "lon"=> 8.350615},
# "42"=> {"lat"=> 50.15495, "lon"=> 8.491605},
# "43"=> {"lat"=> 50.15495, "lon"=> 8.632595},
# "44"=> {"lat"=> 50.15495, "lon"=> 8.773584},
# "45"=> {"lat"=> 50.15495, "lon"=> 8.914575},
# "50"=> {"lat"=> 50.23305, "lon"=> 8.209624},
# "51"=> {"lat"=> 50.23305, "lon"=> 8.350615},
# "52"=> {"lat"=> 50.23305, "lon"=> 8.491605},
# "53"=> {"lat"=> 50.23305, "lon"=> 8.632595},
# "54"=> {"lat"=> 50.23305, "lon"=> 8.773584},
# "55"=> {"lat"=> 50.23305, "lon"=> 8.914575}}

PARAM_START_STRATEGY_FIXED = {
    "run_name" => "cost-func-test3",
    "mode" => 3,
    "start_alt_delta" => 0,
    "end_alt_delta" => 0,
    "rate" => 10,    #feet per sec
    "cross_point" => 0.5, #point of the trajectory at which attacker crosses ownship
    "attacker_pos" => 1
}
