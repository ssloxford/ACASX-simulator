import JSON

TACODE_CLEAR_COST = 0
TACODE_PA_COST = 1
TACODE_TA_NOMINAL_COST = 2
TACODE_TA_DEGRADED_COST = 2 # ?? Check what this is 
TACODE_RA_COST = 5
longest_ra_flag_run_COST = 5
non_zero_rate_ra_COST = 10

function initialisation_run(
    trajectory_filename,
    strategy,
    trajectory,
    discretes,
    strategy_log,
    current_best_cost,
    current_best_strategy,
    current_best_statelog,
    grid_mode = false,
    attacker_lat = -1,
    attacker_lon = -1
)
    """
    A method to carry out the initial run of an optimisation loop, setting the first round of 'best' values.

    Parameters
    ----------
    trajectory_filename : string
        Filename/descriptor for the trajectory
    strategy : Dict  
        The strategy to be used in this initial run
    trajectory : Dict
        The trajectory to run the simulation on
    discretes : OwnDiscreteData
        Standard ownship discretes
    strategy_log : List
        The log of strategies used so far 
    current_best_cost : int
        The current best cost achieved in the optimisation runs
    current_best_strategy : Dict
        The strategy achieving the current best cost in the optimisation runs
    current_best_statelog : Dict
        The statelog achieving the current best cost in the optimisation runs
    grid_mode : bool
        Whether we are using the attacker grid mode or not 
    attacker_lat : float
        Latitude of the attacker
    attacker_lon : float
        Longitude of the attacker

    Returns
    -------
    Dict
        Dictionary containing the cost, statelog and strategy from the initial run
    """

    altitudes = [0.0,0.0]

    # Depending on position, get the relevant altitude and apply the 'range' from the strategy
    # Allows ascending, descending, static
    altitudes = altitude_prep(trajectory, strategy)

    #Get the strategy name to name the output file
    fname_mod = strategy["run_name"]

    #Create intent for attacker using altitudes
    # This is a bit OTT as we only use the altitudes, Mode S address and trajectory length from this
    at_intents = attacker_intent_prep(
        trajectory, 
        strategy, 
        altitudes)
    # Create new aircraft instance
    ac = Aircraft.AircraftInstance()
    try
        if grid_mode == true
            run_opensky_input_batch_gridder(
                ac, 
                trajectory["data"], 
                discretes, 
                strategy["attacker_pos"], 
                at_intents, 
                attacker_lat, 
                attacker_lon)
        else
            run_opensky_input_batch(
                ac, 
                trajectory["data"], 
                discretes, 
                strategy["attacker_pos"], 
                at_intents)
        end
        # Output STM/TRM/OWN files
        dump_logs(
            ac, 
            PARAM_LOGS_FILEPATH, 
            trajectory_filename[1:end-5], 
            strategy)

        current_best_cost = calculate_run_cost(ac.state_log, 1)
        #println("Start cost $(current_best_cost)")
    catch error
        println("Run Failed")
        println(error)
    end

    current_best_statelog = deepcopy(ac.state_log)
    Aircraft.reset() 
    push!(
        strategy_log, 
        {
            "strategy"=>current_best_strategy,
            "cost"=>current_best_cost, 
            "best_cost"=>current_best_cost
        })
    
    return {
        "current_best_cost" => current_best_cost,
        "current_best_statelog" => current_best_statelog,
        "start_cost" => current_best_cost
    }
end

