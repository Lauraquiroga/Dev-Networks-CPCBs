library(igraph)
#install.packages("rstudioapi")
library(rstudioapi)

# To set current directory as working directory:
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()
list.files()

# --- Downstream Driven Scenarios Graph ---

# Read the CSV file
df_ds <- read.csv("../data/downstream_driven.csv", stringsAsFactors = FALSE)

# Get unique usernames (nodes = developers)
nodes_ds <- unique(df_ds$username)

# Create edges with weights based on shared scenarios
# edge_weights will store the weight for each pair
edge_weights <- list()

scenarios <- unique(df_ds$scenario)

for (scenario in scenarios) {
  # Get all rows for this scenario
  scenario_data <- df_ds[df_ds$scenario == scenario, ]
  
  # Calculate involvement for each developer in this scenario
  # (sum of max_inv across all projects they appear in for this scenario)
  dev_involvement <- aggregate(max_inv ~ username, data = scenario_data, FUN = sum)
  
  # Get developers in this scenario
  devs <- unique(scenario_data$username)
  
  # Create edges between all pairs of developers in this scenario
  if (length(devs) > 1) {
    pairs <- combn(devs, 2)
    for (i in 1:ncol(pairs)) {
      dev1 <- pairs[1, i]
      dev2 <- pairs[2, i]
      
      # Get involvement values for both developers
      inv1 <- dev_involvement$max_inv[dev_involvement$username == dev1]
      inv2 <- dev_involvement$max_inv[dev_involvement$username == dev2]
      
      # Calculate scenario weight as minimum of their involvements
      scenario_weight <- min(c(inv1, inv2))
      
      # Create edge key (sorted to avoid duplicates)
      edge_key <- paste(sort(c(dev1, dev2)), collapse = "_")
      
      # Add to cumulative weight
      if (is.null(edge_weights[[edge_key]])) {
        edge_weights[[edge_key]] <- scenario_weight
      } else {
        edge_weights[[edge_key]] <- edge_weights[[edge_key]] + scenario_weight
      }
    }
  }
}

# Convert edge_weights list to edge_list dataframe
edge_list <- data.frame(
  from = character(),
  to = character(),
  weight = numeric(),
  stringsAsFactors = FALSE
)

for (edge_key in names(edge_weights)) {
  devs <- strsplit(edge_key, "_")[[1]]
  edge_list <- rbind(edge_list, data.frame(
    from = devs[1],
    to = devs[2],
    weight = edge_weights[[edge_key]],
    stringsAsFactors = FALSE
  ))
}

# Create the graph
g_ds <- graph_from_data_frame(d = edge_list, vertices = nodes_ds, directed = FALSE)

# Add inverse weight as edge attribute (for distance-based metrics)
E(g_ds)$inv_weight <- 1 / E(g_ds)$weight

cat("\n--- Downstream Driven Graph Metrics ---\n")
# Print graph summary
print(paste("Number of nodes (downstream):", vcount(g_ds)))
print(paste("Number of edges (downstream):", ecount(g_ds)))
print(paste("Edge weight range (downstream):", min(E(g_ds)$weight), "to", max(E(g_ds)$weight)))
#print(g)


# Plot the graph
plot(g_ds, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4, layout = layout_nicely(g_ds), main = "Downstream Driven Scenarios")

# --- Downstream Graph Metrics ---
# 1. Number of connected components
num_components_ds <- components(g_ds)$no
cat("Number of connected components:", num_components_ds, "\n")
# 2. Giant component size
giant_component_size_ds <- max(components(g_ds)$csize)
cat("Giant component size:", giant_component_size_ds, "\n")
# 3. Graph density
density_ds <- edge_density(g_ds)
cat("Graph density:", density_ds, "\n")
# 4. Average weighted degree
avg_weighted_degree_ds <- mean(strength(g_ds, weights=E(g_ds)$weight))
cat("Average weighted degree:", avg_weighted_degree_ds, "\n")
# 5. Gini coefficient (degree distribution)
gini_coeff <- function(x) {
  n <- length(x)
  x_sorted <- sort(x)
  index <- 1:n
  return((2 * sum(index * x_sorted)) / (n * sum(x_sorted)) - (n + 1) / n)
}
gini_ds <- gini_coeff(degree(g_ds))
cat("Gini coefficient (degree distribution):", gini_ds, "\n")

