"""
aircraft.jl

Module representing the aircraft, including helper functions 
wrapping data input into the ACAS system.
"""

module Aircraft
    export Iterate, LogState, LogHeadingObservation, LogBaroAltObservation, LogDiscretes, LogRadAltObservation, LogUF16UDS30, LogDF0, AircraftInstance

    include("standardised_code/structures.jl")
    include("standardised_code/math_utils.jl")
    include("standardised_code/global_constants.jl")

    include("logger.jl")
    include("utilities.jl")
    include("parameter_loading_helpers.jl")
    import LoggerTool

    # Set this up as an aircraft logger - logs internal stuff
    const logger = LoggerTool.setup(true, true, 3, "aircraft_log.txt")

    include("do385_params.jl")
    #include("user_params.jl")

    import JSON

    @time params = load_params(PARAMS_DIR, PARAMS_FILENAME)

    include("standardised_code/stm.jl")
    include("standardised_code/trm.jl")

    type StateLogEntry
        time::Float64
        trm_report::TRMReport
        stm_report::StmReport
        trm_state::TRMState
        own::OwnShipData
        StateLogEntry(time::Float64, trm_report::TRMReport, stm_report::StmReport, trm_state::TRMState, own::OwnShipData) = new(time, trm_report, stm_report, trm_state, own)
    end

    type AircraftInstance
        trm_state::TRMState
        current_trm_report::TRMReport
        current_stm_report::StmReport
        internal_clock::Float64
        mode_c::Vector{ModeCReply}
        state_log::Vector{StateLogEntry}
        AircraftInstance() = new(TRMState(), TRMReport(), StmReport(),  0.0, Array(ModeCReply, 0), Array(StateLogEntry, 0))
    end

    # Iterate was using the internal clock which was set 
    # before the current cycle of messages came in
    # Now changed to go to the start of the next cycle.

    function reset()
        """
        Resets the state of the aircraft module
        """
        #global own = 0
        global own = OwnShipData()
        global target_db = Database{Uint32,Target}(uint32(0))
        global hyp_track_db = Database{Uint32,HypotheticalModeCTrackFile}(uint32(0))
        global modecIntervals = ModeCIntervals()

        delete!(target_db, uint32(0))
        delete!(hyp_track_db, uint32(0))
    end


    function Iterate(ac::AircraftInstance, time, uds_messages, prescriptive)
        """
        This method is called when all of the messages from a given time step
        have been consumed. It also requires any UDS messages from the next 
        time step be passed in too.

        When called, it will run the STM and TRM code, updating the state logs
        of the aircraft in doing so. Nominally, this is called once per second.

        Parameters
        ----------
        ac : AircraftInstance
            An aircraft instance which this method will update
        time : Int
            The time step we have just received messages for
        uds_messages : Array
            A list of any UDS messages from the next iteration which need
            processing
        prescriptive : Bool
            Whether we are in prescriptive mode, true indicating we are not
            processing Mode C
        Returns
        -------
        trm_report : TRMReport
            The resulting TRM report from this iteration
        """

        # Process Mode C if needs be
        if prescriptive == false
        # Adding Mode C Replies
            ReceiveModeCReplies(ac.mode_c)    
            ac.mode_c = Array(ModeCReply, 0)
        end

        # Update the internal clock and call the STM
        ac.internal_clock = ac.internal_clock + 1.0
        ac.current_stm_report = GenerateStmReport(ceil(time))
        
        #Now input and upcoming uds_messages
        for i in uds_messages
            LogUF16UDS30(i)
        end

        # Generate the TRM report
        trm_report = VerticalTRMUpdate(ac.trm_state, deepcopy(ac.current_stm_report.trm_input))
        
        # Run housekeeping to update the STM
        StmHousekeeping(deepcopy(trm_report))
        ac.current_trm_report = trm_report

        # Now update the statelog 
        push!(
            ac.state_log, 
            StateLogEntry(
                ceil(time), 
                deepcopy(ac.current_trm_report), 
                deepcopy(ac.current_stm_report), 
                deepcopy(ac.trm_state), 
                deepcopy(own)
            )
        )

        return trm_report
    end

    function LogHeadingObservation(input_data)
        """
        Processes a heading input, ensuring it is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input heading
        """
        heading = -1.0
        if typeof(input_data["heading_true_rad"]) == UTF8String
            if input_data["heading_true_rad"] == "_NaN_"
                heading = NaN
            end
        else
            heading = float64(input_data["heading_true_rad"])
        end

        ReceiveHeadingObservation(
            heading,
            input_data["toa"],
            input_data["heading_degraded"])
    end

    function LogRadAltObservation(input_data)
        """
        Processes a radio altimeter input, ensuring it is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input rad alt data
        """
        #ac.internal_clock = toa
        radalt = -1.0
        if typeof(input_data["rad_alt_ft"]) == UTF8String
            if input_data["rad_alt_ft"] == "_NaN_"
                radalt = NaN
            end
        else
            radalt = float64(input_data["rad_alt_ft"])
        end
        #println(typeof(input_data["rad_alt_ft"]))
        ReceiveRadAltObservation(radalt)
    end

    function LogBaroAltObservation(input_data)
        """
        Processes a barometric altimeter input, ensuring it is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input barometric altimeter message
        """
        #ac.internal_clock = toa
        baroalt = -1.0
        if typeof(input_data["baro_alt_ft"]) == UTF8String
            if input_data["baro_alt_ft"] == "_NaN_"
                baroalt = NaN
            end
        else
            baroalt = float64(input_data["baro_alt_ft"])
        end
        toa = -1.0
        if typeof(input_data["toa"]) == UTF8String
            if input_data["toa"] == "_NaN_"
                toa = NaN
            end
        else
            toa = float64(input_data["toa"])
        end

        #println(typeof(input_data["baro_alt_ft"]))
        ReceiveBaroAltObservation(
            baroalt,
            toa)
    end

    function LogDiscretes(input_data)
        """
        Processes a discretes input, and passes it to the STM

        Parameters
        ==========
        input_data
            Input discrete data
        """
        ReceiveDiscretes(uint32(input_data["address"]),
                uint32(input_data["mode_a"]),
                input_data["opflg"],
                uint32(input_data["manual_SL"]),
                input_data["own_ground_display_mode_on"],
                input_data["on_surface"],
                input_data["aoto_on"],
                input_data["is_coarsely_quant"])
    end

    function LogDF0(input_data)
        """
        Processes a DF0 input, inputs it into the STM.

        Parameters
        ==========
        input_data
            Input DF0 message
        """
        #ac.internal_clock = toa
        baroalt = -1.0
        if typeof(input_data["baro_alt_ft"]) == UTF8String
            if input_data["baro_alt_ft"] == "_NaN_"
                baroalt = NaN
            end
        else
            baroalt = float64(input_data["baro_alt_ft"])
        end

        r_slant = -1.0
        if typeof(input_data["r_slant_ft"]) == UTF8String
            if input_data["r_slant_ft"] == "_NaN_"
                r_slant = NaN
            end
        else
            r_slant = float64(input_data["r_slant_ft"])
        end

        Chi_rel_rad = -1.0
        if typeof(input_data["Chi_rel_rad"]) == UTF8String
            if input_data["Chi_rel_rad"] == "_NaN_"
                Chi_rel_rad = NaN
            end
        else
            Chi_rel_rad = float64(input_data["Chi_rel_rad"])
        end

        #println("DF $baroalt $r_slant $(input_data["mode_s"])")

        ReceiveDF0(r_slant,
                    Chi_rel_rad,
                    baroalt,
                    uint32(input_data["mode_s"]),
                    uint32(input_data["quant_ft"]),
                    uint32(input_data["ri"]),
                    uint32(input_data["surv_mode"]),
                    input_data["toa"]
        )
    end

    function LogUF16UDS30(input_data)
        """
        Processes a UDS30 input, inputs it into the STM.

        Parameters
        ==========
        input_data
            Input UF16UDS30 message
        """
        #ac.internal_clock = toa
        ReceiveUF16UDS30(
            uint32(input_data["mode_s"]),
            uint32(input_data["cvc"]),
            uint32(input_data["vrc"]),
            uint32(input_data["vsb"]),
            input_data["toa"]
        )
    end

    function LogTargetDesignation(input_data)
        """
        Processes a target designation message, inputs it into the STM.

        Parameters
        ==========
        input_data
            Input Target Designation
        """
        #ac.internal_clock = toa
        ReceiveTargetDesignation(
            uint32(input_data["mode_s"]),
            uint32(input_data["designation"])
        )
    end

    function LogWGS84Observation(input_data)
        """
        Processes a WGS84 message input, and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input WGS84 message
        """
        ReceiveWgs84Observation(
                            float64(input_data["lat_deg"]),
                            float64(input_data["lon_deg"]),
                            float64(input_data["vel_ew_kts"]),
                            float64(input_data["vel_ns_kts"]),
                            input_data["toa"])
    end

    function LogAirbornePositionReport(input_data)
        """
        Processes an airport position report (ADS-B) input, ensuring it is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input Airborne position report message
        """
        baroalt = -1.0
        if typeof(input_data["baro_alt_ft"]) == UTF8String
            if input_data["baro_alt_ft"] == "_NaN_"
                baroalt = NaN
            end
        else
            baroalt = float64(input_data["baro_alt_ft"])
        end

        ReceiveStateVectorPositionReport(
            float64(input_data["lat_deg"]),
            float64(input_data["lon_deg"]),
            baroalt,
            uint32(input_data["address"]),
            uint32(input_data["nic"]),
            uint32(input_data["quant_ft"]),
            input_data["rebroadcast"],
            input_data["non_icao"],
            input_data["toa"]
        )
    end

    function LogAirborneVelocityReport(input_data)
        """
        Processes a velocity report (ADS-B) input, ensuring it is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input Airborne velocity report message
        """
        ReceiveStateVectorVelocityReport(
            float64(input_data["vel_ew_kts"]),
            float64(input_data["vel_ns_kts"]),
            uint32(input_data["address"]),
            uint32(input_data["nic"]),
            input_data["rebroadcast"],
            input_data["non_icao"],
            input_data["toa"]
        )
    end

    function LogModeStatusReport(input_data)
        """
        Processes a Mode status report input, ensuring it is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input mode status report message
        """
        ReceiveModeStatusReport(
            uint32(input_data["adsb_version"]),
            uint32(input_data["nacp"]),
            uint32(input_data["nacv"]),
            uint32(input_data["sil"]),
            uint32(input_data["sda"]),
            uint32(input_data["address"]),
            input_data["rebroadcast"],
            input_data["non_icao"]
        )
    end

    function LogCapabilityReport(input_data)
        """
        Processes a capability report input, and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input capability report
        """
        ReceiveCapabilityReport(
            uint32(input_data["adsb_version"]),
            uint8(input_data["ca_operational"]),
            uint8(input_data["sense"]),
            uint8(input_data["type_capability"]),
            uint8(input_data["priority"]),
            uint8(input_data["daa"]),
            uint32(input_data["address"]),
        )
    end

    function LogModeCReply(ac, input_data)
        """
        Processes a Mode C reply input, ensuring it is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input Mode C reply message
        """
        input = ModeCReply()

        r_slant = -1.0
        if typeof(input_data["r_slant_ft"]) == UTF8String
            if input_data["r_slant_ft"] == "_NaN_"
                r_slant = NaN
            end
        else
            r_slant = float64(input_data["r_slant_ft"])
        end

        Chi_rel_rad = -1.0
        if typeof(input_data["Chi_rel_rad"]) == UTF8String
            if input_data["Chi_rel_rad"] == "_NaN_"
                Chi_rel_rad = NaN
            end
        else
            Chi_rel_rad = float64(input_data["Chi_rel_rad"])
        end


        input.external_ID = input_data["external_ID"]
        input.coded_alt = input_data["coded_alt"]
        input.conf = input_data["confidence"]
        input.r_slant = r_slant
        input.Chi_rel = Chi_rel_rad
        input.toa = input_data["toa"]

        #println("MODE C $input")

        #push!(ac.mode_c, input)

        ReceiveModeCReply(input)
    end

    function LogModeCReplies(ac, input_data)
        """
        Processes a batch of Mode C replies, ensuring each is the correct type and inputs it into the STM.

        Parameters
        ==========
        input_data
            Input Mode C replies
        """
        input = ModeCReply()

        r_slant = -1.0
        if typeof(input_data["r_slant_ft"]) == UTF8String
            if input_data["r_slant_ft"] == "_NaN_"
                r_slant = NaN
            end
        else
            r_slant = float64(input_data["r_slant_ft"])
        end

        Chi_rel_rad = -1.0
        if typeof(input_data["Chi_rel_rad"]) == UTF8String
            if input_data["Chi_rel_rad"] == "_NaN_"
                Chi_rel_rad = NaN
            end
        else
            Chi_rel_rad = float64(input_data["Chi_rel_rad"])
        end


        input.external_ID = input_data["external_ID"]
        input.coded_alt = input_data["coded_alt"]
        input.conf = input_data["confidence"]
        input.r_slant = r_slant
        input.Chi_rel = Chi_rel_rad
        input.toa = input_data["toa"]

        #println("MODE C $input")

        push!(ac.mode_c, input)
        #ReceiveModeCReply(input)

    end

end

