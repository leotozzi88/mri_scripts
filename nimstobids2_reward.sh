# This script BIDSifies HCP subjects from the "raw" folder. It assumes a consistent naming of the folders containing the images.
# This specific version is a version designed for Linux to be used on the "Reward" server. 
# If any of the expected files are missing, a logfile is produced.
# The first argument is the path to the subject directory.
# The second argument is the path to the folder of the json templates.

subfolder=${1}
subname=${1##*/}
jsonsfolder=${2}
origdir=$PWD

echo "BIDSifying subject $subname"

cd "${subfolder}"

mkdir $origdir/sub-${subname}
mkdir $origdir/sub-${subname}/ses-1
mkdir $origdir/sub-${subname}/ses-2

# Setting the bvals and bvecs for diffusion to fix the inconsistent bvals/bvecs from CNI

bvals81='0 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0'
bvecs81='0.0000 0.0000 -0.8600 0.8600 -0.7710 -0.7710 0.2124 -0.2124 0.2385 -0.2385 0.0530 -0.0530 0.3529 -0.3529 0.0000 0.0000 0.0000 0.7266 -0.7266 -0.9327 0.9327 -0.1209 0.1209 0.4519 -0.4519 0.6304 -0.6304 -0.1854 -0.1854 -0.4531 -0.4531 0.6153 0.6153 0.0000 -0.9200 -0.9200 0.4057 0.4057 0.7347 0.7347 0.6035 0.6035 0.0799 -0.0799 0.9052 0.9052 -0.2860 -0.2860 0.0000 -0.2919 0.2919 0.5197 -0.5197 0.0777 0.0777 0.1549 -0.1549 0.8036 0.8036 -0.5936 0.5936 0.9079 0.9079 0.0134 0.0134 0.0000 0.3140 0.3140 -0.8470 -0.8470 -0.7820 0.7820 -0.8783 -0.8783 -0.1737 0.1737 0.0800 -0.0800 0.5458 0.5458 0.0000 \n
0.0000 0.0000 0.5008 -0.5008 0.6040 0.6040 0.9650 -0.9650 -0.9097 0.9097 0.9148 -0.9148 0.9291 -0.9291 0.0000 0.0000 0.0000 0.5419 -0.5419 -0.1665 0.1665 -0.7402 0.7402 0.2477 -0.2477 -0.4859 0.4859 0.2952 0.2952 0.7214 0.7214 0.4157 0.4157 0.0000 0.3546 0.3546 -0.6460 -0.6460 -0.1613 -0.1613 0.6473 0.6473 -0.5528 0.5528 -0.1242 -0.1242 0.0145 0.0145 0.0000 0.4648 -0.4648 -0.8274 0.8274 -0.9922 -0.9922 -0.2466 0.2466 0.4193 0.4193 -0.8044 0.8044 0.3665 0.3665 0.5170 0.5170 0.0000 0.0242 0.0242 0.3495 0.3495 -0.6107 0.6107 0.0566 0.0566 -0.7318 0.7318 0.9828 -0.9828 -0.0366 -0.0366 0.0000 \n
0.0000 0.0000 0.0980 -0.0980 -0.2018 -0.2018 0.1540 -0.1540 -0.3401 0.3401 0.4004 -0.4004 -0.1106 0.1106 1.0000 -1.0000 0.0000 -0.4224 0.4224 -0.3199 0.3199 -0.6614 0.6614 -0.8570 0.8570 -0.6054 0.6054 0.9373 0.9373 0.5237 0.5237 -0.6697 -0.6697 0.0000 -0.1667 -0.1667 0.6466 0.6466 0.6590 0.6590 0.4656 0.4656 -0.8294 0.8294 0.4064 0.4064 0.9581 0.9581 0.0000 -0.8359 0.8359 0.2127 -0.2127 -0.0980 -0.0980 0.9566 -0.9566 0.4224 0.4224 0.0255 -0.0255 -0.2036 -0.2036 -0.8559 -0.8559 0.0000 0.9491 0.9491 0.4004 0.4004 0.1247 -0.1247 0.4747 0.4747 0.6590 -0.6590 -0.1667 0.1667 -0.8371 -0.8371 0.0000'
bvals79='0 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 3000 1500 0'
bvecs79="0.0000 0.0000 -0.8600 0.8600 -0.7710 -0.7710 0.2124 -0.2124 0.2385 -0.2385 0.0530 -0.0530 0.3529 -0.3529 0.0000 0.0000 0.0000 0.7266 -0.7266 -0.9327 0.9327 -0.1209 0.1209 0.4519 -0.4519 0.6304 -0.6304 -0.1854 -0.1854 -0.4531 -0.4531 0.6153 0.6153 0.0000 -0.9200 -0.9200 0.4057 0.4057 0.7347 0.7347 0.6035 0.6035 0.0799 -0.0799 0.9052 0.9052 -0.2860 -0.2860 0.0000 -0.2919 0.2919 0.5197 -0.5197 0.0777 0.0777 0.1549 -0.1549 0.8036 0.8036 -0.5936 0.5936 0.9079 0.9079 0.0134 0.0134 0.0000 0.3140 0.3140 -0.8470 -0.8470 -0.7820 0.7820 -0.8783 -0.8783 -0.1737 0.1737 0.0800 -0.0800 0.5458 0.5458 0.0000 \n
0.0000 0.0000 0.5008 -0.5008 0.6040 0.6040 0.9650 -0.9650 -0.9097 0.9097 0.9148 -0.9148 0.9291 -0.9291 0.0000 0.0000 0.0000 0.5419 -0.5419 -0.1665 0.1665 -0.7402 0.7402 0.2477 -0.2477 -0.4859 0.4859 0.2952 0.2952 0.7214 0.7214 0.4157 0.4157 0.0000 0.3546 0.3546 -0.6460 -0.6460 -0.1613 -0.1613 0.6473 0.6473 -0.5528 0.5528 -0.1242 -0.1242 0.0145 0.0145 0.0000 0.4648 -0.4648 -0.8274 0.8274 -0.9922 -0.9922 -0.2466 0.2466 0.4193 0.4193 -0.8044 0.8044 0.3665 0.3665 0.5170 0.5170 0.0000 0.0242 0.0242 0.3495 0.3495 -0.6107 0.6107 0.0566 0.0566 -0.7318 0.7318 0.9828 -0.9828 -0.0366 -0.0366 0.0000 \n
0.0000 0.0000 0.0980 -0.0980 -0.2018 -0.2018 0.1540 -0.1540 -0.3401 0.3401 0.4004 -0.4004 -0.1106 0.1106 1.0000 -1.0000 0.0000 -0.4224 0.4224 -0.3199 0.3199 -0.6614 0.6614 -0.8570 0.8570 -0.6054 0.6054 0.9373 0.9373 0.5237 0.5237 -0.6697 -0.6697 0.0000 -0.1667 -0.1667 0.6466 0.6466 0.6590 0.6590 0.4656 0.4656 -0.8294 0.8294 0.4064 0.4064 0.9581 0.9581 0.0000 -0.8359 0.8359 0.2127 -0.2127 -0.0980 -0.0980 0.9566 -0.9566 0.4224 0.4224 0.0255 -0.0255 -0.2036 -0.2036 -0.8559 -0.8559 0.0000 0.9491 0.9491 0.4004 0.4004 0.1247 -0.1247 0.4747 0.4747 0.6590 -0.6590 -0.1667 0.1667 -0.8371 -0.8371 0.0000"

# Find fieldmaps
for sess in 1 2
do
  for dir in pe0 pe1
  do
  if [ ! -d SE_fieldmap_${sess}_${dir} ]
  then
  echo "Fieldmap $sess $dir is missing" >> "$origdir/${subname}_BIDS_log.txt"
else
  cd "$(find . -name *fieldmap_${sess}_${dir} -type d)"
  mkdir -p $origdir/sub-${subname}/ses-${sess}/fmap
  cp *.nii.gz $origdir/sub-${subname}/ses-${sess}/fmap/sub-${subname}_ses-${sess}_dir-${dir}_epi.nii.gz
  # Keeping only one volume
  fslroi $origdir/sub-${subname}/ses-${sess}/fmap/sub-${subname}_ses-${sess}_dir-${dir}_epi.nii.gz $origdir/sub-${subname}/ses-${sess}/fmap/sub-${subname}_ses-${sess}_dir-${dir}_epi.nii.gz 3 -1
  # Copying json
  cp $jsonsfolder/Fieldmap_${dir}_ses${sess}.json $origdir/sub-${subname}/ses-${sess}/fmap/sub-${subname}_ses-${sess}_dir-${dir}_epi.json
  # Fixing json to match subject
  sed -i -e "s/SUBNUM/sub-${subname}/g" $origdir/sub-${subname}/ses-${sess}/fmap/sub-${subname}_ses-${sess}_dir-${dir}_epi.json
  cd ..
fi
done
done

# Find rest
for sess in 1 2
do
  for dir in pe0 pe1
  do
  if [ ! -d rfMRI_${sess}_${dir} ]
  then
  echo "Rest $sess $dir is missing" >> "$origdir/${subname}_BIDS_log.txt"
else
  cd "rfMRI_${sess}_${dir}"
  mkdir -p $origdir/sub-${subname}/ses-${sess}/func
  cp *.nii.gz $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-rest_acq-${dir}_bold.nii.gz
  # Cut 2 calibration volumes
  fslroi $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-rest_acq-${dir}_bold.nii.gz $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-rest_acq-${dir}_bold.nii.gz 2 -1
  # Copying json
  cp $jsonsfolder/Rest_${dir}.json $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-rest_acq-${dir}_bold.json
  cd ..
fi
done
done

# Find tasks
for task in emotion gambling wm
do
  if [ ! -d tfMRI_${task} ]
  then
  echo "${task} is missing" >> "$origdir/${subname}_BIDS_log.txt"
else
  sess=1
  cd "tfMRI_${task}"
  mkdir -p $origdir/sub-${subname}/ses-${sess}/func
  cp *.nii.gz $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-${task}_bold.nii.gz
  # Cut 2 calibration volumes
  fslroi $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-${task}_bold.nii.gz $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-${task}_bold.nii.gz 2 -1
  # Copying json
  cp $jsonsfolder/${task}.json $origdir/sub-${subname}/ses-${sess}/func/sub-${subname}_ses-${sess}_task-${task}_bold.json
  cd ..
fi
done

# Find T1
if [ ! -d T1w_MPRAGE_PROMO ]
then
echo "T1 is missing" >> "$origdir/${subname}_BIDS_log.txt"
else
  sess=1
  mkdir $origdir/sub-${subname}/ses-${sess}/anat
  cd "T1w_MPRAGE_PROMO"
  cp *.nii.gz $origdir/sub-${subname}/ses-${sess}/anat/sub-${subname}_ses-${sess}_T1w.nii.gz
  cd ..
fi

# Find T2
if [ ! -d T2w_CUBE_PROMO ]
then
echo "T2 is missing" >> "$origdir/${subname}_BIDS_log.txt"
else
  sess=1
  mkdir -p $origdir/sub-${subname}/ses-${sess}/anat
  cd "T2w_CUBE_PROMO"
  cp *.nii.gz $origdir/sub-${subname}/ses-${sess}/anat/sub-${subname}_ses-${sess}_T2w.nii.gz
  cd ..
fi

# Find DWI
for numdir in 79 81
do
for dir in pe0 pe1
do
  if [ ! -d DTI_${dir}_g${numdir} ]
  then
  echo "DTI ${dir} g${numdir} is missing" >> "$origdir/${subname}_BIDS_log.txt"
else
  sess=2
  mkdir -p $origdir/sub-${subname}/ses-${sess}/dwi
  cd "DTI_${dir}_g${numdir}"
  cp *.nii.gz $origdir/sub-${subname}/ses-${sess}/dwi/sub-${subname}_ses-${sess}_acq-${dir}g${numdir}_dwi.nii.gz
  # Copying json
  cp $jsonsfolder/Diffusion_${dir}.json $origdir/sub-${subname}/ses-${sess}/dwi/sub-${subname}_ses-${sess}_acq-${dir}g${numdir}_dwi.json
  # Writing bvals/bvecs
  var="bvals${numdir}"
  echo -en ${!var} > $origdir/sub-${subname}/ses-${sess}/dwi/sub-${subname}_ses-${sess}_acq-${dir}g${numdir}_dwi.bval
  var="bvecs${numdir}"
  echo -en ${!var} > $origdir/sub-${subname}/ses-${sess}/dwi/sub-${subname}_ses-${sess}_acq-${dir}g${numdir}_dwi.bvec
  cd ..
fi
done
done
