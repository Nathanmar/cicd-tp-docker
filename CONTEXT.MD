# Contexte du Projet : API de Gestion de Tâches (Todo App)

Vous travaillez dans une startup qui développe une API de gestion de tâches. L'équipe a grandi (5 développeurs, 3 environnements différents), et le déploiement se fait encore manuellement via FTP.

## Mission du CTO

"Conteneurise tout. Je veux que n'importe qui puisse cloner le repo, lancer `docker compose up`, et avoir l'app qui tourne en 30 secondes. Et je veux que chaque push sur `main` build, scan et push l'image automatiquement. Plus jamais de 'ça marche sur ma machine'."

## Exigences Techniques

1. **Conteneurisation complète** : Utilisation de Docker pour l'API, la Base de Données (BDD), Redis et Nginx.
2. **Optimisation d'image** : Image multi-stage, poids inférieur à 100 Mo.
3. **Sécurité** : Zéro vulnérabilité critique (détectée via scan Trivy).
4. **Pipeline CI/CD** : Build, scan et push automatique vers **GHCR** (GitHub Container Registry).
5. **Observabilité** : Endpoint `/health` fonctionnel pour le healthcheck.
6. **Stratégie de déploiement** : Simulation de déploiement **Blue/Green**.
