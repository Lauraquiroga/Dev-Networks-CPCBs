# Developer Collaboration Networks in CPCB Fixing Scenarios
Modern software ecosystems are highly interdependent, with numerous open-source projects relying on
shared libraries and frameworks. This interconnectedness creates a complex environment where defects
in one project can propagate to others, leading to Cross-Project-Correlated Bugs (CPCBs). The term
CPCB was first defined by Ma et al. (2017) to describe defects in a downstream project whose root cause
originates in an upstream dependency.          

Although prior research has examined CPCBs through qualitative methods (such as manual analyses
and interviews) there is limited understanding of the developer collaboration structures that arise during
their resolution. Gaining insight into how developers interact across project boundaries is essential for
uncovering how information, responsibility, and expertise circulate within these interconnected software
ecosystems.         

This project aims to fill that gap by modeling and analyzing developer collaboration networks derived
from CPCB fixing scenarios, comparing how coordination patterns differ between two broad categories
of bug resolution: (1) downstream-driven fixes, where the downstream project independently implements
a solution, and (2) upstream-involved fixes, where coordination with upstream maintainers is required.
Ultimately, the goal of this project is to provide an empirical understanding of how cross-project
collaboration shapes the resolution of interdependent bugs, contributing to both the network science of
collaboration and the broader study of software maintenance in large, distributed ecosystems.        

# Project Structure
         
This section of the README file was generated using AI.

This repository contains scripts and data for extracting, mining, and analyzing developer collaboration networks in CPCB (Cross-Project Correlated Bugs) fixing scenarios:

## Directories

- **scripts-data-generation/**: Python scripts for data extraction and pre-processing
  - **extract_issues.py**: Extracts GitHub issues from CPCB pattern categorization Excel files. Processes multiple sheets and generates a combined CSV file with issue metadata including fix types and pattern structures.
  - **mine_dev_info.py**: Mines developer participation information from GitHub issues using the GitHub API. Identifies different developer roles (PR authors, bug report authors, commenters, and reviewers) for each issue.
  - **data_analysis.py**: Analyzes the extracted data to generate statistics about issues, projects, and developer participation patterns, comparing downstream-driven fixes vs. upstream-involved fixes.
  - **derive_dev_affiliation.py**: Derives developer affiliations with projects based on their participation patterns.
  - **detect_bots.py**: Identifies and filters out bot accounts from the developer data.
  - **bot_comment_parser.py**: Parses bot comments to extract relevant information.
  - **process_developer_involvement.py**: Processes and quantifies developer involvement across scenarios.
  - **remove_devs_from_list.py**: Utility for removing specific developers from analysis.

- **network-analysis/**: R scripts for network analysis and visualization
  - **dev_network.R**: Main network analysis script. Constructs and analyzes developer collaboration networks for both downstream-driven and upstream-involved scenarios. Computes network metrics (degree distribution, betweenness centrality, community detection), performs statistical tests (Wilcoxon, KS test), and generates visualizations color-coded by betweenness centrality, Louvain communities, and primary project affiliations.

- **data/**: Directory for input/output data files. Intermediate files used in the data cleaning process are not tracked in github. Key CSV files tracked here include:

    - **combined_issues.csv**: Aggregated list of all CPCB-related issues across projects and patterns.
    - **developer_info.csv** / **developer_info_cleaned.csv**: Developer participation and role information for each issue.
    - **dev_affiliations_primary.csv**: Project affiliation of each developer, used as node attributes in network analysis.
    - **downstream_driven.csv**: List of developers involved in downstream-driven fix scenarios (used in network analysis).
    - **upstream_driven.csv**: List of developers involved in upstream-involved fix scenarios (used in network analysis).

  Note: the main CSV files used in the network analysis script are:
    - **downstream_driven.csv** (list of developers in downstream-driven fixes)
    - **upstream_driven.csv** (list of developers in upstream-involved scenarios)
    - **dev_affiliations_primary.csv** (project affiliation of each developer, used as node attributes in the network)

- **assets/**: Supporting files and resources

## Configuration Files

- **requirements.txt**: Python package dependencies

# References
- Wanwangying Ma et al. “How do developers fix cross-project correlated bugs? a case study on the github scientific python ecosystem”. In: 2017 IEEE/ACM 39th International Conference on Software Engineering (ICSE). IEEE. 2017, pp. 381–392.          
- Ashraf, U., Mayr-Dorn, C., Mashkoor, A., Egyed, A., & Panichella, S. (2021, May). Do communities in developer interaction networks align with subsystem developer teams? An empirical study of open source systems. In 2021 IEEE/ACM Joint 15th International Conference on Software and System Processes (ICSSP) and 16th ACM/IEEE International Conference on Global Software Engineering (ICGSE) (pp. 61-71). IEEE.
- Canfora, G., Cerulo, L., Cimitile, M., & Di Penta, M. (2011, May). Social interactions around cross-system bug fixings: the case of freebsd and openbsd. In Proceedings of the 8th working conference on mining software repositories (pp. 143-152).     
- Herbold, S., Amirfallah, A., Trautsch, F., & Grabowski, J. (2021). A systematic mapping study of developer social network research. Journal of Systems and Software, 171, 110802.
- Kumar, A., & Gupta, A. (2013, February). Evolution of developer social network and its impact on bug fixing process. In Proceedings of the 6th India Software Engineering Conference (pp. 63-72).
