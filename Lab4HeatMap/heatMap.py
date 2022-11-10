import pandas as pd
import matplotlib.pyplot as plt

path_to_csv= "finalTemperatures.csv"
df= pd.read_csv (path_to_csv ,index_col=0)

plt.imshow(df,cmap='hot',interpolation='nearest')

plt.show()