-- Databricks notebook source
-- MAGIC %md
-- MAGIC # SQL

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bases de datos

-- COMMAND ----------

--Listamos las bases de datos existentes
SHOW DATABASES;

-- COMMAND ----------

--Creamos una base de datos 
CREATE DATABASE IF NOT EXISTS clase03a;

-- COMMAND ----------

DROP DATABASE IF EXISTS clase03b CASCADE

-- COMMAND ----------

CREATE DATABASE IF NOT EXISTS clase03b
COMMENT 'Base de datos - clases PUCP'
--LOCATION '/proyectos/PUCP' -- En Databricks Free Edition ya no se permite acceder a DBFS
WITH DBPROPERTIES ('creator' = 'Juan Tovar', 'date' = '2026-03-31');

-- COMMAND ----------

SHOW DATABASES;

-- COMMAND ----------

SHOW DATABASES LIKE 'clase.*';

-- COMMAND ----------

DESCRIBE DATABASE EXTENDED clase03a;

-- COMMAND ----------

DESCRIBE DATABASE EXTENDED clase03b;

-- COMMAND ----------

--Eliminamos una base de datos
--CASCADE permite eliminar las objetos que estan dentro de la base de datos
DROP DATABASE IF EXISTS clase03a CASCADE;

-- COMMAND ----------

ALTER DATABASE clase03b SET 
DBPROPERTIES ( 'edited-by' = 'Juan DBA');

-- COMMAND ----------

DESCRIBE DATABASE EXTENDED clase03b;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Volumen
-- MAGIC Un Volume actúa como un punto de montaje que mapea una ubicación de almacenamiento a una ruta simple dentro del workspace de Databricks.

-- COMMAND ----------

-- Creamos un volume para los datos
CREATE VOLUME IF NOT EXISTS clase03b.data;

-- COMMAND ----------

-- MAGIC %python
-- MAGIC dbutils.fs.ls("/Volumes/workspace/clase03b/data")

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Tablas

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Cliente

-- COMMAND ----------

DROP TABLE IF EXISTS clase03b.cliente_a;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS clase03b.CLIENTE_A(
ID STRING,
NOMBRE STRING,
TELEFONO STRING,
CORREO STRING,
FECHA_INGRESO STRING,
EDAD INT,
SALARIO DOUBLE,
ID_EMPRESA STRING
)
--LOCATION 'dbfs:/Volumes/workspace/clase03b/data/cliente.data' --En Databricks Free Edition ya no se permite acceder a DBFS
TBLPROPERTIES ('creator'='Juan Tovar', 'created_at'='2026-03-31');

-- COMMAND ----------

COPY INTO clase03b.CLIENTE_A (ID, NOMBRE, TELEFONO, CORREO, FECHA_INGRESO, EDAD, SALARIO, ID_EMPRESA)
FROM (
  SELECT 
    _c0 as ID,
    _c1 as NOMBRE, 
    _c2 as TELEFONO,
    _c3 as CORREO,
    _c4 as FECHA_INGRESO,
    cast(_c5 as INT) as EDAD,
    cast(_c6 as DOUBLE) as SALARIO,
    _c7 as ID_EMPRESA
  FROM '/Volumes/workspace/clase03b/data/cliente.data'
)
FILEFORMAT = CSV
FORMAT_OPTIONS ('delimiter' = '|', 'header' = 'false');

-- COMMAND ----------

SELECT * FROM text.`/Volumes/workspace/clase03b/data/cliente.data` LIMIT 5;

-- COMMAND ----------

-- Consultamos la tabla con datos
SELECT * FROM clase03b.cliente_a LIMIT 10;

-- COMMAND ----------

-- MAGIC %python
-- MAGIC !pwd

-- COMMAND ----------

--La tabla _sqldf almacena el resultado de tu última consulta SQL ejecutada
SELECT * FROM _sqldf WHERE edad>30 ORDER BY edad desc;

-- COMMAND ----------

SHOW TABLES IN clase03b;

-- COMMAND ----------

SELECT COUNT(1) TOTAL_COUNT FROM clase03b.cliente_a LIMIT 10;

-- COMMAND ----------

DESC clase03b.cliente_a;

-- COMMAND ----------

DESC FORMATTED clase03b.cliente_a;

-- COMMAND ----------

--DROP TABLE clase03b.CLIENTE_a;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Empresa

-- COMMAND ----------

