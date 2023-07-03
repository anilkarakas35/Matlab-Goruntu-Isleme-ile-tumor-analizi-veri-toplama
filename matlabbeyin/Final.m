clc
close all
clear all
[filename, filepath] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg, *.png, *.bmp)'}, 'Select an image file');
if isequal(filename, 0) || isequal(filepath, 0)
    disp('No file selected. Program terminated.');
    return;
end

% Seçilen dosyayı oku
image_path = fullfile(filepath, filename);
s = imread(image_path);
figure;
imshow(s);
title('Alınan Görüntü','FontSize',20);

num_iter = 10;
    delta_t = 1/7;
    kappa = 15;
    option = 2;
    disp('Görüntü işleniyor Lütfen Bekleyiniz . . .');
%Preprocessing image please wait . . .
    inp = anisodiff(s,num_iter,delta_t,kappa,option);
%Removing noise Filtering Completed !!
    inp = uint8(inp);
    
inp=imresize(inp,[256,256]);
if size(inp,3)>1
    inp=rgb2gray(inp);
end
figure;
imshow(inp);
title('Filtrelenmiş Görüntü','FontSize',20);


sout=imresize(inp,[256,256]);
t0=60;
th=t0+((max(inp(:))+min(inp(:)))./2);
for i=1:1:size(inp,1)
    for j=1:1:size(inp,2)
        if inp(i,j)>th
            sout(i,j)=1;
        else
            sout(i,j)=0;
        end
    end
end

label=bwlabel(sout);
stats=regionprops(logical(sout),'Solidity','Area','BoundingBox');
density=[stats.Solidity];
area=[stats.Area];
high_dense_area=density>0.6;
max_area=max(area(high_dense_area));
tumor_label=find(area==max_area);
tumor=ismember(label,tumor_label);
if max_area>100
   figure;
   imshow(tumor)
   title('Tümör Tespit','FontSize',20);


else
    h = msgbox('Tümör Tespit Edilemedi!!','status');
    %disp('no tumor');
    return;
    end
box = stats(tumor_label);
if ~isempty(box)
    wantedBox = box.BoundingBox;
    % Display the bounding box
    figure;
    imshow(inp);
    hold on;
    rectangle('Position', wantedBox, 'EdgeColor', 'r', 'LineWidth', 2);
    title('Kare içine Al', 'FontSize', 20);
else
    disp('Kare İçine Al');
end



hold off;

dilationAmount = 5;
rad = floor(dilationAmount);
[r,c] = size(tumor);
filledImage = imfill(tumor, 'holes');
for i=1:r
   for j=1:c
       x1=i-rad;
       x2=i+rad;
       y1=j-rad;
       y2=j+rad;
       if x1<1
           x1=1;
       end
       if x2>r
           x2=r;
       end
       if y1<1
           y1=1;
       end
       if y2>c
           y2=c;
       end
       erodedImage(i,j) = min(min(filledImage(x1:x2,y1:y2)));
   end
end
figure
imshow(erodedImage);
title('Tümör Belirt','FontSize',20);

tumorOutline=tumor;
tumorOutline(erodedImage)=0;
figure;  
imshow(tumorOutline);
title('Tümörü Çizgi ile Göster','FontSize',20);

rgb = inp(:,:,[1 1 1]);
red = rgb(:,:,1);
red(tumorOutline)=255;
green = rgb(:,:,2);
green(tumorOutline)=0;
blue = rgb(:,:,3);
blue(tumorOutline)=0;
tumorOutlineInserted(:,:,1) = red; 
tumorOutlineInserted(:,:,2) = green; 
tumorOutlineInserted(:,:,3) = blue; 
figure
imshow(tumorOutlineInserted);
title('Tümör Kırmızı Çizgi ile belirt','FontSize',20);

figure
subplot(231);imshow(s);title('Alınan Görüntü','FontSize',20);
subplot(232);imshow(inp);title('Filtrelenmiş Görüntü','FontSize',20);

subplot(233);imshow(tumor);title('Tümör Tespit','FontSize',20);
subplot(234);imshow(tumorOutline);title('Tümörü Çizgi ile Göster','FontSize',20);
subplot(235);imshow(tumorOutlineInserted);title('Tümör Kırmızı Çizgi ile belirt','FontSize',20);
% Tümör raporu oluşturma
report = cell(1, numel(stats));

for i = 1:numel(stats)
    report{i} = sprintf('Tümör %d:\n', i);
    report{i} = [report{i} sprintf('Alan: %d piksel\n', stats(i).Area)];
    report{i} = [report{i} sprintf('Dikdörtgen sınırlayıcı kutu: (%.2f, %.2f, %.2f, %.2f)\n', ...
        stats(i).BoundingBox(1), stats(i).BoundingBox(2), ...
        stats(i).BoundingBox(3), stats(i).BoundingBox(4))];
    report{i} = [report{i} sprintf('Yoğunluk: %.2f\n', stats(i).Solidity)];
    report{i} = [report{i} sprintf('\n')];
end

% Raporu ekrana yazdırma
for i = 1:numel(report)
    disp(report{i});
end