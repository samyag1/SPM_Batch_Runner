%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 3944 $)
%-----------------------------------------------------------------------
matlabbatch{1}.spm.spatial.coreg.estimate.ref = $$$INSERT_REFERENCE$$$;
matlabbatch{1}.spm.spatial.coreg.estimate.source = $$$INSERT_SOURCE$$$;
matlabbatch{1}.spm.spatial.coreg.estimate.other = $$$INSERT_FILES$$$;
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
