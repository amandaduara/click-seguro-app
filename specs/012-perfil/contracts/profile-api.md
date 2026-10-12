# Contrato: perfil (API usada, rotas e interface do módulo)

**Feature**: [../spec.md](../spec.md) · **Plan**: [../plan.md](../plan.md)

## 1. Endpoints (conferidos em 2026-10-12, [R0](../research.md#r0-conferência-no-servidor-real-portão-de-api))

| Método e caminho | Sucesso | Erros tratados |
|---|---|---|
| `GET /users/me` | 200 `{name, email, phone?, role, receiveNotifications, avatarUrl?}` | 404 `USER_NOT_FOUND` → sessão encerrada (feature 002) |
| `PATCH /users/me` `{name?, email?, phone?}` | 204 | 409 `USER_EMAIL_ALREADY_EXISTS` → `EmailInUseFailure`; 400 `VALIDATION_ERROR` `errors[{field}]` → `ProfileFieldFailure`; ⚠️ 500 com `email` (bug) → falha genérica |
| `POST /users/me/avatar` multipart `avatar` (jpeg/png/webp ≤ 5 MB) | **200** `{avatarUrl}` | 400 `INVALID_IMAGE_TYPE` → `AvatarTypeFailure`; 500 `UPLOAD_FAILED` → genérica |
| `DELETE /users/me/avatar` | 204 | 500 `DELETE_FAILED` → genérica |
| `GET /users/me/news/{read,saved,liked}?limit=1` | 200 `{data, meta{total}}` → só `total` | padrão |
| `GET /app/educational/modules` | 200 `{modules[{id, title, order, lessonsCount, completedCount, …}], totalLessonsCompleted, totalLessonsAvailable}` | padrão |
| `GET /users/me/news/{read,liked}?page&limit=20` (módulo `news`) | 200 `{data[], meta}` | padrão |

## 2. Rotas

| Caminho | Navegador | Tela | Dono |
|---|---|---|---|
| `/profile` | aba Perfil (já existe) | `ProfilePage` (conta ou convite) | profile |
| `/profile/edit` | raiz (já existe) | `EditProfilePage` | profile |
| `/profile/achievements` | raiz (**nova**, filha de `/profile`) | `AchievementsPage` | profile |
| `/news/saved` | raiz (já existe, feature 010) | lista de salvas | news |
| `/news/read`, `/news/liked` | raiz (**novas**, antes de `/news/:id`) | mesma lista, outro `NewsListKind` | news |

O perfil só navega por caminho (`context.push`), sem importar o `news`.

## 3. Interface do módulo `profile`

```dart
// domain/repositories/profile_repository.dart
Future<Either<Failure, ProfileEntity>> getProfile();
Future<Either<Failure, NewsCountsEntity>> getNewsCounts();
Future<Either<Failure, ActivityProgressEntity>> getActivityProgress();
Future<Either<Failure, Unit>> updateProfile(ProfileUpdate update);
Future<Either<Failure, String>> uploadAvatar(String filePath);   // Right(avatarUrl)
Future<Either<Failure, Unit>> removeAvatar();

// domain/usecases
GetProfileUseCase, GetNewsCountsUseCase, GetActivityProgressUseCase,
UpdateProfileUseCase(repository, session)   // atualiza a sessão em sucesso
UpdateAvatarUseCase(repository, imageStorage)  // envia e apaga a cópia local
RemoveAvatarUseCase

// domain/achievements_calculator.dart
List<AchievementEntity> buildAchievements({required int readCount, required ActivityProgressEntity progress});

// domain/validators/profile_form_validator.dart
ProfileFieldErrors validate({required String name, required String email, required String phone, required bool hadPhone});
String? normalizePhone(String input);      // "(11) 91234-5678" → "+5511912345678"
```

## 4. Mudanças fora do módulo

```dart
// common/services/user_session_service.dart
ValueListenable<int> get profileVersion;   // +1 a cada updateProfile

// shell/presentation/widgets/app_top_bar.dart
// reconstrói com Listenable.merge([session.sessionStatus, session.profileVersion])

// news: enum NewsListKind { saved, read, liked } e a lista de salvas generalizada
```
