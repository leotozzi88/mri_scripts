#!/bin/bash
#
#SBATCH --job-name=hcpstrconnectome
#
#SBATCH --mail-user=ltozzi@stanford.edu
#SBATCH --mail-type=ALL
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=15
#SBATCH --mem-per-cpu=4G

ml biology freesurfer
ml biology fsl
cd /home/groups/leanew1/ltozzi/mrtrix3
./set_path

# Create Glasser parcellation

echo "Creating Glasser parcellation"
mkdir $2/$1/T1w/GenerateGlasserParc_temp
cd  $2/$1/T1w/GenerateGlasserParc_temp
SUBJECTS_DIR=$PWD
cp -r /home/groups/leanew1/ltozzi/fsaverage $PWD
cp -r $2/$1/T1w/$1 $PWD
cp /home/groups/leanew1/ltozzi/HCPMMP1_annotations/lh.HCPMMP1.annot $PWD 
cp /home/groups/leanew1/ltozzi/HCPMMP1_annotations/rh.HCPMMP1.annot $PWD
echo "$1">subslist
. /home/groups/leanew1/ltozzi/create_subj_volume_parcellation.sh -L subslist -a HCPMMP1 -d GlasserParc -f 1 -l 1
cp GlasserParc/$1/HCPMMP1.nii.gz $2/$1/T1w/Diffusion
cp $2/$1/T1w/T1w_acpc_brain_mask.nii.gz $2/$1/T1w/Diffusion
cp $2/$1/T1w/T1w_acpc_dc_restore_brain.nii.gz $2/$1/T1w/Diffusion
cd $2/$1/T1w/Diffusion

# Clean up
rm -r $2/$1/T1w/GenerateGlasserParc_temp

# Modify the integer values in the parcellated image
labelconvert HCPMMP1.nii.gz /home/groups/leanew1/ltozzi/mrtrix3/share/mrtrix3/labelconvert/hcpmmp1_original.txt /home/groups/leanew1/ltozzi/mrtrix3/share/mrtrix3/labelconvert/hcpmmp1_ordered.txt HCPMMP1_nodes.mif -force

# Generate a tissue-segmented image appropriate for Anatomically-Constrained Tractography

5ttgen freesurfer $2/$1/T1w/aparc+aseg.nii.gz 5TT.mif -force

# Collapse the multi-tissue image into a 3D greyscale image for visualisation
5tt2vis 5TT.mif vis.mif -force

#############
#Diffusion image processing
#############

# Cut the first two calibration volumes 
#fslroi data.nii.gz data_cut.nii.gz 2 -1
#cut -f3- -d ' ' bvals > bvals_cut
#cut -f7- -d ' ' bvecs > bvecs_cut

# Convert the diffusion images into a non-compressed format

#mrconvert data_cut.nii.gz DWI.mif -fslgrad bvecs_cut bvals_cut -datatype float32 -force
mrconvert data.nii.gz DWI.mif -fslgrad bvecs bvals -datatype float32 -force

# Generate a mean b=0 image

dwiextract DWI.mif - -bzero | mrmath - mean meanb0.mif -axis 3 -force

# Estimate the response function

dwi2response msmt_5tt DWI.mif 5TT.mif RF_WM.txt RF_GM.txt RF_CSF.txt -voxels RF_voxels.mif -force

# Perform Multi-Shell, Multi-Tissue Constrained Spherical Deconvolution

dwi2fod msmt_csd DWI.mif RF_WM.txt WM_FODs.mif RF_GM.txt GM.mif RF_CSF.txt CSF.mif -mask nodif_brain_mask_old.nii.gz -force
mrconvert WM_FODs.mif - -coord 3 0 | mrcat CSF.mif GM.mif - tissueRGB.mif -axis 3 -force

#############
#Connectome generation
#############

# Generate the initial tractogram

tckgen WM_FODs.mif 10M.tck -act 5TT.mif -backtrack -crop_at_gmwmi -seed_dynamic WM_FODs.mif -maxlength 250 -select 10M -cutoff 0.06 -force

# Apply the Spherical-deconvolution Informed Filtering of Tractograms 2 (SIFT2) algorithm

tcksift2 10M.tck WM_FODs.mif 10Mtck_sift2weights -act 5TT.mif -force

# Map streamlines to the parcellated image to produce a connectome

tck2connectome 10M.tck HCPMMP1_nodes.mif HCPMMP1_connectome.csv  -tck_weights_in 10Mtck_sift2weights -force
