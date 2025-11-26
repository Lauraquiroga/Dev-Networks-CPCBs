"""
bot_comment_parser.py

This script analyzes bot comments on GitHub issues that were flagged as migrated from other platforms. 
It fetches comments from the GitHub API for each migrated issue, extracts comments made by known bot accounts, and identifies all GitHub users mentioned by these bots.

Workflow:
1. Loads a list of migrated issues from a CSV (../data/migrated_issues.csv).
2. For each issue, fetches all comments using the GitHub API.
3. Filters comments authored by known bot accounts (e.g., numpy-gitbot, scipy-gitbot).
4. Extracts all GitHub username mentions from these bot comments.
5. Writes two CSV outputs:
    - ../data/bot_comments.csv: All bot-authored comments with metadata.
    - ../data/mentioned_users.csv: All unique (issue, username) pairs where a bot mentioned a user.

Input:  ../data/migrated_issues.csv (list of GitHub issues)
Output: ../data/bot_comments.csv, ../data/mentioned_users.csv
"""

import csv
import os
import re
import requests
from dotenv import load_dotenv

# ----------------------------
# CONFIGURATION
# ----------------------------

INPUT_CSV = "../data/migrated_issues.csv"          # CSV listing the GitHub issues
BOT_COMMENTS_CSV = "../data/bot_comments.csv"
MENTIONED_USERS_CSV = "../data/mentioned_users.csv"

load_dotenv()  # Loads variables from .env into environment
GITHUB_TOKEN = os.getenv('PAC') # Get Personal Access Token
HEADERS = {"Authorization": f"Bearer {GITHUB_TOKEN}"}

# Bot usernames (registered as normal GitHub users)
BOT_USERNAMES = {"numpy-gitbot", "scipy-gitbot"}

# Regex for GitHub username mentions
MENTION_REGEX = re.compile(r"@([a-zA-Z0-9](?:[a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?)")


# ----------------------------
# FUNCTIONS
# ----------------------------

def parse_issue_ref(ref):
    owner_repo, num = ref.split("#")
    owner, repo = owner_repo.split("/")
    return owner, repo, int(num)


def fetch_issue_comments(owner, repo, number):
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{number}/comments"
    comments, page = [], 1

    while True:
        resp = requests.get(url, headers=HEADERS,
                            params={"page": page, "per_page": 100})
        resp.raise_for_status()
        data = resp.json()
        if not data:
            break
        comments.extend(data)
        page += 1

    return comments


def extract_mentions(text):
    return MENTION_REGEX.findall(text)

# ----------------------------
# MAIN EXTRACTION LOGIC
# ----------------------------

bot_comment_rows = []
mentioned_user_pairs = set()   # <-- dedup set

with open(INPUT_CSV, newline="") as f:
    reader = csv.DictReader(f)

    for row in reader:
        issue_ref = row["GitHub-Issue"].strip()
        owner, repo, issue_number = parse_issue_ref(issue_ref)

        print(f"Processing {issue_ref} ...")

        comments = fetch_issue_comments(owner, repo, issue_number)

        for c in comments:
            user = c.get("user", {})
            login = user.get("login")

            if login in BOT_USERNAMES:
                bot_comment_rows.append({
                    "issue": issue_ref,
                    "comment_id": c.get("id"),
                    "created_at": c.get("created_at"),
                    "user_login": login,
                    "body": (c.get("body", "") or "").replace("\n", " ").strip()
                })

                mentions = extract_mentions(c.get("body", "") or "")
                for m in mentions:
                    mentioned_user_pairs.add((issue_ref, m))  # <-- dedup



# ----------------------------
# WRITE CSV OUTPUT
# ----------------------------

print(f"\nWriting {BOT_COMMENTS_CSV} ...")
with open(BOT_COMMENTS_CSV, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=["issue", "comment_id", "created_at", "user_login", "body"]
    )
    writer.writeheader()
    writer.writerows(bot_comment_rows)

print(f"Writing {MENTIONED_USERS_CSV} ...")
with open(MENTIONED_USERS_CSV, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["issue", "username"])
    writer.writeheader()
    for issue, username in sorted(mentioned_user_pairs):
        writer.writerow({"issue": issue, "username": username})