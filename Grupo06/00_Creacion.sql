-- 1 -SCRIPT DE CREACION

--DROP TABLAS
/*
DROP TABLE IF EXISTS Tabla.Factura;
DROP TABLE IF EXISTS Tabla.Pago;

DROP TABLE IF EXISTS Tabla.DetalleExpensa;
DROP TABLE IF EXISTS Tabla.TipoGasto;
DROP TABLE IF EXISTS Tabla.TipoServicio;

DROP TABLE IF EXISTS Tabla.Unidad_complementaria;
DROP TABLE IF EXISTS Tabla.Unidad_Funcional;
DROP TABLE IF EXISTS Tabla.Expensa;

DROP TABLE IF EXISTS Tabla.Persona;
DROP TABLE IF EXISTS Tabla.Proveedor;
DROP TABLE IF EXISTS Tabla.Consorcio;
*/

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G06')
	BEGIN
		CREATE DATABASE Com2900G06;
		PRINT 'Base de datos creada exitosamente';
	END;
GO
USE Com2900G06
GO
--Crear el Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Tabla')
	BEGIN
		EXEC('CREATE SCHEMA Tabla');
		PRINT ' Schema creado exitosamente';
	END;
go
--Creacion de las tablas
/*========================
=  TABLA: Consorcio
=========================*/
IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Consorcio')
BEGIN
CREATE TABLE Tabla.Consorcio (
	id INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50),
	direccion VARCHAR(100),
	cuit_administracion INT,
	cuenta_bancaria INT,
	opcion_limpieza TINYINT
)
END
/*========================
=  TABLA: Proveedor
=========================*/
go
IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Proveedor')
BEGIN
CREATE TABLE Tabla.Proveedor (
	id INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50),
	direccion VARCHAR(100),
	email VARCHAR(50),
	telefono VARCHAR(20)
)
END
go
/*========================
=  TABLA: Persona
=========================*/
IF NOT EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Persona')
BEGIN
CREATE TABLE Tabla.Persona (
	dni VARCHAR(10) PRIMARY KEY,
	nombre VARCHAR(50),
	apellido VARCHAR(50),
	email VARCHAR(50),
	telefono VARCHAR(20),
	CVU_CBU VARCHAR(30),
	inquilino VARCHAR(50),
	Fecha_Inicio DATE,
	Fecha_Fin DATE
)
END
go

/*========================
=  TABLA: Expensa
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Expensa'
)
BEGIN
    CREATE TABLE Tabla.Expensa (
        id               INT IDENTITY(1,1) PRIMARY KEY,
        id_consorcio     INT              NOT NULL,
        periodo          VARCHAR(7)       NOT NULL,   -- p.ej. '2025-10'
        fecha_emision    DATE             NULL,
        vencimiento_1    DATE             NULL,
        vencimiento_2    DATE             NULL,
        forma_de_pago    VARCHAR(50)      NULL,
        saldo_anterior   DECIMAL(12,2)    NULL,
        interes_por_mora DECIMAL(6,2)     NULL,
        CONSTRAINT FK_Expensa_Consorcio
            FOREIGN KEY (id_consorcio) REFERENCES Tabla.Consorcio(id)
    );
END
GO

/*========================
=  TABLA: Unidad_Funcional
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Unidad_Funcional'
)
BEGIN
    CREATE TABLE Tabla.Unidad_Funcional (
        id                    INT IDENTITY(1,1) PRIMARY KEY,
        id_Consorcio           INT          NULL,           
        dni_Persona           VARCHAR(10)  NULL,
        nro_Unidad_Funcional  INT NULL,
        piso                  VARCHAR(10)  NULL,
        depto                 VARCHAR(10)  NULL,
        porcentaje_prorrateo  DECIMAL(6,3) NULL,
        superficie            DECIMAL(10,2) NULL,
        CONSTRAINT FK_UF_Consorcio
            FOREIGN KEY (id_Consorcio)  REFERENCES Tabla.Consorcio(id),
        CONSTRAINT FK_UF_Persona
            FOREIGN KEY (dni_Persona) REFERENCES Tabla.Persona(dni)
    );
END
GO

/*========================
=  TABLA: Unidad_complementaria
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Unidad_complementaria'
)
BEGIN
    CREATE TABLE Tabla.Unidad_complementaria (
        id                       INT IDENTITY(1,1) PRIMARY KEY,
        id_uf                    INT           NOT NULL,
        baulera                  INT           NULL,
        cochera                  INT           NULL,
        superficie_baulera       DECIMAL(10,2) NULL,
        superficie_cochera       DECIMAL(10,2) NULL,
        CONSTRAINT FK_UC_UF
            FOREIGN KEY (id_uf) REFERENCES Tabla.Unidad_Funcional(id)
    );
END
GO

/*========================
=  TABLA: TipoServicio
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'TipoServicio'
)
BEGIN
    CREATE TABLE Tabla.TipoServicio (
        id                      INT IDENTITY(1,1)  PRIMARY KEY,
        nombre                  VARCHAR(50),
        descripcion_detalle     VARCHAR(50)
        );
END
GO

/*========================
=  TABLA: TipoGasto
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'TipoGasto'
)
BEGIN
    CREATE TABLE Tabla.TipoGasto (
        id                      INT IDENTITY(1,1) PRIMARY KEY,
        nombre                  VARCHAR(50),
        descripcion_detalle     VARCHAR(50)
        );
END
GO

/*========================
=  TABLA: DetalleExpensa
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'DetalleExpensa'
)
BEGIN
    CREATE TABLE Tabla.DetalleExpensa (
        id                  INT IDENTITY(1,1) PRIMARY KEY,
        id_expensa          INT          NOT NULL,
        id_tipo_gasto       INT          NOT NULL,
        id_tipo_servicio    INT          NOT NULL,
        tipo_gasto          VARCHAR(50)  NULL,
        tipo_servicio       VARCHAR(50)  NULL,
        descripcion_detalle VARCHAR(200) NULL,
        periodo_aplicacion  VARCHAR(7)   NULL,     -- p.ej. '2025-10'
        es_cuota            BIT          NULL,
        nro_cuota_actual    INT          NULL,
        total_cuotas        INT          NULL,
        CONSTRAINT FK_Detalle_Expensa
            FOREIGN KEY (id_expensa) REFERENCES Tabla.Expensa(id),
        CONSTRAINT FK_Tipo_Gasto
            FOREIGN KEY (id_tipo_gasto) REFERENCES Tabla.TipoGasto(id),
        CONSTRAINT FK_Tipo_Servicio
            FOREIGN KEY (id_tipo_servicio) REFERENCES Tabla.TipoServicio(id)
    );
END
GO

/*========================
=  TABLA: Pago
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Pago'
)
BEGIN
    CREATE TABLE Tabla.Pago (
        id         INT IDENTITY(1,1) PRIMARY KEY,
        id_expensa INT          NOT NULL,
        fecha      DATE         NOT NULL,
        CVU_CBU    VARCHAR(30)          NULL,  
        importe    DECIMAL(12,2) NOT NULL,
        CONSTRAINT FK_Pago_Expensa
            FOREIGN KEY (id_expensa) REFERENCES Tabla.Expensa(id)
    );
END
GO

/*========================
=  TABLA: Factura
=========================*/
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Tabla' AND TABLE_NAME = 'Factura'
)
BEGIN
    CREATE TABLE Tabla.Factura (
        id                 INT IDENTITY(1,1) PRIMARY KEY,
        id_proveedor       INT           NOT NULL,
        id_detalleexpensa  INT           NOT NULL,
        nro                VARCHAR(30)   NOT NULL,
        fecha              DATE          NOT NULL,
        importe            DECIMAL(12,2) NOT NULL,
        CONSTRAINT FK_Factura_Proveedor
            FOREIGN KEY (id_proveedor)      REFERENCES Tabla.Proveedor(id),
        CONSTRAINT FK_Factura_Detalle
            FOREIGN KEY (id_detalleexpensa) REFERENCES Tabla.DetalleExpensa(id),
        CONSTRAINT UQ_Factura_Proveedor_Nro UNIQUE (id_proveedor, nro)
    );