# --- Upstream Driven Scenarios Graph ---
# Read the upstream CSV file
df_up <- read.csv("../data/upstream_driven.csv", stringsAsFactors = FALSE)

# Get unique usernames (nodes = developers)
nodes_up <- unique(df_up$username)

# Create edges with weights based on shared scenarios
edge_weights_up <- list()

scenarios_up <- unique(df_up$scenario)

for (scenario in scenarios_up) {
  # Get all rows for this scenario
  scenario_data <- df_up[df_up$scenario == scenario, ]
  
  # Calculate involvement for each developer in this scenario
  dev_involvement <- aggregate(max_inv ~ username, data = scenario_data, FUN = sum)
  
  # Get developers in this scenario
  devs_up <- unique(scenario_data$username)
  
  # Create edges between all pairs of developers in this scenario
  if (length(devs_up) > 1) {
    pairs_up <- combn(devs_up, 2)
    for (i in 1:ncol(pairs_up)) {
      dev1 <- pairs_up[1, i]
      dev2 <- pairs_up[2, i]
      
      # Get involvement values for both developers
      inv1 <- dev_involvement$max_inv[dev_involvement$username == dev1]
      inv2 <- dev_involvement$max_inv[dev_involvement$username == dev2]
      
      # Calculate scenario weight as minimum of their involvements
      scenario_weight <- min(c(inv1, inv2))
      
      # Create edge key (sorted to avoid duplicates)
      edge_key <- paste(sort(c(dev1, dev2)), collapse = "_")
      
      # Add to cumulative weight
      if (is.null(edge_weights_up[[edge_key]])) {
        edge_weights_up[[edge_key]] <- scenario_weight
      } else {
        edge_weights_up[[edge_key]] <- edge_weights_up[[edge_key]] + scenario_weight
      }
    }
  }
}

# Convert edge_weights list to edge_list dataframe
edge_list_up <- data.frame(
  from = character(),
  to = character(),
  weight = numeric(),
  stringsAsFactors = FALSE
)

for (edge_key in names(edge_weights_up)) {
  devs <- strsplit(edge_key, "_")[[1]]
  edge_list_up <- rbind(edge_list_up, data.frame(
    from = devs[1],
    to = devs[2],
    weight = edge_weights_up[[edge_key]],
    stringsAsFactors = FALSE
  ))
}

# Create the graph
g_up <- graph_from_data_frame(d = edge_list_up, vertices = nodes_up, directed = FALSE)

# Add inverse weight as edge attribute (for distance-based metrics)
E(g_up)$inv_weight <- 1 / E(g_up)$weight

cat("\n--- Upstream Driven Graph Metrics ---\n")
# Print graph summary
print(paste("Number of nodes (upstream):", vcount(g_up)))
print(paste("Number of edges (upstream):", ecount(g_up)))
print(paste("Edge weight range (upstream):", min(E(g_up)$weight), "to", max(E(g_up)$weight)))


# Plot the graph
plot(g_up, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4, layout = layout_nicely(g_up), main = "Upstream Driven Scenarios")

# --- Upstream Graph Metrics ---
# 1. Number of connected components
num_components_up <- components(g_up)$no
cat("Number of connected components:", num_components_up, "\n")
# 2. Giant component size
giant_component_size_up <- max(components(g_up)$csize)
cat("Giant component size:", giant_component_size_up, "\n")
# 3. Graph density
density_up <- edge_density(g_up)
cat("Graph density:", density_up, "\n")
# 4. Average weighted degree
avg_weighted_degree_up <- mean(strength(g_up, weights=E(g_up)$weight))
cat("Average weighted degree:", avg_weighted_degree_up, "\n")
# 5. Gini coefficient (degree distribution)
gini_up <- gini_coeff(degree(g_up))
cat("Gini coefficient (degree distribution):", gini_up, "\n")

