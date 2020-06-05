namespace BitField {
  
  private static GLib.Tree<string, Type?> list_of_types;
  
  private static GLib.Tree<FieldInfo?, uint16> mask_cash;
  
  void init () {
    list_of_types = new GLib.Tree<string, Type?> ((a, b) => {
      return (GLib.strcmp (a,b));
    });
    
    mask_cash = new GLib.Tree<FieldInfo?, uint16> ((a, b) => {
       return a.compare (b);
    });
  }
  
  void deinit () {
    list_of_types.foreach ((_key, _val) => {
      list_of_types.remove (_key);
      
      return false;
    });
  }
  
  /**
   * @Return true on error.
   */
  public bool add_type (string name, FieldInfo first_field, ...) {
    var va = va_list ();
    
    GLib.List<FieldInfo?> lst = new GLib.List<FieldInfo?> ();
    
    lst.append (first_field);
    for (FieldInfo? fi = va.arg<FieldInfo> (); fi != null;
                                               fi = va.arg<FieldInfo> ()) {
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
        return true;
      }
      for (uint8 j = i + 1; i < lst.length (); j++) {
        var b = lst.nth_data (i);
        
        
        if (a.overlap (b)) {
          GLib.critical ("Overlappinng fields in %s: (%s) (%s).\n" +
                         "\t Will not add bitmap type defitions.",
                         lst.nth_data (i).to_string (),
                         lst.nth_data (j).to_string ());
          return true;
        }
      }
    }
    
    Type t = Type ();
    for (uint8 i = 0; i < lst.length (); i++) {
      t.fields[i] = lst.nth_data (i);
    }
    
    return false;
  }
  
  public void set_8 (ref uint8 field_id, string type_name, uint8 data) {
    
    
    
  }
  
  public struct FieldInfo {
    uint8 field_id;
    uint8 start;
    uint8 end;
    uint8 length;
    
    public int compare (FieldInfo other) {
      if (this.field_id != other.field_id) {
        return other.field_id - this.field_id; 
      } else if (this.start != other.start) {
        return other.start - this.start;
      } else if (this.end != other.end) {
        return other.end - this.end;
      } else if (this.length != other.length) {
        return other.length - this.length;
      }
      
      #if 0
      if (this.start > other.start) {
        return -1;
      } else if (this.start < other.start) {
        return 1;
      } else {
        if (this.end > other.end) {
          return -1;
        } else if (this.end < other.end) {
          return 1;
        } else {
          if (this.length > other.length) {
            return -1;
          } else if (this.length < other.length) {
            return 1;
          }
        }
      }
      #endif
      
      return 0;
    }
    
    [CCode (cname = "bit_field_field_info_compare")]
    public static extern int static_campare (FieldInfo a, FieldInfo b);
    
    
    public bool overlap (FieldInfo other) {
      return (!((this.start < other.end) || (this.end > other.start)));
    }
    
    [CCode (cname = "bit_field_field_info_overlap")]
    public static extern int static_overlap (FieldInfo a, FieldInfo b);
    
    
    public string to_string () {
      return "start: %i, end: %i, length: %i".printf (this.start,
                                                      this.end,
                                                      this.length);
    }
    
    /**
     * returns true on error;
     */
    public bool validate () {
      var distance = this.start - this.end;
      if (distance < 1 || distance != this.length) {
        GLib.critical ("Validtion if FieldInfo object failed: (%s)",
                       this.to_string ());
        return true;
      }
      return false;
    }
    
    [CCode (cname = "bit_field_field_info_validate")]
    public extern static bool static_validate (FieldInfo info);
    
    public uint16 generate_mask () {
      uint16 mask = 0;
      for (size_t i = 0; i < this.length; i++) {
        mask += 0x8000; // set the left-most bit in the field
        mask >> 1; // shit it over to the right one.
      }
      
      mask >> this.start;
      
      return mask;
    }
    
    [CCode (cname = "bit_field_field_generate_mask")]
    public extern static uint16 static_generate_mask (FieldInfo info);
  }
  
  private struct Type {
    FieldInfo[] fields;
    
    Type () {
        fields = new FieldInfo[16];
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
  }
  
  
  
  
}
