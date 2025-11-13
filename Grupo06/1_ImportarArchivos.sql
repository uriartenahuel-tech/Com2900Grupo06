USE Com2900G06
/*
select * from Tabla.Factura;
select * from Tabla.Pago;

select * from Tabla.DetalleExpensa;
select * from Tabla.TipoGasto;
select * from Tabla.TipoServicio;

select * from Tabla.Unidad_complementaria;
select * from Tabla.Unidad_Funcional;
select * from Tabla.Expensa;

select * from Tabla.Persona;
select * from Tabla.Proveedor;
select * from Tabla.Consorcio;
*/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Procedimientos')
BEGIN
    EXEC('CREATE SCHEMA Procedimientos');
END
GO
-- 1) Personas
EXEC Procedimientos.ImportarPersonas
    @RutaArchivo = N'C:\Users\Nahuel\Desktop\Grupo06\archivos\Inquilino-propietarios-datos.csv';

-- 2) Consorcios
EXEC Procedimientos.ImportarConsorcios
    @RutaArchivo = N'C:\Users\Nahuel\Desktop\Grupo06\archivos\UF por consorcio.txt';

-- 3) Unidades funcionales + unidad_complementaria
EXEC Procedimientos.ImportarUnidadesFuncionales
    @RutaUFConsorcioTxt = N'C:\Users\Nahuel\Desktop\Grupo06\archivos\UF por consorcio.txt',
    @RutaUFPersonaCsv   = N'C:\Users\Nahuel\Desktop\Grupo06\archivos\Inquilino-propietarios-UF.csv';

-- 4) Servicios
EXEC Procedimientos.ImportarServicios
    @RutaArchivo = N'C:\Users\Nahuel\Desktop\Grupo06\archivos\Servicios.Servicios.json',
    @anio = 2025;

-- 5) Pagos 
EXEC Procedimientos.ImportarPagos
    @RutaArchivo = N'C:\Users\Nahuel\Desktop\Grupo06\archivos\pagos_consorcios.csv';
/* ============================================================
   SP: Importar personas desde archivo CSV
   Archivo de ejemplo: Inquilino-propietarios-datos.csv
   Formato:
     - Delimitador: ';'
     - Primera fila: encabezado
     - Codificación: Windows-1252 / UTF-8 (según origen)
   Parámetro:
     @RutaArchivo = ruta completa al CSV
   Ejemplo de uso:
     EXEC Procedimientos.ImportarPersonas
          @RutaArchivo = N'C:\Datos\Inquilino-propietarios-datos.csv';
   ============================================================ */
IF OBJECT_ID('Procedimientos.ImportarPersonas','P') IS NOT NULL
    DROP PROCEDURE Procedimientos.ImportarPersonas;
GO

CREATE PROCEDURE Procedimientos.ImportarPersonas
    @RutaArchivo NVARCHAR(4000)      -- ruta completa al CSV (sin hardcode en el código)
