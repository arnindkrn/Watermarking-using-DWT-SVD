function varargout = main(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code


% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main (see VARARGIN)

% Choose default command line output for main
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%Proses Memilih dan Menampilkan Citra Host Asli
function citrahost_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Host');
host = imread(fullfile(PathName,FileName));
axes(handles.citra1);
imshow(host);
title('Citra Host Original');
handles.host = host;
guidata (hObject, handles)

%Proses Memilih dan Menampilkan Citra Watermark Asli
function citrawatermark_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermark');
wlm = imread(fullfile(PathName,FileName));
handles.wlm = wlm;
guidata (hObject, handles)
msg = wlm(:,:,1); 
[m,n]=size(msg);  
if m~=n 
    error('m~=n error');
end
axes(handles.citra2);
imshow(msg);
title('Citra Watermark');
handles.msg = msg;
guidata (hObject, handles)



%Proses Scramble Watermark Asli dengan Arnold's Transform
function scramblewatermark_Callback(hObject, eventdata, handles)
Wy = handles.msg;
[m,n]=size(Wy);  
if m~=n 
    error('m~=n error');
end

%Kunci 
scramble = 30;
handles.scramble = scramble;
guidata(hObject, handles)

%check arnold
key = handles.scramble;

b = check_arnold(m);
if key>b
     error('Arnold Key Error');
end

if key<b
    error('Arnold Key Error');
end

%Scramble
[ws] = arnold(Wy,m,key);
axes(handles.citra3)
handles.ws = ws;
guidata (hObject, handles)
imshow(ws)
title('Scramble Watermark')

%Proses Penyisipan DWT+SVD
function penyisipandwtsvd_Callback(hObject, eventdata, handles)
CitraHost = handles.host;
CitraWatermark = handles.wlm;
key = handles.scramble;

%Alpha
prompt = {'Nilai Alpha:'};
dlgtitle = 'Masukkan Nilai Alpha';
dims = [1 50];
b = inputdlg(prompt,dlgtitle,dims);
alpha = str2double(b{:});
handles.alpha = alpha;
guidata (hObject,handles)

CitraHost = imresize(CitraHost,[512 512]);
[a , d, c] = size(CitraHost);

%Konversi Citra Host Asli RGB ke dalam YCBCR
%Proses pemisahaan nilai R,G,dan B
R = double(CitraHost(:,:,1));
G = double(CitraHost(:,:,2));
B = double(CitraHost(:,:,3));

%Menghitung nilai Y,Cb, Cr
Y = (0.299*R) + (0.587*G) + (0.114*B) + 0;
Cb = (-0.168736*R) + (-0.331264*G) + (0.5*B) + 0.5;
Cr = (0.5*R) + (-0.418688*G) - (0.081312*B) + 0.5;

%Proses Transformasi
x_max = a/2;
y_max = d/2;

row = zeros(a,d);

dwt = zeros(a,d);

idwt = zeros(a,d);

%Level 1
for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        row(i,j) = (Y(i_start,j) + Y(i_end,j))/2;
        row(i_dif,j) = (Y(i_start,j) - Y(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

%Level 2
for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        row(i,j) = (dwt(i_start,j) + dwt(i_end,j))/2;
        row(i_dif,j) = (dwt(i_start,j) - dwt(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

%Level 3
for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        row(i,j) = (dwt(i_start,j) + dwt(i_end,j))/2;
        row(i_dif,j) = (dwt(i_start,j) - dwt(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

new = round (dwt);

%Prosedur SVD pada citra host LL3
[Uy, Sy, Vy] = svd (new);

%Mengubah watermark menjadi greyscale
Wy = CitraWatermark (:,:,1);

%Uji Kunci
[m,n]=size(Wy);
b = check_arnold(m);
if key>b
     error('Arnold Key Error');
end

if key<b
    error('Arnold Key Error');
end
%Transformasi Arnold pada Citra Watermark
WScramble = arnold(Wy,m,key);

%SVD pada Watermark Logo
[Uwy, Swy, Vwy] = svd(double(WScramble));

%Proses Penyisipan Watermark Enkripsi ke dalam Citra Host
Swmy = Sy + alpha*Swy;

%Inverse SVD
wmy = Uy * Swmy * Vy';

%IDWT
%Level 3
for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LH
        row(i,j_start) = (wmy(i,j) + wmy(i,j_dif));
        %HH
        row(i,j_end) = (wmy(i,j) - wmy(i,j_dif));
        %LL
        row(i,j_start) = (wmy(i,j) + wmy(i,j_dif));
        %HL
        row(i,j_end) = (wmy(i,j) - wmy(i,j_dif));
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        idwt(i_start,j) = (row(i,j) + row(i_dif,j));
        idwt(i_end,j) = (row(i,j) - row(i_dif,j));
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

%Level 2
for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LH
        row(i,j_start) = (idwt(i,j) + idwt(i,j_dif));
        %HH
        row(i,j_end) = (idwt(i,j) - idwt(i,j_dif));
        %LL
        row(i,j_start) = (idwt(i,j) + idwt(i,j_dif));
        %HL
        row(i,j_end) = (idwt(i,j) - idwt(i,j_dif));
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        idwt(i_start,j) = (row(i,j) + row(i_dif,j));
        idwt(i_end,j) = (row(i,j) - row(i_dif,j));
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

%Level 1
for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LH
        row(i,j_start) = (idwt(i,j) + idwt(i,j_dif));
        %HH
        row(i,j_end) = (idwt(i,j) - idwt(i,j_dif));
        %LL
        row(i,j_start) = (idwt(i,j) + idwt(i,j_dif));
        %HL
        row(i,j_end) = (idwt(i,j) - idwt(i,j_dif));
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        idwt(i_start,j) = (row(i,j) + row(i_dif,j));
        idwt(i_end,j) = (row(i,j) - row(i_dif,j));
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

newY = round (idwt);

%Calculate new R,G,B
newR = newY + (1.402*(Cr-0.5));
newG = newY - (0.34414*(Cb-0.5))-(0.71414*(Cr-0.5));
newB = newY + (1.772*(Cb-0.5));

%Fill new Image
watermarked(:,:,1) = double(newR);
watermarked(:,:,2) = double(newG);
watermarked(:,:,3) = double(newB);

cwm = watermarked;
axes(handles.citra4)
cwm = (uint8(cwm));
imshow(cwm)
title ('Citra Watermarked');
handles.cwm = cwm;
guidata (hObject,handles)

%Simpan Citra Watermarked DWT+SVD
[watermarkedname, watermarkedpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked');
   imwrite(cwm,fullfile(watermarkedpath,watermarkedname))

%PSNR
CitraHost = handles.host;
citra_watermarked = handles.cwm;

CitraHost = double(CitraHost);
citra_watermarked = double( citra_watermarked );
[m,n,o] = size(CitraHost);
selisih = CitraHost-citra_watermarked;
MSE = sum(sum(sum(selisih.^2)))/(m*n*o);
PSNR = 10*log10((255)^2/MSE);    
set(handles.psnr,'String',PSNR)

%SSIM
CitraHost = handles.host;
citra_watermarked = handles.cwm;
SSIM = ssim (CitraHost, citra_watermarked);
set(handles.ssim, 'String', SSIM)


%Ekstraksi DWT+SVD
%CitraWatermarked
function cwatermarked_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
cwd = imread(fullfile(PathName,FileName));
cwd = imresize(cwd,[512 512]);
axes(handles.citra1);
imshow(cwd);
title ('Citra Watermarked');
handles.cwd = cwd;
guidata (hObject, handles)


function ekstraksidwtsvd_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Host Asli');
chd = imread(fullfile(PathName,FileName));
handles.chd = chd;
guidata (hObject, handles)

[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermark Asli');
cmd = imread(fullfile(PathName,FileName));
ecw = cmd (:,:,1);
[m,n]=size(ecw);  
if m~=n 
    error('m~=n error');
end
handles.cmd = cmd;
guidata (hObject, handles)
handles.ecw = ecw;
guidata (hObject, handles)

Host = handles.chd;
Watermark = handles.cmd;
Citra_Watermarked = handles.cwd;
key = 30;

%Alpha
prompt = {'Nilai Alpha:'};
dlgtitle = 'Masukkan Nilai Alpha';
dims = [1 50];
b = inputdlg(prompt,dlgtitle,dims);
alpha = str2double(b{:});

%Citra Host
%Konversi Citra Host RGB ke dalam YCBCR
[a, d, c] = size(Host);
%Proses pemisahaan nilai R,G,dan B
R = double(Host(:,:,1));
G = double(Host(:,:,2));
B = double(Host(:,:,3));

%Calculate Y,Cb, Cr values
Y = (0.299*R) + (0.587*G) + (0.114*B) + 0;
Cb = (-0.168736*R) + (-0.331264*G) + (0.5*B) + 0.5;
Cr = (0.5*R) + (-0.418688*G) - (0.081312*B) + 0.5;

%Proses Transformasi
x_max = a/2;
y_max = d/2;


row = zeros(a,d);

dwt = zeros(a,d);

%Level 1
for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        row(i,j) = (Y(i_start,j) + Y(i_end,j))/2;
        row(i_dif,j) = (Y(i_start,j) - Y(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

%Level 2
for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        row(i,j) = (dwt(i_start,j) + dwt(i_end,j))/2;
        row(i_dif,j) = (dwt(i_start,j) - dwt(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

%Level 3
for j = 1:d
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = x_max+1;
    for i=1:x_max
        row(i,j) = (dwt(i_start,j) + dwt(i_end,j))/2;
        row(i_dif,j) = (dwt(i_start,j) - dwt(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:a
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = y_max+1;
    for j = 1:y_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

new = round (dwt);

%SVD pada Hy, Hcb, Hcr
[Uy, Sy, Vy] = svd (new);

%Watermark Logo Grayscale
Wy = Watermark (:,:,1);
[m,n]=size(Wy); 

%check arnold
[m,n]=size(Wy);
b = check_arnold(m);
if key>b
    err_dlg = errordlg('Arnold Key Error');
     waitfor(err_dlg);
end

if key<b
    err_dlg = errordlg('Arnold Key Error');
    waitfor(err_dlg);
end

%Transformasi Arnold pada Citra Watermark
WScramble = arnold(Wy,m,key);

%SVD pada Watermark Logo
[Uwy, Swy, Vwy] = svd(double(WScramble));

%Proses Ekstraksi
[o, p, q] = size(Citra_Watermarked);
%Proses pemisahaan nilai R,G,dan B
R = double(Citra_Watermarked(:,:,1));
G = double(Citra_Watermarked(:,:,2));
B = double(Citra_Watermarked(:,:,3));

%Calculate Y,Cb, Cr values
Y_wm = (0.299*R) + (0.587*G) + (0.114*B) + 0;
Cb_wm = (-0.168736*R) + (-0.331264*G) + (0.5*B) + 0.5;
Cr_wm = (0.5*R) + (-0.418688*G) - (0.081312*B) + 0.5;


%Proses Transformasi
o_max = o/2;
p_max = p/2;

row = zeros(o,p);

dwt = zeros(o,p);

%Level 1
for j = 1:p
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = o_max+1;
    for i=1:o_max
        row(i,j) = (Y_wm(i_start,j) + Y_wm(i_end,j))/2;
        row(i_dif,j) = (Y_wm(i_start,j) - Y_wm(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:o
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = p_max+1;
    for j = 1:p_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

%Level 2
for j = 1:p
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = o_max+1;
    for i=1:o_max
        row(i,j) = (dwt(i_start,j) + dwt(i_end,j))/2;
        row(i_dif,j) = (dwt(i_start,j) - dwt(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:o
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = p_max+1;
    for j = 1:p_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

%Level 3
for j = 1:p
    n = 1;
    i_start = n;
    i_end = n + 1;
    i_dif = o_max+1;
    for i=1:o_max
        row(i,j) = (dwt(i_start,j) + dwt(i_end,j))/2;
        row(i_dif,j) = (dwt(i_start,j) - dwt(i_end,j))/2;
        
        i_start = i_start +2;
        i_end = i_end +2;
        i_dif = i_dif +1;
    end
end

for i = 1:o
    n = 1;
    j_start = n;
    j_end = n + 1;
    j_dif = p_max+1;
    for j = 1:p_max
        %LL
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HL
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        %LH
        dwt(i,j) = (row(i,j_start) + row(i,j_end))/2;
        %HH
        dwt(i,j_dif) = (row(i,j_start) - row(i,j_end))/2;
        
        j_start = j_start + 2;
        j_end = j_end + 2;
        j_dif = j_dif + 1;
    end
end

new_wd = round (dwt);

[Uy_wm,Sy_wm,Vy_wm] = svd(new_wd);

Swme = (Sy_wm - Sy)/alpha;
WMy = Uwy*Swme*Vwy';
    
axes(handles.citra2) 
imshow(uint8(WMy)); 
title('Extracted Watermark Terenkripsi');

%Inverse Arnold untuk Dekripsi Citra Watermark hasil Ekstraksi
%Kunci Rahasia
prompt = {'Kunci Rahasia:'};
dlgtitle = 'Masukkan Kunci';
dims = [1 50];
n = inputdlg(prompt,dlgtitle,dims);
key = str2double(n{:});

%Uji Kunci
[m,n]=size(Wy);
b = check_arnold(m);
if key>b
    err_dlg = errordlg('Kunci Salah');
     waitfor(err_dlg);
end

if key<b
    err_dlg = errordlg('Kunci Salah');
    waitfor(err_dlg);
end

if key == b
%Inverse Arnold Transform
WMd=iarnold(WMy,m,key);
axes(handles.citra3)
imshow(uint8(WMd)); 
handles.WMd = WMd;
guidata(hObject,handles)
title('Extracted Watermark Terdekripsi');
%Simpan Citra Watermark Hasil Ekstraksi DWT+SVD
[recimgname, recimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermark Hasil Ekstraksi');
   imwrite((uint8(WMd)),fullfile(recimgpath,recimgname))

%NC
watermark = handles.ecw;
ewatermark = handles.WMd;
wm = double(ecw);
wm_ekstrak = double (ewatermark);
n = length (wm);
X = 0;
Y = 0;
Z = 0;
    for i = 1:n
        for j = 1:n
            X = X + wm(i,j)* wm_ekstrak(i,j);
            Y = Y + wm(i,j)* wm(i,j);
            Z = Z + wm_ekstrak(i,j)* wm_ekstrak(i,j);
        end
    end
 Y = sqrt(Y);
 Z = sqrt(Z);
 NC = X/(Y*Z);
set(handles.nc, 'String', NC)
end

%Reset Program.
function reset_Callback(hObject, eventdata, handles)
axes(handles.citra1);cla reset 
axes(handles.citra2);cla reset
axes(handles.citra3);cla reset
axes(handles.citra4);cla reset
axes(handles.citra1);cla reset
axes(handles.citra2);cla reset
axes(handles.citra3);cla reset
set(handles.psnr, 'String','')
set(handles.ssim, 'String','')
set(handles.nc, 'String','')


%Nilai SSIM.
function psnr_Callback(hObject, eventdata, handles)
function psnr_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%Nilai SSIM.
function ssim_Callback(hObject, eventdata, handles)
function ssim_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%Nilai NC
function nc_Callback(hObject, eventdata, handles)
function nc_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%Gaussian Noise Attack.
function gaussianattack_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmda = imread(fullfile(PathName,FileName));
handles.wmda = wmda;
guidata (hObject, handles)
watermarked = handles.wmda;
A = imnoise (watermarked, 'gaussian', 0.001);
[gaimgname, gaimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Gaussian Attack');
   imwrite(A,fullfile(gaimgpath,gaimgname))
axes(handles.citra1);
imshow (A);
title('Citra Watermarked Gaussian');


%Salt & Pepper Attack.
function saltnpepper_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmdb = imread(fullfile(PathName,FileName));
handles.wmdb = wmdb;
guidata (hObject, handles)
watermarked = handles.wmdb;
B = imnoise (watermarked, 'salt & pepper', 0.001);
[spimgname, spimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Salt&Pepper Attack');
   imwrite(B,fullfile(spimgpath,spimgname))
axes(handles.citra1);
imshow (B);
title('Citra Watermarked Salt & Pepper');


%Sharpen Attack.
function sharpen_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmdc = imread(fullfile(PathName,FileName));
handles.wmdc = wmdc;
guidata (hObject, handles)
watermarked = handles.wmdc;
C = imsharpen(watermarked);
[simgname, simgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Sharpen Attack');
   imwrite(C,fullfile(simgpath,simgname))
axes(handles.citra1);
imshow (uint8(C));
title('Citra Watermarked Sharpen');


%Cropping Attack.
function cropping_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmdd = imread(fullfile(PathName,FileName));
handles.wmdd = wmdd;
guidata (hObject, handles)
watermarked = handles.wmdd;
cropImage = imcrop(watermarked, [250 150 150 250]);
[cimgname, cimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Cropping Attack');
   imwrite(cropImage,fullfile(cimgpath,cimgname))
axes(handles.citra1);
imshow (cropImage);
title('Citra Watermarked Cropped');


%Rotate Attack.
function rotate_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmde = imread(fullfile(PathName,FileName));
handles.wmde = wmde;
guidata (hObject, handles)
watermarked = handles.wmde;
E = imrotate (watermarked,90,'bilinear','crop');
[rimgname, rimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Rotate Attack');
   imwrite(E,fullfile(rimgpath,rimgname))
axes(handles.citra1);
imshow (E);
title('Citra Watermarked Rotated');

%Motion Blur Attack.
function motionblur_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmdf = imread(fullfile(PathName,FileName));
handles.wmdf = wmdf;
guidata (hObject, handles)
watermarked = handles.wmdf;
a = fspecial('motion',10,10);
F = imfilter(watermarked,a,'replicate');
[mbimgname, mbimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Motion Blur Attack');
   imwrite(F,fullfile(mbimgpath,mbimgname))
axes(handles.citra1);
imshow (F);
title('Citra Watermarked Motion Blur Attack');


%Speckle Noise Attack.
function speckle_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmdg = imread(fullfile(PathName,FileName));
handles.wmdg = wmdg;
guidata (hObject, handles)
watermarked = handles.wmdg;
G = imnoise (watermarked, 'speckle',0.001);
[snimgname, snimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Speckle Noise Attack');
   imwrite(G,fullfile(snimgpath,snimgname))
axes(handles.citra1);
imshow (G);
title('Citra Watermarked Speckle Noise Attack');


%Executes on button press in rescale.
function rescale_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile({'*.jpg'},'Pilih Citra Watermarked');
wmdh = imread(fullfile(PathName,FileName));
handles.wmdh = wmdh;
guidata (hObject, handles)
watermarked = handles.wmdh;
H = imresize (watermarked,0.30);
[rsimgname, rsimgpath] = uiputfile({'*.jpg'}, 'Simpan Watermarked Rescale Attack');
   imwrite(H,fullfile(rsimgpath,rsimgname))
axes(handles.citra1);
imshow (H);
title('Citra Watermarked Rescale Attack');
