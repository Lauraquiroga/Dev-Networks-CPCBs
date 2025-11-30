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
      
      # Calculate scenario weight as average of their involvements
      scenario_weight <- mean(c(inv1, inv2))
      
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
      
      # Calculate scenario weight as average of their involvements
      scenario_weight <- mean(c(inv1, inv2))
      
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

