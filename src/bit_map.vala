/* (c) Gustav Hartvigsson 2020 - 2022

                        Cool Licence 1.1

0) You are granted the right to copy, redistrubute, modify,
   redistrubute the modified copies of the software, in any shape
   or form. It would be cool if you did.

1) You do not have to give credit the original author(s) of
   the software, but it would be cool of you if you did.

2) You are allowed to removed the copyright notice if you want to,
   it is up to you, but it would be cool if you did not.

3) This software is provided without any warranty or guarentees of
   function. Use at your own risk. Be cool.

 */

namespace BitField {
  
  private static GLib.Tree<string, Type?> list_of_types;
  
  private static GLib.Tree<FieldInfo?, uint16> mask_cache;
  
  public void init () {
    list_of_types = new GLib.Tree<string, Type?> ((a, b) => {
      return (GLib.strcmp (a,b));
    });
    
    mask_cache = new GLib.Tree<FieldInfo?, uint16> ((a, b) => {
       return a.compare (b);
    });
  }
  
  public void deinit () {
    list_of_types.foreach ((_key, _val) => {
      list_of_types.remove (_key);
      return false;
    });
  }
  
  public static bool add_type_v (string name, FieldInfo first_field, ...) {
    var va = va_list ();
    
    GLib.List<FieldInfo?> lst = new GLib.List<FieldInfo?> ();
    
    lst.append (first_field);
    for (FieldInfo? fi = va.arg<FieldInfo> (); fi != null;
                                               fi = va.arg<FieldInfo> ()) {
      lst.append (fi);
    }
    
    FieldInfo[] lst2 = new FieldInfo[lst.length ()];
    
    for (uint i = 0; i < lst.length (); i++) {
      lst2[i] = lst.nth_data (i);
    }
   
    return add_type (name, lst2);
  }
  
  /**
   * @Return true on error.
   */
  public bool add_type (string name, FieldInfo[] fields) {
    GLib.List<FieldInfo?> lst = new GLib.List<FieldInfo?> ();
    
    foreach  (FieldInfo fi in fields) {
      lst.append (fi);
    }
    
    if (lst.length () >= 16) {
      return true;
    }
    
    lst.sort ((a,b) => {return a.compare (b);});
    
    
    for (uint8 i = 0; i < lst.length (); i++) {
      var a = lst.nth_data (i); 
      // We valitade the items whilst we are at it.
      if (a.validate ()) {
        GLib.critical ("Validtion of FieldInfo object failed: (%s)",
                       a.to_string ());
        return true;
      }
      for (uint8 j = i + 1; i < lst.length (); j++) {
        var b = lst.nth_data (j);
        if (b == null) {
          break;
        }
        if (a.overlap (b)) {
          GLib.critical ("Overlappinng fields in \"%s\": (%s) (%s).\n" +
                         "\t Will not add bitmap type defitions.",
                         name,
                         a.to_string (),
                         b.to_string ());
          return true;
        }
      }
    }
    
    Type t = Type ();
    for (uint8 i = 0; i < lst.length (); i++) {
      t.fields[i] = lst.nth_data (i);
    }
    
    list_of_types.insert (name, t);
    
    // add the masks to the mask cach, so we don't have to re-calculate them
    // each time we need them.
    lst.foreach ((ii) => {
      mask_cache.insert (ii, ii.generate_mask ());
    });
    
    
    return false;
  }
  
  public void set (ref uint16 data,
                   string type_name,
                   int field_id,
                   uint16 in_data) {
    
    var tt = list_of_types.lookup (type_name);
    if (tt == null) {
      GLib.critical ("Name \"%s\" dose not exist among the types valid types.",
                     type_name);
      return;
    }
    var fi = tt.get_field_info (field_id);
    uint16 mask = mask_cache.lookup (fi);
    uint16 invert_mask = ~mask;
    uint16 tmp = data & invert_mask; // everything exept the field.
    
    uint16 tmp_mask = 1;
    for (uint8 i = 0; i < fi.length; i++) {
      tmp_mask <<= 1;
      tmp_mask += 1;
    }
    
    uint16 tmp2 = in_data & tmp_mask;
    
    
    uint16 distance = 15 - fi.end;
    
    
    tmp2 = tmp2 << distance;
    
    
    tmp2 = tmp2 | tmp;
    
    data = tmp2;
  }
  