# --- Degree Distribution (Unweighted) ---
# Downstream Driven Graph
deg_ds <- degree(g_ds, mode = "all")
hist_ds <- hist(deg_ds, breaks = seq(min(deg_ds), max(deg_ds)+1, by=1),
               main = "Degree Distribution (Downstream-driven)",
               xlab = "Degree", ylab = "Frequency", col = "skyblue",
               xaxt = "n", yaxt = "n", xlim = c(min(deg_ds), max(deg_ds)), ylim = c(0, max(tabulate(deg_ds+1))))
# Custom x and y axes with more ticks
axis(1, at = seq(min(deg_ds), max(deg_ds), by = max(1, floor((max(deg_ds)-min(deg_ds))/20))))
axis(2, at = seq(0, max(hist_ds$counts), by = max(1, floor(max(hist_ds$counts)/20))))

# Print degree distribution (downstream)
cat("\nDegree distribution (downstream):\n")
print(table(deg_ds))

# --- Visualize Node with Highest Degree (Downstream) ---
max_deg_ds <- max(deg_ds)
node_max_deg_ds <- names(deg_ds)[which(deg_ds == max_deg_ds)]
cat("\nNode with highest degree (downstream):", node_max_deg_ds, "with degree", max_deg_ds, "\n")

# Highlight this node in the downstream-driven graph
vertex_colors <- rep("lightgray", vcount(g_ds))
vertex_colors[which(V(g_ds)$name == node_max_deg_ds)] <- "red"
plot(g_ds, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4,
  layout = layout_nicely(g_ds), main = paste("Downstream Driven Scenarios\nNode with Highest Degree Highlighted"),
  vertex.color = vertex_colors)

# Upstream Driven Graph
deg_up <- degree(g_up, mode = "all")
hist_up <- hist(deg_up, breaks = seq(min(deg_up), max(deg_up)+1, by=1),
               main = "Degree Distribution (Upstream-involved)",
               xlab = "Degree", ylab = "Frequency", col = "salmon",
               xaxt = "n", yaxt = "n", xlim = c(min(deg_up), max(deg_up)), ylim = c(0, max(tabulate(deg_up+1))))
# Custom x and y axes with more ticks
axis(1, at = seq(min(deg_up), max(deg_up), by = max(1, floor((max(deg_up)-min(deg_up))/20))))
axis(2, at = seq(0, max(hist_up$counts), by = max(1, floor(max(hist_up$counts)/20))))

# Print degree distribution (upstream)
cat("\nDegree distribution (upstream):\n")
print(table(deg_up))

# --- Edge Weight Distribution (Histogram) ---
cat("\nWilcoxon rank-sum test (Mann-Whitney U test) for degree distributions (downstream vs upstream):\n")
wilcox_deg_result <- wilcox.test(deg_ds, deg_up)
print(wilcox_deg_result)
# Downstream Driven Graph
edge_weights_ds <- E(g_ds)$weight
hist(edge_weights_ds, breaks = 30, main = "Edge Weight Distribution (Downstream)",
  xlab = "Edge Weight", ylab = "Frequency", col = "lightblue",
  xaxt = "n", yaxt = "n", xlim = c(min(edge_weights_ds), max(edge_weights_ds)), ylim = c(0, max(tabulate(as.integer(edge_weights_ds)))))
axis(1, at = pretty(edge_weights_ds, n = 20))
axis(2, at = pretty(hist(edge_weights_ds, plot=FALSE)$counts, n = 20))

