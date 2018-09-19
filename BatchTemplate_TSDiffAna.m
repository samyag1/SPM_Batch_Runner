%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 3944 $)
%-----------------------------------------------------------------------
matlabbatch{1}.tsdiffana_tools{1}.tsdiffana_timediff.imgs = {
    $$$INSERT_FILES$$$
    }';
matlabbatch{1}.tsdiffana_tools{1}.tsdiffana_timediff.vf = false;
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1) = cfg_dep;
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).tname = 'Timeseries Analysis Data Files';
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).tgt_spec{1}(1).value = 'mat';
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).tgt_spec{1}(2).value = 'e';
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).sname = 'Analyse Time Series: Timeseries Analysis Data File (1)';
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.tdfn(1).src_output = substruct('.','tdfn', '()',{1});
matlabbatch{2}.tsdiffana_tools{1}.tsdiffana_tsdiffplot.doprint = true;
