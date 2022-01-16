function run_test_mode_acasx(
    ac, test_input, 
    reachback, prescriptive)
    """
    Given some test input, this method runs the test input against 
    ACAS X for the aircraft ac to generate the aircraft state for later
    testing.

    Parameters
    ----------
    ac - Aircraft
        An aircraft object used to run the tests against.
    test_input - Dict
        A dictionary describing the test data, as loaded from the DO-385
        JSON files.
    reachback - Bool
        Set to true if the test involves reachback (i.e. a UDS message
        arrives and needs to be processed before the others)
    prescriptive - Bool
        Set to true if we are in prescriptive test mode.
    """
    time_step = 0.0

    # Time of the first report in the test input
    initial_report_time = test_input["Input"]["acasx_reports"][1]["report_time"]
    # Start time as reported by the input header
    start_time = test_input["Input"]["playback_header"]["start_time"]
    # ACAS X Reports to feed into the sim
    acasx_reports = test_input["Input"]["acasx_reports"]

    last_time = initial_report_time
    current_iter = ceil(initial_report_time)

    # This condition handles if you get the first message at 0.0
    # which makes the system explode for some reason
    if current_iter == 0.0
        current_iter = 1.0
    end

    LoggerTool.debug(
        logger, 
        "Current Iter is $current_iter - Start time is $start_time"
    )

    # If we have a gap between the first message and the start time
    # We just need to repeatedly iterate until the test inputs begin
    # otherwise tests will fail due to incorrect iter numbers
    if abs(start_time - current_iter) > 1.0
        uds_messages = Array(Dict{String,Any}, 0)
        for i in 1:(current_iter-1)
            Aircraft.Iterate(ac, i, uds_messages, prescriptive)
        end
    end
    
    for i in 1:length(acasx_reports)
        #The second part of the condition is a bodge to handle cases where we have a report at 0.0

        # If we are at the start of a new iteration, we need to look ahead to
        # find the UDS messages from the next iteration/time step and 
        # pass them when we 'update' the state logs
        # This also handles the iteration of the normal case, where the gap 
        # between steps is 1
        if abs(ceil(acasx_reports[i]["report_time"]) - current_iter) == 1.0 && acasx_reports[i]["report_time"] > 0.0
            LoggerTool.debug(logger, "Iterate at $(current_iter)")

            #Now look forwards to check for UDS messages
            uds_messages = Array(Dict{String,Any}, 0)
            if reachback == true
                time = current_iter 
                # We can look forward up to 0.6 time units for UDS
                max_time = current_iter + 0.6
                j = i
                if i < length(acasx_reports)
                    while j <= length(acasx_reports) && acasx_reports[j]["report_time"] <= max_time
                        # If we find a UDS, add it to our list of UDS messages
                        if acasx_reports[j]["acas_xaxo_do385"]["data_type"] == "UF16UDS30"
                            push!(uds_messages, acasx_reports[j]["acas_xaxo_do385"]["uf16uds30"])
                            LoggerTool.debug(
                                logger, 
                                "Found $(acasx_reports[j]["report_time"]) $(acasx_reports[j]["acas_xaxo_do385"]["uf16uds30"])")
                        end
                        j += 1
                    end
                end
            end

            # We now iterate the aircraft to update the state logs, including
            # the UDS messages from the next time step
            Aircraft.Iterate(ac, current_iter, uds_messages, prescriptive)
            current_iter = ceil(acasx_reports[i]["report_time"])

        # This handles the case when the gap between iterations is larger than 
        # 1 - it iterates multiple times
        elseif abs(ceil(acasx_reports[i]["report_time"]) - current_iter) > 1.0
            diff = abs(ceil(acasx_reports[i]["report_time"]) - current_iter)
            uds_messages = Array(Dict{String,Any}, 0)
            LoggerTool.debug(
                logger, 
                "Jumping at $current_iter to $(ceil(acasx_reports[i]["report_time"]))")
            for j in current_iter:(ceil(acasx_reports[i]["report_time"])-1)
                Aircraft.Iterate(ac, j, uds_messages, prescriptive)
            end
            current_iter = ceil(acasx_reports[i]["report_time"])
        end

        # Then we process whatever message is at this iteration
        LoggerTool.debug(
            logger,
            "REPORT $(acasx_reports[i]["report_time"]) type $(acasx_reports[i]["acas_xaxo_do385"]["data_type"])")
        last_time = process_message(
            ac, 
            acasx_reports[i], 
            current_iter, 
            reachback, 
            prescriptive) 
    end

    # Iterate one final time to update the state logs
    uds_messages = Array(Dict{String,Any}, 0)
    Aircraft.Iterate(ac, last_time, uds_messages, prescriptive)
