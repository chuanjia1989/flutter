// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  Cache.disableLocking();
  final MockProcessManager mockProcessManager = MockProcessManager();
  final MemoryFileSystem memoryFilesystem = MemoryFileSystem();
  final MockProcess mockProcess = MockProcess();
  final MockPlatform macosPlatform = MockPlatform();
  final MockPlatform notMacosPlatform = MockPlatform();

  when(mockProcess.exitCode).thenAnswer((Invocation invocation) async {
    return 0;
  });
  when(mockProcess.stderr).thenAnswer((Invocation invocation) {
    return const Stream<List<int>>.empty();
  });
  when(mockProcess.stdout).thenAnswer((Invocation invocation) {
    return const Stream<List<int>>.empty();
  });
  when(macosPlatform.isMacOS).thenReturn(true);
  when(notMacosPlatform.isMacOS).thenReturn(false);

  testUsingContext('macOS build fails when there is no macos project', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
  });

  testUsingContext('macOS build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file('macos/build.sh').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => memoryFilesystem,
  });

  testUsingContext('macOS build invokes build script', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file('macos/build.sh').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    when(mockProcessManager.start(<String>[
      '/macos/build.sh',
      '/',
      'release',
      'no-track-widget-creation',
    ], runInShell: true)).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => memoryFilesystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => macosPlatform,
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}