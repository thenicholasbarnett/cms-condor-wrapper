#!/bin/bash -l
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 EXECUTABLE INPUT OUTPUT" >&2
  exit 1
fi

START_DIR="$(pwd)"
EXECUTABLE="$(realpath "$1")"
INPUT="$(realpath "$2")"
OUTPUT="$3"

# Set this to your CMSSW src directory on AFS or EOS, e.g.:
# /afs/cern.ch/user/x/username/public/condor/workArea/CMSSW_X_Y_Z/src
CMSSW_SRC=""

if [[ -z "${CMSSW_SRC}" ]]; then
  echo "ERROR: CMSSW_SRC is not set in runtime_wrapper.sh" >&2
  exit 1
fi

echo "Running in CMSSW environment: $(basename "$(dirname "${CMSSW_SRC}")")"
source /cvmfs/cms.cern.ch/cmsset_default.sh
cd "${CMSSW_SRC}"
eval "$(scramv1 runtime -sh)"
cmsenv
cd "${START_DIR}"

case "${EXECUTABLE}" in

    *.py)
        cmsRun "${EXECUTABLE}" "${INPUT}" "${OUTPUT}"
        ;;

    *.C | *.cc | *.cpp | *.cxx)
        root -l -b -q "${EXECUTABLE}(\"${INPUT}\", \"${OUTPUT}\")"
        ;;

    *.sh)
        chmod +x "${EXECUTABLE}"
        "${EXECUTABLE}" "${INPUT}" "${OUTPUT}"
        ;;

    *)
        echo "ERROR: Unsupported executable file extension ${EXECUTABLE##*.}" >&2
        exit 1
        ;;

esac