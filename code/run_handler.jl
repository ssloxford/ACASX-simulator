#include("optimise_tools.jl")


function costmap(trajectory_list)
    tic()
    map_strategies = generate_cost_map_strategies()

    run_trajectory_list(
        trajectory_list,
        map_strategies
    )
    toc()
end

function static_strategies(trajectory_list)
    tic()
    
    strategies = PARAM_DEFAULT_STRATEGIES

    run_trajectory_list(
        trajectory_list,
        strategies
    )

    toc()
end

function run_trajectory_list(
    trajectory_filenames,
    strategies
)
    count = 0
    for trajectory_name in trajectory_filenames
        count = count + 1
        # Define/instantiate discrete data
        discretes = OwnDiscreteData()
        discretes.mode_s = uint32(9999)
        discretes.modeACode = uint32(1)
        discretes.opflg = true
        discretes.manualSL = SENSITIVITY_LEVEL_AUTOMATIC
        discretes.own_ground_display_mode_on = false
        discretes.on_surface = false
        discretes.aoto_on = false
        discretes.is_coarsely_quant = false

        # For each trajectory
        LoggerTool.info(logger, "Running $(trajectory_name)")
        LoggerTool.info(logger, "Progress - $(round(count/length(trajectory_filenames)*100,1))%")
        filename = joinpath(PARAM_TRAJECTORY_FILEPATH, trajectory_name)

        # Get trajectory JSON
        
        costs_log = Dict{Any,Any}[]
        strategy_log = Dict{Any, Any}[]

        start_strategy = 0

        traj_json = JSON.parsefile(filename)

        costs = run_strategy_list(
            trajectory_name[1:end-5],
            traj_json,
            strategies,
            discretes
        )

        # TODO Add an overload without dirlist 
        # So that it will just dump strats without
        # trajectories 
        log_static_strategies(
            PARAM_STRATS_FILEPATH,
            trajectory_name[1:end-5], 
            values(strategies))

        best_cost = 0
        best_key = 0
        for strat_key in keys(strategies)
            if best_key == 0 || costs[strat_key]["cost"] > best_cost
                best_cost = costs[strat_key]["cost"]
                best_key = strat_key
            end
        end
        
        log_costs(
            PARAM_COSTS_FILEPATH, 
            trajectory_name[1:end-5], 
            costs, 
            0,
            best_cost,
            strategies[best_key])
        
        # TODO  Add if sim mode == 5 here
        log_cost_map(
            PARAM_COSTS_MAP_FILEPATH,
            trajectory_name[1:end-5], 
            costs)
    end

end

function run_strategy_list(
    trajectory_name,
    trajectory,
    strategies,
    discretes
)
    # Logs costs for the run
    costs = Dict{Any, Any}()

    # For each strategy
    for strategy_key in keys(strategies) # Gives (k,v)
        strategy = strategies[strategy_key]
        if strategy != 0
            println("-----------------------------")
            println("Running strategy $(strategy_key)")   

            altitudes = [0.0,0.0]
            
            #println("Alt prep")
            # Depending on position, get the relevant altitude and apply the 'range' from the strategy
            # Allows ascending, descending, static
            altitudes = altitude_prep(trajectory, strategy)

            #Get the strategy name to name the output file
            #Create intent for attacker using altitudes
            # This is a bit OTT as we only use the altitudes, Mode S address and trajectory length from this
            at_intents = attacker_intent_prep(trajectory, strategy, altitudes)
            # Create new aircraft instance
            ac = Aircraft.AircraftInstance()
        
            run_opensky_input_batch(
                ac, 
                trajectory["data"], 
                discretes, 
                strategy["attacker_pos"], 
                at_intents)
            # Output STM/TRM/OWN files
            
            println("Run finished")
            #Put the strategy and cost on one row
            cost_log_entry = deepcopy(strategy)
            cost_log_entry["cost"] = calculate_run_cost(ac.state_log, 1)
            
            costs[strategy_key] = cost_log_entry

            if PARAM_FULL_LOG_DUMP || SIMULATOR_MODE == 2
                dump_logs(
                    ac, 
                    PARAM_LOGS_FILEPATH, 
                    trajectory_name, 
                    strategy)
            end
            
            println("Cost $(costs[strategy_key])")

            Aircraft.reset()
        else
            println("Empty strat - setting zero $(strategy_key)")
            cost_log_entry = strategy
            cost_log_entry["cost"] = -1
            costs[strategy_key] = cost_log_entry
        end
    end

    return costs
    # Add costs to our log
    #push!(costs_log, costs)

end