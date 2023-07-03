% Tümörleri tespit etmek için çağrılan fonksiyon
function detectTumors(~, ~)
    if isempty(selectedImage)
        disp('Önce bir resim seçmelisiniz.');
        return;
    end
    % Tümör tespiti işlemleri
    num_iter = 10;
    delta_t = 1/7;
    kappa = 15;
    option = 2;
    inp = anisodiff(selectedImage,num_iter,delta_t,kappa,option);
    inp = uint8(inp);
    inp = imresize(inp,[256,256]);
    if size(inp,3) > 1
        inp = rgb2gray(inp);
    end
    sout = imresize(inp,[256,256]);
    t0 = 60;
    th = t0 + ((max(inp(:)) + min(inp(:))) ./ 2);
    for i = 1:size(inp,1)
        for j = 1:size(inp,2)
            if inp(i,j) > th
                sout(i,j) = 1;
            else
                sout(i,j) = 0;
            end
        end
    end
    label = bwlabel(sout);
    stats = regionprops(logical(sout), 'Solidity', 'Area', 'BoundingBox');
    density = [stats.Solidity];
    area = [stats.Area];
    high_dense_area = density > 0.6;
    max_area = max(area(high_dense_area));
    tumor_label = find(area == max_area);
    tumor = ismember(label, tumor_label);
    if max_area > 100
        detectedTumors = tumor;
        imshow(detectedTumors, 'Parent', resultAxes);
        tumorReport = sprintf('%s\tTespit edilen tümör sayısı: %d', getHastaIsmi(), numel(tumor_label));
        set(reportText, 'String', tumorReport);
    else
        detectedTumors = [];
        imshow(selectedImage, 'Parent', resultAxes);
        tumorReport = 'Tümör bulunamadı.';
        set(reportText, 'String', tumorReport);
    end
    
    % Hasta verilerini güncelleme
    if ~isempty(detectedTumors)
        % Hasta verilerini güncelleme
        updateHastaVerileri(getHastaIsmi(), '', tumorReport);
    end
end
