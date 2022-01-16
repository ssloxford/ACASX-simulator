from pathlib import Path
import difflib

import pytest

BASELINE_PATH = Path("../output_data/cost_map/baseline_run")
TEST_PATH = Path("../output_data/cost_map/test_run")


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
    
    def test_test_costmap_dir_existence(self):
        grid_dir = TEST_PATH / "cost_map/"
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
    
    def test_baseline_costmap_dir_existence(self):
        grid_dir = BASELINE_PATH / "cost_map/"
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

    # def test_cost_filename_match(self):
    #     baseline_log_path = BASELINE_PATH / "costs/"
    #     test_log_path = TEST_PATH / "costs/"
    #     baseline_costs = sorted([i.stem.lower() for i in baseline_log_path.glob("*.json")])
    #     test_costs = sorted([i.stem.lower() for i in test_log_path.glob("*.json")])

    #     # Compare that logs exist for each
    #     assert baseline_costs == test_costs

    # def test_cost_files(self):
    #     test_cost_path = TEST_PATH / "costs/"
    #     baseline_cost_path = BASELINE_PATH / "costs/"
    #     test_files = [i.name for i in test_cost_path.glob("*.json")]

    #     for baseline_file in baseline_cost_path.glob("*.json"):
    #         with open(baseline_file, "r") as f:
    #             baseline_file_data = f.read()
            
    #         fname = None
    #         for i in test_files:
    #             if i.lower() == baseline_file.name.lower():
    #                 fname = i
            
    #         assert fname is not None

    #         with open(test_cost_path / fname, "r") as f:
    #             test_file_data = f.read()
    #         assert baseline_file_data.lower() == test_file_data.lower()

    # def test_strat_filename_match(self):
    #     baseline_log_path = BASELINE_PATH / "strats/"
    #     test_log_path = TEST_PATH / "strats/"
    #     baseline_strats = sorted([i.stem.lower() for i in baseline_log_path.glob("*.json")])
    #     test_strats = sorted([i.stem.lower() for i in test_log_path.glob("*.json")])

    #     # Compare that logs exist for each
    #     assert baseline_strats == test_strats

    # def test_strat_files(self):
    #     test_strat_path = TEST_PATH / "strats/"
    #     baseline_strat_path = BASELINE_PATH / "strats/"
    #     test_files = [i.name for i in test_strat_path.glob("*.json")]

    #     for baseline_file in baseline_strat_path.glob("*.json"):
    #         with open(baseline_file, "r") as f:
    #             baseline_file_data = f.read()
            
    #         fname = None
    #         for i in test_files:
    #             if i.lower() == baseline_file.name.lower():
    #                 fname = i
            
    #         assert fname is not None

    #         with open(test_strat_path / fname, "r") as f:
    #             test_file_data = f.read()
    #         assert baseline_file_data.lower() == test_file_data.lower()

    # def test_grid_filename_match(self):
    #     baseline_log_path = BASELINE_PATH / "grid/"
    #     test_log_path = TEST_PATH / "grid/"
    #     baseline_grid = sorted([i.stem.lower() for i in baseline_log_path.glob("*.json")])
    #     test_grid = sorted([i.stem.lower() for i in test_log_path.glob("*.json")])

    #     # Compare that logs exist for each
    #     assert baseline_grid == test_grid

    # def test_grid_files(self):
    #     test_grid_path = TEST_PATH / "grid/"
    #     baseline_grid_path = BASELINE_PATH / "grid/"
    #     test_files = [i.name for i in test_grid_path.glob("*.json")]

    #     for baseline_file in baseline_grid_path.glob("*.json"):
    #         with open(baseline_file, "r") as f:
    #             baseline_file_data = f.read()
            
    #         fname = None
    #         for i in test_files:
    #             if i.lower() == baseline_file.name.lower():
    #                 fname = i
            
    #         assert fname is not None

    #         with open(test_grid_path / fname, "r") as f:
    #             test_file_data = f.read()
    #         assert baseline_file_data.lower() == test_file_data.lower()

    def test_costmap_filename_match(self):
        baseline_costmap_path = BASELINE_PATH / "cost_map/"
        test_costmap_path = TEST_PATH / "cost_map/"
        baseline_costmaps = sorted([i.stem.lower() for i in baseline_costmap_path.glob("*.json")])
        test_costmaps = sorted([i.stem.lower() for i in test_costmap_path.glob("*.json")])

        # Compare that logs exist for each
        assert baseline_costmaps == test_costmaps

    def test_costmap_files(self):
        test_costmap_path = TEST_PATH / "cost_map/"
        baseline_costmap_path = BASELINE_PATH / "cost_map/"
        test_files = [i.name for i in test_costmap_path.glob("*.json")]

        for baseline_file in baseline_costmap_path.glob("*.json"):
            with open(baseline_file, "r") as f:
                baseline_file_data = f.read()
            
            fname = None
            for i in test_files:
                if i.lower() == baseline_file.name.lower():
                    fname = i
            
            assert fname is not None

            with open(test_costmap_path / fname, "r") as f:
                test_file_data = f.read()
            assert baseline_file_data.lower() == test_file_data.lower()


if __name__ == "__main__":
    print("Hi")