END
GO

--Crear Schema para unicamente SP
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Procedimientos')
BEGIN
  EXEC('CREATE SCHEMA Procedimientos');
END
GO
----------------
 --SP PERSONA--
----------------
-- INSERTAR PERSONA
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'insertarPersona' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.insertarPersona;
GO
CREATE PROCEDURE Procedimientos.insertarPersona
  @dni          VARCHAR(10),
  @nombre       VARCHAR(50),
  @apellido     VARCHAR(50),
  @email        VARCHAR(50),
  @telefono     VARCHAR(20),
  @CVU_CBU      VARCHAR(30),
  @inquilino    VARCHAR(50) = NULL,
  @Fecha_Inicio DATE = NULL,
  @Fecha_Fin    DATE = NULL
AS
BEGIN
  IF @dni IS NULL OR @nombre IS NULL OR @apellido IS NULL
  BEGIN PRINT 'Error: dni, nombre y apellido son obligatorios'; RETURN; END;

  IF EXISTS (SELECT 1 FROM Tabla.Persona WHERE dni=@dni)
  BEGIN PRINT 'Error: Persona ya existente'; RETURN; END;

  IF @Fecha_Inicio IS NOT NULL AND @Fecha_Fin IS NOT NULL AND @Fecha_Fin < @Fecha_Inicio
  BEGIN PRINT 'Error: Fecha_Fin no puede ser anterior a Fecha_Inicio'; RETURN; END;

  INSERT INTO Tabla.Persona(dni,nombre,apellido,email,telefono,CVU_CBU,inquilino,Fecha_Inicio,Fecha_Fin)
  VALUES(@dni,@nombre,@apellido,@email,@telefono,@CVU_CBU,@inquilino,@Fecha_Inicio,@Fecha_Fin);

  PRINT 'Persona insertada correctamente';
END
GO

-- MODIFICAR PERSONA
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'modificarPersona' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.modificarPersona;
GO
CREATE PROCEDURE Procedimientos.modificarPersona
  @dni          VARCHAR(10),
  @nombre       VARCHAR(50),
  @apellido     VARCHAR(50),
  @email        VARCHAR(50),
  @telefono     VARCHAR(20),
  @CVU_CBU      VARCHAR(30),
  @inquilino    VARCHAR(50) = NULL,
  @Fecha_Inicio DATE = NULL,
  @Fecha_Fin    DATE = NULL
