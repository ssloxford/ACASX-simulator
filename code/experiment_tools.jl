"""
experiment_tools.jl

A range of tools used to assist in running attack simulation experiments. Most tools relate to generating messages based on attacker and ownship positions. 
"""

import JSON

function next_heading_from_opensky(current_timestep, os_entry)
    """
    Given data at a given time point from OpenSky, create the input structure for the simulator.

    Parameters
    ----------
    current_timestep : float
        Current simulator timestep (arbitrary, starts from 0)
    os_entry : Dict
        Dictionary containing data from an OpenSky time point

    Returns
    -------
    output_struct : Dict
        Dictionary containing a heading update, in the correct format for the DO-385 code
    """
    output_struct = {
        "report_time" => current_timestep + 0.0001,
        "report_type" => "Acas_XaXo_DO385",
        "acas_xaxo_do385" => {
            "data_type" => "HEADING_OBS", 
            "heading_obs" => {
                "toa"=> current_timestep + 0.0001,
                "heading_true_rad" => deg2rad(os_entry["heading"]),
                "heading_degraded" => false
            }
        }
    }
    return output_struct
end


function next_altitude_from_opensky(current_timestep, os_entry, trm_report, own_status, offset)
    """
    Generate next heading structure from Opensky trajectory

    Parameters
    ----------
    current_timestep : float
        Current simulation timestep
    os_entry : Dict
        Opensky trajectory entry for current iteration
    trm_report : TRMReport
        Ownship TRM Report from previous iteration
    own_status : OwnshipData
        Ownship status from previous iteration
    offset : float
        Distance between ownship Opensky trajectory and simulation trajectory, caused by responding to an alarm
    
    Returns
    -------
    output_struct : Dict
        Dictionary containing a altitude update, in the correct format for the DO-385 code
    """

    #By default, we want to add any accrued offset to the reported OS altitude
    alt = os_entry["baroaltitude"] * 3.281 + offset

    # Only handles one intruder for now!
    if length(trm_report.designation.intruder) > 0
        if trm_report.designation.intruder[1].active_ra == true
            new_alt = own_status.history.baroalt.value[length(own_status.history.baroalt.value)] + trm_report.display.target_rate

            # However we now need to update the offset by calculating
            # overall difference between the new altitude and the old one. 
            # The old one has already accounted existing offset so we don't need to do anything there.
            offset = new_alt - alt
            alt = new_alt
        end
    end

    output_struct = {
        "report_time" => current_timestep + 0.0001,
        "report_type" => "Acas_XaXo_DO385",
        "acas_xaxo_do385" => {
            "data_type" => "BARO_ALT_OBS", 
            "baro_alt_obs" => {
                "toa"=> current_timestep + 0.0001,
                #Need to convert to feet
                "baro_alt_ft" => alt
            }
        }
    }
    return output_struct, offset
end


function next_wgs84_from_opensky(current_timestep, os_entry)
    """
    Generates next WGS84 return from Opensky data
    
    Parameters
    ----------
    current_timestep : Float
        Current simulation timestep
    os_entry : Opensky Trajectory Step
        Opensky trajectory step for this iteration

    Returns
    -------
    output_struct : Dict
        Dictionary containing a WGS84 update, in the correct format for the DO-385 code
    """
    
    #Need to decompose EW/vel_ns_kts
    head = os_entry["heading"]
    #Convert m/s to kts
    vel = os_entry["velocity"] * 1.944
    ns = 0
    ew = 0
    #println("Head $(head) vel $(vel)")

    #Decompose speeds based on which quadrant it is in
    if head <= 90
        ns = vel * cosd(head)
        ew = vel * sind(head)
    elseif head <= 180
        tmp_head = head - 90
        ns = -(vel * sind(tmp_head))
        ew = vel * cosd(tmp_head)
    elseif head <= 270
        tmp_head = head - 180
        ns = -(vel * cosd(tmp_head))
        ew = -(vel * sind(tmp_head))
    else
        tmp_head = head - 360
        ns = vel * sind(tmp_head)
        ew = -(vel * cosd(tmp_head))
    end

    # Generate output structure
    output_struct = {
        "report_time" => current_timestep + 0.0001,
        "report_type" => "Acas_XaXo_DO385",
        "acas_xaxo_do385" => {
            "data_type" => "WGS84_OBS", 
            "wgs84_obs" => {
                "toa"=> current_timestep + 0.0001,
                #Need to convert to feet
                "lat_deg"=> os_entry["lat"], 
                "lon_deg"=> os_entry["lon"], 
                "vel_ew_kts"=> ew, 
                "vel_ns_kts"=> ns
            }
        }
    }
    return output_struct
