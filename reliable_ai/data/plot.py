import matplotlib.pyplot as plt
import os.path
import numpy as np
import pandas as pd
import seaborn as sns
from sys import argv

if len(argv) != 2:
    print('usage: python3.6 ' + argv[0] + ' data.txt')
    exit(1) 
    
FILE = argv[1]

# Read-in times file line by line. 
filename = os.path.join(os.path.dirname(os.path.realpath(__file__)),FILE)
raw = pd.read_csv(filename, sep=" ", header=None)
raw.columns = ["num_layer", "num_relu", "num_affine", "num_weights", \
               "weights_one_mean","weights_one_max", "weights_one_min", \
               "activation_mean", "activation_median", "activation_max", \
               "dev_box_all_mean", "dev_box_all_max", "dev_box_all_min", \
               "dev_box_all_median", "dev_box_all_norm", \
               "dev_box_one_mean", "dev_box_one_max", "dev_box_one_min", \
               "dev_box_one_median", "dev_box_one_norm", \
               "epsilon", "netname", "netlayer", "verified", "runtime"]
# Clean up dataframe.     
raw = raw[raw["runtime"] > 0]
raw["runtime"] = [np.log10(x) for x in raw["runtime"]]
raw = raw[raw["dev_box_one_norm"] != "None"]
raw = raw.dropna()
for col in ["dev_box_all_mean", "dev_box_all_max", "dev_box_all_min", \
            "dev_box_all_median", "dev_box_all_norm", \
            "dev_box_one_mean", "dev_box_one_max", "dev_box_one_min", \
            "dev_box_one_median", "dev_box_one_norm"]: 
    raw[col] = [float(x) for x in raw[col]]

     
# Create plotting dataframe. 
df = pd.DataFrame()
df["dt"] = raw["runtime"]
df["verified"] = raw["verified"].astype(bool)
df["epsilon"] = pd.cut(raw["epsilon"], bins=4)
df["num_weights"] = pd.cut(raw["num_weights"], bins=3, 
                           labels=["few", "medium", "many"])
df["layer_after"] = pd.cut(raw["netlayer"] - raw["num_layer"], bins=2)
df["dev"] = pd.cut(raw["dev_box_one_norm"], bins=3, 
                   labels=["small", "medium", "large"])
df["norm_max_weight"] = pd.cut(raw["weights_one_max"]/raw["weights_one_mean"], 
                               bins=3, labels=["small", "medium", "large"])

# Plot cleaned data. 
sns.catplot(x="dev", y="dt", hue="epsilon", 
            kind="box", data=df)
sns.catplot(x="num_weights", y="dt", hue="epsilon", col="dev", 
            kind="box", data=df) 
#sns.catplot(x="verified", hue="epsilon", row="norm_max_weight", 
#            kind="count", data=df) 
plt.show()

# Model fitting - Multidimensional linear regression.  
ignored = ["runtime", "verified", "netname"]
reg = pd.DataFrame()
reg["runtime"] = raw["runtime"]  
reg["activation"] = raw["activation_mean"]/784.0
reg["num_weights"] = raw["activation_mean"]/10**6
reg["dev_mean"] = raw["dev_box_one_norm"]/0.5
reg["dev_max"] = raw["dev_box_one_max"]/0.5
reg["weight_mean"] = raw["weights_one_mean"]/1.5
reg["weight_max"] = raw["weights_one_max"]/1.5
reg["epsilon"] = raw["epsilon"]/0.01
y = np.array(reg["runtime"])
X = [reg[z].tolist() for z in reg.columns if not z == "runtime"]
X = np.array(X)
X = X.T
X = np.c_[X, np.ones(X.shape[0])]
beta_hat = np.linalg.lstsq(X,y)[0]
print("Parameters")
print([z for z in reg.columns if not z == "runtime"])
print(beta_hat)