AS
BEGIN
  IF @dni IS NULL
  BEGIN PRINT 'Error: dni es obligatorio'; RETURN; END;

  IF NOT EXISTS (SELECT 1 FROM Tabla.Persona WHERE dni=@dni)
  BEGIN PRINT 'Error: Persona no encontrada'; RETURN; END;

  IF @Fecha_Inicio IS NOT NULL AND @Fecha_Fin IS NOT NULL AND @Fecha_Fin < @Fecha_Inicio
  BEGIN PRINT 'Error: Fecha_Fin no puede ser anterior a Fecha_Inicio'; RETURN; END;

  UPDATE Tabla.Persona
  SET nombre=@nombre, apellido=@apellido, email=@email, telefono=@telefono,
      CVU_CBU=@CVU_CBU, inquilino=@inquilino, Fecha_Inicio=@Fecha_Inicio, Fecha_Fin=@Fecha_Fin
  WHERE dni=@dni;

  PRINT 'Persona modificada correctamente';
END
GO

-- ELIMINAR PERSONA
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'eliminarPersona' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.eliminarPersona;
GO
CREATE PROCEDURE Procedimientos.eliminarPersona
  @dni VARCHAR(10)
AS
BEGIN
  IF @dni IS NULL
  BEGIN PRINT 'Error: dni es obligatorio'; RETURN; END;

  IF NOT EXISTS (SELECT 1 FROM Tabla.Persona WHERE dni=@dni)
  BEGIN PRINT 'Error: Persona no encontrada'; RETURN; END;

  DELETE FROM Tabla.Persona WHERE dni=@dni;

  PRINT 'Persona eliminada correctamente';
END
GO
----------------
--SP PROVEEDOR--
----------------
-- INSERTAR PROVEEDOR
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name='insertarProveedor' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.insertarProveedor;
GO
CREATE PROCEDURE Procedimientos.insertarProveedor
  @nombre    VARCHAR(50),
  @direccion VARCHAR(100)=NULL,
  @email     VARCHAR(50)=NULL,
  @telefono  VARCHAR(20)=NULL
AS
BEGIN
  IF @nombre IS NULL BEGIN PRINT 'Error: nombre es obligatorio'; RETURN; END;

  INSERT INTO Tabla.Proveedor(nombre,direccion,email,telefono)
  VALUES(@nombre,@direccion,@email,@telefono);

  PRINT 'Proveedor insertado correctamente';
END
GO

-- MODIFICAR PROVEEDOR
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name='modificarProveedor' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.modificarProveedor;
GO
CREATE PROCEDURE Procedimientos.modificarProveedor
  @id        INT,
  @nombre    VARCHAR(50),
  @direccion VARCHAR(100)=NULL,
  @email     VARCHAR(50)=NULL,
  @telefono  VARCHAR(20)=NULL
AS
BEGIN
  IF @id IS NULL BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;
  IF NOT EXISTS (SELECT 1 FROM Tabla.Proveedor WHERE id=@id)
  BEGIN PRINT 'Error: Proveedor no encontrado'; RETURN; END;

  UPDATE Tabla.Proveedor
  SET nombre=@nombre, direccion=@direccion, email=@email, telefono=@telefono
  WHERE id=@id;

  PRINT 'Proveedor modificado correctamente';
END
GO

-- ELIMINAR PROVEEDOR
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name='eliminarProveedor' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.eliminarProveedor;
GO
CREATE PROCEDURE Procedimientos.eliminarProveedor
  @id INT
AS
BEGIN
  IF @id IS NULL BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;
  IF NOT EXISTS (SELECT 1 FROM Tabla.Proveedor WHERE id=@id)
  BEGIN PRINT 'Error: Proveedor no encontrado'; RETURN; END;

  DELETE FROM Tabla.Proveedor WHERE id=@id;

  PRINT 'Proveedor eliminado correctamente';
END
GO
----------------
 --SP EXPENSA--
----------------
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name='insertarExpensa' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.insertarExpensa;
GO
CREATE PROCEDURE Procedimientos.insertarExpensa
  @id_consorcio     INT,
  @periodo          VARCHAR(7),
  @fecha_emision    DATE = NULL,
  @vencimiento_1    DATE = NULL,
  @vencimiento_2    DATE = NULL,
  @forma_de_pago    VARCHAR(50) = NULL,
  @saldo_anterior   DECIMAL(12,2) = NULL,
  @interes_por_mora DECIMAL(6,2) = NULL
AS
BEGIN
  IF @id_consorcio IS NULL OR @periodo IS NULL
  BEGIN PRINT 'Error: id_consorcio y periodo son obligatorios'; RETURN; END;

  IF NOT EXISTS (SELECT 1 FROM Tabla.Consorcio WHERE id=@id_consorcio)
  BEGIN PRINT 'Error: Consorcio no existe'; RETURN; END;

  INSERT INTO Tabla.Expensa(id_consorcio,periodo,fecha_emision,vencimiento_1,vencimiento_2,
                            forma_de_pago,saldo_anterior,interes_por_mora)
  VALUES(@id_consorcio,@periodo,@fecha_emision,@vencimiento_1,@vencimiento_2,
         @forma_de_pago,@saldo_anterior,@interes_por_mora);

  PRINT 'Expensa insertada correctamente';
END
GO

