"""
opensky_extraction_pipeline.py

A tool to convert OpenSky flights into JSON 'flights' describing a continuous series of positions, which can be used as input to the ACASX Simulator.
"""

import math
import json
import datetime
from pathlib import Path
import os
import argparse
import traceback

import more_itertools
import pandas as pd
import numpy as np


def label_flights(input_df: pd.DataFrame, split_threshold: int = 60) -> pd.DataFrame:
    """
    This method takes a group of position reports, all from the same ICAO, and labels them according to which continuous 'run' of points they are in. A run is defined as a series of points with inter-point gaps all less than *split_threshold* seconds.

    Parameters
    ----------
    input_df : pd.DataFrame
        A dataframe containing position reports originating from a single ICAO.
    split_threshold : int, optional, default: 60
        The time threshold, in seconds, used to split runs

    Returns
    -------
    tmp_copy_df : pd.DataFrame
        A dataframe containing labelled position reports, according to the flight they belong to

    Raises
    ------
    ValueError
        If the input data, after processing, contained some unlabelled flights
    """
    # First ensure the dataframe is in time order
    tmp_copy_df = input_df.copy().sort_values("timestamp").reset_index(drop=True)
    # Then get the diffs to the previous row, selecting for ones
    # greater than threshold
    splits = tmp_copy_df[(tmp_copy_df["timestamp"].diff()).dt.seconds > split_threshold]
    tmp_copy_df["flight_label"] = -1

    # If there are no splits, label everything as zero
    if splits.shape[0] == 0:
        tmp_copy_df["flight_label"] = 0
    else:
        # Otherwise label the first and last accordingly
        tmp_copy_df.loc[
            tmp_copy_df["timestamp"] < splits.iloc[0]["timestamp"], "flight_label"
        ] = 0
        tmp_copy_df.loc[
            tmp_copy_df["timestamp"] >= splits.iloc[-1]["timestamp"], "flight_label"
        ] = splits.shape[0]

        # Then label each according to the order it appears
        split_rows = [i[1]["timestamp"] for i in splits.iterrows()]

        for ts_start, ts_end, counter in zip(
            split_rows[:-1], split_rows[1:], list(range(1, len(split_rows)))
        ):
            tmp_copy_df.loc[
                (tmp_copy_df["timestamp"] >= ts_start)
                & (tmp_copy_df["timestamp"] < ts_end),
                "flight_label",
            ] = counter

    # We shouldn't have leftover flights, but if we do we want to throw
    # an error so they don't cause downstream problems
    if tmp_copy_df[tmp_copy_df["flight_label"] == -1].shape[0] > 0:
        raise ValueError("Some flights could not be labelled.")
    return tmp_copy_df


def sequence_imputer(input_df: pd.DataFrame, threshold: float = 0.8):
    """
    This method tries to fix basic data issues in a flight trajectory, mainly by either removing leading/trailing NAs, or by filling gaps with interpolation. Threshold sets the percentage of present values needed to attempt interpolation - anything lower is discarded.

    Parameters
    ----------
    input_df : pd.DataFrame
        Dataframe containing the points from a single flight, sorted by timestamp.
    threshold : float, optional, default: 0.8
        The percentage of non NA values needed to attempt interpolation

    Returns
    -------
    flight : pd.DataFrame
        DataFrame containing an imputed flight, or an empty DF if this could not be done (i.e. input was under threshold).
    """

    flight = input_df.copy()

    col = flight["baroaltitude"].values

    ratio = np.sum(flight["baroaltitude"].notna()) / len(flight)
    if ratio >= threshold:  # Fix the data
        # Need to find gaps and fill them with
        if np.isnan(col[0]):
            # Iterate through to find the first value
            first_val_idx = -1
            for i, _ in enumerate(col):
                if not np.isnan(col[i]):
                    first_val_idx = i
                    break

            # We can add backfill strategy here if we want
            # For now it's just removal

            flight = flight.iloc[first_val_idx:]
            col = flight["baroaltitude"].values

        if np.isnan(col[-1]):
            last_val_idx = -1
            for i in range(len(col) - 1, -1, -1):
                # print(i)
                if not np.isnan(col[i]):
                    last_val_idx = i
                    break

            flight = flight.iloc[: last_val_idx - 1]
            col = flight["baroaltitude"].values

        fill = False
        for i in range(len(col)):
            if np.isnan(col[i]):
                fill = True
                next_non_nan_idx = -1
                # print(f"start {i}")
                for j in range(i, len(col)):
                    if not np.isnan(col[j]):
                        next_non_nan_idx = j
                        break

                start_val = col[i - 1]
                val_diff = col[next_non_nan_idx] - col[i - 1]
                # Need to add 1 to stop the penultimate elem being col[j]
                val_step = val_diff / (next_non_nan_idx - i + 1)
                # print(f"diff {val_diff}")

                for j in range(i, next_non_nan_idx):
                    # Need to add one to make the first step be 1 otherwise the multiplier fails
                    step = j - i + 1
                    # Don't forget to have a start_val to add to
                    col[j] = start_val + val_step * step

        flight.loc[:, "baroaltitude"] = col
        return flight

    # Return an empty frame if the flight is no good
    return pd.DataFrame()


