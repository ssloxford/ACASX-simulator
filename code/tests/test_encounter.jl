import JSON

include("../user_params.jl")
#include("../helpers.jl")


function LoadAllEncounters(encounter_path::String)
    encounter_group_paths = readdir(encounter_path)
    paths_to_explore = String[]

    #Gather directories
    for i in encounter_group_paths
        #debugprintln("$i is dir? $(isdir(string(encounter_path, "/", i)))\n")
        if(isdir(string(encounter_path, "/", i)) == true)
            push!(paths_to_explore, string(encounter_path, "/", i, "/"))
        end
    end

    case_dir = Dict{UTF8String, Any}()
    for i in paths_to_explore
        #print(i)
        dir_content = readdir(i)
        #Need to snip first
        for j in dir_content
            ##debugprintln("$j \n")
            if(j[end-3:end] == "json")
                case_id = j[1:13]
                aircraft_id = j[14:22]
                section_id = j[23:end-5]
                #debugprintln("$case_id -- $aircraft_id -- $section_id\n")
                data = JSON.parsefile(string(i,j))
                if (haskey(case_dir, case_id))
                    case_dir[case_id][section_id] = data
                else
                    case_dir[case_id] = Dict{String, Any}()
                    case_dir[case_id][section_id] = data
                end

            end
        end
    end
    LoggerTool.info(logger, "Replacing tests")
    return replace_malformed_json(case_dir)
end

function LoadEncounterGroup(encounter_path::String, id::Int)
    #string_id = parse(Char, id)

    encounter_group_paths = readdir(encounter_path)
    paths_to_explore = String[]

    #println(string_id)

    for i in encounter_group_paths
        if(isdir(string(encounter_path, "/", i)) == true && parse(Int, i[end-1]) == id)
            push!(paths_to_explore, string(encounter_path, "/", i, "/"))
        end
    end

    #println(paths_to_explore)

    case_dir = Dict{UTF8String, Any}()
    for i in paths_to_explore
        #print(i)
        dir_content = readdir(i)
        #Need to snip first
        for j in dir_content
            ##debugprintln("$j \n")
            if(j[end-3:end] == "json")
                case_id = j[1:13]
                aircraft_id = j[14:22]
                section_id = j[23:end-5]
                #debugprintln("$case_id -- $aircraft_id -- $section_id\n")
                data = JSON.parsefile(string(i,j))
                if (haskey(case_dir, case_id))
                    case_dir[case_id][section_id] = data
                else
                    case_dir[case_id] = Dict{String, Any}()
                    case_dir[case_id][section_id] = data
                end

            end
        end
    end
    LoggerTool.info(logger, "Replacing test group")
    return replace_malformed_json(case_dir)
end

function LoadSingleEncounter(encounter_path::String, id::Int)
    string_id = string(id)

    encounter_group_paths = readdir(encounter_path)
    paths_to_explore = String[]

    for i in encounter_group_paths
        #debugprintln("$i is dir? $(isdir(string(encounter_path, "/", i)))\n")
        #debugprintln(i[end-1:end])
        if(isdir(string(encounter_path, "/", i)) == true && i[end-1] == string_id[1])
            push!(paths_to_explore, string(encounter_path, "/", i, "/"))
        end
    end

    #debugprintln("Paths $paths_to_explore")

    case_dir = Dict{UTF8String, Any}()
    for i in paths_to_explore
        #print(i)
        dir_content = readdir(i)
        #Need to snip first
        for j in dir_content
            #println("str $j \n")
            if(j[end-3:end] == "json" && j[10:13] == string_id)
                case_id = j[1:13]
                aircraft_id = j[14:22]
                section_id = j[23:end-5]
                #debugprintln("$case_id -- $aircraft_id -- $section_id\n")
                data = JSON.parsefile(string(i,j))
                if (haskey(case_dir, case_id))
                    case_dir[case_id][section_id] = data
                else
                    case_dir[case_id] = Dict{String, Any}()
                    case_dir[case_id][section_id] = data
                end

            end
        end
    end
    LoggerTool.info(logger, "Replacing single test")
    return replace_malformed_json(case_dir)
end