-- MODIFICAR EXPENSA
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name='modificarExpensa' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.modificarExpensa;
GO
CREATE PROCEDURE Procedimientos.modificarExpensa
  @id               INT,
  @id_consorcio     INT,
  @periodo          VARCHAR(7),
  @fecha_emision    DATE = NULL,
  @vencimiento_1    DATE = NULL,
  @vencimiento_2    DATE = NULL,
  @forma_de_pago    VARCHAR(50) = NULL,
  @saldo_anterior   DECIMAL(12,2) = NULL,
  @interes_por_mora DECIMAL(6,2) = NULL
AS
BEGIN
  IF @id IS NULL BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;
  IF NOT EXISTS (SELECT 1 FROM Tabla.Expensa WHERE id=@id)
  BEGIN PRINT 'Error: Expensa no encontrada'; RETURN; END;
  IF NOT EXISTS (SELECT 1 FROM Tabla.Consorcio WHERE id=@id_consorcio)
  BEGIN PRINT 'Error: Consorcio no existe'; RETURN; END;

  UPDATE Tabla.Expensa
  SET id_consorcio=@id_consorcio, periodo=@periodo, fecha_emision=@fecha_emision,
      vencimiento_1=@vencimiento_1, vencimiento_2=@vencimiento_2,
      forma_de_pago=@forma_de_pago, saldo_anterior=@saldo_anterior,
      interes_por_mora=@interes_por_mora
  WHERE id=@id;

  PRINT 'Expensa modificada correctamente';
END
GO

-- ELIMINAR EXPENSA
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name='eliminarExpensa' AND SCHEMA_NAME(schema_id)='Procedimientos')
  DROP PROCEDURE Procedimientos.eliminarExpensa;
GO
CREATE PROCEDURE Procedimientos.eliminarExpensa
  @id INT
AS
BEGIN
  IF @id IS NULL BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;
  IF NOT EXISTS (SELECT 1 FROM Tabla.Expensa WHERE id=@id)
  BEGIN PRINT 'Error: Expensa no encontrada'; RETURN; END;

  DELETE FROM Tabla.Expensa WHERE id=@id;

  PRINT 'Expensa eliminada correctamente';
END
GO
----------------
 --SP PAGO--
----------------
IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarPago' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarPago;
GO
CREATE PROCEDURE Procedimientos.insertarPago
    @id_expensa INT,
    @fecha      DATE,
    @CVU_CBU    VARCHAR(30),
    @importe    DECIMAL(12,2)
AS
BEGIN
    IF @id_expensa IS NULL OR @fecha IS NULL OR @importe IS NULL
    BEGIN PRINT 'Error: id_expensa, fecha e importe son obligatorios'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Expensa WHERE id=@id_expensa)
    BEGIN PRINT 'Error: Expensa no existe'; RETURN; END;

    IF @importe < 0
    BEGIN PRINT 'Error: importe no puede ser negativo'; RETURN; END;

    INSERT INTO Tabla.Pago (id_expensa,fecha,CVU_CBU,importe)
    VALUES (@id_expensa,@fecha,@CVU_CBU,@importe);

    PRINT 'Pago insertado correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarPago' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarPago;
GO
CREATE PROCEDURE Procedimientos.modificarPago
    @id         INT,
    @id_expensa INT,
    @fecha      DATE,
    @CVU_CBU    VARCHAR(30),
    @importe    DECIMAL(12,2)
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Pago WHERE id=@id)
    BEGIN PRINT 'Error: Pago no encontrado'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Expensa WHERE id=@id_expensa)
    BEGIN PRINT 'Error: Expensa no existe'; RETURN; END;

    IF @importe < 0
    BEGIN PRINT 'Error: importe no puede ser negativo'; RETURN; END;

    UPDATE Tabla.Pago
       SET id_expensa = @id_expensa,
           fecha      = @fecha,
           CVU_CBU    = @CVU_CBU,
           importe    = @importe
     WHERE id=@id;

    PRINT 'Pago modificado correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarPago' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarPago;
GO
CREATE PROCEDURE Procedimientos.eliminarPago
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Pago WHERE id=@id)
    BEGIN PRINT 'Error: Pago no encontrado'; RETURN; END;

    DELETE FROM Tabla.Pago WHERE id=@id;

    PRINT 'Pago eliminado correctamente';
END
GO----------------
--SP CONSORCIO--
----------------
IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarConsorcio' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarConsorcio;
GO
CREATE PROCEDURE Procedimientos.insertarConsorcio
    @nombre             VARCHAR(50),
    @direccion          VARCHAR(100) = NULL,
    @cuit_administracion INT        = NULL,
    @cuenta_bancaria     INT        = NULL,
    @opcion_limpieza     TINYINT    = NULL
AS
BEGIN
    IF @nombre IS NULL
    BEGIN PRINT 'Error: nombre es obligatorio'; RETURN; END;

    IF @opcion_limpieza IS NOT NULL AND @opcion_limpieza NOT IN (0,1)
    BEGIN PRINT 'Error: opcion_limpieza debe ser 0 o 1'; RETURN; END;

    INSERT INTO Tabla.Consorcio (nombre,direccion,cuit_administracion,cuenta_bancaria,opcion_limpieza)
    VALUES (@nombre,@direccion,@cuit_administracion,@cuenta_bancaria,@opcion_limpieza);

    PRINT 'Consorcio insertado correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarConsorcio' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarConsorcio;