def altitude_thresholder(
    input_df: pd.DataFrame, min_alt_threshold=1250, max_alt_threshold=10000
) -> pd.DataFrame:
    """Removes flights outside of min and max altitude thresholds.

    This stage checks if the flight exceeds the bounds defined by min_alt_threshold and max_alt_threshold, returning an empty DataFrame if it does. It is a sanity check to avoid collecting erroneously high position reports, or those at very low altitudes (e.g. approaching landing).

    Parameters
    ----------
    input_df : pd.DataFrame
        Dataframe containing position reports for a flight
    min_alt_threshold : int, optional
        The lower altitude threshold, below which we drop the flight, by default 1250
    max_alt_threshold : int, optional
        The upper altitude threshold, above which we drop the flight, by default 10000

    Returns
    -------
    pd.DataFrame
        Either input_df, if it passes the checks, or an empty dataframe if not.
    """

    if (
        input_df["baroaltitude"].min() > min_alt_threshold
        and input_df["baroaltitude"].max() < max_alt_threshold
    ):
        return input_df
    else:
        return pd.DataFrame()


def spike_smoother(altitude_list: list, min_thresh: float, max_thresh: float) -> list:
    """Smooths single-point large spikes in a list of altitudes.

    This method takes a list of altitude values, and checks for large differences between consecutive altitudes. This is indicative of an erroneous position report, so we try to fix it by leveling off the spike.
    Note that this *only* works on single, large jumps. Longer jumps are harder to fix and know what is actually happening, so we don't.

    Parameters
    ----------
    altitude_list : list
        A list of altitude values, in time order.
    min_thresh : float
        The 'negative' spike threshold, i.e. for large downward/descending spikes
    max_thresh : float
        The 'positive' spike threshold, i.e. for large upward/climbing spikes

    Returns
    -------
    list
        A list of smoothed altitudes
    """

    # First get the diffs between each element
    altitude_diff_list = [b - a for a, b in more_itertools.pairwise(altitude_list)]

    for i in range(1, len(altitude_diff_list) - 1):
        # Check if the diff is a large downward or upward jump
        if altitude_diff_list[i] < min_thresh or altitude_diff_list[i] > max_thresh:
            # We now check if the next diff (i.e. following the spike) returns
            # the altitude back to the 'original' level - i.e. is it a jump
            # back down of similar magnitude
            if abs(altitude_diff_list[i] + altitude_diff_list[i + 1]) < max_thresh:
                altitude_list[i + 1] = altitude_list[i]

    return altitude_list


