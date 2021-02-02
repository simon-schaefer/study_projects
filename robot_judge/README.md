# Building a Robot Judge: Data Science for the Law
This work analyzes the impact of campaign contributions on the ambiguity of US 
state law. Therefore an ambiguity score for each state bill is determined using
a word-sense-disambiguation and sense-similarity based algorithm and compared 
to the campaign contribution limits of each US state. While a correlation 
between the ambiguity of the analyzed bills and the campaign contribution 
limits can be shown, it is not large, neither varying much between different 
states nor industry sectors the bills are clustered to.  

## Usage 
```
source ops/setup_local.bash --build
```

In order to perform analysis based on the US statue and US campaign contribution 
dataset they need to be downloaded and stored in the `data` directory, which is 
created during setup. However these datasets are not publically available. 

For extraction of ambiguity scores and further text features based on the US statue
dataset use

```
python3 scripts/extract.py \ 
--us_campaign_path=[path to us campaign dataset] \
--us_statue_path=[path to us statue dataset] \
--state=[abbreviation of state to analyse, all states per default] \
--logging_mode=["DEBUG", "INFO", "WARNING"]
```

For further analysis and visualization the following commands can be used

```
python3 scripts/visualize_usc_grid.py  --> visualizes US campaign contrib data over states and years
python3 scripts/visualize_usc_map.py --> visualizes US campaign contrib data over states in US map
python3 scripts/visualize_uss_map.py --> visualizes US statue extracted ambiguity scores over states in US map
python3 scripts/visualize_uss_scores.py --> visualizes US statue extracted ambiguity score distribution
python3 scripts/correlation.py --> determines correleation between contribution limits and extracted ambiguity features
```