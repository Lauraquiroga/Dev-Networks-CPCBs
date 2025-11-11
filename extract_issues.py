import pandas as pd

# Script to extract GitHub issues from multiple sheets with the CPCB pattern categorization in an Excel file


# Load the Excel file with multiple sheets
xls = pd.ExcelFile("data/CPCB-patterns.xlsx")

# Empty list to store results
all_issues = []

for sheet_name in xls.sheet_names:
    #IF sheet_name starts with 'PS', process it and is not PS8, PS9 or PS11
    if sheet_name.startswith('PS') and sheet_name not in ['PS8', 'PS9', 'PS11']:
        df = pd.read_excel(xls, sheet_name=sheet_name)
        df['Pattern Structure'] = sheet_name  # Add PS tag

        # Identify the Fix-type column
        fix_col = 'Fix-type'

        # Loop through each row
        for _, row in df.iterrows():
            fix_type = row[fix_col]
            pattern = row['Pattern Structure']
            for col in df.columns:
                # skip columns with empty/NaN header
                if col not in ['#', fix_col, 'Pattern Structure'] \
                   and pd.notna(col) \
                   and str(col).strip() != '' \
                   and pd.notna(row[col]) \
                   and 'commit' not in str(row[col]).lower():
                    all_issues.append({
                        'GitHub Issue': row[col],
                        'PR': 'PR' in col or 'Pull Request' in col,
                        'Fix-type': fix_type,
                        'Pattern Structure': pattern,
                        'Downstream-driven-fix': fix_type == 'PF1' or fix_type == 'PF4' or fix_type == 'PF5', 
                        'ID': f"{pattern}-{row['#']}"
                    })

# Combine into one dataframe
combined = pd.DataFrame(all_issues)

# Drop duplicates if needed
combined = combined.drop_duplicates()

# Save result in a csv file
combined.to_csv("data/combined_issues.csv", index=False)