function optimise_run(
    trajectory_filename,
    strategy,
    trajectory,
    discretes,
    grid_mode = false,
    attacker_lat = -1,
    attacker_lon = -1
)
    """
    Method to carry out an optimisation run on a trajectory

    Parameters
    ----------
    trajectory_filename : string
        Filename/descriptor for the trajectory
    strategy : Dict  
        The strategy to be used in this initial run
    trajectory : Dict
        The trajectory to run the simulation on
    discretes : OwnDiscreteData
        Standard ownship discretes
    grid_mode : bool
        Whether we are using the attacker grid mode or not 
    attacker_lat : float
        Latitude of the attacker
    attacker_lon : float
        Longitude of the attacker

    Returns
    -------
    return_dict : Dict
        Dictionary containing the costs and state logs from this run
    """

    return_dict = {
        "costs" => -1,
        "state_logs" => -1
    }
    if strategy != 0
        #println("-----------------------------")
        #println("Running strategy $(strategy_key)")   

        altitudes = [0.0,0.0]
        
        # Depending on position, get the relevant altitude and apply the 'range' from the strategy
        # Allows ascending, descending, static
        altitudes = altitude_prep(trajectory, strategy)

        #Create intent for attacker using altitudes
        # This is a bit OTT as we only use the altitudes, Mode S address and trajectory length from this
        at_intents = attacker_intent_prep(
            trajectory, 
            strategy, 
            altitudes)
        # Create new aircraft instance
        ac = Aircraft.AircraftInstance()
        #try
        if grid_mode == true
            run_opensky_input_batch_gridder(
                ac, 
                trajectory["data"], 
                discretes, 
                strategy["attacker_pos"], 
                at_intents, 
                attacker_lat, 
                attacker_lon)
        else
            run_opensky_input_batch(
                ac, 
                trajectory["data"], 
                discretes, 
                strategy["attacker_pos"], 
                at_intents)
        end
        # Output STM/TRM/OWN files
        if PARAM_FULL_LOG_DUMP
            dump_logs(
                ac, 
                PARAM_LOGS_FILEPATH, 
                trajectory_filename[1:end-5], 
                strategy)
        end
        #println("Run finished")
        return_dict["costs"] = calculate_run_cost(ac.state_log, 1)
        return_dict["state_logs"] = deepcopy(ac.state_log)
        #println("Cost $(costs[strategy_key])")

        Aircraft.reset()
    end
    return return_dict
end

function starting_strategy_generator(
    strategy_selection_rng
)
    """
    Generates a starting strategy, given a random number generator

    Parameters
    ----------
    strategy_selection_rng : MersenneTwister
        An initialised random number generator 
    
    Returns 
    -------
    Dict
        A starting strategy, either randomly initialised or set to the fixed starting strategy.
    """
    new_strategy = -1
    if PARAM_RANDOM_START == true
        new_strategy =  generate_random_starting_strategy(strategy_selection_rng, 
            [-PARAM_ALT_MAX, PARAM_ALT_MAX],
            [-PARAM_RATE_MAX, PARAM_RATE_MAX],
            1
        )
    else
        new_strategy = PARAM_START_STRATEGY_FIXED
    end

    return new_strategy
end

function generate_rand_trajectory_list(rng, limit, quant)
    """
    Generates a list of trajectories for simulation use, given a random number generator. Samples without replacement.

    Parameters
    ----------
    rng : MersenneTwister
        An initialised random number generator 
    limit : int 
        The length of the input list to select from
    quant : Int
        Number of trajectories to select 

    Returns 
    -------
    inded_arr : list
        A list of trajectory indicies
    """

    index_arr = Int32[]

    # Need to avoid dupes so do it one by one 
    #&& (new_index > 0)
    while length(index_arr) < quant
        new_index = round(rand(rng)*limit)
        if !(new_index in index_arr) && (new_index > 0)
            push!(index_arr, new_index)
        end
    end
    return index_arr
end

function log_cost_grid(base_path, filename, grid)
    """
    Logs a grid of costs to file 

    Parameters
    ----------
    base_path : string
        Directory to save the cost grid to
    filename : string 
        Filename to save the cost grid under 
    grid : Dict 
        Grid structure to save 
    """
    output_fname = joinpath(base_path, "$(filename)-cost-grid.json")

    json_string = JSON.json(grid)
    f = open(output_fname, "w")
    write(f, json_string)
    close(f)
end