AS
BEGIN
    SET NOCOUNT ON;

    /* 
       1) Tabla staging temporal para reflejar el CSV tal cual viene.
       No se usa fuera del SP.
    */
    CREATE TABLE #stg_Persona_raw
    (
        NombreRaw        NVARCHAR(200) NULL,
        ApellidoRaw      NVARCHAR(200) NULL,
        DNIRaw           NVARCHAR(50)  NULL,
        EmailRaw         NVARCHAR(200) NULL,
        TelefonoRaw      NVARCHAR(100) NULL,
        CVUCBURaw        NVARCHAR(100) NULL,
        InquilinoRaw     NVARCHAR(50)  NULL
    );

    /* 2) Cargar el CSV con BULK INSERT usando SQL dinámico
          (es la única forma de parametrizar la ruta). */
    DECLARE @sql NVARCHAR(MAX);

    /* 
       Ajustá CODEPAGE según cómo tengas guardado el archivo:
       - Si es UTF-8: CODEPAGE = '65001'
       - Si es ANSI latino: podés omitir CODEPAGE o usar 1252.
    */
    SET @sql = N'
        BULK INSERT #stg_Persona_raw
        FROM ' + QUOTENAME(@RutaArchivo,'''') + N'
        WITH
        (
            FIRSTROW = 2,                  -- saltear encabezado
            FIELDTERMINATOR = '';'',       -- separador ;
            ROWTERMINATOR   = ''0x0a'',    -- salto de línea
            CODEPAGE = ''65001'',          -- suponemos UTF-8
            TABLOCK
        );';

    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        PRINT 'Error al ejecutar BULK INSERT en ImportarPersonas: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    /* 3) Normalizar datos (TRIM, limpiar espacios raros) y proyectar a tipos destino */
;WITH PersonasLimpias AS
(
    SELECT
        LTRIM(RTRIM(NombreRaw))     AS Nombre,
        LTRIM(RTRIM(ApellidoRaw))   AS Apellido,
        LTRIM(RTRIM(DNIRaw))        AS DNI,
        LTRIM(RTRIM(EmailRaw))      AS Email,
        LTRIM(RTRIM(TelefonoRaw))   AS Telefono,
        LTRIM(RTRIM(CVUCBURaw))     AS CVU_CBU_str,
        LTRIM(RTRIM(InquilinoRaw))  AS Inquilino_str
    FROM #stg_Persona_raw
),
PersonasTransformadas AS
(
    SELECT
        DNI,
        Nombre,
        Apellido,
        Email,
        Telefono,
        CVU_CBU_str AS CVU_CBU,
        CASE 
            WHEN Inquilino_str IN ('1','SI','S','TRUE','T') THEN 'Inquilino'
            WHEN Inquilino_str IN ('0','NO','N','FALSE','F') THEN 'Propietario'
            ELSE NULL
        END AS InquilinoTexto
    FROM PersonasLimpias
    WHERE DNI IS NOT NULL AND DNI <> ''
),
PersonasDeduplicadas AS
(
    SELECT *
    FROM
    (
        SELECT 
            DNI,
            Nombre,
            Apellido,
            Email,
            Telefono,
            CVU_CBU,
            InquilinoTexto,
            ROW_NUMBER() OVER (PARTITION BY DNI ORDER BY DNI) AS rn
        FROM PersonasTransformadas
    ) X
    WHERE rn = 1       -- nos quedamos con UNA fila por DNI
)

MERGE Tabla.Persona AS T
USING PersonasDeduplicadas AS S
   ON T.dni = S.DNI
WHEN MATCHED THEN
    UPDATE SET
        nombre       = COALESCE(S.Nombre, T.nombre),
        apellido     = COALESCE(S.Apellido, T.apellido),
        email        = COALESCE(S.Email, T.email),
        telefono     = COALESCE(S.Telefono, T.telefono),
        CVU_CBU      = COALESCE(S.CVU_CBU, T.CVU_CBU),
        inquilino    = COALESCE(S.InquilinoTexto, T.inquilino),
        Fecha_Inicio = T.Fecha_Inicio,
        Fecha_Fin    = T.Fecha_Fin
WHEN NOT MATCHED BY TARGET THEN
    INSERT (dni, nombre, apellido, email, telefono, CVU_CBU, inquilino, Fecha_Inicio, Fecha_Fin)
    VALUES (S.DNI, S.Nombre, S.Apellido, S.Email, S.Telefono, S.CVU_CBU, S.InquilinoTexto, NULL, NULL);
    PRINT 'ImportarPersonas: proceso finalizado (MERGE sobre Tabla.Persona).';

END
GO

/* ============================================================
   SP: Importar consorcios desde archivo de UFs
   Archivo de ejemplo: "UF por consorcio.txt"

   Formato:
     - Delimitador: TAB (\t)
     - Primera fila: encabezado
     - Codificación: ANSI / Latin1 (CODEPAGE 1252 suele funcionar)

   Parámetro:
     @RutaArchivo = ruta completa al TXT

   Ejemplo de uso:
     EXEC Procedimientos.ImportarConsorcios
          @RutaArchivo = N'C:\Datos\UF por consorcio.txt';
   ============================================================ */
IF OBJECT_ID('Procedimientos.ImportarConsorcios', 'P') IS NOT NULL
    DROP PROCEDURE Procedimientos.ImportarConsorcios;
GO

CREATE PROCEDURE Procedimientos.ImportarConsorcios
    @RutaArchivo NVARCHAR(4000)     -- ruta completa al TXT (sin hardcode en el código)
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Tabla staging que refleja el archivo tal cual viene */
    CREATE TABLE #stg_UFConsorcio
    (
        NombreConsorcio     NVARCHAR(200) NULL,
        nroUnidadFuncional  NVARCHAR(50)  NULL,
        Piso                NVARCHAR(50)  NULL,
        Departamento        NVARCHAR(50)  NULL,
        CoeficienteRaw      NVARCHAR(50)  NULL,
        m2UFRaw             NVARCHAR(50)  NULL,
        BaulerasRaw         NVARCHAR(20)  NULL,
        CocheraRaw          NVARCHAR(20)  NULL,
        m2BauleraRaw        NVARCHAR(50)  NULL,
        m2CocheraRaw        NVARCHAR(50)  NULL
    );

    /* 2) BULK INSERT con SQL dinámico (necesario para parametrizar la ruta) */
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #stg_UFConsorcio
        FROM ' + QUOTENAME(@RutaArchivo,'''') + N'
        WITH
        (
            FIRSTROW = 2,                  -- saltear encabezado
            FIELDTERMINATOR = ''\t'',      -- TAB como separador
            ROWTERMINATOR   = ''0x0A'',    -- salto de línea (LF)
            CODEPAGE = ''1252'',           -- ANSI Latino (el archivo viene así)
            TABLOCK
        );';

    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        PRINT 'Error al ejecutar BULK INSERT en ImportarConsorcios: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    /* 3) Normalizar nombre de consorcio (TRIM) y deduplicar */
    ;WITH ConsorciosLimpios AS
    (
        SELECT DISTINCT
            LTRIM(RTRIM(NombreConsorcio)) AS nombre
        FROM #stg_UFConsorcio
        WHERE NombreConsorcio IS NOT NULL
          AND LTRIM(RTRIM(NombreConsorcio)) <> ''
    )
    INSERT INTO Tabla.Consorcio (nombre, direccion, cuit_administracion, cuenta_bancaria, opcion_limpieza)
    SELECT C.nombre,
           NULL AS direccion,
           NULL AS cuit_administracion,
           NULL AS cuenta_bancaria,
           NULL AS opcion_limpieza
    FROM ConsorciosLimpios C
    LEFT JOIN Tabla.Consorcio T
           ON T.nombre = C.nombre
    WHERE T.id IS NULL;   -- sólo los que no existían

    PRINT 'ImportarConsorcios: proceso finalizado. Nuevos consorcios insertados (si había).';
END
GO

