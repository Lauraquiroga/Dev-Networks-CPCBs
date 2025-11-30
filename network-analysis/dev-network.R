library(igraph)
#install.packages("rstudioapi")
library(rstudioapi)

# To set current directory as working directory:
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()
list.files()

# --- Downstream Driven Scenarios Graph ---

# Read the CSV file
df <- read.csv("../data/downstream_driven.csv", stringsAsFactors = FALSE)

# Get unique usernames (nodes = developers)
nodes <- unique(df$username)

# Create edges based on shared scenarios
# Group by scenario to find developers who co-occur
edge_list <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)

scenarios <- unique(df$scenario)

for (scenario in scenarios) {
  # Get developers in this scenario (across all projects)
  devs <- df$username[df$scenario == scenario]
  
  # Create edges between all pairs of developers in this scenario
  if (length(devs) > 1) {
    pairs <- combn(unique(devs), 2)
    new_edges <- data.frame(
      from = pairs[1, ],
      to = pairs[2, ],
      stringsAsFactors = FALSE
    )
    edge_list <- rbind(edge_list, new_edges)
  }
}

# Remove duplicate edges (since multiple scenarios might connect same developers)
edge_list <- unique(edge_list)

# Create the graph
g <- graph_from_data_frame(d = edge_list, vertices = nodes, directed = FALSE)

# Print graph summary
print(paste("Number of nodes:", vcount(g)))
print(paste("Number of edges:", ecount(g)))
#print(g)

# Plot the graph
plot(g, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4, layout = layout_nicely(g), main = "Downstream Driven Scenarios")

# --- Upstream Driven Scenarios Graph ---
# Read the upstream CSV file
df_up <- read.csv("../data/upstream_driven.csv", stringsAsFactors = FALSE)

# Get unique usernames (nodes = developers)
nodes_up <- unique(df_up$username)

# Create edges based on shared scenarios
edge_list_up <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)

scenarios_up <- unique(df_up$scenario)

for (scenario in scenarios_up) {
  # Get developers in this scenario (across all projects)
  devs_up <- df_up$username[df_up$scenario == scenario]
  # Create edges between all pairs of developers in this scenario
  if (length(devs_up) > 1) {
    pairs_up <- combn(unique(devs_up), 2)
    new_edges_up <- data.frame(
      from = pairs_up[1, ],
      to = pairs_up[2, ],
      stringsAsFactors = FALSE
    )
    edge_list_up <- rbind(edge_list_up, new_edges_up)
  }
}

# Remove duplicate edges
edge_list_up <- unique(edge_list_up)

# Create the graph
g_up <- graph_from_data_frame(d = edge_list_up, vertices = nodes_up, directed = FALSE)

# Print graph summary
print(paste("Number of nodes (upstream):", vcount(g_up)))
print(paste("Number of edges (upstream):", ecount(g_up)))

# Plot the graph
plot(g_up, vertex.size=5, vertex.label=NA, edge.arrow.size=0.4, layout = layout_nicely(g_up), main = "Upstream Driven Scenarios")

