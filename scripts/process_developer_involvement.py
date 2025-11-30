"""
Script to process developer_info_cleaned.csv and generate two separate CSVs:
- downstream_driven.csv: scenarios with Downstream-driven-fix = True
- upstream_driven.csv: scenarios with Downstream-driven-fix = False

Groups by Username + Scenario + Project (derived from Issue field)
Computes max_inv (maximum involvement score) for each group.
"""

import pandas as pd
import os


def calculate_involvement(row):
    """
    Calculate involvement score for a row.
    - If PR-author is True: score = 3
    - If PR-author is False and any of (BugReport-author, Commented, Reviewer) is True: score = 2
    - Otherwise: score = 0
    """
    if row['PR-author']:
        return 3
    elif row['BugReport-author'] or row['Commented'] or row['Reviewer']:
        return 2
    else:
        return 0


def extract_project(issue):
    """
    Extract project name from Issue field.
    Project is the string before the # character.
    Example: 'joblib/joblib#105' -> 'joblib/joblib'
    """
    return issue.split('#')[0]


def process_developer_info(input_file, output_dir):
    """
    Process the developer_info_cleaned.csv file and generate two output CSVs.
    
    Args:
        input_file: Path to the input CSV file
        output_dir: Directory where output files will be saved
    """
    # Read the input CSV
    df = pd.read_csv(input_file)
    
    # Extract project from Issue field
    df['project'] = df['Issue'].apply(extract_project)
    
    # Calculate involvement score for each row
    df['involvement'] = df.apply(calculate_involvement, axis=1)
    
    # Group by Username, Scenario, Project, and Downstream-driven-fix
    # Calculate the maximum involvement score for each group
    grouped = df.groupby(['Username', 'Scenario', 'project', 'Downstream-driven-fix']).agg({
        'involvement': 'max'
    }).reset_index()
    
    # Rename columns to match output format
    grouped = grouped.rename(columns={
        'Username': 'username',
        'involvement': 'max_inv',
        'Scenario': 'scenario'
    })
    
    # Split into downstream-driven and upstream-driven
    downstream_df = grouped[grouped['Downstream-driven-fix'] == True][['username', 'project', 'scenario', 'max_inv']]
    upstream_df = grouped[grouped['Downstream-driven-fix'] == False][['username', 'project', 'scenario', 'max_inv']]
    
    # Save to CSV files
    downstream_output = os.path.join(output_dir, 'downstream_driven.csv')
    upstream_output = os.path.join(output_dir, 'upstream_driven.csv')
    
    downstream_df.to_csv(downstream_output, index=False)
    upstream_df.to_csv(upstream_output, index=False)
    
    print(f"Processing complete!")
    print(f"Downstream-driven records: {len(downstream_df)}")
    print(f"Upstream-driven records: {len(upstream_df)}")
    print(f"Output files saved to:")
    print(f"  - {downstream_output}")
    print(f"  - {upstream_output}")


if __name__ == "__main__":
    # Define paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    data_dir = os.path.join(project_root, 'data')
    
    input_file = os.path.join(data_dir, 'developer_info_cleaned.csv')
    
    # Process the data
    process_developer_info(input_file, data_dir)
