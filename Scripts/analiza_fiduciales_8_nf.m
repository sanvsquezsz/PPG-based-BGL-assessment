% NUEVO 24/05/26 - Creado por Erick J. Argüello-Prada, PhD
% Análisis de parámetros derivados de las derivadas de la señal PPG. Se
% emplean puntos fiduciales. Segmentación, filtrado y extracción.
% Escribe los datos en un archivo de Excel.
% Este código presenta varias modificaciones con respecto a la versión
% anterior "analiza_fiduciales_7_nf.m"

function analiza_fiduciales_8_nf(X,num_sujeto,derivada,fs)
% Extrae las características de cada señal tomando segmentos de la misma:
% X = Segmento de señal.
% num_sujeto = # de registro correspondiente a cada sujeto.
% region_anatomica = ...
% fs = Frecuencia de muestreo.

% nombre_archivo = 'Registros_PPG_NivelesColesterol_3.xlsx';
nombre_archivo = 'Registros_Glucosa_NEW.xlsx';
tot_replicas = 6;
% Consideramos las 4 primeras funciones de modo intrínsecas (IMFs)
orden = 4;
% ...y luego se calculan los parámetros para el primer segmento usando una
% ventana de tamaño predeterminado (w).


% Diferencia #3: Se toma un tamaño de ventana ÚNICO para todas las
% características en lugar de usar dos o más tamaños de ventana.
% Haciendo una equivalencia entre la duración del segmento (120 seg) y una
% ventana de 30 segundos con un solapamiento de ~12 segundos (avance de 18
% segundos), se obtendría algo como esto:
w = floor(length(X)/4);
step = floor(length(X)/7);

% Con esta partición se logran 30 réplicas por señal (ventana = 8 seg)
% w = floor(length(X)/15);
% step = floor(length(X)/31);
% NUEVO! 25/10/25. Para obtener 20 réplicas con ese mismo ancho de ventana
% w = floor(length(X)/15);        % Ventana = 8 segundos
% step = floor(length(X)/21);     % Avance  = 5.8 segundos/solap ~2.2 s


