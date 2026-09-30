% Código para extraer las correlaciones entre columnas de datos (Excel).
% Fue creado en 11/04/25 a falta de saber usar "heatmap"
close all
clear
clc

% Datos del archivo de Excel de Danna López
nombre_archivo = 'Registros_Glucosa_NEW.xlsx';
mi_hoja = 'APG';
rango_celdas_lbl = 'A1:BH1';
rango_celdas_tbl = 'A2:BH121';

% Datos del archivo de Excel para estimación de glucosa
% nombre_archivo = 'Registros_PPG_glucosa_todas.xlsx';
% mi_hoja = 'Todos';
% rango_celdas_lbl = 'A1:GZ1';
% rango_celdas_tbl = 'A2:GZ421';


% Primero lee los datos del Excel y los asigna a una matriz
[aux, etiquetas] = xlsread(nombre_archivo,mi_hoja,rango_celdas_lbl);
tabla = xlsread(nombre_archivo,mi_hoja,rango_celdas_tbl);
clc
[num_filas, num_columnas] = size(tabla);
for i = 1:num_columnas
    for j = 1:num_columnas
        if i == j
            r(i,j) = 1;
        else
            r(i,j) = corr(tabla(:,i),tabla(:,j));
        end
    end
end

% Pruebo escribiendo en una archivo de texto
% fileID = fopen('correlaciones.txt','w');
% fprintf(fileID,'%6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g %6.4g \r\n',r);
% fclose(fileID);


% Otra opción (tomada de: https://la.mathworks.com/matlabcentral/answers/1750730-how-to-plot-correlation-coefficient-matrix-plot
h = heatmap(r,'MissingDataColor','w');
labels = etiquetas;
h.XDisplayLabels = labels;
h.YDisplayLabels = labels;
colormapeditor

% % Obtengo la suma de los absolutos de las correlaciones de cada columna
% for i = 1:num_columnas - 1
%     % se resta la correlación con ella misma
%     suma_col(i) = sum(abs(r(:,i))) - 1     
% end

% NUEVO! 03/05/2026 Permite ordenar las características con base en su
% coeficiente de variación (CV) que no es más que la desviación estándar
% dividida entre la media de los datos.
% Primero calculo los CVs de cada característica:
% for i = 1:num_columnas - 1
%     CV(i) = std(tabla(:,i))/mean(tabla(:,i));
% end
% % ...y luego construyo el diagrama de barras
% bar(categorical(labels(1:num_columnas - 1)), CV, 'BarWidth', 1)


% Se ordenan de mayor a menor según su correlación con respecto a la
% variable objetivo
t = r;
labels_aux = labels;
r_ordenado = -1*ones(1,num_columnas-1);
for i = 1:num_columnas - 1
%     r_ordenado(i) = t(1,num_columnas);
%     labels_ordenado(i) = labels_aux(1);
    for j = 1:num_columnas - 1
        if t(j,num_columnas) > r_ordenado(i)
            r_ordenado(i) = t(j,num_columnas);
            labels_ordenado(i) = labels_aux(j);
            k = j;
        end
    end
    % Anulo la fila con el máximo de cada iteración
    t(k,num_columnas) = -1;
end


% Lo siguiente sería depurar la matriz de correlaciones de tal forma que
% mostrase solo aquellas características cuya |r| > Valor ingresado por el
% usuario.
r_min = str2double(input('Elija el mínimo valor de |r|: ','s'));
while isnan(r_min) || r_min < 0 || r_min >= 1
    disp('ENTRADA INVÁLIDA!');
    r_min = str2double(input('Elija el mínimo valor de |r|: ','s'));
end

% Tomado del código "CorrBarGraph" para generar un diagrama de barras de
% las características en función de su correlación con la variable objetivo
% Create sample data.
xValues = categorical(labels_ordenado);
% xValues = reordercats(xValues,labels_ordenado); % Ordena de > a <
yValues = r_ordenado;

% Plot column plot (bar chart).
% NOTA: Si se quiere un diagrama de barras horizontal, basta con cambiar
% "bar" por "barh"
figure,
bar(xValues, yValues, 'BarWidth', 1)
hold on
plot(xlim, [r_min,r_min], 'LineStyle', '--', 'Color', 'red', 'LineWidth', 2);
plot(xlim, [-r_min,-r_min],'LineStyle', '--', 'Color', 'red', 'LineWidth', 2);
hold off

% Primero colecta las columnas que no cumplen con |r_min|...
j = 1;
for i = 1:num_columnas
    if abs(r(num_columnas,i)) > r_min
        new_r(:,j) = r(:,i);
        % Se conservan las etiquetas...
        new_labels(j) = labels(i);
        j = j + 1;
    end
end


% ... y luego, se colectan las filas
j = 1;
for i = 1:num_columnas
    if abs(r(i,num_columnas)) > r_min
        new_r2(j,:) = new_r(i,:);
        j = j + 1;
    end
end


% Se grafica la nueva matriz
figure
h = heatmap(new_r2,'MissingDataColor','w');
title = mi_hoja;
h.XDisplayLabels = new_labels;
h.YDisplayLabels = new_labels;

% NUEVO 20/06/26. Calcula la tasa CV (CVR) para seleccionar
% características. La idea es calcular CVR = CVR_inter /CV_intra y
% verificar que la variabilidad intersujeto sea MAYOR que la intrasujeto.
continuar = 's';
num_sujetos = 20;
replicas = 6;
for i = 1:num_columnas-1
% while continuar == 's'
%     i = input('Ingrese el número de la característica (columna) a examinar: ');
    disp(['Para la característica ',labels(i)]);
    CV_inter(i) = std(tabla(:,i))/abs(mean(tabla(:,i)))
    for j = 1:num_sujetos
        disp(['Para sujeto ',num2str(j)]);
        CV_intra(j) = std(tabla(1+(j-1)*replicas:j*replicas,i))/abs(mean(tabla(1+(j-1)*replicas:j*replicas,i)));      
    end
    promedio_CV_intra = mean(CV_intra)
    disp(['De modo que su CVR es: ',num2str(CV_inter(i)/promedio_CV_intra)]);
    
    % Guarda estos valores en un archivo, porque escribir a mano resulta
    % pesado
    otro_archivo = 'CV_feat_glucosa.xlsx';
    xlswrite(otro_archivo,[CV_inter(i) CV_intra promedio_CV_intra CV_inter(i)/promedio_CV_intra r(i,num_columnas)],'Hoja3',['B',num2str(i+1)]);
    
%     continuar = input('¿Desea continuar el análisis? (s/n)','s');
end