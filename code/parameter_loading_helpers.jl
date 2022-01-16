"""
This file contains a range of helper functions used to load the DO-385 parameters and DAT files. 
"""
import JSON

# function #debugprintln(str::String)
#     if isdefined(:DEBUG_ACAS)
#         println(str)
#     end
# end


function load_params(parameter_directory::String, filename::String)
    """
    Takes the directory containing the parameters and data files and 
    loads all of them, handling any value replacements which need to be done
    
    Parameters
    ----------
        PARAMS_DIR - String
            Directory containing all the parameter and data files
        filename - String
            Filename of the DO_385 parameters file to load.
    """

    LoggerTool.info(logger, "Loading Params...")
    params = JSON.parsefile(string(parameter_directory, filename))
    params = replace_malformed_json(params)

    params["modes"][1]["state_estimation"]["tau"]["entry_dist"]["vertical_table_content"] = read_dat_file(
        string(
            parameter_directory, 
            params["modes"][1]["state_estimation"]["tau"]["entry_dist"]["vertical_table"]
        )
    )

    params["modes"][1]["state_estimation"]["tau"]["entry_dist"]["horizontal_table_content"] = read_dat_file(
        string(
            parameter_directory, 
            params["modes"][1]["state_estimation"]["tau"]["entry_dist"]["horizontal_table"]
        )
    )

    params["modes"][1]["state_estimation"]["tau"]["entry_dist"]["horizontal_active_table_content"] = read_dat_file(
        string(
            parameter_directory, 
            params["modes"][1]["state_estimation"]["tau"]["entry_dist"]["horizontal_active_table"]
        )
    )

    params["modes"][1]["cost_estimation"]["offline"]["origami"]["equiv_class_table_content"] = read_cost_dat_file(
        string(
            parameter_directory, 
            params["modes"][1]["cost_estimation"]["offline"]["origami"]["equiv_class_table"]
        )
    )

    params["modes"][1]["cost_estimation"]["offline"]["origami"]["minblocks_table_content"] = read_minblocks_dat_file(
        string(
            parameter_directory, 
            params["modes"][1]["cost_estimation"]["offline"]["origami"]["minblocks_table"]
        )
    )

    params["modes"][2]["state_estimation"]["tau"]["entry_dist"]["vertical_table_content"] = read_dat_file(
        string(
            parameter_directory, 
            params["modes"][2]["state_estimation"]["tau"]["entry_dist"]["vertical_table"]
        )
    )

    params["modes"][2]["state_estimation"]["tau"]["entry_dist"]["horizontal_table_content"] = read_dat_file(
        string(
            parameter_directory, 
            params["modes"][2]["state_estimation"]["tau"]["entry_dist"]["horizontal_table"]
        )
    )

    params["modes"][2]["state_estimation"]["tau"]["entry_dist"]["horizontal_active_table_content"] = read_dat_file(
        string(
            parameter_directory, 
            params["modes"][2]["state_estimation"]["tau"]["entry_dist"]["horizontal_active_table"]
        )
    )

    
    #params["modes"][2]["cost_estimation"]["offline"]["origami"]["equiv_class_table_content"] = read_cost_dat_file(params["modes"][2]["cost_estimation"]["offline"]["origami"]["equiv_class_table"])
    params["modes"][2]["cost_estimation"]["offline"]["origami"]["equiv_class_table_content"] = deepcopy(params["modes"][1]["cost_estimation"]["offline"]["origami"]["equiv_class_table_content"])

    #params["modes"][2]["cost_estimation"]["offline"]["origami"]["minblocks_table_content"] = read_minblocks_dat_file(params["modes"][2]["cost_estimation"]["offline"]["origami"]["minblocks_table"])
    params["modes"][2]["cost_estimation"]["offline"]["origami"]["minblocks_table_content"] = deepcopy(params["modes"][1]["cost_estimation"]["offline"]["origami"]["minblocks_table_content"])

    return params
