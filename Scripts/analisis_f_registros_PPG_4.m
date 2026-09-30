 % Código para análisis de las señales PPG adquiridas para el artículo
% "PPG_glucose_body_site", el cual incluirá a Kathalina Osorio y Santiago
% Vásquez de la USC. También será usado por Danna López, pero sin tomar en
% cuenta las características fiduciales.
% Elaborado 25/10/25 - Modificado 17/06/2026
close all
clear
clc

% El usuario ingresa el número del registro
num_registro = str2double(input('Elija el número de registro a analizar: ','s'));
while isnan(num_registro) || num_registro < 0
    disp('ENTRADA INVÁLIDA!');
    num_registro = str2double(input('Elija el número de registro a analizar: ','s'));
end
% Se define la ruta del archivo
num_registro_str = num2str(num_registro);
ruta_archivo = strcat('Sujeto_',num_registro_str,'.mat');

load(ruta_archivo);

% Se llama a la función para evitar repetir el código más de 2 veces
% Para este caso:
% y = señal de la frente
% y1 = señal de la oreja
% y2 = señal del dedo

% Acá se eliminan las primeras "x" muestras a fin de remover el ruido que
% aparece al principio de cada registro (entre 80 y 400 muestras).
x = 200;        % idealmente, x = 100;
y = y(x:end);
y1 = y1(x:end);
y2 = y2(x:end);
t = t(x:end);

% Se grafica para verificar la calidad de la señal
figure,
subplot(3,1,1),plot(t,y),xlim([0 max(t)]),title('Frente'),set(gca,'fontsize',12);     % Permite modificar el tamaño de la fuente para los valores en los ejes
subplot(3,1,2),plot(t,y1),xlim([0 max(t)]),title('Oreja'),set(gca,'fontsize',12);
ylabel('Amplitud (V)');
subplot(3,1,3),plot(t,y2),xlim([0 max(t)]),title('Dedo'),set(gca,'fontsize',12);
set(gcf,'color','w'); % Fondo blanco
xlabel('Tiempo (s)');


% Diferencia #1: La eliminación de línea base, filtrado y estandarización
% de la señal se hace FUERA de la ventana y justo en este orden:
% Eliminación de línea base usando un filtro de mediana (es VITAL, porque
% las señales capturadas por el MX30102 poseen MUCHA desviación en la línea
% base.
tamano_ventana = round(1.5 * fs); 
if mod(tamano_ventana, 2) == 0
    tamano_ventana = tamano_ventana + 1; 
end
linea_base = medfilt1(y, tamano_ventana);
X_sin_deriva = y - linea_base;

linea_base = medfilt1(y1, tamano_ventana);
X_sin_deriva1 = y1 - linea_base;

linea_base = medfilt1(y2, tamano_ventana);
X_sin_deriva2 = y2 - linea_base;


% DIFERENCIA #2
% En lugar de usar Chebyshev, se emplea un filtro Savitsky-Golay, de orden
% 5 y con tamaño de ventana = 15 muestras. Este filtro ya fue usado como
% parte del preprocesamiento del algoritmo que elaboré para detectar PVCs
X_filtrada = sgolayfilt(X_sin_deriva, 5, 15);
X_filtrada1 = sgolayfilt(X_sin_deriva1, 5, 15);
X_filtrada2 = sgolayfilt(X_sin_deriva2, 5, 15);

% DIFERENCIA #3: Interpolar la señal. Dada la frecuencia tan baja de
% muestreo, se decide interpolar la señal a 200 Hz con el fin de mejorar un
% poco la resolución temporal de la ubicación de los máximos y mínimos, lo
% que a su vez podría contribuir al enriquecimiento de información de
% algunas características derivadas del PRV y frecuenciales.
fs_nueva = 200;
X_interp = resample(X_filtrada, fs_nueva, round(fs));
X_interp1 = resample(X_filtrada1, fs_nueva, round(fs));
X_interp2 = resample(X_filtrada2, fs_nueva, round(fs));


% Diferencia #4: En lugar de normalizar, se estandariza la señal aplicando
% la regla del Z-score. Esto se hace porque si en diferentes ventanas la
% amplitud varía, la normalización las limita al rango entre 0 y 1,
% perdiéndose así la información hemodinámica importante a lo largo del
% tiempo.
X_norm = X_interp; %(X_interp - mean(X_interp)) / std(X_interp);


% Se procede a extraer las características de cada una de las señales
% usando el código "analiza_fiduciales_7.m"
% analiza_fiduciales_7(y,num_registro,1,fs);
% analiza_fiduciales_7(y1,num_registro,2,fs);
% analiza_fiduciales_7(y2,num_registro,3,fs);
analiza_fiduciales_8_nf(X_norm,num_registro,0,fs_nueva);
analiza_fiduciales_8_nf(X_interp1,num_registro,1,fs_nueva);
analiza_fiduciales_8_nf(X_interp2,num_registro,2,fs_nueva);

% Mensaje de confirmación de que todo fue un éxito.
disp('Extracción y escritura finalizadas');