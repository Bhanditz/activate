@import AppKit;
@import Foundation;

#include <unistd.h>
#include <sys/wait.h>

int main (int argc, char **argv) {
  if (argc < 2) {
    NSLog(@"Usage: activate EXEPATH");
    return 1;
  }
  char *exePath = argv[1];

  pid_t p = fork();
  if (p == 0) {
    NSLog(@"In child, woo! should launch %s", exePath);
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

      NSRunningApplication* aa = [NSRunningApplication runningApplicationWithProcessIdentifier:p];
      NSLog(@"Looked for %d, got app %@", p, aa);
      if (aa) {
        [aa activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        NSLog(@"App icon: %@", [aa icon]);
        NSImage* img = [[NSImage alloc] initWithContentsOfFile:@"/Users/amos/Library/Application Support/itch/apps/Overland/Overland.app/Contents/Resources/PlayerIcon.icns"];
        NSApplication *app = [NSApplication sharedApplication];
        NSLog(@"Shared app: %@", app);
        [app setApplicationIconImage:img];
        break;
      } else {
        NSString* pst = [NSString stringWithFormat:@"%d", p]; 

        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath: @"/bin/ps"];

        NSArray *arguments;
        arguments = [NSArray arrayWithObjects: @"-eo", @"ppid,pid", nil];
        [task setArguments: arguments];

        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];

        NSFileHandle *file;
        file = [pipe fileHandleForReading];

        [task launch];

        NSData *data;
        data = [file readDataToEndOfFile];

        NSString *string;
        string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

        NSArray<NSString *>* lines = [string componentsSeparatedByString:@"\n"];

        for (NSString *line in lines) {
          NSLog(@"Line: %@", line);
        }

        [string release];
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
