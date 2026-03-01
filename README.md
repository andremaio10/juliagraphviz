# ChemoGraph Analyzer (Julia)

**A specialized tool for visualizing and interpreting Chemical Space Networks.**

This software was developed to analyze molecular similarity graphs, allowing researchers to identify molecular scaffolds (via Spanning Trees), detect discontinuous activity landscapes (via Connected Components), and measure network sparsity.

---

## Prerequisites

To run this software, you need **Julia (v1.6 or higher)** and the following packages.

Run this command in your Julia terminal to install them:

```julia
import Pkg
Pkg.add(["GLMakie", "GraphMakie", "Graphs", "NetworkLayout", "DelimitedFiles", "Statistics"])
```

---

## How to Run

1.  **File Placement:** Ensure the main script (`final_project.jl`) and your data files (e.g., `test1.graph`) are in the same folder.
2.  **Open Terminal:** Open a terminal or console in that specific folder.
3.  **Execute:** Run the following command:

```bash
julia final_project.jl
```

The GUI window will open automatically.

---

## User Manual

### 1. Loading Data
The software features a **Universal Loader** that automatically detects the file format.

* **Input:** Type the filename in the text box (e.g., `test1.graph` or `cyclic.txt`).
* **Action:** Click the **"Load Graph"** button.
* **Supported Formats:**
    * *Professor's Format* (`.graph`): Legacy adjacency list (e.g., `1 : 2,3`).
    * *Standard Edge List* (`.txt` / `.csv`): Simple pairs (e.g., `1,2`).

### 2. Analysis Tools (Interpretation)

| Button | Function | Chemical Context |
| :--- | :--- | :--- |
| **Global Stats** | Calculates Density & Avg Degree | Measures the sparsity/density of the chemical space. |
| **Show Spanning Tree** | Highlights the MST in **Red** | Identifies the "Scaffold" (Backbone) by pruning redundant cycles. |
| **Find Islands** | Colors clusters differently | Detects discontinuous "Activity Landscapes" (disconnected families). |
| **Calc. Diameter** | Computes longest shortest path | Measures the maximum mutational distance between molecules. |

### 3. Graph Comparison (Isomorphism)

Check if two chemical graphs share the exact same topology (structure), regardless of node numbering.

1.  Load the **Main Graph** first (see Section 1).
2.  Type the filename of the second graph in the **"Comparison"** box.
3.  **⚠️ IMPORTANT:** Press **ENTER** to save the filename.
4.  Click **"Check Isomorphism"**.

> **Note on Normalization:** The algorithm automatically removes empty nodes and re-indexes the graph to compare active topologies.
> * *Example:* A triangle defined as `1-2-3` will successfully match a triangle defined as `3-4-5`.

---

## Important Usage Note

**You must reload the graph between different analyses.**

Since operations like "Show Spanning Tree" physically change the visual state of the edges (turning them Red/Gray), you cannot switch directly to "Find Islands" without resetting the visualization.

**Correct Workflow:**
1.  Load Graph → Click **"Show Spanning Tree"** → View Result.
2.  Click **"Load Graph"** again (to reset).
3.  Click **"Find Islands"** → View Result.

---

## File Formats

### Type A: Professor's Format (`.graph`)
Used in course materials (Adjacency List).

```text
# Header: Nodes,Edges
3,3
# Adjacency List (ID : Neighbor1, Neighbor2)
1 : 2,3
2 : 3
3 :
```

### Type B: Standard Edge List (`.txt`)
Used for general interoperability.

```text
1,2
2,3
3,1
```

---

## Troubleshooting

* **"File Not Found":** Ensure your terminal is open in the correct folder. Type `pwd()` in the Julia console to check your current directory.
* **Visual Glitches:** If colors look mixed or wrong, click **"Load Graph"** to perform a full reset of the visualization state.