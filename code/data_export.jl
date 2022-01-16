"""
data_export.jl

This file contains a range of functions dump simulator state, for later analysis.

"""
function dump_logs(ac, path, traj_name, strategy)
    """
    Takes AircraftInstance and outputs three files,
    one for STM, TRM and OWN states for each step of
    the run.
    
    Parameters
    ==========
    ac : AircraftInstance
        AircraftInstance to extract state from
    path : String
        Path to directory to output logs to
    traj_name : String
        The name of the trajectory, used in the output filenames
    strategy : String
        The strategy identifier, used in the output filenames
    """

    # Dump TRM data
    trm_data = Dict{Any, Any}[]
    for i in ac.state_log
        #t = TRMOutput(i.time, i.trm_report)
        push!(trm_data, {"report_time"=>i.time, "trm_report"=>i.trm_report})
    end

    #Assemble metadata
    trm_file_data = {
        "metadata" =>
        {
            "traj_name" => traj_name,
            "run_name" => strategy["run_name"],
            "content" => "trm",
            "mode" => strategy["mode"],
            "start_alt_delta" => strategy["start_alt_delta"],
            "end_alt_delta" => strategy["end_alt_delta"],
            "rate" => strategy["rate"],
            "attacker_pos" => strategy["attacker_pos"],
            "cross_point" => strategy["cross_point"]
        },
        "run_data" => trm_data
    }
    
    json_string = JSON.json(trm_file_data)
    f = open(joinpath(path,"$(traj_name)-$(strategy["run_name"])-TRM.json"), "w")
    write(f, json_string)
    close(f)
    
    # Dump STM data
    stm_data = Dict{Any, Any}[]
    for i in ac.state_log
        #t = TRMOutput(i.time, i.trm_report)
        push!(stm_data, {"report_time"=>i.time, "stm_report"=>i.stm_report})
    end

    #Assemble metadata
    stm_file_data = {
        "metadata" =>
        {
            "traj_name" => traj_name,
            "run_name" => strategy["run_name"],
            "content" => "stm",
            "mode" => strategy["mode"],
            "start_alt_delta" => strategy["start_alt_delta"],
            "end_alt_delta" => strategy["end_alt_delta"],
            "rate" => strategy["rate"],
            "attacker_pos" => strategy["attacker_pos"],
            "cross_point" => strategy["cross_point"]
        },
        "run_data" => stm_data
    }

    json_string = JSON.json(stm_file_data)
    f = open(joinpath(path,"$(traj_name)-$(strategy["run_name"])-STM.json"), "w")
    write(f, json_string)
    close(f)

    # Dump OWN data 
    own_data = Dict{Any, Any}[]
    for i in ac.state_log
        #t = TRMOutput(i.time, i.trm_report)
        push!(own_data, {"report_time"=>i.time, "own_report"=>i.own})
        #println(i.time)
        #println(i.own)
        
    end

    #Assemble metadata
    own_file_data = {
        "metadata" =>
        {
            "traj_name" => traj_name,
            "run_name" => strategy["run_name"],
            "content" => "own",
            "mode" => strategy["mode"],
            "start_alt_delta" => strategy["start_alt_delta"],
            "end_alt_delta" => strategy["end_alt_delta"],
            "rate" => strategy["rate"],
            "attacker_pos" => strategy["attacker_pos"],
            "cross_point" => strategy["cross_point"]
        },
        "run_data" => own_data
    }

    json_string = JSON.json(own_file_data)
    f = open(joinpath(path,"$(traj_name)-$(strategy["run_name"])-OWN.json"), "w")
    write(f, json_string)
    close(f)

end