GO
CREATE PROCEDURE Procedimientos.modificarConsorcio
    @id                 INT,
    @nombre             VARCHAR(50),
    @direccion          VARCHAR(100) = NULL,
    @cuit_administracion INT        = NULL,
    @cuenta_bancaria     INT        = NULL,
    @opcion_limpieza     TINYINT    = NULL
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Consorcio WHERE id=@id)
    BEGIN PRINT 'Error: Consorcio no encontrado'; RETURN; END;

    IF @opcion_limpieza IS NOT NULL AND @opcion_limpieza NOT IN (0,1)
    BEGIN PRINT 'Error: opcion_limpieza debe ser 0 o 1'; RETURN; END;

    UPDATE Tabla.Consorcio
       SET nombre=@nombre,
           direccion=@direccion,
           cuit_administracion=@cuit_administracion,
           cuenta_bancaria=@cuenta_bancaria,
           opcion_limpieza=@opcion_limpieza
     WHERE id=@id;

    PRINT 'Consorcio modificado correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarConsorcio' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarConsorcio;
GO
CREATE PROCEDURE Procedimientos.eliminarConsorcio
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Consorcio WHERE id=@id)
    BEGIN PRINT 'Error: Consorcio no encontrado'; RETURN; END;

    DELETE FROM Tabla.Consorcio WHERE id=@id;

    PRINT 'Consorcio eliminado correctamente';
END
GO

-----------------------
--SP UNIDAD FUNCIONAL--
-----------------------
IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarUnidadFuncional' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarUnidadFuncional;
GO
CREATE PROCEDURE Procedimientos.insertarUnidadFuncional
    @id_Consorcio          INT          = NULL,
    @dni_Persona           VARCHAR(10),
    @nro_Unidad_Funcional  INT          = NULL,
    @piso                  VARCHAR(10)  = NULL,
    @depto                 VARCHAR(10)  = NULL,
    @porcentaje_prorrateo  DECIMAL(6,3) = NULL,
    @superficie            DECIMAL(10,2)= NULL
AS
BEGIN
    IF @dni_Persona IS NULL
    BEGIN PRINT 'Error: dni_Persona es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Persona WHERE dni=@dni_Persona)
    BEGIN PRINT 'Error: Persona no existe'; RETURN; END;

    IF @id_Consorcio IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM Tabla.Consorcio WHERE id=@id_Consorcio)
    BEGIN PRINT 'Error: Consorcio no existe'; RETURN; END;

    INSERT INTO Tabla.Unidad_Funcional
        (id_Consorcio,dni_Persona,nro_Unidad_Funcional,piso,depto,porcentaje_prorrateo,superficie)
    VALUES
        (@id_Consorcio,@dni_Persona,@nro_Unidad_Funcional,@piso,@depto,@porcentaje_prorrateo,@superficie);

    PRINT 'Unidad_Funcional insertada correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarUnidadFuncional' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarUnidadFuncional;
GO
CREATE PROCEDURE Procedimientos.modificarUnidadFuncional
    @id                    INT,
    @id_Consorcio          INT          = NULL,
    @dni_Persona           VARCHAR(10),
    @nro_Unidad_Funcional  INT          = NULL,
    @piso                  VARCHAR(10)  = NULL,
    @depto                 VARCHAR(10)  = NULL,
    @porcentaje_prorrateo  DECIMAL(6,3) = NULL,
    @superficie            DECIMAL(10,2)= NULL
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Unidad_Funcional WHERE id=@id)
    BEGIN PRINT 'Error: Unidad_Funcional no encontrada'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Persona WHERE dni=@dni_Persona)
    BEGIN PRINT 'Error: Persona no existe'; RETURN; END;

    IF @id_Consorcio IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM Tabla.Consorcio WHERE id=@id_Consorcio)
    BEGIN PRINT 'Error: Consorcio no existe'; RETURN; END;

    UPDATE Tabla.Unidad_Funcional
       SET id_Consorcio         = @id_Consorcio,
           dni_Persona          = @dni_Persona,
           nro_Unidad_Funcional = @nro_Unidad_Funcional,
           piso                 = @piso,
           depto                = @depto,
           porcentaje_prorrateo = @porcentaje_prorrateo,
           superficie           = @superficie
     WHERE id=@id;

    PRINT 'Unidad_Funcional modificada correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarUnidadFuncional' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarUnidadFuncional;
GO
CREATE PROCEDURE Procedimientos.eliminarUnidadFuncional
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Unidad_Funcional WHERE id=@id)
    BEGIN PRINT 'Error: Unidad_Funcional no encontrada'; RETURN; END;

    DELETE FROM Tabla.Unidad_Funcional WHERE id=@id;

    PRINT 'Unidad_Funcional eliminada correctamente';
END
GO

----------------------------
--SP UNIDAD COMPLEMENTARIA--
----------------------------
IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarUnidadComplementaria' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarUnidadComplementaria;
GO
CREATE PROCEDURE Procedimientos.insertarUnidadComplementaria
    @id_uf              INT,
    @baulera            INT           = NULL,
    @cochera            INT           = NULL,
    @superficie_baulera DECIMAL(10,2) = NULL,
    @superficie_cochera DECIMAL(10,2) = NULL
