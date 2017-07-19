#!/bin/bash

year=2011
s=10004953_20111116
mpi=4
threads=4

SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs

IMPATH=/ifs/scratch/pimri/posnerlab/1anal/IDP/${year}/${s}
EXPERTOPT=$SUBJECTS_DIR/expert.opt
FLAIR=`ls $IMPATH/flair*nii`
T1=`ls $IMPATH/t1*nii`
SUBJECT=${s}_1mm_flair
CMD1=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/cmd1.${s}
CMD2=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/cmd2.${s}

recon1=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/recon1.${s}
recon2=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/recon2.${s}

### 1 INITIAL RECONA-LL
cat<<EOC >$recon1
#!/bin/bash
FREESURFER_HOME=/ifs/home/msph/epi/jep2111/app/freesurfer/
source $FREESURFER_HOME/SetUpFreeSurfer.sh
SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs
echo NOW PERFORMING RECON-ALL
#recon-all -all -s ${SUBJECT}.test_mpi128 -hires -i $T1 -expert $EXPERTOPT -FLAIR $FLAIR -FLAIRpial -hippocampal-subfields-T1 -openmp 64 
recon-all -all -s ${SUBJECT}_test_mpi${mpi} -i $T1 -FLAIR $FLAIR -FLAIRpial -openmp ${mpi}
EOC

chmod +x $recon1


cat<<-EOM >$CMD1
#!/bin/bash
#$ -V
#$ -cwd -S /bin/bash -N recon1
#$ -l mem=3G,time=48::
#$ -pe orte \${mpi}
#$ -l infiniband=TRUE
source /ifs/home/msph/epi/jep2111/.bashrc
. /nfs/apps/openmpi/current/setenv.sh
mpirun $recon
EOM

#id=`qsub $CMD1`
echo $CMD1

### 2 HIPPOCAMPAL SEGMENTATION
cat<<EOC >$recon2
#!/bin/bash
FREESURFER_HOME=/ifs/home/msph/epi/jep2111/app/freesurfer/
source $FREESURFER_HOME/SetUpFreeSurfer.sh
SUBJECTS_DIR=/ifs/scratch/pimri/posnerlab/1anal/IDP/fs
echo NOW PERFORMING RECON-ALL
#recon-all -all -s ${SUBJECT}.test_mpi128 -hires -i $T1 -expert $EXPERTOPT -FLAIR $FLAIR -FLAIRpial -hippocampal-subfields-T1 -openmp 64 
recon-all -s ${SUBJECT}_test_mpi4 -hippocampal-subfields-T1T2 $FLAIR flair -${threads} 4
EOC

#chmod +x $recon2


cat<<-EOM >$CMD2
#!/bin/bash
#$ -V
#$ -cwd -S /bin/bash -N recon2
#$ -l mem=3G,time=24::
#$ -pe smp ${threads}
#$ -l infiniband=TRUE
source /ifs/home/msph/epi/jep2111/.bashrc
. /nfs/apps/openmpi/current/setenv.sh
mpirun $recon
EOM

#qsub $CMD
echo $CMD2