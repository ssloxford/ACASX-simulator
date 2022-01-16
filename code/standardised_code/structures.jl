"""
HERE BE DRAGONS! 

Structures - data structures used across the standardised codebase

We have just left includes in place, as the rest of the code is copyrighted under DO-385
"""

include("global_constants.jl")

import Base.delete!, Base.get, Base.getindex, Base.haskey, Base.keys, Base.setindex!

const Z = Int64
const R = Float64
const paramsfile_type = Dict{UTF8String,Any}

abstract TrackFile
abstract TID