# Print edge weight distribution (downstream)
cat("\nEdge weight distribution (downstream):\n")
print(summary(edge_weights_ds))
cat("\nEdge weight frequency table (downstream):\n")
print(table(edge_weights_ds))

# Upstream Driven Graph
edge_weights_up <- E(g_up)$weight
hist(edge_weights_up, breaks = 30, main = "Edge Weight Distribution (Upstream)",
  xlab = "Edge Weight", ylab = "Frequency", col = "lightcoral",
  xaxt = "n", yaxt = "n", xlim = c(min(edge_weights_up), max(edge_weights_up)), ylim = c(0, max(tabulate(as.integer(edge_weights_up)))))
axis(1, at = pretty(edge_weights_up, n = 20))
axis(2, at = pretty(hist(edge_weights_up, plot=FALSE)$counts, n = 20))

# Print edge weight distribution (upstream)
cat("\nEdge weight distribution (upstream):\n")
print(summary(edge_weights_up))
cat("\nEdge weight frequency table (upstream):\n")
print(table(edge_weights_up))

# --- Average Path Length (using inverse weights as distances) ---
if (is_connected(g_ds)) {
  avg_path_length_ds <- mean_distance(g_ds, weights = E(g_ds)$inv_weight)
  cat("\nAverage path length (downstream, inv_weight):", avg_path_length_ds, "\n")
} else {
  cat("\nDownstream graph is not connected; computing average path length for the largest component.\n")
  comp_ds <- components(g_ds)
  giant_ds <- induced_subgraph(g_ds, which(comp_ds$membership == which.max(comp_ds$csize)))
  avg_path_length_ds <- mean_distance(giant_ds, weights = E(giant_ds)$inv_weight)
  cat("Average path length (downstream, inv_weight, giant component):", avg_path_length_ds, "\n")
}

if (is_connected(g_up)) {
  avg_path_length_up <- mean_distance(g_up, weights = E(g_up)$inv_weight)
  cat("Average path length (upstream, inv_weight):", avg_path_length_up, "\n")
} else {
  cat("Upstream graph is not connected; computing average path length for the largest component.\n")
  comp_up <- components(g_up)
  giant_up <- induced_subgraph(g_up, which(comp_up$membership == which.max(comp_up$csize)))
  avg_path_length_up <- mean_distance(giant_up, weights = E(giant_up)$inv_weight)
  cat("Average path length (upstream, inv_weight, giant component):", avg_path_length_up, "\n")
}

# --- Betweenness Centrality (using inverse weights as distances) ---
cat("\nTop 10 betweenness centrality (downstream, inv_weight):\n")
betw_ds <- betweenness(g_ds, weights = E(g_ds)$inv_weight, normalized = TRUE)
betw_ds_sorted <- sort(betw_ds, decreasing = TRUE)
print(head(betw_ds_sorted, 10))

# --- Betweenness Centrality Statistics and Plots (Downstream) ---
cat("\nBetweenness centrality stats (downstream):\n")
cat("\nFull betweenness centrality distribution (downstream):\n")
print(betw_ds)
cat("Mean:", mean(betw_ds), "\n")
cat("Variance:", var(betw_ds), "\n")

hist(betw_ds, breaks = 30, main = "Betweenness Centrality Distribution (Downstream)",
  xlab = "Betweenness Centrality", ylab = "Frequency", col = "lightgreen")
boxplot(betw_ds, main = "Betweenness Centrality Boxplot (Downstream)", horizontal = TRUE, col = "lightgreen")

cat("\nTop 10 betweenness centrality (upstream, inv_weight):\n")
betw_up <- betweenness(g_up, weights = E(g_up)$inv_weight, normalized = TRUE)
betw_up_sorted <- sort(betw_up, decreasing = TRUE)
print(head(betw_up_sorted, 10))

