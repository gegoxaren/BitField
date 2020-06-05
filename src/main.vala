int main (string[] args) {
  
  BitField.init ();
  
  BitField.FieldInfo a = {1,2,3};
  BitField.FieldInfo b = {3, 2, 1};
  
  BitField.FieldInfo.static_campare (a,b);
  
  BitField.deinit ();
  return 0;
}
