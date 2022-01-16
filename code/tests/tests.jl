using Base.Test

function replace_NaNs(input)
    for i in keys(input)
        if input[i] == "_NaN_"
            input[i] = NaN
            #println("Found NaN at $i")
        end
    end
    #println(input)
    return input
end

function STM_Display_Test(input, expected)
    expected = replace_NaNs(expected)
    @test expected["arrow"] == input.arrow 
    @test expected["alt_reporting"] == input.alt_reporting 
    @test expected["bearing_valid"] == input.bearing_valid 
    @test uint32(expected["id"]) == input.id 
    #println("ZR $(expected["z_rel"]) $(input.z_rel)")
    if !(isnan(expected["z_rel"]) && isnan(input.z_rel))
        @test expected["z_rel"] == input.z_rel
    end
    #println("$(expected["r_ground"]) $(input.r_ground)")
    @test_approx_eq_eps(expected["r_ground"], input.r_ground, 0.1)
    @test_approx_eq_eps(expected["Chi_rel"], input.Chi_rel, 0.1)
    @test uint32(expected["mode_s"]) == input.mode_s 
    @test expected["is_icao"] == input.is_icao 

end

function STM_Transponder_Test(input, expected)
    #println("$(expected["transponder"]["ri"]) $(input.transponder.ri)")
    @test input.transponder.ri == expected["transponder"]["ri"]
    @test input.transponder.sl == expected["transponder"]["sl"]
    @test input.transponder.vi == expected["transponder"]["vi"]
    @test input.transponder.bit48 == expected["transponder"]["bit48"]
    @test input.transponder.bit69 == expected["transponder"]["bit69"]
    @test input.transponder.bit70 == expected["transponder"]["bit70"]
    @test input.transponder.bit71 == expected["transponder"]["bit71"]
    @test input.transponder.bit72 == expected["transponder"]["bit72"]

end

function STM_TRM_Own_Test(input, expected)

        expected_own = replace_NaNs(expected["trm_input"]["own"])

        #println("Expt $(expected_own["h"]) $(input.trm_input.own.h)")
        if !(isnan(input.trm_input.own.h) && isnan(expected_own["h"]))
            @test input.trm_input.own.h == expected_own["h"] 
        end

        #println("PSI $(input.trm_input.own.psi) ex $(expected_own["psi"])")
        if !isnan(expected_own["psi"])
            @test input.trm_input.own.psi == expected_own["psi"]
        else
            if !isnan(input.trm_input.own.psi) 
                error("STM TRM Own - Psi NaN mismatch")
            end
        end
        @test input.trm_input.own.mode_s == expected_own["mode_s"]
        @test input.trm_input.own.mode_a == expected_own["mode_a"]
        @test input.trm_input.own.opmode == expected_own["opmode"]

        @test input.trm_input.own.degraded_own_surveillance == expected_own["degraded_own_surveillance"]
        @test input.trm_input.own.xo_availability == expected_own["xo_availability"]

        @test length(expected_own["belief_vert"]) == length(input.trm_input.own.belief_vert)

        if length(expected_own["belief_vert"]) > 0
            for i = 1:length(expected_own["belief_vert"])
                #println("ZZ $(input.trm_input.own.belief_vert[i].z) $(expected_own["belief_vert"][i]["z"])")
                @test input.trm_input.own.belief_vert[i].z == expected_own["belief_vert"][i]["z"]

                @test input.trm_input.own.belief_vert[i].dz == expected_own["belief_vert"][i]["dz"]
                @test input.trm_input.own.belief_vert[i].weight == expected_own["belief_vert"][i]["weight"]
            end
        end
end

