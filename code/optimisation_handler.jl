function optimise(trajectory_list)
    """
    Wrapper function to optimise attacks against each trajectory in the given list, from the two static attacker positions, mid- and end-of trajectory.
    Parameters
    ----------
    trajectory_list : list
        List of trajectories to use in this optimisation run
    """
    tic()
    trajectory_optimiser(trajectory_list)
    toc()
end

function gridder(trajectory_list)
    """
    Wrapper function to optimise attacks against a each trajectory in the given list, across all positions in a predefined grid of attacker positions.

    Parameters
    ----------
    trajectory_list : list
        List of trajectories to use in this optimisation run
    """
    
    best_scores_grid = Dict{Any,Any}()
    progress_counter = 0
    tic()
    for latlon_pair in PARAM_ATTACKER_LATLON
        curr_lat = latlon_pair[2]["lat"]
        curr_lon = latlon_pair[2]["lon"]

        LoggerTool.info(logger, "Currently evaluating $(curr_lat), $(curr_lon).")
        LoggerTool.info(logger, "Grid Progress - $(round(progress_counter/length(PARAM_ATTACKER_LATLON)*100,1))%")
        
        #best_scores_grid[latlon_pair[1]] = Dict{Any,Any}()

        traj_best_costs = trajectory_optimiser(
            trajectory_list,
            true,
            curr_lat,
            curr_lon,
            latlon_pair[1]
        )
        progress_counter = progress_counter + 1
        LoggerTool.debug(logger, "Best costs outside loop: $(traj_best_costs)")
        best_scores_grid[latlon_pair[1]] = traj_best_costs
    end
    log_cost_grid(PARAM_GRID_FILEPATH, "grid", best_scores_grid)
    toc()
end


function trajectory_optimiser(
    trajectory_filenames, 
    grid_mode = false,
    attacker_lat = -1,
    attacker_lon = -1,
    grid_id = -1
    )
    """
    Main optimisation loop - for each trajectory in trajectory_filenames, this performs an initial loop then tries to optimise the attacker strategy according to our cost function until it either cannot improve, or hits MAX_ITER.

    Parameters
    ----------
    trajectory_filenames : list
        List of trajectory filenames being used in this optimisation run
    grid_mide : bool 
        True if running in grid mode, where we are defining a grid of coordinate pairs for attacker positions 
    attacker_lat : float
        Attacker latitude, only set if we are in grid mode
    attacker_lon : float 
        Attacker longitude, only set if we are in grid mode 
    grid_id : string 
        Name of the grid to be used in saving, if we are in grid mode.
    """
    best_costs = Dict{Any,Any}()
    # Run through trajectories
    progress_counter = 0
    for trajectory_filename in trajectory_filenames
        
        # For initialising starting strategies
        strategy_selection_rng = MersenneTwister(PARAM_STRATEGY_SELECTION_SEED)
        # For breaking strategy ties
        tiebreaker_rng = MersenneTwister(PARAM_TIEBREAKER_SEED)

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
        LoggerTool.info(logger, "Running $(trajectory_filename)")
        # println("Progress - $(round(i/length(trajectory_indices)*100,1))%")
        filename = joinpath(PARAM_TRAJECTORY_FILEPATH, trajectory_filename)

        # Get trajectory JSON
        
        costs_log = Dict{Any,Any}[]
        strategy_log = Dict{Any, Any}[]

        start_strategy = 0
        
        try
            traj_json = JSON.parsefile(filename)
