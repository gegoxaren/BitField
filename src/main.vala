enum TestFields {
  A,
  B,
  C,
}

int main (string[] args) {
  
  BitField.init ();
  
  BitField.FieldInfo[] info = {
    BitField.FieldInfo (TestFields.A, 0, 5, 6),
    BitField.FieldInfo (TestFields.B, 6, 7, 2),
    BitField.FieldInfo (TestFields.C, 8, 15, 8),
  };
  
  BitField.add_type ("foo", info);
  
  uint16 t1 = 0;
  BitField.set (ref t1, "foo", TestFields.C, 137);
  print ("%i\n", t1);
  
  uint16 t2 = BitField.get (t1 ,"foo", TestFields.C);
  print ("%i\n", t2);
  
  BitField.deinit ();
  return 0;
}