function log_costs(
    base_path, 
    filename, 
    costs_log, 
    start_cost, 
    best_cost, 
    best_strategy
)
    """
    Logs a cost log to file 

    Parameters
    ----------
    base_path : string
        Directory to output files to
    filename : string 
        Filename to save the object under 
    costs_log : Dict 
        Cost log to save 
    start_cost : float 
        Cost from the intialisation run
    best_cost : float
        Best cost across the optimisation run
    best_strategy : Dict
        Strategy leading to the best cost across the optimisation run
    """
    output_fname = joinpath(base_path, "$(filename)-costs.json")

    cost_log_data = {
        "metadata" => {
            "traj_name" => filename,
            "start_cost" => start_cost,
            "best_cost" => best_cost,
            "best_strategy" => best_strategy
        },
        "data" => costs_log
    }
        
    json_string = JSON.json(cost_log_data)
    f = open(output_fname, "w")
    write(f, json_string)
    close(f)
end

function log_cost_map(base_path, filename, costs_log)
    """
    Log a cost map to file
    
    Parameters
    ----------
    base_path : string
        Directory to save the cost map to 
    filename : string 
        Name to save the object under 
    costs_log : Dict
        Costs log to save to file
    """
    output_fname = joinpath(base_path, "$(filename)-costs-map.json")

    cost_log_data = {
        "metadata" => {
            "traj_name" => filename,
        },
        "data" => costs_log
    }
        
    json_string = JSON.json(cost_log_data)
    f = open(output_fname, "w")
    write(f, json_string)
    close(f)
end

function log_strategies(base_path, filename, strategies)
    """
    Dumps a list of strategies to file in column format

    Parameters
    ----------
    base_path : string
        Directory to save files to 
    filename : string 
        Filename to save output under 
    strategieis : list 
        List of strategies to output.
    """
    output_fname = joinpath(base_path, "$(filename)-strats.json")

    #Organising it like this should save space
    output_struct = { filename => {
            "mode" => Int8[],
            "run_name" => String[],
            "start_alt_delta" => Float64[],
            "end_alt_delta" => Float64[], 
            "rate" => Float32[],
            "cross_point" => Float32[],
            "attacker_pos" => Int8[],
            "cost" => Int32[],
            "best_cost" => Int32[]
        }
    }

    for i in strategies
        #println(i)
        for j in i["strategy"]
            #println(j)
            push!(output_struct[filename][j[1]], j[2])
        end
        push!(output_struct[filename]["cost"], i["cost"])
        push!(output_struct[filename]["best_cost"], i["best_cost"])
    end

    json_string = JSON.json(output_struct)
    f = open(output_fname, "w")
    write(f, json_string)
    close(f)
end

function create_cost_log_entry(strategies, costs)
    """
    Given a list of strategies and costs, this matches them up to create a cost log entry, where each strategy has an associated cost.

    Parameters
    ----------
    strategies : Dict
        Strategies used in this run
    costs : Dict 
        Costs as a result of running these strategies

    Returns
    -------
    Dict
        Dictionary mapping strategy keys to costs
    """
    entry = Dict{Any,Any}()
    for i in keys(strategies)
        entry[i] = costs[i]
    end
    return entry
end


# function find_max(arr)
    # """
    # Finds maximum value and the index it occured at in an array

    # Parameters 
    # ----------
    # arr : list 
    #     The list of numbers to search

    # Returns 
    # -------
    # max_val : int or float 
    #     Maximum value in the array
    
    # """
#     max_val = 0
#     PARAM_MAX_ITER = 0

#     for i in 1:length(arr)
#         if arr[i] > max_val
#             PARAM_MAX_ITER = i
#             max_val = arr[i]
#         end
#     end
#     return max_val, PARAM_MAX_ITER
# end


function find_all_value(strategies, find_value)
    """
    Returns all keys which have a given value in strategies

    Parameters 
    ----------
    strategies : list 
        The list of strategies to search
    find_value : Any
        The value to find

    Returns 
    -------
    key_list : list
        List of keys where the value is found
    """
    key_list = ASCIIString[]
    
    for i in keys(strategies)
        if strategies[i] == find_value
            push!(key_list, i)
        end
    end
    return key_list
end

function find_max_dict(dict)
    """
    Finds the maximum value value in the dictionary

    Parameters 
    ----------
    dict : Dict
        A dictionary to search

    Returns 
    -------
    max_val : int or float 
        Maximum value value in the dictionary
    max_key : Any
        Key of the maximum value
    """
    max_val = 0
    max_key = ""

    for i in keys(dict)
        if dict[i] > max_val
            max_key = i
            max_val = dict[i]
        end
    end
    return max_val, max_key
