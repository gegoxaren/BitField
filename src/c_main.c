#include <stdio.h>
#include <glib.h>
#include "vbitfield.h"

enum {
  FOO_A,
  FOO_B,
  FOO_C,
  FOO_LEN
};

int
main (int argc, char ** argv) {
  bit_field_init ();
  
  BitFieldInfo info[] = {
    {FOO_A, 0, 5, 6},
    {FOO_B, 6, 7, 2},
    {FOO_C, 8, 15, 8},
  };

  if (bit_field_add_type ("foo", info, FOO_LEN)) {
    fprintf (stdout, "Something went wrong when adding info.\n");
  }

  guint16 t1 = 0;
  bit_field_set (&t1, "foo", FOO_C, 137);
  fprintf (stdout, "%i\n", t1);
  bit_field_set (&t1, "foo", FOO_B, 3);
  fprintf (stdout, "%i\n", t1);
  bit_field_set (&t1, "foo", FOO_A, 7);
  fprintf (stdout, "%i\n", t1);

  guint16 t2 = bit_field_get (t1, "foo", FOO_C);
  fprintf (stdout, "C: %i\n", t2);
  t2 = bit_field_get (t1, "foo", FOO_B);
  fprintf (stdout, "B: %i\n", t2);
  t2 = bit_field_get (t1, "foo", FOO_A);
  fprintf (stdout, "A: %i\n", t2);

  bit_field_deinit ();

  return 0;
}
