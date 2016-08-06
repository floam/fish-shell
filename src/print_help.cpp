#include "print_help.h"
#include <stdlib.h>
#include <string.h>
#include "common.h"
#include "config.h"  // IWYU pragma: keep

#define HELP_ERR "Could not show help message\n"

/// Print help message for the specified command.
void print_help(const std::string &c, int fd) {
    const std::string cmd = wcs2string(
        format_string(L"eval \"$__fish_bin_dir/fish\" -c '__fish_print_help %s >&%d'", &c, fd));
    if (system(cmd.c_str()) == -1) {
        write_loop(2, HELP_ERR, strlen(HELP_ERR));
    }
}