CREATE TABLE clase03b.EMPRESA(
ID STRING,
NOMBRE STRING
)
TBLPROPERTIES ('creator'='Juan Tovar', 'created_at'='2026-03-31');

-- COMMAND ----------

COPY INTO clase03b.EMPRESA (ID, NOMBRE)
FROM (
  SELECT 
    _c0 as ID,
    _c1 as NOMBRE
  FROM '/Volumes/workspace/clase03b/data/empresa.data'
)
FILEFORMAT = CSV
FORMAT_OPTIONS ('delimiter' = '|', 'header' = 'false');

-- COMMAND ----------

/*
--También se puede subir con header true
COPY INTO clase03b.EMPRESAA
FROM '/Volumes/workspace/clase03b/data/empresa_.data'
FILEFORMAT = CSV
FORMAT_OPTIONS ('delimiter' = '|', 'header' = 'true');
*/

-- COMMAND ----------

select * from clase03b.empresa;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Consulta

-- COMMAND ----------

SELECT c.NOMBRE, EDAD, e.NOMBRE EMPRESA FROM clase03b.cliente_a c
JOIN clase03b.empresa e ON c.ID_EMPRESA=e.ID;

-- COMMAND ----------

WITH clientes AS (
  SELECT NOMBRE, EDAD, ID_EMPRESA FROM clase03b.cliente_a
) 
SELECT c.NOMBRE, c.EDAD, e.NOMBRE EMPRESA FROM clase03b.empresa e
JOIN clientes c ON e.ID = c.ID_EMPRESA

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Formatos

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### PARQUET

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Function to convert bytes to a human-readable format
-- MAGIC def human_readable_size(size):
-- MAGIC     for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
-- MAGIC         if size < 1024:
-- MAGIC             return f"{size:.2f} {unit}"
-- MAGIC         size /= 1024

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df = spark.read.table("clase03b.cliente_a")
-- MAGIC        
-- MAGIC display(df)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df.write.format("parquet").save("dbfs:/Volumes/workspace/clase03b/data/cliente_parquet")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC dir_path = "/Volumes/workspace/clase03b/data/cliente_parquet"
-- MAGIC files = dbutils.fs.ls(dir_path)
-- MAGIC
-- MAGIC # Calculate the total size
-- MAGIC total_size = sum(file.size for file in files)
-- MAGIC
-- MAGIC # Get the human-readable size
-- MAGIC print(f"Total size: {human_readable_size(total_size)}")

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### ORC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df.write.format("orc").save("dbfs:/Volumes/workspace/clase03b/data/cliente_orc")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC dir_path = "/Volumes/workspace/clase03b/data/cliente_orc"
-- MAGIC files = dbutils.fs.ls(dir_path)
-- MAGIC
-- MAGIC # Calculate the total size
-- MAGIC total_size = sum(file.size for file in files)
-- MAGIC
-- MAGIC # Get the human-readable size
-- MAGIC print(f"Total size: {human_readable_size(total_size)}")

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Compresión

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS clase03b.CLIENTE_ORC_GZIP(
ID STRING,
NOMBRE STRING,
TELEFONO STRING,
CORREO STRING,
FECHA_INGRESO STRING,
EDAD INT,
SALARIO DOUBLE,
ID_EMPRESA STRING
)
--LOCATION '/proyectos/PUCP/cliente_orc_comp'
TBLPROPERTIES ("orc.compression"="GZIP");

-- COMMAND ----------

INSERT OVERWRITE TABLE clase03b.CLIENTE_ORC_GZIP SELECT * FROM clase03b.cliente_a;
SELECT * FROM clase03b.CLIENTE_ORC_GZIP LIMIT 10;

-- COMMAND ----------

DESC FORMATTED clase03b.CLIENTE_ORC_GZIP;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Caso

-- COMMAND ----------

