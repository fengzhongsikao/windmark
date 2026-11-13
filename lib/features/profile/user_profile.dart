import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:windmark/app/app_copy.dart';

class UserProfile {
  const UserProfile({required this.name, this.avatarFile, this.revision = 0});

  final String name;
  final File? avatarFile;
  final int revision;

  static const fallback = UserProfile(name: AppCopy.name);

  UserProfile copyWith({String? name, File? avatarFile, int? revision}) {
    return UserProfile(
      name: name ?? this.name,
      avatarFile: avatarFile ?? this.avatarFile,
      revision: revision ?? this.revision,
    );
  }
}

abstract interface class UserProfileStore {
  Future<UserProfile> load();

  Future<UserProfile> saveName(String name);

  Future<UserProfile> saveAvatar(List<int> bytes);

  Future<UserProfile> clearAvatar();
}

final userProfileStoreProvider = Provider<UserProfileStore>((ref) {
  return FileUserProfileStore();
});

class UserProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() {
    return ref.watch(userProfileStoreProvider).load();
  }

  Future<void> saveName(String name) async {
    final next = await ref.read(userProfileStoreProvider).saveName(name.trim());
    state = AsyncData(next.copyWith(revision: state.value?.revision ?? 0));
  }

  Future<void> saveAvatar(List<int> bytes) async {
    final next = await ref.read(userProfileStoreProvider).saveAvatar(bytes);
    final revision = (state.value?.revision ?? 0) + 1;
    state = AsyncData(next.copyWith(revision: revision));
  }

  Future<void> clearAvatar() async {
    final next = await ref.read(userProfileStoreProvider).clearAvatar();
    final revision = (state.value?.revision ?? 0) + 1;
    state = AsyncData(UserProfile(name: next.name, revision: revision));
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile>(
      UserProfileController.new,
    );

final class FileUserProfileStore implements UserProfileStore {
  Future<Directory> _directory() => getApplicationDocumentsDirectory();

  Future<File> _avatarFile() async {
    final directory = await _directory();
    return File('${directory.path}/avatar.jpg');
  }

  Future<File> _nameFile() async {
    final directory = await _directory();
    return File('${directory.path}/display_name.txt');
  }

  @override
  Future<UserProfile> load() async {
    try {
      final avatar = await _avatarFile();
      final nameFile = await _nameFile();
      var name = AppCopy.name;
      if (await nameFile.exists()) {
        final text = (await nameFile.readAsString()).trim();
        if (text.isNotEmpty) {
          name = text;
        }
      }
      final hasAvatar = await avatar.exists();
      return UserProfile(name: name, avatarFile: hasAvatar ? avatar : null);
    } on Object {
      return UserProfile.fallback;
    }
  }

  @override
  Future<UserProfile> saveName(String name) async {
    final file = await _nameFile();
    await file.writeAsString(name, flush: true);
    return load();
  }

  @override
  Future<UserProfile> saveAvatar(List<int> bytes) async {
    final file = await _avatarFile();
    await file.writeAsBytes(bytes, flush: true);
    return load();
  }

  @override
  Future<UserProfile> clearAvatar() async {
    final file = await _avatarFile();
    if (await file.exists()) {
      await file.delete();
    }
    return load();
  }
}

final class MemoryUserProfileStore implements UserProfileStore {
  MemoryUserProfileStore({String name = AppCopy.name}) : _name = name;

  String _name;
  File? _avatar;

  @override
  Future<UserProfile> load() async {
    return UserProfile(name: _name, avatarFile: _avatar);
  }

  @override
  Future<UserProfile> saveName(String name) async {
    _name = name;
    return load();
  }

  @override
  Future<UserProfile> saveAvatar(List<int> bytes) async {
    return load();
  }

  @override
  Future<UserProfile> clearAvatar() async {
    _avatar = null;
    return load();
  }
}
