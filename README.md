# WordPress sur AWS avec Terraform (eu-west-3)

Déploiement automatisé d'un site WordPress : serveur web EC2, base de données RDS sur 2 zones de disponibilité, disque EBS de persistance, accès HTTP et HTTPS. Le code est découpé en 4 modules réutilisables.

## Architecture

```
                         Internet
                            │  80 / 443
┌───────────────────────── VPC 10.0.0.0/16 — eu-west-3 ──────────────────────────┐
│                                                                                 │
│   AZ 1                                         AZ 2                             │
│   ┌── subnet public 10.0.0.0/24 ──┐            ┌── subnet public 10.0.1.0/24 ─┐ │
│   │  EC2 t3.micro (WordPress)     │            │                              │ │
│   │  Amazon Linux 2023            │            │                              │ │
│   │  + EBS 10 Go (/var/www/html)  │            │                              │ │
│   └──────────────┬────────────────┘            └──────────────────────────────┘ │
│                  │ 3306 (SG web → SG db)                                        │
│   ┌── subnet privé 10.0.10.0/24 ──┐            ┌── subnet privé 10.0.11.0/24 ─┐ │
│   │  RDS db.t3.micro (principal)  │ ─réplica─▶ │  RDS standby (Multi-AZ)      │ │
│   └───────────────────────────────┘            └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Correspondance avec le cahier des charges

| Exigence | Implémentation |
|---|---|
| Région Paris | `region = "eu-west-3"` (variable) |
| EC2 `t3.micro` | module `ec2`, variable `instance_type` |
| AMI récupérée automatiquement | `data "aws_ami"` : dernière Amazon Linux 2023 |
| AZ récupérées automatiquement | `data "aws_availability_zones"` dans le module `networking` |
| `aws_db_instance` `db.t3.micro` sur 2 AZ | module `rds` : `multi_az = true`, subnet group sur 2 AZ |
| EBS 10 Go dans la même AZ que l'EC2 | module `ebs` : `availability_zone = module.ec2.availability_zone` |
| HTTP port 80 | security group web + Apache |
| Bonus HTTPS port 443 (TLS) | `enable_https = true` : mod_ssl + certificat autosigné |
| Aucun mot de passe en dur | `db_password` sans valeur par défaut, `sensitive`, fourni par `TF_VAR_db_password` |
| Modules | `networking`, `ec2`, `rds`, `ebs` |

## Structure

```
├── modules
│    ├── networking   VPC, subnets publics/privés sur 2 AZ, IGW, routes, security groups
│    ├── ec2          AMI automatique, instance, user_data (install_wordpress.sh)
│    ├── rds          subnet group, aws_db_instance Multi-AZ
│    └── ebs          volume 10 Go chiffré + attachement /dev/sdf
├── variables.tf      toutes les variables, avec validations
├── main.tf           provider, appels de modules, sorties
├── install_wordpress.sh
└── terraform.tfvars.example
```

## Prérequis

- Terraform ≥ 1.6
- Identifiants AWS configurés (jamais dans le code) :

```bash
aws configure               # region : eu-west-3, output : json
aws sts get-caller-identity # doit afficher le compte
```

## Déploiement

```bash
export TF_VAR_db_password='MotDePasseSolide2026'   # 8-41 caractères, sans espace / @ "

terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Durée : **15 à 25 minutes**, surtout pour la base Multi-AZ. L'instance EC2 n'est créée qu'une fois la base disponible.

Après l'`apply`, **attendre 3 à 5 minutes** que le script d'installation se termine, puis ouvrir la sortie `wordpress_url`. L'assistant d'installation de WordPress s'affiche (langue, titre, compte administrateur).

```bash
terraform output
```

HTTPS : `wordpress_https_url`. Le certificat est autosigné, le navigateur affiche donc un avertissement à accepter.

## Personnalisation (optionnelle)

Toutes les variables ont une valeur par défaut, sauf le mot de passe. Pour les modifier :

```bash
cp terraform.tfvars.example terraform.tfvars
```

Accès SSH (fermé par défaut) : renseigner `key_name` (paire de clés existante dans eu-west-3) et `ssh_allowed_cidrs` (ton IP en `/32`), puis :

```bash
ssh -i ~/.ssh/<cle>.pem ec2-user@<ec2_public_ip>
sudo tail -f /var/log/install-wordpress.log
```

## Vérifications

```bash
terraform output ec2_availability_zone ebs_availability_zone   # identiques
terraform output rds_multi_az                                  # true
curl -I "$(terraform output -raw wordpress_url)"               # HTTP 302 vers l'installation WordPress
```

## Suppression

```bash
terraform destroy
```

## Bonnes pratiques appliquées

- Code modulaire, chaque module avec `variables.tf`, `main.tf`, `outputs.tf`.
- Aucune valeur sensible dans le code : mot de passe par variable d'environnement, marqué `sensitive`.
- Versions de Terraform et du provider épinglées.
- Validation des entrées (`namespace`, nom et utilisateur de base, mot de passe, taille EBS).
- Tags communs via `default_tags`.
- Base non exposée : subnets privés sans route Internet, `publicly_accessible = false`, accès MySQL uniquement depuis le security group web.
- Chiffrement : volume racine, volume EBS et stockage RDS chiffrés ; IMDSv2 obligatoire.
- SSH fermé par défaut.
- Script d'installation robuste : volume identifié sans risque de formater le disque système, montage par UUID, mot de passe transmis en base64, journal complet.

## Dépannage

| Symptôme | Solution |
|---|---|
| `Invalid character` à `terraform init` | espaces insécables issus d'un copier-coller : `find . -name '*.tf' -exec sed -i 's/\xC2\xA0/ /g' {} +` |
| `Unable to locate credentials` | `aws configure` avec l'utilisateur courant (pas `sudo`) |
| `Unknown output type: yes` | `aws configure set output json` |
| Erreur `FreeTierRestriction` sur la base | compte en offre gratuite : `terraform apply -var 'db_backup_retention_period=0'`, ou `-var 'db_multi_az=false'` si le Multi-AZ est refusé |
| Page inaccessible juste après l'`apply` | attendre la fin du script (3 à 5 min) |
