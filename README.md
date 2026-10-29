# MayoristaConnect - Solución Móvil Offline-First

Prototipo funcional móvil desarrollado para la gestión de toma de pedidos y control de ventas offline para MYPEs distribuidoras mayoristas en la región Piura.

## Stack Tecnológico
- Framework: Flutter (Dart)
- Base de Datos Local: SQLite (sqflite) para operaciones CRUD locales
- Persistencia de Sesión y Configuración: shared_preferences
- Gestión de Ciclo de Vida: WidgetsBindingObserver (persistencia de borradores al suspender la app)
- Patrón de Arquitectura: Clean Architecture + MVVM

## Funcionalidades Obligatorias (Unidad II)
1. Navegación Dinámica: Enrutamiento entre múltiples vistas (Login, Dashboard de Rutas, Pedido/Formulario, Historial).
2. Persistencia Local SQLite (CRUD Completo):
   - Create: Registro de nuevos pedidos de preventa con cálculo de montos e IGV.
   - Read: Visualización del historial de pedidos pendientes en modo offline.
   - Update: Edición del monto/total de pedidos locales existentes.
   - Delete: Eliminación física de registros en la base de datos local.
3. Preferencias Compartidas: Almacenamiento seguro del rol de sesión activa y persistencia de configuración.
4. Ciclo de Vida: Resguardo automático en memoria local del borrador del pedido si la app entra en segundo plano (paused / inactive).

## Instrucciones de Compilación y Ejecución
1. Clonar el repositorio:
   git clone https://github.com/Pereyra2003/mayorista_connect.git

2. Entrar al directorio del proyecto:
   cd mayorista_connect

3. Instalar dependencias:
   flutter pub get

4. Ejecutar en emulador o dispositivo físico:
   flutter run
