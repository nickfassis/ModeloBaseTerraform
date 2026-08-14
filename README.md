# ModeloBaseTerraform

Modelo base de infraestrutura como código (IaC) para hospedagem de sites estáticos em um bucket S3 da AWS, com pipeline de CI/CD via GitHub Actions para os ambientes `dev` e `prod`.

## Visão geral

Este repositório provisiona:

- Um bucket S3 configurado para **hospedagem de site estático** (opcional, controlado por variável).
- Política de leitura pública para os objetos do bucket.
- Upload automático dos arquivos `.html` da pasta [`app/`](app/) para o bucket.
- Backend remoto do Terraform em S3 (state) com lock via DynamoDB.
- Pipelines de deploy (`plan`/`apply`) e destroy via GitHub Actions, separados por ambiente.

## Estrutura do projeto

```
.
├── app/                        # Arquivos estáticos publicados no bucket
│   ├── index.html
│   └── error.html
├── infra/
│   ├── main.tf                 # Recursos: bucket S3, hosting, política pública, upload dos HTMLs
│   ├── variables.tf            # Variáveis de entrada do módulo
│   ├── outputs.tf               # Outputs (endpoint e domínio do site)
│   ├── provider.tf              # Provider AWS
│   ├── backend.tf               # Backend S3 (preenchido em tempo de pipeline)
│   ├── destroy_config.json      # Flags para destruir a infra por ambiente
│   └── envs/
│       ├── dev/terraform.tfvars
│       └── prod/terraform.tfvars
└── .github/workflows/
    ├── terraform.yml           # Workflow reutilizável (init/validate/plan/apply/destroy)
    ├── dev.yml                 # Dispara o workflow acima no push para a branch develop
    └── prod.yml                # Dispara o workflow acima no push para a branch production
```

## Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.8.3`
- Conta AWS com permissões para criar/gerenciar buckets S3 e políticas IAM
- AWS CLI configurado (ou credenciais exportadas via variáveis de ambiente) para execução local

## Variáveis

Definidas em [`infra/variables.tf`](infra/variables.tf):

| Variável                 | Tipo   | Padrão         | Descrição                                              |
|---------------------------|--------|----------------|---------------------------------------------------------|
| `bucket_name`              | string | —              | Nome do bucket S3 (obrigatória)                        |
| `enable_website_hosting`   | bool   | `true`         | Habilita hosting de site estático no bucket             |
| `index_document`           | string | `index.html`   | Documento de índice do site                              |
| `error_document`           | string | `error.html`   | Documento de erro do site                                |

Os valores por ambiente ficam em `infra/envs/<ambiente>/terraform.tfvars`, por exemplo:

```hcl
# infra/envs/dev/terraform.tfvars
bucket_name = "dev-us-east-1-buildrun-pipeline-ministrare"
```

## Outputs

Definidos em [`infra/outputs.tf`](infra/outputs.tf):

- `website_endpoint`: endpoint público do site estático no S3.
- `website_domain`: domínio do site estático no S3.

Ambos retornam `null` quando `enable_website_hosting = false`.

## Uso local

```bash
cd infra

terraform init \
  -backend-config="bucket=<bucket-do-state>" \
  -backend-config="key=<repo>/<ambiente>.tfstate" \
  -backend-config="region=<regiao>" \
  -backend-config="dynamodb_table=<tabela-de-lock>"

terraform workspace select <ambiente> || terraform workspace new <ambiente>

terraform plan  -var-file="./envs/<ambiente>/terraform.tfvars"
terraform apply -var-file="./envs/<ambiente>/terraform.tfvars"
```

Ambientes disponíveis: `dev` e `prod`.

## CI/CD (GitHub Actions)

O deploy é automatizado por três workflows:

- **[`terraform.yml`](.github/workflows/terraform.yml)** — workflow reutilizável (`workflow_call`) que recebe o ambiente e a configuração AWS como entrada e executa, na ordem: checkout → setup do Terraform → configuração de credenciais AWS (via OIDC/assume role) → leitura de `destroy_config.json` → `terraform init` → `terraform validate` → `destroy` **ou** `plan` + `apply`, dependendo da flag de destroy do ambiente.
- **[`dev.yml`](.github/workflows/dev.yml)** — disparado em push para a branch `develop`, aplica o ambiente `dev`.
- **[`prod.yml`](.github/workflows/prod.yml)** — disparado em push para a branch `production`, aplica o ambiente `prod`.

Autenticação com a AWS é feita via **OIDC** (`aws-actions/configure-aws-credentials`), assumindo uma IAM Role — não são usadas credenciais estáticas nos workflows.

### Destroy controlado

O arquivo [`infra/destroy_config.json`](infra/destroy_config.json) controla, por ambiente, se o pipeline deve **destruir** a infraestrutura em vez de aplicar:

```json
{
  "dev": true,
  "prod": true
}
```

Quando a flag do ambiente é `true`, o workflow executa `terraform destroy -auto-approve` em vez de `plan`/`apply`. Ajuste este arquivo com cuidado, especialmente para `prod`.

## Licença

Este projeto está licenciado sob a [GNU General Public License v2.0](LICENSE).
