# optimisation_handler.jl

## optimise
```
Wrapper function to optimise attacks against each trajectory in the given list, from the two static attacker positions, mid- and end-of trajectory.

Parameters
----------
trajectory_list : list
    List of trajectories to use in this optimisation run
```

## gridder
```
Wrapper function to optimise attacks against a each trajectory in the given list, across all positions in a predefined grid of attacker positions.

Parameters
----------
trajectory_list : list
    List of trajectories to use in this optimisation run
```

## trajectory_optimiser

```
Main optimisation loop - for each trajectory in trajectory_filenames, this performs an initial loop then tries to optimise the attacker strategy according to our cost function until it either cannot improve, or hits MAX_ITER.

Parameters
----------
trajectory_filenames : list
    List of trajectory filenames being used in this optimisation run
grid_mide : bool 
    True if running in grid mode, where we are defining a grid of coordinate pairs for attacker positions 
attacker_lat : float
    Attacker latitude, only set if we are in grid mode
attacker_lon : float 
    Attacker longitude, only set if we are in grid mode 
grid_id : string 
    Name of the grid to be used in saving, if we are in grid mode.
```

### Notes
This is the main control loop for the optimisation function of the simulator. 
    
It loads trajectories and randomly selects some according to the simulation parameters set. It then tries to find the optimal strategy for the attacker, i.e. the one which causes the maximum disruption according to our cost function.
    
For each trajectory, it performs an initialisation run (either based on a fixed start strategy defined in params.jl, or a random one, controlled by PARAM_RANDOM_START), then performs a sort of gradient ascent to try to find the best combination of strategy parameters. It does this for PARAM_MAX_ITER steps.

At any step, if the optimisation for a given trajectory cannot find a new higher cost in the neighbouring options, it traverses a ridge for up to PARAM_RIDGE_COUNT_THRESHOLD steps. This allows it to walk along plateaus in the hope of reaching further maxima. 

If either no higher neighbouring costs are available or we exceed PARAM_RIDGE_COUNT_THRESHOLD, we either stop the optimisation or restart if PARAM_RANDOM_RESTART is set.

This method outputs, for each trajectory, a log of the best (max) costs, best trajectory and the internal STM, TRM and Ownship state at the end of each iteration.