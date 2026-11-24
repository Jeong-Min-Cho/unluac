package unluac;

import java.io.FileOutputStream;
import java.io.IOException;

import unluac.decompile.FileOutputProvider;
import unluac.decompile.Output;

public class Configuration {

  public enum Mode {
    DECOMPILE,
    DISASSEMBLE,
    ASSEMBLE,
    HELP,
    VERSION,
  }
  
  public enum VariableMode {
    NODEBUG,
    DEFAULT,
    FINDER,
  }
  
  public boolean rawstring;
  public boolean annotate_source;
  public Mode mode;
  public VariableMode variable;
  public boolean strict_scope;
  public boolean luaj;
  public String typemap;
  public String opmap;
  public String output;
  
  public Configuration() {
    rawstring = false;
    annotate_source = false;
    mode = Mode.DECOMPILE;
    variable = VariableMode.DEFAULT;
    strict_scope = false;
    luaj = false;
    opmap = null;
    output = null;
  }
  
  public Configuration(Configuration other) {
    rawstring = other.rawstring;
    annotate_source = other.annotate_source;
    mode = other.mode;
    variable = other.variable;
    strict_scope = other.strict_scope;
    opmap = other.opmap;
    output = other.output;
  }
  
  public Output getOutput() {
    if(output != null) {
      try {
        return new Output(new FileOutputProvider(new FileOutputStream(output)));
      } catch(IOException e) {
        Main.error(e.getMessage(), false);
        return null;
      }
    } else {
      return new Output();
    }
  }
  
}
