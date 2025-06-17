# Save this as app.py
from fastapi import FastAPI
from pydantic import BaseModel
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
import joblib

app = FastAPI()

# Load and prepare the model
df = pd.read_csv('mymoviedb.csv',lineterminator='\n')
features = ['Popularity', 'Vote_Count', 'Vote_Average']
df = df.dropna(subset=features)

scaler = MinMaxScaler()
scaled_features = scaler.fit_transform(df[features])
df_scaled = pd.DataFrame(scaled_features, columns=features)

df['Success_Score'] = (0.5 * df_scaled['Popularity']) + (0.3 * df_scaled['Vote_Count']) + (0.2 * df_scaled['Vote_Average'])
threshold = df['Success_Score'].median()
df['Hit_Flop'] = df['Success_Score'].apply(lambda x: 1 if x > threshold else 0)

X = df[features]
y = df['Hit_Flop']
model = RandomForestClassifier()
model.fit(X, y)

# Save the model and scaler
joblib.dump(model, 'hit_flop_model.pkl')
joblib.dump(scaler, 'scaler.pkl')

# API input schema
class MovieData(BaseModel):
    popularity: float
    vote_count: int
    vote_average: float

@app.post('/predict')
def predict(data: MovieData):
    model = joblib.load('hit_flop_model.pkl')
    scaler = joblib.load('scaler.pkl')

    input_df = pd.DataFrame([[data.popularity, data.vote_count, data.vote_average]], columns=features)
    input_scaled = scaler.transform(input_df)

    prediction = model.predict(input_df)
    result = 'Hit' if prediction[0] == 1 else 'Flop'
    return {'prediction': result}