-- MAGIC %python
-- MAGIC #https://datosabiertos.mef.gob.pe/dataset/ejecucion-del-gasto-de-mantenimiento
-- MAGIC #https://www.mef.gob.pe/es/?option=com_content&language=es-ES&Itemid=100944&lang=es-ES&view=article&id=504
-- MAGIC
-- MAGIC #1min
-- MAGIC import requests
-- MAGIC import ssl
-- MAGIC ssl._create_default_https_context = ssl._create_unverified_context
-- MAGIC
-- MAGIC url = "https://fs.datosabiertos.mef.gob.pe/datastorefiles/2026-Gasto-Mantenimiento.csv"
-- MAGIC
-- MAGIC response = requests.get(url, verify=0)
-- MAGIC
-- MAGIC filename = "2026-Gasto-Mantenimiento.csv"
-- MAGIC with open(filename, 'wb') as file:
-- MAGIC     file.write(response.content)
-- MAGIC
-- MAGIC print(f"File saved as {filename}")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # OPCIÓN: Descarga desde google drive
-- MAGIC
-- MAGIC import gdown
-- MAGIC
-- MAGIC file_id = "1dLGSdA7f7x14Ujvj3gyPrjSgt2AWi2YQ"
-- MAGIC filename = "2026-Gasto-Mantenimiento.csv"
-- MAGIC
-- MAGIC gdown.download(f"https://drive.google.com/uc?id={file_id}", filename)
-- MAGIC print(f"File saved as {filename}")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC !ls -lhtr

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Capa Workload

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Por limitante de espacio en memoria (uso de put) en free edition, podemos eliminar las primeras 100,000 lineas
-- MAGIC !sed -i '3,100000d' 2026-Gasto-Mantenimiento.csv

-- COMMAND ----------

-- MAGIC %python
-- MAGIC !head -2 2026-Gasto-Mantenimiento.csv

-- COMMAND ----------

-- MAGIC %python
-- MAGIC !pwd

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # ~10s
-- MAGIC # Transferimos el archivo local al file system de databricks DBFS 
-- MAGIC source_path = "/Workspace/Users/jc.tovarg@pucp.edu.pe/BDA/2026-Gasto-Mantenimiento.csv"
-- MAGIC #source_path = "file:/Workspace/Notebooks/2025-Gasto-Mantenimiento.csv"
-- MAGIC #destination_path = "dbfs:/Volumes/workspace/clase03b/data/2026-Gasto-Mantenimiento.csv"
-- MAGIC destination_path = "dbfs:/Volumes/workspace/default/data/2026-Gasto-Mantenimiento.csv"
-- MAGIC
-- MAGIC with open(source_path, 'r') as file:
-- MAGIC     content = file.read()
-- MAGIC
-- MAGIC #dbutils.fs.put(destination_path, content, overwrite=True)
-- MAGIC dbutils.fs.cp(source_path, destination_path)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Access files in the volume
-- MAGIC dbutils.fs.ls("/Volumes/workspace/default/data")

-- COMMAND ----------

DROP TABLE IF EXISTS clase03b.gasto_m_land;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Capa Landing

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS default.gasto_m_land(
  ANO_EJE STRING,
  MES_EJE STRING,
  NIVEL_GOBIERNO STRING,
  NIVEL_GOBIERNO_NOMBRE STRING,
  SECTOR STRING,
  SECTOR_NOMBRE STRING,
  PLIEGO STRING,
  PLIEGO_NOMBRE STRING,
  SEC_EJEC STRING,
  EJECUTORA STRING,
  EJECUTORA_NOMBRE STRING,
  DEPARTAMENTO_EJECUTORA STRING,
  DEPARTAMENTO_EJECUTORA_NOMBRE STRING,
  PROVINCIA_EJECUTORA STRING,
  PROVINCIA_EJECUTORA_NOMBRE STRING,
  DISTRITO_EJECUTORA STRING,
  DISTRITO_EJECUTORA_NOMBRE STRING,
  SEC_FUNC STRING,
  PROGRAMA_PPTO STRING,
  PROGRAMA_PPTO_NOMBRE STRING,
  TIPO_ACT_PROY STRING,
  TIPO_ACT_PROY_NOMBRE STRING,
  PRODUCTO_PROYECTO STRING,
  PRODUCTO_PROYECTO_NOMBRE STRING,
  ACTIVIDAD_ACCION_OBRA STRING,
  ACTIVIDAD_ACCION_OBRA_NOMBRE STRING,
  FUNCION STRING,
  FUNCION_NOMBRE STRING,
  DIVISION_FUNCIONAL STRING,
  DIVISION_FUNCIONAL_NOMBRE STRING,
  GRUPO_FUNCIONAL STRING,
  GRUPO_FUNCIONAL_NOMBRE STRING,
  META STRING,
  FINALIDAD STRING,
  META_NOMBRE STRING,
  DEPARTAMENTO_META STRING,
  DEPARTAMENTO_META_NOMBRE STRING,
  FUENTE_FINANCIAMIENTO STRING,
  FUENTE_FINANCIAMIENTO_NOMBRE STRING,
  RUBRO STRING,
  RUBRO_NOMBRE STRING,
  TIPO_RECURSO STRING,
  TIPO_RECURSO_NOMBRE STRING,
  CATEGORIA_GASTO STRING,
  CATEGORIA_GASTO_NOMBRE STRING,
  TIPO_TRANSACCION STRING,
  GENERICA STRING,
  GENERICA_NOMBRE STRING,
  SUBGENERICA STRING,
  SUBGENERICA_NOMBRE STRING,
  SUBGENERICA_DET STRING,
  SUBGENERICA_DET_NOMBRE STRING,
  ESPECIFICA STRING,
  ESPECIFICA_NOMBRE STRING,
  ESPECIFICA_DET STRING,
  ESPECIFICA_DET_NOMBRE STRING,
  MONTO_PIA STRING,
  MONTO_PIM STRING,
  MONTO_CERTIFICADO STRING,
  MONTO_COMPROMETIDO_ANUAL STRING,
  MONTO_COMPROMETIDO STRING,
  MONTO_DEVENGADO STRING,
  MONTO_GIRADO STRING
);

