%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 3944 $)
%-----------------------------------------------------------------------
matlabbatch{1}.spm.spatial.preproc.data = $$$INSERT_REFERENCE$$$;
matlabbatch{1}.spm.spatial.preproc.output.GM = [0 0 1];
matlabbatch{1}.spm.spatial.preproc.output.WM = [0 0 1];
matlabbatch{1}.spm.spatial.preproc.output.CSF = [0 0 1];
matlabbatch{1}.spm.spatial.preproc.output.biascor = 1;
matlabbatch{1}.spm.spatial.preproc.output.cleanup = 0;
matlabbatch{1}.spm.spatial.preproc.opts.tpm = {
                                               '/usr/local/matlab-tools/spm/spm8/tpm/grey.nii'
                                               '/usr/local/matlab-tools/spm/spm8/tpm/white.nii'
                                               '/usr/local/matlab-tools/spm/spm8/tpm/csf.nii'
                                               };
matlabbatch{1}.spm.spatial.preproc.opts.ngaus = [2
                                                 2
                                                 2
                                                 4];
matlabbatch{1}.spm.spatial.preproc.opts.regtype = 'mni';
matlabbatch{1}.spm.spatial.preproc.opts.warpreg = 1;
matlabbatch{1}.spm.spatial.preproc.opts.warpco = 25;
matlabbatch{1}.spm.spatial.preproc.opts.biasreg = 0.0001;
matlabbatch{1}.spm.spatial.preproc.opts.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.opts.samp = 3;
matlabbatch{1}.spm.spatial.preproc.opts.msk = {''};
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1) = cfg_dep;
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).tname = 'Parameter File';
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(1).value = 'mat';
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(2).value = 'e';
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).sname = 'Segment: Norm Params Subj->MNI';
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{2}.spm.spatial.normalise.write.subj.matname(1).src_output = substruct('()',{1}, '.','snfile', '()',{':'});
matlabbatch{2}.spm.spatial.normalise.write.subj.resample = $$$INSERT_FILES$$$;
matlabbatch{2}.spm.spatial.normalise.write.roptions.preserve = 0;
matlabbatch{2}.spm.spatial.normalise.write.roptions.bb = [NaN NaN NaN
                                                          NaN NaN NaN];
matlabbatch{2}.spm.spatial.normalise.write.roptions.vox = [NaN NaN NaN];
matlabbatch{2}.spm.spatial.normalise.write.roptions.interp = 1;
matlabbatch{2}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
matlabbatch{2}.spm.spatial.normalise.write.roptions.prefix = 'w';
