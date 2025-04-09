#!/bin/bash

set -e
ldconfig

# --- Default values for arguments ---
SEQUENCE=""
JOB_NAME_WITH_TIMESTAMP=""
MODEL_PRESET="monomer"
DB_PRESET="reduced_dbs"
GPU_RELAX_PRESET="false"
EXTRA_ARGS=()

# --- Function to display usage and exit ---
usage() {
  echo "Usage: $0 --sequence <sequence> --output_dir <job_name_with_timestamp> [--model_preset <preset>] [--db_preset <preset>] [--use_gpu_relax <true|false>] [extra arguments for run_alphafold.py]"
  echo "  --sequence: Amino acid sequence to predict."
  echo "  --output_dir: Directory for output files (job name with timestamp)."
  echo "  --model_preset: Model preset (default: monomer)."
  echo "  --db_preset: Database preset (default: reduced_dbs)."
  echo "  --use_gpu_relax: Whether to use GPU for relaxation (default: false)."
  echo "  Extra arguments will be passed directly to run_alphafold.py."
  exit 1
}


while [[ $# -gt 0 ]]; do
  case "$1" in
    --sequence)
      SEQUENCE="$2"
      shift 2
      ;;
    --output_dir)
      JOB_NAME_WITH_TIMESTAMP="$2"
      shift 2
      ;;
    --model_preset)
      MODEL_PRESET="$2"
      shift 2
      ;;
    --db_preset)
      DB_PRESET="$2"
      shift 2
      ;;
    --use_gpu_relax)
      GPU_RELAX_PRESET="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# --- Input Validation ---
if [[ -z "$SEQUENCE" ]]; then
  echo "Error: Missing required --sequence argument for wrapper"
  usage
  exit 1
fi

if [[ -z "$JOB_NAME_WITH_TIMESTAMP" ]]; then
  echo "Error: Missing required --output_dir (job name with timestamp) argument for wrapper"
  usage
  exit 1
fi

# --- Define the base output directory prefix ---
# this can be extracted to other variables if needed
BASE_OUTPUT_PREFIX="/gcs/alphafold-output-vertex-europe-west4/predict"

# --- Combining prefix, job name part, and timestamp ---
FINAL_OUTPUT_DIR="${BASE_OUTPUT_PREFIX}/${JOB_NAME_WITH_TIMESTAMP}"

# --- Define ALPHAFOLD_DB_ROOT ---
ALPHAFOLD_DB_ROOT="/gcs/alphafold-dbs-vertex-dectris-europe-west4"

# --- Ensure the target directory exists (using mkdir -p for safety) ---
# Note: This relies on the /gcs mount being writable by the job's service account
#       and the 'predict' folder already existing if needed by permissions.
#       It will attempt to create the JOB_NAME_PART_TIMESTAMP subdirectory.
mkdir -p "$FINAL_OUTPUT_DIR"
echo "Ensured output directory exists (or created): $FINAL_OUTPUT_DIR"

# --- Create FASTA file ---
FASTA_PATH="/tmp/input.fasta"
printf ">alphafold_job\n%s\n" "$SEQUENCE" > "$FASTA_PATH"


echo "--- Starting AlphaFold ---"
echo "Sequence Length: ${#SEQUENCE}"
echo "Job Name Part: $JOB_NAME_WITH_TIMESTAMP"
echo "Model Preset: $MODEL_PRESET"
echo "DB Preset: $DB_PRESET"
echo "Use GPU Relax Preset: $GPU_RELAX_PRESET"
echo "Final Output Dir: $FINAL_OUTPUT_DIR"
echo "Wrapper Extra Args: ${EXTRA_ARGS[@]}"


# --- Build the arguments list for run_alphafold.py using an array ---
COMMAND_ARGS=(
  "--fasta_paths=$FASTA_PATH"
  "--output_dir=$FINAL_OUTPUT_DIR"
  "--data_dir=$ALPHAFOLD_DB_ROOT"
  "--uniref90_database_path=$ALPHAFOLD_DB_ROOT/uniref90/uniref90.fasta"
  "--mgnify_database_path=$ALPHAFOLD_DB_ROOT/mgnify/mgy_clusters_2022_05.fa"
  "--template_mmcif_dir=$ALPHAFOLD_DB_ROOT/pdb_mmcif/mmcif_files"
  "--obsolete_pdbs_path=$ALPHAFOLD_DB_ROOT/pdb_mmcif/obsolete.dat"
  "--small_bfd_database_path=$ALPHAFOLD_DB_ROOT/small_bfd/bfd-first_non_consensus_sequences.fasta"
  "--bfd_database_path=$ALPHAFOLD_DB_ROOT/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"
  "--uniref30_database_path=$ALPHAFOLD_DB_ROOT/uniref30/UniRef30_2021_03"
  "--pdb70_database_path=$ALPHAFOLD_DB_ROOT/pdb70/pdb70"
  "--max_template_date=1900-01-01"
  "--model_preset=$MODEL_PRESET"
  "--db_preset=$DB_PRESET"
  "--use_gpu_relax=$GPU_RELAX_PRESET"
  "${EXTRA_ARGS[@]}"
)

echo "Running command:"
printf "%q " python3 /app/alphafold/run_alphafold.py "${COMMAND_ARGS[@]}"
echo # Print a newline

# --- Execute the command ---
python3 /app/alphafold/run_alphafold.py "${COMMAND_ARGS[@]}"

echo "--- AlphaFold Finished ---"