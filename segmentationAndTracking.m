function segmentationAndTracking()

% Function to make all the different steps wanted
% - Stitching through FIJI
% - Segmentation through Fogbank
% - Tracking through Lineage Mapper
% - Get the centroids via Matlab
%
% Made by Laurent GUERARD

    tic;
    
    % This function will call all the different functions necessary
    
    %Set the working directory
    %tmp = matlab.desktop.editor.getActive;
    %cd(fileparts(tmp.Filename));
    
    %----------------------------------------
    % 1st PART WITH THE FIJI STITCHING MACRO
    %----------------------------------------
    
    choiceStitching = lower(questdlg('Do you want to do the stitching part ?',...
        'Stitching?', ...
        'Yes','No','Cancel','Cancel'));
    
    switch choiceStitching
        case 'yes'    
               message = sprintf('The 1st part of the code will be to tile and stitch the images.\r\n To do so, please select the folder where the images are.');
               waitfor(msgbox(message));
               runFIJIMacro();
        case 'cancel'
               error('Cancel button pressed');
    end
    
    %Get the home folder of the user
    if ispc
        home = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
    else
        home = getenv('HOME');
    end
    
    home = strcat(home,filesep);
    
    %Check if the FIJI script has been executed. If not, ask for the image
    %folder.
    textFilePath = strcat(home,'folder.txt');
    if exist(textFilePath,'file') == 2
        raw_images_path_temp = fileread(textFilePath);
        raw_images_path = strcat(raw_images_path_temp,'OutputStitched/SingleImages')
    else
        raw_images_path = uigetdir(home,'Choose the Single Images folder')
    end
    
    subDirs = dir(raw_images_path);
    
    message2 = sprintf(['The 2nd and 3rd part of the code will be for the segmentation and the tracking of the images.\r\n',...
        'These 2 steps will require a lot of parameters that can be known only by first using the segmentation and tracking tools.\r\n',...
        'Be careful, you might need to write down the parameters since they are quite numerous. Also, don''t save the results, the images will be saved for all the folders at once.']);
    
    waitfor(msgbox(message2));
    
    choiceSegmentation = lower(questdlg('Do you already have the parameters for the segmentation ?',...
        'Segmentation?', ...
        'Yes','No','Cancel','Cancel'));
    
    switch choiceSegmentation
        case 'no'    
              FogBank_GUI_v2();
              waitfor(msgbox('When you''ve found parameters for your segmentation, click OK'));
        case 'cancel'
            error('Cancel button pressed');
    end
    
    
    
    choiceTracking = lower(questdlg('Do you already have the parameters for the tracking ?',...
        'Tracking?', ...
        'Yes','No','Cancel','Cancel'));
    
    switch choiceTracking
        case 'no'    
              Lineage_Mapper();
              waitfor(msgbox('When you''ve found parameters for your tracking, click OK'));
        case 'cancel'
            error('Cancel button pressed');
    end
    
    %-----------------------------------
    % PARAMETERS FOR SEGMENTATION 
    %-----------------------------------
    
    %------------------------------------
    % Pop up window for EGT segmentation
    %------------------------------------
    
    dlg_title = 'EGT segmentation values';
    prompt = {'Enter Minimal object size:','Enter Minimal Hole size:','Enter value for the greedy slider:',...
        'Enter morpholigical radius:'};
    num_lines = 1;
    defaultans = {'2000','3000','0','2'};
    EGTAnswer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    
    if size(EGTAnswer) == 0
        error('Cancel button pressed');
    end
    
    %-----------------------------------
    % Pop up window for fogbank segmentation
    %-----------------------------------
    
    dlg2_title = 'Fogbank segmentation values';
    fogbankprompt = {'Use Border Mask? (enter True or False):',...
        'Use Mitotic Mask? (enter True or False):','Use Seed Mask? (enter True or False):',...
        'Fogbank direction (enter Min -> Max or Max -> Min):','Min Object Area','Min Seed Size'};
    fogbanknum_lines = 1;
    fogbankdefaultans = {'False','False','False','Min -> Max','1000','1000'};
    fogbankAnswer = inputdlg(fogbankprompt,dlg2_title,fogbanknum_lines,fogbankdefaultans);
    
    if size(fogbankAnswer) == 0
        error('Cancel button pressed');
    end
    
    %-----------------------------------
    % Pop up window for the border mask
    %-----------------------------------
    
    borderAnswer = {'>','85','True','False','False'};
    
    if (strcmp(lower(fogbankAnswer{1}),'true'))
        borderTitle = 'Border Mask Options';
        borderPrompt = {'Foreground operator (possible values: > < >= <=):',...
            'Foreground pixels:','Thin Mask (entre True or False):',...
            'Operate on Gradient (enter True or False):','Break Holes (enter True or False):'};
        borderLines = 1;
        borderDefaultans = {'>','85','True','False','False'};
        borderAnswer = inputdlg(borderPrompt,borderTitle,borderLines,borderDefaultans);
    end

    if size(borderAnswer) == 0
        error('Cancel button pressed');
    end
    
    %----------------------------------
    % Pop up window for the mitotic mask
    %----------------------------------
    
    mitoticAnswer = {'Intensity','Percentile','97','1','250','>','None','8','120','Min -> Max','0.3'};
    
    if (strcmp(lower(fogbankAnswer{2}),'true'))
        mitoticTitle = 'Mitotic Mask Options';
        mitoticPrompt = {'Grayscale modifier (possible values: Intensity, Gradient, Std, Entropy):',...
            'Threshold modifier (possible values: Pixel, Percentile):',...
            'Threshold value:','Filter radius:',...
            'Minimum Size Object:',...
            'Threshold modifier (possible values: > < >= <=):',...
            'Morphological operation (possible values: None, Dilate, Erode, Close, Open):',...
            'Morphological radius:','Min seed area',...
            'Fogbank direction (possible values Min -> Max, Max -> Min):',...
            'Circularity Threshold:'};
        mitoticLines = 1;
        mitoticDefaultAns = {'Intensity','Percentile','97','1','250','>','None','8','120','Min -> Max','0.3'};
        mitoticAnswer = inputdlg(mitoticPrompt,mitoticTitle,mitoticLines,mitoticDefaultAns);
    end
    
    if size(mitoticAnswer) == 0
        error('Cancel button pressed');
    end
    
    %----------------------------------
    % Pop up window for the seed mask
    %----------------------------------
    
    seedAnswer = {'False','3','<','<','10','15','120','None','2',...
            '0','Geodesic','25'};

    
    if (strcmp(lower(fogbankAnswer{3}),'true'))
        seedTitle = 'Seed Mask Options';
        seedPrompt = {'Operate on Gradient (enter True or False):',...
            'Percentile Threshold left:','Percentile Threshold operator left (possible values < <=):',...
            'Percentile Threshold right:','Percentile Threshold operator right (possible values < <=):',...
            'Object Size Range left:','Object Size Range right:',...
            'Morphological Operation (possible values None Dilate Erode Close Open):',...
            'Morphological Operation radius:','Circularity threshold:',...
            'Cluster Seeds Using (possible values Geodesic Euclidian):',...
            'Cluster distance:'};
        seedLines = 1;
        seedDefaultAns = {'False','3','<','10','<','15','120','None','2',...
            '0','Geodesic','25'};
        seedAnswer = inputdlg(seedPrompt,seedTitle,seedLines,seedDefaultAns);
    end

    if size(seedAnswer) == 0
        error('Cancel button pressed');
    end
    
    
    %-----------------------------------
    % PARAMETERS FOR TRACKING 
    %----------------------------------- 
    
    %trackAnswer = {'100','50','20','50','20','50','70','30',...
        %'5','True','32','10','1','1','100','20','False'};
    
    trackTitle = 'Lineage Mapper tracking values';
    trackPrompt = {'Weight Overlap:','Weight Centroids:','Weight Size:',...
        'Max centroids distance:','Division overlap threshold:',...
        'Daughter size similarity:','Daughter aspect ratio similarity:',...
        'Circularity threshold:','Number of frames to check circularity:',...
        'Enable cell mitosis (True or False):','Cell life threshold:',...
        'Cell apoptosis delta centroids threshold:','Cell density:',...
        'Border cell:','Cell size threshold:','Fusion overlap threshold',...
        'Enable cell fusion (True or False):'};
    trackNumLines = 1;
    trackDefaultAns = {'100','50','20','50','20','50','70','30',...
        '5','True','32','10','1','1','100','20','False'};
    trackAnswer = inputdlg(trackPrompt,trackTitle,trackNumLines,trackDefaultAns);
    
    if size(trackAnswer) == 0
        error('Cancel button pressed');
    end
    
    %-----------------------------------
    % LOOP THROUGH ALL THE SUBFOLDERS
    %-----------------------------------
    
    %Filters out all the iteam in the main folder that are not directories
    subDirs(~ [subDirs.isdir]) = [];
    
    %And this filters out the parent and current directory '.' and '..'
    tf = ismember( {subDirs.name}, {'.', '..'});
    subDirs(tf) = [];
    numberOfFolders = length(subDirs);           
    
    for i = 1: numberOfFolders
        thisSubDir = subDirs(i).name
        fullPath = strcat(raw_images_path,filesep,thisSubDir,filesep) 
        fogbankWithoutGUI(fullPath,EGTAnswer,fogbankAnswer,borderAnswer,mitoticAnswer,seedAnswer);
        lineageMapperWithoutGUI(fullPath,thisSubDir,trackAnswer);
        trackingPath = strcat(fullPath,'SegmentationOutput',filesep,'Tracking',filesep)
        getCentroids(trackingPath);
    end
        
    %-----------------
    % END MESSAGE
    %-----------------
    
    message = sprintf('The macro is now finished. You should find the centroid coordinates in each well folder.');
    toc;
end

