package unluac.test;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Random;

import unluac.Configuration;
import unluac.Main;
import unluac.parse.MalformedChunkException;

/**
 * Feeds truncated and corrupted chunks to the parser and checks that every
 * failure is reported as a MalformedChunkException rather than escaping as
 * some other exception or error.
 *
 * Usage: RunFuzzTests [mutations per seed chunk, default 300]
 */
public class RunFuzzTests {

  private static final String[] seeds = {
    "assign", "literal", "literallist", "closure", "upvalue01",
  };

  private static int mutations = 300;

  public static void main(String[] args) throws IOException {
    if(args.length > 0) mutations = Integer.parseInt(args[0]);
    LuaSpec[] specs = {
      new LuaSpec(0x50),
      new LuaSpec(0x51),
      new LuaSpec(0x51, 4),
      new LuaSpec(0x52),
      new LuaSpec(0x53),
      new LuaSpec(0x54),
      new LuaSpec(0x54, 8),
      new LuaSpec(0x55),
    };
    new File("./test/working").mkdirs();
    String compiled = "./test/working/fuzz.luac";
    Map<String, String> failures = new LinkedHashMap<String, String>();
    int cases = 0;
    int skipped = 0;
    for(LuaSpec spec : specs) {
      for(String seed : seeds) {
        try {
          LuaC.compile(spec, "./test/src/" + seed + ".lua", compiled);
        } catch(IOException e) {
          skipped++;
          continue;
        }
        byte[] chunk = Files.readAllBytes(new File(compiled).toPath());
        String label = spec.id() + "/" + seed;
        Random random = new Random(label.hashCode());
        for(int length = 0; length < chunk.length; length++) {
          cases++;
          check(label + " truncated to " + length, java.util.Arrays.copyOf(chunk, length), failures);
        }
        for(int i = 0; i < mutations; i++) {
          byte[] mutated = chunk.clone();
          int flips = 1 + random.nextInt(4);
          StringBuilder where = new StringBuilder();
          for(int f = 0; f < flips; f++) {
            int at = random.nextInt(mutated.length);
            mutated[at] = (byte) random.nextInt(256);
            where.append(f == 0 ? "" : ",").append(at);
          }
          cases++;
          check(label + " with bytes " + where + " changed", mutated, failures);
        }
      }
    }
    System.out.println(cases + " fuzz cases, " + skipped + " seed compilations skipped");
    if(failures.isEmpty()) {
      System.out.println(skipped == 0 ? "All tests passed!" : "Passed, but some compilers were missing.");
      System.exit(0);
    } else {
      System.out.println(failures.size() + " distinct failure(s):");
      for(Map.Entry<String, String> failure : failures.entrySet()) {
        System.out.println("  " + failure.getKey());
        System.out.println("    first seen: " + failure.getValue());
      }
      System.exit(1);
    }
  }

  private static void check(String name, byte[] input, Map<String, String> failures) {
    try {
      Main.parse(ByteBuffer.wrap(input), new Configuration());
    } catch(MalformedChunkException e) {
      // Expected: a clean report.
    } catch(Throwable t) {
      StackTraceElement[] trace = t.getStackTrace();
      String key = t.getClass().getName() + (trace.length > 0 ? " at " + trace[0] : "");
      if(!failures.containsKey(key)) {
        failures.put(key, name);
      }
    }
  }

}
