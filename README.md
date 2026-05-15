<table>
<tr>
<td><img src="images/CMS_logo.png" alt="CMS logo" width="250"/></td>
<td>This repository provides two bash scripts for simplifying HTCondor job submission within the CMS collaboration. Any and all contents of this repository are free to use for any purpose.</td>
</tr>
  
</table>
<p align="center">
  <img src="images/HTCondor_logo.png" alt="HTCondor logo" width="700"/>
</p>

HTCondor (formerly Condor) is a distributed high throughput computing workload manager developed at the University of Wisconsin-Madison. Users submit jobs to an HTCondor queue, and HTCondor handles scheduling and execution across available worker nodes. HTCondor is open source and licensed under Apache 2.0, with extensive documentation available in the resources section.
<br><br>
<h1>HTCondor Job Submission</h1>

These two bash scripts act as a simple wrapper for submitting HTCondor jobs on any system with CMSSW and HTCondor access, such as LXPLUS. By specifying a CMSSW release directory, users can generate and submit jobs with a single terminal command.

<br>

| Script | Description |
| - | - |
| `make_condor.sh` | Entry point called by the user. Generates a working directory, an HTCondor submission file, and submits the jobs (skippable with `-n`). |
| `runtime_wrapper.sh` | Sets up CMSSW runtime environment and executes the user-provided executable based on its type (`.C`, `.cpp`, `.cc`, `.cxx`, `.py`, or `.sh`). |

<h2>Usage</h2>

Specify which CMSSW release to use by setting `CMSSW_SRC` on line 16 of `runtime_wrapper.sh` to the desired CMSSW working area before submitting jobs. The CMSSW release will be pinned on any node executing a job submitted through this wrapper, fixing the versions of ROOT, python, and all other dependencies for reproducible job execution.

Execute the following terminal command to generate (and submit) HTCondor jobs. A timestamped working directory is created in the location `make_condor.sh` is executed. 

```
./make_condor.sh JOBNAME EXECUTABLE FILELIST OUTPUT_DIR [--no-submit|-n]
```

| Argument | Description |
| - | - |
| `JOBNAME` | Label for the set of jobs, used in directory and file naming. |
| `EXECUTABLE` | Path to macro executing on each worker node for each input file. |
| `FILELIST` | Path to plain text file containing one input file on every line. One job is submitted for each input file. |
| `OUTPUT_DIR` | Directory where output ROOT files are stored. A timestamped output subdirectory is created here. |
| `-n` | Optional flag to generate the submission file without submitting. |

<h2>Working Example</h2>

> Don't forget to run `chmod +x make_condor.sh` before executing `make_condor.sh` for the first time

In this example a ROOT based macro is generating dijet asymmetries from ten HiForest files made from a hard QCD MC sample of the 2024 pp reference run (5.36 TeV) generated with Pythia. This pp reference run was collected for comparisons with the PbPb collisions that followed shortly after.

```
./make_condor.sh DijetAsymmetry_2024ppRef /afs/cern.ch/user/n/nbarnett/public/executable_files/asymmetry_generator_condor_2024ppRef_MC_5_12_2026.C /afs/cern.ch/user/n/nbarnett/public/txt_files/filelists/filelist_HiForest_2024ppref_MC_withPU_10files.txt .
```

The filelist used in this example is shown below. This format is needed to properly use this Condor submission wrapper.

```
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1006.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1007.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1008.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1009.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_100.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1010.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1011.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1012.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1013.root
/eos/cms/store/group/phys_heavyions/nbarnett/Forests/MC/forests_2024ppRef_MC_withPU/HiForestMiniAOD_1014.root
```

<h3>Executable Interface</h3>

This wrapper, as written, passes exactly two positional arguments — an input file and an output file — to the user-provided executable. This convention is enforced within `runtime_wrapper.sh`, regardless of the executable file type, as shown below. Compatibility of the executable with this interface should be verified before submitting jobs.

| Extension | Interpreter | Command |
| - | - | - |
| `.C`, `.cpp`, `.cc`, or `.cxx` | `root` | `root -l -b -q 'executable.C'("INPUT_FILE", "OUTPUT_FILE")'` |
| `.py` | `cmsRun` | `cmsRun executable.py INPUT_FILE OUTPUT_FILE` |
| `.sh` | `./` | `./executable.sh INPUT_FILE OUTPUT_FILE` |

<h3>Working Directory</h3>

A working directory is where a Condor submission file is made and submitted. The filelist, executable, jobname, submission file, submit generator, and runtime wrapper are all put into this working directory. Every working directory is timestamped and contains everything used in the Condor submission. The name and output structure of any working directory is shown below.

```
condor_<JOBNAME>_<YEAR-MONTH-DAY_HOUR-MINUTE-SECOND>/
├── submit_<JOBNAME>.condor
├── <EXECUTABLE>
├── <FILELIST>
└── logs/
    ├── out/   # stdout (.out) for each job
    ├── err/   # stderr (.err) for each job
    └── log/   # HTCondor log (.log) for each job
```

<details>

<summary><h3>Condor Commands</h3></summary>

These commands can be run in a terminal logged into LXPLUS to interact with HTCondor. These are the most common Condor commands, but there are many more.

| Command | Description |
| - | - |
| `condor_q` | Show job queue on the local schedd. |
| `condor_q -better-analyze <JOB_ID>` | Diagnose, potentially idle, job with specified ID. |
| `condor_q -hold` | Show only held jobs and their hold reasons. |
| `condor_q -idle` | Show only idle jobs. |
| `condor_rm <JOB_ID>` | Remove job with specified ID from the queue. |
| `condor_rm -all` | Remove all submitted jobs from the queue. |

</details>

<h3>Notes</h3>

The following parameters are set within `make_condor.sh` and can be adjusted.

**`+JobFlavour`** sets the maximum wall clock time allowed per job. The available flavours and their time limits are shown below. The default in this wrapper is `longlunch` (2 hours).
  
| JobFlavour | Time Limit |
| - | - |
| `espresso` | 20 minutes |
| `microcentury` | 1 hour |
| `longlunch` | 2 hours |
| `workday` | 8 hours |
| `tomorrow` | 1 day |
| `testmatch` | 3 days |
| `nextweek` | 1 week |

**`request_cpus`** sets the number of CPU cores requested for each job. The default in this wrapper is `4`.

**`request_memory`** sets the amount of RAM requested for each job. This wrapper does not request a specific amount of memory for each job by default. To specify `request_memory` for each job add the following to `make_condor.sh` on line 62:
```
request_memory = <MB>
```

<h3>Additional Resources</h3>

* [CERN Batch Service Documentation](https://batchdocs.web.cern.ch/) — official guide for HTCondor on lxplus
* [CERN HTCondor Submission File Guide](https://batchdocs.web.cern.ch/local/submit.html) — details on submission file parameters like `JobFlavour`, `request_cpus`, etc.
* [Condor Commands Reference (CERN TWiki)](https://twiki.cern.ch/twiki/bin/view/CENF/NeutrinoClusterCondorDoc) - reference for commands `condor_q`, `condor_status`, `condor_rm`, and more *(requires CERN login)*
* [HTCondor Documentation](https://htcondor.org/documentation/htcondor.html) - official HTCondor webpage, manual, and user guide
* [HTCondor Source Code Repository](https://github.com/htcondor/htcondor) - open-source codebase for HTCondor, licensed under Apache 2.0

