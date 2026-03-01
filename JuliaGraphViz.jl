using GLMakie
using GraphMakie
using Graphs
using NetworkLayout
using DelimitedFiles
using Statistics

# ==============================================================================
# SECTION 1: THE BACKEND (LOGIC)
# ==============================================================================

# --- Function 1: Read Professor's Format (.graph) ---
function load_prof_format(filename)
    lines = readlines(filename)
    valid_lines = filter(l -> !startswith(strip(l), "#") && !isempty(strip(l)), lines)
    
    if isempty(valid_lines); error("File appears empty."); end
    
    header = split(split(valid_lines[1], "#")[1], ",")
    n_nodes = parse(Int, strip(header[1]))
    g = SimpleGraph(n_nodes)
    
    for i in 2:length(valid_lines)
        line = split(valid_lines[i], "#")[1]
        if occursin(":", line)
            parts = split(line, ":")
            u = parse(Int, strip(parts[1]))
            if length(parts) > 1 && !isempty(strip(parts[2]))
                for v_str in split(strip(parts[2]), ",")
                    if !isempty(strip(v_str))
                        add_edge!(g, u, parse(Int, strip(v_str)))
                    end
                end
            end
        end
    end
    return g
end

# --- Function 2: Read Standard CSV (.txt) ---
function load_simple_format(filename)
    data = readdlm(filename, ',', Int)
    g = SimpleGraph(maximum(data))
    for row in eachrow(data)
        add_edge!(g, row[1], row[2])
    end
    return g
end

# --- Function 3: Universal Loader ---
function load_graph_file(fname::String)
    if !isfile(fname); return nothing, "File not found"; end
    try
        first_lines = readlines(fname)[1:min(5, countlines(fname))]
        is_prof = any(occursin(":", l) for l in first_lines)
        g = is_prof ? load_prof_format(fname) : load_simple_format(fname)
        return g, is_prof ? "Prof Format (.graph)" : "CSV Format (.txt)"
    catch e
        return nothing, "Parse Error: $e"
    end
end

# --- Function 4: Graph Normalizer (Fixes '3-4-5' vs '1-2-3' issue) ---
function get_active_topology(g::SimpleGraph)
    active_nodes = [v for v in vertices(g) if degree(g, v) > 0]
    if isempty(active_nodes)
        return SimpleGraph(0)
    end
    clean_g, _ = induced_subgraph(g, active_nodes)
    return clean_g
end

# --- Function 5: Algorithms (MST) ---
function get_mst_edges(g::SimpleGraph)
    mst = kruskal_mst(g)
    mst_set = Set([(src(e), dst(e)) for e in mst])
    union!(mst_set, Set([(dst(e), src(e)) for e in mst]))
    return mst_set, (ne(g) - length(mst))
end

# --- Function 6: Stats ---
function calculate_stats(g::SimpleGraph)
    n, e = nv(g), ne(g)
    if n == 0; return "Graph Empty"; end
    dens = n > 1 ? (2 * e) / (n * (n - 1)) : 0.0
    return "Nodes: $n | Edges: $e\nDensity: $(round(dens, digits=4))\nAvg Deg: $(round(mean(degree(g)), digits=2))"
end

# ==============================================================================
# SECTION 2: THE GUI (INTERFACE)
# ==============================================================================

# 1. VISUAL STATE
g_observable = Observable(SimpleGraph(1))
node_colors = Observable{Any}(fill(:lightblue, 1)) 
edge_colors = Observable{Any}(fill(:black, 0))     
edge_widths = Observable{Any}(fill(2.0, 0))        

# 2. LAYOUT
fig = Figure(size = (1300, 950), title = "ChemoGraph Analyzer (Corrected)")
ax = Axis(fig[1, 1], title = "Chemical Space Visualization")
hidedecorations!(ax); hidespines!(ax)
control_panel = fig[1, 2]

p = graphplot!(ax, g_observable, layout=NetworkLayout.Spring(), 
               node_color=node_colors, node_size=30,
               edge_color=edge_colors, edge_width=edge_widths,
               nlabels_textsize=15, nlabels_align=(:center, :center))

# 3. CONTROLS
Label(control_panel[1, 1], "--- 1. Main Graph ---", font=:bold, fontsize=16)
filename_box = Textbox(control_panel[2, 1], placeholder = "test1.graph", width = 200)
load_btn = Button(control_panel[3, 1], label = "Load Main Graph", width = 200)

Label(control_panel[4, 1], "--- 2. Comparison ---", font=:bold, fontsize=16)
compare_box = Textbox(control_panel[5, 1], placeholder = "Type name + ENTER", width = 200)
iso_btn = Button(control_panel[6, 1], label = "Check Isomorphism", width = 200)

