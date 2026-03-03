#include "ruby.h"

void Init_needs_ext_in_lib_ext(void) {
  rb_define_module("NeedsExtInLib");
}
