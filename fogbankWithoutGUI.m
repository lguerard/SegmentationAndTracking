function fogbankWithoutGUI(subDir,EGTAnswer,fogbankAnswer,borderAnswer,mitoticAnswer,seedAnswer)

% fogbankWithoutGUI   Allow the fogbank segmentation without GUI
%   Fogbank was developed at the National Institute of Standards and Technology by employees of the Federal Government
%   
%   Made by Laurent GUERARD 

    %Move to the folder where the function is stored
    tmp = matlab.desktop.editor.getActive;
    cd(fileparts(tmp.Filename));

    %Check that fogbank is not already deployed
    if ~isdeployed
        addpath([pwd filesep 'Fogbanksrc']);
    end


    % Global Params
    %-----------------------------------------------------------------------------------------
    %-----------------------------------------------------------------------------------------
    warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid'); % suppress warnings if the sliders min and max values are both 1
    
    %-------------------------------
    % FOLDER VARIABLES
    %-------------------------------
    
    raw_images_path = subDir
    raw_images_common_name = '';
    raw_image_files = [];
    nb_frames = 0;
    current_frame_nb = 1;
    
    save_images_path = strcat(raw_images_path,'SegmentationOutput');    
    mkdir(save_images_path);
    
    

    nb_frames_temp = 1;
    zero_pad = num2str(length(num2str(nb_frames_temp)));
    colormap_options = {'gray','jet','hsv','hot','cool'};
    contour_color_options = {'Red', 'Green', 'Blue', 'Black', 'White'};
    
    %--------------------------------------
    % FOREGROUND VARIABLES
    %--------------------------------------
    
    morphological_operations = {'None','Dilate','Erode','Close','Open'};
    fg_morph_operation = morphological_operations{1};
    fg_min_object_size = str2num(EGTAnswer{1});
    fg_min_hole_size = str2num(EGTAnswer{2});
    fg_greedy_slider_num = str2num(EGTAnswer{3});    
    fg_display_contour = true;
    fg_display_raw_image = true;
    fg_import_masks = false;
    fg_strel_disk_radius = str2num(EGTAnswer{4});
    
    os_display_use_border = str2bool(fogbankAnswer{1});
    os_display_use_mitotic = str2bool(fogbankAnswer{2})
    os_display_use_seed = str2bool(fogbankAnswer{3});
    os_display_contour = true;
    os_display_raw_image = true;

    load_seed_mask_path = raw_images_path;
    load_seed_mask_common_name = raw_images_common_name;
    use_load_seed_mask = false;
    seed_img_files = [];            
    

    % used in foreground mask and object separation panels
    min_object_size = str2num(fogbankAnswer{5});
    min_peak_size = str2num(fogbankAnswer{6});
    nb_obj = 0;

    img = [];
    foreground_mask = [];
    fogbank_direction = fogbankAnswer{4};
    %----------------------------------------
    % BORDER VARIABLES
    %----------------------------------------
    
    border_mask = [];
    border_threshold_value = str2num(borderAnswer{2});
    border_threshold_operator_modifier = borderAnswer{1};
    border_display_contour = false;
    border_thin_mask_flag = str2bool(borderAnswer{3});
    border_operate_on_gradient_flag = str2bool(borderAnswer{4});
    border_colormap = colormap_options{1};
    border_break_holes_flag = str2bool(borderAnswer{5});
    border_temp_mask = [];
    
    %----------------------------------------
    % SEED VARIABLES
    %----------------------------------------
    
    seed_mask = [];
    seed_min_object_size = str2num(seedAnswer{6});
    seed_max_object_size = str2num(seedAnswer{7});
    seed_display_contour = false;
    seed_threshold_operatorL = seedAnswer{3};
    seed_threshold_operatorR = seedAnswer{5};
    seed_threshold_valueL = str2num(seedAnswer{2});
    seed_threshold_valueR = str2num(seedAnswer{4});

    seed_use_border = true;
    seed_cluster_dist = str2num(seedAnswer{12});
    seed_circularity_threshold = str2num(seedAnswer{10});
    seed_strel_disk_radius = str2num(seedAnswer{9});
    seed_morph_operation = seedAnswer{8};
    seed_operate_on_gradient_flag = str2bool(seedAnswer{1});
    seed_adjust_contrast = 0;

    seed_display_labeled_text = false;
    seed_selected_colormap_opt = colormap_options{1};
    seed_temp_mask = [];

    seed_countour_color_selected_opt = contour_color_options{1};
    
    %----------------------------------------
    % MITOTIC VARIABLES
    %----------------------------------------
    
    mitotic_mask = [];
    mitotic_grayscale_modifier = mitoticAnswer{1}
    mitotic_threshold_modifier = mitoticAnswer{2}
    mitotic_threshold_value = str2num(mitoticAnswer{3})
    mitotic_filter_radius = str2num(mitoticAnswer{4})
    mitotic_min_object_size = str2num(mitoticAnswer{5})
    mitotic_threshold_operator = mitoticAnswer{6}
    mitotic_morph_operation = mitoticAnswer{7}
    mitotic_strel_disk_radius = str2num(mitoticAnswer{8})
    mitotic_min_peak_size = str2num(mitoticAnswer{9})
    mitotic_fogbank_direction = mitoticAnswer{10}
    mitotic_circularity_threshold = str2num(mitoticAnswer{11})

    mit_temp_mask = [];
    mit_text_location = 0;

    mit_display_labeled_text = false;

    threshold_operator_modifiers = {'>','<','>=','<='};
    seed_threshold_operator_modifiers = {'<','<='};
    threshold_modifiers = {'Pixel','Percentile'};
    grayscale_modifiers = {'Intensity','Gradient','Std','Entropy'};
    fg_adjust_contrast_display_raw_image = false;
    os_adjust_contrast_display_raw_image = false;

    %Check the path to the images to add a file separator if needed
    if raw_images_path(end) ~= filesep
        raw_images_path = [raw_images_path filesep];
    end
        
    %Get the list of all the files
    raw_image_files = dir([raw_images_path '*' raw_images_common_name '*.tif'])
    
    [pathstr,filename,ext] = fileparts(raw_image_files.name);
    
    nb_frames = length(raw_image_files);
    if nb_frames <= 0
        errordlg('Chosen img folder doesn''t contain any .tif images.');
    return;
    end
        
    % explore the possibility that this single image contains a sequence internally
    if nb_frames == 1
        stats = imfinfo([raw_images_path raw_image_files(1).name]);
        if numel(stats) > 1
            nb_frames = numel(stats);
            raw_image_files = repmat(raw_image_files, nb_frames,1);
        end
    end
    
    a = uint16(zeros(stats(1).Height,stats(1).Width,nb_frames));
    b = zeros(stats(1).Height, stats(1).Width, nb_frames);
    emptyImage = zeros(stats(1).Height, stats(1).Width);
    %size(a)
    
    %If multi frames, will loop through them
    for i = 1:nb_frames
        %Make the segmentation
        [segmented_image, nb_obj] = fogbank_given_image(i);
        %imshow(segmented_image);
        
        %Select the way to save the output images. Labeled mask needed for
        %the tracking
        type = 'Labeled Mask';

        switch type
            case 'Binary Mask'
                a(:,:,i) = uint16(logical(segmented_image));
                imwrite(uint16(logical(segmented_image)), [save_images_path filesep filename sprintf(['%0' zero_pad 'd'],i) '.tif']);                 
            case 'Labeled Mask'
                a(:,:,i) = uint16(segmented_image);
                imwrite(uint16(segmented_image), [save_images_path filesep filename sprintf(['T%0' zero_pad 'd'],i) '.tif']);                 
            otherwise % 'As Shown in Preview'
                a(:,:,i) = getSuperimpose_Image();
                imwrite(get_Superimpose_Image(), [save_images_path filesep filename sprintf(['%0' zero_pad 'd'],i) formatted_format]);
        end
        
       
    end
    
    %Create a folder to make one stack of all the segmented images
    mkdir([save_images_path filesep 'Stack' filename filesep]);
    imwrite(a(:,:,1), [save_images_path filesep 'Stack' filename filesep filename '.tif']);
    for k = 2:size(a,3)
        imwrite(a(:,:,k), [save_images_path filesep 'Stack' filename filesep filename '.tif'], 'writemode', 'append');
    end
    
    
    %Make the segmentation operation
    function [segmented_image, nb_obj] = fogbank_given_image(img_nb)
        
        img = loadCurrentImage(img_nb);
        
        foreground_mask = get_Foreground_Mask();
        
        % get a copy of the border mask
        border_mask = get_Border_Mask_Image();
        % get a copy of the seed mask
        seed_mask = get_Seed_Mask_Image();
        % get a copy of the mitotic mask
        mitotic_mask = get_Mitotic_Mask_Image();
        
        % get the img fogbank will operate on
        I1 = get_Fogbank_Input_Image();
        
        temp_border_mask = border_mask;
        if ~os_display_use_border || isempty(border_mask)
            temp_border_mask = false(size(foreground_mask));
        end
        
        % fog bank the images
        temp = regexprep(fogbank_direction, '\W', '');
        if strcmpi(temp, 'minmax')
            fogbank_dir = 1;
        else
            fogbank_dir = 0;
        end
        
        prctile_bin = 5;
        
        % apply the seeds to I1
        if os_display_use_seed && ~isempty(seed_mask)
            if fogbank_dir % min to max
                I1(seed_mask>0) = min(I1(seed_mask>0));
            else % max to min
                I1(seed_mask>0) = max(I1(seed_mask>0));
            end
            
            [segmented_image, ~] = fog_bank_perctile_geodist_seed(I1, logical(foreground_mask), ~temp_border_mask, seed_mask, min_object_size, fogbank_dir, prctile_bin);
            
            % if any foreground region was not found by a seed add it back in to prevent loosing any area
            temp = bwlabel(foreground_mask);
            temp(segmented_image>0) = 0;
            mv = max(temp(:));
            if mv ~= 0
                temp = bwlabel(bwareaopen(temp,min_object_size));
                temp = cast(temp, class(segmented_image));
                highest_cell_nb = max(segmented_image(:));
                temp(temp>0) = temp(temp>0) + highest_cell_nb;
                % copy in the missing objects
                segmented_image(temp>0) = temp(temp>0);
            end
        else
            [segmented_image, ~] = fog_bank_perctile_geodist(I1, logical(foreground_mask), ~temp_border_mask, min_peak_size, min_object_size, fogbank_dir, prctile_bin);
        end
        
        if os_display_use_mitotic && ~isempty(mitotic_mask)
            mitotic_mask = relabel_image(mitotic_mask);
            temp = mitotic_mask>0;
            mitotic_mask(temp) = mitotic_mask(temp) + max(segmented_image(:));
            
            segmented_image(temp) = mitotic_mask(temp);
            
            [segmented_image, nb_obj] = relabel_image(segmented_image);
            segmented_image = check_body_connectivity(segmented_image, nb_obj);
        end
        
        nb_obj = max(segmented_image(:));
        
        
    end
    
    function I = loadCurrentImage(nb)
            if nargin == 0
                nb = current_frame_nb;
            end
            if numel(imfinfo([raw_images_path raw_image_files(nb).name])) > 1
                I = imread([raw_images_path raw_image_files(nb).name], 'Index', nb);
            else
                I = imread([raw_images_path raw_image_files(nb).name]);
            end
    end

    function BW = get_Foreground_Mask()
            BW = EGT_Segmentation(img,fg_min_object_size,fg_min_hole_size, fg_greedy_slider_num);
            fg_morph_operation = lower(regexprep(fg_morph_operation, '\W', ''));
            BW = morphOp(img, BW, fg_morph_operation, fg_strel_disk_radius);
            
            BW = fill_holes(BW, fg_min_hole_size);
            BW = bwareaopen(BW ,fg_min_object_size,8);
            
    end


    function BW = morphOp(I, BW, op_str, radius, border_mask)
        if nargin == 5
            use_border_flag = true;
        else
            use_border_flag = false;
            border_mask = [];
        end

        if radius == 0
            return; % radius of 0 will have no affect
        end

        border_mask = logical(border_mask);


        op_str = lower(regexprep(op_str, '\W', ''));
        switch op_str
            case 'dilate'
                if use_border_flag
                    BW = geodesic_imdilate(BW, ~border_mask, radius);
                else
                    BW = imdilate(BW, strel('disk', radius));
                end
            case 'erode'
                BW = imerode(BW, strel('disk', radius));
            case 'close'
                if use_border_flag
                    BW = geodesic_imclose(BW, ~border_mask, radius);
                else
                    BW = imclose(BW, strel('disk', radius));
                end
            case 'open'
                if use_border_flag
                    BW = geodesic_imopen(BW, ~border_mask, radius);
                else
                    BW = imopen(BW, strel('disk', radius));
                end

            case 'iterativegraydilate'
                BW = iterative_geodesic_gray_dilate(I, BW, ~border_mask, radius, 0.5);
        end

    end

    function BW = get_Border_Mask_Image()
            
            if os_display_use_border
                if border_operate_on_gradient_flag
                    img_filter = 'gradient';
                else
                    img_filter = 'none';
                end
                %img_filter
                BW = generate_border_mask(img, img_filter, border_threshold_value, border_threshold_operator_modifier, border_break_holes_flag, border_thin_mask_flag, foreground_mask);
                disp('End');
            else
                BW = [];
            end

    end

    function I1 = get_Fogbank_Input_Image()

            %temp = 1;
            type_str = 'Grayscale';
            type_str = strrep(lower(type_str), ' ','');

            I1 = [];
            if strcmpi(type_str, 'distancetransformfromseeds')
                if os_display_use_seed
                    % distance transform from the seeds
                    if os_display_use_border
                        I1 = bwdistgeodesic(~border_mask, seed_mask>0, 'quasi-euclidean');
                    else
                        I1 = bwdist(seed_mask>0, 'euclidean');
                    end
                else
                    errordlg('Cannot use Distance Transform from Seeds without enabling the seed mask');
                    return;
                end
            end
            if strcmpi(type_str, 'distancetransformfrombackground')
                % distance transform from the background
                if os_display_use_border
                    temp = foreground_mask;
                    temp(~border_mask) = 0;
                    I1 = bwdist(temp, 'euclidean');
                else
                    I1 = bwdist(~foreground_mask, 'euclidean');
                end
            end
            if strcmpi(type_str, 'gradient')
                I1 = imgradient(img);
            end


            if ~isempty(I1)
                I1(~foreground_mask) = 0;
                I1(isnan(I1)) = max(I1(:));
            end
            if isempty(I1)
                I1 = double(img);
            end
            I1(isinf(I1)) = max(I1(~isinf(I1)));
    end
    

    function BW = get_Seed_Mask_Image(load_img_flag)

            if os_display_use_seed
                gen_seed_image_flag = false;
                if exist('load_img_flag','var')
                    if load_img_flag
                        gen_seed_image_flag = false;
                    else
                        gen_seed_image_flag = true;
                    end
                else
                    if use_load_seed_mask
                        gen_seed_image_flag = false;
                    else
                        gen_seed_image_flag = true;
                    end

                end

                if ~gen_seed_image_flag

                    if numel(imfinfo([load_seed_mask_path seed_img_files(current_frame_nb).name])) > 1
                        BW = imread([load_seed_mask_path seed_img_files(current_frame_nb).name], 'Index', current_frame_nb);
                    else
                        BW = imread([load_seed_mask_path seed_img_files(current_frame_nb).name]);
                    end
                    BW = double(BW);

                    if size(BW,1) ~= size(img,1) || size(BW,2) ~= size(img,2)
                        errordlg('Loaded Seed image doesn''t match the image dimensions of the image being segmented.');
                        return;
                    end

                    % if BW is a binary image, relabel it into connected component objects
                    u = unique(BW);
                    if numel(u) <= 2
                        BW = bwlabel(BW);
                    end

                else
                    if seed_operate_on_gradient_flag
                        img_filter = 'gradient';
                    else
                        img_filter = 'none';
                    end

                    % swap the direction of the left operator to reflect the face that its: <thres> <operator> <pixelvalue>
                    % instead of <pixelvalue> <operator> <thres>
                   switch seed_threshold_operatorL
                       case '<'
                           tempL = '>=';
                       case '<='
                           tempL = '>';
                       case '>'
                           tempL = '<=';
                       case '>='
                           tempL = '<';
                       otherwise
                           error('Invalid Threhsold Operator');
                   end

                   if seed_use_border
                       BW = generate_seed_mask(img, img_filter, seed_threshold_valueL, tempL, seed_threshold_valueR, seed_threshold_operatorR, seed_min_object_size, seed_max_object_size, seed_circularity_threshold, seed_cluster_dist, foreground_mask, border_mask);
                   else
                       BW = generate_seed_mask(img, img_filter, seed_threshold_valueL, tempL, seed_threshold_valueR, seed_threshold_operatorR, seed_min_object_size, seed_max_object_size, seed_circularity_threshold, seed_cluster_dist, foreground_mask);
                   end

                    % perform any required morphological cleanup of the img
                    seed_morph_operation = lower(regexprep(seed_morph_operation, '\W', ''));
                    if seed_use_border
                        BW = morphOp(img, BW, seed_morph_operation, seed_strel_disk_radius, ~foreground_mask);
                    else
                        BW = morphOp(img, BW, seed_morph_operation, seed_strel_disk_radius);
                    end
                end
            else
                BW = [];
            end
    end


    function BW = get_Mitotic_Mask_Image()
            if os_display_use_mitotic
                I1 = generate_image_to_threshold(img, mitotic_grayscale_modifier, mitotic_filter_radius);
                [BW, ~] = threshold_image(I1, mitotic_threshold_modifier,mitotic_threshold_operator, mitotic_threshold_value);
                BW = logical(BW);
    %             if strcmpi(mitotic_threshold_operator, threshold_operator_modifiers{2})
    %                 BW = ~BW;
    %             end

                BW = fill_holes(BW, mitotic_min_object_size*2);

                mitotic_morph_operation = lower(regexprep(mitotic_morph_operation, '\W', ''));
                BW = morphOp(img, BW, mitotic_morph_operation, mitotic_strel_disk_radius);

                BW = bwareaopen(BW, mitotic_min_object_size+1);

                % fog bank the images
                temp = regexprep(mitotic_fogbank_direction, '\W', '');
                if strcmpi(temp, 'minmax')
                    fogbank_dir = 1;
                else
                    fogbank_dir = 0;
                end

                temp = logical(BW);
                temp = imerode(temp, strel('disk',ceil(mitotic_strel_disk_radius/2)));
                % fog bank mitotic cell apart
                [BW, ~] = fog_bank_perctile_geodist(I1, logical(BW), temp, mitotic_min_peak_size, mitotic_min_object_size, fogbank_dir, 10);
                BW = filter_by_circularity(BW, mitotic_circularity_threshold);

            else
                BW = [];
            end

    end
    
    function I = generate_image_to_threshold(I, method, fwr)

        method = lower(regexprep(method, '\W', ''));

        if strfind(method, 'gradient')
            invalid_pixels = (I == 0);
            I = double(I);

            I = imgradient(I,'Sobel');
            I(invalid_pixels) = 0;
        end

        if strfind(method, 'entropy')
            invalid_pixels = (I == 0);

            if ~exist('fwr','var')
                fwr = 2;
            end
            rd = 2*fwr + 1;
            nhood = true(rd,rd);

            I = entropyfilt(I,nhood);
            I(invalid_pixels) = 0;
        end

        if strfind(method, 'std')
            if ~exist('fwr','var')
                fwr = 2;
            end
            rd = 2*fwr + 1;
            nhood = true(rd,rd);

            invalid_pixels = (I == 0);
            I = double(I);
            I = stdfilt(I, nhood);
        %     I = compute_std_filter(I, fwr);
            I(invalid_pixels) = 0;
        end

    end

    function [BW, threshold_value] = threshold_image(I, modifier, operator, threshold_value)

        modifier = lower(regexprep(modifier, '\W', ''));

        if strfind(modifier, 'percentile')
            assert(threshold_value >= 0 && threshold_value <= 100);
            P = prctile(single(I(:)), threshold_value);
            threshold_value = P(1); 
        end

        switch operator
            case '>'
                BW = I > threshold_value;
            case '<'
                BW = I < threshold_value;
            case '>='
                BW = I >= threshold_value;
            case '<='
                BW = I <= threshold_value;
            otherwise
                error('Invalid threshold operator');
        end
    end
    
end



