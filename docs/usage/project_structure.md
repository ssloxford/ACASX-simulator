Project Structure
=================

There are a lot of parts to this project, so this page aims to explain them and how they fit together.

```
ACASX/
├── code/
│   ├── do385_data/
│   ├── standardised_code/
│   ├── test_params/
│   └── tests/    
├── docker-utils/
├── docs/
├── input_data/
├── output_data/
├── tests/
├── tools/
├── README.md
├── acasx.dockerfile
├── baseline_output.tgz
├── docker-compose.yml
└── test_all.sh
```

## Docker

The project is set up to be run using Docker - this is configured with two files
* `acas.dockerfile` - this sets up the container containing the code, and is setup to use entrypoint. This means you can run it as if you were just running the `main_opt_refactor.jl` script, passing args after `docker-compose run simulator`. You should not need to edit this file.
* `docker-compose.yml` - defines the containers and volumes. You may need to set this up for your own use-case, specifically changing the local location of your input and output directories.

## Input and Output

Using default settings, you will need `input_data` and `output_data` directories in your ACASX directory. This matches up roughly to inside the container - e.g. inputting from `input_data/frankfurt_data` will load to `/input_data/frankfurt_data/`, and the same for output data.

## Code 
This directory contains all the code for the simulator. This is volume mounted to Docker so you do not need to rebuild each time. You should not need to edit anything in:
* `do385_data` - contains DO-385 data files
* `standardised_code` - contains DO-385 code
* `tests` - contains DO-385 testing code
* `test_params` - contains baseline tests

The entrypoint is currently called `main_opt_refactor.jl`, which takes command line arguments. 

## Docs

You will need `Python 3`, `sphinx` and `recommonmark` to build these docs. Run `make html` in this directory to generate docs, which can then be viewed in a web browser, using:
```
cd docs/_build/html/
python3 -m http.server [PORT]
```

## Tests 

Pytest code for baseline tests - you probably will not need to use these, but if you do, just install `pytest` then run `./test_all` from the root directory. See [here](test_details.md)

## Tools

This contains a pipeline to process Opensky data and produce trajectory JSON files. See [here](input_data.md)
