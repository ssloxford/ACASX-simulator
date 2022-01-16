function run_opensky_input_batch(
    ac, 
    data, 
    ownship_discretes, 
    attacker_pos, 
    at_intents
)
    """
    This method runs an attack simulation on an aircraft flying the trajectory defined by data.

    Parameters
    ----------
    ac : Aircraft 
        Aircraft object to use as the target aircraft
    data : Dict
        Trajectory data
    ownship_discretes : OwnDiscreteData
        Ownship discretes data, as defined using the basic template
    attacker_pos : int 
        Attacker position indicator - 0 is an end attacker, 1 is a middle attacker
    at_intents : OpenskyAttackerIntent
        Attacker intention, i.e. the strategy used in the attack
    """        
    # radius_km = 6365.066
    # radius_ft = radius_km * 3281

    # time_step = 0.0
    # last_time = 0.1
    # current_iter = ceil(0.0)
    # #This condition handles if you get the first message at 0.0
    # if current_iter == 0.0
    #     current_iter = 1.0
    # end

    # offset = 0

    if attacker_pos == 1
        lon_mid = data[floor(length(data)/2)]["lon"]
        lat_mid = data[floor(length(data)/2)]["lat"]
    else
        lon_mid = data[length(data)]["lon"]
        lat_mid = data[length(data)]["lat"]
    end

    opensky_input_loop(
        ac, 
        data, 
        ownship_discretes, 
        attacker_pos, 
        at_intents,
        lat_mid,
        lon_mid
    )

    # # TODO This is the loop we need to change to run for steps 1 to x, generating messages each time 
    # Aircraft.Iterate(ac,last_time,[], true)

    # current_iter = 0
    # for i in 1:length(data)

    #     current_iter = i

    #     # ------- Ownship discretes
    #     next_osdisc = next_ownship_discretes(current_iter, ownship_discretes)

    #     current_iter = next_osdisc["report_time"]

    #     last_time = process_message(ac,
    #      next_osdisc, 
    #      current_iter, 
    #      false, 
    #      true)

    #     # ------- Next Alt from Opensky
    #     next_alt, offset = next_altitude_from_opensky(current_iter, data[i],
    #     ac.state_log[length(ac.state_log)].trm_report, 
    #     ac.state_log[length(ac.state_log)].own, offset)

    #     current_iter = next_alt["report_time"]

    #     #println("OFFSET $(offset)")
        
    #     last_time = process_message(ac,
    #      next_alt, 
    #      current_iter, 
    #      false, 
    #      true)


    #     # ------- Next head from opensky
    #     next_head = next_heading_from_opensky(current_iter, data[i])

    #     current_iter = next_head["report_time"]
        
    #     last_time = process_message(ac,
    #                     next_head, 
    #                     current_iter, 
    #                     false, 
    #                     true)
        

    #     # ------ WGS84
    #     next_wgs84 = next_wgs84_from_opensky(current_iter, data[i])

    #     current_iter = next_wgs84["report_time"]

    #     last_time = process_message(ac,
    #                     next_wgs84, 
    #                     current_iter, 
    #                     false, 
    #                     true)

    #     ##---------- Attacker messages ---------


    #     if current_iter > 2
    #         next_df0 = generate_next_attacker_df0_opensky(current_iter, 
    #         data[i],
    #         lat_mid, 
    #         lon_mid, 
    #         0,
    #         radius_ft, 
    #         ac.state_log[end].own, 
    #         at_intents[1],
    #         length(data))

    #         current_iter = next_df0["report_time"]

    #         last_time = process_message(ac,
    #                         next_df0, 
    #                         current_iter, 
    #                         false, 
    #                         true)
    #     end

    #     ## --------- ITERATE -------------
    #     #print("Iterate")
    #     Aircraft.Iterate(ac, last_time, [], true)

    #     current_iter = ceil(current_iter)
    # end
end


