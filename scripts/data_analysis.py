import csv
from pathlib import Path
from collections import defaultdict, Counter

def analyze_combined_issues(path):
    with path.open(newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    total_issues = len(rows)
    total_prs = sum(1 for r in rows if r["PR"].lower() == "true")
    total_bug_reports = total_issues - total_prs
    projects = {r["GitHub-Issue"].split("#")[0] for r in rows}
    total_projects = len(projects)
    downstream_true = sum(1 for r in rows if r["Downstream-driven-fix"].lower() == "true")
    total_ids = len({r["ID"] for r in rows})

    print("📊 Combined Issues Analysis")
    print(f"Total issues: {total_issues}")
    print(f"PRs: {total_prs}")
    print(f"Bug Reports: {total_bug_reports}")
    print(f"Projects involved: {total_projects}")
    print(f"Downstream-driven-fix (True): {downstream_true}")
    print(f"Downstream-driven-fix (False): {total_issues - downstream_true}")
    print(f"Unique IDs: {total_ids}")
    print()


def analyze_developer_info(path):
    with path.open(newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    # --- Overall developer stats ---
    distinct_users = {r["username"] for r in rows}
    devs_per_issue = defaultdict(set)
    for r in rows:
        devs_per_issue[r["issue"]].add(r["username"])
    avg_devs_per_issue = sum(len(devs) for devs in devs_per_issue.values()) / len(devs_per_issue)

    print("👩‍💻 Developer Info Analysis (All Issues)")
    print(f"Total developers: {len(distinct_users)}")
    print(f"Distinct users: {len(distinct_users)}")
    print(f"Average developers per issue: {avg_devs_per_issue:.2f}")
    print()

    # --- Split by Downstream-driven-fix ---
    downstream_groups = {"true": [], "false": []}
    for r in rows:
        key = r["Downstream-driven-fix"].lower()
        if key in downstream_groups:
            downstream_groups[key].append(r)

    for status, group in downstream_groups.items():
        if not group:
            continue

        # distinct users for this group
        users = {r["username"] for r in group}

        # developers per issue for this group
        devs_per_issue_group = defaultdict(set)
        for r in group:
            devs_per_issue_group[r["issue"]].add(r["username"])
        avg_devs_per_issue_group = sum(len(devs) for devs in devs_per_issue_group.values()) / len(devs_per_issue_group)

        # frequency of each user (how many times they appear)
        user_counts = Counter(r["username"] for r in group)
        avg_appearances_per_user = sum(user_counts.values()) / len(user_counts)

        print(f"👥 Developer Info (Downstream-driven-fix = {status.capitalize()})")
        print(f"Distinct users: {len(users)}")
        print(f"Average developers per issue: {avg_devs_per_issue_group:.2f}")
        print(f"Average times each user appears: {avg_appearances_per_user:.2f}")
        print(f"Top 5 most active users: {user_counts.most_common(5)}")
        print()


def main():
    combined_path = Path("../data/combined_issues.csv")
    devinfo_path = Path("../data/developer_info_enriched.csv")

    analyze_combined_issues(combined_path)
    analyze_developer_info(devinfo_path)


if __name__ == "__main__":
    main()
