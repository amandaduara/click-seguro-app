# Data Model: Perfil

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-12

Formatos conferidos no servidor em [R0](research.md#r0-conferência-no-servidor-real-portão-de-api).
Nada novo é guardado no aparelho (a cópia da foto escolhida é apagada depois do envio).

## Entidades (domain, módulo `profile`)

| Entidade | Campos | Regras |
|---|---|---|
| `ProfileEntity` | `name`, `email`, `phone?` (`+55…`), `avatarUrl?`, `receiveNotifications` | `initials`: até 2 letras das primeiras palavras do nome |
| `NewsCountsEntity` | `read`, `saved`, `liked` (int) | `meta.total` de cada lista |
| `ModuleProgressEntity` | `title`, `order`, `lessonsCount`, `completedCount` | `isCompleted` = `lessonsCount > 0 && completedCount >= lessonsCount` |
| `ActivityProgressEntity` | `modules: List<ModuleProgressEntity>`, `lessonsCompleted` (`totalLessonsCompleted`) | `modulesCompleted` = nº de módulos com `isCompleted`; `modulesWithLessons` = módulos com `lessonsCount > 0` |
| `AchievementEntity` | `kind: AchievementKind`, `moduleTitle?`, `moduleOrder?` (desempate e cor), `current`, `target`, `achieved` | `progress` = `current/target` (limitado a 1) |
| `ProfileUpdate` | `name?`, `email?`, `phone?` | só os campos que mudaram (FR-013) |

`AchievementKind { firstLesson, firstModule, dedicatedStudent, securityMaster, attentiveReader, dedicatedReader, module }`.

## Regras das conquistas (`AchievementsCalculator`, [R3](research.md#r3-conquistas-rn-008))

| Kind | current | target | Só existe se |
|---|---|---|---|
| `firstLesson` | lições concluídas | 1 | sempre |
| `firstModule` | módulos concluídos | 1 | sempre |
| `dedicatedStudent` | lições concluídas | 10 | sempre |
| `securityMaster` | módulos concluídos | módulos com lições | houver ≥ 1 módulo com lições |
| `attentiveReader` | notícias lidas | 1 | sempre |
| `dedicatedReader` | notícias lidas | 10 | sempre |
| `module` (um por módulo) | `completedCount` | `lessonsCount` | `lessonsCount > 0` |

Ordem: `achieved` primeiro; depois maior `progress`; empate → ordem do enum e, entre módulos,
`order` do serviço.

## Falhas (`profile/domain/failures/profile_failures.dart`)

| Falha | Quando | Mensagem (chave) |
|---|---|---|
| `EmailInUseFailure` | 409 `USER_EMAIL_ALREADY_EXISTS` | `profile_edit_email_in_use` (no campo) |
| `AvatarTypeFailure` | 400 `INVALID_IMAGE_TYPE` | `profile_photo_invalid` |
| `ConnectionFailure`, `ServerFailure`, `UnauthorizedFailure` | padrão (inclui o 500 do e-mail, R0, e o 400 `VALIDATION_ERROR`, que a validação local evita; a `ApiException` não traz o campo) | `profile_edit_save_failed` na edição |

## Controllers

**`ProfileController`** (um, provido pela página):

| Getter | Tipo | Significado |
|---|---|---|
| `status` | `ProfileStatus { loading, loaded, error }` | carga do perfil (tela inteira) |
| `profile` | `ProfileEntity?` | |
| `counts` | `AreaState<NewsCountsEntity>` | `loading / loaded(value) / failed` |
| `achievements` | `AreaState<List<AchievementEntity>>` | depende de `counts` e do progresso |
| `achievedCount`, `totalCount` | int | "Conquistas (4)" |

Métodos: `load()` (mostra carregando), `refresh()` (silencioso, [R4](research.md#r4-atualizar-ao-voltar-à-aba-fr-007)),
`retryCounts()`, `retryAchievements()`.

**`EditProfileController`**:

| Campo | Regra |
|---|---|
| `name`, `email`, `phone` (texto digitado) | erros por campo: `nameLength`, `emailInvalid`, `emailInUse`, `phoneInvalid`, `phoneRequired` |
| `canSave` | algum campo diferente do original (normalizado) e não está salvando |
| `isSaving`, `photoState { idle, uploading, removing }`, `localPhotoPath?` | |

Métodos: `save()` → `Failure?`, `pickPhoto(PhotoSource)` → `PickPhotoOutcome`, `removePhoto()` →
`Failure?`, `hasChanges`.

Validação ([R5](research.md#r5-editar-perfil)): nome `trim().length` 6–150; e-mail
`trim().toLowerCase()` com a expressão do `CredentialsValidator`; telefone: dígitos (sem "55"
inicial quando digitado com "+55") com 10 ou 11 → `+55` + dígitos; vazio só se o original era
`null`.

## Mudanças em outros módulos

- `common`: `UserSessionService.profileVersion` (`ValueListenable<int>`), incrementado em
  `updateProfile` ([R6](research.md#r6-saudação-atualizada-sc-003)).
- `shell`: `AppTopBar` ouve `sessionStatus` e `profileVersion`.
- `news` ([R8](research.md#r8-listas-de-lidas-e-curtidas-us4)): `NewsListKind { saved, read,
  liked }`; lista de salvas generalizada; rotas `/news/read` e `/news/liked`.

## Chaves de i18n (novas, prefixo `profile_`; inglês equivalente)

| Chave | pt-BR |
|---|---|
| `profile_settings` | Configurações |
| `profile_edit_photo_label` | Editar perfil |
| `profile_stat_read` / `_saved` / `_liked` | Lidas / Salvas / Curtidas |
| `profile_stat_semantic` | {} notícias {}, abrir lista |
| `profile_stats_failed` | Não foi possível carregar seus números. |
| `profile_achievements` | Conquistas |
| `profile_achievements_see_all` | Ver todas |
| `profile_achievements_failed` | Não foi possível carregar suas conquistas. |
| `profile_achievement_done` | Conquistada |
| `profile_ach_first_lesson` … `profile_ach_dedicated_reader` | Primeira lição, Primeiro módulo, Estudante dedicado, Mestre da segurança, Leitor atento, Leitor dedicado |
| `profile_ach_progress_lessons` / `_modules` / `_news` | {} de {} lições / módulos / notícias |
| `profile_cta_news_title` / `_sub` | Ler mais notícias / Fique por dentro dos golpes novos |
| `profile_cta_activities_title` / `_sub` | Fazer novas atividades / Complete desafios e ganhe medalhas |
| `profile_guest_title` / `_body` / `_action` | Entre na sua conta / Com uma conta, o SafeNews guarda tudo o que você faz, mesmo se trocar de celular. / Entrar ou criar conta |
| `profile_guest_benefits_title` + 4 itens | O que você ganha com uma conta / (lista do Figma) |
| `profile_edit_name` / `_email` / `_phone` / `_phone_hint` | Nome / E-mail / Telefone / (11) 91234-5678 |
| `profile_edit_save` / `profile_edit_saved` / `profile_edit_save_failed` | Salvar / Dados salvos / Não foi possível salvar. Tente de novo mais tarde. |
| `profile_edit_error_name` / `_email` / `_email_in_use` / `_phone` / `_phone_required` | O nome precisa ter de 6 a 150 letras. / Digite um e-mail válido. / Este e-mail já está em uso. / Digite o telefone com DDD. / Informe um telefone com DDD. |
| `profile_edit_discard_title` / `_body` / `_confirm` / `_cancel` | Descartar alterações? / O que você mudou não será salvo. / Descartar / Continuar editando |
| `profile_photo_gallery` / `_camera` / `_remove` / `_remove_confirm_title` / `_remove_confirm` / `_uploading` / `_failed` / `_invalid` / `_permission_title` / `_permission_body` | Galeria / Câmera / Remover foto / Remover a foto? / Remover / Enviando foto… / Não foi possível trocar a foto. / Esta imagem não é aceita. Use uma foto JPG ou PNG. / Sem acesso às fotos / Para escolher uma foto, libere o acesso nas configurações do celular. |
| `news_read_title` / `news_liked_title` / `news_read_empty` / `news_liked_empty` | Notícias lidas / Notícias curtidas / Você ainda não leu nenhuma notícia. / Você ainda não curtiu nenhuma notícia. |
