#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#include <unistd.h>
#include <sys/wait.h>

extern char **environ;

int try_activate (pid_t pid) {
  NSRunningApplication* aa = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
  NSLog(@"Looked for %d, got app %@", pid, aa);
  if (!aa) {
    return 0;
  }

  [aa activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
  return 1;
}

int main (int argc, char **argv) {
  if (argc < 2) {
    NSLog(@"Usage: activate EXEPATH");
    return 1;
  }
  char *exePath = argv[1];

  pid_t p = fork();
  if (p == 0) {
    NSLog(@"Launch %s", exePath);
    NSLog(@"Environ = %s", environ[0]);
    int eret = execl("/usr/bin/sandbox-exec", "/usr/bin/sandbox-exec", "-f", "/Users/amos/Dev/sand/itch.sb", exePath, NULL);
    NSLog(@"Done execing (eret = %d)", eret);
  } else {
    NSLog(@"Launched child");
    usleep(200000);

    int found = 0;
    while (!found) {
      int status;
      int wret = waitpid(-1, &status, WNOHANG);
      if (wret != 0) {
        NSLog(@"Child exited (with %d), quitting...", status);
        exit(status);
      }

      if (try_activate(p)) {
        NSLog(@"Activated!");
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
              NSLog(@"Found child process %@", tokens[1]);
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

    NSLog(@"Now waiting for child..");

    int status;
    wait(&status);
    NSLog(@"Child exited with %d", status);
  }

  return 0;
}
