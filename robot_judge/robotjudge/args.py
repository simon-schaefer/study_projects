import argparse
import os

import matplotlib

import robotjudge.utilities.miscellaneous
import robotjudge.constants as rc

matplotlib.use("Agg")


def parse_args_and_setup() -> argparse.Namespace:
    args = argparse.ArgumentParser(
        description="Building a Robot Judge - Measuring Language Ambiguity", usage="%(prog)s [options]"
    )
    # Data-specific arguments.
    args.add_argument(
        "--us_statue_path",
        help="Path to US Statue dataset.",
        type=str,
        default=os.path.join(rc.ENV_DATA_PATH, "us_statue"),
    )
    args.add_argument(
        "--us_campaign_path",
        help="Path to US Campaign Financing dataset.",
        type=str,
        default=os.path.join(rc.ENV_DATA_PATH, "us_campaign"),
    )
    args.add_argument("--us_statue_use_raw", help="Dont use preextracted raw file", action="store_true")
    args.add_argument("--use_year", help="Use year for analysis (or state only)", action="store_true")
    args.add_argument("--state", help="use only specific state (default all)", type=str, default="all")
    # General arguments.
    args.add_argument(
        "--logging_mode",
        help="Program logging mode. ",
        choices=["DEBUG", "INFO", "WARNING"],
        type=str,
        default=rc.DEBUG_LEVEL_DEFAULT,
    )
    # Parse arguments to namespace.
    args = args.parse_args()

    # Setup debug mode by calling misc setup function.
    robotjudge.utilities.miscellaneous.setup(debug_level=args.logging_mode)

    return args