end

function find_max_dict_adj(dict)
    """
    Finds the maximum value in the dictionary, but with some extra logic in case no maximum is found (i.e. all zero) - in which case we just pick a key

    Parameters 
    ----------
    dict : Dict
        A dictionary to search

    Returns 
    -------
    max_val : int or float 
        Maximum value value in the dictionary
    max_key : Any
        Key of the maximum value
    """
    max_val = 0
    max_key = ""

    found = false

    for i in keys(dict)
        if dict[i] > max_val
            max_key = i
            max_val = dict[i]
            found = true
        end
    end

    if found == false
        tmp_list = ASCIIString[]
        for i in keys(dict)
            push!(tmp_list, i)
        end
        max_key = tmp_list[1]
        max_val = dict[max_key]
    end

    return max_val, max_key
end

function rand_int_in_range(rng, limit)
    """
    Simple helper function to select a random integer less than limit
    
    Parameters 
    ----------
    rng : MersenneTwister
        An initialised random number generator 
    limit : int or float
        The upper bound of numbers to select from

    Returns
    -------
    int 
        Randomly selected number 
    """
    return round(rand(rng)*limit)
end

function rand_list_index(rng, limit)
    """
    Simple helper function to select a random integer less than limit, but accounting for the case where it returns zero
    
    Parameters 
    ----------
    rng : MersenneTwister
        An initialised random number generator 
    limit : int or float
        The upper bound of numbers to select from

    Returns
    -------
    int or float 
        Randomly selected number 
    """
    val = round(rand(rng)*limit)
    if val < 1
        return 1
    elseif val > limit
        return limit
    else
        return val
    end
end

function generate_random_float_in_range(rng, range)
    """
    This is a helper to handle generating a random number over a range which runs fron negative to positive. It is a bit clumsy!
    
    Parameters 
    ----------
    rng : MersenneTwister
        An initialised random number generator 
    range : list
        A two element list of lower and upper bound

    Returns
    -------
    float 
        Randomly selected number 
    """
    rand_float = rand(rng)

    pos = rand_int_in_range(rng, 1)

    if bool(pos)
        return rand_float*range[2]
    else
        return rand_float*range[1]
    end
end

function generate_random_starting_strategy(rng, alt_range, rate_range, max_pos)
    """
    Wrapper to generate a random starting strategy

    Parameters
    ----------
    rng : MersenneTwister
        An initialised random number generator
    alt_range : list[float, float]
        A range of altitudes to select the start and end altitude differences from
    rate_range : list[float, float]
        A range of vertical rates to select the start and end vertical rates from      
    max_pos : int 
        Unused.

    Returns
    -------
    Dict
        Dictionary describing the starting strategy
    """
    return {
        "run_name" => "RANDOM_START",
        "mode" => 3,
        "start_alt_delta" => generate_random_float_in_range(rng, alt_range),
        "end_alt_delta" => generate_random_float_in_range(rng, alt_range),
        "rate" => generate_random_float_in_range(rng, rate_range),
        "cross_point" => rand(rng), #point of the trajectory at which attacker crosses ownship
        "attacker_pos" => bool(rand_int_in_range(rng, 1))
    }

end

function generate_cost_map_strategies()
    """
    This iterates over the full range of strategy parameters in order to generate strategies covering the full range of the cost function. 
    
    Returns
    -------
    new_strategies : Dict 
        Dictionary containing cost map strategies
    """
    new_strategies = Dict{Any, Any}()

    for i in -PARAM_RATE_MAX:PARAM_COST_MAP_RATE_INTERVAL:PARAM_RATE_MAX
        for j in PARAM_CROSS_POINT_MIN:PARAM_COST_MAP_CROSS_POINT_INTERVAL:PARAM_CROSS_POINT_MAX
            new_strategies["cp$(j)r$(i)-end"] = {
                "run_name" => "cp$(j)r$(i)-end",
                "mode" => 3,
                "start_alt_delta" => 0,
                "end_alt_delta" => 0,
                "rate" => i,
                "cross_point" => j, #point of the trajectory at which attacker crosses ownship
                "attacker_pos" => 0
            }
            new_strategies["cp$(j)r$(i)-mid"] = {
                "run_name" => "cp$(j)r$(i)-mid",
                "mode" => 3,
                "start_alt_delta" => 0,
                "end_alt_delta" => 0,
                "rate" => i,
                "cross_point" => j, #point of the trajectory at which attacker crosses ownship
                "attacker_pos" => 1
            }
        end 
    end
    return new_strategies
