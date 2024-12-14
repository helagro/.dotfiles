import sys
import json
import pandas as pd


def main(args):
    # Initialize an empty list to hold the data
    dataframes = []

    for i, arg in enumerate(args, start=1):
        # Parse the JSON string into a Python dictionary
        json_data = json.loads(arg)

        # Convert the dictionary to a DataFrame
        df = pd.DataFrame(list(json_data.items()),
                          columns=['Date', f'Values_{i}'])

        # Ensure the 'Date' column is of datetime type for consistency
        df['Date'] = pd.to_datetime(df['Date'])

        # Append the DataFrame to the list
        dataframes.append(df)

    # Merge all DataFrames on the 'Date' column
    result = dataframes[0]
    for df in dataframes[1:]:
        result = result.merge(df, on='Date', how='outer')

    # Sort by Date
    result = result.sort_values('Date', ascending=False)

    # Print the final DataFrame
    print(result.to_csv(index=False, sep='\t', header=False))


if __name__ == "__main__":
    # The script expects the JSON strings to be passed as command line arguments
    if len(sys.argv) < 2:
        print("Please provide at least one JSON object as an argument.")
        sys.exit(1)

    # Run the main function with the list of JSON args
    main(sys.argv[1:])
