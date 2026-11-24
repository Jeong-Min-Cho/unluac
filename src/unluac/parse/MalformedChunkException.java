package unluac.parse;

/**
 * Thrown when the input isn't a Lua bytecode chunk unluac can read: wrong
 * signature, unsupported version, or an inconsistent header.
 */
public class MalformedChunkException extends RuntimeException {

  private static final long serialVersionUID = 1L;

  public MalformedChunkException(String message) {
    super(message);
  }

}
