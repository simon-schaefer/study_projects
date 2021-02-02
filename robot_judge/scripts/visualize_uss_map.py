import logging
import os

import pandas as pd

import robotjudge.args
import robotjudge.constants as rc
import robotjudge.data.us_campaign
import robotjudge.utilities.visualization as rup


def main():
    args = robotjudge.args.parse_args_and_setup()
    logging.info("Collecting extracted data from summary.pkl")
    uss_df = pd.read_pickle(os.path.join(args.us_statue_path, "summary.pkl"))
    uss_df[rc.COL_AMBIGUITY] = uss_df[rc.COL_AMBIGUITY].apply(lambda x: 2.0 * x)

    df_state_amb_df = uss_df[[rc.COL_STATE, rc.COL_AMBIGUITY]].dropna()
    df_state_amb_dict = dict(df_state_amb_df.groupby(rc.COL_STATE)[rc.COL_AMBIGUITY].median())
    states, scores = [], []
    for state, score in df_state_amb_dict.items():
        states.append(state)
        scores.append(score)

    rup.plot_us_state_data(states, scores)


if __name__ == "__main__":
    main()