# --- Betweenness Centrality Statistics and Plots (Upstream) ---
cat("\nBetweenness centrality stats (upstream):\n")
cat("\nFull betweenness centrality distribution (upstream):\n")
print(betw_up)
cat("Mean:", mean(betw_up), "\n")
cat("Variance:", var(betw_up), "\n")
hist(betw_up, breaks = 30, main = "Betweenness Centrality Distribution (Upstream)",
  xlab = "Betweenness Centrality", ylab = "Frequency", col = "orange")
boxplot(betw_up, main = "Betweenness Centrality Boxplot (Upstream)", horizontal = TRUE, col = "orange")

# --- Kolmogorov–Smirnov Test: Compare Betweenness Distributions ---
cat("\nKolmogorov–Smirnov test (KS test) for betweenness centrality distributions (downstream vs upstream):\n")
ks_result <- ks.test(betw_ds, betw_up)
print(ks_result)

cat("\nWilcoxon rank-sum test (Mann-Whitney U test) for betweenness centrality distributions (downstream vs upstream):\n")
wt_result <- wilcox.test(betw_ds, betw_up)
print(wt_result)

# --- Plot Networks Color-Coded by Betweenness Centrality Rank ---

# Helper function to assign colors by rank
get_centrality_colors <- function(names_vec, betw_sorted) {
  colors <- rep("lightgray", length(names_vec))
  top1 <- names(betw_sorted)[1]
  top5 <- names(betw_sorted)[2:5]
  top10 <- names(betw_sorted)[6:10]
  colors[names_vec == top1] <- "red"
  colors[names_vec %in% top5] <- "orange"
  colors[names_vec %in% top10] <- "yellow"
  return(colors)
}

# Downstream network plot
colors_ds <- get_centrality_colors(V(g_ds)$name, betw_ds_sorted)
plot(g_ds, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4,
  layout = layout_nicely(g_ds), main = "Downstream-driven: Nodes by Betweenness Rank",
  vertex.color = colors_ds)
legend("topright", legend = c("Top 1", "Top 2-5", "Top 6-10", "Other"),
    col = c("red", "orange", "yellow", "lightgray"), pch = 19, pt.cex = 1.5, bty = "n")

# Upstream network plot
colors_up <- get_centrality_colors(V(g_up)$name, betw_up_sorted)
plot(g_up, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4,
  layout = layout_nicely(g_up), main = "Upstream-involved: Nodes by Betweenness Rank",
  vertex.color = colors_up)
legend("topright", legend = c("Top 1", "Top 2-5", "Top 6-10", "Other"),
    col = c("red", "orange", "yellow", "lightgray"), pch = 19, pt.cex = 1.5, bty = "n")


# --- Louvain Community Detection (using edge weights) ---
cat("\nLouvain community detection (downstream, using weights):\n")
comm_ds <- cluster_louvain(g_ds, weights = E(g_ds)$weight)
print(comm_ds)
cat("Membership table (downstream):\n")
print(table(membership(comm_ds)))

cat("\nLouvain community detection (upstream, using weights):\n")
comm_up <- cluster_louvain(g_up, weights = E(g_up)$weight)
print(comm_up)
cat("Membership table (upstream):\n")
print(table(membership(comm_up)))


# --- Plot Networks Color-Coded by Louvain Communities ---
set.seed(42) # seed for the colors
comm_colors_ds <- rainbow(length(unique(membership(comm_ds))))
vertex_colors_ds <- comm_colors_ds[membership(comm_ds)]
plot(g_ds, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4,
  layout = layout_nicely(g_ds), main = "Downstream: Louvain Communities",
  vertex.color = vertex_colors_ds)
legend("topright", legend = paste("Community", sort(unique(membership(comm_ds)))),
    col = comm_colors_ds, pch = 19, pt.cex = 1.2, bty = "n")

comm_colors_up <- rainbow(length(unique(membership(comm_up))))
vertex_colors_up <- comm_colors_up[membership(comm_up)]
plot(g_up, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4,
  layout = layout_nicely(g_up), main = "Upstream: Louvain Communities",
  vertex.color = vertex_colors_up)