-- COMMAND ----------

COPY INTO default.gasto_m_land
FROM '/Volumes/workspace/default/data/2026-Gasto-Mantenimiento.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('delimiter' = ',', 'header' = 'true');

-- COMMAND ----------

SELECT COUNT(1) FROM default.gasto_m_land;

-- COMMAND ----------

DESCRIBE DETAIL default.gasto_m_land

-- COMMAND ----------

SELECT 
  ROUND(sizeInBytes / 1024 / 1024, 3) AS size_mb
FROM (
  _sqldf 
);

-- COMMAND ----------

DESC FORMATTED default.gasto_m_land

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Curated

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS clase03b.gasto_m_cur(
  ANO_EJE INT,
  MES_EJE STRING,
  NIVEL_GOBIERNO STRING,
  NIVEL_GOBIERNO_NOMBRE STRING,
  SECTOR STRING,
  SECTOR_NOMBRE STRING,
  PLIEGO STRING,
  PLIEGO_NOMBRE STRING,
  SEC_EJEC STRING,
  EJECUTORA STRING,
  EJECUTORA_NOMBRE STRING,
  DEPARTAMENTO_EJECUTORA STRING,
  DEPARTAMENTO_EJECUTORA_NOMBRE STRING,
  PROVINCIA_EJECUTORA STRING,
  PROVINCIA_EJECUTORA_NOMBRE STRING,
  DISTRITO_EJECUTORA STRING,
  DISTRITO_EJECUTORA_NOMBRE STRING,
  SEC_FUNC STRING,
  PROGRAMA_PPTO STRING,
  PROGRAMA_PPTO_NOMBRE STRING,
  TIPO_ACT_PROY STRING,
  TIPO_ACT_PROY_NOMBRE STRING,
  PRODUCTO_PROYECTO STRING,
  PRODUCTO_PROYECTO_NOMBRE STRING,
  ACTIVIDAD_ACCION_OBRA STRING,
  ACTIVIDAD_ACCION_OBRA_NOMBRE STRING,
  FUNCION STRING,
  FUNCION_NOMBRE STRING,
  DIVISION_FUNCIONAL STRING,
  DIVISION_FUNCIONAL_NOMBRE STRING,
  GRUPO_FUNCIONAL STRING,
  GRUPO_FUNCIONAL_NOMBRE STRING,
  META STRING,
  FINALIDAD STRING,
  META_NOMBRE STRING,
  DEPARTAMENTO_META STRING,
  DEPARTAMENTO_META_NOMBRE STRING,
  FUENTE_FINANCIAMIENTO STRING,
  FUENTE_FINANCIAMIENTO_NOMBRE STRING,
  RUBRO STRING,
  RUBRO_NOMBRE STRING,
  TIPO_RECURSO STRING,
  TIPO_RECURSO_NOMBRE STRING,
  CATEGORIA_GASTO STRING,
  CATEGORIA_GASTO_NOMBRE STRING,
  TIPO_TRANSACCION STRING,
  GENERICA STRING,
  GENERICA_NOMBRE STRING,
  SUBGENERICA STRING,
  SUBGENERICA_NOMBRE STRING,
  SUBGENERICA_DET STRING,
  SUBGENERICA_DET_NOMBRE STRING,
  ESPECIFICA STRING,
  ESPECIFICA_NOMBRE STRING,
  ESPECIFICA_DET STRING,
  ESPECIFICA_DET_NOMBRE STRING,
  MONTO_PIA INT,
  MONTO_PIM STRING,
  MONTO_CERTIFICADO STRING,
  MONTO_COMPROMETIDO_ANUAL STRING,
  MONTO_COMPROMETIDO STRING,
  MONTO_DEVENGADO INT,
  MONTO_GIRADO STRING

)
TBLPROPERTIES ('creator'='Juan Tovar', 'created_at'='2026-03-31');

