function tumorDetectionGUI()
    % Figure ve bileşenleri oluşturma
    fig = figure('Position', [200, 200, 600, 400], 'MenuBar', 'none', 'ToolBar', 'none');
    imgAxes = axes('Parent', fig, 'Position', [0.05, 0.2, 0.4, 0.7]);
    resultAxes = axes('Parent', fig, 'Position', [0.55, 0.2, 0.4, 0.7]);
    selectBtn = uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', 'Resim Seç', ...
        'Position', [30, 30, 100, 30], 'Callback', @selectImage);
    detectBtn = uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', 'Tümörleri Tespit Et', ...
        'Position', [150, 30, 150, 30], 'Callback', @detectTumors);
    reportText = uicontrol('Parent', fig, 'Style', 'text', 'String', '', ...
        'Position', [350, 30, 230, 30]);

    % Seçilen resmi depolamak için değişkenler
    selectedImage = [];
    detectedTumors = [];
    tumorReport = '';

    % Hasta verilerini tutmak için değişkenler
    hastaVerileri = struct('Isim', {}, 'Soyisim', {}, 'Tumor', {});

    % Resim seçmek için çağrılan fonksiyon
    function selectImage(~, ~)
        [filename, filepath] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg, *.png, *.bmp)'}, 'Resim Seç');
        if isequal(filename, 0) || isequal(filepath, 0)
            disp('Resim seçilmedi.');
            return;
        end
        image_path = fullfile(filepath, filename);
        selectedImage = imread(image_path);
        imshow(selectedImage, 'Parent', imgAxes);
        
        % Hasta verilerini güncelleme
        [~, name, ~] = fileparts(filename);
        nameParts = split(name, '_');
        isim = nameParts{1};
        soyisim = nameParts{2};
        updateHastaVerileri(isim, soyisim, '');
        
        % Hasta ismi güncelleme
        updateHastaIsmi(isim, soyisim);
    end

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
            tumorReport = sprintf('Tespit edilen tümör sayısı: %d', numel(tumor_label));
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

    % Hasta ismini güncelleyen yardımcı fonksiyon
    function updateHastaIsmi(isim, soyisim)
        set(fig, 'Name', ['Hasta İsmi: ' isim ' ' soyisim]);
    end

    % Hasta ismini döndüren yardımcı fonksiyon
    function [isim, soyisim] = getHastaIsmi()
        name = strrep(get(fig, 'Name'), 'Hasta İsmi: ', '');
        nameParts = split(name, ' ');
        isim = nameParts{1};
        soyisim = nameParts{2};
    end

    % Hasta verilerini güncelleyen yardımcı fonksiyon
    function updateHastaVerileri(isim, soyisim, tumor)
        % Hasta verilerini güncelleme
        found = false;
        for i = 1:numel(hastaVerileri)
            if strcmp(hastaVerileri(i).Isim, isim) && strcmp(hastaVerileri(i).Soyisim, soyisim)
                if isempty(hastaVerileri(i).Tumor)  % Tumor boş ise güncelle
                    hastaVerileri(i).Tumor = tumor;
                end
                found = true;
                break;
            end
        end
        if ~found
            newEntry = struct('Isim', isim, 'Soyisim', soyisim, 'Tumor', tumor);
            hastaVerileri = [hastaVerileri newEntry];
        end
        
        % Excel dosyasını güncelleme
        data = cell(numel(hastaVerileri)+1, 3);
        data{1, 1} = 'isim';
        data{1, 2} = 'Tumor';
        for i = 1:numel(hastaVerileri)
            data{i+1, 1} = [hastaVerileri(i).Isim ' ' hastaVerileri(i).Soyisim];
            if isempty(hastaVerileri(i).Tumor)
                data{i+1, 2} = '-';
            else
                data{i+1, 2} = hastaVerileri(i).Tumor;
            end
        end
        xlswrite('hasta_verileri.xlsx', data, 'Sheet1');
        
        disp('Hasta verileri güncellendi.');
    end
end
