import collections
import logging
from typing import Any, List

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import plotly.graph_objects as go


def plot_string_histogram(string_list: List[str], title: str, axis: plt.Axes):
    """Plot frequency of unique strings in list in matplotlib axis."""
    logging.info("Plotting frequency of unique strings")
    letter_counts = dict(collections.Counter(string_list))
    axis.bar(letter_counts.keys(), letter_counts.values())
    axis.set_title(title)


def plot_year_state_data(years: List[int], states: List[str], data: List[Any], axis: plt.Axes):
    """Plot years, states and labels as grid of available labels per year and state."""
    assert len(years) == len(states) == len(data)
    logging.info("Plotting year-state-data distribution on a grid")
    state_dict = {state: state_id for state_id, state in enumerate(np.unique(states))}
    num_states = len(state_dict.keys())
    year_dict = {year: year_id for year_id, year in enumerate(np.unique(years))}
    num_years = len(year_dict.keys())
    data_dict = {x: x_id for x_id, x in enumerate(np.unique(data))}

    matches = np.ones((num_states, num_years)) * (-1)
    for state, year, x in zip(states, years, data):
        matches[state_dict[state], year_dict[year]] = data_dict[x]

    sns.heatmap(matches.T, linewidths=0.1, cbar_kws={"ticks": np.arange(-1, 3).tolist()}, ax=axis)
    axis.set_xticklabels(list(state_dict.keys()))
    axis.set_yticklabels(list(year_dict.keys()))


def plot_us_state_data(states: List[str], data: List[Any]):
    """Plot data on US state map, using plotly graph objects, save created image under fname file."""
    assert len(states) == len(data)
    logging.info("Plotting and showing data on US state map")
    fig = go.Figure(
        data=go.Choropleth(
            locations=states,  # Spatial coordinates
            z=data,  # Data to be color-coded
            locationmode="USA-states",  # set of locations match entries in `locations`
            colorscale="Reds",
            colorbar_title="",
        )
    )
    fig.update_layout(geo_scope="usa")  # limite map scope to USA)
    fig.show()


def plot_hist_chart(scores: List[float], label: str, axis: plt.Axes):
    """Plot histogram chart from distribution of scores."""
    logging.info("Plotting histogram chart from distribution of scores")
    axis.hist(scores, bins=20, range=(0.0, 1.0))
    axis.set_xlabel(label)
    axis.set_ylabel("Frequency")


def plot_state_score_boxplots(bases: List[str], scores: List[float], base_label: str, score_label: str, axis: plt.Axes):
    """Plot score distribution over states in boxplot plot. Values are expected to be presorted."""
    logging.info(f"Plotting {base_label} - {score_label} - boxplot plot")
    sns.boxplot(x=scores, y=bases)
    axis.set_xlabel(score_label)
    axis.set_ylabel(base_label)


def plot_table_from_df(df: pd.DataFrame, colors: List[str], axis: plt.Axes):
    """Plot table from dataframe in mmatplotlib axis."""
    cell_text = []
    for row in range(len(df)):
        cell_text.append(df.iloc[row])
    cell_colors = [colors for _ in range(len(df.columns))]
    head_colors = ["#FF0000" for _ in range(len(df.columns))]
    axis.table(cellText=cell_text, colLabels=df.columns, cellColours=cell_colors, colColours=head_colors, loc='center')
    axis.axis('off')
