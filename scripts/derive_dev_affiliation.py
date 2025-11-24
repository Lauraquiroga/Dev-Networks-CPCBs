"""
Derive Developer Affiliation Scores and Categories

This script analyzes developer participation in GitHub issues and pull requests to derive affiliation scores and categories for each developer within each project.

Workflow:
1. Loads developer activity data from a CSV (../data/developer_info.csv).
2. Converts participation columns to booleans and extracts the project name from each issue reference.
3. Computes a weighted participation score for each developer per project, based on their roles (PR author, reviewer, bug reporter, commenter).
4. Normalizes scores to determine the percentage of each developer's activity per project.
5. Assigns an affiliation category (primary, secondary, incidental, other) based on thresholds and the developer's highest project involvement.
6. Flags drive-by contributors with very low total activity.
7. Saves the results to a CSV (../data/dev_affiliations.csv) and prints a sample of the output.

Input:  ../data/developer_info.csv (must contain columns for participation types and issue references)
        Sample header: Username,Issue,PR-author,BugReport-author,Commented,Reviewer,Fix-type,Pattern-Structure,Downstream-driven-fix,Scenario
Output: ../data/dev_affiliations.csv (affiliation scores and categories per developer per project)
        Sample header: Username,Project,ParticipationScore,TotalScore,AffiliationPct,AffiliationType,DriveBy
"""

import pandas as pd

# Weights for each participation type
WEIGHTS = {
    "PR-author": 4,
    "Reviewer": 3,
    "BugReport-author": 2,
    "Commented": 1
}

# Thresholds for affiliation categories
SECONDARY_THRESHOLD = 0.20   # ≥ 20% → secondary affiliation
INCIDENTAL_THRESHOLD = 0.10  # < 10% → incidental

INPUT_CSV = '../data/developer_info.csv"'
OUTPUT_CSV = '../data/dev_affiliations.csv'


# ---------------------------------------------------------
# 1. LOAD DATA
# ---------------------------------------------------------

df = pd.read_csv(INPUT_CSV)

# Convert boolean-like strings to real booleans
for col in ["PR-author", "BugReport-author", "Commented", "Reviewer"]:
    df[col] = df[col].astype(str).str.lower().isin(["true", "1", "yes"])


# ---------------------------------------------------------
# 2. EXTRACT PROJECT FROM ISSUE FIELD
# Issue format: "owner/repo/#1234"
# We extract "owner/repo" as the project ID
# ---------------------------------------------------------

def extract_project(issue_str):
    try:
        parts = issue_str.split("#")[0]  # "owner/repo/"
        return parts.strip("/").lower()  # "owner/repo"
    except:
        return None

df["Project"] = df["Issue"].apply(extract_project)


# ---------------------------------------------------------
# 3. COMPUTE PARTICIPATION SCORES PER DEVELOPER PER PROJECT
# ---------------------------------------------------------

# Compute weighted score for each row
df["ParticipationScore"] = (
    df["PR-author"] * WEIGHTS["PR-author"] +
    df["Reviewer"] * WEIGHTS["Reviewer"] +
    df["BugReport-author"] * WEIGHTS["BugReport-author"] +
    df["Commented"] * WEIGHTS["Commented"]
)

# Aggregate scores per developer per project
scores = (
    df.groupby(["Username", "Project"])["ParticipationScore"]
      .sum()
      .reset_index()
)

# Total score per developer
total_scores = (
    scores.groupby("Username")["ParticipationScore"]
          .sum()
          .rename("TotalScore")
)
scores = scores.merge(total_scores, on="Username")

# Compute normalised affiliation percentage
scores["AffiliationPct"] = scores["ParticipationScore"] / scores["TotalScore"]


# ---------------------------------------------------------
# 4. DETERMINE AFFILIATION CATEGORY
# ---------------------------------------------------------

def affiliation_label(row, max_pct):
    if row["AffiliationPct"] == max_pct:
        return "primary"
    elif row["AffiliationPct"] >= SECONDARY_THRESHOLD:
        return "secondary"
    elif row["AffiliationPct"] < INCIDENTAL_THRESHOLD:
        return "incidental"
    else:
        return "other"

# Compute primary affiliation threshold for each dev
max_pct_per_dev = (
    scores.groupby("Username")["AffiliationPct"]
          .max()
          .rename("MaxPct")
)
scores = scores.merge(max_pct_per_dev, on="Username")

# Assign category
scores["AffiliationType"] = scores.apply(
    lambda row: affiliation_label(row, row["MaxPct"]),
    axis=1
)


# ---------------------------------------------------------
# 5. FILTER DRIVE-BY CONTRIBUTORS
# Developers with very low total activity
# ---------------------------------------------------------

scores["DriveBy"] = scores["TotalScore"] < 3  # threshold adjustable


# ---------------------------------------------------------
# 6. SAVE RESULTS
# ---------------------------------------------------------

scores.to_csv(OUTPUT_CSV, index=False)

print(f"Affiliation scores computed and saved to {OUTPUT_CSV}")
print(scores.head(10))
