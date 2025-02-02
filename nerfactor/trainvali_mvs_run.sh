#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

scene='scan105'
gpus='3'
model='nerfactor_mvs'
overwrite='True'
proj_root='/data/vision/billf/intrinsic/sim'
repo_dir="$proj_root/code/nerfactor"
viewer_prefix='http://vision38.csail.mit.edu' # or just use ''

# I. Shape Pre-Training
imh='256'
near='200'
far='1000'
use_nerf_alpha='True'
surf_root="$proj_root/output/surf_mvs/$scene"
shape_outdir="$proj_root/output/train/${scene}_shape_mvs"
#REPO_DIR="$repo_dir" "$repo_dir/nerfactor/trainvali_run.sh" "$gpus" --config='shape_mvs.ini' --config_override="imh=$imh,near=$near,far=$far,use_nerf_alpha=$use_nerf_alpha,mvs_root=$surf_root,outroot=$shape_outdir,viewer_prefix=$viewer_prefix,overwrite=$overwrite"

# II. Joint Optimization (training and validation)
shape_ckpt="$shape_outdir/lr1e-2/checkpoints/ckpt-2"
brdf_ckpt="$proj_root/output/train/merl/lr1e-2/checkpoints/ckpt-50"
xyz_jitter_std=1
test_envmap_dir="$proj_root/data/envmaps/for-render_h16/test"
shape_mode='finetune'
outroot="$proj_root/output/train/${scene}_$model"
REPO_DIR="$repo_dir" "$repo_dir/nerfactor/trainvali_run.sh" "$gpus" --config="$model.ini" --config_override="imh=$imh,near=$near,far=$far,use_nerf_alpha=$use_nerf_alpha,mvs_root=$surf_root,shape_model_ckpt=$shape_ckpt,brdf_model_ckpt=$brdf_ckpt,xyz_jitter_std=$xyz_jitter_std,test_envmap_dir=$test_envmap_dir,shape_mode=$shape_mode,outroot=$outroot,viewer_prefix=$viewer_prefix,overwrite=$overwrite"
exit

# III. Simultaneous Relighting and View Synthesis (testing)
ckpt="$outroot/lr5e-3/checkpoints/ckpt-10"
if [[ "$scene" == pinecone || "$scene" == vasedeck || "$scene" == scan* ]]; then
    # Real scenes: NeRF & DTU
    color_correct_albedo='false'
else
    color_correct_albedo='true'
fi
REPO_DIR="$repo_dir" "$repo_dir/nerfactor/test_run.sh" "$gpus" --ckpt="$ckpt" --color_correct_albedo="$color_correct_albedo"
REPO_DIR=/data/vision/billf/intrinsic/sim/code/nerfactor
