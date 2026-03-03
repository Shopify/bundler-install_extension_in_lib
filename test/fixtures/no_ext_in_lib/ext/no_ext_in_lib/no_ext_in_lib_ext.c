#include "ruby.h"

void Init_no_ext_in_lib_ext(void) {
  rb_define_module("NoExtInLib");
}
