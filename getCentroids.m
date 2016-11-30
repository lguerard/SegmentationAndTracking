function getCentroids(subDir)

% This function will give the centroids of the tracked cells
% 
% Made by Laurent GUERARD

    %List all the images in the subdirectory
    imgs = dir([subDir filesep '*.tif']);
    imgs = {imgs.name}
    centroids = cell(numel(imgs),1);
    
    %Loop through the images to find the centroids
    for i = 1:numel(imgs)
        L = imread([subDir filesep imgs{i}]);
        stats = regionprops(L,'Centroid');

        %Build list of centroids for this image as regionprops will list
        %centroids as [NaN, Nan] for missing objects
        cents = NaN(numel(stats),2);
        for k = 1:numel(stats)
            cents(k,:) = stats(k).Centroid;
        end

        centroids{i} = cents;
    end
    
    %centroids{1}(13,:);
    
    title = '';
    
    nRow = max(cellfun(@length, centroids));
    nCol = length(centroids);
    col = 0;
    content = NaN(nRow,nCol)*2;
    for cID = 1:nCol
        %cID
        col = col +1;
        ne = length(centroids{cID});
        content(1:ne,col) = centroids{cID}(:,1);
        col = col +1;
        content(1:ne,col) = centroids{cID}(:,2);
    end
    
    maxSize = max(cellfun(@length,centroids));
    fcn = @(x) [x nan(1,maxSize-numel(x))];
    rmat = cellfun(fcn,centroids,'UniformOutput',false);
    rmat = vertcat(rmat{:});
    
    %centroids{1}(1,:)
%   
    centroidFile = strcat(subDir,filesep,'centroids.txt')
    fileID = fopen(centroidFile,'w');
    FirstLine = '\tTimePoint1';
    SecondLine = 'TrackID\tCoordX\tCoordY\t';
    add2 = 'CoordX\tCoordY\t';
    for i=2:(size(content,2)/2)
        add = strcat('TimePoint',num2str(i));
        FirstLine = strcat(FirstLine,'\t\t');
        FirstLine = strcat(FirstLine,add);
%         FirstLine
        SecondLine = strcat(SecondLine,add2);
%         SecondLine
    end
    fprintf(fileID,FirstLine);
    fprintf(fileID,'\r\n');
    fprintf(fileID,SecondLine);
    fprintf(fileID,'\r\n');

    printCol = '%f\t';
    add3 = printCol;
    for i=2:(size(content,2)/2)
        printCol = strcat(printCol,add3);
    end
    
    for i=1:size(content,1)
        %printTrack = ('%u\t',i)
        %printTrack = strcat(printTrack,i)
        fprintf(fileID,'%u\t',i);
        fprintf(fileID,printCol, content(i,:));
        fprintf(fileID,'\r\n');
    end
    
end