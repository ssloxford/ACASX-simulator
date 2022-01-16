workspace()

import JSON

cd("/acasx/code/")

include("logger.jl")
include("utilities.jl")

include("standardised_code/structures.jl")
include("standardised_code/math_utils.jl")
include("standardised_code/global_constants.jl")

include("aircraft.jl")
include("simulator_helpers.jl")
include("optimise_helpers.jl")

include("experiment_datastructs.jl")
include("data_export.jl")

include("simulator_core.jl")

include("tests/tests.jl")
include("tests/test_encounter.jl")
include("tests/test_run.jl")

include("experiment_tools.jl")
include("opensky_tools.jl")

include("run_handler.jl")
include("optimisation_handler.jl")


#import LoggerTool
import Aircraft

#import LoggerTool

# Set this up as an aircraft logger - logs internal stuff
const logger = LoggerTool.setup(true, true, 2)

#This checks for infs and replaces them with the proper symbol
#It also checks for matrices inside arrays and extracts them

type TRMOutput
    report_time::Float64
    trm_report::TRMReport
    TRMOutput(report_time::Float64, trm_report::TRMReport) = new(report_time, trm_report)
end

#discretes = OwnDiscreteData()

# Load the list of trajectories to run on 
tic()

println(logger)

parsed_args = parse_commandline()
LoggerTool.info(logger, parsed_args)

include(parsed_args["params_file"])

mkpath(PARAM_LOGS_FILEPATH)
mkpath(PARAM_COSTS_FILEPATH)
mkpath(PARAM_STRATS_FILEPATH)
mkpath(PARAM_GRID_FILEPATH)
mkpath(PARAM_COSTS_MAP_FILEPATH)

global SIMULATOR_MODE = parsed_args["sim_mode"]

if parsed_args["test_mode"] == true
    trajectory_list = PARAM_TEST_TRAJECTORY_LIST
else
    dir_list = readdir(PARAM_TRAJECTORY_FILEPATH)
    trajectory_indices = trajectory_selector(dir_list)
    trajectory_list = dir_list[trajectory_indices]
end

if parsed_args["sim_mode"] == 1
    LoggerTool.info(logger, "Testing Mode.")
    run_all_test_groups()
elseif parsed_args["sim_mode"] == 2
    LoggerTool.info(logger, "Defined Strategy Mode.")
    static_strategies(trajectory_list)
elseif parsed_args["sim_mode"] == 3
    LoggerTool.info(logger, "Optimiser Mode.")
    optimise(trajectory_list)
elseif parsed_args["sim_mode"] == 4
    LoggerTool.info(logger, "Grid Mode.")
    gridder(trajectory_list)
elseif parsed_args["sim_mode"] == 5
    LoggerTool.info(logger, "Cost Map Mode.")
    costmap(trajectory_list)
end

LoggerTool.close(logger)
