% Fix for Mac Pro invariant set problem. 
cwd = pwd; 
cd(fileparts(which('lcp'))) 
lcp_compile; 
cd(cwd) 
% and then update the toolboxes:
tbxmanager update
clear classes
mpt_init