end

function next_ownship_discretes(current_timestep, discretes)
    """
    Generates next ownship discretes structure
    
    Parameters
    ----------
    current_timestep : float
        Current simulation timestep
    discretes : OwnshipDiscretes
        Populated ownship discretes structure

    Returns
    -------
    output_struct : Dict
        Dictionary containing an ownship discretes update, in the correct format for the DO-385 code
    """
    output_struct = {
        "report_time" => current_timestep + 0.0001,
        "report_type" => "Acas_XaXo_DO385",
        "acas_xaxo_do385" => {
            "data_type" => "OWNSHIP_DISCRETES",
            "ownship_discretes" => {
                "toa"=> current_timestep + 0.0001, 
                "address"=> discretes.mode_s, 
                "mode_a"=> discretes.modeACode, 
                "opflg"=> discretes.opflg, 
                "manual_SL"=> discretes.manualSL, 
                "own_ground_display_mode_on"=> discretes.own_ground_display_mode_on, 
                "on_surface"=> discretes.on_surface, 
                "aoto_on"=> discretes.aoto_on, 
                "is_coarsely_quant"=> discretes.is_coarsely_quant
            }
        }
    }

    return output_struct
end

function generate_next_attacker_df0_opensky(current_timestep, own_data, attacker_lat, attacker_lon, attacker_alt, radius, own_status, intent, sim_steps)
    """
    Generates next DF0 message for an attacker targetting
    an aircraft from an Opensky trajectory. Calculates using
    Haversine distance.
    
    Parameters
    ----------
        current_timestamp : Float
            current simulation timestep
        own_data : Opensky Trajectory
            data for current point in target aircraft trajectory from Opensky
        attacker_lat : Float
            attacker latitude (real)
        attacker_lon : Float
            attacker longitude (real)
        attacker_alt : Float
            (falsified) altitude of the attacker at the point of attack 
        radius : Float
            radius of the Earth
        own_status : OwnshipData
            Ownship data from the previous iteration 
        intent : AttackerIntent
            intent data for the attacker
        sim_steps : Int
            Number of steps in the run
    
    Returns
    -------
    df0_struct : Dict
        Dictionary describing the next DF0 input, in the correct format for the DO-385 code
    """

    # Get the current iteration of the simulation from the timestamp
    current_iter = floor(current_timestep)

    #println(own_status.history.baroalt.value)
    baro_alt = 0

    if intent.mode == 0
        # Get the per-step change in barometric altitude based on the length of simulation
        baro_alt_delta = ((intent.last_baro_alt - intent.start_baro_alt)/sim_steps)
        
        # Calculate next barometric altitude 
        # plus 0.02 adds jitter, stops slant trig going mad as the attacker crosses the target aircraft

        #here, check mode - if 0 then do the existing calc, if 1 then use rate (so start + steps*rate)
        baro_alt = intent.start_baro_alt + (baro_alt_delta*floor(current_timestep)) + 0.02
    elseif intent.mode == 1
        baro_alt = intent.start_baro_alt + (intent.rate * current_timestep)
    elseif intent.mode == 2
        baro_alt = intent.start_baro_alt + (intent.rate * current_timestep)
        if ((intent.rate < 0) && (baro_alt < intent.last_baro_alt)) || ((intent.rate > 0) && (baro_alt > intent.last_baro_alt))
            baro_alt = intent.last_baro_alt
        end
    elseif intent.mode == 3 
        #I think this is right - need to check!
        #Should be able to just base it on the start altitude because we can pre-calc it
        baro_alt = intent.start_baro_alt + (intent.rate * current_timestep)
    end

    # Calculate slant using Haversine distance
    slant_range = slant_distance_from_latlon(own_data["lat"],
                                            own_data["lon"],
                                            attacker_lat,
                                            attacker_lon,
                                            radius, 
                                            own_status.history.baroalt.value[length(own_status.history.baroalt.value)])

    # Calculate bearing between aircraft and attacker 
    # Mod pi catch weird cases which somehow end up wrapped around
    chi_rel = (bearing_to_latlon(own_data["lat"],
                                own_data["lon"],
                                attacker_lat,
                                attacker_lon,
                                false) + 2*pi) % 2pi

    # Construct DF0 struct for this run
    df0_struct = {
        "report_time" => current_timestep + 0.0001,
        "report_type" => "Acas_XaXo_DO385",
        "acas_xaxo_do385" => {
            "data_type" => "DF0",
            "df0" => {
                "toa" => current_timestep + 0.0001,
                "mode_s" => 1,
                "r_slant_ft" => slant_range,
                "Chi_rel_rad" => chi_rel,
                "baro_alt_ft" => baro_alt,
                "quant_ft" => intent.quant_ft,
                "ri" => intent.ri,
                "surv_mode" => intent.surv_mode
            }
        }
    }

    return df0_struct
