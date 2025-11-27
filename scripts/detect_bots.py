"""
detect_bots.py

This script identifies suspicious or bot-like developer accounts in the developer info dataset. It flags accounts that are either in a known list of bot usernames or whose username contains the substring 'bot' (case-insensitive).

Workflow:
1. Loads developer info from a CSV (../data/developer_info.csv).
2. Checks each username against a set of known bot accounts and a regex for 'bot' in the username.
3. Writes all flagged (suspicious) accounts to a new CSV (../data/suspicious_bots.csv).

Input:  ../data/developer_info.csv (developer account data)
Output: ../data/suspicious_bots.csv (flagged suspicious/bot accounts)
"""
import csv
import re

INPUT_FILE = "../data/developer_info.csv"
OUTPUT_FILE = "../data/suspicious_bots.csv"

# Known bot accounts
KNOWN_BOTS = {
    "coveralls",
    "travisbot",
    "numpy-gitbot",
    "scipy-gitbot",
    "codecov-io",
}

# Regex to detect usernames containing "bot" in any casing
BOT_REGEX = re.compile(r"bot", re.IGNORECASE)


def is_suspicious(username: str) -> bool:
    """Return True if username is a known bot or matches the bot regex."""
    if username in KNOWN_BOTS:
        return True
    if BOT_REGEX.search(username):
        return True
    return False


def main():
    suspicious_rows = []

    # Read input CSV
    with open(INPUT_FILE, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        header = reader.fieldnames

        for row in reader:
            username = row["Username"].strip()
            if is_suspicious(username):
                suspicious_rows.append(row)

    # Write output CSV
    if suspicious_rows:
        with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=header)
            writer.writeheader()
            writer.writerows(suspicious_rows)

        print(f"Detected {len(suspicious_rows)} suspicious accounts. Saved to {OUTPUT_FILE}")
    else:
        print("No suspicious accounts detected.")


if __name__ == "__main__":
    main()
