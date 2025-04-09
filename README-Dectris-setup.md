# AlphaFold Wrapper Script

This script serves as a wrapper around the AlphaFold protein structure prediction pipeline to simplify its execution and standardize its usage within a specific environment (e.g., a cloud computing platform like Vertex AI). It handles argument parsing, input validation, output directory management, and construction of the command-line arguments for the core `run_alphafold.py` script.

## Why a Wrapper is Needed

Directly executing `run_alphafold.py` can be cumbersome for several reasons:

1.  **Complexity:** The `run_alphafold.py` script has many command-line arguments, making it prone to errors if not configured correctly.
2.  **Environment-Specific Configuration:** The paths to databases, output directories, and other environment-specific settings may vary. A wrapper provides a centralized location to manage these settings.
3.  **Simplified Usage:** The wrapper can present a simplified interface to the user, requiring only essential input and hiding the complexity of the underlying AlphaFold pipeline.
4.  **Standardization:** A wrapper ensures that AlphaFold is run consistently across different jobs and users, promoting reproducibility.
5.  **Error Handling:** The wrapper script enhances error handling. It checks for required arguments and provides helpful error messages if something is missing or invalid.

## Functionality

This wrapper script performs the following actions:

1.  **Argument Parsing:** Parses command-line arguments provided by the user.
2.  **Input Validation:** Validates that required arguments (e.g., sequence, output directory) are provided.
3.  **Output Directory Management:** Constructs the full output directory path based on a base prefix and the provided job name. It then ensures that the output directory exists.
4.  **FASTA File Creation:** Creates a temporary FASTA file containing the input sequence, which is required by AlphaFold.
5.  **Command Construction:** Constructs the complete command-line arguments for `run_alphafold.py`, including database paths, model presets, and other relevant settings.
6.  **Execution:** Executes the `run_alphafold.py` script with the constructed arguments.
7.  **Logging:** Prints useful information about the run, such as the sequence length, output directory, and command being executed.

## Upload database to bucket

authenticate with gcloud auth login
To upload a protein database to the bucket use:
gsutil -m cp -r /{insterPath}/pdb70 gs://alphafold-dbs-vertex-dectris-europe-west4/

## Switch Dockerfile

go to /alphafold
docker build -f docker/Dockerfile -t alphafold-wrapper .

docker tag alphafold-wrapper europe-west4-docker.pkg.dev/vertex-ai-alphafold-454207/alphafold-repo/alphafold:latest

docker push europe-west4-docker.pkg.dev/vertex-ai-alphafold-454207/alphafold-repo/alphafold:latest

## Argument Details

Here's a breakdown of each argument used within the script:

SEQUENCE: Stores the amino acid sequence provided via the --sequence argument. This is the primary input for AlphaFold.

JOB_NAME_WITH_TIMESTAMP: Stores the job name (and usually a timestamp) provided via the --output_dir argument. This is used to create a unique output directory for each run.

MODEL_PRESET: Stores the selected model preset (e.g., monomer, multimer). This determines which AlphaFold model will be used for prediction. Defaults to monomer.

DB_PRESET: Stores the selected database configuration (e.g., reduced_dbs, full_dbs). This determines which databases AlphaFold will use for sequence alignments and template searches. Defaults to reduced_dbs.

GPU_RELAX_PRESET: Stores whether or not the GPU will be used for structure relaxation (true or false). Defaults to false.

EXTRA_ARGS: An array that stores any additional command-line arguments provided by the user that are not explicitly handled by the wrapper. These arguments are passed directly to run_alphafold.py.

BASE_OUTPUT_PREFIX: A constant that defines the base directory where all AlphaFold output will be stored: /gcs/alphafold-output-vertex-europe-west4/predict. This should be configured according to your environment.

FINAL_OUTPUT_DIR: The full path to the output directory, constructed by combining BASE_OUTPUT_PREFIX and JOB_NAME_WITH_TIMESTAMP. This is where AlphaFold will write its results.

ALPHAFOLD_DB_ROOT: A constant that defines the root directory where the AlphaFold databases are located: /gcs/alphafold-dbs-vertex-dectris-europe-west4. This should be configured according to your environment.

FASTA_PATH: A constant that defines the path to the temporary FASTA file: /tmp/input.fasta.

COMMAND_ARGS: An array that holds all the command-line arguments that will be passed to run_alphafold.py. The wrapper constructs this array based on the user-provided arguments and the environment configuration.

## Environment Variables

The script relies on correctly setting the BASE_OUTPUT_PREFIX and ALPHAFOLD_DB_ROOT variables to reflect your specific environment. These variables are hardcoded in the script, but can be modified accordingly.

Dependencies
AlphaFold: This script assumes that AlphaFold is installed and that the run_alphafold.py script is located at /app/alphafold/run_alphafold.py.

Python 3: AlphaFold requires Python 3.

GCS Mount: If you are using Google Cloud Storage (GCS), you must have the GCS bucket mounted at the specified BASE_OUTPUT_PREFIX and ALPHAFOLD_DB_ROOT locations.

GNU Coreutils: For basic command line functionality (mkdir, echo, printf etc.)

Notes
This wrapper script is designed to be run within a specific environment (e.g., a cloud computing platform). You may need to modify it to adapt it to your own environment.

Make sure that the service account running the script has the necessary permissions to read the AlphaFold databases and write to the output directory.

Consult the AlphaFold documentation for detailed information about the AlphaFold pipeline and its command-line arguments.

## Usage

```bash
./alphafold_wrapper.sh --sequence <sequence> --output_dir <job_name_with_timestamp> [--model_preset <preset>] [--db_preset <preset>] [--use_gpu_relax <true|false>] [extra arguments for run_alphafold.py]
./alphafold_wrapper.sh: The name of the wrapper script. Make sure the script is executable (chmod +x alphafold_wrapper.sh).

--sequence <sequence>: The amino acid sequence to be predicted. This is a required argument. Example: --sequence "MGWSCFGKMADSRK..."

--output_dir <job_name_with_timestamp>: The name of the directory where the AlphaFold results will be stored. This will be combined with the base output directory (/gcs/alphafold-output-vertex-europe-west4/predict) to form the final output path. This is a required argument. Example: --output_dir "my_protein_job_20241027"

--model_preset <preset>: Specifies the AlphaFold model preset to use. Available options are:

monomer: For predicting the structure of a single protein chain (default).

monomer_casp14: For models trained on CASP14 data.

monomer_ptm: For models with pTM head

multimer: For predicting the structure of protein complexes.
Example: --model_preset "monomer_ptm"

--db_preset <preset>: Specifies the database configuration to use. Available options are:

reduced_dbs: Uses a smaller set of databases for faster execution, but potentially lower accuracy (default).

full_dbs: Uses the full set of databases for maximum accuracy, but requires more resources and time.
Example: --db_preset "full_dbs"

--use_gpu_relax <true|false>: Specifies whether to use the GPU for the final structure relaxation step.

true: Uses the GPU for relaxation (faster).

false: Uses the CPU for relaxation. (default)
Example: --use_gpu_relax "true"

```
