import glob
import os
import logging

import tqdm

import robotjudge.args
import robotjudge.data.us_statue


def main():
    args = robotjudge.args.parse_args_and_setup()
    # Get all of the .zip archives in the corpus.
    zfiles = glob.glob(os.path.join(args.us_statue_path, "*.zip"))
    zfiles.sort()
    # Extracting zip files loop.
    logging.info(f"Start extracting {len(zfiles)} zip files")
    uss_data = robotjudge.data.us_statue.USStatueData(args)
    for ifile, fname in enumerate(tqdm.tqdm(zfiles)):
        uss_data.load_and_preprocess(fname)
        uss_data.store()


if __name__ == "__main__":
    main()