/* ============================================================
   SP: Importar Unidades Funcionales (y Unidad_complementaria)
   Archivos de entrada:
     - @RutaUFConsorcioTxt : "UF por consorcio.txt"
         Delimitador: TAB (\t)
         Columnas:
            Nombre del consorcio
            nroUnidadFuncional
            Piso
            departamento
            coefic...iente
            m2_unidad_funcional
            bauleras
            cochera
            m2_baulera
            m2_cochera

     - @RutaUFPersonaCsv : "Inquilino-propietarios-UF.csv"
         Delimitador: '|'
         Columnas:
            CVU/CBU
            Nombre del consorcio
            nroUnidadFuncional
            piso
            departamento

   Requiere:
     - Tabla.Persona ya cargada (ImportarPersonas)
     - Tabla.Consorcio ya cargada (ImportarConsorcios)

   Lógica:
     - Staging de ambos archivos
     - Join por consorcio + nro UF + piso + depto
     - Join con Persona por CVU_CBU
     - Join con Consorcio por nombre
     - MERGE a Unidad_Funcional y Unidad_complementaria

   Ejemplo de uso:
     EXEC Procedimientos.ImportarUnidadesFuncionales
          @RutaUFConsorcioTxt = N'C:\Datos\UF por consorcio.txt',
          @RutaUFPersonaCsv   = N'C:\Datos\Inquilino-propietarios-UF.csv';
   ============================================================ */
IF OBJECT_ID('Procedimientos.ImportarUnidadesFuncionales','P') IS NOT NULL
    DROP PROCEDURE Procedimientos.ImportarUnidadesFuncionales;
GO

