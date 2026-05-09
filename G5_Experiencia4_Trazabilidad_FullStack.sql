/* =========================================================
   SCRIPT MAESTRO COMPLETO — GRUPO 5
   EXPERIENCIA 4: TRAZABILIDAD DE LOS DATOS
   Incluye: Bitácora, Triggers (Scripts 02-04), Pruebas (Script 05)
   ========================================================= */

USE master;
GO

IF DB_ID(N'SistemaVentas_G5') IS NULL
BEGIN
    RAISERROR('ERROR: La base de datos SistemaVentas_G5 no existe.', 16, 1);
    RETURN;
END;
GO

USE SistemaVentas_G5;
GO

SET NOCOUNT ON;

PRINT '======================================================';
PRINT '  INSTALACIÓN COMPLETA — SISTEMA DE AUDITORÍA G5';
PRINT '======================================================';

/* =====================================================
   SCRIPT 01 — TABLA BITÁCORA E ÍNDICES
   ===================================================== */

PRINT '>>> [01] Creando tabla Bitácora...';

IF OBJECT_ID(N'dbo.Bitacora', N'U') IS NOT NULL
    DROP TABLE dbo.Bitacora;
GO

CREATE TABLE dbo.Bitacora (
    IdBitacora        BIGINT        IDENTITY(1,1) NOT NULL,
    UsuarioAccion     NVARCHAR(128) NOT NULL,
    UsuarioBaseDatos  NVARCHAR(128) NULL,
    FechaHoraAccion   DATETIME2(3)  NOT NULL
        CONSTRAINT DF_Bitacora_FechaHoraAccion DEFAULT SYSDATETIME(),

    -- VARCHAR(20) para cubrir tipos extendidos del Script 04
    TipoAccion        VARCHAR(20)   NOT NULL,

    NombreTabla       NVARCHAR(128) NOT NULL,

    -- NULL permitido: Script 04 no siempre la provee
    ClaveReferencia   NVARCHAR(250) NULL,

    DetalleAccion     NVARCHAR(MAX) NULL,
    HostName          NVARCHAR(128) NULL,
    ApplicationName   NVARCHAR(256) NULL,

    CONSTRAINT PK_Bitacora PRIMARY KEY (IdBitacora),

    -- CHECK ampliado para todos los scripts del grupo
    CONSTRAINT CK_Bitacora_TipoAccion CHECK (
        TipoAccion IN (
            'INSERT',    'UPDATE',   'DELETE',
            'STOCK_UPD', 'USER_ADD', 'USER_DEL',
            'PAYMENT',   'ROLE_UPD'
        )
    )
);
GO

PRINT '    [OK] Tabla Bitácora creada.';

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Bitacora_FechaHoraAccion'
      AND object_id = OBJECT_ID(N'dbo.Bitacora')
)
BEGIN
    CREATE INDEX IX_Bitacora_FechaHoraAccion
    ON dbo.Bitacora (FechaHoraAccion DESC);
    PRINT '    [OK] Índice IX_Bitacora_FechaHoraAccion creado.';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Bitacora_TablaAccion'
      AND object_id = OBJECT_ID(N'dbo.Bitacora')
)
BEGIN
    CREATE INDEX IX_Bitacora_TablaAccion
    ON dbo.Bitacora (NombreTabla, TipoAccion, FechaHoraAccion DESC);
    PRINT '    [OK] Índice IX_Bitacora_TablaAccion creado.';
END;
GO

/* =====================================================
   SCRIPT 02 — TRIGGERS: Clientes y Productos
   ===================================================== */

PRINT '>>> [02] Instalando triggers de tablas maestras...';
GO