function STM_TRM_Intruder_Test(input, expected)
    input_intruders = input.trm_input.intruder
    expected_intruders = expected["trm_input"]["intruder"]

    @test length(expected_intruders) == length(input_intruders)

    if length(expected_intruders) > 0
        for i = 1:length(expected_intruders)
            found = false
            for k = 1:length(input_intruders)
                if expected_intruders[i]["id"] == input_intruders[k].id
                    found = true
                    #println("Found int")
                    @test input_intruders[k].valid == expected_intruders[i]["valid"] 
                    #println("ID--$(input_intruders[k].id) ex $(expected_intruders[i]["id"])")
                    @test input_intruders[k].id == expected_intruders[i]["id"] 
                    @test input_intruders[k].address == expected_intruders[i]["address"] 
                    @test input_intruders[k].is_icao == expected_intruders[i]["is_icao"] 
                    #println("VRC--input $(input_intruders[k].vrc) ex $(expected_intruders[i]["vrc"])")
                    @test input_intruders[k].vrc == expected_intruders[i]["vrc"] 
                   
                    @test input_intruders[k].equipage == expected_intruders[i]["equipage"] 
                    @test input_intruders[k].active_cas_version == expected_intruders[i]["active_cas_version"] 
                    @test input_intruders[k].coordination_msg == expected_intruders[i]["coordination_msg"] 
                    @test input_intruders[k].source == expected_intruders[i]["source"] 
                    @test input_intruders[k].degraded_surveillance == expected_intruders[i]["degraded_surveillance"] 
                    @test input_intruders[k].is_proximate == expected_intruders[i]["is_proximate"] 
                    @test input_intruders[k].designated_mode == expected_intruders[i]["designated_mode"] 
                    @test input_intruders[k].protection_mode == expected_intruders[i]["protection_mode"] 
                    @test input_intruders[k].dna == expected_intruders[i]["dna"] 
                    @test input_intruders[k].xo_valid == expected_intruders[i]["xo_valid"] 
                    @test input_intruders[k].xo_status == expected_intruders[i]["xo_status"] 

                    STM_Display_Test(input_intruders[k].stm_display, expected_intruders[i]["stm_display"])


                    input_intruder_verts = input_intruders[k].belief_vert
                    expected_intruder_verts = expected_intruders[i]["belief_vert"]

                    #println("Here1")
                    @test length(input_intruder_verts) == length(expected_intruder_verts)

                    if length(input_intruder_verts) > 0
                        for j = 1:length(expected_intruder_verts)
                            #println("$(input_intruder_verts[j].z) ex $(expected_intruder_verts[j]["z"])")
                            @test input_intruder_verts[j].z == expected_intruder_verts[j]["z"]
                            @test input_intruder_verts[j].dz == expected_intruder_verts[j]["dz"]
                            @test input_intruder_verts[j].weight == expected_intruder_verts[j]["weight"]
                        end
                    end


                    #println("Here2")
                    input_intruder_horiz = input_intruders[k].belief_horiz
                    #println("Here22")
                    expected_intruder_horiz = expected_intruders[i]["belief_horiz"]
                    #println("Here2 $(length(input_intruder_horiz)) $(length(expected_intruder_horiz))")
                    @test length(input_intruder_horiz) == length(expected_intruder_horiz)
                    
                    if length(input_intruder_horiz) > 0
                        for j = 1:length(expected_intruder_horiz)
                            #println("$(input_intruder_horiz[j].x_rel), $(expected_intruder_horiz[j]["x_rel"])")
                            @test_approx_eq_eps(input_intruder_horiz[j].x_rel, expected_intruder_horiz[j]["x_rel"], 0.1)
                            @test_approx_eq_eps(input_intruder_horiz[j].y_rel, expected_intruder_horiz[j]["y_rel"], 0.1)
                            @test_approx_eq_eps(input_intruder_horiz[j].dx_rel, expected_intruder_horiz[j]["dx_rel"], 0.1)
                            @test_approx_eq_eps(input_intruder_horiz[j].dy_rel, expected_intruder_horiz[j]["dy_rel"], 0.1)
                            @test_approx_eq_eps(input_intruder_horiz[j].weight, expected_intruder_horiz[j]["weight"], 0.1)
                        end
                    end
                    
                end
                found = true
            end
            if found == false
                error("STM TRM Intruder - no match")
            end
        end
    end
end


function STM_TRM_Input_Test(input, expected)
    STM_TRM_Own_Test(input, expected)
    STM_TRM_Intruder_Test(input, expected)
end

