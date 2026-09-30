%=======================================================================
%===== SISTEMA UNIFICADO DE EVALUACIÓN BIOMÉDICA LOSO (20 SUJETOS) =====
%===== Filtrado por Cercanía a la Mediana y Colapso Inter-sujeto   =====
%=======================================================================
close all
clear; clc;

% --- CONFIGURACIÓN DE EXPERIMENTO (MODIFICA AQUÍ) ---
% Opciones de Selector: 'mRMR' | 'ReliefF' | 'F-Test'
METODO_SELECCION = 'F-Test'; 
% Opciones de Modelo: 'Lasso' | 'RandomForest' | 'BoostedTrees' | 'BaggedTrees' | 'SVR'
MODELO_ELEGIDO = 'RandomForest'; 
K_top = 9; % Número de características con mayor importancia a seleccionar por fold
% -----------------------------------------------------

% --- 1. CARGA DE DATOS DESDE EXCEL ---
nombre_archivo = 'Registros_Glucosa_New_2.xlsx'; 
fprintf('Leyendo datos desde %s...\n', nombre_archivo);
datos_raw = readmatrix(nombre_archivo, 'sheet', 'TodosCVR_VIF_RF');

% Esta variable la cree yo para definir el número de columnas de la hoja de
num_columnas = 19;   %Número TOTAL de columnas de la hoja (incluye BGL) 

% Validar dimensiones del archivo cargado (20 sujetos x 6 réplicas = 120 filas)
[filas, columnas] = size(datos_raw);
if filas ~= 120 || columnas ~= num_columnas
 error('El archivo NO tiene las dimensiones adecuadas (debe ser 120 filas x 60 columnas).');
end


X_raw = datos_raw(:, 1:num_columnas - 1);
y_raw = datos_raw(:, num_columnas); % Variable objetivo

% --- 2. GENERACIÓN DE IDs Y FILTRADO POR MEDIANA (1 DATO POR SUJETO) ---
num_sujetos = 20;
replicas_por_sujeto = 6;
replicas_a_seleccionar = 4;

IDs_raw = repelem(1:num_sujetos, replicas_por_sujeto)';

% Inicializar matrices colapsadas (1 fila por sujeto)
X = zeros(num_sujetos, columnas - 1);
y = zeros(num_sujetos, 1);

for s = 1:num_sujetos
    % Extraer los 6 registros del sujeto actual
    idx_sujeto = (IDs_raw == s);
    X_sujeto = X_raw(idx_sujeto, :);
    y_sujeto = y_raw(idx_sujeto);
    
    % 1. Calcular la mediana de la variable objetivo para este sujeto
    mediana_y = median(y_sujeto);
    
    % 2. Calcular la distancia absoluta de cada réplica a la mediana
    distancias = abs(y_sujeto - mediana_y);
    
    % 3. Ordenar distancias y seleccionar las 4 réplicas más cercanas
    [~, idx_ordenado] = sort(distancias, 'ascend');
    idx_seleccionados = idx_ordenado(1:replicas_a_seleccionar);
    
    % 4. Promediar únicamente las 4 réplicas elegidas para consolidar el sujeto
    X(s, :) = mean(X_sujeto(idx_seleccionados, :), 1);
    y(s, :) = mean(y_sujeto(idx_seleccionados), 1);
end

% Nuevos identificadores para el proceso LOSO (ahora son 20 filas en total)
IDs = (1:num_sujetos)';
SujetosUnicos = unique(IDs);
N_sujetos = length(SujetosUnicos);

% Inicializar matrices globales para almacenamiento síncrono
caracteristicas_por_fold = zeros(N_sujetos, K_top);
valores_reales_global = zeros(length(y), 1);
predicciones_global = zeros(length(y), 1);

% Consultar estandarización por consola
estandarizar = input('¿Desea estandarizar los datos? (s/n): ', 's');
while estandarizar ~= 's' && estandarizar ~= 'n'
 disp('ENTRADA INVÁLIDA!');
 estandarizar = input('¿Desea estandarizar los datos? (s/n): ', 's');
end

