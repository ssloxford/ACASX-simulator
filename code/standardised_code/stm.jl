"""
HERE BE DRAGONS! 

Surveillance and Tracking Module - implements STM functionality.

We have just left includes in place, as the rest of the code is copyrighted under DO-385
"""

Base.delete!(db::Database, k) = Base.delete!(db.dictionary, k)
Base.get(db::Database, k, default) = Base.get(db.dictionary, k, default)
Base.getindex(db::Database, k) = Base.getindex(db.dictionary, k)
Base.haskey(db::Database, k) = Base.haskey(db.dictionary, k)
Base.keys(db::Database) = Base.sort(Base.collect(Base.keys(db.dictionary)))
Base.setindex!(db::Database, v, k) = Base.setindex!(db.dictionary, v, k)

own = OwnShipData()

#Have to instatiate with a key then delete as the standard code doesn't provide a constructor for
#an empty database
target_db = Database{Uint32,Target}(uint32(0))

hyp_track_db = Database{Uint32,HypotheticalModeCTrackFile}(uint32(0))

modecIntervals = ModeCIntervals()

geoutils = GeoUtils()