def check_trajectory_altitude(
    alt_data: list, min_thresh: float, max_thresh: float, tolerance: float
) -> bool:
    """Checks if a list contains large jumps in altitude, returning True if not.

    This method checks if large jumps in altitude exist in a list of consecutive barometric altitude reports. If they are, it returns False, otherwise it returns True. This method is meant to be used in conjunction with spike_smoother, which removes single point spikes first.

    Parameters
    ----------
    alt_data : list
        A list of altitudes, in time order
    min_thresh : float
        The low threshold for altitude differences, i.e. for downward jumps/descending
    max_thresh : float
        The high threshold for altitude differences, i.e. for upward jumps/ascending
    tolerance : float
        An extra tolerance factor, to allow cases where the trajectory slightly exceeds the thresholds

    Returns
    -------
    bool
        True, if there are no unacceptable jumps in the trajectory, else False.
    """
    # Make sure there's at least a pair to compare
    if len(alt_data) > 1:
        # Get consecutive diffs
        diffs = [b - a for a, b in more_itertools.pairwise(alt_data)]

        # Check if anything exceeds the thresholds
        if (max(diffs) > (max_thresh + tolerance)) or (
            min(diffs) < (min_thresh - tolerance)
        ):
            return False
        else:
            return True
    else:
        return False


def invalid_trajectory_checker(
    input_df: pd.DataFrame, min_thresh: float, max_thresh: float, tolerance: float
) -> pd.DataFrame:
    """Smooths any small altitude spikes, then checks if any other large spikes exist.

    This method first smooths any single-point altitude spikes, which sometimes occur in the data. After this is done, it checks for larger jumps (i.e. cases when a spike happens and lasts for a few seconds) - if they exist, an empty DataFrame is returned to remove this trajectory, else the flight with the smoothed altitude is returned.

    Parameters
    ----------
    input_df : pd.DataFrame
        Input flight position reports
    min_thresh : float
        The lower threshold for altitude differences, for the downward/descending jump case
    max_thresh : float
        The uper threshold for altitude differences, for the upward/climbing jump case
    tolerance : float
        A tolerance factor to allow for small jitters beyond the threshold, when checking trajectory validity

    Returns
    -------
    pd.DataFrame
        Either the flight with spikes removed, if the trajectory is valid, otherwise an empty DataFrame
    """
    flight = input_df.copy()
    # Smoothes single point spikes
    flight.loc[:, "baroaltitude"] = spike_smoother(
        flight["baroaltitude"].tolist(), min_thresh, max_thresh
    )

    # Now we check if there are still any large spikes, e.g. caused by
    # big jumps up then down, or just a big jump which is then maintained
    # We could try to fix this but it is hard to know the ground truth
    if check_trajectory_altitude(
        flight["baroaltitude"].tolist(), min_thresh, max_thresh, tolerance
    ):
        return flight
    else:
        return pd.DataFrame()


def json_serial(obj: object) -> float:
    """Checks if the passed object is a Datetime and serialises it.

    Parameters
    ----------
    obj : object
        An object to serialise.

    Returns
    -------
    float
        A timestamp representing the inputted datetime object.

    Raises
    ------
    TypeError
        If the provided object is not a datetime
    """
    if isinstance(obj, datetime.datetime):
        return math.floor(obj.timestamp())
    raise TypeError(f"Type {type(obj)} not serializable")


def save_flights_to_json(input_df: pd.DataFrame, path: Path):
    """Saves a flight to JSON

    Given some input flight data, saves it to a JSON file in the directory provided in path.

    Parameters
    ----------
    input_df : pd.DataFrame
        Cleaned, input flight data
    path : Path
        The directory to save the flight to

    Raises
    ------
    ValueError
        If NAs are found in the flight.
    """
    time = input_df["timestamp"].iloc[0].strftime("%Y%m%d-%H%M%S")
    if input_df["baroaltitude"].notna().values.all():
        output = {}
        # Create the metadata for the flight
        output["metadata"] = {
            "min_alt": input_df["baroaltitude"].min(),
            "max_alt": input_df["baroaltitude"].max(),
            "mid_alt": input_df["baroaltitude"].iloc[
                math.floor(len(input_df["baroaltitude"]) / 2)
            ],
            "first_alt": input_df["baroaltitude"].iloc[0],
            "last_alt": input_df["baroaltitude"].iloc[-1],
        }
        output["data"] = input_df.to_dict(orient="records")

        # Dump to JSON
        with open(
            os.path.join(path, "{}-{}.json".format(input_df.iloc[0]["icao24"], time)),
            "w",
        ) as f:
            json.dump(output, f, default=json_serial)
    else:
        raise ValueError(
            "NAs found in exported Dataframe: {} {}".format(
                input_df.iloc[0]["icao24"], time
            )
        )


