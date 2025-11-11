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

This repository contains Python scripts for extracting, mining, and analyzing developer collaboration networks in CPCB (Cross-Project Correlated Bugs) fixing scenarios:

- **scripts/**: Directory containing the main Python scripts
  - **extract_issues.py**: Extracts GitHub issues from CPCB pattern categorization Excel files. It processes multiple sheets (PS1-PS7, excluding PS8, PS9, PS11) and generates a combined CSV file with issue metadata including fix types and pattern structures.
  - **mine_dev_info.py**: Mines developer participation information from GitHub issues using the GitHub API. It identifies different developer roles (PR authors, bug report authors, commenters, and reviewers) for each issue.
  - **data_analysis.py**: Analyzes the extracted data to generate statistics about issues, projects, and developer participation patterns, comparing downstream-driven fixes vs. upstream-involved fixes.

- **requirements.txt**: Python package dependencies (pandas, openpyxl, python-dotenv, requests)
- **data/**: Directory for input/output data files (not tracked in git)

# References
- Wanwangying Ma et al. “How do developers fix cross-project correlated bugs? a case study on the github scientific python ecosystem”. In: 2017 IEEE/ACM 39th International Conference on Software Engineering (ICSE). IEEE. 2017, pp. 381–392.          
- Ashraf, U., Mayr-Dorn, C., Mashkoor, A., Egyed, A., & Panichella, S. (2021, May). Do communities in developer interaction networks align with subsystem developer teams? An empirical study of open source systems. In 2021 IEEE/ACM Joint 15th International Conference on Software and System Processes (ICSSP) and 16th ACM/IEEE International Conference on Global Software Engineering (ICGSE) (pp. 61-71). IEEE.
- Canfora, G., Cerulo, L., Cimitile, M., & Di Penta, M. (2011, May). Social interactions around cross-system bug fixings: the case of freebsd and openbsd. In Proceedings of the 8th working conference on mining software repositories (pp. 143-152).     
- Herbold, S., Amirfallah, A., Trautsch, F., & Grabowski, J. (2021). A systematic mapping study of developer social network research. Journal of Systems and Software, 171, 110802.
- Kumar, A., & Gupta, A. (2013, February). Evolution of developer social network and its impact on bug fixing process. In Proceedings of the 6th India Software Engineering Conference (pp. 63-72).     
