from pathlib import Path
import difflib

import pytest

BASELINE_PATH = Path("../output_data/static_strat/baseline_run")
TEST_PATH = Path("../output_data/static_strat/test_run")


class TestACASXOutput:
    def test_dir_existence(self):
        assert BASELINE_PATH.exists()
        assert TEST_PATH.exists()

    def test_test_log_dir_existence(self):
        grid_dir = TEST_PATH / "logs/"
        assert grid_dir.exists()

    def test_test_cost_dir_existence(self):
        cost_dir = TEST_PATH / "costs/"
        assert cost_dir.exists()

    def test_test_strategy_dir_existence(self):
        strategy_dir = TEST_PATH / "strats/"
        assert strategy_dir.exists()

    def test_test_grid_dir_existence(self):
        grid_dir = TEST_PATH / "grid/"
        assert grid_dir.exists()

    def test_baseline_log_dir_existence(self):
        grid_dir = BASELINE_PATH / "logs/"
        assert grid_dir.exists()

    def test_baseline_cost_dir_existence(self):
        cost_dir = BASELINE_PATH / "costs/"
        assert cost_dir.exists()

    def test_baseline_strategy_dir_existence(self):
        strategy_dir = BASELINE_PATH / "strats/"
        assert strategy_dir.exists()

    def test_baseline_grid_dir_existence(self):
        grid_dir = BASELINE_PATH / "grid/"
        assert grid_dir.exists()

    def test_log_filename_match(self):
        baseline_log_path = BASELINE_PATH / "logs/"
        test_log_path = TEST_PATH / "logs/"
        baseline_logs = sorted([i.stem.lower() for i in baseline_log_path.glob("*.json")])
        test_logs = sorted([i.stem.lower() for i in test_log_path.glob("*.json")])

        # Compare that logs exist for each
        assert baseline_logs == test_logs

    def test_log_files(self):
        test_log_path = TEST_PATH / "logs/"
        baseline_log_path = BASELINE_PATH / "logs/"
        test_files = [i.name for i in test_log_path.glob("*.json")]

        for baseline_file in baseline_log_path.glob("*.json"):
            with open(baseline_file, "r") as f:
                baseline_file_data = f.read()
            
            fname = None
            for i in test_files:
                if i.lower() == baseline_file.name.lower():
                    fname = i
            
            assert fname is not None

            with open(test_log_path / fname, "r") as f:
                test_file_data = f.read()
            assert baseline_file_data.lower() == test_file_data.lower()


if __name__ == "__main__":
    print("Hi")
