Simulating Attacks
===================

Taken from Params.jl, referencing 'mode' field:


Strategy Structure
------------------
The fields in a strategy dictionary are as follows:

* `run_name`: identifier for this run - must be unique.
* `mode`: running mode of sim, see below.
* `start_alt_delta`: difference in height that attacker will start from target. This may not be used in some modes.
* `end_alt_delta`: difference in height that attacker will end from target. This may not be used in some modes.
* `rate`: rate of change of altitude of attacker.
* `attacker_pos`: position of the attacker relative to the trajectory.
    * `1` for under the middle lat/lon
    * `0` for under the end lat/lon


Simulation Modes
----------------

Non-adaptive - altitudes are based on a fixed crossover position, i.e. we take the ownship altitude at some point x and do all of our calculations based on that. For example if we have the crossover at 0.5 of the run, we take the ownship altitude at half way through the trajectory, then set our start and end altitudes based on that

* 0 - Fixed start and end altitude, non-adaptive
    * This simply calculates the rate based on the number of steps in the run and the start and end altitudes (i.e. (start+end)/#steps). Crossover altitude is above the attacker_pos
    * Params needed: 
        * `start_alt_delta`
        * `end_alt_delta`
        * `attacker_pos`
* 1 - Fixed start and rate, no bounding, non-adaptive
    * The sim simply changes by rate every step starting from the start     altitude. Crossover altitude is above attacker pos, and the attacker will continue to change by rate until the end of the run 
    * Params needed: 
        * `start_alt_delta`
        * `rate`
        * `attacker_pos`
* 2 - Fixed start, end, rate, non-adaptive
    * Same as 1 but when the aircraft hits the end altitude it stops changing by rate, i.e. is bounded by it.
    * Params needed: 
        * `start_alt_delta`
        * `end_alt_delta`
        * `rate`
        * `attacker_pos`
* 3 - Crossover point and rate, non-adaptive
    * The altitude of the ownship at cross_point is used as crossover point against which the start and end altitude of the attacker is selected. 
    * The start and end alt of the attacker is calculated using the rate, so if the rate is 50, then the start altitude is `own_alt[cross_point] - (run_length*cross_point)*rate` and the end alt is `own_alt[cross_point] + (run_length*(1-cross_point))*rate`