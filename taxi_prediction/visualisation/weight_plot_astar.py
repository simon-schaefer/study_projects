'''
Visualisation of the relation between the map-prediction weight vector
of AStar Search (velocity_time_estimation) and the accuracy, as 2D-plot.
'''

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm

WEIGHT_ACC_FILE = "../predictions/astar_log.csv"

# Read weight - accuracy data into pandas dataframe. 
data = pd.read_csv(WEIGHT_ACC_FILE, index_col=False)
print(data.head())

# Get weight and accuracy vector.
data = data.sort_values(by=['velocity'])
X = data['velocity']
C = data['accuracy']

# Interpolation line.
f = np.poly1d(np.polyfit(X, C, 5))
X_interp = np.arange(min(X), max(X), 0.01)
C_interp = [f(x) for x in X_interp]

# Plot surface plot. 
fig = plt.figure()
ax  = plt.plot(X, C, '.', X_interp, C_interp, '-')
plt.xlabel('Weight of Velocity_Time_Estimate')
plt.ylabel('Error [RPSE]') 
plt.show()