AS
BEGIN
    IF @id_uf IS NULL
    BEGIN PRINT 'Error: id_uf es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Unidad_Funcional WHERE id=@id_uf)
    BEGIN PRINT 'Error: Unidad_Funcional no existe'; RETURN; END;

    INSERT INTO Tabla.Unidad_complementaria
        (id_uf,baulera,cochera,superficie_baulera,superficie_cochera)
    VALUES
        (@id_uf,@baulera,@cochera,@superficie_baulera,@superficie_cochera);

    PRINT 'Unidad_complementaria insertada correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarUnidadComplementaria' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarUnidadComplementaria;
GO
CREATE PROCEDURE Procedimientos.modificarUnidadComplementaria
    @id                 INT,
    @id_uf              INT,
    @baulera            INT           = NULL,
    @cochera            INT           = NULL,
    @superficie_baulera DECIMAL(10,2) = NULL,
    @superficie_cochera DECIMAL(10,2) = NULL
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Unidad_complementaria WHERE id=@id)
    BEGIN PRINT 'Error: Unidad_complementaria no encontrada'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Unidad_Funcional WHERE id=@id_uf)
    BEGIN PRINT 'Error: Unidad_Funcional no existe'; RETURN; END;

    UPDATE Tabla.Unidad_complementaria
       SET id_uf              = @id_uf,
           baulera            = @baulera,
           cochera            = @cochera,
           superficie_baulera = @superficie_baulera,
           superficie_cochera = @superficie_cochera
     WHERE id=@id;

    PRINT 'Unidad_complementaria modificada correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarUnidadComplementaria' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarUnidadComplementaria;
GO
CREATE PROCEDURE Procedimientos.eliminarUnidadComplementaria
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Unidad_complementaria WHERE id=@id)
    BEGIN PRINT 'Error: Unidad_complementaria no encontrada'; RETURN; END;

    DELETE FROM Tabla.Unidad_complementaria WHERE id=@id;

    PRINT 'Unidad_complementaria eliminada correctamente';
END
GO

----------------------
--SP DETALLE EXPENSA--
----------------------
IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarDetalleExpensa' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarDetalleExpensa;
GO
CREATE PROCEDURE Procedimientos.insertarDetalleExpensa
    @id_expensa          INT,
    @id_tipo_gasto       INT,
    @id_tipo_servicio    INT,
    @tipo_gasto          VARCHAR(50)  = NULL,
    @tipo_servicio       VARCHAR(50)  = NULL,
    @descripcion_detalle VARCHAR(200) = NULL,
    @periodo_aplicacion  VARCHAR(7)   = NULL,
    @es_cuota            BIT          = NULL,
    @nro_cuota_actual    INT          = NULL,
    @total_cuotas        INT          = NULL
AS
BEGIN
    IF @id_expensa IS NULL OR @id_tipo_gasto IS NULL OR @id_tipo_servicio IS NULL
    BEGIN PRINT 'Error: id_expensa, id_tipo_gasto e id_tipo_servicio son obligatorios'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Expensa WHERE id=@id_expensa)
    BEGIN PRINT 'Error: Expensa no existe'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoGasto WHERE id=@id_tipo_gasto)
    BEGIN PRINT 'Error: TipoGasto no existe'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoServicio WHERE id=@id_tipo_servicio)
    BEGIN PRINT 'Error: TipoServicio no existe'; RETURN; END;

    IF ISNULL(@es_cuota,0)=1
    BEGIN
        IF @total_cuotas IS NULL OR @total_cuotas <= 0
        BEGIN PRINT 'Error: total_cuotas debe ser > 0 cuando es_cuota=1'; RETURN; END;

        IF @nro_cuota_actual IS NULL OR @nro_cuota_actual NOT BETWEEN 1 AND @total_cuotas
        BEGIN PRINT 'Error: nro_cuota_actual debe estar entre 1 y total_cuotas'; RETURN; END;
    END

    INSERT INTO Tabla.DetalleExpensa
        (id_expensa,id_tipo_gasto,id_tipo_servicio,tipo_gasto,tipo_servicio,
         descripcion_detalle,periodo_aplicacion,es_cuota,nro_cuota_actual,total_cuotas)
    VALUES
        (@id_expensa,@id_tipo_gasto,@id_tipo_servicio,@tipo_gasto,@tipo_servicio,
         @descripcion_detalle,@periodo_aplicacion,@es_cuota,@nro_cuota_actual,@total_cuotas);

    PRINT 'DetalleExpensa insertado correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarDetalleExpensa' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarDetalleExpensa;