CREATE PROCEDURE Procedimientos.ImportarUnidadesFuncionales
    @RutaUFConsorcioTxt NVARCHAR(4000),
    @RutaUFPersonaCsv   NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Staging de UF por consorcio */
    CREATE TABLE #stg_UFConsorcio
    (
        NombreConsorcioRaw    NVARCHAR(200) NULL,
        nroUFRaw              NVARCHAR(50)  NULL,
        PisoRaw               NVARCHAR(50)  NULL,
        DeptoRaw              NVARCHAR(50)  NULL,
        CoeficienteRaw        NVARCHAR(50)  NULL,
        m2UFRaw               NVARCHAR(50)  NULL,
        BaulerasRaw           NVARCHAR(20)  NULL,
        CocheraRaw            NVARCHAR(20)  NULL,
        m2BauleraRaw          NVARCHAR(50)  NULL,
        m2CocheraRaw          NVARCHAR(50)  NULL
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #stg_UFConsorcio
        FROM ' + QUOTENAME(@RutaUFConsorcioTxt,'''') + N'
        WITH
        (
            FIRSTROW = 2,             -- saltear encabezado
            FIELDTERMINATOR = ''\t'', -- TAB
            ROWTERMINATOR   = ''0x0A'',
            CODEPAGE = ''1252'',      -- ANSI latino
            TABLOCK
        );';

    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        PRINT 'Error BULK INSERT UF por consorcio: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    /* 2) Staging de Inquilino-propietarios-UF.csv */
    CREATE TABLE #stg_UFPersona
    (
        CVU_CBU_Raw          NVARCHAR(100) NULL,
        NombreConsorcioRaw   NVARCHAR(200) NULL,
        nroUFRaw             NVARCHAR(50)  NULL,
        PisoRaw              NVARCHAR(50)  NULL,
        DeptoRaw             NVARCHAR(50)  NULL
    );

    SET @sql = N'
        BULK INSERT #stg_UFPersona
        FROM ' + QUOTENAME(@RutaUFPersonaCsv,'''') + N'
        WITH
        (
            FIRSTROW = 2,             -- saltear encabezado
            FIELDTERMINATOR = ''|'',  -- pipe
            ROWTERMINATOR   = ''0x0A'',
            CODEPAGE = ''1252'',
            TABLOCK
        );';

    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        PRINT 'Error BULK INSERT Inquilino-propietarios-UF: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;


    /* 3) Normalización y armado de datos finales para merge */

    CREATE TABLE #UF_Merge
    (
        id_Consorcio          INT          NOT NULL,
        nro_Unidad_Funcional  INT          NOT NULL,
        dni_Persona           VARCHAR(10)  NULL,
        piso                  VARCHAR(10)  NULL,
        depto                 VARCHAR(10)  NULL,
        porcentaje_prorrateo  DECIMAL(6,3) NULL,
        superficie            DECIMAL(10,2) NULL,
        baulera               INT          NULL,
        cochera               INT          NULL,
        superficie_baulera    DECIMAL(10,2) NULL,
        superficie_cochera    DECIMAL(10,2) NULL
    );

    ;WITH UFConsorcioLimpio AS
    (
        SELECT
            LTRIM(RTRIM(NombreConsorcioRaw)) AS NombreConsorcio,
            LTRIM(RTRIM(nroUFRaw))           AS nroUF,
            LTRIM(RTRIM(PisoRaw))            AS Piso,
            LTRIM(RTRIM(DeptoRaw))           AS Depto,
            LTRIM(RTRIM(CoeficienteRaw))     AS Coeficiente,
            LTRIM(RTRIM(m2UFRaw))            AS m2UF,
            LTRIM(RTRIM(BaulerasRaw))        AS Bauleras,
            LTRIM(RTRIM(CocheraRaw))         AS Cochera,
            LTRIM(RTRIM(m2BauleraRaw))       AS m2Baulera,
            LTRIM(RTRIM(m2CocheraRaw))       AS m2Cochera
        FROM #stg_UFConsorcio
        WHERE NombreConsorcioRaw IS NOT NULL
          AND LTRIM(RTRIM(NombreConsorcioRaw)) <> ''
    ),
    UFPersonaLimpio AS
    (
        SELECT
            LTRIM(RTRIM(CVU_CBU_Raw))        AS CVU_CBU,
            LTRIM(RTRIM(NombreConsorcioRaw)) AS NombreConsorcio,
            LTRIM(RTRIM(nroUFRaw))           AS nroUF,
            LTRIM(RTRIM(PisoRaw))            AS Piso,
            LTRIM(RTRIM(DeptoRaw))           AS Depto
        FROM #stg_UFPersona
        WHERE CVU_CBU_Raw IS NOT NULL
          AND LTRIM(RTRIM(CVU_CBU_Raw)) <> ''
    ),
    UFJoin AS
    (
        SELECT
            uc.NombreConsorcio,
            uc.nroUF,
            uc.Piso,
            uc.Depto,
            TRY_CONVERT(INT, uc.nroUF) AS nroUF_int,
            TRY_CONVERT(DECIMAL(6,3), REPLACE(uc.Coeficiente, ',', '.')) AS coeficiente,
            TRY_CONVERT(DECIMAL(10,2), REPLACE(uc.m2UF, ',', '.'))       AS m2UF_dec,
            CASE WHEN UPPER(uc.Bauleras) IN ('SI','S','YES','Y','1') THEN 1 ELSE 0 END AS baulera,
            CASE WHEN UPPER(uc.Cochera)  IN ('SI','S','YES','Y','1') THEN 1 ELSE 0 END AS cochera,
            TRY_CONVERT(DECIMAL(10,2), REPLACE(uc.m2Baulera, ',', '.'))  AS m2Baulera_dec,
            TRY_CONVERT(DECIMAL(10,2), REPLACE(uc.m2Cochera, ',', '.'))  AS m2Cochera_dec,
            up.CVU_CBU,
            up.NombreConsorcio AS NombreConsorcio_Persona,
            up.nroUF           AS nroUF_Persona,
            up.Piso            AS Piso_Persona,
            up.Depto           AS Depto_Persona
        FROM UFConsorcioLimpio uc
        LEFT JOIN UFPersonaLimpio up
               ON up.NombreConsorcio = uc.NombreConsorcio
              AND up.nroUF          = uc.nroUF
              AND up.Piso           = uc.Piso
              AND up.Depto          = uc.Depto
    )
    INSERT INTO #UF_Merge
    (
        id_Consorcio,
        nro_Unidad_Funcional,
        dni_Persona,
        piso,
        depto,
        porcentaje_prorrateo,
        superficie,
        baulera,
        cochera,
        superficie_baulera,
        superficie_cochera
    )
    SELECT
        c.id AS id_Consorcio,
        uj.nroUF_int AS nro_Unidad_Funcional,
        p.dni AS dni_Persona,
        uj.Piso,
        uj.Depto,
        uj.coeficiente,
        uj.m2UF_dec,
        uj.baulera,
        uj.cochera,
        uj.m2Baulera_dec,
        uj.m2Cochera_dec
    FROM UFJoin uj
    INNER JOIN Tabla.Consorcio c
            ON c.nombre = uj.NombreConsorcio
    LEFT JOIN Tabla.Persona p
            ON p.CVU_CBU = uj.CVU_CBU
    WHERE uj.nroUF_int IS NOT NULL;
    -- Nota: si no hay Persona con ese CVU_CBU, dni_Persona queda NULL.
    -- Si quisieras exigir que siempre haya persona, poné "AND p.dni IS NOT NULL".


    /* 4) MERGE a Unidad_Funcional, usando clave natural (id_Consorcio + nro_Unidad_Funcional) */

    CREATE TABLE #UF_Result
    (
        id_uf               INT         NOT NULL,
        id_Consorcio        INT         NOT NULL,
        nro_Unidad_Funcional INT        NOT NULL,
        baulera             INT         NULL,
        cochera             INT         NULL,
        superficie_baulera  DECIMAL(10,2) NULL,
        superficie_cochera  DECIMAL(10,2) NULL
    );

    MERGE Tabla.Unidad_Funcional AS T
    USING #UF_Merge AS S
      ON T.id_Consorcio         = S.id_Consorcio
     AND T.nro_Unidad_Funcional = S.nro_Unidad_Funcional
    WHEN MATCHED THEN
        UPDATE SET
            T.dni_Persona          = COALESCE(S.dni_Persona, T.dni_Persona),
            T.piso                 = COALESCE(S.piso, T.piso),
            T.depto                = COALESCE(S.depto, T.depto),
            T.porcentaje_prorrateo = COALESCE(S.porcentaje_prorrateo, T.porcentaje_prorrateo),
            T.superficie           = COALESCE(S.superficie, T.superficie)
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (id_Consorcio, dni_Persona, nro_Unidad_Funcional, piso, depto,
                porcentaje_prorrateo, superficie)
        VALUES (S.id_Consorcio, S.dni_Persona, S.nro_Unidad_Funcional, S.piso, S.depto,
                S.porcentaje_prorrateo, S.superficie)
    OUTPUT
        inserted.id               AS id_uf,
        inserted.id_Consorcio     AS id_Consorcio,
        inserted.nro_Unidad_Funcional AS nro_Unidad_Funcional,
        S.baulera,
        S.cochera,
        S.superficie_baulera,
        S.superficie_cochera
    INTO #UF_Result;

    /* 5) MERGE a Unidad_complementaria (1 fila por UF) */

    MERGE Tabla.Unidad_complementaria AS T
    USING #UF_Result AS S
      ON T.id_uf = S.id_uf
    WHEN MATCHED THEN
        UPDATE SET
            T.baulera            = S.baulera,
            T.cochera            = S.cochera,
            T.superficie_baulera = S.superficie_baulera,
            T.superficie_cochera = S.superficie_cochera
    WHEN NOT MATCHED BY TARGET
         AND (S.baulera IS NOT NULL OR S.cochera IS NOT NULL
              OR S.superficie_baulera IS NOT NULL OR S.superficie_cochera IS NOT NULL) THEN
        INSERT (id_uf, baulera, cochera, superficie_baulera, superficie_cochera)
        VALUES (S.id_uf, S.baulera, S.cochera, S.superficie_baulera, S.superficie_cochera);

    PRINT 'ImportarUnidadesFuncionales: proceso finalizado (UF + Unidad_complementaria).';
END
GO

/* ============================================================
   SP: Importar pagos desde pagos_consorcios.csv

   Archivo:
     - Nombre: pagos_consorcios.csv
     - Delimitador: ','
     - Encabezado en la primera fila
     - Columnas:
         Id de pago,fecha,CVU/CBU, Valor
       (fecha en formato dd/mm/yyyy, Valor con '$' y '.' de miles)

   Parámetro:
     @RutaArchivo = ruta completa al CSV

   Lógica:
     1) Staging del CSV
     2) Parseo de fecha y monto
     3) Enriquecimiento con Persona, UF, Consorcio
     4) Alta (o creación) de Expensa por (id_consorcio, periodo)
     5) Insert de Pago sin duplicar

   Ejemplo de uso:
     EXEC Procedimientos.ImportarPagos
          @RutaArchivo = N'C:\Datos\pagos_consorcios.csv';
   ============================================================ */
IF OBJECT_ID('Procedimientos.ImportarPagos','P') IS NOT NULL
    DROP PROCEDURE Procedimientos.ImportarPagos;
GO

CREATE PROCEDURE Procedimientos.ImportarPagos
    @RutaArchivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Staging bruto del CSV */
    CREATE TABLE #stg_Pagos
    (
        IdPagoRaw    NVARCHAR(50)  NULL,
        FechaRaw     NVARCHAR(50)  NULL,
        CVU_CBURaw   NVARCHAR(100) NULL,
        ValorRaw     NVARCHAR(100) NULL
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #stg_Pagos
        FROM ' + QUOTENAME(@RutaArchivo,'''') + N'
        WITH
        (
            FIRSTROW = 2,              -- saltear encabezado
            FIELDTERMINATOR = '','',   -- coma
            ROWTERMINATOR   = ''0x0A'',
            CODEPAGE = ''65001'',      -- el archivo viene en UTF-8 con BOM
            TABLOCK
        );';

    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        PRINT 'Error BULK INSERT pagos_consorcios: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;


    /* 2) Transformar a tipos destino (fecha, importe, periodo) */

    CREATE TABLE #Pagos_Transformados
    (
        IdPago      INT          NULL,
        Fecha       DATE         NULL,
        Periodo     CHAR(7)      NULL,     -- 'YYYY-MM'
        CVU_CBU     VARCHAR(30)  NULL,
        Importe     DECIMAL(12,2) NULL
    );

    INSERT INTO #Pagos_Transformados (IdPago, Fecha, Periodo, CVU_CBU, Importe)
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(IdPagoRaw))) AS IdPago,
        TRY_CONVERT(DATE, LTRIM(RTRIM(FechaRaw)), 103) AS Fecha,  -- 103 = dd/mm/yyyy
        CASE 
            WHEN TRY_CONVERT(DATE, LTRIM(RTRIM(FechaRaw)), 103) IS NOT NULL
                 THEN CONVERT(CHAR(7), TRY_CONVERT(DATE, LTRIM(RTRIM(FechaRaw)), 103), 126) 
                 -- formato 126 = ISO: 'YYYY-MM-DD' -> char(7) = 'YYYY-MM'
            ELSE NULL
        END AS Periodo,
        CONVERT(VARCHAR(30), LTRIM(RTRIM(CVU_CBURaw))) AS CVU_CBU,
        TRY_CONVERT(DECIMAL(12,2),
            REPLACE(                         -- sacar puntos de miles
                REPLACE(                     -- sacar '$'
                    REPLACE(LTRIM(RTRIM(ValorRaw)), ' ', ''), 
                    '$',''
                ),
            '.','')
        ) AS Importe
    FROM #stg_Pagos;


    /* 3) Enriquecer con Persona, UF y Consorcio */

    CREATE TABLE #Pagos_Con_Consorcio
    (
        IdPago      INT          NULL,
        Fecha       DATE         NULL,
        Periodo     CHAR(7)      NULL,
        CVU_CBU     VARCHAR(30)  NULL,
        Importe     DECIMAL(12,2) NULL,
        id_Consorcio INT         NULL
    );

    INSERT INTO #Pagos_Con_Consorcio
        (IdPago, Fecha, Periodo, CVU_CBU, Importe, id_Consorcio)
    SELECT
        pT.IdPago,
        pT.Fecha,
        pT.Periodo,
        pT.CVU_CBU,
        pT.Importe,
        c.id AS id_Consorcio
    FROM #Pagos_Transformados pT
    INNER JOIN Tabla.Persona per
        ON per.CVU_CBU = pT.CVU_CBU
    INNER JOIN Tabla.Unidad_Funcional uf
        ON uf.dni_Persona = per.dni
    INNER JOIN Tabla.Consorcio c
        ON c.id = uf.id_Consorcio
    WHERE pT.Fecha IS NOT NULL
      AND pT.Periodo IS NOT NULL
      AND pT.Importe IS NOT NULL;
    -- si no matchea Persona/UF/Consorcio o los datos vienen mal, el pago se descarta


    /* 4) Asegurar Expensas por (id_consorcio, periodo).
          Si ya existen, no se duplica nada. Si no existen, se crean. */

    ;WITH ExpensasNecesarias AS
    (
        SELECT DISTINCT
            pc.id_Consorcio,
            pc.Periodo
        FROM #Pagos_Con_Consorcio pc
        WHERE pc.id_Consorcio IS NOT NULL
          AND pc.Periodo IS NOT NULL
    )
    INSERT INTO Tabla.Expensa
        (id_consorcio, periodo, fecha_emision, vencimiento_1, vencimiento_2,
         forma_de_pago, saldo_anterior, interes_por_mora)
    SELECT
        eN.id_Consorcio,
        eN.Periodo,
        -- como ejemplo: fecha_emision = primer día del periodo
        TRY_CONVERT(DATE, eN.Periodo + '-01', 126) AS fecha_emision,
        NULL AS vencimiento_1,
        NULL AS vencimiento_2,
        NULL AS forma_de_pago,
        NULL AS saldo_anterior,
        NULL AS interes_por_mora
    FROM ExpensasNecesarias eN
    LEFT JOIN Tabla.Expensa e
           ON e.id_consorcio = eN.id_Consorcio
          AND e.periodo      = eN.Periodo
    WHERE e.id IS NULL;  -- sólo las que no existían


    /* 5) Armar pagos finales con id_expensa ya resuelto */

    CREATE TABLE #Pagos_Finales
    (
        id_expensa INT          NOT NULL,
        fecha      DATE         NOT NULL,
        CVU_CBU    VARCHAR(30)  NOT NULL,
        importe    DECIMAL(12,2) NOT NULL
    );

    INSERT INTO #Pagos_Finales (id_expensa, fecha, CVU_CBU, importe)
    SELECT
        e.id       AS id_expensa,
        pc.Fecha   AS fecha,
        pc.CVU_CBU,
        pc.Importe
    FROM #Pagos_Con_Consorcio pc
    INNER JOIN Tabla.Expensa e
            ON e.id_consorcio = pc.id_Consorcio
           AND e.periodo      = pc.Periodo
    WHERE pc.id_Consorcio IS NOT NULL
      AND pc.Periodo IS NOT NULL
      AND pc.Importe IS NOT NULL
      AND pc.Fecha IS NOT NULL;


    /* 6) MERGE a Tabla.Pago evitando duplicados.
          Usamos como "clave natural" (id_expensa, fecha, CVU_CBU, importe) */

    MERGE Tabla.Pago AS T
    USING #Pagos_Finales AS S
      ON T.id_expensa = S.id_expensa
     AND T.fecha      = S.fecha
     AND T.CVU_CBU    = S.CVU_CBU
     AND T.importe    = S.importe
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (id_expensa, fecha, CVU_CBU, importe)
        VALUES (S.id_expensa, S.fecha, S.CVU_CBU, S.importe);

    PRINT 'ImportarPagos: proceso finalizado (Pagos + Expensas creadas si era necesario).';
END
GO

/* ============================================================
   SP: ImportarServicios

   Archivo:
     - Servicios.Servicios.json
     - Estructura (por ejemplo):
        [
          {
            "_id": { "$oid": "..." },
            "Nombre del consorcio": "Azcuenaga",
            "Mes": "abril",
            "BANCARIOS": "22,648.59",
            "LIMPIEZA": "120,000.00",
            "ADMINISTRACION": "200,000.00",
            "SEGUROS": "33.706,04",
            "GASTOS GENERALES": "9.344,32",
            "SERVICIOS PUBLICOS-Agua": "482.925,88",
            "SERVICIOS PUBLICOS-Luz": "532.116,75"
          },
          ...
        ]

   Parámetros:
     @RutaArchivo  = ruta completa al JSON
     @Anio         = año a usar en el período (ej: 2025)

   Lógica:
     1) Leer archivo JSON con OPENROWSET(BULK ... SINGLE_CLOB)
     2) Parsear con OPENJSON a una tabla "ancha"
     3) Pasar a formato "largo" (un concepto por fila) + parsear importes
     4) Construir nombres de TipoGasto / TipoServicio:
        - Si el concepto tiene '-', izquierda = TipoGasto, derecha = TipoServicio
        - Si no, ambos usan el mismo nombre
     5) Insertar TipoGasto / TipoServicio que falten
     6) Asegurar Expensa por (Consorcio, Periodo)
     7) MERGE a DetalleExpensa sin duplicar

   NOTA: El importe NO está en la tabla, así que lo dejo
         en la descripción (para no perder info). Si después agregás
         una columna monto en DetalleExpensa, acá la podés usar.
   ============================================================ */
IF OBJECT_ID('Procedimientos.ImportarServicios','P') IS NOT NULL
    DROP PROCEDURE Procedimientos.ImportarServicios;
GO

CREATE PROCEDURE Procedimientos.ImportarServicios
    @RutaArchivo NVARCHAR(4000),
    @Anio        INT
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Leer JSON del archivo a una tabla temporal */
    CREATE TABLE #JsonRaw (JsonDoc NVARCHAR(MAX));

    DECLARE @sql  NVARCHAR(MAX);
    DECLARE @json NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #JsonRaw(JsonDoc)
        SELECT BulkColumn
        FROM OPENROWSET(
            BULK ' + QUOTENAME(@RutaArchivo,'''') + N',
            SINGLE_CLOB
        ) AS j;
    ';

    BEGIN TRY
        EXEC(@sql);
    END TRY
    BEGIN CATCH
        PRINT 'Error al leer JSON en ImportarServicios: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    SELECT TOP 1 @json = JsonDoc FROM #JsonRaw;

    IF @json IS NULL
    BEGIN
        PRINT 'ImportarServicios: archivo vacío o no legible.';
        RETURN;
    END


    /* 2) Tabla "ancha" con las columnas del JSON */
    CREATE TABLE #ServiciosRaw
    (
        NombreConsorcio NVARCHAR(200) NULL,
        Mes             NVARCHAR(50)  NULL,
        BANCARIOS       NVARCHAR(50)  NULL,
        LIMPIEZA        NVARCHAR(50)  NULL,
        ADMINISTRACION  NVARCHAR(50)  NULL,
        SEGUROS         NVARCHAR(50)  NULL,
        GASTOS_GENERALES NVARCHAR(50) NULL,
        SERV_PUB_Agua   NVARCHAR(50)  NULL,
        SERV_PUB_Luz    NVARCHAR(50)  NULL
    );

    INSERT INTO #ServiciosRaw
    (
        NombreConsorcio, Mes,
        BANCARIOS, LIMPIEZA, ADMINISTRACION, SEGUROS,
        GASTOS_GENERALES, SERV_PUB_Agua, SERV_PUB_Luz
    )
    SELECT
        [NombreConsorcio],
        Mes,
        BANCARIOS,
        LIMPIEZA,
        ADMINISTRACION,
        SEGUROS,
        [GASTOS GENERALES],
        [SERVICIOS PUBLICOS-Agua],
        [SERVICIOS PUBLICOS-Luz]
    FROM OPENJSON(@json)
    WITH
    (
        [NombreConsorcio]      NVARCHAR(200) '$."Nombre del consorcio"',
        Mes                    NVARCHAR(50)  '$.Mes',
        BANCARIOS              NVARCHAR(50)  '$.BANCARIOS',
        LIMPIEZA               NVARCHAR(50)  '$.LIMPIEZA',
        ADMINISTRACION         NVARCHAR(50)  '$.ADMINISTRACION',
        SEGUROS                NVARCHAR(50)  '$.SEGUROS',
        [GASTOS GENERALES]     NVARCHAR(50)  '$."GASTOS GENERALES"',
        [SERVICIOS PUBLICOS-Agua] NVARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"',
        [SERVICIOS PUBLICOS-Luz]  NVARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"'
    );


    /* 3) Pasar a tabla "larga": un servicio por fila + parsear importes */

    CREATE TABLE #ServiciosNorm
    (
        NombreConsorcio NVARCHAR(200) NOT NULL,
        Mes             NVARCHAR(50)  NOT NULL,
        Concepto        NVARCHAR(50)  NOT NULL,
        Importe         DECIMAL(18,2) NULL
    );

    INSERT INTO #ServiciosNorm (NombreConsorcio, Mes, Concepto, Importe)
    SELECT
        LTRIM(RTRIM(sr.NombreConsorcio)) AS NombreConsorcio,
        LTRIM(RTRIM(sr.Mes))             AS Mes,
        v.Concepto,
        /* Parseo robusto de importe (acepta "200,000.00" y "9.344,32") */
        CASE 
            WHEN TRY_CONVERT(DECIMAL(18,2),
                 REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(v.MontoRaw)), ' ', ''), '$',''), ',', '')
                 ) IS NOT NULL
            THEN TRY_CONVERT(DECIMAL(18,2),
                 REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(v.MontoRaw)), ' ', ''), '$',''), ',', '')
                 )
            ELSE TRY_CONVERT(DECIMAL(18,2),
                 REPLACE(
                    REPLACE(
                        REPLACE(LTRIM(RTRIM(v.MontoRaw)), ' ', ''),
                    '.', ''),
                 ',', '.')
                 )
        END AS Importe
    FROM #ServiciosRaw sr
    CROSS APPLY
    (
        VALUES
            ('BANCARIOS',             sr.BANCARIOS),
            ('LIMPIEZA',              sr.LIMPIEZA),
            ('ADMINISTRACION',        sr.ADMINISTRACION),
            ('SEGUROS',               sr.SEGUROS),
            ('GASTOS GENERALES',      sr.GASTOS_GENERALES),
            ('SERVICIOS PUBLICOS-Agua', sr.SERV_PUB_Agua),
            ('SERVICIOS PUBLICOS-Luz',  sr.SERV_PUB_Luz)
    ) AS v(Concepto, MontoRaw)
    WHERE LTRIM(RTRIM(ISNULL(sr.NombreConsorcio,''))) <> ''
      AND LTRIM(RTRIM(ISNULL(sr.Mes,''))) <> ''
      AND v.MontoRaw IS NOT NULL
      AND LTRIM(RTRIM(v.MontoRaw)) <> '';


    /* 4) Agregar periodo (YYYY-MM) y nombres de TipoGasto / TipoServicio */

    CREATE TABLE #ServiciosPeriodo
    (
        NombreConsorcio    NVARCHAR(200) NOT NULL,
        Periodo            CHAR(7)       NOT NULL, -- 'YYYY-MM'
        Concepto           NVARCHAR(50)  NOT NULL,
        Importe            DECIMAL(18,2) NULL,
        NombreTipoGasto    NVARCHAR(50)  NOT NULL,
        NombreTipoServicio NVARCHAR(50)  NOT NULL
    );

    INSERT INTO #ServiciosPeriodo
    (
        NombreConsorcio, Periodo, Concepto, Importe,
        NombreTipoGasto, NombreTipoServicio
    )
    SELECT
        sN.NombreConsorcio,
        -- Construcción de Periodo a partir de @Anio + Mes en castellano
        CONVERT(CHAR(7),
            DATEFROMPARTS(
                @Anio,
                CASE LOWER(LTRIM(RTRIM(sN.Mes)))
                    WHEN 'enero'   THEN 1
                    WHEN 'febrero' THEN 2
                    WHEN 'marzo'   THEN 3
                    WHEN 'abril'   THEN 4
                    WHEN 'mayo'    THEN 5
                    WHEN 'junio'   THEN 6
                    WHEN 'julio'   THEN 7
                    WHEN 'agosto'  THEN 8
                    WHEN 'septiembre' THEN 9
                    WHEN 'setiembre'  THEN 9
                    WHEN 'octubre' THEN 10
                    WHEN 'noviembre' THEN 11
                    WHEN 'diciembre' THEN 12
                    ELSE 1   -- fallback
                END,
                1
            ),
            126
        ) AS Periodo,
        sN.Concepto,
        sN.Importe,
        -- TipoGasto = parte izquierda del '-', o todo
        CASE 
            WHEN CHARINDEX('-', sN.Concepto) > 0
                THEN LTRIM(RTRIM(LEFT(sN.Concepto, CHARINDEX('-', sN.Concepto)-1)))
            ELSE LTRIM(RTRIM(sN.Concepto))
        END AS NombreTipoGasto,
        -- TipoServicio = parte derecha del '-', o el mismo nombre
        CASE 
            WHEN CHARINDEX('-', sN.Concepto) > 0
                THEN LTRIM(RTRIM(SUBSTRING(sN.Concepto, CHARINDEX('-', sN.Concepto)+1, 8000)))
            ELSE LTRIM(RTRIM(sN.Concepto))
        END AS NombreTipoServicio
    FROM #ServiciosNorm sN;


    /* 5) Cargar TipoGasto y TipoServicio faltantes */

    INSERT INTO Tabla.TipoGasto(nombre, descripcion_detalle)
    SELECT DISTINCT
        sp.NombreTipoGasto,
        NULL
    FROM #ServiciosPeriodo sp
    LEFT JOIN Tabla.TipoGasto tg
           ON tg.nombre = sp.NombreTipoGasto
    WHERE tg.id IS NULL;

    INSERT INTO Tabla.TipoServicio(nombre, descripcion_detalle)
    SELECT DISTINCT
        sp.NombreTipoServicio,
        NULL
    FROM #ServiciosPeriodo sp
    LEFT JOIN Tabla.TipoServicio ts
           ON ts.nombre = sp.NombreTipoServicio
    WHERE ts.id IS NULL;


    /* 6) Asegurar Expensas por (Consorcio, Periodo) */

    ;WITH ExpensasNecesarias AS
    (
        SELECT DISTINCT
            c.id   AS id_consorcio,
            sp.Periodo
        FROM #ServiciosPeriodo sp
        INNER JOIN Tabla.Consorcio c
            ON c.nombre = sp.NombreConsorcio
    )
    INSERT INTO Tabla.Expensa
        (id_consorcio, periodo, fecha_emision, vencimiento_1, vencimiento_2,
         forma_de_pago, saldo_anterior, interes_por_mora)
    SELECT
        eN.id_consorcio,
        eN.Periodo,
        DATEFROMPARTS(@Anio, CAST(SUBSTRING(eN.Periodo, 6, 2) AS INT), 1),
        NULL, NULL, NULL, NULL, NULL
    FROM ExpensasNecesarias eN
    LEFT JOIN Tabla.Expensa e
           ON e.id_consorcio = eN.id_consorcio
          AND e.periodo      = eN.Periodo
    WHERE e.id IS NULL;


    /* 7) Preparar filas finales para DetalleExpensa */

    CREATE TABLE #ServiciosDetalle
    (
        id_expensa        INT          NOT NULL,
        id_tipo_gasto     INT          NOT NULL,
        id_tipo_servicio  INT          NOT NULL,
        tipo_gasto        VARCHAR(50)  NULL,
        tipo_servicio     VARCHAR(50)  NULL,
        descripcion       VARCHAR(200) NULL,
        periodo_aplicacion CHAR(7)     NULL
    );

    INSERT INTO #ServiciosDetalle
    (
        id_expensa, id_tipo_gasto, id_tipo_servicio,
        tipo_gasto, tipo_servicio, descripcion, periodo_aplicacion
    )
    SELECT
        e.id               AS id_expensa,
        tg.id              AS id_tipo_gasto,
        ts.id              AS id_tipo_servicio,
        sp.NombreTipoGasto AS tipo_gasto,
        sp.NombreTipoServicio AS tipo_servicio,
        -- metemos el importe en la descripción para no perderlo
        LEFT(
          sp.Concepto + ' - Importe: ' + ISNULL(CONVERT(VARCHAR(30), sp.Importe), '0'),
          200
        ) AS descripcion,
        sp.Periodo         AS periodo_aplicacion
    FROM #ServiciosPeriodo sp
    INNER JOIN Tabla.Consorcio c
        ON c.nombre = sp.NombreConsorcio
    INNER JOIN Tabla.Expensa e
        ON e.id_consorcio = c.id
       AND e.periodo      = sp.Periodo
    INNER JOIN Tabla.TipoGasto tg
        ON tg.nombre = sp.NombreTipoGasto
    INNER JOIN Tabla.TipoServicio ts
        ON ts.nombre = sp.NombreTipoServicio;


    /* 8) MERGE a Tabla.DetalleExpensa para no duplicar */

    MERGE Tabla.DetalleExpensa AS T
    USING #ServiciosDetalle AS S
      ON T.id_expensa       = S.id_expensa
     AND T.id_tipo_gasto    = S.id_tipo_gasto
     AND T.id_tipo_servicio = S.id_tipo_servicio
     AND ISNULL(T.periodo_aplicacion,'') = ISNULL(S.periodo_aplicacion,'')
    WHEN MATCHED THEN
        UPDATE SET
            T.tipo_gasto        = S.tipo_gasto,
            T.tipo_servicio     = S.tipo_servicio,
            T.descripcion_detalle = S.descripcion
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (id_expensa, id_tipo_gasto, id_tipo_servicio,
                tipo_gasto, tipo_servicio, descripcion_detalle,
                periodo_aplicacion, es_cuota, nro_cuota_actual, total_cuotas)
        VALUES (S.id_expensa, S.id_tipo_gasto, S.id_tipo_servicio,
                S.tipo_gasto, S.tipo_servicio, S.descripcion,
                S.periodo_aplicacion, 0, NULL, NULL);

    PRINT 'ImportarServicios: proceso finalizado (TipoGasto, TipoServicio, Expensa y DetalleExpensa actualizados).';
END
GO