legend("bottomleft", legend = paste("Community", sort(unique(membership(comm_up)))),
    col = comm_colors_up, pch = 19, pt.cex = 1.2, bty = "n")

# --- Load Developer Affiliations and Color-Code Networks by Primary Affiliation ---

# Read the developer affiliations CSV file
df_aff <- read.csv("../data/dev_affiliations_v2.csv", stringsAsFactors = FALSE)

# Filter to only primary affiliations
df_primary <- df_aff[df_aff$AffiliationType == "primary", ]

# Create a lookup table: username -> primary project
primary_affiliation_lookup <- setNames(df_primary$Project, df_primary$Username)

# Get unique primary affiliations (projects)
unique_projects <- unique(df_primary$Project)
n_projects <- length(unique_projects)

# Calculate project frequencies across all nodes
all_nodes <- union(V(g_ds)$name, V(g_up)$name)
project_counts_all <- table(primary_affiliation_lookup[all_nodes])
# Sort projects by frequency (most frequent first)
projects_by_frequency <- names(sort(project_counts_all, decreasing = TRUE))

# Create a highly distinguishable color palette
# Manually selected colors that are maximally distinct
distinct_colors <- c(
  "#E41A1C",  # Red
  "#377EB8",  # Blue
  "#4DAF4A",  # Green
  "#FF7F00",  # Orange
  "#984EA3",  # Purple
  "#FFFF33",  # Yellow
  "#A65628",  # Brown
  "#F781BF",  # Pink
  "#00CED1",  # Dark Turquoise
  "#32CD32",  # Lime Green
  "#8B4513",  # Saddle Brown
  "#FF1493",  # Deep Pink
  "#1E90FF",  # Dodger Blue
  "#FFD700",  # Gold
  "#8B008B",  # Dark Magenta
  "#00FA9A",  # Medium Spring Green
  "#DC143C",  # Crimson
  "#4169E1",  # Royal Blue
  "#FF6347",  # Tomato
  "#9370DB"   # Medium Purple
)

# Assign colors: most frequent projects get the most distinct colors
project_colors <- rep("#CCCCCC", n_projects)  # Default gray for less common projects
names(project_colors) <- unique_projects

for (i in seq_along(projects_by_frequency)) {
  if (i <= length(distinct_colors)) {
    project_colors[projects_by_frequency[i]] <- distinct_colors[i]
  }
}

# Function to assign colors to nodes based on primary affiliation
get_affiliation_colors <- function(graph, affiliation_lookup, color_palette) {
  node_names <- V(graph)$name
  colors <- rep("lightgray", length(node_names))  # Default color for nodes without affiliation
  
  for (i in seq_along(node_names)) {
    username <- node_names[i]
    if (username %in% names(affiliation_lookup)) {
      primary_project <- affiliation_lookup[[username]]
      if (primary_project %in% names(color_palette)) {
        colors[i] <- color_palette[[primary_project]]
      }
    }
  }
  
  return(colors)
}

# --- Plot Downstream Network Color-Coded by Primary Affiliation ---
affiliation_colors_ds <- get_affiliation_colors(g_ds, primary_affiliation_lookup, project_colors)

plot(g_ds, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4,
  layout = layout_with_fr(g_ds), main = "Downstream: Nodes by Primary Affiliation",
  vertex.color = affiliation_colors_ds)

# Create legend with top projects (by frequency)
project_counts_ds <- table(primary_affiliation_lookup[V(g_ds)$name])
top_projects_ds <- names(sort(project_counts_ds, decreasing = TRUE)[1:min(10, length(project_counts_ds))])
legend("topright", legend = c(top_projects_ds, "No primary aff."),
    col = c(project_colors[top_projects_ds], "lightgray"), 
    pch = 19, pt.cex = 1.0, cex = 0.7, bty = "n")

# --- Plot Upstream Network Color-Coded by Primary Affiliation ---
affiliation_colors_up <- get_affiliation_colors(g_up, primary_affiliation_lookup, project_colors)