% Ahora comienza lo bueno:
% Análisis con ventana de 30 segundos
j = 1;
for i = 1:step:length(X) - w + 1
    % Se guarda el segmento de señal en una variable aparte...
    f1 = X(i:i + w - 1);
    
    % #############################
    % Características no fiduciales
    % #############################
    % Transformada de Fourier
    FFTx = caculafft(f1,fs);
    media_FFTx(j) = mean(FFTx);
    std_FFTx(j) = std(FFTx);
    skew_FFTx(j) = skewness(FFTx);
    kurt_FFTx(j) = kurtosis(FFTx);
    
    
    % Descomposición empírica de modos (EMD)
    IMF(j,:,:) = emd_n(f1,orden);
    
    % Para calcular métricas de cada IMF se tiene en cuenta la
    % vectorización (e.g., si quiero la varianza de la IMF de orden "n" se
    % hace: valor(j) = var(IMF,n,:);
    
    % Transfomación de 3D a 2D
    IMF1(j,:) = IMF(j,1,:);
    IMF2(j,:) = IMF(j,2,:);
    IMF3(j,:) = IMF(j,3,:);
    IMF4(j,:) = IMF(j,4,:);
%     IMF5(j,:) = IMF(j,5,:);
%     IMF6(j,:) = IMF(j,6,:);


    % Es necesario crear una función aparte que calcule las métricas para
    % cada IMF (media, std, skew, kurt, ZCR, entropía, frecuencia media y 
    [media_IMF1(j), desv_est_IMF1(j), kurt_IMF1(j), skew_IMF1(j), crest_IMF1(j), mean_freq_IMF1(j)] = calcula_param_IMF(IMF1(j,:),fs);
    [media_IMF2(j), desv_est_IMF2(j), kurt_IMF2(j), skew_IMF2(j), crest_IMF2(j), mean_freq_IMF2(j)] = calcula_param_IMF(IMF2(j,:),fs);
    [media_IMF3(j), desv_est_IMF3(j), kurt_IMF3(j), skew_IMF3(j), crest_IMF3(j), mean_freq_IMF3(j)] = calcula_param_IMF(IMF3(j,:),fs);
    [media_IMF4(j), desv_est_IMF4(j), kurt_IMF4(j), skew_IMF4(j), crest_IMF4(j), mean_freq_IMF4(j)] = calcula_param_IMF(IMF4(j,:),fs);
%     [media_IMF5(j), desv_est_IMF5(j), kurt_IMF5(j), skew_IMF5(j), crest_IMF5(j), mean_freq_IMF5(j)] = calcula_param_IMF(IMF5(j,:),fs);
%     [media_IMF6(j), desv_est_IMF6(j), kurt_IMF6(j), skew_IMF6(j), crest_IMF6(j), mean_freq_IMF6(j)] = calcula_param_IMF(IMF6(j,:),fs);
    
    
    % Estadísticas (aunque muy sensibles al ruido)
    media(j) = mean(f1);
    desv_est(j) = std(f1);
    rms_value(j) = rms(f1);
    skew(j) = skewness(f1);
    kurt(j) = kurtosis(f1);    
    zero_cross(j) = ZCR(f1);
    entropia(j) = entropy(f1);
    
    % Nuevo! operador Kaiser-Teager (ex = Teager operator; ey = energy operator)
    [ex,~] = energyop(f1);
    % Operador Teager
    media_KTE(j) = mean(ex);
    std_KTE(j) = std(ex);
    skew_KTE(j) = skewness(ex);
    kurt_KTE(j) = kurtosis(ex);
    
    % Coeficientes autorregresivos de Burg (orden 2 y 4)
    ar_coeffs(j,:) = arburg(f1, 4);
    ar_coeff_2(j) = ar_coeffs(j,3);
    ar_coeff_4(j) = ar_coeffs(j,5);

    % BONUS track. Otras que solo pueden ser ejecutadas en versiones más
    % modernas que esta que tengo yo.
    lyapExp(j) = lyapunovExponent(f1, fs);  % Exponente de Lyapunov
    
    
    % Más características... (NUEVAS 10/08/2026)
    % 2. Obtener el Espectrograma de la señal
    window = round(0.5 * fs); % Ventana de 0.5 segundos
    noverlap = round(0.4 * fs); % Traslape del 80%
    nfft = 512;
    [S, F, T] = spectrogram(f1, window, noverlap, nfft, fs);
    potencia_spec = abs(S).^2;

    % Característica 2: Entropía del espectrograma (mide irregularidad espectral)
    % Normalizar la matriz de potencia como una distribución de probabilidad
    P_norm = potencia_spec ./ sum(potencia_spec, 'all');
    entropia_tf(j) = -sum(P_norm .* log2(P_norm + eps), 'all');

    sig_normalizada = normalize(f1); % Convierte a Z-score (valores entre -3 y 3)
    % 1. Calcular el retraso de tiempo óptimo (\tau) usando la primera autocorrelación cero
    [autocorr, lags] = xcorr(sig_normalizada, 'coeff');
    % Encontrar el primer cruce por cero o el primer mínimo
    % --- 2. Cálculo Automático del Retraso Óptimo (Tau) ---
    % Usamos la autocorrelación para encontrar cuándo la señal se desfasa idealmente
    r_mitad = autocorr(lags >= 0); % Nos quedamos con la mitad positiva
    lags_mitad = lags(lags >= 0);
    % Encontrar el primer cruce por cero
    idx_cero = find(r_mitad <= 0, 1, 'first');

    if isempty(idx_cero)
        tau = 15; % Valor por defecto si no cruza (típico para fs=100Hz)
    else
        tau = lags_mitad(idx_cero);
    end

    % --- 3. Reconstrucción con el Tau Corregido ---
    X_t = sig_normalizada(1:end-tau);
    X_tau = sig_normalizada(tau+1:end);

    % --- NUEVAS CARACTERÍSTICAS GEOMÉTRICAS ---

    % A. Área y Perímetro usando la Envolvente Convexa (Convex Hull)
    [k, area_ventana] = convhull(X_t, X_tau);
    features_area_psr = area_ventana;

    % El perímetro se calcula sumando la distancia euclidiana entre los vértices de la envolvente
    vertices_x = X_t(k);
    vertices_y = X_tau(k);
    perimetro_ventana = sum(sqrt(diff(vertices_x).^2 + diff(vertices_y).^2));
    features_perimetro_psr = perimetro_ventana;

    % B. Densidad de Puntos respecto al Centroide
    % Encontrar el centro geométrico de la trayectoria
    centro_x = mean(X_t);
    centro_y = mean(X_tau);

    % Calcular la distancia de cada punto de la trayectoria hacia el centroide
    distancias_al_centro = sqrt((X_t - centro_x).^2 + (X_tau - centro_y).^2);

    % La densidad se define inversamente proporcional a la distancia promedio:
    % Si los puntos están muy concentrados (arteria rígida), el radio promedio disminuye y la densidad sube.
    % Si los puntos están dispersos (HRV alta), el radio promedio aumenta y la densidad baja.
    features_densidad_cent = 1 / mean(distancias_al_centro);

    % Graficar de nuevo
    figure;
    plot(X_t, X_tau, 'b', 'LineWidth', 1);
    grid on; axis square;
    xlabel('PPG(t)'); ylabel(['PPG(t + ' num2str(tau) ')']);
    title('Espacio de Fases 2D Corregido');

    % --- Extracción de Características Finales del Paciente ---
    % Promediamos las ventanas para obtener los descriptores robustos del registro
    area_final(j)      = mean(features_area_psr);
    perimetro_final(j) = mean(features_perimetro_psr);
    densidad_final(j)  = mean(features_densidad_cent);

    % Mostrar resultados en consola
    % fprintf('--- Características Extraídas (fs = %d Hz) ---\n', fs);
    % fprintf('Entropía del Espectrograma: %.4f\n', entropia_tf(j))
    % fprintf('Área Promedio del Atractor: %.4f\n', area_final(j));
    % fprintf('Perímetro Promedio de la Envolvente: %.4f\n', perimetro_final(j));
    % fprintf('Densidad de Puntos del Centroide: %.4f\n', densidad_final(j));



    % ########################################################
    % Características fiduciales (solo para la señal original)
    % ########################################################
    % if derivada == 0
        [a, b, c, d, e, f, g, h, k, l] = Alpinista_simple_4_todos(f1,fs);

        % Se promedia cada característica dentro de la ventana
        media_a(j) = mean(a);
        media_b(j) = mean(b);
        media_c(j) = mean(c);
        media_d(j) = mean(d);
        media_e(j) = mean(e);
        media_f(j) = mean(f);
        media_g(j) = mean(g);
        media_h(j) = mean(h);
        media_k(j) = mean(k);
        media_l(j) = mean(l);

        % Se añaden otras cantidades para no tener que calcularlas en el Excel
        media_m(j) = media_c(j)/ media_a(j);    % Tiempo de cresta normalizado
        media_n(j) = media_d(j)/ media_a(j);    % Tiempo de descenso normalizado
        media_o(j) = media_f(j)/ media_c(j);    % Pendiente ascendente
        media_p(j) = media_f(j)/ media_d(j);    % Pendiente descendente

        % Y para finalizar, las que se derivan de la variabilidad de frecuencia
        % pulsátil (PRV) - parámetro "a" extraído del Alpinista.
        % 1. Convertir los intervalos entre picos 'a' (muestras) a milisegundos
        % (ms). Se considera la frecuencia de muestreo
        RR = (a / fs) * 1000;

        % Diferencias sucesivas entre intervalos adyacentes
        dif_RR = diff(RR);

        % --- MÉTRICAS EN EL DOMINIO DEL TIEMPO ---

        % SDNN: Desviación estándar de todos los intervalos RR
        SDNN_val(j) = std(RR);

        % RMSSD: Raíz cuadrada de la media de las diferencias sucesivas al cuadrado
        RMSSD_val(j) = sqrt(mean(dif_RR.^2));

        % SDSD: Desviación estándar de las diferencias sucesivas
        SDSD_val(j) = std(dif_RR);
    % end
    
    
    % --- MÉTRICAS EN EL DOMINIO DE LA FRECUENCIA ---
    % Nota: Al ser una ventana corta de 30 segundos, los intervalos no son
    % equidistantes, por lo que hay que interpolar la serie RR original
    % para un análisis espectral continuo. Se interpola, como suele
    % reportarse en la literatura a 4 Hz
    % fs_interp = 4;
    % tiempo_acumulado = cumsum(RR) / 1000; % Tiempo en segundos
    % % Asegurar que el tiempo empiece en 0
    % tiempo_acumulado = tiempo_acumulado - tiempo_acumulado(1);
    % 
    % tiempo_uniforme = 0:(1/fs_interp):tiempo_acumulado(end);
    % RR_interpolado = interp1(tiempo_acumulado, RR, tiempo_uniforme, 'spline');
    % 
    % % Eliminar la tendencia lineal de la serie para no distorsionar las bajas frecuencias
    % RR_detrend = detrend(RR_interpolado);
    % 
    % % Calcular el periodograma (Espectro de potencia)
    % [potencia, frecuencias] = periodogram(RR_detrend, [], [], fs_interp);
    % 
    % % Definición de bandas estándar para PRV/HRV (en Hz)
    % % LF (Low Frequency): 0.04 - 0.15 Hz -> Refleja actividad simpática y parasimpática
    % % HF (High Frequency): 0.15 - 0.40 Hz -> Refleja actividad parasimpática (respiración)
    % 
    % rango_LF = (frecuencias >= 0.04 & frecuencias <= 0.15);
    % rango_HF = (frecuencias > 0.15 & frecuencias <= 0.40);
    % 
    % % Integrar el área bajo la curva para obtener la potencia absoluta en ms²
    % LF_val(j) = trapz(frecuencias(rango_LF), potencia(rango_LF));
    % HF_val(j) = trapz(frecuencias(rango_HF), potencia(rango_HF));
    % 
    % % Relación LF/HF (Balance autonómico)
    % LF_HF_ratio(j) = LF_val(j) / HF_val(j);
    
    
    j = j + 1;
end


% Finalmente, se escriben los resultados en un Excel previamente creado
% para ello. Los vectores deben trasponerse para que se escriban como
% columnas.
media_FFTx = media_FFTx';
std_FFTx = std_FFTx';
skew_FFTx = skew_FFTx';
kurt_FFTx = kurt_FFTx';

% Espacio reservado para Descomposición empírica de modos (EMD)
media_IMF1 = media_IMF1';
desv_est_IMF1 = desv_est_IMF1';
kurt_IMF1 = kurt_IMF1';
skew_IMF1 = skew_IMF1';
crest_IMF1 = crest_IMF1';
mean_freq_IMF1 = mean_freq_IMF1';

media_IMF2 = media_IMF2';
desv_est_IMF2 = desv_est_IMF2';
kurt_IMF2 = kurt_IMF2';
skew_IMF2 = skew_IMF2';
crest_IMF2 = crest_IMF2';
mean_freq_IMF2 = mean_freq_IMF2';

media_IMF3 = media_IMF3';
desv_est_IMF3 = desv_est_IMF3';
kurt_IMF3 = kurt_IMF3';
skew_IMF3 = skew_IMF3';
crest_IMF3 = crest_IMF3';
mean_freq_IMF3 = mean_freq_IMF3';

media_IMF4 = media_IMF4';
desv_est_IMF4 = desv_est_IMF4';
kurt_IMF4 = kurt_IMF4';
skew_IMF4 = skew_IMF4';
crest_IMF4 = crest_IMF4';
mean_freq_IMF4 = mean_freq_IMF4';

% media_IMF5 = media_IMF5';
% desv_est_IMF5 = desv_est_IMF5';
% kurt_IMF5 = kurt_IMF5';
% skew_IMF5 = skew_IMF5';
% crest_IMF5 = crest_IMF5';
% mean_freq_IMF5 = mean_freq_IMF5';
% 
% media_IMF6 = media_IMF6';
% desv_est_IMF6 = desv_est_IMF6';
% kurt_IMF6 = kurt_IMF6';
% skew_IMF6 = skew_IMF6';
% crest_IMF6 = crest_IMF6';
% mean_freq_IMF6 = mean_freq_IMF6';


media = media';
desv_est = desv_est';
rms_value = rms_value';
skew = skew';
kurt = kurt';
zero_cross = zero_cross';
entropia = entropia';

media_KTE = media_KTE';
std_KTE = std_KTE';
skew_KTE = skew_KTE';
kurt_KTE = kurt_KTE';

ar_coeff_2 = ar_coeff_2';
ar_coeff_4 = ar_coeff_4';

lyapExp = lyapExp';

% NUEVAS 10/08/2026
entropia_tf = entropia_tf';
area_final = area_final';
perimetro_final = perimetro_final';
densidad_final = densidad_final';



% if derivada == 0
    media_a = media_a';
    media_b = media_b';
    media_c = media_c';
    media_d = media_d';
    media_e = media_e';
    media_f = media_f';
    media_g = media_g';
    media_h = media_h';
    media_k = media_k';
    media_l = media_l';
    % NUEVAS (ver arriba)
    media_m = media_m';
    media_n = media_n';
    media_o = media_o';
    media_p = media_p';

    SDNN_val = SDNN_val';
    RMSSD_val = RMSSD_val';
    SDSD_val = SDSD_val';
    % LF_val = LF_val';
    % HF_val = HF_val';
    % LF_HF_ratio = LF_HF_ratio';
% end


% Se establece la fila para comenzar a escribir según el número de registro
num_fila = (num_sujeto - 1)*tot_replicas + 2;   %Fila 1 del Excel para etiquetas

% Finalmente, se escriben los resultados en un Excel previamente creado
% para contener los datos, ahora en TRES hojas diferentes!
switch derivada
    case 0
        mi_hoja = 'PPG';
        xlswrite(nombre_archivo,media_FFTx,mi_hoja,['A',num2str(num_fila)]);
        xlswrite(nombre_archivo,std_FFTx,mi_hoja,['B',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_FFTx,mi_hoja,['C',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_FFTx,mi_hoja,['D',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF1,mi_hoja,['E',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF1,mi_hoja,['F',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF1,mi_hoja,['G',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF1,mi_hoja,['H',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF1,mi_hoja,['I',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF1,mi_hoja,['J',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF2,mi_hoja,['K',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF2,mi_hoja,['L',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF2,mi_hoja,['M',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF2,mi_hoja,['N',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF2,mi_hoja,['O',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF2,mi_hoja,['P',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF3,mi_hoja,['Q',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF3,mi_hoja,['R',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF3,mi_hoja,['S',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF3,mi_hoja,['T',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF3,mi_hoja,['U',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF3,mi_hoja,['V',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF4,mi_hoja,['W',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF4,mi_hoja,['X',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF4,mi_hoja,['Y',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF4,mi_hoja,['Z',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF4,mi_hoja,['AA',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF4,mi_hoja,['AB',num2str(num_fila)]);

        xlswrite(nombre_archivo,media,mi_hoja,['AC',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est,mi_hoja,['AD',num2str(num_fila)]);
        xlswrite(nombre_archivo,rms_value,mi_hoja,['AE',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew,mi_hoja,['AF',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt,mi_hoja,['AG',num2str(num_fila)]);
        xlswrite(nombre_archivo,zero_cross,mi_hoja,['AH',num2str(num_fila)]);
        xlswrite(nombre_archivo,entropia,mi_hoja,['AI',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_KTE,mi_hoja,['AJ',num2str(num_fila)]);
        xlswrite(nombre_archivo,std_KTE,mi_hoja,['AK',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_KTE,mi_hoja,['AL',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_KTE,mi_hoja,['AM',num2str(num_fila)]);

        xlswrite(nombre_archivo,ar_coeff_2,mi_hoja,['AN',num2str(num_fila)]);
        xlswrite(nombre_archivo,ar_coeff_4,mi_hoja,['AO',num2str(num_fila)]);

        xlswrite(nombre_archivo,lyapExp,mi_hoja,['AP',num2str(num_fila)]);

        % NUEVAS Características (10/08/2026)
        xlswrite(nombre_archivo,entropia_tf,mi_hoja,['AQ',num2str(num_fila)]);
        xlswrite(nombre_archivo,area_final,mi_hoja,['AR',num2str(num_fila)]);
        xlswrite(nombre_archivo,perimetro_final,mi_hoja,['AS',num2str(num_fila)]);
        xlswrite(nombre_archivo,densidad_final,mi_hoja,['AT',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_a,mi_hoja,['AU',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_b,mi_hoja,['AV',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_c,mi_hoja,['AW',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_d,mi_hoja,['AX',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_e,mi_hoja,['AY',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_f,mi_hoja,['AZ',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_g,mi_hoja,['BA',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_h,mi_hoja,['BB',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_k,mi_hoja,['BC',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_l,mi_hoja,['BD',num2str(num_fila)]);
        % NUEVAS (24/05/26)
        xlswrite(nombre_archivo,media_m,mi_hoja,['BE',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_n,mi_hoja,['BF',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_o,mi_hoja,['BG',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_p,mi_hoja,['BH',num2str(num_fila)]);

        xlswrite(nombre_archivo,SDNN_val,mi_hoja,['BI',num2str(num_fila)]);
        xlswrite(nombre_archivo,RMSSD_val,mi_hoja,['BJ',num2str(num_fila)]);
        xlswrite(nombre_archivo,SDSD_val,mi_hoja,['BK',num2str(num_fila)]);
        % xlswrite(nombre_archivo,LF_val,mi_hoja,['BG',num2str(num_fila)]);
        % xlswrite(nombre_archivo,HF_val,mi_hoja,['BH',num2str(num_fila)]);
        % xlswrite(nombre_archivo,LF_HF_ratio,mi_hoja,['BI',num2str(num_fila)]);
        
    case 1
        mi_hoja = 'VPG';
        xlswrite(nombre_archivo,media_FFTx,mi_hoja,['A',num2str(num_fila)]);
        xlswrite(nombre_archivo,std_FFTx,mi_hoja,['B',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_FFTx,mi_hoja,['C',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_FFTx,mi_hoja,['D',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF1,mi_hoja,['E',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF1,mi_hoja,['F',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF1,mi_hoja,['G',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF1,mi_hoja,['H',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF1,mi_hoja,['I',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF1,mi_hoja,['J',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF2,mi_hoja,['K',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF2,mi_hoja,['L',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF2,mi_hoja,['M',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF2,mi_hoja,['N',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF2,mi_hoja,['O',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF2,mi_hoja,['P',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF3,mi_hoja,['Q',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF3,mi_hoja,['R',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF3,mi_hoja,['S',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF3,mi_hoja,['T',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF3,mi_hoja,['U',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF3,mi_hoja,['V',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF4,mi_hoja,['W',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF4,mi_hoja,['X',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF4,mi_hoja,['Y',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF4,mi_hoja,['Z',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF4,mi_hoja,['AA',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF4,mi_hoja,['AB',num2str(num_fila)]);

        xlswrite(nombre_archivo,media,mi_hoja,['AC',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est,mi_hoja,['AD',num2str(num_fila)]);
        xlswrite(nombre_archivo,rms_value,mi_hoja,['AE',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew,mi_hoja,['AF',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt,mi_hoja,['AG',num2str(num_fila)]);
        xlswrite(nombre_archivo,zero_cross,mi_hoja,['AH',num2str(num_fila)]);
        xlswrite(nombre_archivo,entropia,mi_hoja,['AI',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_KTE,mi_hoja,['AJ',num2str(num_fila)]);
        xlswrite(nombre_archivo,std_KTE,mi_hoja,['AK',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_KTE,mi_hoja,['AL',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_KTE,mi_hoja,['AM',num2str(num_fila)]);

        xlswrite(nombre_archivo,ar_coeff_2,mi_hoja,['AN',num2str(num_fila)]);
        xlswrite(nombre_archivo,ar_coeff_4,mi_hoja,['AO',num2str(num_fila)]);

        xlswrite(nombre_archivo,lyapExp,mi_hoja,['AP',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_a,mi_hoja,['AQ',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_b,mi_hoja,['AR',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_c,mi_hoja,['AS',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_d,mi_hoja,['AT',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_e,mi_hoja,['AU',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_f,mi_hoja,['AV',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_g,mi_hoja,['AW',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_h,mi_hoja,['AX',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_k,mi_hoja,['AY',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_l,mi_hoja,['AZ',num2str(num_fila)]);
        % NUEVAS (24/05/26)
        xlswrite(nombre_archivo,media_m,mi_hoja,['BA',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_n,mi_hoja,['BB',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_o,mi_hoja,['BC',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_p,mi_hoja,['BD',num2str(num_fila)]);

        xlswrite(nombre_archivo,SDNN_val,mi_hoja,['BE',num2str(num_fila)]);
        xlswrite(nombre_archivo,RMSSD_val,mi_hoja,['BF',num2str(num_fila)]);
        xlswrite(nombre_archivo,SDSD_val,mi_hoja,['BG',num2str(num_fila)]);
        
    case 2
        mi_hoja = 'APG';
        xlswrite(nombre_archivo,media_FFTx,mi_hoja,['A',num2str(num_fila)]);
        xlswrite(nombre_archivo,std_FFTx,mi_hoja,['B',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_FFTx,mi_hoja,['C',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_FFTx,mi_hoja,['D',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF1,mi_hoja,['E',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF1,mi_hoja,['F',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF1,mi_hoja,['G',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF1,mi_hoja,['H',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF1,mi_hoja,['I',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF1,mi_hoja,['J',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF2,mi_hoja,['K',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF2,mi_hoja,['L',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF2,mi_hoja,['M',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF2,mi_hoja,['N',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF2,mi_hoja,['O',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF2,mi_hoja,['P',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF3,mi_hoja,['Q',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF3,mi_hoja,['R',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF3,mi_hoja,['S',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF3,mi_hoja,['T',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF3,mi_hoja,['U',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF3,mi_hoja,['V',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_IMF4,mi_hoja,['W',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est_IMF4,mi_hoja,['X',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_IMF4,mi_hoja,['Y',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_IMF4,mi_hoja,['Z',num2str(num_fila)]);
        xlswrite(nombre_archivo,crest_IMF4,mi_hoja,['AA',num2str(num_fila)]);
        xlswrite(nombre_archivo,mean_freq_IMF4,mi_hoja,['AB',num2str(num_fila)]);

        xlswrite(nombre_archivo,media,mi_hoja,['AC',num2str(num_fila)]);
        xlswrite(nombre_archivo,desv_est,mi_hoja,['AD',num2str(num_fila)]);
        xlswrite(nombre_archivo,rms_value,mi_hoja,['AE',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew,mi_hoja,['AF',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt,mi_hoja,['AG',num2str(num_fila)]);
        xlswrite(nombre_archivo,zero_cross,mi_hoja,['AH',num2str(num_fila)]);
        xlswrite(nombre_archivo,entropia,mi_hoja,['AI',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_KTE,mi_hoja,['AJ',num2str(num_fila)]);
        xlswrite(nombre_archivo,std_KTE,mi_hoja,['AK',num2str(num_fila)]);
        xlswrite(nombre_archivo,skew_KTE,mi_hoja,['AL',num2str(num_fila)]);
        xlswrite(nombre_archivo,kurt_KTE,mi_hoja,['AM',num2str(num_fila)]);

        xlswrite(nombre_archivo,ar_coeff_2,mi_hoja,['AN',num2str(num_fila)]);
        xlswrite(nombre_archivo,ar_coeff_4,mi_hoja,['AO',num2str(num_fila)]);

        xlswrite(nombre_archivo,lyapExp,mi_hoja,['AP',num2str(num_fila)]);

        xlswrite(nombre_archivo,media_a,mi_hoja,['AQ',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_b,mi_hoja,['AR',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_c,mi_hoja,['AS',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_d,mi_hoja,['AT',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_e,mi_hoja,['AU',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_f,mi_hoja,['AV',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_g,mi_hoja,['AW',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_h,mi_hoja,['AX',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_k,mi_hoja,['AY',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_l,mi_hoja,['AZ',num2str(num_fila)]);
        % NUEVAS (24/05/26)
        xlswrite(nombre_archivo,media_m,mi_hoja,['BA',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_n,mi_hoja,['BB',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_o,mi_hoja,['BC',num2str(num_fila)]);
        xlswrite(nombre_archivo,media_p,mi_hoja,['BD',num2str(num_fila)]);

        xlswrite(nombre_archivo,SDNN_val,mi_hoja,['BE',num2str(num_fila)]);
        xlswrite(nombre_archivo,RMSSD_val,mi_hoja,['BF',num2str(num_fila)]);
        xlswrite(nombre_archivo,SDSD_val,mi_hoja,['BG',num2str(num_fila)]);
        
end