# This script runs a GLM analysis using FSL on a cifti dense timeseries file in FSLR 91k space (output of fmriprep). It requires the original surfaces of the subject from freesurfer, some files from the HCP pipelines (fs_LR-deformed_to-fsaverage.L/R.sphere.32k_fs_LR.surf.gii). Freesurfer, connectome workbench command and FSL must be on the path. It also requires an FSF template and the onset times to be in the CIFTI directory and organized (see below). Smoothing is hardcoded as 4 mm FWHM (HCP standard), high-pass filter is hard coded as 200s (HCPstandard). The CIFTI is resampled in FSLR 32k space (HCPstandard). Output is saved in BIDS fomat.

# Example usage: 
# runfeatoncifti.sh 'sub-CONN008' 'Emotion' 'sub-CONN008_ses-00_task-emotion_acq-mb_dir-pe0_space-fsLR_den-91k_bold.dtseries.nii' 'Emotion.fsf' 'sub-CONN008_ses-00_task-emotion_acq-mb_dir-pe0_desc-MELODIC_mixing_noise.tsv' 'lh.white' 'lh.pial' 'lh.sphere.reg' 'fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii' 'rh.white' 'rh.pial' 'rh.sphere.reg' 'fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii' '91282_Greyordinates.dscalar.nii' 'anat'

### Loading necessary files

subname=${1}
taskname=${2}
funccifti=${3}
ciftipath=$(dirname $funccifti)
templatefsf=${4} # a complete FSF template with the task design. The event timinigs are assumed to be in: ${ciftipath}/EVs/${taskname} 
confounds=${5} # to be added as regressors in the GLM

l_fs_white=${6} # from the subject FS directory
l_fs_pial=${7} # from the subject FS directory
l_current_freesurfer_sphere=${8} # from the subject FS directory
l_new_sphere=${9} # from the HCP pipelines

r_fs_white=${10} # from the subject FS directory
r_fs_pial=${11} # from the subject FS directory
r_current_freesurfer_sphere=${12} # from the subject FS directory 
r_new_sphere=${13} # from the HCP pipelines

temp32k=${14} # a file in the 32k greyordinate space as template
anatfolder=${15} # where the resampled surfaces should be saved

# Go to CIFTI directory
cd $ciftipath

# Get TR info from CIFTI file
TR_vol=`wb_command -file-information ${funccifti} -no-map-info -only-step-interval`

# Extract number of time points in CIFTI time series file
npts=`wb_command -file-information ${funccifti} -no-map-info -only-number-of-maps`

### Create midthickness file in FSLR 32k space 

# Left
l_midthickness_current_out=${subname}_hemi-L_midthickness.surf.gii
l_midthickness_new_out=${subname}_hemi-L_midthickness_32k_fs.surf.gii
l_current_gifti_sphere_out=lh.sphere.reg.surf.gii

wb_shortcuts -freesurfer-resample-prep $l_fs_white $l_fs_pial $l_current_freesurfer_sphere $l_new_sphere $l_midthickness_current_out $l_midthickness_new_out $l_current_gifti_sphere_out

# Right
r_midthickness_current_out=${subname}_hemi-R_midthickness.surf.gii
r_midthickness_new_out=${subname}_hemi-R_midthickness_32k_fs.surf.gii
r_current_gifti_sphere_out=rh.sphere.reg.surf.gii

wb_shortcuts -freesurfer-resample-prep $r_fs_white $r_fs_pial $r_current_freesurfer_sphere $r_new_sphere $r_midthickness_current_out $r_midthickness_new_out $r_current_gifti_sphere_out


### Resample the CIFTI

wb_command -cifti-resample ${funccifti} COLUMN ${temp32k} COLUMN ADAP_BARY_AREA CUBIC ${subname}_${taskname}_32k_bold.dtseries.nii 


### Apply constrained spatial smoothing to CIFTI dense analysis