Label(control_panel[7, 1], "--- 3. Analysis ---", font=:bold, fontsize=16)
stats_btn = Button(control_panel[8, 1], label = "Global Stats", width = 200)
mst_btn = Button(control_panel[9, 1], label = "Show Spanning Tree", width = 200)
components_btn = Button(control_panel[10, 1], label = "Find Islands", width = 200)
path_btn = Button(control_panel[11, 1], label = "Calc. Diameter", width = 200)

status_label = Label(control_panel[12, 1], "Status: Ready", 
                     fontsize = 14, color = :black, width = 250, word_wrap=true)

# 4. CALLBACKS

on(load_btn.clicks) do _
    input_val = filename_box.stored_string[]
    fname = isempty(input_val) ? "test1.graph" : input_val
    new_g, msg = load_graph_file(fname)
    if new_g !== nothing
        g_observable[] = new_g
        node_colors[] = fill(:lightblue, nv(new_g))
        edge_colors[] = fill(:black, ne(new_g))
        edge_widths[] = fill(2.0, ne(new_g))
        p.nlabels = [string(i) for i in 1:nv(new_g)]
        autolimits!(ax)
        status_label.text = "Loaded Main: $(nv(new_g)) Nodes.\n($msg)"
    else
        status_label.text = "Error: $msg"
    end
end

on(iso_btn.clicks) do _
    println(">>> Isomorphism Clicked") 
    g1_raw = g_observable[]
    if nv(g1_raw) == 0; status_label.text = "Error: Load Main Graph first."; return; end
    
    fname2 = compare_box.stored_string[]
    if isempty(fname2); status_label.text = "⚠️ Input Empty! Press ENTER."; return; end
    
    g2_raw, msg = load_graph_file(fname2)
    
    if g2_raw !== nothing
        try
            status_label.text = "Comparing..." 
            sleep(0.05)
            
            # --- NORMALIZATION ---
            g1_clean = get_active_topology(g1_raw)
            g2_clean = get_active_topology(g2_raw)
            
            # --- SIZE CHECK ---
            if nv(g1_clean) != nv(g2_clean)
                status_label.text = "❌ NO MATCH (Size Mismatch).\nMain: $(nv(g1_clean)), Comp: $(nv(g2_clean))"
                return
            end
            if ne(g1_clean) != ne(g2_clean)
                status_label.text = "❌ NO MATCH (Edge Count Mismatch)."
                return
            end

            # --- THE FIX: USE Graphs.Experimental.has_isomorph ---
            is_iso = Graphs.Experimental.has_isomorph(g1_clean, g2_clean)
            
            if is_iso
                status_label.text = "✅ MATCH FOUND!\nGraphs are Isomorphic."
                println(">>> Result: MATCH")
            else
                status_label.text = "❌ NO MATCH.\nDifferent structures."
                println(">>> Result: NO MATCH")
            end
            
        catch e
            err_msg = sprint(showerror, e)
            status_label.text = "⚠️ ERROR: $err_msg"
            showerror(stdout, e, catch_backtrace())
        end
    else
        status_label.text = "Error loading Comparison file:\n$msg"
    end
end

on(stats_btn.clicks) do _
    status_label.text = calculate_stats(g_observable[])
end

on(mst_btn.clicks) do _
    g = g_observable[]
    if ne(g) > 0
        mst_set, rem_count = get_mst_edges(g)
        new_c, new_w = Symbol[], Float64[]
        for e in edges(g)
            if (src(e),dst(e)) in mst_set
                push!(new_c, :red); push!(new_w, 5.0)
            else
                push!(new_c, :lightgray); push!(new_w, 1.0)
            end
        end
        edge_colors[] = new_c; edge_widths[] = new_w
        status_label.text = "MST Highlighted.\nRedundant edges hidden: $rem_count"
    else
        status_label.text = "Graph is empty."
    end
end

on(components_btn.clicks) do _
    g = g_observable[]
    comps = connected_components(g)
    new_c = fill(:lightblue, nv(g))
    palette = [:red, :green, :orange, :purple, :cyan]
    for (i, c) in enumerate(comps)
        col = palette[(i % length(palette)) + 1]
        for n in c; new_c[n] = col; end
    end
    node_colors[] = new_c
    edge_colors[] = fill(:black, ne(g))
    status_label.text = "Found $(length(comps)) Clusters."
end

on(path_btn.clicks) do _
    g = g_observable[]
    if is_connected(g)
        status_label.text = "Diameter: $(diameter(g)) steps."
    else
        status_label.text = "Graph is Disconnected."
    end
end

display(fig)
println("System Online. Using Graphs.Experimental.has_isomorph.")
readline()