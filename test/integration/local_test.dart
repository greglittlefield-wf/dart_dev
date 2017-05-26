// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('vm')
library dart_dev.test.integration.local_test;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:test/test.dart';

const String noTaskProject = 'test_fixtures/local/no_tasks';
const String noExecutableProject = 'test_fixtures/local/no_executable';
const String validTaskProject = 'test_fixtures/local/good_tasks';
const String followSymlinkProject = 'test_fixtures/local/follow_symlinks';
const String overrideTask = 'test_fixtures/local/override_task';
const String noFollowSymlinkProject = 'test_fixtures/local/no_follow_symlinks';

Future<TaskProcess> local(String projectPath,
    {List<String> taskArgs: const []}) async {
  await Process.run('pub', ['get'], workingDirectory: projectPath);
  return new TaskProcess('pub', ['run', 'dart_dev']..addAll(taskArgs),
      workingDirectory: projectPath);
}

Future expectExitWith(Future<TaskProcess> process, Matcher match) async {
  var p = await process;
  await p.done;

  var statusCode = await p.exitCode;

  expect(statusCode, match,
      reason: 'Expected process to exit with given exit code');
}

Future<bool> _parseOuput(Future<TaskProcess> process, String pattern) async {
  var p = await process;
  await p.done;

  var outputContainsPattern =
      await p.stdout.any((line) => line.contains(pattern));
  var errorOutputContainsPattern =
      await p.stderr.any((line) => line.contains(pattern));

  return (outputContainsPattern || errorOutputContainsPattern);
}

Future expectOutput(Future<TaskProcess> process, String pattern) async {
  expect(await _parseOuput(process, pattern), isTrue,
      reason:
          'The following pattern was expected in the output but was not found:\n\n\t"${pattern}"');
}

Future expectNotInOutput(Future<TaskProcess> process, String pattern) async {
  expect(await _parseOuput(process, pattern), isFalse,
      reason:
          'The following pattern was not expected in the output but was found:\n\n\t"${pattern}"');
}

void main() {
  group('Local Task', () {
    test('should work as expected without any tasks', () async {
      await expectExitWith(local(noTaskProject), equals(0));
    });

    test(
        'should return with non zero exit code when unknown executable task is called',
        () async {
      await expectExitWith(
          local(noExecutableProject, taskArgs: ['noExec']), isNot(0));
    });

    test(
        'should report error when attempting a task with an unknown executable',
        () async {
      await expectOutput(local(noExecutableProject, taskArgs: ['noExec']),
          'An executable was not defined for the discovered task noExec.');
    });

    test('should allow a local task to override a built-in one', () async {
      await expectOutput(local(overrideTask, taskArgs: ['analyze']),
          'Custom local analyze task');
    });

    test('should contain discovered tasks when no dart_dev task given',
        () async {
      await expectOutput(local(validTaskProject), 'exampleTask');
    });

    test('should execute a task when given the local task', () async {
      await expectOutput(
          // Executes the example local task which appends the first argument
          // provided to a the 'Hello ' string.
          local(validTaskProject, taskArgs: ['exampleTask']),
          'Hello');
    });

    test('should allow all arguments formats to be passed to underlying task',
        () async {
      // Value arguments are allowed
      await expectOutput(
          local(validTaskProject, taskArgs: ['exampleTask', 'world!']),
          'Hello world!');

      // Single dash option arguments are allowed
      await expectOutput(
          local(validTaskProject, taskArgs: ['exampleTask', 'world!', '-l']),
          'HELLO WORLD!');

      // Double dashed arguments are allowed
      await expectOutput(
          local(validTaskProject,
              taskArgs: ['exampleTask', 'world!', '--loud']),
          'HELLO WORLD!');
    });

    test('should not follow symlink directories when configured', () async {
      await expectNotInOutput(local(noFollowSymlinkProject), 'exampleTask');
    });

    test('should follow symlink directories when configured', () async {
      await expectOutput(local(followSymlinkProject), 'exampleTask');
    });
  });
}
