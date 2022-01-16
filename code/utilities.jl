"""
This file contains any utility functions used in more than one part of the simulator. It should be kept lean to avoid importing unnecessary functions
"""

function replace_malformed_json(d::Dict{UTF8String,Any})
    """
    Method to clean up the returned dictionary when parsing a JSON file. The parser handles lists, NaNs and Infs badly, leaving them as strings rather 
    than coercing them. This function tries to clean this up as much as possible, recusively.

    Parameters
    ----------
    d : Dict{UTF8String, Any}
        Dictionary object to be cleaned, typically a parsed JSON file.

    Returns
    -------
    d : Dict{UTF8String, Any}
        A cleaned version of the input dictionary
    """
    LoggerTool.info(logger, "UTF8String version!")
    k = keys(d)
    for x in k
        if isa(d[x], Dict{UTF8String,Any}) 
            d[x] = replace_malformed_json(d[x])
        elseif isa(d[x], Array) && length(d[x]) > 0
            if isa(d[x], Array{Any,1}) && isa(d[x][1], Array)
                #This apostrophe is vital... Otherwise the matrices are transposed
                d[x] = hcat(d[x]...)'
            end
            for i in 1:length(d[x])
                if isa(d[x][i], Dict{UTF8String,Any})
                    replace_malformed_json(d[x][i])
                elseif d[x][i] == "_Inf_"
                    d[x][i] = Inf
                elseif d[x][i] == "-_Inf_" || d[x][i] == "-Inf_"
                    d[x][i] = -Inf
                elseif d[x][i] == "_NaN_"
                    d[x][i] = NaN
                end
            end
        else
            if d[x] == "_Inf_"
                d[x] = Inf
            elseif d[x] == "-_Inf_"
                d[x] = -Inf
            elseif d[x] == "_NaN_"
                d[x] = NaN
            end
            
        end
    end
    return d
end