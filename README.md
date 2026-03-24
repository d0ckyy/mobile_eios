# mobile_eios

Мобильный Flutter-клиент для ЭИОС МГУ им. Н.П. Огарева.

Приложение предназначено для входа в личный кабинет студента, просмотра расписания, профиля, успеваемости, тестов по дисциплинам и отметки посещаемости по QR-коду.

## Что умеет приложение

- Авторизация через учетную запись ЭИОС.
- Автоматическое сохранение токенов и обновление сессии по `refresh_token`.
- Просмотр расписания в календарном формате.
- Просмотр профиля пользователя.
- Просмотр дисциплин и рейтинг-планов.
- Прохождение тестов по дисциплинам.
- Отметка посещаемости через QR-сканер.
- Работа с сообщениями внутри отдельных дисциплин.

## Стек

- `Flutter`
- `Dart`
- `flutter_bloc` / `bloc` для управления состоянием
- `dio` для работы с API
- `flutter_secure_storage` для хранения токенов
- `flutter_dotenv` для конфигурации через `.env`
- `table_calendar` для календаря расписания
- `mobile_scanner` для QR-сканирования

## Как устроен проект

Основные директории:

- `lib/core` - тема, навигация, сеть, исключения
- `lib/data` - модели, репозитории, хранилище токенов
- `lib/presentation` - экраны и BLoC
- `images` - графические assets
- `ios`, `android` - нативные проекты платформ

Экраны:

- `Вход`
- `Расписание`
- `Профиль`
- `Успеваемость`
- `Тесты по дисциплинам`
- `Посещаемость по QR`

## Переменные окружения

Перед запуском нужно создать файл `.env` в корне проекта.

`.env.example`:

```env
CLIENT_ID=your_client_id
CLIENT_SECRET=your_client_secret
```

Приложение использует эти значения для авторизации и обновления токенов.


## Запуск на iPhone

### 1. Mac и iPhone

1. Установить CocoaPods:

```bash
sudo gem install cocoapods
```

2. Подключить iPhone к Mac.
3. Разблокировать iPhone и нажать `Trust`, если появится запрос.
4. На iPhone включить `Developer Mode`:
   `Settings -> Privacy & Security -> Developer mode`.
5. В Xcode добавить свой Apple ID:
   `Xcode -> Settings -> Accounts`.

### 2. Подготовить проект

Из корня проекта выполнить:

```bash
flutter pub get
cd ios
pod install
cd ..
open ios/Runner.xcworkspace
```

Важно:

- открывать нужно именно `ios/Runner.xcworkspace`
- не открывать `ios/Runner.xcodeproj`, иначе CocoaPods-конфигурация может не подтянуться

### 3. Настроить подпись в Xcode

1. В левой панели выбрать `Runner`.
2. В секции `TARGETS` выберать `Runner`.
3. Открыть вкладку `Signing & Capabilities`.
4. Включить `Automatically manage signing`.
5. В поле `Team` выбрать свой Apple ID / Personal Team.
6. Указать уникальный `Bundle Identifier`, например:
   `ru.d0ckyy.eios`

### 4. Запустить на устройстве

1. В верхней панели Xcode выбрать iPhone.
2. Нажать `Run` или `Cmd + R`.
3. На iPhone открыть:
   `Settings -> General -> VPN and device management`
   и довериться сертификату разработчика.
4. Запустить приложение.

После первой успешной настройки подписи можно запускать и из терминала:

```bash
flutter devices
flutter run -d <device_id>
```

## Полезные команды

```bash
flutter pub get
flutter analyze
flutter run
flutter build apk
flutter build ios --no-codesign
```

Если `flutter` не добавлен в `PATH`:

```bash
$HOME/flutter/bin/flutter analyze
```

## О проекте

- Авторизация и обновление токенов реализованы через `Dio` и `OAuth/Token`.
- Токены сохраняются в `FlutterSecureStorage`.
- Начальный экран выбирается по наличию сохраненного access token.
- Основная навигация после входа идет через нижние табы.
- iOS-проект зависит от CocoaPods, поэтому после изменений в iOS-части может понадобиться `pod install`.

## Основные файлы

- `lib/main.dart`
- `lib/core/network/api_service.dart`
- `lib/data/repositories/auth_repository.dart`
- `lib/presentation/screens/login/login_screen.dart`
- `lib/presentation/screens/tabs_screen.dart`
 