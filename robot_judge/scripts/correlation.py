import logging
import os

import numpy as np
import pandas as pd

import robotjudge.args
import robotjudge.constants as rc
import robotjudge.data.us_campaign
import robotjudge.utilities.visualization as rup

import matplotlib.pyplot as plt


def main():
    args = robotjudge.args.parse_args_and_setup()
    logging.info("Collecting extracted data from USS dataset from summary.pkl")
    uss_df = pd.read_pickle(os.path.join(args.us_statue_path, "summary.pkl"))
    uss_df[rc.COL_NUM_TOKENS] = uss_df[rc.COL_NUM_TOKENS].apply(lambda x: float(x))

    state_amb = uss_df[[rc.COL_STATE, rc.COL_AMBIGUITY]].dropna().groupby(rc.COL_STATE)[rc.COL_AMBIGUITY].median()
    state_numnum = uss_df[[rc.COL_STATE, rc.COL_NUM_NUMS]].dropna().groupby(rc.COL_STATE)[rc.COL_NUM_NUMS].mean()
    state_numadj = uss_df[[rc.COL_STATE, rc.COL_NUM_ADJS]].dropna().groupby(rc.COL_STATE)[rc.COL_NUM_ADJS].mean()
    state_numtok = uss_df[[rc.COL_STATE, rc.COL_NUM_TOKENS]].dropna().groupby(rc.COL_STATE)[rc.COL_NUM_TOKENS].mean()

    usc_df = robotjudge.data.us_campaign.USCampaignFinancing(args).df
    usc_df = usc_df[usc_df[rc.COL_CONTRIB_LIMITS_INT] >= 0]
    state_contrib = usc_df.groupby(rc.COL_STATE)[rc.COL_CONTRIB_LIMITS_INT].mean()

    logging.info("Merging uss and usc dataframe")
    corr_df = pd.concat([state_contrib, state_amb, state_numnum, state_numadj, state_numtok], axis=1, sort=False)
    correlation_matrix = corr_df.dropna().corr()
    print(correlation_matrix)

    fig, ax = plt.subplots(figsize=(10, 3))
    rup.plot_table_from_df(correlation_matrix, colors=["#FFFF99", "w", "w", "w", "w"], axis=ax)
    plt.savefig(os.path.join(rc.ENV_PLOT_PATH, "corr_state_ext_table.png"))
    plt.close()


if __name__ == "__main__":
    main()