function dump_logs_opt(state_log, path, traj_name, strategy)
    """
    Log dumper used in the optimisation process. Given a state log from
    an aircraft, it dumps the TRM, STM and OWN log.
    
    Parameters
    ==========
    ac : AircraftInstance
        AircraftInstance to extract state from
    path : String
        Path to directory to output logs to
    traj_name : String
        The name of the trajectory, used in the output filenames
    strategy : String
        The strategy identifier, used in the output filenames
    """

    # Dump TRM data
    trm_data = Dict{Any, Any}[]
    #println(length(state_log))
    for i in state_log
        #t = TRMOutput(i.time, i.trm_report)

        push!(trm_data, {"report_time"=>i.time, "trm_report"=>i.trm_report})
    end

    #Assemble metadata
    trm_file_data = {
        "metadata" =>
        {
            "traj_name" => traj_name,
            "run_name" => strategy["run_name"],
            "content" => "trm",
            "mode" => strategy["mode"],
            "start_alt_delta" => strategy["start_alt_delta"],
            "end_alt_delta" => strategy["end_alt_delta"],
            "rate" => strategy["rate"],
            "attacker_pos" => strategy["attacker_pos"],
            "cross_point" => strategy["cross_point"]
        },
        "run_data" => trm_data
    }
    
    json_string = JSON.json(trm_file_data)
    f = open(joinpath(path,"$(traj_name)-$(strategy["run_name"])-TRM.json"), "w")
    write(f, json_string)
    close(f)
    
    # Dump STM data
    stm_data = Dict{Any, Any}[]
    for i in state_log
        #t = TRMOutput(i.time, i.trm_report)
        push!(stm_data, {"report_time"=>i.time, "stm_report"=>i.stm_report})
    end

    #Assemble metadata
    stm_file_data = {
        "metadata" =>
        {
            "traj_name" => traj_name,
            "run_name" => strategy["run_name"],
            "content" => "stm",
            "mode" => strategy["mode"],
            "start_alt_delta" => strategy["start_alt_delta"],
            "end_alt_delta" => strategy["end_alt_delta"],
            "rate" => strategy["rate"],
            "attacker_pos" => strategy["attacker_pos"],
            "cross_point" => strategy["cross_point"]
        },
        "run_data" => stm_data
    }

    json_string = JSON.json(stm_file_data)
    f = open(joinpath(path,"$(traj_name)-$(strategy["run_name"])-STM.json"), "w")
    write(f, json_string)
    close(f)

    # Dump OWN data 
    own_data = Dict{Any, Any}[]
    for i in state_log
        #t = TRMOutput(i.time, i.trm_report)
        push!(own_data, {"report_time"=>i.time, "own_report"=>i.own})
        #println(i.time)
        #println(i.own)
        
    end

    #Assemble metadata
    own_file_data = {
        "metadata" =>
        {
            "traj_name" => traj_name,
            "run_name" => strategy["run_name"],
            "content" => "own",
            "mode" => strategy["mode"],
            "start_alt_delta" => strategy["start_alt_delta"],
            "end_alt_delta" => strategy["end_alt_delta"],
            "rate" => strategy["rate"],
            "attacker_pos" => strategy["attacker_pos"],
            "cross_point" => strategy["cross_point"]
        },
        "run_data" => own_data
    }

    json_string = JSON.json(own_file_data)
    f = open(joinpath(path,"$(traj_name)-$(strategy["run_name"])-OWN.json"), "w")
    write(f, json_string)
    close(f)

end

function log_static_strategies(
    base_path,
    filename,
    strategies
)
    """
    Given a list of strategies, this method dumps them to files

    Parameters
    ==========
    base_path : String
        Path to directory to output strategies to
    filename : String
        The name of 
    strategies : List
        Strategies to dump
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
            # "best_cost" => Int32[]
        }
    }

    for strat in strategies
        #println(strat)
        for field in strat
            #println(j)
            push!(output_struct[filename][field[1]], field[2])
        end
        # push!(output_struct[filename]["cost"], strat["cost"])
        # push!(output_struct[filename]["best_cost"], strat["best_cost"])
    end

    json_string = JSON.json(output_struct)
    f = open(output_fname, "w")
    write(f, json_string)
    close(f)
end