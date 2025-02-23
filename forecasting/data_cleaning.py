import pandas as pd

# Load the dataset
df = pd.read_csv('data/data_raw.csv')

cleaned_df = df[['StartDateTime', 'TradeDate', 'ISEM DA Price']]
cleaned_df.to_csv('data/arima/arima_data.csv', index=False)