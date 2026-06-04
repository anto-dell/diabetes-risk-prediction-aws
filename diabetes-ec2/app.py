import json
import os
import io
import sys
import boto3
import joblib
import numpy as np
import pandas as pd
from flask import Flask, request, jsonify

app = Flask(__name__)

# The pipeline was trained in a Jupyter notebook where these two functions
# lived in __main__. 

def zeros_to_nan(X: pd.DataFrame) -> pd.DataFrame:
    """Convert medically-impossible 0s to NaN for selected columns."""
    X = X.copy()
    X[["Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI"]] = X[
        ["Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI"]
    ].replace(0, np.nan)
    return X


def add_interactions(X: pd.DataFrame) -> pd.DataFrame:
    """Add interaction features used by the trained pipeline."""
    X = X.copy()
    X["Age_BMI"]        = X["Age"] * X["BMI"]
    X["Glucose_BMI"]    = X["Glucose"] * X["BMI"]
    X["Preg_Age_Ratio"] = X["Pregnancies"] / (X["Age"] + 1)
    return X


_main = sys.modules["__main__"]
_main.zeros_to_nan     = zeros_to_nan
_main.add_interactions = add_interactions

# Load model from S3 when the server starts
s3 = boto3.client('s3', region_name='eu-central-1')
BUCKET = "diabetes-model-antonella-2026"
KEY    = "pima_best_pipeline.joblib"

def load_model():
    response = s3.get_object(Bucket=BUCKET, Key=KEY)
    body = response['Body'].read()
    bundle = joblib.load(io.BytesIO(body))
    return bundle['pipeline'], bundle['features'], float(bundle['operating_threshold'])

pipeline, features, threshold = load_model()

@app.route('/predict', methods=['POST'])
def predict():
    try:
        body = request.get_json()

        missing = [f for f in features if f not in body]
        if missing:
            return jsonify({'error': f'Missing fields: {missing}'}), 400

        df    = pd.DataFrame([body])[features]
        proba = float(pipeline.predict_proba(df)[:, 1][0])
        pred  = int(proba >= threshold)

        return jsonify({
            'prediction':  'Diabetes' if pred else 'No Diabetes',
            'probability': round(proba, 4)
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)