end



function bytes2string(input::Array{Uint8,1})
    """
    Helper function converting bytes to a string object
    """
    output_string = string()

    for i in input
        output_string = string(output_string,char(i))
    end
    return output_string
end

function uint32bytes2int(input::Array{Uint8,1})
    """
    Helper function for unpacking DO-385 data file uint32 to integer fields
    """
    return int64(reinterpret(Uint32, input)[1])
end

function uint32bytes2uint32(input::Array{Uint8,1})
    """
    Helper function for unpacking DO-385 data file unint32 to uint32 fields
    """
    return reinterpret(Uint32, input)[1]
end

function uint8bytes2int(input::Uint8)
    """
    Helper function for unpacking DO-385 data file uint8 to integer fields
    """
    return int64(reinterpret(Uint8, input)[1])
end

function uint8bytes2uint8(input::Uint8)
    """
    Helper function for unpacking DO-385 data file uint8 to uint8 fields
    """
    return reinterpret(Uint8, input)[1]
end

function bytes2float16(input::Array{Uint8,1})
    """
    Helper function for unpacking DO-385 data file bytes to float16 fields
    """
    #Put two bytes in in the right order
    #println(input)
    return reinterpret(Float16,input)[1]
end

function bytes2float64(input::Array{Uint8,1})
    """
    Helper function for unpacking DO-385 data file bytes to float64 fields
    """
    #Put eight bytes in in the right order
    #println(input)
    return reinterpret(Float64,input)[1]
end