  public uint16 get (uint16 data,
                     string type_name,
                     int field_id) {
    
    var fi = list_of_types.lookup (type_name).get_field_info (field_id);
    uint16 mask = mask_cache.lookup (fi);
    uint16 tmp = data & mask; // only what is in the field.
    
    
    uint16 distance = 15 - fi.end;
    
    
    tmp = tmp >> distance;
    return tmp;
  }
  
  Type? get_type (string name) {
    return list_of_types.lookup (name);
  } 
  
  /**
   * Create a new FieldInfo using the following syntax:
   * {{{
   *  enum MyTypeFields {
   *    F1,
   *    F2,
   *    //....
   *  }
   *
   *  BitField.FieldInfo[] my_fields_info = {
   *    BitField.FieldInfo (MyTypeFields.F1, 0, 5, 6),
   *    BitField.FieldInfo (MyTypeFields.F2, 0, 5, 6),
   *    //.....
   *  }
   *  
   *  if (FieldInfo.add_type ("MyType", my_fields_info)) {
   *    stderr.printf ("Something went wrong!");
   *  }
   * }}}
   * 
   */
  [CCode (cprefix="bit_field_info_", cname="BitFieldInfo")]
  public struct FieldInfo {
    int field_id;
    uint8 start;
    uint8 end;
    uint8 length;
    
    public FieldInfo (int field_id, uint8 start, uint8 end, uint8 length) {
      this.field_id = field_id;
      this.start = start;
      this.end = end;
      this.length = length; 
    }
    
    public int compare (FieldInfo other) {
      if (this.field_id != other.field_id) {
        return  this.field_id - other.field_id; 
      } else if (this.start != other.start) {
        return  this.start - other.start;
      } else if (this.end != other.end) {
        return this.end - other.end;
      } else if (this.length != other.length) {
        return this.length - other.length;
      }
      
      return 0;
    }
    
    [CCode (cname = "bit_field_info_compare")]
    public static extern int static_compare (FieldInfo a, FieldInfo b);
    
    
    
    public bool overlap (FieldInfo other) {
      return (!((this.start < other.end) || (this.end > other.start)));
    }
    
    [CCode (cname = "bit_field_info_overlap")]
    public static extern bool static_overlap (FieldInfo a, FieldInfo b);
    
    
    public string to_string () {
      return "field_id: %i start: %i, end: %i, length: %i".printf (
                                                      this.field_id,
                                                      this.start,
                                                      this.end,
                                                      this.length);
    }
    
    /**
     * returns true on error;
     */
    public bool validate () {
      var distance = this.end - this.start + 1;
      if (distance < 1 || distance != this.length) {
        return true;
      }
      return false;
    }
    
    [CCode (cname = "bit_field_info_validate")]
    public extern static bool static_validate (FieldInfo info);
    
    public uint16 generate_mask () {
      uint16 mask = 0;
      for (size_t i = 0; i < this.length; i++) {
        mask >>= 1; // shit it over to the right one.
        mask += 0x8000; // set the left-most bit in the field
      }
      
      // Shift over the mask to where it should start.
      mask >>= this.start; 
      
      return mask;
    }
    
    [CCode (cname = "bit_field_info_generate_mask")]
    public extern static uint16 static_generate_mask (FieldInfo info);
  }
  
  public struct Type {
    FieldInfo[] fields;
    
    Type () {
        fields = new FieldInfo[16];
        for (uint8 i = 0; i < 16; i++) {
          fields[i] = {255,255,255,255};
        }
    }
    
    public string to_string () {
      var sb = new GLib.StringBuilder ();
      
      sb.append (typeof (Type).name ())
        .append (": (\n");
      for (size_t i = 0; i < fields.length; i++) {
          sb.append ("\t (")
            .append (fields[i].to_string ())
            .append (")\n");
      }
      
      sb.append (")\n");
      return sb.str;
    }
    
    public FieldInfo get_field_info (int field_id) {
      
      FieldInfo ii = {0};
      
      foreach (FieldInfo ij in fields) {
        if (ij.field_id == field_id) {
          ii = ij;
        }
      }
      
      return ii;
    }
    
  }
  
}
