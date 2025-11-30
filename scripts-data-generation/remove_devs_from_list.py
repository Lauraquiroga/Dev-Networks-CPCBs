"""
remove_devs_from_list.py

Removes rows from ../data/developer_info.csv if their Username appears in ../data/suspicious_bots.csv.
Writes the filtered developer info to ../data/developer_info_cleaned.csv.
"""

import csv

DEVINFO_CSV = "../data/developer_info.csv"
SUSPICIOUS_CSV = "../data/suspicious_bots.csv"
OUTPUT_CSV = "../data/developer_info_cleaned.csv"

# Read suspicious usernames into a set
with open(SUSPICIOUS_CSV, newline="", encoding="utf-8") as f:
	reader = csv.DictReader(f)
	suspicious_usernames = {row["Username"].strip() for row in reader}

# Filter developer_info.csv
with open(DEVINFO_CSV, newline="", encoding="utf-8") as f_in, \
	 open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f_out:
	reader = csv.DictReader(f_in)
	writer = csv.DictWriter(f_out, fieldnames=reader.fieldnames)
	writer.writeheader()
	removed = 0
	kept = 0
	for row in reader:
		if row["Username"].strip() not in suspicious_usernames:
			writer.writerow(row)
			kept += 1
		else:
			removed += 1

print(f"Removed {removed} suspicious developers. Kept {kept} developers. Cleaned file written to {OUTPUT_CSV}")
