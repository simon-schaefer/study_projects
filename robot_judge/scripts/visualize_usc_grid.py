import os

import robotjudge.args
import robotjudge.constants as rc
import robotjudge.data.us_campaign
import robotjudge.utilities.visualization as rup

import matplotlib.pyplot as plt


def main():
    args = robotjudge.args.parse_args_and_setup()
    usc_df = robotjudge.data.us_campaign.USCampaignFinancing(args).df

    fig, ax = plt.subplots(figsize=(20, 13))
    rup.plot_year_state_data(usc_df[rc.COL_YEAR], usc_df[rc.COL_STATE], usc_df[rc.COL_CONTRIB_LIMITS], ax)
    plt.savefig(os.path.join(rc.ENV_PLOT_PATH, "usc_state_years.png"))
    plt.close()


if __name__ == "__main__":
    main()
