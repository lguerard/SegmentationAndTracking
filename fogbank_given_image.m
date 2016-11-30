function testWithoutGUI()

    raw_images_path = '/home/laurent/Downloads/AnnaL/Ibidi 24 plastic ibitreat-160622_Ph1_002/data/OutputTest0/11102016/';
            if raw_images_path(end) ~= filesep
                raw_images_path = [raw_images_path filesep];
            end

    %a = imread('/home/laurent/Downloads/AnnaL/Ibidi 24 plastic ibitreat-160622_Ph1_002/data/OutputTest0/11102016/C5_Trans.tif');
    [segmented_image, nb_obj] = fogbank_given_image(1);


end

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