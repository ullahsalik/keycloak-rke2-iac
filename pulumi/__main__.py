import pulumi
import pulumi_kubernetes as k8s
from pulumi_kubernetes.helm.v3 import Chart, ChartOpts, FetchOpts

config = pulumi.Config()
# Securely fetching passwords [cite: 16]
admin_password = config.get_secret("adminPassword")
db_password = config.get_secret("dbPassword")

# 1. Deploy PostgreSQL (Single Node) [cite: 8, 13]
postgres_chart = Chart(
    "postgres",
    ChartOpts(
        chart="postgresql",
        version="15.5.0",
        fetch_opts=FetchOpts(
            repo="https://charts.bitnami.com/bitnami",
        ),
        values={
            "image": {
                "repository": "bitnami/postgresql",
                "tag": "latest"
            },
            "auth": {
                "database": "keycloak",
                "username": "bn_keycloak",
                "password": db_password,
                "postgresPassword": db_password,
            },
            "primary": {
                "persistence": {
                    "enabled": False # Set to True for production reproducibility [cite: 8]
                },
                "resources": {
                    "requests": {"cpu": "100m", "memory": "256Mi"},
                    "limits": {"cpu": "200m", "memory": "512Mi"}
                }
            }
        }
    )
)

# 2. Deploy Keycloak configured to use the external DB [cite: 12]
keycloak_chart = Chart(
    "keycloak",
    ChartOpts(
        chart="keycloak",
        version="25.2.0", 
        fetch_opts=FetchOpts(
            repo="https://charts.bitnami.com/bitnami",
        ),
        values={
            "image": {
                "repository": "bitnamilegacy/keycloak",
                "tag": "26.3.3-debian-12-r0"
            },
            "auth": {
                "adminUser": "admin",
                "adminPassword": admin_password
            },
            # Connecting to the Postgres service deployed above
            "externalDatabase": {
                "host": "postgres-postgresql",
                "port": 5432,
                "database": "keycloak",
                "user": "bn_keycloak",
                "password": db_password,
            },
            "resources": {
                "limits": {"cpu": "500m", "memory": "1024Mi"},
                "requests": {"cpu": "100m", "memory": "512Mi"}
            },
            "extraEnvVars": [
                {"name": "KC_CACHE", "value": "local"}, # Disables JGroups/Infinispan clustering
                {"name": "KC_HEALTH_ENABLED", "value": "true"}
            ],
            "proxy": "edge",
            "ingress": {
                "enabled": True,
                "hostname": "keycloak.local",
                "ingressClassName": "nginx",
                "annotations": {
                    "nginx.ingress.kubernetes.io/ssl-redirect": "true",
                },
                # This triggers the second half of the Helm template you shared
                "tls": True,
                "selfSigned": True, 
                "extraTls": [{
                    "hosts": ["keycloak.local"],
                    # The template calculates secretName as: printf "%s-tls" .Values.ingress.hostname
                    # So for keycloak.local, it will create 'keycloak.local-tls'
                    "secretName": "keycloak.local-tls" 
                }]
            },
            "postgresql": {
                "enabled": False # Disabling the sub-chart to use our standalone instance
            }
        },
    ),
    opts=pulumi.ResourceOptions(depends_on=[postgres_chart]) # Ensure DB is up first
)

pulumi.export("keycloak_url", "https://keycloak.local")