#Success doesn't actually return 
function STM_Report_Test(input, expected)
    #println("Displen $(length(expected["display"])) in $(length(input.display))")
    @test length(expected["display"]) == length(input.display)

    if length(expected["display"]) > 0
        for i = 1:length(expected["display"])
            #Adding this loop in because some of the tests are out of order...
            found = false
            #println("i is $i")
            for j = 1:length(input.display)
                #println("$(expected["display"][i]["id"]) $(input.display[j].id)")
                if expected["display"][i]["id"] == input.display[j].id
                    #println("Found")
                    STM_Display_Test(input.display[j], expected["display"][i])
                    found = true
                end
            end
            if found == false
                error("STM Display not found")
            end
        end
    end
    
    STM_TRM_Input_Test(input, expected)
    STM_Transponder_Test(input, expected)
    
end


function TRM_Report_Test(input, expected)
    success = true
    error_log = Array(String, 0)

    TRM_Coordination_Test(input.coordination, expected["coordination"])

    TRM_Designation_Test(input.designation, expected["designation"])

    TRM_Broadcast_Test(input.broadcast, expected["broadcast"])

    TRM_Ground_Msg_Test(input.ground_msg, expected["ground_msg"])
    
    #Commented out for now as they didn't seem to use Inf in their test spec...
    #TRM_Debug_Data_Test(input.debug, expected["debug"])
    
    # Display
    TRM_Display_Test(input.display, expected["display"])


end

function TRM_Display_Test(input, expected)

    @test input.cc == expected["cc"]
    @test input.vc == expected["vc"]
    @test input.ua == expected["ua"]
    @test input.da == expected["da"]
    @test input.target_rate == expected["target_rate"]
    @test input.turn_off_aurals == expected["turn_off_aurals"]
    @test input.crossing == expected["crossing"]
    @test input.alarm == expected["alarm"]

    @test length(expected["intruder"]) == length(input.intruder)
    
    if length(expected["intruder"]) > 0
        for i = 1:length(expected["intruder"])
            found = false
            for j = 1:length(input.intruder)
                if expected["intruder"][i]["id"] == input.intruder[j].id
                    TRM_Intruder_Display_Test(input.intruder[j], expected["intruder"][i])
                    found = true
                end
            end
            if found == false
                error("Matching TRM Display not found")
            end
        end
    end
end

function TRM_Intruder_Display_Test(input, expected)
    
    @test input.id == expected["id"]
    @test input.mode_s == expected["mode_s"]
    @test input.is_icao == expected["is_icao"]
    @test input.code == expected["code"]
    @test_approx_eq_eps(input.tds, expected["tds"], 0.1)


end

function TRM_Coordination_Test(input, expected)
    @test length(expected) == length(input)

    if length(expected) > 0
        for i = 1:length(expected)
            found = false
            for j = 1:length(input)
                if input[j].id == expected[i]["id"]
                    found = true
                    @test input[j].id == expected[i]["id"]
                    @test input[j].cvc == expected[i]["cvc"]
                    #println("TRM VRC $(input[j].vrc) $(expected[i]["vrc"])")
                    @test input[j].vrc == expected[i]["vrc"]
                    @test input[j].vsb == expected[i]["vsb"]
                    @test input[j].chc == expected[i]["chc"]
                    @test input[j].hrc == expected[i]["hrc"]
                    @test input[j].hsb == expected[i]["hsb"]
                    @test input[j].mtb == expected[i]["mtb"]
                    @test input[j].mid == expected[i]["mid"]
                    @test input[j].taa == expected[i]["taa"]
                    @test input[j].coordination_msg == expected[i]["coordination_msg"]
                end
            end
            if found == false
                error("TRM Coordination ID match failed")
            end
        end
    end
end