CREATE OR ALTER TRIGGER dbo.TR_Clientes_Auditoria
ON dbo.Clientes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- [INSERT]
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, TipoAccion,
            NombreTabla, ClaveReferencia, DetalleAccion,
            HostName, ApplicationName
        )
        SELECT
            SUSER_SNAME(), USER_NAME(), 'INSERT',
            'Clientes', CONVERT(NVARCHAR(250), i.DUI), NULL,
            HOST_NAME(), APP_NAME()
        FROM inserted i;

    -- [UPDATE]
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, TipoAccion,
            NombreTabla, ClaveReferencia, DetalleAccion,
            HostName, ApplicationName
        )
        SELECT
            SUSER_SNAME(), USER_NAME(), 'UPDATE',
            'Clientes', CONVERT(NVARCHAR(250), i.DUI),
            CONCAT(
                CASE WHEN ISNULL(d.Nombre_Completo,'') <> ISNULL(i.Nombre_Completo,'')
                     THEN CONCAT('Nombre: [', d.Nombre_Completo, '] -> [', i.Nombre_Completo, ']; ')
                     ELSE '' END,
                CASE WHEN ISNULL(d.Email,'') <> ISNULL(i.Email,'')
                     THEN CONCAT('Email: [', d.Email, '] -> [', i.Email, ']; ')
                     ELSE '' END,
                CASE WHEN ISNULL(d.ID_Estado,-1) <> ISNULL(i.ID_Estado,-1)
                     THEN CONCAT('Estado: [', d.ID_Estado, '] -> [', i.ID_Estado, ']; ')
                     ELSE '' END
            ),
            HOST_NAME(), APP_NAME()
        FROM inserted i
        INNER JOIN deleted d ON i.DUI = d.DUI;

    -- [DELETE]
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, TipoAccion,
            NombreTabla, ClaveReferencia, DetalleAccion,
            HostName, ApplicationName
        )
        SELECT
            SUSER_SNAME(), USER_NAME(), 'DELETE',
            'Clientes', CONVERT(NVARCHAR(250), d.DUI),
            CONCAT(
                'DUI: ',    d.DUI,
                ' | Nombre: ', d.Nombre_Completo,
                ' | Email: ',  ISNULL(d.Email, 'N/A')
            ),
            HOST_NAME(), APP_NAME()
        FROM deleted d;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_Productos_Auditoria
ON dbo.Productos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- [INSERT]
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, TipoAccion,
            NombreTabla, ClaveReferencia, DetalleAccion,
            HostName, ApplicationName
        )
        SELECT
            SUSER_SNAME(), USER_NAME(), 'INSERT',
            'Productos', CONVERT(NVARCHAR(250), i.ID_Producto), NULL,
            HOST_NAME(), APP_NAME()
        FROM inserted i;

    -- [UPDATE]
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, TipoAccion,
            NombreTabla, ClaveReferencia, DetalleAccion,
            HostName, ApplicationName
        )
        SELECT
            SUSER_SNAME(), USER_NAME(), 'UPDATE',
            'Productos', CONVERT(NVARCHAR(250), i.ID_Producto),
            CONCAT(
                CASE WHEN ISNULL(d.Nombre_Producto,'') <> ISNULL(i.Nombre_Producto,'')
                     THEN CONCAT('Nombre: [', d.Nombre_Producto, '] -> [', i.Nombre_Producto, ']; ')
                     ELSE '' END,
                CASE WHEN ISNULL(CAST(d.Precio_Venta AS NVARCHAR),'') <> ISNULL(CAST(i.Precio_Venta AS NVARCHAR),'')
                     THEN CONCAT('Venta: [', d.Precio_Venta, '] -> [', i.Precio_Venta, ']; ')
                     ELSE '' END,
                CASE WHEN ISNULL(CAST(d.Stock_Actual AS NVARCHAR),'') <> ISNULL(CAST(i.Stock_Actual AS NVARCHAR),'')
                     THEN CONCAT('Stock: [', d.Stock_Actual, '] -> [', i.Stock_Actual, ']; ')
                     ELSE '' END
            ),
            HOST_NAME(), APP_NAME()
        FROM inserted i
        INNER JOIN deleted d ON i.ID_Producto = d.ID_Producto;

    -- [DELETE]
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, TipoAccion,
            NombreTabla, ClaveReferencia, DetalleAccion,
            HostName, ApplicationName
        )
        SELECT
            SUSER_SNAME(), USER_NAME(), 'DELETE',
            'Productos', CONVERT(NVARCHAR(250), d.ID_Producto),
            CONCAT(
                'Producto: ', d.Nombre_Producto,
                ' | Stock Final: ', d.Stock_Actual
            ),
            HOST_NAME(), APP_NAME()
        FROM deleted d;
