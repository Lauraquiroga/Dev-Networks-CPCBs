"""
Mine Developer Information from GitHub Issues

This script loads a GitHub personal access token from a .env file, reads a CSV of combined issues, and uses the GitHub API 
to fetch additional information about repositories or issues. It is designed to automate the enrichment of issue data with 
live GitHub metadata for further analysis.
"""

import os
import csv
import requests
from dotenv import load_dotenv
from collections import defaultdict

load_dotenv()  # Loads variables from .env into environment
GITHUB_TOKEN = os.getenv('PAC') # Get Personal Access Token
HEADERS = {'Authorization': f'token {GITHUB_TOKEN}'}

# GitHub API URL
API_URL = "https://api.github.com/repos/"

# Input and Output file paths
INPUT_CSV = '../data/combined_issues.csv'
OUTPUT_CSV = '../data/developer_info.csv'

# --- Helper Functions ---

def parse_issue_ref(issue_ref):
    """Parse the issue reference to extract owner, repo, and issue number."""
    try:
        repo_path, issue_num = issue_ref.split('#')
        owner, repo = repo_path.split('/')
        return owner, repo, issue_num
    except ValueError:
        return None, None, None


def safe_request(url):
    """Perform a safe GET request with basic rate-limit handling."""
    while True:
        response = requests.get(url, headers=HEADERS)
        # if response.status_code == 403 and 'X-RateLimit-Remaining' in response.headers:
        #     reset_time = int(response.headers.get('X-RateLimit-Reset', time.time() + 60))
        #     wait_for = max(0, reset_time - int(time.time()) + 5)
        #     print(f"Rate limit reached, waiting {wait_for} seconds...")
        #     time.sleep(wait_for)
        if response.status_code == 403:
            print(f"Rate limit exceeded. Try again later.")
            return None
        elif response.status_code == 404:
            print(f"⚠️ Not found: {url}")
            return None
        elif response.status_code != 200:
            print(f"⚠️ Error {response.status_code} on {url}")
            return None
        else:
            return response.json()
        
# --- Get developer participation per issue ---
def process_issue(issue_ref, is_pr):
    owner, repo, issue_num = parse_issue_ref(issue_ref)
    if not owner:
        return {}

    issue_url = f"{API_URL}{owner}/{repo}/issues/{issue_num}"
    issue_data = safe_request(issue_url)
    if not issue_data:
        return {}

    # dictionary {username: {'PR-author': bool, 'BugReport-author': bool, 'commented': bool, 'reviewer': bool}}
    dev_roles = defaultdict(lambda: {
        'PR-author': False,
        'BugReport-author': False,
        'Commented': False,
        'Reviewer': False
    })

    # --- Author ---
    if issue_data.get('user'):
        username = issue_data['user']['login']
        if is_pr:
            dev_roles[username]['PR-author'] = True
        else:
            dev_roles[username]['BugReport-author'] = True

    # --- Commenters ---
    comments_url = issue_data.get('comments_url')
    if comments_url:
        comments = safe_request(comments_url)
        if comments:
            for c in comments:
                if c.get('user'):
                    username = c['user']['login']
                    dev_roles[username]['Commented'] = True

    # --- Reviewers (PR only) ---
    if is_pr:
        pr_reviews_url = f"{API_URL}{owner}/{repo}/pulls/{issue_num}/reviews"
        reviews = safe_request(pr_reviews_url)
        if reviews:
            for r in reviews:
                if r.get('user'):
                    username = r['user']['login']
                    dev_roles[username]['Reviewer'] = True

    return dev_roles


# --- Main execution ---
def main():
    all_rows = []

    with open(INPUT_CSV, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            issue_ref = row['GitHub-Issue'].strip()
            is_pr = row['PR'].strip().lower() == 'true'
            print(f"Processing {issue_ref} (PR={is_pr})...")

            dev_roles = process_issue(issue_ref, is_pr)

            for username, roles in dev_roles.items():
                all_rows.append({
                    'Username': username,
                    'Issue': issue_ref,
                    'PR-author': roles['PR-author'],
                    'BugReport-author': roles['BugReport-author'],
                    'Commented': roles['Commented'],
                    'Reviewer': roles['Reviewer'],
                    'Fix-type': row['Fix-type'],
                    'Pattern-Structure': row['Pattern-Structure'],
                    'Downstream-driven-fix': row['Downstream-driven-fix'],
                    'Scenario': row['Scenario'],
                })


    # --- Save combined results ---
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'Username', 'Issue', 'PR-author', 'BugReport-author', 'Commented', 'Reviewer', 'Fix-type', 'Pattern-Structure', 'Downstream-driven-fix', 'Scenario'
        ])
        writer.writeheader()
        writer.writerows(all_rows)

    print(f"✅ Developer information saved to {OUTPUT_CSV}")


if __name__ == "__main__":
    main()