fprintf('\nEjecutando LOSO con [%s] (Top %d) + [%s]...\n', METODO_SELECCION, K_top, MODELO_ELEGIDO);

% --- 3. BUCLE PRINCIPAL DE VALIDACIÓN CRUZADA LOSO ---
for i = 1:N_sujetos
    sujeto_test = SujetosUnicos(i);
    
    % --- ENTRENAMIENTO: Mantener réplicas individuales (76 filas en total) ---
    % Identificar índices de los 19 sujetos de entrenamiento en la matriz original (sin promediar)
    idx_train_raw = (IDs_raw ~= sujeto_test);
    X_train_raw = X_raw(idx_train_raw, :); 
    y_train = y_raw(idx_train_raw);
    
    % --- PRUEBA: Mantener el sujeto consolidado (1 fila promediada) ---
    testIdx = (IDs == sujeto_test);
    X_test_raw = X(testIdx, :); 
    y_test = y(testIdx);
    
    % Estandarización local estricta por pliegue (Evita fuga de datos)
    switch estandarizar
        case 's'
            media_train = mean(X_train_raw, 1);
            desviacion_train = std(X_train_raw, 0, 1);
            desviacion_train(desviacion_train == 0) = 1; % Prevenir división por cero
            X_train_scaled = (X_train_raw - media_train) ./ desviacion_train;
            X_test_scaled = (X_test_raw - media_train) ./ desviacion_train;
        case 'n'
            X_train_scaled = X_train_raw;
            X_test_scaled = X_test_raw;
    end
    
    % --- SELECCIÓN DE CARACTERÍSTICAS POR RANKING UNIFICADO ---
    switch METODO_SELECCION
        case 'mRMR'
            % Ahora X_train_scaled tiene 76 filas. mRMR ya puede calcular Información Mutua.
            idx_ordenado = fsrmrmr(X_train_scaled, y_train);
            variables_vuelta = idx_ordenado(1:K_top);
        case 'ReliefF'
            [idx_ordenado, ~] = relieff(X_train_scaled, y_train, 10); 
            variables_vuelta = idx_ordenado(1:K_top);
        case 'F-Test'
            [~, p_valores] = fsrftest(X_train_scaled, y_train);
            [~, idx_ordenado] = sort(p_valores, 'ascend');
            variables_vuelta = idx_ordenado(1:K_top);
        otherwise
            error('Método de selección no reconocido.')
    end
    
    % Almacenar las variables elegidas en esta vuelta para el análisis de consenso
    caracteristicas_por_fold(i, :) = variables_vuelta;
    
    % Filtrar matrices finales reteniendo solo el Top K seleccionado
    X_train_final = X_train_scaled(:, variables_vuelta);
    X_test_final = X_test_scaled(:, variables_vuelta);
    
    % --- ENTRENAMIENTO DEL MODELO SELECCIONADO ---
    switch MODELO_ELEGIDO
        case 'Lasso'
            [B, FitInfo] = lasso(X_train_final, y_train, 'CV', 5);
            idxLambda = FitInfo.IndexMinMSE;
            predicciones_sujeto = (X_test_final * B(:, idxLambda)) + FitInfo.Intercept(idxLambda);
        case 'RandomForest'
            modelo = TreeBagger(100, X_train_final, y_train, 'Method', 'regression', ...
                'MinLeafSize', 5, 'OOBPrediction', 'on');
            predicciones_sujeto = predict(modelo, X_test_final);
        case 'BoostedTrees'
            modelo = fitrensemble(X_train_final, y_train, 'Method', 'LSBoost', ...
                'NumLearningCycles', 100, 'LearnRate', 0.1);
            predicciones_sujeto = predict(modelo, X_test_final);
        case 'BaggedTrees'
            modelo = fitrensemble(X_train_final, y_train, 'Method', 'Bag', ...
                'NumLearningCycles', 100);
            predicciones_sujeto = predict(modelo, X_test_final);
        case 'SVR'
            modelo = fitrsvm(X_train_final, y_train, 'KernelFunction', 'gaussian', ...
                'KernelScale', 'auto', 'Standardize', false);
            predicciones_sujeto = predict(modelo, X_test_final);
        otherwise
            error('Modelo elegido no reconocido.');
    end
    
    % Almacenar de forma síncrona en los vectores globales usando la máscara de prueba
    valores_reales_global(testIdx) = y_test;
    predicciones_global(testIdx) = predicciones_sujeto;
