%% --- 1. AYARLAR VE BAĞLANTI ---
clear; clc; close all;

% 1. ADIM: Portunu Kontrol Et!
% Aşağıdaki komut bağlı olan portları gösterir.
disp('Bulunan Portlar:');
disp(serialportlist("available")); 

port = "COM14";  % <<< BURAYI KENDİ PORTUNLA DEĞİŞTİR (Örn: COM3, COM5)
baudRate = 9600;

% Bağlantıyı Kur
try
    if exist('s', 'var')
        delete(s); % Önceki bağlantı açık kaldıysa kapat
    end
    s = serialport(port, baudRate);
    configureTerminator(s, "CR/LF");
    flush(s);
    disp('✅ STM32 Bağlandı! Veriler bekleniyor...');
catch
    error('❌ HATA: Port açılamadı! Arduino IDE serial ekranı açıksa kapat.');
end

%% --- 2. GRAFİK ARAYÜZÜ (DASHBOARD) ---
f = figure('Name', 'Gelişmiş Kalman Filtresi Analizi', 'Color', 'w', ...
           'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.7]);

% -- SOL PANEL: 2D KONUM (HARİTA) --
subplot(2, 2, [1 3]); % Sol tarafı kapla
hAnimRawMap  = animatedline('Color', [1 0 0 0.4], 'Marker', '.', 'LineStyle', 'none'); % Kırmızı (Ham)
hAnimFiltMap = animatedline('Color', 'b', 'LineWidth', 2); % Mavi (Filtreli)
title('2D Konum Takibi (Kuş Bakışı)');
xlabel('Boylam (Longitude)');
ylabel('Enlem (Latitude)');
grid on; axis equal;
legend('Ham GPS (Gürültülü)', 'Kalman Filtreli (Düzgün)', 'Location', 'northwest');

% -- SAĞ ÜST PANEL: ENLEM (ZAMAN SERİSİ) --
subplot(2, 2, 2);
hAnimLatRaw  = animatedline('Color', 'r', 'LineStyle', ':');
hAnimLatFilt = animatedline('Color', 'b', 'LineWidth', 2);
title('Enlem (Latitude) Performansı');
legend('Ham', 'Filtreli');
grid on;

% -- SAĞ ALT PANEL: BOYLAM (ZAMAN SERİSİ) --
subplot(2, 2, 4);
hAnimLonRaw  = animatedline('Color', 'r', 'LineStyle', ':');
hAnimLonFilt = animatedline('Color', 'b', 'LineWidth', 2);
title('Boylam (Longitude) Performansı');
legend('Ham', 'Filtreli');
grid on;

%% --- 3. VERİ OKUMA VE GÜNCELLEME DÖNGÜSÜ ---
pointCount = 0;     % Sayaç
maxPoints = 500;    % Ekranda tutulacak maksimum nokta

disp('Grafik çiziliyor... (Durdurmak için Ctrl+C yapabilirsin)');

while true
    try
        % 1. Veriyi Oku
        dataLine = readline(s);
        
        % 2. Virgülle ayır ve sayıya çevir
        % Beklenen Format: "Lat, Lon, FiltLat, FiltLon"
        vals = str2double(split(dataLine, ','));
        
        % Veri hatalıysa veya eksikse atla
        if length(vals) < 4 || any(isnan(vals))
            continue; 
        end
        
        % Değişkenleri ata
        raw_lat = vals(1);
        raw_lon = vals(2);
        filt_lat = vals(3);
        filt_lon = vals(4);
        
        % (Opsiyonel) GPS henüz veri bulamadıysa (0,0 geliyorsa) çizme
        if raw_lat == 0 || raw_lon == 0
            continue;
        end
        
        % 3. Grafikleri Güncelle (AnimatedLine ile)
        
        % -> Harita Güncelle
        addpoints(hAnimRawMap, raw_lon, raw_lat);
        addpoints(hAnimFiltMap, filt_lon, filt_lat);
        
        % -> Enlem Grafiği Güncelle
        addpoints(hAnimLatRaw, pointCount, raw_lat);
        addpoints(hAnimLatFilt, pointCount, filt_lat);
        
        % -> Boylam Grafiği Güncelle
        addpoints(hAnimLonRaw, pointCount, raw_lon);
        addpoints(hAnimLonFilt, pointCount, filt_lon);
        
        pointCount = pointCount + 1;
        
        % 4. Ekranı Kaydır (Son 500 noktayı göster)
        if pointCount > maxPoints
            % Eksenleri kaydırarak animasyon hissi ver
            xlim(f.Children(1), [pointCount-maxPoints pointCount]); % Sağ alt
            xlim(f.Children(2), [pointCount-maxPoints pointCount]); % Sağ üst
        end
        
        % 5. Çizimi Yenile (Hızlı mod)
        drawnow limitrate;
        
    catch e
        disp('Bir hata oluştu veya durduruldu.');
        disp(e.message);
        break;
    end
end

% Temizlik
clear s;
disp('Bağlantı kapatıldı.');