function read_dat_file(file_name::String)
    """
    Loads the data file stored at file_name, unpacking it from the 
    custom packing used by the DO-385 standard
    
    Parameters
    ----------
        file_name : String
            Filename of the DO_385 data file to load.

    Returns
    -------
        RDataTable
            Table containing extracted data from dat file.
    """
    UINT32_SIZE = 4
    UINT8_SIZE = 1
    FLOAT16_SIZE = 2
    FLOAT64_SIZE = 8

    file_handle = open(file_name)
    data_blob = readbytes(file_handle)
    
    close(file_handle)

    offset = 1

    index_data = nothing
    main_data = nothing
    dimension_count = -1
    cut_counts = nothing
    names = nothing
    cuts = nothing

    file_type_len = -1
    file_type = ""

    auxiliary_data_size = -1


    #Check magic magic_number
    magic_number = uint32bytes2int(data_blob[1:4])
    offset = offset + UINT32_SIZE

    LoggerTool.info(logger, "Loading $(file_name)")

    # Check if it's the stated magic number
    if magic_number == 1634
        #debugprintln("Magic number check passed for $file_name")

        file_type_len = uint8bytes2int(data_blob[offset])

        offset = offset + UINT8_SIZE
        file_type = bytes2string(data_blob[offset:offset+file_type_len-1])

        offset = offset + file_type_len
        #debugprintln("File type: $file_type")

        auxiliary_data_size = uint32bytes2int(data_blob[offset:offset+3])
        offset = offset + UINT32_SIZE

        #debugprintln("Aux offset at $offset")

        #debugprintln("Auxiliary data size: $auxiliary_data_size")

        auxiliary_data = data_blob[offset:offset+auxiliary_data_size-1]
        offset = offset + auxiliary_data_size

        # AUX Data
        aux_offset = 1
        dimension_count = uint32bytes2int(auxiliary_data[aux_offset:aux_offset+3])
        aux_offset = aux_offset + UINT32_SIZE

        #debugprintln("Aux -- dimension_count: $dimension_count")

        cut_counts = Array(Int64,0)
        for i in 1:dimension_count
            push!(cut_counts, uint32bytes2int(auxiliary_data[aux_offset:aux_offset+3]))
            aux_offset = aux_offset + UINT32_SIZE
        end
        #debugprintln("Aux -- cut counts: $cut_counts total $(sum(cut_counts))")

        names = Array(String, 0)
        for i in 1:dimension_count
            dim_name_len = uint8bytes2int(auxiliary_data[aux_offset])
            aux_offset = aux_offset + UINT8_SIZE

            dim_name = bytes2string(auxiliary_data[aux_offset:aux_offset+dim_name_len-1])
            aux_offset = aux_offset + dim_name_len

            push!(names, dim_name)
        end

        cuts = Array(Float64,0)
        for i in aux_offset:FLOAT64_SIZE:auxiliary_data_size-FLOAT64_SIZE+1
            push!(cuts, bytes2float64(auxiliary_data[i:i+7]))
        end
        #debugprintln("Aux -- dim names $names")

        #debugprintln("Aux -- num cuts $(length(cuts))")

        #debugprintln("Aux offset $aux_offset")


        # END AUX Data

        index_type_len = uint8bytes2int(data_blob[offset])
        offset = offset + UINT8_SIZE

        index_type = bytes2string(data_blob[offset:offset+index_type_len-1])
        offset = offset + index_type_len
        
        #debugprintln("Index type: $index_type")
    
        data_type_len = uint8bytes2int(data_blob[offset])
        offset = offset + UINT8_SIZE

        data_type = bytes2string(data_blob[offset:offset+data_type_len-1])
        offset = offset + data_type_len

        #debugprintln("Data type: $data_type")

        count_included = -1
        if file_type == "varblockdictionary"
            count_included = uint8bytes2int(data_blob[offset])
        end
        offset = offset + UINT8_SIZE

        maximum_block_elements = uint8bytes2int(data_blob[offset])
        offset = offset + UINT8_SIZE

        #debugprintln("Maximum block elements: $maximum_block_elements")

        index_element_count = uint32bytes2int(data_blob[offset:offset+3])
        offset = offset + UINT32_SIZE

        #debugprintln("Index element count: $index_element_count")

        data_element_count = uint32bytes2int(data_blob[offset:offset+3])
        offset = offset + UINT32_SIZE

        #debugprintln("Data element count: $data_element_count")

        #debugprintln("Offset $offset")

        if index_element_count > 0
            type_len_multiplier = 1
            if index_type == "uint8"
                type_len_multiplier = 1
                index_data = Array(Uint8, 0)
            elseif index_type == "uint32"
                type_len_multiplier = 4
                index_data = Array(Uint32, 0)
            elseif index_type == "half"
                type_len_multiplier = 2
                index_data = Array(Float16, 0)
            elseif index_type == "double"
                type_len_multiplier = 8
                index_data = Array(Float64, 0)
            end
            
            index_data_len = type_len_multiplier * index_element_count

            index_data_blob = data_blob[offset:offset+index_data_len-1]

            #debugprintln("Index data: $(length(index_data_blob))")
            if index_type == "uint8"
                index_data = reinterpret(Uint8, index_data_blob)
            elseif index_type == "uint32"
                index_data = reinterpret(Uint32, index_data_blob)
            elseif index_type == "half"
                index_data = reinterpret(Float16, index_data_blob)
            elseif index_type == "double"
                index_data = reinterpret(Float64, index_data_blob)
            end
            offset = offset + index_data_len
        end

        #debugprintln("Offset $offset")

        if data_element_count > 0
            type_len_multiplier = 1
            if data_type == "uint8"
                type_len_multiplier = 1
                main_data = Array(Uint8, 0)
            elseif data_type == "uint32"
                type_len_multiplier = 4
                main_data = Array(Uint32, 0)
            elseif data_type == "half"
                type_len_multiplier = 2
                main_data = Array(Float16, 0)
            elseif data_type == "double"
                type_len_multiplier = 8
                main_data = Array(Float64, 0)
            end
            
            main_data_len = type_len_multiplier * data_element_count

            #debugprintln("Offset at $offset $main_data_len $(offset+main_data_len-1)")

            main_data_blob = data_blob[offset:offset+main_data_len-1]

            #debugprintln("Data data: $(length(main_data_blob))")
            if data_type == "uint8"
                main_data = reinterpret(Uint8, main_data_blob)
            elseif data_type == "uint32"
                main_data = reinterpret(Uint32, main_data_blob)
            elseif data_type == "half"
                main_data = reinterpret(Float16, main_data_blob)
            elseif data_type == "double"
                main_data = reinterpret(Float64, main_data_blob)
            end
            offset = offset + main_data_len
        
        end

        #debugprintln("Offset $offset")

    else
        error("Magic Number check failed for $file_name")
    end

    if index_data == nothing
        index_data = Array(Uint32,0)
    end

    return RDataTable(names, cut_counts, cuts, index_data, main_data)

