# 🚀 Experiencia de Aprendizaje 4: Sistema Integral de Trazabilidad G5

## 📝 Descripción General

Este proyecto implementa una solución robusta de **Auditoría y Trazabilidad** para la base de datos `SistemaVentas_G5`. Mediante el uso estratégico de **Triggers**, el sistema garantiza que cualquier modificación en los datos deje un rastro digital inalterable, permitiendo cumplir con estándares de seguridad y control de información.

---

## 👥 Integrantes y Distribución de Responsabilidades
 Responsabilidad Técnica |

* **Líder de Integración:** Diseño de arquitectura de Bitácora, optimización de índices, unificación del Script Maestro y desarrollo de la Batería de Pruebas Automatizada. |
* **Tablas de Apoyo:** Creación y configuración de las tablas de apoyo (Empleados, Inventario, Usuarios, Pagos y Roles) y sus respectivos triggers base. |
* **Tablas Maestras:** Desarrollo de triggers de auditoría para las tablas de Clientes y Productos. |
* **Tablas Transaccionales:** Desarrollo de triggers de auditoría para Pedidos y Detalle_Pedido. |

---

## 🛠️ Innovación: El Script Maestro Único

Para asegurar una instalación libre de errores, hemos consolidado todos los componentes en un **Script Maestro Único**. Esta aproximación elimina:

1. **Errores de Dependencia:** La tabla Bitácora siempre se crea antes que los triggers.
2. **Conflictos de Versión:** Asegura que todos los integrantes usen el mismo estándar de campos.
3. **Dificultad de Despliegue:** El profesor solo necesita ejecutar **un solo archivo** para ver todo el sistema funcionando.

---

## 📋 Estructura de la Tabla Bitácora

La auditoría captura los siguientes datos críticos en cada movimiento:

* **IdBitacora:** Identificador único (Folio).
* **UsuarioAccion / UsuarioBaseDatos:** Identificación del operador.
* **FechaHoraAccion:** Marca de tiempo precisa (`DATETIME2`).
* **TipoAccion:** Categoría del evento (`INSERT`, `UPDATE`, `DELETE`, etc.).
* **NombreTabla:** Origen de la modificación.
* **DetalleAccion:** Comparativa de cambios o datos eliminados.
* **HostName / ApplicationName:** Rastreo del equipo y software de origen.

---

## 🚦 Instrucciones de Ejecución

1. Abra el archivo `Script_Maestro_G5.sql` en **SQL Server Management Studio**.
2. Asegúrese de estar conectado a la instancia de base de datos correcta.
3. **Ejecute el script (F5).**
4. El script realizará automáticamente:
* Limpieza y creación de la tabla `Bitacora`.
* Instalación de los **9 triggers** de seguridad.
* Ejecución de la **Batería de Pruebas** (Testeo de cada trigger).
* Despliegue del **Reporte Final de Auditoría**.



---

## 🧪 Validación de Resultados

El script finaliza mostrando una **Batería de Pruebas Corregida**, la cual utiliza lógica dinámica para buscar registros existentes y evitar errores de Llaves Foráneas (FK). Al finalizar, podrá observar:

* La lista de triggers instalados y su estado **ACTIVO**.
* El reporte cronológico de todas las acciones de prueba capturadas.
* Un resumen cuantitativo por tabla para verificar la cobertura total.

---

**© 2026 - Grupo 5 | Ingeniería de Bases de Datos**