def basic_cleaning(input_df: pd.DataFrame) -> pd.DataFrame:
    """Performs basic cleaning on the input data.

    This method sets up the DataFrame for the pipeline, including creating a proper timestamp column and removing unused columns.

    Parameters
    ----------
    input_df : pd.DataFrame
        DataFrame containing OpenSky position reports

    Returns
    -------
    pd.DataFrame
        A DataFrame with basic cleaning performed.
    """
    input_df["timestamp"] = pd.to_datetime(input_df["time"], unit="s")
    input_df.drop(columns=["geoaltitude"], inplace=True)
    return input_df


def label_points_into_flights(input_df: pd.DataFrame) -> pd.DataFrame:
    """Wrapper function for the flight labelling stage of the pipeline.

    Parameters
    ----------
    input_df : pd.DataFrame
        Input DataFrame, containing OpenSky position reports.

    Returns
    -------
    pd.DataFrame
        A DataFrame where each flight by each ICAO is labelled. Note that labels are only unique within an ICAO, not across the whole DF.
    """
    return input_df.groupby(["icao24"]).apply(label_flights).reset_index(drop=True)


def impute_missing_flight_points(input_df: pd.DataFrame, tolerance=0.8) -> pd.DataFrame:
    """Wrapper function for missing altitude imputation.

    Parameters
    ----------
    input_df : pd.DataFrame
        DataFrame containing labelled flight position reports
    tolerance : float, optional
        Percentage of values in a flight required to be present, in order for imputation to occur, by default 0.8

    Returns
    -------
    pd.DataFrame
        A DataFrame containing imputed, labelled flights, with those falling below the threshold discarded.
    """
    return (
        input_df.groupby(["icao24", "flight_label"])
        .apply(sequence_imputer, tolerance)
        .reset_index(drop=True)
    )


def threshold_flights_by_altitude_range(
    input_df: pd.DataFrame, min_alt_threshold=1250, max_alt_threshold=10000
) -> pd.DataFrame:
    """Wrapper function for altitude thresholding stage.

    Parameters
    ----------
    input_df : pd.DataFrame
        DataFrame containing labelled, imputed flights
    min_alt_threshold : int, optional
        Altitude lower bound, in metres, by default 1250
    max_alt_threshold : int, optional
        Altitude upper bound, in metres, by default 10000

    Returns
    -------
    pd.DataFrame
        DataFrame containing only flights occuring within the defined altitude boundaries
    """
    return (
        input_df.groupby(["icao24", "flight_label"])
        .apply(altitude_thresholder, min_alt_threshold, max_alt_threshold)
        .reset_index(drop=True)
    )


def remove_invalid_trajectories(
    input_df: pd.DataFrame, min_threshold: float, max_threshold: float, tolerance: float
) -> pd.DataFrame:
    """Wrapper function for spike smoothing/throwing away discontinuous trajectories.

    Parameters
    ----------
    input_df : pd.DataFrame
        DataFrame containing imputed, labelled and altitude bounded position reports.
    min_threshold : float
        The maximum allowable descent/downward jump between two altitudes
    max_threshold : float
        The maximum allowable climb/upward jump between two altitudes
    tolerance : float
        A jitter factor to allow flights which come close to this boundary to not be dropped

    Returns
    -------
    pd.DataFrame
        A DataFrame containing only flights which have been smoothed and no not have discontinuous trajectories.
    """
    return (
        input_df.groupby(["icao24", "flight_label"])
        .apply(invalid_trajectory_checker, min_threshold, max_threshold, tolerance)
        .reset_index(drop=True)
    )


