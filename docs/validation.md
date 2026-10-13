# Evidencia de validación

Validación local del 2026-10-13, Windows amd64, Terraform 1.14.8.

| Raíz | Provider seleccionado | validate | Runs mock |
|---|---|---|---|
| 01 AWS network | aws 6.68.0 | OK | 3/3 |
| 02 AWS async | aws 6.68.0, archive 2.8.1 | OK | 1/1 |
| 03 Azure storage | azurerm 4.81.0 | OK | 2/2 |
| 04 GCP Run | google 6.50.0 | OK | 3/3 |
| 05 Kubernetes | kubernetes 2.38.0 | OK | 1/1 |

`terraform fmt -check -recursive`: OK. Worker Python: 2/2 tests.
Suite reproducible: `./scripts/validate.ps1` desde la raíz.

Pruebas positivas: subredes privadas, SG cerrado, CIDR determinista, separación de
zonas, visibility/timeout, retención DLQ, fallos parciales, storage privado sin
shared keys, ZRS, escala acotada y hardening Kubernetes.
Pruebas negativas: una sola AZ, nombre Azure inválido, imagen mutable y invoker público.

No se ejecutaron planes/applies con proveedores reales ni smoke tests de cloud.
Los digests e identificadores de los ejemplos requieren sustitución. Los diagramas
se entregan como Mermaid renderizable por GitHub; no se exportaron imágenes.
CI ejecuta la misma suite en Linux; consultar el run del commit para su resultado.