# To obtain sigma, divide FWHM by 2.3548
# In this case, FWHM is 4 (HCP default for total smoothing)

echo 'Smoothing 4mm FWHM'

wb_command -cifti-smoothing ${subname}_${taskname}_32k_bold.dtseries.nii 1.69865806013 1.69865806013 COLUMN ${subname}_${taskname}_32k_bold_s4.dtseries.nii  -left-surface ${subname}_hemi-L_midthickness_32k_fs.surf.gii -right-surface ${subname}_hemi-R_midthickness_32k_fs.surf.gii


### Apply temporal filtering

echo 'Filtering 200s high-pass'

# Convert CIFTI to "fake" NIFTI
wb_command -cifti-convert -to-nifti ${subname}_${taskname}_32k_bold_s4.dtseries.nii ${subname}_${taskname}_32k_bold_s4_fakenifti.nii.gz

# Extract mean
fslmaths ${subname}_${taskname}_32k_bold_s4_fakenifti.nii.gz -Tmean ${subname}_${taskname}_32k_bold_s4_fakenifti_mean.nii.gz

# Compute smoothing kernel sigma, in this case highpass cut-off is 200s (HCP default)
hp_sigma=`echo "0.5 * 200 / $TR_vol" | bc -l`; 

# Use fslmaths to apply high pass filter and then add mean back to image
fslmaths ${subname}_${taskname}_32k_bold_s4_fakenifti.nii.gz -bptf ${hp_sigma} -1 -add ${subname}_${taskname}_32k_bold_s4_fakenifti_mean.nii.gz ${subname}_${taskname}_32k_bold_s4_hp200_fakenifti.nii.gz

# Convert "fake" NIFTI back to CIFTI
wb_command -cifti-convert -from-nifti ${subname}_${taskname}_32k_bold_s4_hp200_fakenifti.nii.gz ${subname}_${taskname}_32k_bold_s4.dtseries.nii ${subname}_${taskname}_32k_bold_s4_hp200.dtseries.nii

# Cleanup the "fake" NIFTI files
rm *_fakenifti*


### Run film_gls (GLM analysis)

echo 'Running GLM'

# Create a feat directory
FEATDir="${taskname}_feat"
mkdir $FEATDir

# Copy template fsf file into $FEATDir
cp $templatefsf ${FEATDir}/design.fsf

# Edit fsf file to record the parameters used in this analysis
sed -i -e "s|set fmri(paradigm_hp) \"200\"|set fmri(paradigm_hp) \"${TemporalFilter}\"|g" ${FEATDir}/design.fsf
sed -i -e "s|set fmri(smooth) \"2\"|set fmri(smooth) \"${FinalSmoothingFWHM}\"|g" ${FEATDir}/design.fsf

# Copy confounds
cp $confounds ${FEATDir}/confounds.txt

# find current value for npts in template.fsf
fsfnpts=`grep "set fmri(npts)" ${FEATDir}/design.fsf | cut -d " " -f 3 | sed 's|"||g'`;

# Ensure number of time points in fsf matches time series image
if [ "$fsfnpts" -eq "$npts" ] ; then
	echo "Scan length matches number of timepoints in template.fsf: ${fsfnpts}"
else
	echo "Change design.fsf: Warning! Scan length does not match template.fsf!"
	echo "Warning! Changing Number of Timepoints in fsf (""${fsfnpts}"") to match time series image (""${npts}"")"
	sed -i -e  "s|set fmri(npts) \"\?${fsfnpts}\"\?|set fmri(npts) ${npts}|g" ${FEATDir}/design.fsf
fi

cd $FEATDir 
feat_model design confounds.txt
cd ..

# Set variables for additional design files
designmatrix=${FEATDir}/design.mat
designcontrasts=${FEATDir}/design.con

# Split CIFTI into surface and volume
wb_command -cifti-separate ${subname}_${taskname}_32k_bold_s4_hp200.dtseries.nii COLUMN -volume-all ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200.nii.gz -label ${FEATDir}/volumeroi.nii -metric CORTEX_LEFT ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200_L.func.gii -metric CORTEX_RIGHT ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200_R.func.gii