end

function read_minblocks_dat_file(file_name::String)
    """
    Loads the minblocks dat file stored at file_name, unpacking it from the 
    custom packing used by the DO-385 standard. This is similar to the others
    but has a slightly different packing.

    Parameters
    ----------
        file_name : String
            Filename of the DO_385 data file to load.

    Returns
    -------
        RDataTable
            Table containing extracted data from dat file.
    """

    UINT32_SIZE = 4
    UINT8_SIZE = 1
    FLOAT16_SIZE = 2
    FLOAT64_SIZE = 8

    file_handle = open(file_name)
    data_blob = readbytes(file_handle)
    close(file_handle)

    offset = 1

    index_data = nothing
    main_data = nothing
    dimension_count = -1
    cut_counts = nothing
    names = nothing
    cuts = nothing

    file_type_len = -1
    file_type = ""

    auxiliary_data_size = -1


    #Check magic magic_number
    #magic_number_bytes = reverse(data_blob[1:4])
    #magic_number = parseint(bytes2hex(magic_number_bytes), 16)
    magic_number = uint32bytes2int(data_blob[1:4])
    offset = offset + UINT32_SIZE

    LoggerTool.info(logger, "Loading $(file_name)")

    #debugprintln("Data size $(length(data_blob))")

    if magic_number == 1634
        #debugprintln("Magic number check passed for $file_name")

        file_type_len = uint8bytes2int(data_blob[offset])

        offset = offset + UINT8_SIZE
        file_type = bytes2string(data_blob[offset:offset+file_type_len-1])

        offset = offset + file_type_len
        #debugprintln("File type: $file_type")

        auxiliary_data_size = uint32bytes2int(data_blob[offset:offset+3])
        offset = offset + UINT32_SIZE

        #debugprintln("Auxiliary data size: $auxiliary_data_size")

        auxiliary_data = data_blob[offset:offset+auxiliary_data_size-1]
        offset = offset + auxiliary_data_size

        # AUX Data

        ## THis is off by two somewhere

        aux_offset = 1
        dimension_count = uint32bytes2int(auxiliary_data[aux_offset:aux_offset+3])
        aux_offset = aux_offset + UINT32_SIZE

        #debugprintln("Aux -- dimension_count: $dimension_count")

        cut_counts = Array(Int64,0)
        for i in 1:dimension_count
            push!(cut_counts, uint32bytes2int(auxiliary_data[aux_offset:aux_offset+3]))
            aux_offset = aux_offset + UINT32_SIZE
        end
        #debugprintln("Aux -- cut counts: $cut_counts total $(sum(cut_counts))")

        names = Array(String, 0)
        for i in 1:dimension_count
            dim_name_len = uint8bytes2int(auxiliary_data[aux_offset])
            aux_offset = aux_offset + UINT8_SIZE

            dim_name = bytes2string(auxiliary_data[aux_offset:aux_offset+dim_name_len-1])
            aux_offset = aux_offset + dim_name_len

            push!(names, dim_name)
        end

        cuts = Array(Float64,0)
        for i in aux_offset:FLOAT64_SIZE:auxiliary_data_size-FLOAT64_SIZE+1
            push!(cuts, bytes2float64(auxiliary_data[i:i+7]))
        end
        #debugprintln("Aux -- dim names $names")

        #debugprintln("Aux -- num cuts $(length(cuts))")

        #debugprintln("Aux offset $aux_offset")


        # END AUX Data

        index_type_len = uint8bytes2int(data_blob[offset])
        offset = offset + UINT8_SIZE

        index_type = bytes2string(data_blob[offset:offset+index_type_len-1])
        offset = offset + index_type_len
        
        #debugprintln("Index type: $index_type")
    
        data_type_len = uint8bytes2int(data_blob[offset])
        offset = offset + UINT8_SIZE

        data_type = bytes2string(data_blob[offset:offset+data_type_len-1])
        offset = offset + data_type_len

        #debugprintln("Data type: $data_type")

        count_included = -1
        if file_type == "varblockdictionary"
            count_included = uint8bytes2int(data_blob[offset])
        end
        offset = offset + UINT8_SIZE

        maximum_block_elements = uint8bytes2int(data_blob[offset])
        offset = offset + UINT8_SIZE

        #debugprintln("Maximum block elements: $maximum_block_elements")

        index_element_count = uint32bytes2int(data_blob[offset:offset+3])
        offset = offset + UINT32_SIZE

        #debugprintln("Index element count: $index_element_count")

        data_element_count = uint32bytes2int(data_blob[offset:offset+3])
        offset = offset + UINT32_SIZE

        #debugprintln("Data element count: $data_element_count")

        #debugprintln("Offset $offset")

        if index_element_count > 0
            type_len_multiplier = 1
            if index_type == "uint8"
                type_len_multiplier = 1
                index_data = Array(Uint8, 0)
            elseif index_type == "uint32"
                type_len_multiplier = 4
                index_data = Array(Uint32, 0)
            elseif index_type == "half"
                type_len_multiplier = 2
                index_data = Array(Float16, 0)
            elseif index_type == "double"
                type_len_multiplier = 8
                index_data = Array(Float64, 0)
            end
            
            index_data_len = type_len_multiplier * index_element_count

            index_data_blob = data_blob[offset:offset+index_data_len-1]

            #debugprintln("Index data: $(length(index_data_blob))")

            if index_type == "uint8"
                index_data = reinterpret(Uint8, index_data_blob)
            elseif index_type == "uint32"
                index_data = reinterpret(Uint32, index_data_blob)
            elseif index_type == "half"
                index_data = reinterpret(Float16, index_data_blob)
            elseif index_type == "double"
                index_data = reinterpret(Float64, index_data_blob)
            end

            offset = offset + index_data_len
        end


        #debugprintln("Pre-data Offset $offset")

        if data_element_count > 0
            type_len_multiplier = 1
            if data_type == "uint8"
                type_len_multiplier = 1
                main_data = Array(Uint8, 0)
            elseif data_type == "uint32"
                type_len_multiplier = 4
                main_data = Array(Uint32, 0)
            elseif data_type == "half"
                type_len_multiplier = 2
                main_data = Array(Float16, 0)
            elseif data_type == "double"
                type_len_multiplier = 8
                main_data = Array(Float64, 0)
            end
            
            main_data_len = type_len_multiplier * data_element_count

            #debugprintln("Offset at $offset $main_data_len $(offset+main_data_len-1)")

            main_data_blob = data_blob[offset:offset+main_data_len-1]

            #debugprintln("Data data: $(length(main_data_blob))")
            if data_type == "uint8"
                main_data = reinterpret(Uint8, main_data_blob)
            elseif data_type == "uint32"
                main_data = reinterpret(Uint32, main_data_blob)
            elseif data_type == "half"
                main_data = reinterpret(Float16, main_data_blob)
            elseif data_type == "double"
                main_data = reinterpret(Float64, main_data_blob)
            end

            offset = offset + main_data_len

            if length(main_data) == data_element_count
                #debugprintln("CORRECT")
            else
                #debugprintln("INCORRECT $(length(main_data)) $main_data_len")

            end
        end

        #debugprintln("Offset $offset")

    else
        error("Magic Number check failed for $file_name")
    end

    if index_data == nothing
        index_data = Array(Uint32,0)
    end

    return RDataTable(names, cut_counts, cuts, index_data, main_data)