end

function process_message(ac, i, current_iter, reachback, prescriptive)
    """
    Given an ACAS X message, this logs it with the ACAS X simulation 
    in the Aircraft module. This is meant to represent the 'box' 
    as a whole, so consumes any ACAS X message.

    Parameters
    ----------
    ac - Aircraft
        Aircraft object representing the current state of the ACAS X sim
        onboard
    i - Dict
        Dictionary representing an ACAS X message
    current_iter - Int
        Current iteration/iteration to log the message against
    reachback - Bool
        Set to true if we in reachback mode
    prescriptive - Bool
        Set to true if we are in prescriptive test mode
    
    Returns 
    -------
    last_time - Int
        The time step of the report just processed.
    """
    if i["acas_xaxo_do385"]["data_type"] == "OWNSHIP_DISCRETES"
        Aircraft.LogDiscretes(i["acas_xaxo_do385"]["ownship_discretes"])
    elseif i["acas_xaxo_do385"]["data_type"] == "HEADING_OBS"
        Aircraft.LogHeadingObservation(i["acas_xaxo_do385"]["heading_obs"])
    elseif i["acas_xaxo_do385"]["data_type"] == "BARO_ALT_OBS"
        #println(i["acas_xaxo_do385"]["baro_alt_obs"])
        Aircraft.LogBaroAltObservation(i["acas_xaxo_do385"]["baro_alt_obs"])
    elseif i["acas_xaxo_do385"]["data_type"] == "DF0"
        Aircraft.LogDF0(i["acas_xaxo_do385"]["df0"])
    elseif i["acas_xaxo_do385"]["data_type"] == "WGS84_OBS"
        Aircraft.LogWGS84Observation(i["acas_xaxo_do385"]["wgs84_obs"])
    elseif i["acas_xaxo_do385"]["data_type"] == "RAD_ALT_OBS"
        Aircraft.LogRadAltObservation(i["acas_xaxo_do385"]["rad_alt_obs"])
    elseif i["acas_xaxo_do385"]["data_type"] == "AIRBORNE_POSITION_REPORT"
        Aircraft.LogAirbornePositionReport(i["acas_xaxo_do385"]["airborne_position_report"])
    elseif i["acas_xaxo_do385"]["data_type"] == "AIRBORNE_VELOCITY_REPORT"
        Aircraft.LogAirborneVelocityReport(i["acas_xaxo_do385"]["airborne_velocity_report"])
    elseif i["acas_xaxo_do385"]["data_type"] == "MODE_STATUS_REPORT"
        Aircraft.LogModeStatusReport(i["acas_xaxo_do385"]["mode_status_report"])
    elseif i["acas_xaxo_do385"]["data_type"] == "UF16UDS30"
        Aircraft.LogUF16UDS30(i["acas_xaxo_do385"]["uf16uds30"])
    elseif i["acas_xaxo_do385"]["data_type"] == "TARGET_DESIGNATION"
        Aircraft.LogTargetDesignation(i["acas_xaxo_do385"]["target_designation"])
    elseif i["acas_xaxo_do385"]["data_type"] == "CAPABILITY_REPORT"
        Aircraft.LogCapabilityReport(i["acas_xaxo_do385"]["capability_report"])
    elseif i["acas_xaxo_do385"]["data_type"] == "MODE_C_REPLY"
        if prescriptive
            Aircraft.LogModeCReply(ac, i["acas_xaxo_do385"]["mode_c_reply"])
        else
            Aircraft.LogModeCReplies(ac, i["acas_xaxo_do385"]["mode_c_reply"])
        end
    else
        error("Unidentified message type: $(i["acas_xaxo_do385"]["data_type"])")
    end
    last_time = i["report_time"]

    return last_time
end
