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
    data{1, 1} = 'İsim';
    data{1, 2} = 'Soyisim';
    data{1, 3} = 'Tumor';
    for i = 1:numel(hastaVerileri)
        data{i+1, 1} = hastaVerileri(i).Isim;
        data{i+1, 2} = hastaVerileri(i).Soyisim;
        if isempty(hastaVerileri(i).Tumor)
            data{i+1, 3} = '-';
        else
            data{i+1, 3} = hastaVerileri(i).Tumor;
        end
    end
    
    % Mevcut tabloyu güncelleme
    [~, txtData] = xlsread('hasta_verileri.xlsx');
    [numRows, ~] = size(txtData);
    for i = 1:numRows-1
        if strcmp(txtData{i+1, 1}, isim) && strcmp(txtData{i+1, 2}, soyisim)
            txtData{i+1, 3} = data{i+1, 3};
            break;
        end
    end
    
    xlswrite('hasta_verileri.xlsx', txtData, 'Sheet1');
    
    disp('Hasta verileri güncellendi.');
end
