# Frontend PWA: Sistema de Citas Escolares

Aplicación web móvil progresiva (PWA) desarrollada en HTML5, Tailwind CSS y JavaScript Vanilla. Diseñada para alojarse en **Amazon S3** y distribuirse con **Amazon CloudFront** a costo $0.

## 📱 Estructura de Archivos
* `index.html`: Interfaz móvil con vista de acudientes y panel de profesores.
* `app.js`: Lógica de conexión con API Gateway y Amazon Cognito.
* `config.js`: Variables de conexión (URL de API Gateway y Cognito User Pool ID generados por Terraform).
* `styles.css`: Efectos visuales, bloqueo de horarios ocupados y animaciones.
* `manifest.json`: Manifiesto para instalación nativa en la pantalla de inicio del celular.

## 🚀 Despliegue en AWS
Los archivos se suben automáticamente al bucket privado de S3 mediante los recursos de Terraform en `terraform/frontend_deploy.tf`.