GO
CREATE PROCEDURE Procedimientos.modificarDetalleExpensa
    @id                  INT,
    @id_expensa          INT,
    @id_tipo_gasto       INT,
    @id_tipo_servicio    INT,
    @tipo_gasto          VARCHAR(50)  = NULL,
    @tipo_servicio       VARCHAR(50)  = NULL,
    @descripcion_detalle VARCHAR(200) = NULL,
    @periodo_aplicacion  VARCHAR(7)   = NULL,
    @es_cuota            BIT          = NULL,
    @nro_cuota_actual    INT          = NULL,
    @total_cuotas        INT          = NULL
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.DetalleExpensa WHERE id=@id)
    BEGIN PRINT 'Error: DetalleExpensa no encontrado'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Expensa WHERE id=@id_expensa)
    BEGIN PRINT 'Error: Expensa no existe'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoGasto WHERE id=@id_tipo_gasto)
    BEGIN PRINT 'Error: TipoGasto no existe'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoServicio WHERE id=@id_tipo_servicio)
    BEGIN PRINT 'Error: TipoServicio no existe'; RETURN; END;

    IF ISNULL(@es_cuota,0)=1
    BEGIN
        IF @total_cuotas IS NULL OR @total_cuotas <= 0
        BEGIN PRINT 'Error: total_cuotas debe ser > 0 cuando es_cuota=1'; RETURN; END;

        IF @nro_cuota_actual IS NULL OR @nro_cuota_actual NOT BETWEEN 1 AND @total_cuotas
        BEGIN PRINT 'Error: nro_cuota_actual debe estar entre 1 y total_cuotas'; RETURN; END;
    END

    UPDATE Tabla.DetalleExpensa
       SET id_expensa          = @id_expensa,
           id_tipo_gasto       = @id_tipo_gasto,
           id_tipo_servicio    = @id_tipo_servicio,
           tipo_gasto          = @tipo_gasto,
           tipo_servicio       = @tipo_servicio,
           descripcion_detalle = @descripcion_detalle,
           periodo_aplicacion  = @periodo_aplicacion,
           es_cuota            = @es_cuota,
           nro_cuota_actual    = @nro_cuota_actual,
           total_cuotas        = @total_cuotas
     WHERE id=@id;

    PRINT 'DetalleExpensa modificado correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarDetalleExpensa' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarDetalleExpensa;
GO
CREATE PROCEDURE Procedimientos.eliminarDetalleExpensa
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.DetalleExpensa WHERE id=@id)
    BEGIN PRINT 'Error: DetalleExpensa no encontrado'; RETURN; END;

    DELETE FROM Tabla.DetalleExpensa WHERE id=@id;

    PRINT 'DetalleExpensa eliminado correctamente';
END
GO

--------------
--SP FACTURA--
--------------
IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarFactura' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarFactura;
GO
CREATE PROCEDURE Procedimientos.insertarFactura
    @id_proveedor      INT,
    @id_detalleexpensa INT,
    @nro               VARCHAR(30),
    @fecha             DATE,
    @importe           DECIMAL(12,2)
AS
BEGIN
    IF @id_proveedor IS NULL OR @id_detalleexpensa IS NULL OR
       @nro IS NULL OR @fecha IS NULL OR @importe IS NULL
    BEGIN PRINT 'Error: proveedor, detalle, nro, fecha e importe son obligatorios'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Proveedor WHERE id=@id_proveedor)
    BEGIN PRINT 'Error: Proveedor no existe'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.DetalleExpensa WHERE id=@id_detalleexpensa)
    BEGIN PRINT 'Error: DetalleExpensa no existe'; RETURN; END;

    IF @importe < 0
    BEGIN PRINT 'Error: importe no puede ser negativo'; RETURN; END;

    IF EXISTS (SELECT 1 FROM Tabla.Factura 
               WHERE id_proveedor=@id_proveedor AND nro=@nro)
    BEGIN PRINT 'Error: ya existe una factura con ese nro para el proveedor'; RETURN; END;

    INSERT INTO Tabla.Factura (id_proveedor,id_detalleexpensa,nro,fecha,importe)
    VALUES (@id_proveedor,@id_detalleexpensa,@nro,@fecha,@importe);

    PRINT 'Factura insertada correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarFactura' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarFactura;
GO
CREATE PROCEDURE Procedimientos.modificarFactura
    @id                INT,
    @id_proveedor      INT,
    @id_detalleexpensa INT,
    @nro               VARCHAR(30),
    @fecha             DATE,
    @importe           DECIMAL(12,2)
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Factura WHERE id=@id)
    BEGIN PRINT 'Error: Factura no encontrada'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Proveedor WHERE id=@id_proveedor)
    BEGIN PRINT 'Error: Proveedor no existe'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.DetalleExpensa WHERE id=@id_detalleexpensa)
    BEGIN PRINT 'Error: DetalleExpensa no existe'; RETURN; END;

    IF @importe < 0
    BEGIN PRINT 'Error: importe no puede ser negativo'; RETURN; END;

    IF EXISTS (SELECT 1 FROM Tabla.Factura 
               WHERE id_proveedor=@id_proveedor AND nro=@nro AND id<>@id)
    BEGIN PRINT 'Error: ya existe otra factura con ese nro para el proveedor'; RETURN; END;

    UPDATE Tabla.Factura
       SET id_proveedor      = @id_proveedor,
           id_detalleexpensa = @id_detalleexpensa,
           nro               = @nro,
           fecha             = @fecha,
           importe           = @importe
     WHERE id=@id;

    PRINT 'Factura modificada correctamente';
END
GO

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarFactura' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarFactura;
GO
CREATE PROCEDURE Procedimientos.eliminarFactura
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN PRINT 'Error: id es obligatorio'; RETURN; END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.Factura WHERE id=@id)
    BEGIN PRINT 'Error: Factura no encontrada'; RETURN; END;

    DELETE FROM Tabla.Factura WHERE id=@id;

    PRINT 'Factura eliminada correctamente';
END
GO
-----------------
--SP TIPO GASTO--
-----------------
IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarTipoGasto' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarTipoGasto;
GO
CREATE PROCEDURE Procedimientos.insertarTipoGasto
    @nombre              VARCHAR(50),
    @descripcion_detalle VARCHAR(50) = NULL