function run_opensky_input_batch_gridder(ac, data, ownship_discretes, attacker_pos, at_intents, lat, lon)
    """
    This method runs an attack simulation on Opensky data, but allows any lat/lon pair to be passed as the attacker position

    Parameters
    ----------
    ac : Aircraft 
        Aircraft object to use as the target aircraft
    data : Dict
        Trajectory data
    ownship_discretes : OwnDiscreteData
        Ownship discretes data, as defined using the basic template
    attacker_pos : int 
        Attacker position indicator - 0 is an end attacker, 1 is a middle attacker
    at_intents : OpenskyAttackerIntent
        Attacker intention, i.e. the strategy used in the attack
    lat : float
        Latitude of the attacker
    lon : float 
        Longitude of the attacker
    """
    opensky_input_loop(
        ac, 
        data, 
        ownship_discretes, 
        attacker_pos, 
        at_intents, 
        lat, 
        lon
    )

end

function opensky_input_loop(
    ac, 
    data, 
    ownship_discretes, 
    attacker_pos, 
    at_intents, 
    lat_mid, 
    lon_mid
)
    """
    Core loop for running attacks on an Opensky trajectory, with the attacker positioned at lat_mid, lon_mid.

    Parameters
    ----------
    ac : Aircraft 
        Aircraft object to use as the target aircraft
    data : Dict
        Trajectory data
    ownship_discretes : OwnDiscreteData
        Ownship discretes data, as defined using the basic template
    attacker_pos : int 
        Attacker position indicator - 0 is an end attacker, 1 is a middle attacker
    at_intents : OpenskyAttackerIntent
        Attacker intention, i.e. the strategy used in the attack
    lat_mid : float
        Latitude of the attacker
    lon_mid : float 
        Longitude of the attacker
    """
    radius_km = 6365.066
    radius_ft = radius_km * 3281

    time_step = 0.0
    last_time = 0.1

    current_iter = ceil(0.0)
    #This condition handles if you get the first message at 0.0
    if current_iter == 0.0
        current_iter = 1.0
    end

    offset = 0
    # TODO This is the loop we need to change to run for steps 1 to x, generating messages each time 

    Aircraft.Iterate(ac,last_time,[], true)

    current_iter = 0
    for i in 1:length(data)

        current_iter = i

        # ------- Ownship discretes
        next_osdisc = next_ownship_discretes(current_iter, ownship_discretes)

        current_iter = next_osdisc["report_time"]

        last_time = process_message(ac,
         next_osdisc, 
         current_iter, 
         false, 
         true)

        # ------- Next Alt from Opensky
        next_alt, offset = next_altitude_from_opensky(current_iter, data[i],
        ac.state_log[length(ac.state_log)].trm_report, 
        ac.state_log[length(ac.state_log)].own, offset)

        current_iter = next_alt["report_time"]

        #println("OFFSET $(offset)")
        
        last_time = process_message(ac,
         next_alt, 
         current_iter, 
         false, 
         true)


        # ------- Next head from opensky
        next_head = next_heading_from_opensky(current_iter, data[i])

        current_iter = next_head["report_time"]
        
        last_time = process_message(ac,
                        next_head, 
                        current_iter, 
                        false, 
                        true)
        

        # ------ WGS84
        next_wgs84 = next_wgs84_from_opensky(current_iter, data[i])

        current_iter = next_wgs84["report_time"]

        last_time = process_message(ac,
                        next_wgs84, 
                        current_iter, 
                        false, 
                        true)

        ##---------- Attacker messages ---------


        if current_iter > 2
            next_df0 = generate_next_attacker_df0_opensky(current_iter, 
            data[i],
            lat_mid, 
            lon_mid, 
            0,
            radius_ft, 
            ac.state_log[end].own, 
            at_intents[1],
            length(data))

            current_iter = next_df0["report_time"]

            last_time = process_message(ac,
                            next_df0, 
                            current_iter, 
                            false, 
                            true)
        end

        ## --------- ITERATE -------------
        #print("Iterate")
        Aircraft.Iterate(ac, last_time, [], true)

        current_iter = ceil(current_iter)
    end
end
