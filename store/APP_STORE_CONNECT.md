# App Store Connect — Auto Wize

Cole estes valores no App Store Connect. URLs públicas (GitHub Pages):

| Campo | URL |
|-------|-----|
| **Privacy Policy URL** | https://berglimma.github.io/CheckApp/privacy.html |
| **Support URL** | https://berglimma.github.io/CheckApp/support.html |
| **Marketing URL** (opcional) | https://berglimma.github.io/CheckApp/ |
| **Terms** (EULA custom / link no app) | https://berglimma.github.io/CheckApp/terms.html |

---

## Identidade do app

| Campo | Valor |
|-------|--------|
| Nome | Auto Wize |
| Subtítulo (30 caracteres) | Checklists de frota |
| Bundle ID | `dowloads.ChecklistApp` |
| SKU sugerido | `autowize001` |
| Categoria primária | **Business** (Negócios) |
| Categoria secundária | **Productivity** (Produtividade) |
| Faixa etária | **4+** (sem conteúdo restrito; coleta dados comerciais/PII declarada na Privacy) |

---

## Descrição (PT-BR)

```
O Auto Wize é o checklist inteligente para frotas e locadoras.

Registre entrega e devolução de veículos, trocas provisórias, avarias e avaliações de tratores — com fotos, assinatura, combustível e inspeção completa.

Recursos:
• Checklist de Entrega com número de reserva
• Devolução com conferência de KM e avarias
• Troca provisória atrelada à reserva
• Cálculo de avarias e relatório
• Avaliação de tratores / equipamentos
• Seleção visual de marca e modelo
• Avisos ao cliente por SMS/iMessage e e-mail
• Histórico e exportação em PDF
• Login com e-mail, Apple e Google

Ideal para equipes que precisam padronizar a inspeção de frota no dia a dia.
```

## Texto promocional (170 caracteres)

```
Checklists de frota com reserva, troca, avarias, tratores, fotos e avisos ao cliente por SMS e e-mail.
```

## Palavras-chave (100 caracteres, separadas por vírgula, sem espaços extras desnecessários)

```
checklist,frota,locadora,entrega,devolução,avarias,trator,veículo,inspeção,PDF
```

---

## App Privacy (nutrition label) — respostas sugeridas

**Coleta dados ligados à identidade?** Sim  

| Tipo de dado | Vinculado ao usuário | Usado para rastreamento | Finalidades |
|--------------|----------------------|-------------------------|-------------|
| E-mail | Sim | Não | Funcionalidade do app |
| Nome | Sim | Não | Funcionalidade do app |
| Número de telefone | Sim | Não | Funcionalidade do app |
| Fotos ou vídeos | Sim | Não | Funcionalidade do app |
| Outros conteúdos do usuário (assinaturas, checklists, CPF/documento do cliente) | Sim | Não | Funcionalidade do app |
| Identificadores do usuário (conta) | Sim | Não | Funcionalidade do app |

**Rastreamento:** Não  
**Dados usados para publicidade:** Não  

---

## Classificação etária

Responda o questionário indicando **sem** violência, sexo, drogas, gambling, etc.  
Resultado esperado: **4+**.

---

## Criptografia / Export Compliance

No Info.plist: `ITSAppUsesNonExemptEncryption = false`  
No Connect: **Yes, uses encryption** → **exempt** (apenas HTTPS / APIs padrão), ou use a declaração do plist.

---

## Conta demo — App Review Information

**Sign-in required:** Yes  

```
Username / E-mail: demo@autowize.app
Password: Demo@Autowize2026!
```

**Notes for Review:**

```
Auto Wize is a fleet checklist app (delivery, return, temporary vehicle swap, damage reports, tractor inspection).

Demo login (email/password):
• Email: demo@autowize.app
• Password: Demo@Autowize2026!

Also supports Sign in with Apple and Google.

Privacy Policy: https://berglimma.github.io/CheckApp/privacy.html
Support: https://berglimma.github.io/CheckApp/support.html

Account deletion: Profile → Excluir minha conta (also erases local operational PII: histories, client CPF, photos, signatures, reservations).

Brand/model images are for operational vehicle selection reference only.
```

**Contact:** use your Apple ID / phone; support e-mail `suporte.autowize@gmail.com`

---

## Screenshots

1. Gere no Simulator (iPhone 16 Pro Max = 6.7", iPhone 11 Pro Max / 15 Plus ≈ 6.5").
2. Ou use os mocks em `store/screenshots/` como base visual e substitua por capturas reais antes do envio.
3. iPad: se o app oferecer iPad (`TARGETED_DEVICE_FAMILY = 1,2`), inclua 13" screenshots.

Fluxo sugerido nas telas: Login → Home → Entrega → Troca → Histórico.
