% =========================================================================
% SCRIPT DE MATLAB: FILTRADO DE MULTICOLINEALIDAD MEDIANTE VIF RECURSIVO
% =========================================================================

% 1. Carga tus datos desde la hoja "PPG" del archivo Excel
% Cambia 'tu_archivo.xlsx' por el nombre real de tu archivo en tu carpeta
archivoExcel = 'Registros_Glucosa_NEW.xlsx';
opts = detectImportOptions(archivoExcel, 'Sheet', 'PPG');
tablaCompleta = readtable(archivoExcel, opts);

% 2. Lista manual de tus 33 variables supervivientes (aquellas con CVR >= 3.0)
% Agrega o quita nombres según los que hayan pasado tu filtro de estabilidad
variablesEstables = {'stdFFT', 'meanFFT', 'PPGA', 'RMS', 'pPPGATc', 'STD', ...
                     'RMSSD', 'SDSD', 'PPAT', 'pPPGATd', 'SDNN', 'aPPGA', ...
                     'Mean', 'Entrop', 'PWV', 'Tc', 'Td', 'ZCR', 'PPI', 'skewIMF2'};

% Extraer la matriz de características X
X = table2array(tablaCompleta(:, variablesEstables));
nombresX = variablesEstables;

% 3. Algoritmo VIF Recursivo
umbralVIF = 10.0; % Estándar de la industria (puedes usar 5.0 si quieres ser más estricto)
continuarBucle = true;

fprintf('--- INICIANDO ANÁLISIS DE MULTICOLINEALIDAD (VIF) ---\n');

while continuarBucle
    numVariables = size(X, 2);
    valoresVIF = zeros(numVariables, 1);
    
    % Calcular el VIF para cada característica
    for i = 1:numVariables
        y_vif = X(:, i);
        X_vif = X;
        X_vif(:, i) = []; % Eliminar la variable actual para la regresión interna
        
        % Regresión lineal interna para calcular el R-cuadrado
%         [~, ~, ~, ~, stats] = beds(X_vif, y_vif); 
        % Nota: Si tu versión de MATLAB no tiene 'beds', usamos fitlm de forma alternativa:
        mdl = fitlm(X_vif, y_vif);
        rCuadrado = mdl.Rsquared.Ordinary;
        
        % Fórmula del VIF
        valoresVIF(i) = 1 / (1 - rCuadrado);
    end
    
    % Encontrar el VIF máximo
    [maxVIF, idxMax] = max(valoresVIF);
    
    if maxVIF > umbralVIF
        fprintf('Eliminando var: "%s" con VIF de %.2f (Altamente redundante).\n', nombresX{idxMax}, maxVIF);
        % Remover de la matriz y de la lista de nombres
        X(:, idxMax) = [];
        nombresX(idxMax) = [];
    else
        continuarBucle = false;
    end
end

fprintf('\n? ¡Proceso Completado exitosamente!\n');
fprintf('Características finales óptimas seleccionadas para tu regresión:\n');
disp(nombresX');