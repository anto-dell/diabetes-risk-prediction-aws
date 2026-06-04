import json
import os
import sys

import joblib
import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# The pipeline was trained in a Jupyter notebook where these two functions
# lived in __main__.  joblib re-looks them up in __main__ when unpickling,
# so they must be registered here before joblib.load() is called.
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Load the model once at cold-start.
# Lambda reuses the execution environment across warm invocations,
# so this only runs once per container — not on every request.
# ---------------------------------------------------------------------------
model_path = os.path.join(os.environ.get("LAMBDA_TASK_ROOT", "."), "pima_best_pipeline.joblib")
bundle    = joblib.load(model_path)
pipeline  = bundle["pipeline"]
threshold = float(bundle["operating_threshold"])
features  = bundle["features"]


def lambda_handler(event, _context):
    try:
        body = json.loads(event.get("body") or "{}")

        missing = [f for f in features if f not in body]
        if missing:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": f"Missing fields: {missing}"}),
            }

        input_df = pd.DataFrame([body], columns=features)
        proba    = float(pipeline.predict_proba(input_df)[0][1])
        pred     = int(proba >= threshold)

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "prediction":  "Diabetes" if pred else "No Diabetes",
                "probability": round(proba, 4),
            }),
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
        }
