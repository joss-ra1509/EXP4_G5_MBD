Experiencia de Aprendizaje 4: Sistema Integral de Trazabilidad G5


📝 Descripción del Proyecto
Este proyecto implementa una solución avanzada de Auditoría y Trazabilidad para el sistema SistemaVentas_G5. A través de una arquitectura basada en Triggers, el sistema captura automáticamente cada interacción (INSERT, UPDATE, DELETE) en las tablas críticas, garantizando la integridad de la información y la rendición de cuentas.

🚀 Innovación: El Script Maestro (All-in-One)
A diferencia de las entregas convencionales fragmentadas, este proyecto se ha consolidado en un Script Maestro Único.

Ventaja: Elimina errores de dependencia, rutas de archivos inexistentes y conflictos de ejecución.

Garantía: Asegura que la Bitacora se cree con los estándares de seguridad necesarios antes de que los triggers intenten escribir en ella.


🛠️ Estructura de la Auditoría
La tabla Bitacora diseñada captura un rastro digital completo:

Quién: UsuarioAccion (Login del sistema) y UsuarioBaseDatos.

Dónde: HostName (Computadora de origen) y ApplicationName.

Qué: TipoAccion y DetalleAccion (con comparativa de valores anteriores y nuevos).

Cuándo: FechaHoraAccion con precisión de milisegundos (DATETIME2).

👥 Distribución de Responsabilidades (Actualizada)IntegranteRol y Aporte TécnicoMakaLíder de Integración: Diseño de la arquitectura de la Bitácora, Índices de rendimiento, unificación del Script Maestro y desarrollo de la Batería de Pruebas Automatizada.RubelEstructura de Apoyo: Creación y configuración de las tablas de apoyo (Empleados, Inventario, Usuarios, Pagos y Roles) y sus triggers base.JasonDesarrollo de Triggers para Tablas Maestras (Clientes y Productos).LuisDesarrollo de Triggers para Tablas Transaccionales (Pedidos y Detalle Pedido).


🚦 Instrucciones de Uso
Abra el archivo Script_Maestro_G5.sql en SQL Server Management Studio (SSMS).

Asegúrese de estar conectado a la instancia donde reside SistemaVentas_G5.

Presione F5 o haga clic en Execute.

El script realizará automáticamente:

Limpieza y creación de la infraestructura de bitácora.

Instalación de los 9 triggers de auditoría.

Ejecución de una Batería de Pruebas que inserta, modifica y elimina datos reales y temporales.

Generación de un Reporte de Trazabilidad final.


🧪 Batería de Pruebas Corregida
El script incluye una lógica de validación inteligente:

Validación de FK: El script busca dinámicamente un DUI y un Producto existente para realizar pruebas en las tablas de Pedidos y Detalles sin violar llaves foráneas.

Cobertura 100%: Se testea cada uno de los 9 triggers instalados.

Reporte Estadístico: Al finalizar, se muestra un resumen de registros capturados agrupados por tabla y acción.


📊 Resultados Esperados
Al ejecutar el script, se debe visualizar en la pestaña de resultados:

Una tabla con el listado de todos los triggers instalados y su estado (ACTIVO).

El detalle de la bitácora con las acciones realizadas durante el test.

Un resumen cuantitativo que confirma cuántos INSERT, UPDATE y DELETE fueron procesados.
