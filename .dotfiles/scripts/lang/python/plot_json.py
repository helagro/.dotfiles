import sys
import json
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator
import re
import numpy as np
from sklearn.linear_model import LinearRegression
from scipy.interpolate import UnivariateSpline
from sklearn.metrics import r2_score

TIME_REGEX = r"^\d{2}:\d{2}$"


def main(arg, plot_name):
    # Load the JSON data
    json_data = json.loads(arg)
    df = pd.DataFrame(list(json_data.items()), columns=['Date', 'Value'])
    df['Date'] = pd.to_datetime(df['Date'])

    plt.figure(figsize=(10, 6))
    plt.tight_layout()

    # Handle y values of type time
    df.dropna(subset=['Value'], inplace=True)
    is_time_series = is_time(str(df['Value'].iloc[0]))
    if is_time_series:
        print("Time series detected")
        df['Value'] = df['Value'].apply(to_time)
    df.dropna(subset=['Value'], inplace=True)

    # --------------------- LINEAR REGRESSION -------------------- #

    # Fit a linear regression model
    df['Days'] = (df['Date'].max() - df['Date']).dt.days
    X = df['Days'].values.reshape(-1, 1)
    y = df['Value'].apply(conv_time) if is_time_series else df['Value']
    model = LinearRegression().fit(X, y)
    df['Trend'] = model.predict(X)

    slope = model.coef_[0]

    # Calculate the difference in y values
    intercept = model.intercept_
    x_start = X.min()
    x_end = X.max()
    y_start = slope * x_start + intercept
    y_end = slope * x_end + intercept
    difference = y_end - y_start

    plt.subplots_adjust(bottom=0.65)
    plt.figtext(0.5, 0.01, f"Slope: {slope}; Change: {difference}", fontsize=11, color='blue', ha='center')

    # Plot the trend line
    plt.plot(df["Date"], df["Trend"], color='red', label="Trend")

    # ------------------- POLYNOMIAL REGRESSION ------------------- #

    # Fit a polynomial regression model

    poly_model = np.poly1d(np.polyfit(df['Days'], y, 8))
    df['Polynomial'] = poly_model(df['Days'])

    # ---------------------- SPLINE INTERPOLATION ----------------- #

    # Fit a spline interpolation model
    print(df['Days'])
    spline_model = UnivariateSpline(df['Days'], y)
    df['Spline'] = spline_model(df['Days'])

    # ----------------------- USE BEST FIT ----------------------- #

    # Use the best fit line
    if r2_score(y, df['Polynomial']) < r2_score(y, df['Spline']):
        plt.plot(df["Date"], df["Spline"], color='orange', label="Spline")

    plt.plot(df["Date"], df["Polynomial"], color='green', label="Polynomial")

    # ------------------------- MAIN PLOT ------------------------ #
    # Plot the line with 50% opacity
    plt.plot(
        df["Date"],
        df["Value"].apply(conv_time) if is_time_series else df["Value"],
        alpha=0.3,  # Line opacity at 50%
        color="tab:blue",
        label="Value")

    # Plot the markers with 100% opacity
    plt.plot(
        df["Date"],
        df["Value"].apply(conv_time) if is_time_series else df["Value"],
        marker="o",  # Markers
        alpha=1.0,  # Marker opacity at 100%
        linestyle="None",  # No line between markers
        color="tab:blue",  # Marker color
        label="Value (Markers)")

    plt.title(plot_name, fontsize=16)
    plt.xlabel("Date", fontsize=14)
    plt.ylabel("Value", fontsize=14)
    plt.xticks(rotation=45)
    plt.grid(True, linestyle="--", alpha=0.7)
    plt.legend()
    plt.tight_layout()

    plt.gca().yaxis.set_major_locator(MaxNLocator(integer=True, prune='both', nbins=10))

    # Display the plot
    plt.show()


def is_time(value):
    # print(value)
    return re.match(TIME_REGEX, value) is not None


def to_time(value):
    try:
        return pd.to_datetime(value, format='%H:%M').time()
    except Exception as e:
        return np.nan


def conv_time(value):
    if hasattr(value, 'hour'):
        return value.hour + value.minute / 60.0
    else:
        return np.nan


if __name__ == "__main__":
    plot_name = "Value Over Time"
    if len(sys.argv) > 2:
        plot_name = sys.argv[2]

    print(f"Arguments: {sys.argv}")

    if len(sys.argv) >= 2:
        try:
            main(sys.argv[1], plot_name)
        except KeyboardInterrupt:
            pass
    else:
        print("Usage: python plot_json.py <json_data> <plot_name>")
        sys.exit(1)
