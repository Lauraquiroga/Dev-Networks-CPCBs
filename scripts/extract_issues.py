"""
Extract GitHub Issues from CPCB Pattern Excel Workbook

This script extracts and consolidates GitHub issue references from an Excel workbook containing multiple sheets, each categorized by CPCB pattern structures.

For each relevant sheet (those starting with 'PS', except PS8, PS9, PS11), the script:
    - Reads the sheet into a DataFrame
    - Identifies and skips columns with empty, NaN, or 'Unnamed' headers
    - Iterates over rows, extracting issue references and associated metadata (fix type, pattern structure, scenario, etc.)
    - Excludes rows/columns that do not represent actionable issues (e.g., 'PF9' fix type, columns with 'commit' in the value)

The result is a deduplicated CSV file (`../data/combined_issues.csv`) containing all extracted issues and their context, suitable for further analysis or enrichment.
"""

import pandas as pd



# Load the Excel file with multiple sheets
xls = pd.ExcelFile("../data/CPCB_patterns_updated.xlsx")

# Empty list to store results

all_issues = []

def is_valid_header(col):
    """
    Returns True if the column header is not empty, not NaN, and not an 'Unnamed' Excel placeholder.
    """
    if pd.isna(col):
        return False
    s = str(col).strip()
    if s == '' or s.lower().startswith('unnamed'):
        return False
    return True

for sheet_name in xls.sheet_names:
    #IF sheet_name starts with 'PS', process it and is not PS8, PS9, PS11 (3-project cases with 2 solution types)
    if sheet_name.startswith('PS') and sheet_name not in ['PS8', 'PS9', 'PS11']:
        df = pd.read_excel(xls, sheet_name=sheet_name)
        df['Pattern-Structure'] = sheet_name  # Add PS tag

        # Identify the Fix-type column
        fix_col = 'Fix-type'

        # Loop through each row
        for _, row in df.iterrows():
            fix_type = row[fix_col]
            pattern = row['Pattern-Structure']
            if fix_type != 'PF9': # Exclude No fix pattern
                for col in df.columns:
                    # skip columns with empty/NaN/Unnamed header (usually just annotations)
                    if col not in ['#', fix_col, 'Scenario', 'Pattern-Structure'] \
                    and is_valid_header(col) \
                    and pd.notna(row[col]) \
                    and 'commit' not in str(row[col]).lower():
                        all_issues.append({
                            'GitHub-Issue': row[col],
                            'PR': 'PR' in col or 'Pull Request' in col,
                            'Fix-type': fix_type,
                            'Pattern-Structure': pattern,
                            'Downstream-driven-fix': fix_type == 'PF1' or fix_type == 'PF4' or fix_type == 'PF5', 
                            'Scenario': row['Scenario'],
                            'ID': f"{pattern}-{row['#']}"
                        })

# Combine into one dataframe
combined = pd.DataFrame(all_issues)

# Drop duplicates if needed
combined = combined.drop_duplicates()

# Save result in a csv file
combined.to_csv("../data/combined_issues.csv", index=False)