#Run film_gls on subcortical volume data
film_gls --rn=${FEATDir}/SubcorticalVolumeStats --sa --ms=5 --in=${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200.nii.gz --pd=${designmatrix} --con=${designcontrasts} --thr=1 --mode=volumetric

# Clean up
rm ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200.nii.gz

#Run film_gls on cortical surface data 
for hemisphere in L R ; do

#Prepare for film_gls  
wb_command -metric-dilate ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200_${hemisphere}.func.gii ${subname}_hemi-${hemisphere}_midthickness_32k_fs.surf.gii 50 ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200_${hemisphere}_dil.func.gii -nearest

#Run film_gls on surface data
film_gls --rn=${FEATDir}/${hemisphere}_SurfaceStats --sa --ms=15 --epith=5 --in2=${subname}_hemi-${hemisphere}_midthickness_32k_fs.surf.gii --in=${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200_${hemisphere}_dil.func.gii --pd=${designmatrix} --con=${designcontrasts} --mode=surface

# Clean up
rm ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200_${hemisphere}.func.gii ${FEATDir}/${subname}_${taskname}_32k_bold_s4_hp200_${hemisphere}_dil.func.gii 
done

# Merge cortical surface and subcortical volume into grayordinates
mkdir ${FEATDir}/GrayordinatesStats
cat ${FEATDir}/SubcorticalVolumeStats/dof > ${FEATDir}/GrayordinatesStats/dof
cat ${FEATDir}/SubcorticalVolumeStats/logfile > ${FEATDir}/GrayordinatesStats/logfile
cat ${FEATDir}/L_SurfaceStats/logfile >> ${FEATDir}/GrayordinatesStats/logfile
cat ${FEATDir}/R_SurfaceStats/logfile >> ${FEATDir}/GrayordinatesStats/logfile

for Subcortical in ${FEATDir}/SubcorticalVolumeStats/*nii.gz ; do
File=$( basename $Subcortical .nii.gz );
wb_command -cifti-create-dense-timeseries ${FEATDir}/GrayordinatesStats/${File}.dtseries.nii -volume $Subcortical ${FEATDir}/volumeroi.nii -left-metric ${FEATDir}/L_SurfaceStats/${File}.func.gii  -right-metric ${FEATDir}/R_SurfaceStats/${File}.func.gii
done


### Clean up and BIDSify

# Remove the sphere registrations
rm lh.sphere.reg.surf.gii rh.sphere.reg.surf.gii

# Remove the volume ROIs
rm ${FEATDir}/volumeroi.nii

# Remove the midthickness file in 91k (it should already exist as output of fmriprep)
rm ${subname}_hemi-L_midthickness.surf.gii ${subname}_hemi-R_midthickness.surf.gii

# Move the midthickness files in 32k to the anatomical directory
mv ${subname}_hemi-L_midthickness_32k_fs.surf.gii ${anatfolder}/${subname}_hemi-L_space-fsLR_den-32k_midthickness.surf.gii
mv ${subname}_hemi-R_midthickness_32k_fs.surf.gii ${anatfolder}/${subname}_hemi-R_space-fsLR_den-32k_midthickness.surf.gii

# Rename the dense timeseries file to BIDS standard
newciftiname=$(echo "${funccifti/91k/32k}")
newciftiname_s4=$(echo "${newciftiname/_bold/_desc-s2_bold}")
newciftiname_s4_hp200=$(echo "${newciftiname/_bold/_desc-s2hp200_bold}")

mv ${subname}_${taskname}_32k_bold.dtseries.nii $newciftiname
mv ${subname}_${taskname}_32k_bold_s4.dtseries.nii ${newciftiname_s4}
mv ${subname}_${taskname}_32k_bold_s4_hp200.dtseries.nii ${newciftiname_s4_hp200}