end

function altitude_prep(trajectory_json, strategy)
    """
    Given a trajectory and a strategy, prepares the start and ending altitudes 
    for the attacker according to the strategy.

    Parameters
    ----------
    trajectory_json : Dict
        Dictionary describing the target aircraft trajectory
    strategy : Dict 
        Dictionary describing the attacker strategy

    Returns
    -------
    altitudes : list
        Start and end altitudes for the attacker trajectory.
    """
    altitudes = [0.0,0.0]
    
    # For any of the modes where the attacker is set to 'cross over' the target # altitude at either the middle (attacker_pos = 1) or end 
    # (attacker_pos = 0) of the target trajectory.
    if strategy["mode"] == 0 || strategy["mode"] == 1 || strategy["mode"] == 2
        # Case of cross over in the middle of the target trajectory
        if strategy["attacker_pos"] == 1
            # Needs conversion to float since the JSON parser doesn't 
            # handle floats well
            altitudes[1] = trajectory_json["metadata"]["mid_alt"]*3.281 + float(strategy["start_alt_delta"])
            altitudes[2] = trajectory_json["metadata"]["mid_alt"]*3.281 + float(strategy["end_alt_delta"])
        # Case of cross over at the end of the target trajectory
        elseif strategy["attacker_pos"] == 0
            altitudes[1] = trajectory_json["metadata"]["last_alt"]*3.281 + float(strategy["start_alt_delta"])
            altitudes[2] = trajectory_json["metadata"]["last_alt"]*3.281 + float(strategy["end_alt_delta"])
        end
    # This is the mode where we determine the altitude crossover point based on
    # a defined altitude rate change and cross point - it calculates where the 
    # start and end altitudes need to be to make this happen.
    elseif strategy["mode"] == 3
        run_length = length(trajectory_json["data"])
        crossover_step = int(floor(run_length*strategy["cross_point"]))
        
        #This is a guard in case crossover step goes to 0
        if crossover_step == 0
            crossover_step = 1
        end
        alt_at_cross = trajectory_json["data"][crossover_step]["baroaltitude"]*3.281

        altitudes[1] = alt_at_cross - (crossover_step * strategy["rate"])
        altitudes[2] = alt_at_cross + ((run_length-crossover_step) * strategy["rate"])
    end
    return altitudes
end

function attacker_intent_prep(trajectory_json, strategy, altitudes)
    """
    Prepares an attacker intent structure given a trajectory, strategy and start/end altitudes

    Parameters
    ----------
    trajectory_json : Dict
        Dictionary describing the target aircraft trajectory
    strategy : Dict
        Dictionary describing the attacker strategy
    altitudes : list
        List of start and end altitudes
    """
    return [OpenskyAttackerIntent(
        10,
        altitudes[1],
        altitudes[2],
        25,
        3,
        0,
        length(trajectory_json["data"]),
        strategy["mode"],
        strategy["rate"])]