end

function read_cost_dat_file(file_name::String)
    """
    Loads the cost dat file stored at file_name, unpacking it from the 
    custom packing used by the DO-385 standard. This is similar to the others
    but has a slightly different packing.

    Parameters
    ----------
        file_name : String
            Filename of the DO_385 data file to load.

    Returns
    -------
        tables : RDataTable[]
            A list of tables containing extracted data from dat file.
    """
    UINT32_SIZE = 4
    UINT8_SIZE = 1
    FLOAT16_SIZE = 2
    FLOAT64_SIZE = 8

    file_handle = open(file_name)
    data_blob = readbytes(file_handle)
    close(file_handle)

    offset = 1

    index_data = nothing
    main_data = nothing
    dimension_count = -1
    cut_counts = nothing
    names = nothing
    cuts = nothing

    file_type_len = -1
    file_type = ""

    auxiliary_data_size = -1

    tables = RDataTable[]
    #Check magic magic_number
    #magic_number_bytes = reverse(data_blob[1:4])
    #magic_number = parseint(bytes2hex(magic_number_bytes), 16)

    while length(data_blob) > 0
        offset = 1
        magic_number = uint32bytes2int(data_blob[1:4])
        offset = offset + UINT32_SIZE

        println("Loading $(file_name)")

        if magic_number == 1634
            #debugprintln("Magic number check passed for $file_name")

            file_type_len = uint8bytes2int(data_blob[offset])

            offset = offset + UINT8_SIZE
            file_type = bytes2string(data_blob[offset:offset+file_type_len-1])

            offset = offset + file_type_len
            #debugprintln("File type: $file_type")

            auxiliary_data_size = uint32bytes2int(data_blob[offset:offset+3])
            offset = offset + UINT32_SIZE

            #debugprintln("Auxiliary data size: $auxiliary_data_size")

            auxiliary_data = data_blob[offset:offset+auxiliary_data_size-1]
            offset = offset + auxiliary_data_size

            # AUX Data

            ## THis is off by two somewhere

            aux_offset = 1
            dimension_count = uint32bytes2int(auxiliary_data[aux_offset:aux_offset+3])
            aux_offset = aux_offset + UINT32_SIZE

            #debugprintln("Aux -- dimension_count: $dimension_count")

            cut_counts = Array(Int64,0)
            for i in 1:dimension_count
                push!(cut_counts, uint32bytes2int(auxiliary_data[aux_offset:aux_offset+3]))
                aux_offset = aux_offset + UINT32_SIZE
            end
            #debugprintln("Aux -- cut counts: $cut_counts total $(sum(cut_counts))")

            names = Array(String, 0)
            for i in 1:dimension_count
                dim_name_len = uint8bytes2int(auxiliary_data[aux_offset])
                aux_offset = aux_offset + UINT8_SIZE

                dim_name = bytes2string(auxiliary_data[aux_offset:aux_offset+dim_name_len-1])
                aux_offset = aux_offset + dim_name_len

                push!(names, dim_name)
            end

            cuts = Array(Float64,0)
            for i in aux_offset:FLOAT64_SIZE:auxiliary_data_size-FLOAT64_SIZE+1
                push!(cuts, bytes2float64(auxiliary_data[i:i+7]))
            end
            #debugprintln("Aux -- dim names $names")

            #debugprintln("Aux -- num cuts $(length(cuts))")

            #debugprintln("Aux offset $aux_offset")


            # END AUX Data

            index_type_len = uint8bytes2int(data_blob[offset])
            offset = offset + UINT8_SIZE

            index_type = bytes2string(data_blob[offset:offset+index_type_len-1])
            offset = offset + index_type_len
            
            #debugprintln("Index type: $index_type")
        
            data_type_len = uint8bytes2int(data_blob[offset])
            offset = offset + UINT8_SIZE

            data_type = bytes2string(data_blob[offset:offset+data_type_len-1])
            offset = offset + data_type_len

            #debugprintln("Data type: $data_type")

            count_included = -1
            if file_type == "varblockdictionary"
                count_included = uint8bytes2int(data_blob[offset])
            end
            offset = offset + UINT8_SIZE

            maximum_block_elements = uint8bytes2int(data_blob[offset])
            offset = offset + UINT8_SIZE

            #debugprintln("Maximum block elements: $maximum_block_elements")

            index_element_count = uint32bytes2int(data_blob[offset:offset+3])
            offset = offset + UINT32_SIZE

            #debugprintln("Index element count: $index_element_count")

            data_element_count = uint32bytes2int(data_blob[offset:offset+3])
            offset = offset + UINT32_SIZE

            #debugprintln("Data element count: $data_element_count")

            #debugprintln("Offset $offset")

            if index_element_count > 0
                type_len_multiplier = 1
                if index_type == "uint8"
                    type_len_multiplier = 1
                    index_data = Array(Uint8, 0)
                elseif index_type == "uint32"
                    type_len_multiplier = 4
                    index_data = Array(Uint32, 0)
                elseif index_type == "half"
                    type_len_multiplier = 2
                    index_data = Array(Float16, 0)
                elseif index_type == "double"
                    type_len_multiplier = 8
                    index_data = Array(Float64, 0)
                end
                
                index_data_len = type_len_multiplier * index_element_count

                index_data_blob = data_blob[offset:offset+index_data_len-1]

                #debugprintln("Index data: $(length(index_data_blob))")
                if index_type == "uint8"
                    index_data = reinterpret(Uint8, index_data_blob)
                elseif index_type == "uint32"
                    index_data = reinterpret(Uint32, index_data_blob)
                elseif index_type == "half"
                    index_data = reinterpret(Float16, index_data_blob)
                elseif index_type == "double"
                    index_data = reinterpret(Float64, index_data_blob)
                end
                offset = offset + index_data_len
            end

            #debugprintln("Offset $offset")

            if data_element_count > 0
                type_len_multiplier = 1
                if data_type == "uint8"
                    type_len_multiplier = 1
                    main_data = Array(Uint8, 0)
                elseif data_type == "uint32"
                    type_len_multiplier = 4
                    main_data = Array(Uint32, 0)
                elseif data_type == "half"
                    type_len_multiplier = 2
                    main_data = Array(Float16, 0)
                elseif data_type == "double"
                    type_len_multiplier = 8
                    main_data = Array(Float64, 0)
                end
                
                main_data_len = type_len_multiplier * data_element_count

                #debugprintln("Offset at $offset $main_data_len $(offset+main_data_len-1)")

                main_data_blob = data_blob[offset:offset+main_data_len-1]

                #debugprintln("Data data: $(length(main_data_blob))")
                if data_type == "uint8"
                    main_data = reinterpret(Uint8, main_data_blob)
                elseif data_type == "uint32"
                    main_data = reinterpret(Uint32, main_data_blob)
                elseif data_type == "half"
                    main_data = reinterpret(Float16, main_data_blob)
                elseif data_type == "double"
                    main_data = reinterpret(Float64, main_data_blob)
                end
                offset = offset + main_data_len
            
            end

            #debugprintln("Offset $offset")

        else
            error("Magic Number check failed for $file_name")
        end

        if index_data == nothing
            index_data = Array(Uint32,0)
        end

        #Get rid of this bit of the blob
        data_blob = data_blob[offset:end]
        push!(tables, RDataTable(names, cut_counts, cuts, index_data, main_data))
    end


    return tables
end