public class StringUtil {
  /**
   * Return a random String.
   *
   * @param  Integer  length
   * @return String
   */
  public static String random(Integer length) {
    return StringUtil.random(
      length,
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    );
  }

  /**
   * Return a random String.
   *
   * @param  Integer  length
   * @param  String  characters
   * @return String
   */
  public static String random(Integer length, String characters) {
    String result = '';

    while (result.length() < length) {
      Integer i = Math.mod(
        Math.abs(Crypto.getRandomInteger()),
        characters.length()
      );

      result += characters.mid(i, 1);
    }

    return result;
  }

  public static String tokenize(String toTokenize, String regExp) {
    if (String.isEmpty(toTokenize) || String.isEmpty(regExp)) {
      return '';
    }
    return String.join(
        new List<String>(new Set<String>(toTokenize.split(regExp))),
        ''
      )
      .left(255);
  }

  /*
   * Format a given string to be used in a csv file
   * If the string is null this method returns an empty string
   */
  public static String formatForCsv(String toFormat) {
    return toFormat == null ? '' : toFormat.escapeCsv();
  }

  /**
   * format Treat the first argument as a pattern and return a string using
   * the second argument for substitution and formatting. The substitution
   * and formatting are the same as apex:outputText and the Java MessageFormat
   * class. Non-string types in the second argument’s List are implicitly
   * converted to strings, respecting the toString() method overrides that
   * exist on the type.
   *
   * @param stringToFormat (String):
   * https://docs.oracle.com/javase/7/docs/api/java/text/MessageFormat.html
   * @param formattingArguments (List<Object>): The values to include in the
   * string can be null, and will be replaced with a blank string.
   *
   * @return String: a formatted string is returned ensuring 'two or more
   * spaces in sequence' are replaced with one space, and trimming spaces at
   * both ends of the string. Allowing careful reuse of patterns with more
   * arguments than is used.
   */
  public static String format(
    String stringToFormat,
    List<Object> formattingArguments
  ) {
    for (Integer i = 0; i < formattingArguments.size(); i++) {
      if (formattingArguments[i] == null) {
        formattingArguments[i] = '';
      }
    }
    return String.format(stringToFormat, formattingArguments).normalizeSpace();
  }

  /**
   * newGUID generates a new GUID in the ZDHC Gateway style.
   * @return String: A 32 character GUID without dashes.
   */
  public static String newGUID() {
    return EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128)).toUpperCase();
  }
}