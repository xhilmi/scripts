#!/bin/bash

# Function to get project IDs interactively
get_project_ids() {
    echo "=== GKE Cluster Autoscaler Checker ==="
    echo ""
    echo "Choose input method:"
    echo "1) Use default project list"
    echo "2) Enter project IDs manually"
    echo "3) Load from current gcloud projects"
    echo ""
    read -p "Select option (1-3): " choice
    echo ""
    
    case $choice in
        1)
            # Default project list
            PROJECT_IDS=(
                "wowpass"
                "wowcarstensz" 
                "wowproject"
                "wowsign"
            )
            echo "Using default projects:"
            printf "  - %s\n" "${PROJECT_IDS[@]}"
            ;;
        2)
            # Manual input
            echo "Enter project IDs (one per line, press Enter twice when done):"
            PROJECT_IDS=()
            while true; do
                read -p "Project ID: " project_id
                if [[ -z "$project_id" ]]; then
                    break
                fi
                PROJECT_IDS+=("$project_id")
                echo "  ✓ Added: $project_id"
            done
            ;;
        3)
            # Load from gcloud
            echo "Available projects from gcloud:"
            available_projects=($(gcloud projects list --format="value(projectId)" 2>/dev/null))
            
            if [[ ${#available_projects[@]} -eq 0 ]]; then
                echo "❌ No projects found. Please run 'gcloud auth login' first."
                exit 1
            fi
            
            for i in "${!available_projects[@]}"; do
                echo "  $((i+1))) ${available_projects[$i]}"
            done
            echo ""
            
            echo "Select projects (enter numbers separated by spaces, e.g: 1 3 4):"
            read -p "Selection: " selections
            
            PROJECT_IDS=()
            for num in $selections; do
                index=$((num-1))
                if [[ $index -ge 0 && $index -lt ${#available_projects[@]} ]]; then
                    PROJECT_IDS+=("${available_projects[$index]}")
                    echo "  ✓ Selected: ${available_projects[$index]}"
                else
                    echo "  ❌ Invalid selection: $num"
                fi
            done
            ;;
        *)
            echo "❌ Invalid choice. Using default projects."
            PROJECT_IDS=(
                "wowpass"
                "wowcarstensz"
                "wowproject" 
                "wowsign"
            )
            ;;
    esac
    
    if [[ ${#PROJECT_IDS[@]} -eq 0 ]]; then
        echo "❌ No projects selected. Exiting."
        exit 1
    fi
    
    echo ""
    echo "Final project list:"
    printf "  - %s\n" "${PROJECT_IDS[@]}"
    echo ""
    read -p "Continue with these projects? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled by user."
        exit 1
    fi
}

# Get project IDs interactively
get_project_ids

# Generate timestamp for filename
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
OUTPUT_FILE="cluster-autoscaler-${TIMESTAMP}.csv"

echo ""
echo "Starting GKE cluster autoscaler check at: $(date)"
echo "Output file: $OUTPUT_FILE"
echo "Processing ${#PROJECT_IDS[@]} projects..."
echo ""

# Clear file and add CSV Header with timestamp
echo "# Generated on: $(date)" > "$OUTPUT_FILE"
echo "# Projects: ${PROJECT_IDS[*]}" >> "$OUTPUT_FILE"
echo "project_id,cluster_name,location,location_type,nodepool_name,initial_nodes,min_nodes,max_nodes,current_nodes,status" >> "$OUTPUT_FILE"

for PROJECT_ID in "${PROJECT_IDS[@]}"; do
  echo "Processing: $PROJECT_ID"
  
  # Check if project exists
  if ! gcloud projects describe "$PROJECT_ID" --quiet >/dev/null 2>&1; then
    echo "  ⚠️  Project $PROJECT_ID not accessible. Skipping..."
    continue
  fi
  
  gcloud container clusters list \
    --project "$PROJECT_ID" \
    --format="csv[no-heading](name, location, locationType)" \
    --quiet 2>/dev/null | while IFS=, read -r NAME LOC TYPE; do
    
    NAME=$(echo "$NAME" | xargs)
    LOC=$(echo "$LOC" | xargs) 
    TYPE=$(echo "$TYPE" | xargs)
    
    if [[ "$TYPE" == "ZONE" ]]; then
      gcloud container node-pools list \
        --project "$PROJECT_ID" \
        --cluster="$NAME" \
        --zone="$LOC" \
        --format="csv[no-heading](name, initialNodeCount, autoscaling.minNodeCount, autoscaling.maxNodeCount, status)" \
        --quiet 2>/dev/null | while IFS=, read -r POOL_NAME INITIAL MIN MAX STATUS; do
        echo "$PROJECT_ID,$NAME,$LOC,$TYPE,$POOL_NAME,$INITIAL,$MIN,$MAX,-,$STATUS" >> "$OUTPUT_FILE"
      done
    else
      gcloud container node-pools list \
        --project "$PROJECT_ID" \
        --cluster="$NAME" \
        --region="$LOC" \
        --format="csv[no-heading](name, initialNodeCount, autoscaling.minNodeCount, autoscaling.maxNodeCount, status)" \
        --quiet 2>/dev/null | while IFS=, read -r POOL_NAME INITIAL MIN MAX STATUS; do
        echo "$PROJECT_ID,$NAME,$LOC,$TYPE,$POOL_NAME,$INITIAL,$MIN,$MAX,-,$STATUS" >> "$OUTPUT_FILE"
      done
    fi
  done
done

echo ""
echo "✅ Complete! Output saved to: $OUTPUT_FILE"
echo "Report generated at: $(date)"
