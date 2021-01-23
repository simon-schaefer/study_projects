'''
Visualisation of the relation between the map-prediction weight vector
of LocalSearch and the accuracy, as 3D-surface plot.
'''

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm

WEIGHT_ACC_FILE = "../predictions/opt_local.csv"

# Read weight - accuracy data into pandas dataframe. 
data = pd.read_csv(WEIGHT_ACC_FILE, index_col=False)
data = data.astype('float')

print(data.head())

# Drop all rows with large error. 
small_error = data['accuracy'] < 0.4
data = data[small_error]
minimum = data.loc[data['accuracy'].idxmin]
print(minimum)

# In an optimisation problem (e.g. the local map prediction search)
# the weights are not important in absolute but relative values. 
# Therefore we plot the relative weights. 
X = data['end_dis']
Y = data['direction']
C = data['accuracy']

# Plot surface plot. 
fig = plt.figure()
ax = plt.axes(projection='3d')
ax.plot_trisurf(X, Y, C, cmap='viridis', edgecolor='none');
ax.set_xlabel('Distance')
ax.set_ylabel('Direction')
ax.set_zlabel('Error (RMPSE)') 
plt.show()