#            println(traj_json)

            #Randomise our start strategy if param is set
            current_best_strategy = starting_strategy_generator(strategy_selection_rng)

            #println("starting with $(current_best_strategy)")
            current_best_cost = 0
            start_cost = 0
            current_best_statelog = 0

            #Refactor the running bit
            strategy = current_best_strategy

            # Random restart vars 
            overall_best_strategy = 0
            overall_best_cost = 0
            overall_best_statelog = 0

            #println("-----------------------------")
            #println("Running strategy $(strategy["run_name"])")   

            # ===================================
            #
            # Start of initialisation loop
            #
            # ===================================


            ret_vals = initialisation_run(
                trajectory_filename,
                strategy,
                traj_json,
                discretes,
                strategy_log,
                current_best_cost,
                current_best_strategy,
                current_best_statelog,
                grid_mode,
                attacker_lat,
                attacker_lon
            )
            #print(ret_vals)

            current_best_cost = ret_vals["current_best_cost"]
            start_cost = ret_vals["start_cost"]
            current_best_statelog = ret_vals["current_best_statelog"]

            #println("Best cost after start $(current_best_cost)")

            # This presets values in case none of the strategies 
            # are better - Should look at why that happens.
            overall_best_strategy = current_best_strategy
            overall_best_statelog = ret_vals["current_best_statelog"]

            # ===================================
            #
            # Start of optimisation loop
            #
            # ===================================


            #Currently just varies one thing at once 
            learning_rate = PARAM_START_LEARNING_RATE
            last_cost = start_cost
            ridge_count = 0

            for j in 1:PARAM_MAX_ITER
                print("\r")
                print("\u001b[36m[STATUS]\u001b[0m: Iteration $(j)/$(PARAM_MAX_ITER)")
                opt_strategies = 0
                if grid_mode == true
                    opt_strategies = prepare_strategies_gridder(
                        current_best_strategy, 
                        filename, 
                        j, 
                        learning_rate)
                else
                    opt_strategies = prepare_strategies(
                        current_best_strategy, 
                        filename, 
                        j, 
                        learning_rate)
                end
                
                # Logs costs for the run
                costs = Dict{Any, Any}()

                #This allows us to log the best run data on each run
                iter_state_logs = Dict{Any, Any}()

                # For each strategy
                #println("STRATS")
                #println(keys(opt_strategies))
                for strategy_key in keys(opt_strategies) # Gives (k,v)
                    #println("KEY $(strategy_key)")
                    strategy = opt_strategies[strategy_key]
                    run_results = 0
                    if grid_mode == true
                        run_results = optimise_run(
                            trajectory_filename,
                            strategy,
                            traj_json,
                            discretes,
                            grid_mode,
                            attacker_lat,
                            attacker_lon
                            )
                    else
                        run_results = optimise_run(
                            trajectory_filename,
                            strategy,
                            traj_json,
                            discretes)
                    end



                    costs[strategy_key] = run_results["costs"]
                    if run_results["state_logs"] != -1
                        iter_state_logs[strategy_key] = run_results["state_logs"]
                    end
                end
                #println("Max Cost")
                # Find max cost and it's key
                max_cost = -1
                max_key = -1
                if grid_mode == true
                    max_cost, max_key = find_max_dict_adj(costs)
                else
                    max_cost, max_key = find_max_dict(costs)
                end
                # Add costs to our log
                push!(costs_log, create_cost_log_entry(opt_strategies, costs))
                # Add best strategy to our create_cost_log_entry
                push!(
                    strategy_log, 
                    {
                        "strategy"=>opt_strategies[max_key],
                        "cost"=>max_cost,
                        "best_cost"=>current_best_cost
                    })
                # Finally dump the logs of the best strategy
                if PARAM_BEST_STRAT_DUMP
                    dump_logs_opt(
                        iter_state_logs[max_key], 
                        PARAM_LOGS_FILEPATH, 
                        trajectory_filename[1:end-5], 
                        opt_strategies[max_key])
                end

                #println("checking costs")

                # If the new best cost is higher, just take that
                if max_cost > current_best_cost
                    #println("New best cost $(max_cost)")
                    current_best_cost = max_cost
                    current_best_strategy = opt_strategies[max_key]
                    current_best_statelog = deepcopy(iter_state_logs[max_key])
                    ridge_count = 0
                elseif max_cost == current_best_cost && ridge_count < PARAM_RIDGE_COUNT_THRESHOLD
                    # Otherwise if it is equal we need to proceed
                    # along the ridge  

                    # Get all the strategies with the maximum cost
                    max_key_list = find_all_value(costs, max_cost)

                    # If we have steps left on the ridge, continue
                    # If we have one option, just take that
                    if length(max_key_list) == 1
                        current_best_cost = max_cost
                        current_best_strategy = opt_strategies[max_key]
                        current_best_statelog = deepcopy(iter_state_logs[max_key])
                        #println("One option")
                    else
                        # Otherwise pick a random option
                        key = max_key_list[rand_list_index(tiebreaker_rng, length(max_key_list))]
                        current_best_cost = max_cost
                        current_best_strategy = opt_strategies[key]
                        current_best_statelog = deepcopy(iter_state_logs[max_key])
                        #println("Multiple options")
                    end
                    ridge_count = ridge_count + 1            
                else
                    #println("Breaking at run $(j) - only descent available")
                    if PARAM_RANDOM_RESTART
                        #println("Random restart!")
                        #If random restart, we simply reset 
                        # our current best strategy
                        # and save it to overall best 
                        if current_best_cost > overall_best_cost
                            overall_best_cost = current_best_cost
                            overall_best_statelog = current_best_statelog
                            overall_best_strategy = current_best_strategy
                        end
                        current_best_cost = -1
                        current_best_statelog = 0

                        current_best_strategy = starting_strategy_generator(strategy_selection_rng)

                        # Reset learning rate
                        learning_rate = PARAM_START_LEARNING_RATE
                    else
                        #println("Ending run.")
                        break
                    end
                end
                
                #Reduce the learning rate
                learning_rate = learning_rate - (learning_rate*PARAM_LEARNING_RATE_LOOP_DECAY)

            end

            # Need to do some stuff here about whether we're using random restart or not

            if PARAM_RANDOM_RESTART
                println()
                LoggerTool.info(logger, "Best Strategy $(overall_best_strategy)")
                LoggerTool.info(logger, "Best cost $(overall_best_cost)")
            else
                println()
                LoggerTool.info(logger, "Best Strategy $(current_best_strategy)")
                LoggerTool.info(logger, "Best cost $(current_best_cost)")

                # We can also now stash the current best in overall best to avoid
                # duplication below
                overall_best_cost = current_best_cost
                overall_best_statelog = current_best_statelog
                overall_best_strategy = current_best_strategy
            end
            #end

            #print("Overall best cost $(overall_best_cost)")

            if grid_mode == true
                #println("Logging")
                #println(overall_best_statelog)
                log_costs(PARAM_COSTS_FILEPATH, 
                            "$(trajectory_filename[1:end-5])-$(grid_id)", 
                            costs_log, 
                            start_cost,
                            overall_best_cost,
                            overall_best_strategy)
                log_strategies(PARAM_STRATS_FILEPATH,
                                "$(trajectory_filename[1:end-5])-$(grid_id)", 
                                strategy_log)
                #if overall_best_statelog != 0                                
                dump_logs_opt(overall_best_statelog, 
                                PARAM_LOGS_FILEPATH, 
                                "$(trajectory_filename[1:end-5])-$(grid_id)", 
                                overall_best_strategy)
                #end
            else 
                log_costs(
                    PARAM_COSTS_FILEPATH, 
                    trajectory_filename[1:end-5], 
                    costs_log, 
                    start_cost,
                    overall_best_cost,
                    overall_best_strategy)
                log_strategies(
                    PARAM_STRATS_FILEPATH,
                    trajectory_filename[1:end-5], 
                    strategy_log)
                dump_logs_opt(
                    overall_best_statelog, 
                    PARAM_LOGS_FILEPATH, 
                    trajectory_filename[1:end-5], 
                    overall_best_strategy)
            end
            #println("Best cost for $(dir_list[i]) is $(overall_best_cost)")
            best_costs[trajectory_filename] = overall_best_cost
            
        catch err
            # Add newline since we are likely to follow a print statement
            print("\n")
            LoggerTool.error(logger, "Maybe failed to extract JSON for $(filename) - probably NaN")
            LoggerTool.error(logger, err)
        end
        print("\n")
    end

    #toc()
    # Otherwise it will ping after each grid slot
    if grid_mode == false
        run(`python3 ping_slack.py`)
    end

    return best_costs
end