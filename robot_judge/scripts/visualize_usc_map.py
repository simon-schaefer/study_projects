import robotjudge.args
import robotjudge.constants as rc
import robotjudge.data.us_campaign
import robotjudge.utilities.visualization as rup


def main():
    args = robotjudge.args.parse_args_and_setup()
    usc_df = robotjudge.data.us_campaign.USCampaignFinancing(args).df

    states, data = [], []
    for _, row in usc_df.iterrows():
        if row[rc.COL_YEAR] == 1999:
            states.append(row[rc.COL_STATE])
            data.append(row[rc.COL_CONTRIB_LIMITS_INT])

    rup.plot_us_state_data(states, data)


if __name__ == "__main__":
    main()
