%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clear the workspace

clear all
close all
clc

fclose('all');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Nominate some input folders

if ispc
  Username = getenv('Username');
  Home = fullfile('C:', 'Users', Username, 'Desktop');
elseif isunix || ismac
  [ Status, CmdOut ] = system('whoami');
  Home = fullfile('home', CmdOut, 'Desktop');
end  
  
StartPath = uigetdir(Home, 'Select a top-level folder with scan folders inside');

% 01. Magnitude
MagnitudeSource = uigetdir(StartPath, 'MAGNITUDE folder');

if ~ischar(MagnitudeSource)
  h = msgbox('No folder chosen', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end 
  
% 02. Phase
PhaseSource = uigetdir(StartPath, 'PHASE folder');

if ~ischar(PhaseSource)
  h = msgbox('No folder chosen', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Nominate a single output root folder

% 01. Sub-folders will be created in the worker function
MergedRoot = uigetdir(StartPath, 'Root folder for OUTPUT files');

if ~ischar(MergedRoot)
  h = msgbox('No folder chosen', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Call the worker function - this has been written so that it can be called programmatically for multiple acquisitions

pft_NonRigid2DFlowFunction(MagnitudeSource, PhaseSource, MergedRoot);