-- COMMAND ----------

--DROP TABLE clase03b.gasto_m_cur 

-- COMMAND ----------

--~10s
INSERT OVERWRITE TABLE clase03b.gasto_m_cur 
SELECT 
    CAST(REPLACE(ANO_EJE, '"', '') AS INT) AS ANO_EJE,
    REPLACE(MES_EJE, '"', '') AS MES_EJE,
    REPLACE(NIVEL_GOBIERNO, '"', '') AS NIVEL_GOBIERNO,
    REPLACE(NIVEL_GOBIERNO_NOMBRE, '"', '') AS NIVEL_GOBIERNO_NOMBRE,
    REPLACE(SECTOR, '"', '') AS SECTOR,
    REPLACE(SECTOR_NOMBRE, '"', '') AS SECTOR_NOMBRE,
    REPLACE(PLIEGO, '"', '') AS PLIEGO,
    REPLACE(PLIEGO_NOMBRE, '"', '') AS PLIEGO_NOMBRE,
    REPLACE(SEC_EJEC, '"', '') AS SEC_EJEC,
    REPLACE(EJECUTORA, '"', '') AS EJECUTORA,
    REPLACE(EJECUTORA_NOMBRE, '"', '') AS EJECUTORA_NOMBRE,
    REPLACE(DEPARTAMENTO_EJECUTORA, '"', '') AS DEPARTAMENTO_EJECUTORA,
    REPLACE(DEPARTAMENTO_EJECUTORA_NOMBRE, '"', '') AS DEPARTAMENTO_EJECUTORA_NOMBRE,
    REPLACE(PROVINCIA_EJECUTORA, '"', '') AS PROVINCIA_EJECUTORA,
    REPLACE(PROVINCIA_EJECUTORA_NOMBRE, '"', '') AS PROVINCIA_EJECUTORA_NOMBRE,
    REPLACE(DISTRITO_EJECUTORA, '"', '') AS DISTRITO_EJECUTORA,
    REPLACE(DISTRITO_EJECUTORA_NOMBRE, '"', '') AS DISTRITO_EJECUTORA_NOMBRE,
    REPLACE(SEC_FUNC, '"', '') AS SEC_FUNC,
    REPLACE(PROGRAMA_PPTO, '"', '') AS PROGRAMA_PPTO,
    REPLACE(PROGRAMA_PPTO_NOMBRE, '"', '') AS PROGRAMA_PPTO_NOMBRE,
    REPLACE(TIPO_ACT_PROY, '"', '') AS TIPO_ACT_PROY,
    REPLACE(TIPO_ACT_PROY_NOMBRE, '"', '') AS TIPO_ACT_PROY_NOMBRE,
    REPLACE(PRODUCTO_PROYECTO, '"', '') AS PRODUCTO_PROYECTO,
    REPLACE(PRODUCTO_PROYECTO_NOMBRE, '"', '') AS PRODUCTO_PROYECTO_NOMBRE,
    REPLACE(ACTIVIDAD_ACCION_OBRA, '"', '') AS ACTIVIDAD_ACCION_OBRA,
    REPLACE(ACTIVIDAD_ACCION_OBRA_NOMBRE, '"', '') AS ACTIVIDAD_ACCION_OBRA_NOMBRE,
    REPLACE(FUNCION, '"', '') AS FUNCION,
    REPLACE(FUNCION_NOMBRE, '"', '') AS FUNCION_NOMBRE,
    REPLACE(DIVISION_FUNCIONAL, '"', '') AS DIVISION_FUNCIONAL,
    REPLACE(DIVISION_FUNCIONAL_NOMBRE, '"', '') AS DIVISION_FUNCIONAL_NOMBRE,
    REPLACE(GRUPO_FUNCIONAL, '"', '') AS GRUPO_FUNCIONAL,
    REPLACE(GRUPO_FUNCIONAL_NOMBRE, '"', '') AS GRUPO_FUNCIONAL_NOMBRE,
    REPLACE(META, '"', '') AS META,
    REPLACE(FINALIDAD, '"', '') AS FINALIDAD,
    REPLACE(META_NOMBRE, '"', '') AS META_NOMBRE,
    REPLACE(DEPARTAMENTO_META, '"', '') AS DEPARTAMENTO_META,
    REPLACE(DEPARTAMENTO_META_NOMBRE, '"', '') AS DEPARTAMENTO_META_NOMBRE,
    REPLACE(FUENTE_FINANCIAMIENTO, '"', '') AS FUENTE_FINANCIAMIENTO,
    REPLACE(FUENTE_FINANCIAMIENTO_NOMBRE, '"', '') AS FUENTE_FINANCIAMIENTO_NOMBRE,
    REPLACE(RUBRO, '"', '') AS RUBRO,
    REPLACE(RUBRO_NOMBRE, '"', '') AS RUBRO_NOMBRE,
    REPLACE(TIPO_RECURSO, '"', '') AS TIPO_RECURSO,
    REPLACE(TIPO_RECURSO_NOMBRE, '"', '') AS TIPO_RECURSO_NOMBRE,
    REPLACE(CATEGORIA_GASTO, '"', '') AS CATEGORIA_GASTO,
    REPLACE(CATEGORIA_GASTO_NOMBRE, '"', '') AS CATEGORIA_GASTO_NOMBRE,
    REPLACE(TIPO_TRANSACCION, '"', '') AS TIPO_TRANSACCION,
    REPLACE(GENERICA, '"', '') AS GENERICA,
    REPLACE(GENERICA_NOMBRE, '"', '') AS GENERICA_NOMBRE,
    REPLACE(SUBGENERICA, '"', '') AS SUBGENERICA,
    REPLACE(SUBGENERICA_NOMBRE, '"', '') AS SUBGENERICA_NOMBRE,
    REPLACE(SUBGENERICA_DET, '"', '') AS SUBGENERICA_DET,
    REPLACE(SUBGENERICA_DET_NOMBRE, '"', '') AS SUBGENERICA_DET_NOMBRE,
    REPLACE(ESPECIFICA, '"', '') AS ESPECIFICA,
    REPLACE(ESPECIFICA_NOMBRE, '"', '') AS ESPECIFICA_NOMBRE,
    REPLACE(ESPECIFICA_DET, '"', '') AS ESPECIFICA_DET,
    REPLACE(ESPECIFICA_DET_NOMBRE, '"', '') AS ESPECIFICA_DET_NOMBRE,
    CAST(REPLACE(MONTO_PIA, '"', '') AS DOUBLE) AS MONTO_PIA,
    REPLACE(MONTO_PIM, '"', '') AS MONTO_PIM,
    REPLACE(MONTO_CERTIFICADO, '"', '') AS MONTO_CERTIFICADO,
    REPLACE(MONTO_COMPROMETIDO_ANUAL, '"', '') AS MONTO_COMPROMETIDO_ANUAL,
    REPLACE(MONTO_COMPROMETIDO, '"', '') AS MONTO_COMPROMETIDO,
    CAST(REPLACE(MONTO_DEVENGADO, '"', '') AS DOUBLE) AS MONTO_DEVENGADO,
    REPLACE(MONTO_GIRADO, '"', '') AS MONTO_GIRADO
FROM clase03b.gasto_m_land;
SELECT * FROM clase03b.gasto_m_cur LIMIT 10;

-- COMMAND ----------

SELECT COUNT(1) FROM clase03b.gasto_m_cur;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Functional

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS clase03b.gasto_m_resumen(
ANO_EJE INT,
PIM DOUBLE,
DEVENGADO DOUBLE,
AVANCE DOUBLE
)
TBLPROPERTIES ('creator'='Juan Tovar', 'created_at'='2026-03-31');


-- COMMAND ----------

INSERT OVERWRITE TABLE clase03b.gasto_m_resumen
SELECT 
ANO_EJE, SUM(MONTO_PIM) A, SUM(MONTO_DEVENGADO) B, ROUND(B/A*100, 3) AVANCE
FROM clase03b.gasto_m_cur
GROUP BY ANO_EJE;
SELECT * FROM clase03b.gasto_m_resumen;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Ejercicio
-- MAGIC
-- MAGIC Busque un dataset y aplique los proceso por cada capa, según el Caso.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Capa Workload

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Capa Landing

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Capa Curated

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Capa Functional

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **¡Sigamos aprendiendo! #MachineLearning #Python #DeepLearning #BigData**
