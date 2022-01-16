"""
This file contains any helpers used in admin/high-level running of the simulator, such as parsing command line arguments.
"""

using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "sim_mode"
            help = "Set the simulator mode, either testing, single strategy, optimisation or grid. See docs for details."
            default = 1
            arg_type = Int
            required = true
        "--params_file"
            help = "Path to parameter file to use."
            default = "user_params.jl"
            arg_type = String
        "--test_mode"
            help = "Enables test mode, which forces the simulator to use a pre-defined list of trajectories as input."
            action = :store_true
    end

    return parse_args(s)
end

function trajectory_selector(dir_list)
    LoggerTool.info(logger, "Loaded files - $(length(dir_list)) trajectories.")

    # Add RNGs here
    # One for run selection (seeded), one for strategy selection
    trajectory_selection_rng = MersenneTwister(PARAM_RUN_SELECTION_SEED)

    # Select strategies here
    trajectory_indices = generate_rand_trajectory_list(
        trajectory_selection_rng,                                             length(dir_list),
        PARAM_NUMBER_OF_TRAJECTORIES)

    LoggerTool.info(logger, "Selected $(length(trajectory_indices)) trajectories.")

    return trajectory_indices
end