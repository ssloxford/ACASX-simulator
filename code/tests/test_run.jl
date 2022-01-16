function run_tests(ac, test_input)

    for i in 1:length(test_input["StmOutput"]["acasx_reports"])
        LoggerTool.debug(logger, "Testing iter $i - ")
        b = test_input["StmOutput"]["acasx_reports"][i]["acas_xaxo_do385"]
        a = ac.state_log[i]
        STM_Report_Test(a.stm_report, b["stm_report"])
        LoggerTool.debug(logger, "\tIter $i STM Report Test Passed...")
    
        ext_trm = test_input["TrmOutput"]["acasx_reports"][i]["acas_xaxo_do385"]["trm_report"]
    
        TRM_Report_Test(a.trm_report, ext_trm)
        LoggerTool.debug(logger, "\tIter $i TRM Report Test Passed...") 
    end

    LoggerTool.info(logger, "Tests Passed!")
end

function run_test_group(group)
    tests = LoadEncounterGroup(PARAM_TEST_ENCOUNTERS_PATH, group)

    failed_tests = Array(UTF8String, 0)

    for i in keys(tests)
        ac = Aircraft.AircraftInstance()

        prescriptive = tests[i]["Input"]["playback_header"]["description"]["info"]["prescriptive"]

        if prescriptive == true
            # This is for the single reachback test
            if i == "Encounter3303"
                run_test_mode_acasx(
                    ac, 
                    tests[i], 
                    true, 
                    prescriptive
                )
            else 
                run_test_mode_acasx(
                    ac, 
                    tests[i], 
                    false, 
                    prescriptive
                )
            end
            LoggerTool.info(logger, "Testing $i")
            try
                run_tests(ac, tests[i])
                
            catch y
                LoggerTool.debug(logger, "Failing $i")
                push!(failed_tests, i)
                LoggerTool.debug(logger, y)
            end 
            Aircraft.reset()
            LoggerTool.debug(logger, "Resetting...")
        else
            LoggerTool.info(logger, "Test $i is not prescriptive. Passing...")
        end

    end

    LoggerTool.info(logger, "Failed the following tests: ")
    for i in failed_tests
        LoggerTool.info(logger, i)
    end
    return failed_tests
end

function run_all_test_groups()
    failed_tests = Array(UTF8String, 0)

    for i in 1:7
        append!(failed_tests, run_test_group(i))
    end

    LoggerTool.info(logger, "Testing finished.")

    if length(failed_tests) == 0
        LoggerTool.info(logger, "No tests failed.")
    else
        LoggerTool.warn(logger, "The following tests failed:")
        for i in failed_tests
            LoggerTool.warn(logger, i)
        end
    end
end


function run_single_input(test_id, output_logs)
    test = LoadSingleEncounter(PARAM_TEST_ENCOUNTERS_PATH, test_id)
    encounter_name = "Encounter$test_id"

    ac = Aircraft.AircraftInstance()

    LoggerTool.info(logger, "Running $encounter_name")

    #Collect whether prescriptive or not 
    prescriptive = test[encounter_name]["Input"]["playback_header"]["description"]["info"]["prescriptive"]
    
    # If this is a prescriptive test, then we run it, 
    # Otherwise it is a Mode C test so we don't bother.
    if prescriptive == true
        if test_id == 3303
            run_test_mode_acasx(
                ac, 
                test[encounter_name], 
                true, 
                prescriptive
            )
        else 
            run_test_mode_acasx(
                ac, 
                test[encounter_name], 
                false, 
                prescriptive
            )
        end
    else
        LoggerTool.debug(logger, "Test $test_id is not prescriptive, passing.")
    end

    if output_logs == true
        dump_logs(ac, "output/", test_id)
    end

    return ac
end
