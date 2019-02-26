import numpy as np
import pandas as pd
import json

with open('builtenv.json','r') as f:
	data = json.load(f)

zoning = []
land_use = []
facilities = []

for i in range(len(data)):
	curr = data[i]
	curr_zoning = curr['zoning']
	curr_zoning['boroCD'] = curr['borocd']
	curr_land_use = curr['land_use']
	curr_land_use['boroCD'] = curr['borocd']
	curr_facilities = curr['facilities']
	curr_facilities['boroCD'] = curr['borocd']
	zoning.append(curr_zoning.copy())
	land_use.append(curr_land_use.copy())
	facilities.append(curr_facilities.copy())

zoning_df = pd.DataFrame(zoning)
land_use_df = pd.DataFrame(land_use)
facilities_df = pd.DataFrame(facilities)

zoning_df.to_csv('zoning.csv',index = False)
land_use_df.to_csv('land_use.csv', index = False)
facilities_df.to_csv('facilities.csv', index = False)