AS
BEGIN

    IF @nombre IS NULL
    BEGIN
        PRINT 'Error: nombre es obligatorio';
        RETURN;
    END;


    IF EXISTS (SELECT 1 FROM Tabla.TipoGasto WHERE nombre = @nombre)
    BEGIN
        PRINT 'Error: ya existe un TipoGasto con ese nombre';
        RETURN;
    END;

    INSERT INTO Tabla.TipoGasto (nombre, descripcion_detalle)
    VALUES (@nombre, @descripcion_detalle);

    PRINT 'TipoGasto insertado correctamente';
END
GO


IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarTipoGasto' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarTipoGasto;
GO
CREATE PROCEDURE Procedimientos.modificarTipoGasto
    @id                  INT,
    @nombre              VARCHAR(50),
    @descripcion_detalle VARCHAR(50) = NULL
AS
BEGIN
    IF @id IS NULL
    BEGIN
        PRINT 'Error: id es obligatorio';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoGasto WHERE id = @id)
    BEGIN
        PRINT 'Error: TipoGasto no encontrado';
        RETURN;
    END;

    IF @nombre IS NULL
    BEGIN
        PRINT 'Error: nombre es obligatorio';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM Tabla.TipoGasto 
               WHERE nombre = @nombre AND id <> @id)
    BEGIN
        PRINT 'Error: ya existe otro TipoGasto con ese nombre';
        RETURN;
    END;

    UPDATE Tabla.TipoGasto
       SET nombre = @nombre,
           descripcion_detalle = @descripcion_detalle
     WHERE id = @id;

    PRINT 'TipoGasto modificado correctamente';
END
GO


IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarTipoGasto' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarTipoGasto;
GO
CREATE PROCEDURE Procedimientos.eliminarTipoGasto
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN
        PRINT 'Error: id es obligatorio';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoGasto WHERE id = @id)
    BEGIN
        PRINT 'Error: TipoGasto no encontrado';
        RETURN;
    END;


    IF EXISTS (SELECT 1 FROM Tabla.DetalleExpensa WHERE id_tipo_gasto = @id)
    BEGIN
        PRINT 'Error: no se puede eliminar el TipoGasto porque está referenciado en DetalleExpensa';
        RETURN;
    END;

    DELETE FROM Tabla.TipoGasto WHERE id = @id;

    PRINT 'TipoGasto eliminado correctamente';
END
GO

--------------------
--SP TIPO SERVICIO--
--------------------

IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='insertarTipoServicio' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.insertarTipoServicio;
GO
CREATE PROCEDURE Procedimientos.insertarTipoServicio
    @nombre              VARCHAR(50),
    @descripcion_detalle VARCHAR(50) = NULL
AS
BEGIN
    IF @nombre IS NULL
    BEGIN
        PRINT 'Error: nombre es obligatorio';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM Tabla.TipoServicio WHERE nombre = @nombre)
    BEGIN
        PRINT 'Error: ya existe un TipoServicio con ese nombre';
        RETURN;
    END;

    INSERT INTO Tabla.TipoServicio (nombre, descripcion_detalle)
    VALUES (@nombre, @descripcion_detalle);

    PRINT 'TipoServicio insertado correctamente';
END
GO


IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='modificarTipoServicio' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.modificarTipoServicio;
GO
CREATE PROCEDURE Procedimientos.modificarTipoServicio
    @id                  INT,
    @nombre              VARCHAR(50),
    @descripcion_detalle VARCHAR(50) = NULL
AS
BEGIN
    IF @id IS NULL
    BEGIN
        PRINT 'Error: id es obligatorio';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoServicio WHERE id = @id)
    BEGIN
        PRINT 'Error: TipoServicio no encontrado';
        RETURN;
    END;

    IF @nombre IS NULL
    BEGIN
        PRINT 'Error: nombre es obligatorio';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM Tabla.TipoServicio 
               WHERE nombre = @nombre AND id <> @id)
    BEGIN
        PRINT 'Error: ya existe otro TipoServicio con ese nombre';
        RETURN;
    END;

    UPDATE Tabla.TipoServicio
       SET nombre = @nombre,
           descripcion_detalle = @descripcion_detalle
     WHERE id = @id;

    PRINT 'TipoServicio modificado correctamente';
END
GO


IF EXISTS (SELECT 1 FROM sys.procedures 
           WHERE name='eliminarTipoServicio' AND SCHEMA_NAME(schema_id)='Procedimientos')
    DROP PROCEDURE Procedimientos.eliminarTipoServicio;
GO
CREATE PROCEDURE Procedimientos.eliminarTipoServicio
    @id INT
AS
BEGIN
    IF @id IS NULL
    BEGIN
        PRINT 'Error: id es obligatorio';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Tabla.TipoServicio WHERE id = @id)
    BEGIN
        PRINT 'Error: TipoServicio no encontrado';
        RETURN;
    END;

  
    IF EXISTS (SELECT 1 FROM Tabla.DetalleExpensa WHERE id_tipo_servicio = @id)
    BEGIN
        PRINT 'Error: no se puede eliminar el TipoServicio porque está referenciado en DetalleExpensa';
        RETURN;
    END;

    DELETE FROM Tabla.TipoServicio WHERE id = @id;

    PRINT 'TipoServicio eliminado correctamente';
END
GO