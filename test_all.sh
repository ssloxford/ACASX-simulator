#!/bin/bash

sudo rm -rf output_data/cost_map/test_run/
sudo rm -rf output_data/grid/test_run/
sudo rm -rf output_data/optimise/test_run/
sudo rm -rf output_data/static_strat/test_run/

echo "Basic tests" > test_results.txt
docker-compose run simulator 1 >> test_results.txt
echo "-------------------------------------------------------" >> test_results.txt
docker-compose run simulator 2 --params_file test_params/static_strat_test_params.jl --test_mode
docker-compose run simulator 3 --params_file test_params/optimise_test_params.jl --test_mode
docker-compose run simulator 4 --params_file test_params/gridder_test_params.jl --test_mode
docker-compose run simulator 5 --params_file test_params/cost_map_test_params.jl --test_mode

cd tests 
echo "Static" >> ../test_results.txt
pytest -q static_strat_test.py >> ../test_results.txt
echo "Optimise" >> ../test_results.txt
pytest -q optimizer_test.py >> ../test_results.txt
echo "Gridder" >> ../test_results.txt
pytest -q gridder_test.py >> ../test_results.txt
echo "Cost Map" >> ../test_results.txt
pytest -q costmap_test.py >> ../test_results.txt

cd ..

tail test_results.txt