function TRM_Designation_Test(input, expected)
    # availability
    @test input.availability == expected["availability"]


    # intruder
    @test length(expected["intruder"]) == length(input.intruder)

    if length(expected["intruder"]) > 0
        for i = 1:length(expected["intruder"])
            found = false
            for j = 1:length(input.intruder)
                if input.intruder[j].id == expected["intruder"][i]["id"]
                    found = true
                    @test input.intruder[j].id == expected["intruder"][i]["id"]
                    @test input.intruder[j].address == expected["intruder"][i]["address"]
                    @test input.intruder[j].is_icao == expected["intruder"][i]["is_icao"]
                    @test input.intruder[j].designated_mode == expected["intruder"][i]["designated_mode"]
                    @test input.intruder[j].active_ra == expected["intruder"][i]["active_ra"]
                    @test input.intruder[j].suppressed_ra == expected["intruder"][i]["suppressed_ra"]
                    @test input.intruder[j].multithreat == expected["intruder"][i]["multithreat"]
                    @test input.intruder[j].valid == expected["intruder"][i]["valid"]
                    @test input.intruder[j].status == expected["intruder"][i]["status"]

                    #logic_mode
                    @test input.intruder[j].logic_mode.processing == expected["intruder"][i]["logic_mode"]["processing"]
                    @test input.intruder[j].logic_mode.dna == expected["intruder"][i]["logic_mode"]["dna"]
                    @test input.intruder[j].logic_mode.protection_mode == expected["intruder"][i]["logic_mode"]["protection_mode"]
                end
            end
            if found == false
                error("TRM Designation ID match failed")
            end
        end
    end
end


function TRM_Broadcast_Test(input, expected)
    #ra_data

    @test input.ra_data.avra_single_intent == expected["ra_data"]["avra_single_intent"]
    @test input.ra_data.avra_crossing == expected["ra_data"]["avra_crossing"]
    @test input.ra_data.avra_down == expected["ra_data"]["avra_down"]
    @test input.ra_data.avra_strength == expected["ra_data"]["avra_strength"]
    @test input.ra_data.ldi == expected["ra_data"]["ldi"]
    @test input.ra_data.rmf == expected["ra_data"]["rmf"]
    @test input.ra_data.rac == expected["ra_data"]["rac"]
    @test input.ra_data.rat == expected["ra_data"]["rat"]
    @test input.ra_data.mte == expected["ra_data"]["mte"]

    @test input.spi == expected["spi"]
    @test input.aid == expected["aid"]
    @test input.cac == expected["cac"]
end

function TRM_Ground_Msg_Test(input, expected)
    @test input.ra_data.avra_single_intent == expected["ra_data"]["avra_single_intent"]
    @test input.ra_data.avra_crossing == expected["ra_data"]["avra_crossing"]
    @test input.ra_data.avra_down == expected["ra_data"]["avra_down"]
    @test input.ra_data.avra_strength == expected["ra_data"]["avra_strength"]
    @test input.ra_data.ldi == expected["ra_data"]["ldi"]
    @test input.ra_data.rmf == expected["ra_data"]["rmf"]
    @test input.ra_data.rac == expected["ra_data"]["rac"]
    @test input.ra_data.rat == expected["ra_data"]["rat"]
    @test input.ra_data.mte == expected["ra_data"]["mte"]

    @test input.tti == expected["tti"]
    @test input.dsi == expected["dsi"]
    @test input.spi == expected["spi"]

    if expected["tid"]["tid_type"] == 1
        #address
        @test input.tid.tid == expected["tid"]["address"]["tid"]
    elseif expected["tid"]["tid_type"] == 0
        @test input.tid.tida == expected["tid"]["altrngbrg"]["tida"]
        @test input.tid.tidr == expected["tid"]["altrngbrg"]["tidr"]
        @test input.tid.tidb == expected["tid"]["altrngbrg"]["tidb"]
    else 
        error("Unexpected TID Type $(expected["tid"]["tid_type"])")
    end
end

function TRM_Debug_Data_Test(input, expected)
    @test input.alert == expected["alert"]
    #println("$(input.dz_min) $(expected["dz_min"])")
    @test input.dz_min == expected["dz_min"]
    @test input.dz_max == expected["dz_max"]
    @test input.ddz == expected["ddz"]

    @test length(expected["intruder"]) == length(input.intruder)

    if length(expected["intruder"]) > 0 
        for i = 1:length(expected["intruder"])
            @test input.intruder[i].id == expected["intruder"][i]["id"] 
            @test input.intruder[i].address == expected["intruder"][i]["address"] 
            @test input.intruder[i].is_icao == expected["intruder"][i]["is_icao"] 
            @test input.intruder[i].sense == expected["intruder"][i]["sense"] 
        end
    end
end

