from flask import Flask, request, jsonify
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import r2_score
from sklearn.preprocessing import OneHotEncoder
from sklearn.model_selection import train_test_split
from statsmodels.tsa.arima.model import ARIMA
from pmdarima import auto_arima
import librosa
import tensorflow as tf
import os
from pydub import AudioSegment
from pydub.playback import play
from sklearn.preprocessing import LabelEncoder
import warnings
from flask_cors import CORS

warnings.filterwarnings("ignore")

app = Flask(__name__)
CORS(app)
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024

# Load datasets
csv_file_path = "noise_data.csv"  # Adjust this path as needed
data = pd.read_csv(csv_file_path).dropna()
data.rename(columns={'Day': 'avg_day_value', 'Night': 'avg_night_value'}, inplace=True)
df = pd.read_csv("nosise_data_set.csv").dropna()

# One-hot encode the 'Station' column for Random Forest
encoder = OneHotEncoder(sparse_output=False, drop='first')
station_encoded = encoder.fit_transform(df[['Station']])

# Prepare features and target variables for Random Forest
X = pd.concat([pd.DataFrame(station_encoded), df[['Year', 'Month']].reset_index(drop=True)], axis=1)
y = df[['Day', 'Night']]
X.columns = X.columns.astype(str)

# Split data into training and testing sets for Random Forest
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
rf_model = RandomForestRegressor(n_estimators=100, random_state=42)
rf_model.fit(X_train, y_train)

# Calculate R² scores for the model
y_pred_test = rf_model.predict(X_test)
r2_day_model = r2_score(y_test['Day'], y_pred_test[:, 0])
r2_night_model = r2_score(y_test['Night'], y_pred_test[:, 1])


# RandomForest prediction route with new logic
@app.route('/predict_random_forest', methods=['POST'])
def predict_random_forest():
    data = request.json
    station = data['station']
    month = int(data['month'])
    year = int(data['year'])

    # Encode the station
    station_encoded = encoder.transform([[station]])
    input_data = pd.concat([pd.DataFrame(station_encoded), pd.DataFrame([[year, month]])], axis=1)

    # Make predictions
    noise_pred = rf_model.predict(input_data)
    day_noise = noise_pred[0, 0]
    night_noise = noise_pred[0, 1]

    return jsonify({
        'predicted_day_value': day_noise,
        'predicted_night_value': night_noise,
        'r2_day': r2_day_model,
        'r2_night': r2_night_model
    })

# ARIMA prediction route (unchanged)
@app.route('/predict_arima', methods=['POST'])
def predict_arima():
    user_date = request.json.get('date')
    user_station = request.json.get('station')

    # Filter data based on station
    filtered_data = data[data['Station'] == user_station]
    if filtered_data.empty:
        return jsonify({"error": "Station not found."}), 400

    # Set size for splitting data for ARIMA model
    size = int(len(filtered_data) * 0.80)
    X = filtered_data['avg_day_value']
    Y = filtered_data['avg_night_value']
    
    # Forecast day predictions using ARIMA
    train, test = X[:size], X[size:]
    history = [x for x in train]
    observations = list(test)
    predictions = []

    auto_model = auto_arima(filtered_data["avg_day_value"])
    p, d, q = auto_model.order
    for obs in observations:
        history.append(obs)
        model = ARIMA(history, order=(p, d, q)).fit()
        yhat = model.forecast()[0]
        predictions.append(yhat)
    r2_day = r2_score(observations, predictions)

    # Forecast night predictions using ARIMA
    train2, test2 = Y[:size], Y[size:]
    history2 = list(train2)
    observations2 = list(test2)
    predictions2 = []

    auto_model2 = auto_arima(filtered_data["avg_night_value"])
    a, b, c = auto_model2.order
    for obs2 in observations2:
        history2.append(obs2)
        model2 = ARIMA(history2, order=(a, b, c)).fit()
        yhat2 = model2.forecast()[0]
        predictions2.append(yhat2)
    r2_night = r2_score(observations2, predictions2)
    
    # Prepare date range and results for the given date
    index_months = pd.date_range(start='2011-01-01', end='2019-04-01', freq="MS")
    pred2 = model2.predict(start=1, end=len(filtered_data) + 4)
    pred = model.predict(start=1, end=len(filtered_data) + 4)

    dataframe = pd.DataFrame({"Date": index_months, "DayPredictions": pred, "NightPredictions": pred2})
    prediction_result = dataframe[dataframe['Date'] == user_date]

    if not prediction_result.empty:
        result = {
            "Station": user_station,
            "Date": user_date,
            "Prediction": prediction_result['DayPredictions'].values[0],
            "Prediction2": prediction_result['NightPredictions'].values[0],
            "r2_day": r2_day,
            "r2_night": r2_night
        }
    else:
        result = {
            "Error": "Date not found"
        }
    return jsonify(result)

# Load the trained model
model = tf.keras.models.load_model('my_model.keras')

# Label encoder to decode the predicted classes
class_labels = [
    'dog_bark', 'children_playing', 'car_horn', 'air_conditioner', 'street_music',
    'gun_shot', 'siren', 'engine_idling', 'jackhammer', 'drilling'
]
le = LabelEncoder()
le.fit(class_labels)

# Function to preprocess a new audio file
def preprocess_audio(file_path):
    try:
        # Load audio file
        audio, sample_rate = librosa.load(file_path, sr=None)
        # Ensure the FFT window size is appropriate
        n_fft = min(2048, len(audio))
        # Extract MFCC features
        mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40, n_fft=n_fft)
        # Scale the MFCC features
        mfccs_scaled = np.mean(mfccs.T, axis=0)
        # Reshape for the model input
        mfccs_scaled = mfccs_scaled[np.newaxis, ..., np.newaxis]
        return mfccs_scaled
    except Exception as e:
        print(f"Error encountered while processing file: {file_path}, error: {e}")
        return None

# Function to predict the class of a new audio file
def predict_audio_class(file_path):
    # Preprocess the audio file
    features = preprocess_audio(file_path)
    if features is None:
        return None
    # Predict the class
    predictions = model.predict(features)
    predicted_class = np.argmax(predictions, axis=1)
    class_label = le.inverse_transform(predicted_class)
    return class_label[0]

# Route to handle file upload and prediction
@app.route('/predict_audio', methods=['POST'])
def predict_audio():
    if 'audio_file' not in request.files:
        return jsonify({"error": "No audio file uploaded."}), 400

    # Save the uploaded file temporarily
    audio_file = request.files['audio_file']
    temp_path = os.path.join("temp", audio_file.filename)
    os.makedirs("temp", exist_ok=True)
    audio_file.save(temp_path)

    try:
        # Predict the audio class
        predicted_class = predict_audio_class(temp_path)
        if predicted_class is None:
            return jsonify({"error": "Error processing the audio file."}), 500

        return jsonify({
            "predicted_class": predicted_class
        })
    except Exception as e:
        print(f"Error during prediction: {e}")
        return jsonify({"error": f"An error occurred during prediction: {e}"}), 500
    finally:
        # Cleanup the temporary file
        if os.path.exists(temp_path):
            os.remove(temp_path)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)