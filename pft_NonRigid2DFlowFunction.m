function pft_NonRigid2DFlowFunction(MagnitudeSource, PhaseSource, MergedRoot)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Nominate some o/p folders

% 01. Motion-corrected modulus
MagnitudeTarget = fullfile(MergedRoot, 'MAGNITUDE - NON-RIGID');

if (exist(MagnitudeTarget, 'dir') ~= 7)
  mkdir(MagnitudeTarget);
end

% 02. Motion-corrected velocity
VelocityTarget = fullfile(MergedRoot, 'VELOCITY - NON-RIGID');

if (exist(VelocityTarget, 'dir') ~= 7)
  mkdir(VelocityTarget);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read in the source data
[ MagnitudeData, MagnitudeInfo ] = pft_ReadDicomCineStack(MagnitudeSource);

[ PhaseData, PhaseInfo ] = pft_ReadDicomCineStack(PhaseSource);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convert the phase images to velocity units (cm/s)
[ Intercept, Slope ] = pft_GetVelocityScaling(PhaseInfo{1});

Velocity = Intercept + Slope*double(PhaseData);

Venc = - Intercept;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Assign some o/p arrays
[ NROWS, NCOLS, NEPOCHS ] = size(MagnitudeData);

MoCoMagnitude = zeros([NROWS, NCOLS, NEPOCHS], 'double');
MoCoVelocity  = zeros([NROWS, NCOLS, NEPOCHS], 'double');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for e = 1:NEPOCHS
  MoCoMagnitude(:, :, e) = squeeze(MagnitudeData(:, :, e));
  MoCoVelocity(:, :, e) = squeeze(Velocity(:, :, e));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 01. Write out the modulus images
Dictionary = dicomdict('get');

wb = waitbar(0, 'Writing out MoCo modulus images');

NFILES = NEPOCHS;

n = 1;

for e = 1:NEPOCHS
  Head = MagnitudeInfo{n};
  
  Head.RescaleType       = 'Grayscale';
  Head.SeriesDescription = 'Synthetic RSS image';
  Head.ImageComments     = 'MoCo Magnitude image';
  
  OutputPathName = fullfile(MagnitudeTarget, pft_NumberedFileName(n));
  
  dicomwrite(uint16(MoCoMagnitude(:, :, e)), OutputPathName, Head, 'CreateMode', 'copy', 'Dictionary', Dictionary, 'WritePrivate', true);
  
  waitbar(double(n)/double(NFILES), wb, sprintf('%1d of %1d files written', n, NFILES));
    
  n = n + 1;
end

waitbar(1, wb, sprintf('%1d of %1d files written', NFILES, NFILES));
pause(1.0);
delete(wb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 02. Write out the velocity images
MoCoPhaseData = uint16(double(2^15)*(MoCoVelocity/Venc + 1.0));

wb = waitbar(0, 'Writing out MoCo velocity images');

NFILES = NEPOCHS;

n = 1;

for e = 1:NEPOCHS
  Head = pft_ModifyHeader(PhaseInfo{n}, Venc, 'Synthetic RSS image', '16-bit MoCo phase image');
    
  OutputPathName = fullfile(VelocityTarget, pft_NumberedFileName(n));
  
  dicomwrite(MoCoPhaseData(:, :, e), OutputPathName, Head, 'CreateMode', 'copy', 'Dictionary', Dictionary, 'WritePrivate', true);
  
  waitbar(double(n)/double(NFILES), wb, sprintf('%1d of %1d files written', n, NFILES));
    
  n = n + 1;
end

waitbar(1, wb, sprintf('%1d of %1d files written', NFILES, NFILES));
pause(1.0);
delete(wb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Write out a small summary file
fid = fopen(fullfile(MergedRoot, 'Summary - Non-Rigid Co-Registration.txt'), 'wt');

fprintf(fid, 'Magnitude source folder: %s\n', MagnitudeSource);
fprintf(fid, 'Phase source folder:     %s\n', PhaseSource);

fprintf(fid, '\n');

fprintf(fid, 'Output root folder: %s\n', MergedRoot);

fprintf(fid, '\n');

fprintf(fid, 'Original Venc  = %.2f cm/s\n', Venc);

fprintf(fid, '\n');

fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Write out a tidy XLSX file with information grouped into several tabs

FolderData = { 'INPUTS',             ' '; ...
               'Magnitude',  MagnitudeSource; ...
               'Phase',      PhaseSource; ...
               'OUTPUTS ',           ' ';
               'Output Root Folder', MergedRoot };
           
xlswrite(fullfile(MergedRoot, 'Processing Summary.xlsx'), FolderData, 'Data Folders');

ProcessingData = { 'Co-Registration'; ...
                   'Non-Rigid' };
               
xlswrite(fullfile(MergedRoot, 'Processing Summary.xlsx'), ProcessingData, 'Processing');

VencData = { 'Image',                         'Venc [cm/s]',                      'Intercept',                          'Slope'; ...
             'Original Venc',              Venc,                             - Venc,                             2.0*Venc/double(2^12);
             };
         
xlswrite(fullfile(MergedRoot, 'Processing Summary.xlsx'), VencData, 'Vencs and Velocity Scaling');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Signal completion
h = msgbox('All done !', 'Exit', 'modal');
uiwait(h);
delete(h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function ends
end




