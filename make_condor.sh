#!/bin/bash
set -euo pipefail

if [[ $# -lt 4 || $# -gt 5 ]]; then
  echo "Usage: $0 JOBNAME EXECUTABLE FILELIST OUTPUT_DIR [--no-submit|-n]" >&2
  exit 1
fi

JOBNAME="$1"
EXECUTABLE="$(realpath "$2")"
FILELIST="$(realpath "$3")"
OUTPUT_DIR="$(realpath "$4")"

NO_SUBMIT=false
if [[ $# -eq 5 && ( "$5" == "--no-submit" || "$5" == "-n" ) ]]; then
  NO_SUBMIT=true
elif [[ $# -eq 5 ]]; then
  echo "Unknown flag: $5" >&2
  exit 1
fi

TODAY=$(date +"%Y-%m-%d_%H-%M-%S")
WORKDIR="condor_${JOBNAME}_${TODAY}"
WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x runtime_wrapper.sh

echo "Making working directory: ${WORKDIR}"

mkdir -p "${WORKDIR}"
(
    cd "${WORKDIR}"

    EXE_NAME="$(basename "${EXECUTABLE}")"
    FILELIST_NAME="$(basename "${FILELIST}")"

    echo "Copying files to working directory..."

    cp "${EXECUTABLE}" .
    cp "${FILELIST}" .

    if [[ "${EXE_NAME}" == *.sh ]]; then
        chmod +x "${EXE_NAME}"
    fi

    mkdir -p logs/out logs/err logs/log

    mkdir -p "${OUTPUT_DIR}/${WORKDIR}"

    SUBMISSION_FILE="submit_${JOBNAME}.condor"
    echo "Making Condor submission file: ${SUBMISSION_FILE}"

    cat > "${SUBMISSION_FILE}" <<EOF
Universe                = vanilla
Executable              = ${WRAPPER_DIR}/runtime_wrapper.sh

+JobFlavour             = "longlunch"

should_transfer_files   = YES
when_to_transfer_output = ON_EXIT

request_cpus            = 4

Transfer_Input_Files    = ${WRAPPER_DIR}/runtime_wrapper.sh,$(pwd)/${EXE_NAME}
EOF

    COUNT=0

    while IFS= read -r INPUT_FILE; do

        [[ -z "${INPUT_FILE}" ]] && continue

        OUTPUT_FILE="${OUTPUT_DIR}/${WORKDIR}/output_${JOBNAME}_${COUNT}.root"

        cat >> "${SUBMISSION_FILE}" <<EOF
Arguments = ${EXE_NAME} ${INPUT_FILE} ${OUTPUT_FILE}

Output    = $(pwd)/logs/out/job_${COUNT}.out
Error     = $(pwd)/logs/err/job_${COUNT}.err
Log       = $(pwd)/logs/log/job_${COUNT}.log

Queue

EOF
        COUNT=$((COUNT + 1))

    done < "${FILELIST_NAME}"

    if [[ "$NO_SUBMIT" == true ]]; then
        echo "--no-submit flag enabled — skipping condor_submit."
        echo "${COUNT} jobs in submission file: $(pwd)/${SUBMISSION_FILE}"
    else
        echo "Submitting ${COUNT} jobs..."
        condor_submit "${SUBMISSION_FILE}"
        echo "Done."
    fi

)