END;
GO

PRINT '    [OK] TR_Clientes_Auditoria y TR_Productos_Auditoria instalados.';

/* =====================================================
   SCRIPT 03 — TRIGGERS: Pedidos y Detalle_Pedido
   ===================================================== */

PRINT '>>> [03] Instalando triggers transaccionales...';
GO

CREATE OR ALTER TRIGGER dbo.TR_Pedidos_Auditoria
ON dbo.Pedidos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- [UPDATE]
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, FechaHoraAccion,
            TipoAccion, NombreTabla, ClaveReferencia,
            DetalleAccion, HostName, ApplicationName
        )
        SELECT
            ORIGINAL_LOGIN(), SUSER_SNAME(), SYSDATETIME(),
            'UPDATE', 'Pedidos', CONVERT(NVARCHAR(250), i.ID_Pedido),
            CONCAT(
                CASE WHEN ISNULL(CONVERT(NVARCHAR(MAX), d.DUI_Cliente),  N'<<NULL>>') <> ISNULL(CONVERT(NVARCHAR(MAX), i.DUI_Cliente),  N'<<NULL>>')
                     THEN CONCAT('DUI_Cliente: ',  COALESCE(CONVERT(NVARCHAR(MAX), d.DUI_Cliente),  N'NULL'), ' -> ', COALESCE(CONVERT(NVARCHAR(MAX), i.DUI_Cliente),  N'NULL'), '; ') ELSE '' END,
                CASE WHEN ISNULL(CONVERT(NVARCHAR(MAX), d.Total_Venta),  N'<<NULL>>') <> ISNULL(CONVERT(NVARCHAR(MAX), i.Total_Venta),  N'<<NULL>>')
                     THEN CONCAT('Total_Venta: ',  COALESCE(CONVERT(NVARCHAR(MAX), d.Total_Venta),  N'NULL'), ' -> ', COALESCE(CONVERT(NVARCHAR(MAX), i.Total_Venta),  N'NULL'), '; ') ELSE '' END,
                CASE WHEN ISNULL(CONVERT(NVARCHAR(MAX), d.ID_Estado),    N'<<NULL>>') <> ISNULL(CONVERT(NVARCHAR(MAX), i.ID_Estado),    N'<<NULL>>')
                     THEN CONCAT('ID_Estado: ',    COALESCE(CONVERT(NVARCHAR(MAX), d.ID_Estado),    N'NULL'), ' -> ', COALESCE(CONVERT(NVARCHAR(MAX), i.ID_Estado),    N'NULL'), '; ') ELSE '' END
            ),
            HOST_NAME(), APP_NAME()
        FROM inserted i
        INNER JOIN deleted d ON i.ID_Pedido = d.ID_Pedido;

    -- [INSERT]
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, FechaHoraAccion,
            TipoAccion, NombreTabla, ClaveReferencia,
            DetalleAccion, HostName, ApplicationName
        )
        SELECT
            ORIGINAL_LOGIN(), SUSER_SNAME(), SYSDATETIME(),
            'INSERT', 'Pedidos', CONVERT(NVARCHAR(250), i.ID_Pedido),
            NULL, HOST_NAME(), APP_NAME()
        FROM inserted i;

    -- [DELETE]
    ELSE IF EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, FechaHoraAccion,
            TipoAccion, NombreTabla, ClaveReferencia,
            DetalleAccion, HostName, ApplicationName
        )
        SELECT
            ORIGINAL_LOGIN(), SUSER_SNAME(), SYSDATETIME(),
            'DELETE', 'Pedidos', CONVERT(NVARCHAR(250), d.ID_Pedido),
            CONCAT(
                'DUI_Cliente: ',  COALESCE(CONVERT(NVARCHAR(MAX), d.DUI_Cliente),  N'NULL'), '; ',
                'Total_Venta: ',  COALESCE(CONVERT(NVARCHAR(MAX), d.Total_Venta),  N'NULL'), '; ',
                'ID_Estado: ',    COALESCE(CONVERT(NVARCHAR(MAX), d.ID_Estado),    N'NULL')
            ),
            HOST_NAME(), APP_NAME()
        FROM deleted d;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_Detalle_Pedido_Auditoria
