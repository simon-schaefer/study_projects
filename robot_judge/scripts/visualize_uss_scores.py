import logging
import os

import pandas as pd

import robotjudge.args
import robotjudge.constants as rc
import robotjudge.utilities.visualization as rup

import matplotlib.pyplot as plt


def make_base_to_ambiguity_plots(df: pd.DataFrame, base_col: str, figname: str):
    df_base_amb_df = df[[base_col, rc.COL_AMBIGUITY]].dropna()
    base_amb_mean_dict = dict(df_base_amb_df.groupby(base_col)[rc.COL_AMBIGUITY].median())
    df_base_amb_df[rc.COL_AMBIGUITY_MEAN] = df_base_amb_df[base_col].apply(lambda x: base_amb_mean_dict[x])
    df_base_amb_df.sort_values(rc.COL_AMBIGUITY_MEAN, inplace=True)

    fig, ax = plt.subplots(figsize=(20, 13))
    rup.plot_state_score_boxplots(df_base_amb_df[base_col], df_base_amb_df[rc.COL_AMBIGUITY], base_col, "ambiguity", ax)
    plt.savefig(os.path.join(rc.ENV_PLOT_PATH, figname))
    plt.close()


def main():
    args = robotjudge.args.parse_args_and_setup()
    logging.info("Collecting extracted data from summary.pkl")
    uss_df = pd.read_pickle(os.path.join(args.us_statue_path, "summary.pkl"))
    uss_df[rc.COL_AMBIGUITY] = uss_df[rc.COL_AMBIGUITY].apply(lambda x: 2.0 * x)

    make_base_to_ambiguity_plots(uss_df.copy(), rc.COL_STATE, "uss_ambiguity_by_state.png")
    make_base_to_ambiguity_plots(uss_df.copy(), rc.COL_SECTOR, "uss_ambiguity_by_sector.png")

    uss_stseamb_df = uss_df[[rc.COL_STATE, rc.COL_SECTOR, rc.COL_AMBIGUITY]].dropna()
    uss_stseamb_df[rc.COL_STATE_SECTOR] = uss_stseamb_df.apply(
        lambda row: f"{row[rc.COL_STATE]}-{row[rc.COL_SECTOR]}", axis=1
    )
    stse_amb_mean_dict = dict(uss_stseamb_df.groupby(rc.COL_STATE_SECTOR)[rc.COL_AMBIGUITY].median())
    uss_stseamb_df[rc.COL_AMBIGUITY_MEAN] = uss_stseamb_df[rc.COL_STATE_SECTOR].apply(lambda x: stse_amb_mean_dict[x])
    uss_stseamb_df.sort_values(rc.COL_AMBIGUITY_MEAN, inplace=True)

    fig, ax = plt.subplots(figsize=(15, 35))
    rup.plot_state_score_boxplots(
        uss_stseamb_df[rc.COL_STATE_SECTOR], uss_stseamb_df[rc.COL_AMBIGUITY], rc.COL_STATE_SECTOR, "ambiguity", ax
    )
    plt.savefig(os.path.join(rc.ENV_PLOT_PATH, "uss_ambiguity_state_sector.png"))
    plt.close()


if __name__ == "__main__":
    main()