def export_flights(input_df: pd.DataFrame, output_path: Path) -> pd.DataFrame:
    """Wrapper to export all flights in the input_df to JSON

    Parameters
    ----------
    input_df : pd.DataFrame
        Flight data points to export
    output_path : Path
        Directory path to export JSON files to.

    Returns
    -------
    pd.DataFrame
        Input Dataframe
    """
    return input_df.groupby(["icao24", "flight_label"]).apply(
        save_flights_to_json, output_path
    )


def run_pipeline(input_path: Path, output_path: Path, args: argparse.Namespace):
    """Wrapper to run the processing pipeline and export the results.

    Parameters
    ----------
    input_path : Path
        Path pointing to a HDF file to process.
    output_path : Path
        Path pointing to a directory to export JSON files to.
    args : argparse.Namespace
        Parsed command line arguments.
    """
    (
        pd.read_hdf(input_path)
        .pipe(basic_cleaning)
        .pipe(label_points_into_flights)
        .pipe(impute_missing_flight_points, tolerance=args.impute_tolerance)
        .pipe(
            threshold_flights_by_altitude_range,
            min_alt_threshold=args.altitude_min,
            max_alt_threshold=args.altitude_max,
        )
        .pipe(
            remove_invalid_trajectories,
            min_threshold=args.invalid_min_threshold,
            max_threshold=args.invalid_max_threshold,
            tolerance=args.invalid_tolerance,
        )
        .pipe(export_flights, output_path=output_path)
    )


if __name__ == "__main__":
    # Parse args

    DESCENT_FPM = 4500
    CLIMB_FPM = 5000

    # need this in meters per second
    DEFAULT_INVALID_MAX_THRESHOLD = CLIMB_FPM / 3.281 / 60
    DEFAULT_INVALID_MIN_THRESHOLD = -DESCENT_FPM / 3.281 / 60
    DEFAULT_INVALID_TOLERANCE = 5

    DEFAULT_IMPUTE_TOLERANCE = 0.8

    DEFAULT_ALTITUDE_MIN = 1250
    DEFAULT_ALTITUDE_MAX = 10000

    parser = argparse.ArgumentParser(
        description="Data processing pipeline to convert HDFs containing OpenSky position reports into a series of JSON files, each containing one flight",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument(
        "input_path", type=str, help="Directory or HDF file to process."
    )
    parser.add_argument(
        "output_path", type=str, help="Directory to save exported JSON files to."
    )
    parser.add_argument(
        "--impute_tolerance",
        type=float,
        help="Percentage threshold for flight altitude imputation - if a flight has a lower percentage of present values than this, it is dropped.",
        default=DEFAULT_IMPUTE_TOLERANCE,
    )
    parser.add_argument(
        "--invalid_max_threshold",
        type=float,
        help="Threshold for maximum altitude climb between two points (in metres/sec).",
        default=DEFAULT_INVALID_MAX_THRESHOLD,
    )
    parser.add_argument(
        "--invalid_min_threshold",
        type=float,
        help="Threshold for maximum altitude descent between two points (in metres/sec).",
        default=DEFAULT_INVALID_MIN_THRESHOLD,
    )
    parser.add_argument(
        "--invalid_tolerance",
        type=float,
        help="Tolerance value to allow jitters past the invalid min and max thresholds.",
        default=DEFAULT_INVALID_TOLERANCE,
    )
    parser.add_argument(
        "--altitude_min",
        type=float,
        help="Lower bound of acceptable altitudes (in metres).",
        default=DEFAULT_ALTITUDE_MIN,
    )
    parser.add_argument(
        "--altitude_max",
        type=float,
        help="Upper bound of acceptable altitudes (in metres).",
        default=DEFAULT_ALTITUDE_MAX,
    )

    args = parser.parse_args()

    # Check input path exists
    input_path = Path(args.input_path)
    output_path = Path(args.output_path)

    if not output_path.exists():
        output_path.mkdir(parents=True, exist_ok=True)

    if input_path.exists():
        if not input_path.is_dir():
            run_pipeline(input_path, output_path, args)
        else:
            for path in input_path.iterdir():
                print("Processing {}".format(path))
                try:
                    run_pipeline(path, output_path, args)
                except:
                    print("Error on {}".format(path))
                    traceback.print_exc()