ON dbo.Detalle_Pedido
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- [UPDATE]
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, FechaHoraAccion,
            TipoAccion, NombreTabla, ClaveReferencia,
            DetalleAccion, HostName, ApplicationName
        )
        SELECT
            ORIGINAL_LOGIN(), SUSER_SNAME(), SYSDATETIME(),
            'UPDATE', 'Detalle_Pedido', CONVERT(NVARCHAR(250), i.ID_Detalle),
            CONCAT(
                CASE WHEN ISNULL(CONVERT(NVARCHAR(MAX), d.ID_Pedido),  N'<<NULL>>') <> ISNULL(CONVERT(NVARCHAR(MAX), i.ID_Pedido),  N'<<NULL>>')
                     THEN CONCAT('ID_Pedido: ',  COALESCE(CONVERT(NVARCHAR(MAX), d.ID_Pedido),  N'NULL'), ' -> ', COALESCE(CONVERT(NVARCHAR(MAX), i.ID_Pedido),  N'NULL'), '; ') ELSE '' END,
                CASE WHEN ISNULL(CONVERT(NVARCHAR(MAX), d.Cantidad),   N'<<NULL>>') <> ISNULL(CONVERT(NVARCHAR(MAX), i.Cantidad),   N'<<NULL>>')
                     THEN CONCAT('Cantidad: ',   COALESCE(CONVERT(NVARCHAR(MAX), d.Cantidad),   N'NULL'), ' -> ', COALESCE(CONVERT(NVARCHAR(MAX), i.Cantidad),   N'NULL'), '; ') ELSE '' END,
                CASE WHEN ISNULL(CONVERT(NVARCHAR(MAX), d.Subtotal),   N'<<NULL>>') <> ISNULL(CONVERT(NVARCHAR(MAX), i.Subtotal),   N'<<NULL>>')
                     THEN CONCAT('Subtotal: ',   COALESCE(CONVERT(NVARCHAR(MAX), d.Subtotal),   N'NULL'), ' -> ', COALESCE(CONVERT(NVARCHAR(MAX), i.Subtotal),   N'NULL'), '; ') ELSE '' END
            ),
            HOST_NAME(), APP_NAME()
        FROM inserted i
        INNER JOIN deleted d ON i.ID_Detalle = d.ID_Detalle;

    -- [INSERT]
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, FechaHoraAccion,
            TipoAccion, NombreTabla, ClaveReferencia,
            DetalleAccion, HostName, ApplicationName
        )
        SELECT
            ORIGINAL_LOGIN(), SUSER_SNAME(), SYSDATETIME(),
            'INSERT', 'Detalle_Pedido', CONVERT(NVARCHAR(250), i.ID_Detalle),
            NULL, HOST_NAME(), APP_NAME()
        FROM inserted i;

    -- [DELETE]
    ELSE IF EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (
            UsuarioAccion, UsuarioBaseDatos, FechaHoraAccion,
            TipoAccion, NombreTabla, ClaveReferencia,
            DetalleAccion, HostName, ApplicationName
        )
        SELECT
            ORIGINAL_LOGIN(), SUSER_SNAME(), SYSDATETIME(),
            'DELETE', 'Detalle_Pedido', CONVERT(NVARCHAR(250), d.ID_Detalle),
            CONCAT(
                'ID_Pedido: ',  COALESCE(CONVERT(NVARCHAR(MAX), d.ID_Pedido),  N'NULL'), '; ',
                'Cantidad: ',   COALESCE(CONVERT(NVARCHAR(MAX), d.Cantidad),   N'NULL'), '; ',
                'Subtotal: ',   COALESCE(CONVERT(NVARCHAR(MAX), d.Subtotal),   N'NULL')
            ),
            HOST_NAME(), APP_NAME()
        FROM deleted d;
END;
GO

PRINT '    [OK] TR_Pedidos_Auditoria y TR_Detalle_Pedido_Auditoria instalados.';