end

function prepare_strategies(current_best_strategy, filename, iteration, learning_rate)
    """
    This prepares the strategies for the next optimisation loop, given the current best strategy.

    Parameters
    ----------
    current_best_strategy : Dict 
        The current best strategy in the optimisation run, used to base the new strategies on.
    filename : string 
        The base filename for these strategies 
    iteration : int 
        The current simulation iteration 
    learning_rate : float 
        A factor by which to apply change to each parameter of new strategies

    Returns 
    -------
    new_strategies : Dict
        The new strategies 
    """
    new_strategies = Dict{Any, Any}()

    #plus on rate
    if (current_best_strategy["rate"]+(learning_rate*PARAM_RATE_MAX)) <= PARAM_RATE_MAX
        new_strategies["prm"] = {
            "run_name" => "iter$(iteration)-pr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"]+(learning_rate*PARAM_RATE_MAX),
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["pre"] = {
            "run_name" => "iter$(iteration)-pr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"]+(learning_rate*PARAM_RATE_MAX),
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    else
        new_strategies["prm"] = {
            "run_name" => "iter$(iteration)-pr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => PARAM_RATE_MAX,
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["pre"] = {
            "run_name" => "iter$(iteration)-pr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => PARAM_RATE_MAX,
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    end
    #minus rate
    if (current_best_strategy["rate"]-(learning_rate*PARAM_RATE_MAX)) >= -PARAM_RATE_MAX
        new_strategies["nrm"] = {
            "run_name" => "iter$(iteration)-nr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"]-(learning_rate*PARAM_RATE_MAX),
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["nre"] = {
            "run_name" => "iter$(iteration)-nr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"]-(learning_rate*PARAM_RATE_MAX),
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    else
        new_strategies["nrm"] = {
            "run_name" => "iter$(iteration)-nr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => -PARAM_RATE_MAX,
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["nre"] = {
            "run_name" => "iter$(iteration)-nr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => -PARAM_RATE_MAX,
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    end
    #plus cross point
    if (current_best_strategy["cross_point"]+(PARAM_CROSS_POINT_MAX*learning_rate)) <= PARAM_CROSS_POINT_MAX
        new_strategies["pcm"] = {
            "run_name" => "iter$(iteration)-pc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => current_best_strategy["cross_point"]+(PARAM_CROSS_POINT_MAX*learning_rate), #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["pce"] = {
            "run_name" => "iter$(iteration)-pc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => current_best_strategy["cross_point"]+(PARAM_CROSS_POINT_MAX*learning_rate), #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    else
        new_strategies["pcm"] = {
            "run_name" => "iter$(iteration)-pc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => PARAM_CROSS_POINT_MAX, #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["pce"] = {
            "run_name" => "iter$(iteration)-pc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => PARAM_CROSS_POINT_MAX, #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    end
    #negative cross point
    if (current_best_strategy["cross_point"]-(PARAM_CROSS_POINT_MAX*learning_rate)) >= PARAM_CROSS_POINT_MIN
        new_strategies["ncm"] = {
            "run_name" => "iter$(iteration)-nc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => current_best_strategy["cross_point"]-(PARAM_CROSS_POINT_MAX*learning_rate), #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["nce"] = {
            "run_name" => "iter$(iteration)-nc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => current_best_strategy["cross_point"]-(PARAM_CROSS_POINT_MAX*learning_rate), #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    else
        new_strategies["ncm"] = {
            "run_name" => "iter$(iteration)-nc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => PARAM_CROSS_POINT_MIN, #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
        new_strategies["nce"] = {
            "run_name" => "iter$(iteration)-nc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => PARAM_CROSS_POINT_MIN, #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 0
        }
    end

    return new_strategies
end

function prepare_strategies_gridder(current_best_strategy, filename, iteration, learning_rate)
    """
    This prepares the strategies for the next optimisation loop in grid mode, given the current best strategy. Note that this is similar to prepare_strategies, but sets all attacker positions to 'end' as it is ignored.

    Parameters
    ----------
    current_best_strategy : Dict 
        The current best strategy in the optimisation run, used to base the new strategies on.
    filename : string 
        The base filename for these strategies 
    iteration : int 
        The current simulation iteration 
    learning_rate : float 
        A factor by which to apply change to each parameter of new strategies

    Returns 
    -------
    new_strategies : Dict
        The new strategies 
    """
    new_strategies = Dict{Any, Any}()

    #plus on rate
    if (current_best_strategy["rate"]+(learning_rate*PARAM_RATE_MAX)) <= PARAM_RATE_MAX
        new_strategies["prm"] = {
            "run_name" => "iter$(iteration)-pr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"]+(learning_rate*PARAM_RATE_MAX),
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    else
        new_strategies["prm"] = {
            "run_name" => "iter$(iteration)-pr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => PARAM_RATE_MAX,
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    end
    #minus rate
    if (current_best_strategy["rate"]-(learning_rate*PARAM_RATE_MAX)) >= -PARAM_RATE_MAX
        new_strategies["nrm"] = {
            "run_name" => "iter$(iteration)-nr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"]-(learning_rate*PARAM_RATE_MAX),
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    else
        new_strategies["nrm"] = {
            "run_name" => "iter$(iteration)-nr",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => -PARAM_RATE_MAX,
            "cross_point" => current_best_strategy["cross_point"], #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    end
    #plus cross point
    if (current_best_strategy["cross_point"]+(PARAM_CROSS_POINT_MAX*learning_rate)) <= PARAM_CROSS_POINT_MAX
        new_strategies["pcm"] = {
            "run_name" => "iter$(iteration)-pc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => current_best_strategy["cross_point"]+(PARAM_CROSS_POINT_MAX*learning_rate), #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    else
        new_strategies["pcm"] = {
            "run_name" => "iter$(iteration)-pc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => PARAM_CROSS_POINT_MAX, #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    end
    #negative cross point
    if (current_best_strategy["cross_point"]-(PARAM_CROSS_POINT_MAX*learning_rate)) >= PARAM_CROSS_POINT_MIN
        new_strategies["ncm"] = {
            "run_name" => "iter$(iteration)-nc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => current_best_strategy["cross_point"]-(PARAM_CROSS_POINT_MAX*learning_rate), #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    else
        new_strategies["ncm"] = {
            "run_name" => "iter$(iteration)-nc",
            "mode" => current_best_strategy["mode"],
            "start_alt_delta" => current_best_strategy["start_alt_delta"],
            "end_alt_delta" => current_best_strategy["end_alt_delta"],
            "rate" => current_best_strategy["rate"],
            "cross_point" => PARAM_CROSS_POINT_MIN, #point of the trajectory at which attacker crosses ownship
            "attacker_pos" => 1
        }
    end

    return new_strategies
end

# Note this only works for *one* intruder
# Needs the RA run count fixing for longer intruders
function calculate_run_cost(run_data, num_intruders)
    """
    Given the output from a simulation run, this calculates the cost. Note that this function currently only supports a single intruder.

    Parameters
    ----------
    run_data : list
        A list of TRM Reports for analysis
    num_intruders : int 
        The number of intruders to evaluate - MUST BE 1.

    Returns
    -------
    cost : float 
        The cost of the inputted run data, according to the cost function.
        
    """
    # Take aircraft state_log, iterate through
    # Extract stats as per notebook into small datastructure
    # calculate cost based on that

    TACODE_CLEAR_count = 0
    TACODE_PA_count = 0
    TACODE_TA_NOMINAL_count = 0
    TACODE_TA_DEGRADED_count = 0
    TACODE_RA_count = 0

    longest_ra_flag_run = 0

    non_zero_rate_ra_count = 0

    # Need to create lists of intruders! 
    #Or do we? We probably want the absolute 
    #intruder_codes_list = fill(Int[], num_intruders, 1)
    #println(intruder_codes_list)

    active_ra_ongoing = false
    current_ra_flag_run = 0

    for i in run_data
        trm_data = i.trm_report

        active_ra_count = 0

        if length(trm_data.designation.intruder) > 0
            # Cycle through the intruders
            # Note that this will add one score per intruder
            #for j in trm_data.designation.intruder
            #I have changed this back from a loop as if it counts an active RA for each intruder
            #per cycle then the count will get trashed. Needs fixing for multiple intruders
            j = trm_data.designation.intruder[1]
            # If there's an ongoing RA, set active_ra_ongoing flag 
            if j.active_ra == true 
                active_ra_ongoing = true
                active_ra_count = active_ra_count + 1
                current_ra_flag_run = current_ra_flag_run + 1
            else
                #Check if we were on a streak
                if active_ra_ongoing == true
                    if current_ra_flag_run > longest_ra_flag_run
                        longest_ra_flag_run = current_ra_flag_run
                    end
                    current_ra_flag_run = 0
                    active_ra_ongoing = false
                end
            end

            # Increment non_zero_rate_ra_count if there's an RA happening
            if abs(trm_data.display.target_rate) > 0 && active_ra_ongoing
                non_zero_rate_ra_count = non_zero_rate_ra_count + 1
            end
            

            #Count the codes
            for j in trm_data.display.intruder
                if j.code == TACODE_CLEAR
                    TACODE_CLEAR_count = TACODE_CLEAR_count + 1
                elseif j.code == TACODE_PA 
                    TACODE_PA_count = TACODE_PA_count + 1
                elseif j.code == TACODE_TA_DEGRADED
                    TACODE_TA_DEGRADED_count = TACODE_TA_DEGRADED_count + 1
                elseif j.code == TACODE_TA_NOMINAL
                    TACODE_TA_NOMINAL_count = TACODE_TA_NOMINAL_count + 1
                elseif j.code == TACODE_RA
                    TACODE_RA_count = TACODE_RA_count + 1
                end
            end
        end
    end

    code_total = TACODE_CLEAR_count + TACODE_PA_count + TACODE_TA_DEGRADED_count + TACODE_TA_NOMINAL_count + TACODE_RA_count
    LoggerTool.debug(logger, "Non-zero RA: $(non_zero_rate_ra_count)")

    LoggerTool.debug(logger, "Codes:")
    LoggerTool.debug(logger, "TACODE_CLEAR $(TACODE_CLEAR_count)")
    LoggerTool.debug(logger, "TACODE_PA $(TACODE_PA_count)")
    LoggerTool.debug(logger, "TACODE_TA_DEGRADED $(TACODE_TA_DEGRADED_count)")
    LoggerTool.debug(logger, "TACODE_TA_NOMINAL $(TACODE_TA_NOMINAL_count)")
    LoggerTool.debug(logger, "TACODE_RA $(TACODE_RA_count)")
    LoggerTool.debug(logger, "Sanity check: $(code_total) RL $(length(run_data))")

    LoggerTool.debug(logger, "Longest RA Run: $(longest_ra_flag_run)")

    cost = 0
    cost = cost + (TACODE_CLEAR_count*TACODE_CLEAR_COST)
    cost = cost + (TACODE_PA_count*TACODE_PA_COST)
    cost = cost + (TACODE_TA_DEGRADED_count*TACODE_TA_DEGRADED_COST)
    cost = cost + (TACODE_TA_NOMINAL_count*TACODE_TA_NOMINAL_COST)
    cost = cost + (TACODE_RA_count*TACODE_RA_COST)

    cost = cost + (longest_ra_flag_run*longest_ra_flag_run_COST)

    cost = cost + (non_zero_rate_ra_count*non_zero_rate_ra_COST)

    #Now calculate cost
    return cost
end

