#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#include <unistd.h>
#include <sys/wait.h>

#ifndef ACTIVATE_VERSION
#define ACTIVATE_VERSION "head"
#endif

#ifdef DEBUG
#define debug(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define debug(...)
#endif

extern char **environ;

int try_activate (pid_t pid) {
  NSRunningApplication* aa = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
  debug(@"Looked for %d, got app %@", pid, aa);
  if (!aa) {
    return 0;
  }

  [aa activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
  return 1;
}

int activate (char **args) {
  pid_t p = fork();
  if (p == 0) {
    debug(@"Launch %s", args[0]);
    debug(@"Environ = %s", environ[0]);

    int eret = execvp(args[0], args);
    debug(@"Done execing (eret = %d)", eret);
  } else {
    debug(@"Launched child");
    usleep(200000);

    int found = 0;
    while (!found) {
      int status;
      int wret = waitpid(-1, &status, WNOHANG);
      if (wret != 0) {
        debug(@"Child exited (with %d), quitting...", status);
        exit(status);
      }

      if (try_activate(p)) {
        debug(@"Activated!");
        found = true;
      } else {
        NSString* pidstring = [NSString stringWithFormat:@"%d", p];

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath: @"/bin/ps"];

        NSArray *arguments = [NSArray arrayWithObjects: @"-eo", @"ppid,pid", nil];
        [task setArguments: arguments];

        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];

        NSFileHandle *file = [pipe fileHandleForReading];

        [task launch];

        NSData *data = [file readDataToEndOfFile];
        NSString *psoutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

        NSArray* lines = [psoutput componentsSeparatedByString:@"\n"];

        for (NSString *line in lines) {
          NSArray* tokens = [line componentsSeparatedByString:@" "];
          if ([tokens count] == 2) {
            if ([tokens[0] isEqualToString:pidstring]) {
              debug(@"Found child process %@", tokens[1]);
              pid_t cpid = (pid_t) [tokens[1] intValue];
              if (try_activate(cpid)) {
                found = true;
                break;
              }
            }
          }
        }

        [psoutput release];
        [task release];
      }

      sleep(1);
    }

    debug(@"Now waiting for child..");

    int status;
    wait(&status);
    debug(@"Child exited with %d", status);
  }

  return 0;
}

int main (int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "Usage: activate COMMAND ARGS\n");
    return 1;
  }

  char *firstArg = argv[1];

  if (strcmp(firstArg, "-V") == 0) {
    printf("%s\n", ACTIVATE_VERSION);
    return 0;
  }

  if (strcmp(firstArg, "--print-library-paths") == 0) {
    NSArray* paths = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSUserDomainMask, YES );
    for (NSString* path in paths) {
      printf("%s\n", [path UTF8String]);
    }
    return 0;
  }

  if (strcmp(firstArg, "--print-bundle-executable-path") == 0) {
    NSString* bundlePath = [NSString stringWithUTF8String:argv[2]];
    NSBundle* bundle = [NSBundle bundleWithPath:bundlePath];
    printf("%s\n", [[bundle executablePath] UTF8String]);
  }

  return activate(&argv[1]);
}

