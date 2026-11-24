#!/bin/bash
# Gera o APK de release e envia ao Firebase App Distribution (projeto click-seguro-app).
# Uso: bash tools/distribute.sh "notas da versão"   (TESTER_GROUPS=alias1,alias2 para outros grupos)
# Exige android/key.properties (chave de upload) e `npx firebase-tools@15 login` feito uma vez.
# Sem API_URL, o app usa o servidor padrão de EnvironmentConfig; para outro, API_URL=https://.../api/v1.
set -e
cd "$(dirname "$0")/.."
APP_ID=1:631785980806:android:38621b21baba3c71532207
TESTER_GROUPS=${TESTER_GROUPS:-testadores}
NOTES=${1:-$(git log -1 --format=%s)}

if [ ! -f android/key.properties ]; then
  echo "Falta android/key.properties: o APK sairia com a chave de debug e não atualizaria o instalado." >&2
  exit 1
fi

DEFINES=()
if [ -n "$API_URL" ]; then DEFINES+=(--dart-define=API_URL="$API_URL"); fi

# Número de build crescente para o aparelho aceitar a atualização sem desinstalar.
flutter build apk --release "${DEFINES[@]}" --build-number="$(git rev-list --count HEAD)"

npx -y firebase-tools@15 appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app "$APP_ID" --groups "$TESTER_GROUPS" --release-notes "$NOTES"