end


function haversine(lat_1, lon_1, lat_2, lon_2, radius)
    """
    Calculates Haversine distance between two coordinate pairs

    Parameters
    ----------
    lat_1 : float
        Latitude of the first coordinate pair
    lon_1 : float
        Longitude of the first coordinate pair
    lat_2 : float
        Latitude of the second coordinate pair
    lon_2 : float
        Longitude of the second coordinate pair
    radius : float
        Radius of the Earth

    Returns
    -------
    d : float
        Distance between coordinate pairs
    """
    phi_1 = deg2rad(lat_1)
    phi_2 = deg2rad(lat_2)
    
    delta_phi = deg2rad(lat_2 - lat_1)
    delta_lambda = deg2rad(lon_2 - lon_1)
    
    a = (sin(delta_phi/2) ^ 2) + cos(phi_1) * cos(phi_2) * sin(delta_lambda/2) ^ 2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    d = radius * c

    return d
end

function slant_distance_from_latlon(
    lat_1, 
    lon_1, 
    lat_2, 
    lon_2, 
    radius, 
    altitude_diff
)
    """
    Calculates Haversine distance between two coordinates, factoring in any altitude differences to give a slant (straight line) distance

    Parameters
    ----------
    lat_1 : float
        Latitude of the first coordinate pair
    lon_1 : float
        Longitude of the first coordinate pair
    lat_2 : float
        Latitude of the second coordinate pair
    lon_2 : float
        Longitude of the second coordinate pair
    radius : float
        Radius of the Earth

    Returns
    -------
    float
        Slant distance between two posititions at a given altitude difference
    """
    haver_dist = haversine(lat_1, lon_1, lat_2, lon_2, radius)
    #print("")
    return sqrt(haver_dist^2 + altitude_diff^2)
end


#Bearing from lat_1,lon_1 to lat_2,lon_2
function bearing_to_latlon(lat_1, lon_1, lat_2, lon_2, degrees)
    """
    Calculates the bearing from one coordinate pair to another, in degrees or radians

    Parameters
    ----------
    latlon_from_vector
        Latitude of the target coordinate pair
    lon_2 : float
        Longitude of the target coordinate pair
    degrees : bool
        True to return degrees, else return radians

    Returns
    -------
    float
        Bearing between lat_1, lon_1 and lat_2, lon_2
    """
    phi_1 = deg2rad(lat_1)
    phi_2 = deg2rad(lat_2)
    
    delta_phi = deg2rad(lat_2 - lat_1)
    delta_lambda = deg2rad(lon_2 - lon_1)

    y = sin(delta_lambda) * cos(phi_2)
    x = cos(phi_1) * sin(phi_2) - sin(phi_1)*cos(phi_2)*cos(delta_lambda)
    brng_rad = atan2(y,x)

    if degrees == true
        return rad2deg(brng_rad)
    else
        return brng_rad
    end
end

function latlon_from_vector(lat_1, lon_1, distance, bearing, radius)
    """
    Given a coordinate pair, distance and bearing, this calculates the resulting coordinate pair.

    Parameters
    ----------
    lat_1 : float
        Latitude of the first coordinate pair
    lon_1 : float
        Longitude of the first coordinate pair
    distance : float
        Length of the vector
    bearing : float
        Bearing from coordinate pair of the vector
    radius : float
        Radius of the Earth

    Returns
    -------
    (float, float)
        Coordinate pair
    """
    phi_1 = deg2rad(lat_1)
    lambda_1 = deg2rad(lon_1)
    phi_2 = asin(sin(phi_1) * cos(distance/radius) + cos(phi_1) * sin(distance/radius) * cos(bearing))
    lambda_2 = lambda_1 + atan2(sin(bearing) * sin(distance/radius) * cos(phi_1), cos(distance/radius) - sin(phi_1) * sin(phi_2))
    return (phi_2, lambda_2)
end
