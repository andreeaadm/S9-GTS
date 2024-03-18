public with sharing class iCare_CustomExceptionData {
    public String name;
    public String message;
    public Integer code;

    public iCare_CustomExceptionData(String name, String message, Integer code) {
        this.name = name;
        this.message = message;
        this.code = code;
    }
}