plot(g_up, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4,
  layout = layout_nicely(g_up), main = "Upstream: Nodes by Primary Affiliation",
  vertex.color = affiliation_colors_up)

# Create legend with top projects (by frequency)
project_counts_up <- table(primary_affiliation_lookup[V(g_up)$name])
top_projects_up <- names(sort(project_counts_up, decreasing = TRUE)[1:min(10, length(project_counts_up))])
legend("topleft", legend = c(top_projects_up, "No primary aff."),
  col = c(project_colors[top_projects_up], "lightgray"), 
  pch = 19, pt.cex = 1.0, cex = 0.7, bty = "n")

# --- Print Affiliation Statistics ---
cat("\n--- Primary Affiliation Statistics ---\n")
cat("Downstream Network:\n")
cat("Nodes with primary affiliation:", sum(V(g_ds)$name %in% names(primary_affiliation_lookup)), "/", vcount(g_ds), "\n")
cat("Top 5 primary affiliations:\n")
print(head(sort(project_counts_ds, decreasing = TRUE), 5))

cat("\nUpstream Network:\n")
cat("Nodes with primary affiliation:", sum(V(g_up)$name %in% names(primary_affiliation_lookup)), "/", vcount(g_up), "\n")
cat("Top 5 primary affiliations:\n")
print(head(sort(project_counts_up, decreasing = TRUE), 5))

# --- Normalized Mutual Information (NMI) ---
# Compare Louvain communities with project affiliations

# Function to compute NMI
compute_nmi <- function(graph, louvain_membership, affiliation_lookup) {
  node_names <- V(graph)$name
  
  # Create affiliation membership vector (aligned with graph nodes)
  affiliation_membership <- rep(NA, length(node_names))
  
  for (i in seq_along(node_names)) {
    username <- node_names[i]
    if (username %in% names(affiliation_lookup)) {
      affiliation_membership[i] <- affiliation_lookup[[username]]
    }
  }
  
  # Filter out nodes without affiliation
  has_affiliation <- !is.na(affiliation_membership)
  louvain_filtered <- louvain_membership[has_affiliation]
  affiliation_filtered <- affiliation_membership[has_affiliation]
  
  # Convert project names to numeric factors
  affiliation_numeric <- as.numeric(factor(affiliation_filtered))
  
  # Use igraph's compare function with method "nmi"
  nmi_value <- compare(louvain_filtered, affiliation_numeric, method = "nmi")
  
  return(list(
    nmi = nmi_value,
    n_nodes_with_affiliation = sum(has_affiliation),
    n_louvain_communities = length(unique(louvain_filtered)),
    n_project_affiliations = length(unique(affiliation_filtered))
  ))
}

cat("\n--- Normalized Mutual Information (NMI) ---\n")
cat("Comparing Louvain communities with project affiliations\n\n")

# Downstream network NMI
nmi_ds <- compute_nmi(g_ds, membership(comm_ds), primary_affiliation_lookup)
cat("Downstream Network:\n")
cat("  NMI:", nmi_ds$nmi, "\n")
cat("  Nodes with affiliation:", nmi_ds$n_nodes_with_affiliation, "/", vcount(g_ds), "\n")
cat("  Number of Louvain communities:", nmi_ds$n_louvain_communities, "\n")
cat("  Number of project affiliations:", nmi_ds$n_project_affiliations, "\n\n")

# Upstream network NMI
nmi_up <- compute_nmi(g_up, membership(comm_up), primary_affiliation_lookup)
cat("Upstream Network:\n")
cat("  NMI:", nmi_up$nmi, "\n")
cat("  Nodes with affiliation:", nmi_up$n_nodes_with_affiliation, "/", vcount(g_up), "\n")
cat("  Number of Louvain communities:", nmi_up$n_louvain_communities, "\n")
cat("  Number of project affiliations:", nmi_up$n_project_affiliations, "\n")
