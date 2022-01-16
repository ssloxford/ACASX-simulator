"""
experiment_datastructs.jl

Data structures used in the experimental code
"""
type AttackerIntent
    """
    Structure to describe an attacker's intended trajectory over the course of the simulation. Used in the old-style simulations with a 'defined' target, i.e. flying some arbitrary trajectory
    """
    mode_s::Uint32
    start_flat_dist::R
    last_flat_dist::R
    start_chi_rel::R
    last_chi_rel::R
    start_baro_alt::R
    last_baro_alt::R
    quant_ft::R
    ri::R
    surv_mode::Int16
    simulation_steps::Int16
    AttackerIntent(mode_s, 
                    start_flat_dist, 
                    last_flat_dist, 
                    start_chi_rel,
                    last_chi_rel,
                    start_baro_alt,
                    last_baro_alt,
                    quant_ft,
                    ri,
                    surv_mode,
                    simulation_steps) = new(
                    mode_s, 
                    start_flat_dist, 
                    last_flat_dist, 
                    start_chi_rel,
                    last_chi_rel,
                    start_baro_alt,
                    last_baro_alt,
                    quant_ft,
                    ri,
                    surv_mode,
                    simulation_steps
                )
end

type OpenskyAttackerIntent
    """
    Structure to describe an attacker's intention over a target trajectory taken from OpenSky. Used in all the implemented modes of the simulator.
    """
    mode_s::Uint32
    start_baro_alt::R
    last_baro_alt::R
    quant_ft::R
    ri::R
    surv_mode::Int16
    simulation_steps::Int16
    mode::Int16
    rate::Float32
    OpenskyAttackerIntent(mode_s, 
                    start_baro_alt,
                    last_baro_alt,
                    quant_ft,
                    ri,
                    surv_mode,
                    simulation_steps,
                    mode,
                    rate) = new(
                    mode_s, 
                    start_baro_alt,
                    last_baro_alt,
                    quant_ft,
                    ri,
                    surv_mode,
                    simulation_steps,
                    mode,
                    rate
                )
end
