@isTest
public with sharing class TC_TestDataFactory {
  public static List<String> titles = new List<String>{
    '',
    'Mr.',
    'Mrs.',
    'Ms.',
    'Mx.',
    'Miss'
  };

  public static List<Id> newIdList(List<SObject> objects) {
    List<Id> ids = new List<Id>();
    for (SObject o : objects) {
      ids.add(o.Id);
    }
    return ids;
  }

  public static Integer random(Integer minimum, Integer maximum) {
    return minimum +
      Math.mod(Math.abs(Crypto.getRandomInteger()), maximum - minimum);
  }

  public static String random(Integer length, String charSet) {
    String s = '';
    for (Integer i = 0; i < length; i++) {
      Integer r = Math.mod(
        Math.abs(Crypto.getRandomInteger()),
        charSet.length()
      );
      s += charSet.substring(r, r + 1);
    }
    return s;
  }

  public static String randomWord(Integer length) {
    List<String> charSet = new List<String>{ 'aeiou', 'bcdfghjklmnpqrstvwxyz' };
    String s = '';
    for (Integer i = 0; i < length; i++) {
      Integer r = Math.abs(Crypto.getRandomInteger());
      // Use first bit to achieve a balance, even is vowel, odd is consonant.
      String charSetRef = charSet.get(r & 1);
      Integer c = Math.mod(r >> 1, charSetRef.length());
      s += charSetRef.substring(c, c + 1);
    }
    return s;
  }

  public static String randomWord(Integer lengthMin, Integer lengthMax) {
    return randomWord(random(lengthMin, lengthMax));
  }

  public static String randomName(
    Integer words,
    Integer lengthMin,
    Integer lengthMax
  ) {
    List<String> s = new List<String>();
    for (Integer i = 0; i < words; i++) {
      s.add(randomWord(random(lengthMin, lengthMax)).capitalize());
    }
    return String.join(s, ' ');
  }

  public static String randomValue(List<String> values) {
    if (values.isEmpty()) {
      return null;
    }
    return values[random(0, values.size())];
  }

  public static String randomValue(List<Schema.PicklistEntry> values) {
    if (values.isEmpty()) {
      return null;
    }
    Schema.PicklistEntry e = values[random(0, values.size())];
    Integer n = 0;
    while (!e.isActive() && n++ < 10) {
      e = values[random(0, values.size())];
    } // Find an active one up to 10 retries.
    return e.getValue();
  }

  public static Integer firstnamesIndex = 0;
  // prettier-ignore
  public static List<String> firstnames = new List<String>{
    // Two sets of names beginning A through to Z in sequence.
    'Abagail','Bobbee','Cariotta','Davida','Eleanora','Florenza','Gaynor','Harry','Isabella','Jannelle','Kala','Loralyn','Mahala','Natty','Owen','Paulita','Quain','Raeann','Selestina','Tasia','Ulysses','Victor','William','Xylina','Yolande','Zerach',
    'Antonia','Brian','Clarisse','Doralin','Eugine','Freddi','Gwennie','Hyacinthia','Ivette','Juliet','Kristin','Lyndel','Monique','Nola','Osmar','Prudence','Quinby','Roxane','Susanna','Thia','Urson','Vonnie','Winna','Yindi','Zoltin'
  };
  public static String getFirstname() {
    return firstnames[Math.mod(firstnamesIndex++, firstnames.size())];
  }

  public static Integer lastnamesIndex = 0;
  // prettier-ignore
  public static List<String> lastnames = new List<String>{
    // Two sets of names beginning A through to Z in sequence.
    // One extra last name so repeated calls for first and last name pairs skew.
    'Albers','Brinklow','Cadmus','Draffin','Emlenton','Franconia','Garber','Hardtner','Imbler','Jesup','Kahlotus','Landrum','Manistique','Niangua','Ogunquit','Pendleton','Quondin','Rebuck','Swartz','Tallevast','Underbore','Varna','Wainscott','Xylup','Yalaha','Zoberocki',
    'Aorarr','Byeant','Chroast','Dillons','Ezekki','Fillaski','Gilia','Hopsovi','Innservic','Jomdraski','Krillopson','Livemost','Morninski','Nesheroc','Omptooso','Pranvar','Quoson','Rainings','Sandisko','Truovon','Usvanski','Voonson','Wumbatter','Xabatas','Ylsoroia','Zarch',
    'Azarach'
  };
  public static String getLastname() {
    return lastnames[Math.mod(lastnamesIndex++, lastnames.size())];
  }

  public static Integer companyIndex = 0;
  public static String getCompanyname() {
    return lastnames[Math.mod(companyIndex++, lastnames.size())];
  }

  public static Integer letternameIndex = 0;
  public static String getLettername() {
    final String c26 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Integer n = letternameIndex++;
    // Two characters enough for 676 combinations.
    Integer a = Math.mod(n / 26, 26);
    Integer b = Math.mod(n, 26);
    String name = c26.substring(a, a + 1) + ' ' + c26.substring(b, b + 1);
    if (letternameIndex >= 676) {
      name += ' ' + lastnames[Math.mod(n / 676, lastnames.size())];
    }
    return name;
  }
}