/* =====================================================
   SCRIPT 04 — TRIGGERS: Empleados, Inventario,
               Usuarios, Pagos, Roles
   ===================================================== */

PRINT '>>> [04] Instalando triggers de tablas de apoyo...';
GO

IF OBJECT_ID('dbo.TR_Auditoria_Empleados', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Auditoria_Empleados;
GO
CREATE TRIGGER dbo.TR_Auditoria_Empleados
ON dbo.Empleados
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
        SELECT SUSER_SNAME(), 'INSERT', 'Empleados',
               'Alta de registro: ' + Nombre_Completo
        FROM inserted;

    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
        SELECT SUSER_SNAME(), 'UPDATE', 'Empleados',
               'Actualización: ' + i.Nombre_Completo
        FROM inserted i;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
        SELECT SUSER_SNAME(), 'DELETE', 'Empleados',
               'Eliminación: ' + Nombre_Completo
        FROM deleted;
END;
GO

IF OBJECT_ID('dbo.TR_Auditoria_Inventario', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Auditoria_Inventario;
GO
CREATE TRIGGER dbo.TR_Auditoria_Inventario
ON dbo.Inventario
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
    SELECT SUSER_SNAME(), 'STOCK_UPD', 'Inventario', 'Ajuste de stock'
    FROM inserted;
END;
GO

IF OBJECT_ID('dbo.TR_Auditoria_Usuarios', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Auditoria_Usuarios;
GO
CREATE TRIGGER dbo.TR_Auditoria_Usuarios
ON dbo.Usuarios
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted)
        INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
        SELECT SUSER_SNAME(), 'USER_ADD', 'Usuarios',
               'Creación de acceso: ' + NombreUsuario
        FROM inserted;

    IF EXISTS (SELECT 1 FROM deleted)
        INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
        SELECT SUSER_SNAME(), 'USER_DEL', 'Usuarios',
               'Remoción de acceso: ' + NombreUsuario
        FROM deleted;
END;
GO

IF OBJECT_ID('dbo.TR_Auditoria_Pagos', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Auditoria_Pagos;
GO
CREATE TRIGGER dbo.TR_Auditoria_Pagos
ON dbo.Pagos
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
    SELECT SUSER_SNAME(), 'PAYMENT', 'Pagos',
           'Registro de transacción financiera'
    FROM inserted;
END;
GO

IF OBJECT_ID('dbo.TR_Auditoria_Roles', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Auditoria_Roles;
GO
CREATE TRIGGER dbo.TR_Auditoria_Roles
ON dbo.Roles
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Bitacora (UsuarioAccion, TipoAccion, NombreTabla, DetalleAccion)
    SELECT SUSER_SNAME(), 'ROLE_UPD', 'Roles',
           'Modificación de perfil/rol'
    FROM inserted;
END;
GO

PRINT '    [OK] Triggers de tablas de apoyo instalados.';

/* =====================================================
   VALIDACIÓN DE TRIGGERS INSTALADOS
   ===================================================== */

PRINT '>>> Validando triggers instalados...';

SELECT
    t.name                   AS [Trigger],
    OBJECT_NAME(t.parent_id) AS [Tabla],
    t.is_disabled            AS [Deshabilitado]
FROM sys.triggers t
WHERE t.parent_class = 1
  AND OBJECT_NAME(t.parent_id) IN (
      'Clientes', 'Productos', 'Pedidos', 'Detalle_Pedido',
      'Empleados', 'Inventario', 'Usuarios', 'Pagos', 'Roles'
  )
ORDER BY [Tabla];
GO

/* =====================================================
   SCRIPT 05 — BATERÍA COMPLETA DE PRUEBAS (CORREGIDA)
   ===================================================== */

PRINT '======================================================';
PRINT '  BATERÍA DE PRUEBAS — AUDITORÍA G5';
PRINT '======================================================';

/* --------------------------------------------------
   PASO PREVIO: tomamos claves reales que ya existen
   en la base de datos para evitar errores de FK
   -------------------------------------------------- */

DECLARE @DUI_Real     NVARCHAR(20);
DECLARE @ID_Prod_Real INT;
DECLARE @ID_Venta_Real INT;

SELECT TOP 1 @DUI_Real     = DUI        FROM dbo.Clientes  WHERE ID_Estado = 1;
SELECT TOP 1 @ID_Prod_Real = ID_Producto FROM dbo.Productos WHERE ID_Estado = 1;
SELECT TOP 1 @ID_Venta_Real = IdVenta    FROM dbo.Ventas;

PRINT '>>> DUI usado en pruebas:      ' + ISNULL(@DUI_Real, 'NULL — no hay clientes activos');
PRINT '>>> ID_Producto usado:         ' + ISNULL(CAST(@ID_Prod_Real AS VARCHAR), 'NULL — no hay productos activos');
PRINT '>>> IdVenta usado en Pagos:    ' + ISNULL(CAST(@ID_Venta_Real AS VARCHAR), 'NULL — no hay ventas');

/* TEST 1 — Productos */
PRINT '>>> [TEST 1] Productos: INSERT -> UPDATE -> DELETE';

INSERT INTO dbo.Productos (Nombre_Producto, Precio_Costo, Margen_Ganancia, Precio_Venta, Stock_Actual, ID_Estado)
VALUES ('Producto Test G5', 10.00, 20.00, 12.00, 50, 1);

UPDATE dbo.Productos
SET Precio_Venta = 15.00, Nombre_Producto = 'Producto Test G5 MOD'
WHERE Nombre_Producto = 'Producto Test G5';

UPDATE dbo.Productos
SET Stock_Actual = 35
WHERE Nombre_Producto = 'Producto Test G5 MOD';

DELETE FROM dbo.Productos
WHERE Nombre_Producto = 'Producto Test G5 MOD';

/* TEST 2 — Clientes */
PRINT '>>> [TEST 2] Clientes: INSERT -> UPDATE -> DELETE';

INSERT INTO dbo.Clientes (DUI, Nombre_Completo, Email, ID_Estado)
VALUES ('99999999-9', 'Cliente Test G5', 'test@g5.com', 1);

UPDATE dbo.Clientes
SET Email = 'modificado@g5.com'
WHERE DUI = '99999999-9';

UPDATE dbo.Clientes
SET Nombre_Completo = 'Cliente Test G5 MOD', ID_Estado = 2
WHERE DUI = '99999999-9';

DELETE FROM dbo.Clientes
WHERE DUI = '99999999-9';

/* TEST 3 — Pedidos (usa DUI real de la BD) */
PRINT '>>> [TEST 3] Pedidos: INSERT -> UPDATE -> DELETE';

IF @DUI_Real IS NULL
BEGIN
    PRINT '    [SKIP] No hay clientes activos para la prueba de Pedidos.';
END
ELSE
BEGIN
    INSERT INTO dbo.Pedidos (DUI_Cliente, Fecha_Pedido, Total_Venta, ID_Estado)
    VALUES (@DUI_Real, GETDATE(), 250.00, 1);

    DECLARE @IdPedido3 INT = SCOPE_IDENTITY();

    UPDATE dbo.Pedidos
    SET Total_Venta = 300.00, ID_Estado = 2
    WHERE ID_Pedido = @IdPedido3;

    DELETE FROM dbo.Pedidos
    WHERE ID_Pedido = @IdPedido3;
END;

/* TEST 4 — Detalle_Pedido (usa DUI y Producto reales) */
PRINT '>>> [TEST 4] Detalle_Pedido: INSERT -> UPDATE -> DELETE';

IF @DUI_Real IS NULL OR @ID_Prod_Real IS NULL
BEGIN
    PRINT '    [SKIP] Faltan clientes o productos activos para la prueba de Detalle_Pedido.';
END
ELSE
BEGIN
    INSERT INTO dbo.Pedidos (DUI_Cliente, Fecha_Pedido, Total_Venta, ID_Estado)
    VALUES (@DUI_Real, GETDATE(), 100.00, 1);

    DECLARE @IdPedido4 INT = SCOPE_IDENTITY();

    INSERT INTO dbo.Detalle_Pedido (ID_Pedido, ID_Producto, Cantidad, Precio_Unitario_Historico, Subtotal)
    VALUES (@IdPedido4, @ID_Prod_Real, 2, 12.00, 24.00);

    UPDATE dbo.Detalle_Pedido
    SET Cantidad = 5, Subtotal = 60.00
    WHERE ID_Pedido = @IdPedido4;

    DELETE FROM dbo.Detalle_Pedido WHERE ID_Pedido = @IdPedido4;
    DELETE FROM dbo.Pedidos        WHERE ID_Pedido = @IdPedido4;
END;

/* TEST 5 — Empleados */
PRINT '>>> [TEST 5] Empleados: INSERT -> UPDATE -> DELETE';

INSERT INTO dbo.Empleados (Nombre_Completo, Cargo, Salario)
VALUES ('Empleado Test G5', 'Auditor', 1500.00);

UPDATE dbo.Empleados
SET Salario = 1800.00
WHERE Nombre_Completo = 'Empleado Test G5';

DELETE FROM dbo.Empleados
WHERE Nombre_Completo = 'Empleado Test G5';

/* TEST 6 — Inventario (trigger solo en UPDATE) */
PRINT '>>> [TEST 6] Inventario: UPDATE';

IF @ID_Prod_Real IS NOT NULL
BEGIN
    UPDATE dbo.Inventario SET StockActual = 75 WHERE IdProducto = @ID_Prod_Real;
    UPDATE dbo.Inventario SET StockActual = 50 WHERE IdProducto = @ID_Prod_Real;
END
ELSE
    PRINT '    [SKIP] No hay productos para actualizar inventario.';

/* TEST 7 — Roles */
PRINT '>>> [TEST 7] Roles: INSERT + UPDATE';

INSERT INTO dbo.Roles (Nombre_Rol) VALUES ('Rol_Test_G5');

UPDATE dbo.Roles
SET Nombre_Rol = 'Rol_Test_G5_MOD'
WHERE Nombre_Rol = 'Rol_Test_G5';

/* TEST 8 — Usuarios */
PRINT '>>> [TEST 8] Usuarios: INSERT -> DELETE';

INSERT INTO dbo.Usuarios (NombreUsuario, Clave, IdRol)
SELECT 'usuario_test_g5', 'clave2026',
       (SELECT TOP 1 IdRol FROM dbo.Roles WHERE Nombre_Rol = 'Rol_Test_G5_MOD');

DELETE FROM dbo.Usuarios WHERE NombreUsuario = 'usuario_test_g5';
DELETE FROM dbo.Roles    WHERE Nombre_Rol    = 'Rol_Test_G5_MOD';

/* TEST 9 — Pagos (usa IdVenta real) */
PRINT '>>> [TEST 9] Pagos: INSERT';

IF @ID_Venta_Real IS NOT NULL
BEGIN
    INSERT INTO dbo.Pagos (IdVenta, MontoPago, MetodoPago)
    VALUES (@ID_Venta_Real, 99.99,  'Efectivo');

    INSERT INTO dbo.Pagos (IdVenta, MontoPago, MetodoPago)
    VALUES (@ID_Venta_Real, 150.00, 'Transferencia');
END
ELSE
    PRINT '    [SKIP] No hay ventas registradas para asociar pagos.';

/* =====================================================
   REPORTE FINAL
   ===================================================== */

PRINT '>>> REPORTE COMPLETO DE BITÁCORA:';

SELECT
    IdBitacora        AS [Folio],
    FechaHoraAccion   AS [Timestamp],
    TipoAccion        AS [Acción],
    NombreTabla       AS [Tabla],
    ClaveReferencia   AS [PK],
    DetalleAccion     AS [Detalle],
    UsuarioAccion     AS [Usuario]
FROM dbo.Bitacora
ORDER BY IdBitacora DESC;

PRINT '>>> RESUMEN POR TABLA:';

SELECT
    NombreTabla   AS [Tabla],
    TipoAccion    AS [Tipo],
    COUNT(*)      AS [Registros]
FROM dbo.Bitacora
GROUP BY NombreTabla, TipoAccion
ORDER BY NombreTabla, TipoAccion;

PRINT '======================================================';
PRINT '  SCRIPT MAESTRO COMPLETADO — GRUPO 5 2026';
PRINT '======================================================';
GO