end

% --- 4. CÁLCULO DE MÉTRICAS GLOBALES REALES (A NIVEL INTER-SUJETO) ---
y_real_sujetos = valores_reales_global; 
y_pred_sujetos = predicciones_global;   

residuos_sujetos = y_real_sujetos - y_pred_sujetos;
MAE_global = mean(abs(residuos_sujetos));
RMSE_global = sqrt(mean(residuos_sujetos.^2));

% NUEVO (10/07/2026) Cálculo del MAD (no es lo mismo que el MAE)
MAD_global = mean(abs(y_real_sujetos - mean(y_real_sujetos)));

% Uso de eps para blindar la división matemática
MAPE_global = mean(abs(residuos_sujetos ./ (y_real_sujetos + eps))) * 100;
% Cálculo del MARD (NUEVO, el que se usa en clínica)
MARD_global = mean(abs(residuos_sujetos ./ (0.5 * (y_real_sujetos + y_pred_sujetos) + eps))) * 100;

% Cálculo del coeficiente de determinación corregido para escala agrupada
SST = sum((y_real_sujetos - mean(y_real_sujetos)).^2);
SSR = sum(residuos_sujetos.^2);
R2_global = 1 - (SSR / SST);

% --- 5. ANÁLISIS DE CONSENSO DE CARACTERÍSTICAS (UMBRAL DEL 80%) ---
todas_las_selecciones = caracteristicas_por_fold(:);
num_features = size(X, 2); % Dinámico según las columnas reales (59)
conteos_globales = zeros(num_features, 1);
for col = 1:num_features
 conteos_globales(col) = sum(todas_las_selecciones == col);
end

% El 80% de 20 pliegues (sujetos) equivale exactamente a mínimo 16 presencias
umbral_presencia = ceil(0.70 * N_sujetos); 
variables_estables = find(conteos_globales >= umbral_presencia);

% --- 6. IMPRESIÓN DE RESULTADOS FINALES ---
fprintf('\n================ REPORTE DE MÉTRICAS CLÍNICAS REALES ================\n');
fprintf('MAE (Inter-sujeto): %.4f mg/dL\n', MAE_global);
fprintf('RMSE (Inter-sujeto): %.4f mg/dL\n', RMSE_global);
fprintf('MAD (Inter-sujeto): %.4f mg/dL\n', MAD_global);
fprintf('MAPE (Inter-sujeto): %.4f %%\n', MAPE_global);
fprintf('MARD (Inter-sujeto): %.4f %%\n', MARD_global);
fprintf('R-cuadrado (R2): %.4f\n', R2_global);
disp('---------------------------------------------------------------------');
fprintf('Características estables definitivas (>70%% de consenso - Folds): ');
if isempty(variables_estables)
 fprintf('\nNinguna variable superó el umbral estricto del 70%% con el selector %s.\n', METODO_SELECCION);
else
 fprintf('\nVariables estables (columnas de Excel):\n');
 disp(variables_estables');
end
disp('=====================================================================');

% --- 7. EXPORTACIÓN PARA DIAGRAMA DE BLAND-ALTMAN ---
% Exporta los 20 puntos consolidados inter-sujeto
nombre_txt = 'datos_bland_altman.txt';
fid = fopen(nombre_txt, 'w');
if fid ~= -1
 fprintf(fid, 'Real\tPredicho\n');
 for k = 1:length(valores_reales_global)
 fprintf(fid, '%.4f\t%.4f\n', valores_reales_global(k), predicciones_global(k));
 end
 fclose(fid);
 fprintf('¡Datos de Bland-Altman exportados exitosamente a "%s"!\n', nombre_txt);
else
 warning('No se pudo generar el archivo de texto para Bland-Altman.');
end